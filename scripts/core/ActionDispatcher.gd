extends RefCounted
class_name ActionDispatcher


const ACTION_ROLL := "roll"
const ACTION_GRID_ROUTE_CHOICE := "grid_route_choice"
const ACTION_BUY_PROPERTY := "buy_property"
const ACTION_SKIP_PROPERTY := "skip_property"
const ACTION_PLAY_CARD := "play_card"

const PAYLOAD_PLAYER_ID := "player_id"
const PAYLOAD_CARD_ID := "card_id"
const PAYLOAD_WINDOW_ID := "window_id"
const PAYLOAD_TARGET_PLAYER_ID := "target_player_id"

const PENDING_ACTING_PLAYER_ID := "acting_player_id"
const PENDING_ELIGIBLE_PLAYERS := "eligible_players"
const PENDING_CARD_ID := "card_id"
const PENDING_WINDOW_ID := "window_id"
const PENDING_TARGET_PLAYER_ID := "target_player_id"

const RESULT_ACCEPTED := "accepted"
const RESULT_REJECTION_REASON := "rejection_reason"


func submit_action(sender_peer_id: int, action_type: String, payload: Dictionary = {}, control_resolver: Callable = Callable()) -> Dictionary:
	var rejection_reason := get_action_rejection_reason(sender_peer_id, action_type, payload, control_resolver)
	if not rejection_reason.is_empty():
		return _rejected(rejection_reason)

	if not _dispatch_action(action_type, payload):
		return _rejected("game rejected intent")

	return _accepted()


func is_known_action(action_type: String) -> bool:
	match action_type:
		ACTION_ROLL, ACTION_GRID_ROUTE_CHOICE, ACTION_BUY_PROPERTY, ACTION_SKIP_PROPERTY, ACTION_PLAY_CARD:
			return true

	return false


func get_action_rejection_reason(sender_peer_id: int, action_type: String, payload: Dictionary = {}, control_resolver: Callable = Callable()) -> String:
	if not is_known_action(action_type):
		return "unknown intent"

	var game_manager: Variant = _get_game_manager()
	if game_manager == null or game_manager.state == null:
		return "game not ready"

	match action_type:
		ACTION_ROLL:
			var current_player_id: int = game_manager.state.get_current_player_id()
			if not _can_control_player(control_resolver, sender_peer_id, current_player_id):
				return "not your turn"
			if not game_manager.turn_system.can_roll():
				return "roll is not available"
			if game_manager.state.has_pending_movement() or game_manager.state.has_pending_grid_movement():
				return "movement is pending"
		ACTION_GRID_ROUTE_CHOICE:
			var route_player_id: int = game_manager.state.get_current_player_id()
			if not _can_control_player(control_resolver, sender_peer_id, route_player_id):
				return "not your route choice"
			if not game_manager.turn_system.can_resolve_route_choice():
				return "route choice is not available"
			if not game_manager.state.has_pending_grid_movement():
				return "no grid movement pending"
		ACTION_BUY_PROPERTY, ACTION_SKIP_PROPERTY:
			if not game_manager.state.has_pending_property_purchase():
				return "no property decision pending"
			var property_player_id := int(game_manager.state.pending_property_purchase.get("player_id", -1))
			if not _can_control_player(control_resolver, sender_peer_id, property_player_id):
				return "not your property decision"
			if not game_manager.turn_system.can_resolve_property_decision():
				return "property decision is not available"
		ACTION_PLAY_CARD:
			return _get_card_action_rejection_reason(game_manager, sender_peer_id, payload, control_resolver)

	return ""


func _dispatch_action(action_type: String, payload: Dictionary) -> bool:
	var game_manager: Variant = _get_game_manager()
	if game_manager == null:
		return false

	match action_type:
		ACTION_ROLL:
			return game_manager.request_roll()
		ACTION_GRID_ROUTE_CHOICE:
			return game_manager.request_grid_route_choice(int(payload.get("direction", 0)))
		ACTION_BUY_PROPERTY:
			return game_manager.request_buy_pending_property()
		ACTION_SKIP_PROPERTY:
			return game_manager.request_skip_pending_property()
		ACTION_PLAY_CARD:
			return game_manager.request_play_card_intent(payload)

	return false


func _get_game_manager() -> Variant:
	var main_loop: MainLoop = Engine.get_main_loop()
	if main_loop is SceneTree:
		return main_loop.root.get_node_or_null("/root/GameManager")

	return null


func _can_control_player(control_resolver: Callable, sender_peer_id: int, player_id: int) -> bool:
	if player_id < 0:
		return false

	if not control_resolver.is_valid():
		return true

	return bool(control_resolver.call(sender_peer_id, player_id))


func _get_card_action_rejection_reason(game_manager: Variant, sender_peer_id: int, payload: Dictionary, control_resolver: Callable) -> String:
	if not game_manager.state.has_pending_intervention():
		return "no card intervention pending"

	var player_id := int(payload.get(PAYLOAD_PLAYER_ID, -1))
	if player_id < 0:
		return "missing card player"

	if not _can_control_player(control_resolver, sender_peer_id, player_id):
		return "not your card action"

	var pending_intervention: Dictionary = game_manager.state.pending_intervention
	var pending_actor_id := int(pending_intervention.get(PENDING_ACTING_PLAYER_ID, -1))
	if pending_actor_id >= 0 and pending_actor_id != player_id:
		return "not active card player"

	var eligible_players: Array = pending_intervention.get(PENDING_ELIGIBLE_PLAYERS, [])
	if not _array_has_int(eligible_players, player_id):
		return "player is not eligible for card window"

	var card_id := _get_string_name(payload.get(PAYLOAD_CARD_ID, &""))
	if card_id == &"":
		return "missing card id"

	if not game_manager.state.has_card_in_hand(player_id, card_id):
		return "card not in hand"

	var pending_card_id := _get_string_name(pending_intervention.get(PENDING_CARD_ID, &""))
	if pending_card_id != &"" and pending_card_id != card_id:
		return "card mismatch"

	var window_id := _get_string_name(payload.get(PAYLOAD_WINDOW_ID, &""))
	if window_id == &"":
		return "missing card window"

	var pending_window_id := _get_string_name(pending_intervention.get(PENDING_WINDOW_ID, &""))
	if pending_window_id != &"" and pending_window_id != window_id:
		return "card window mismatch"

	if pending_intervention.has(PENDING_TARGET_PLAYER_ID):
		var target_player_id := int(payload.get(PAYLOAD_TARGET_PLAYER_ID, -1))
		var pending_target_player_id := int(pending_intervention.get(PENDING_TARGET_PLAYER_ID, -1))
		if target_player_id != pending_target_player_id:
			return "invalid card target"

	return ""


func _array_has_int(values: Array, expected_value: int) -> bool:
	for value in values:
		if int(value) == expected_value:
			return true

	return false


func _get_string_name(value: Variant) -> StringName:
	if value == null:
		return &""

	var text := str(value).strip_edges()
	if text.is_empty():
		return &""

	return StringName(text)


func _accepted() -> Dictionary:
	return {
		RESULT_ACCEPTED: true,
		RESULT_REJECTION_REASON: "",
	}


func _rejected(reason: String) -> Dictionary:
	return {
		RESULT_ACCEPTED: false,
		RESULT_REJECTION_REASON: reason,
	}
