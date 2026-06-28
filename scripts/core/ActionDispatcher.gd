extends RefCounted
class_name ActionDispatcher


const ACTION_ROLL := "roll"
const ACTION_GRID_ROUTE_CHOICE := "grid_route_choice"
const ACTION_BUY_PROPERTY := "buy_property"
const ACTION_SKIP_PROPERTY := "skip_property"

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
		ACTION_ROLL, ACTION_GRID_ROUTE_CHOICE, ACTION_BUY_PROPERTY, ACTION_SKIP_PROPERTY:
			return true

	return false


func get_action_rejection_reason(sender_peer_id: int, action_type: String, _payload: Dictionary = {}, control_resolver: Callable = Callable()) -> String:
	if not is_known_action(action_type):
		return "unknown intent"

	if GameManager.state == null:
		return "game not ready"

	match action_type:
		ACTION_ROLL:
			var current_player_id := GameManager.state.get_current_player_id()
			if not _can_control_player(control_resolver, sender_peer_id, current_player_id):
				return "not your turn"
			if not GameManager.turn_system.can_roll():
				return "roll is not available"
			if GameManager.state.has_pending_movement() or GameManager.state.has_pending_grid_movement():
				return "movement is pending"
		ACTION_GRID_ROUTE_CHOICE:
			var route_player_id := GameManager.state.get_current_player_id()
			if not _can_control_player(control_resolver, sender_peer_id, route_player_id):
				return "not your route choice"
			if not GameManager.turn_system.can_resolve_route_choice():
				return "route choice is not available"
			if not GameManager.state.has_pending_grid_movement():
				return "no grid movement pending"
		ACTION_BUY_PROPERTY, ACTION_SKIP_PROPERTY:
			if not GameManager.state.has_pending_property_purchase():
				return "no property decision pending"
			var property_player_id := int(GameManager.state.pending_property_purchase.get("player_id", -1))
			if not _can_control_player(control_resolver, sender_peer_id, property_player_id):
				return "not your property decision"
			if not GameManager.turn_system.can_resolve_property_decision():
				return "property decision is not available"

	return ""


func _dispatch_action(action_type: String, payload: Dictionary) -> bool:
	match action_type:
		ACTION_ROLL:
			return GameManager.request_roll()
		ACTION_GRID_ROUTE_CHOICE:
			return GameManager.request_grid_route_choice(int(payload.get("direction", BoardConnectionData.Direction.NONE)))
		ACTION_BUY_PROPERTY:
			return GameManager.request_buy_pending_property()
		ACTION_SKIP_PROPERTY:
			return GameManager.request_skip_pending_property()

	return false


func _can_control_player(control_resolver: Callable, sender_peer_id: int, player_id: int) -> bool:
	if player_id < 0:
		return false

	if not control_resolver.is_valid():
		return true

	return bool(control_resolver.call(sender_peer_id, player_id))


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
