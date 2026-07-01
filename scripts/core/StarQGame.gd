extends Node
class_name StarQGame


const MAX_EVENT_LOG_LINES := 100
const MAP_STEP_DURATION := 0.14
const PIECE_OFFSETS: Array[Vector2] = [
	Vector2(-8.0, -6.0),
	Vector2(8.0, -6.0),
	Vector2(-8.0, 8.0),
	Vector2(8.0, 8.0),
]


@onready var _board: Board = $MapView/Board as Board
@onready var _pieces_root: Node2D = $MapView/Pieces as Node2D
@onready var _ui: GameUI = $UI as GameUI

var _visual_pieces_by_player_id: Dictionary = {}
var _event_log: Array[String] = []
var _map_animation_queue: Array[Dictionary] = []
var _is_animating_map_movement: bool = false
var _pending_route_choice_payload: Dictionary = {}
var _roll_is_ready: bool = false
var _has_received_network_snapshot: bool = false
var _pending_network_intent_type: String = ""


func _ready() -> void:
	_register_visual_pieces()
	_connect_ui_actions()
	EventBus.game_event_emitted.connect(_on_game_event)
	NetworkManager.connection_status_changed.connect(_on_network_status_changed)
	NetworkManager.intent_accepted.connect(_on_network_intent_accepted)
	NetworkManager.intent_rejected.connect(_on_network_intent_rejected)
	NetworkManager.local_player_changed.connect(_on_network_local_player_changed)
	NetworkManager.state_snapshot_received.connect(_on_network_state_snapshot_received)
	if _ui != null:
		_ui.set_network_address_text(NetworkManager.DEFAULT_URL)
		_ui.set_host_open_seat_control_enabled(NetworkManager.host_can_control_open_seats)
		_ui.set_network_status_text("Network: %s" % NetworkManager.get_status_message())
	_start_local_game()


func _start_local_game() -> void:
	if _board == null:
		push_error("StarQGame requires a Board child.")
		return

	var board_data: BoardData = _board.board_data as BoardData
	if board_data == null or board_data.get_map_grid() == null:
		push_error("StarQGame requires BoardData with a map grid.")
		return

	for message in board_data.get_player_spawn_validation_messages():
		push_warning(message)

	GameManager.start_local_game(_create_initial_player_states(board_data), board_data)


func _create_initial_player_states(board_data: BoardData) -> Array[PlayerState]:
	var players: Array[PlayerState] = []
	var player_ids: Array[int] = []
	for player_id_value in _visual_pieces_by_player_id:
		player_ids.append(int(player_id_value))

	player_ids.sort()
	for player_id in player_ids:
		players.append(PlayerState.new(
			player_id,
			"Player %d" % [player_id + 1],
			1500,
			board_data.get_player_spawn_tile_index(player_id)
		))

	return players


func _connect_ui_actions() -> void:
	if _ui == null:
		push_error("StarQGame requires a GameUI child.")
		return

	_ui.roll_pressed.connect(_on_roll_pressed)
	_ui.property_buy_pressed.connect(_on_property_buy_pressed)
	_ui.property_skip_pressed.connect(_on_property_skip_pressed)
	_ui.grid_route_choice_pressed.connect(_on_grid_route_choice_pressed)
	_ui.network_host_pressed.connect(_on_network_host_pressed)
	_ui.network_join_pressed.connect(_on_network_join_pressed)
	_ui.host_open_seat_control_toggled.connect(_on_host_open_seat_control_toggled)
	_ui.card_play_pressed.connect(_on_card_play_pressed)


func _on_roll_pressed() -> void:
	if _has_pending_client_intent():
		return

	if NetworkManager.submit_roll():
		_begin_pending_client_intent(NetworkManager.INTENT_ROLL)


func _on_grid_route_choice_pressed(direction: int) -> void:
	if _has_pending_client_intent():
		return

	if NetworkManager.submit_grid_route_choice(direction):
		_begin_pending_client_intent(NetworkManager.INTENT_GRID_ROUTE_CHOICE)


func _on_property_buy_pressed() -> void:
	if _has_pending_client_intent():
		return

	if NetworkManager.submit_buy_property():
		_begin_pending_client_intent(NetworkManager.INTENT_BUY_PROPERTY)


func _on_property_skip_pressed() -> void:
	if _has_pending_client_intent():
		return

	if NetworkManager.submit_skip_property():
		_begin_pending_client_intent(NetworkManager.INTENT_SKIP_PROPERTY)


func _on_card_play_pressed(player_id: int, card_id: StringName, window_id: StringName, target_player_id: int) -> void:
	if _has_pending_client_intent():
		return

	if NetworkManager.submit_play_card(player_id, card_id, window_id, target_player_id):
		_begin_pending_client_intent(NetworkManager.INTENT_PLAY_CARD)
		_update_money_label()
		_refresh_card_hand()
		_update_roll_availability()


func _on_network_host_pressed() -> void:
	_has_received_network_snapshot = false
	_clear_pending_client_intent()
	NetworkManager.start_host()


func _on_network_join_pressed(address: String) -> void:
	_has_received_network_snapshot = false
	_clear_pending_client_intent()
	NetworkManager.join_host(address)


func _on_host_open_seat_control_toggled(enabled: bool) -> void:
	NetworkManager.set_host_can_control_open_seats(enabled)
	_update_roll_availability()
	_refresh_pending_action_controls()


func _on_game_event(event: GameEvent) -> void:
	if NetworkManager.is_client():
		_clear_pending_client_intent()

	match event.type:
		GameEvent.GAME_STARTED:
			_handle_game_started()
		GameEvent.ROUND_STARTED:
			_handle_round_started(event.payload)
		GameEvent.TURN_STARTED:
			_handle_turn_started(event.payload)
		GameEvent.DICE_ROLLED:
			_handle_dice_rolled(event.payload)
		GameEvent.MAP_PLAYER_MOVED:
			_handle_map_player_moved(event.payload)
		GameEvent.MAP_ROUTE_CHOICE_REQUESTED:
			_handle_map_route_choice_requested(event.payload)
		GameEvent.MAP_PLAYER_LANDED:
			_handle_map_player_landed(event.payload)
		GameEvent.TILE_EFFECT_RESOLVED:
			_handle_tile_effect_resolved(event.payload)
		GameEvent.RENT_PAID:
			_handle_rent_paid(event.payload)
		GameEvent.PROPERTY_PURCHASE_OFFERED:
			_handle_property_purchase_offered(event.payload)
		GameEvent.PROPERTY_PURCHASED:
			_handle_property_purchased(event.payload)
		GameEvent.PROPERTY_PURCHASE_SKIPPED:
			_handle_property_purchase_skipped(event.payload)


func _handle_game_started() -> void:
	_event_log.clear()
	_pending_route_choice_payload.clear()
	_roll_is_ready = false
	_update_log_label()
	_update_dice_label(0)
	_update_tile_label(-1, "")
	_update_event_label("")
	_update_money_label()
	_sync_piece_positions()
	_sync_property_owner_visuals()
	if _ui != null:
		_ui.hide_route_actions()
		_ui.hide_property_actions()
		_ui.set_roll_allowed(false)
	_refresh_card_hand()


func _handle_round_started(payload: Dictionary) -> void:
	var round_number: int = int(payload.get("round", 1))
	if _ui != null:
		_ui.set_round_text("Round %d" % round_number)

	if round_number > 1:
		_add_event_log_line("Round %d begins" % round_number)


func _handle_turn_started(payload: Dictionary) -> void:
	var player_id: int = int(payload.get("player_id", -1))
	if _ui != null and player_id >= 0:
		_ui.set_turn_text("Player %d Turn" % [player_id + 1])

	_roll_is_ready = player_id >= 0 and NetworkManager.can_control_player(player_id)
	_update_roll_availability()
	_refresh_card_hand()


func _handle_dice_rolled(payload: Dictionary) -> void:
	_roll_is_ready = false
	_update_dice_label(int(payload.get("dice_value", 0)))
	_update_roll_availability()
	_refresh_card_hand()


func _handle_map_player_moved(payload: Dictionary) -> void:
	var player_id: int = int(payload.get("player_id", -1))
	var path_positions: Array[Vector2i] = _get_grid_positions(payload.get("path_grid_positions", []))
	if player_id < 0 or path_positions.is_empty():
		return

	if _ui != null:
		_ui.hide_route_actions()
	_map_animation_queue.append({
		"player_id": player_id,
		"path_positions": path_positions,
	})
	if not _is_animating_map_movement:
		_is_animating_map_movement = true
		_play_queued_map_animations()


func _handle_map_route_choice_requested(payload: Dictionary) -> void:
	_pending_route_choice_payload = payload.duplicate(true)
	if not _is_animating_map_movement:
		_show_pending_route_choice()


func _handle_map_player_landed(payload: Dictionary) -> void:
	var player_id: int = int(payload.get("player_id", -1))
	var tile_name: String = str(payload.get("tile_name", "Unknown"))
	var dice_value: int = int(payload.get("dice_value", 0))
	var node_id: int = int(payload.get("node_id", -1))

	_update_event_label("")
	_update_tile_label(player_id, tile_name)
	_add_event_log_line("P%d rolled %d -> node %d %s" % [player_id + 1, dice_value, node_id, tile_name])


func _handle_tile_effect_resolved(payload: Dictionary) -> void:
	var player_id: int = int(payload.get("player_id", -1))
	var tile_name: String = str(payload.get("tile_name", "tile"))
	var money_delta: int = int(payload.get("money_delta", 0))
	var delta_text: String = "+$%d" % money_delta if money_delta >= 0 else "-$%d" % abs(money_delta)
	var verb: String = "received" if money_delta >= 0 else "lost"
	var message: String = "P%d %s %s on %s" % [player_id + 1, verb, delta_text, tile_name]
	_update_money_label()
	_update_event_label(message)
	_add_event_log_line(message)


func _handle_rent_paid(payload: Dictionary) -> void:
	var payer_id: int = int(payload.get("payer_id", -1))
	var owner_id: int = int(payload.get("owner_id", -1))
	var amount: int = int(payload.get("amount", 0))
	var tile_name: String = str(payload.get("tile_name", "property"))
	var message: String = "P%d paid P%d $%d rent for %s" % [payer_id + 1, owner_id + 1, amount, tile_name]
	_update_money_label()
	_update_event_label(message)
	_add_event_log_line(message)


func _handle_property_purchase_offered(payload: Dictionary) -> void:
	var player_id: int = int(payload.get("player_id", -1))
	var tile_name: String = str(payload.get("tile_name", "property"))
	var price: int = int(payload.get("price", 0))
	var message: String = "P%d can buy %s for $%d" % [player_id + 1, tile_name, price]
	_update_event_label(message)
	_add_event_log_line(message)
	if _ui != null:
		if NetworkManager.can_control_player(player_id):
			_ui.show_property_actions()
		else:
			_ui.hide_property_actions()


func _handle_property_purchased(payload: Dictionary) -> void:
	var player_id: int = int(payload.get("player_id", -1))
	var tile_index: int = int(payload.get("tile_index", -1))
	var tile_name: String = str(payload.get("tile_name", "property"))
	var price: int = int(payload.get("price", 0))
	var message: String = "P%d bought %s for $%d" % [player_id + 1, tile_name, price]
	if _board != null and tile_index >= 0:
		_board.set_property_owner(tile_index, player_id)
	_update_money_label()
	_update_event_label(message)
	_add_event_log_line(message)
	if _ui != null:
		_ui.hide_property_actions()


func _handle_property_purchase_skipped(payload: Dictionary) -> void:
	var player_id: int = int(payload.get("player_id", -1))
	var tile_name: String = str(payload.get("tile_name", "property"))
	var reason: String = str(payload.get("reason", "skipped"))
	var message: String = "P%d skipped %s" % [player_id + 1, tile_name]
	if reason == "insufficient_funds":
		message = "P%d cannot afford %s" % [player_id + 1, tile_name]

	_update_event_label(message)
	_add_event_log_line(message)
	if _ui != null:
		_ui.hide_property_actions()


func _play_queued_map_animations() -> void:
	while not _map_animation_queue.is_empty():
		var queued_movement: Dictionary = _map_animation_queue[0]
		_map_animation_queue.remove_at(0)
		var player_id: int = int(queued_movement.get("player_id", -1))
		var path_positions: Array[Vector2i] = _get_grid_positions(queued_movement.get("path_positions", []))
		var piece: PlayerPiece = _get_visual_piece(player_id)
		if piece == null:
			continue

		for grid_position in path_positions:
			var tween := create_tween()
			tween.tween_property(piece, "position", _get_grid_canvas_position(grid_position) + _get_piece_offset(player_id), MAP_STEP_DURATION)
			await tween.finished

	_is_animating_map_movement = false
	_show_pending_route_choice()
	_update_roll_availability()


func _show_pending_route_choice() -> void:
	if _pending_route_choice_payload.is_empty() or _ui == null:
		return

	var player_id: int = int(_pending_route_choice_payload.get("player_id", -1))
	var remaining_steps: int = int(_pending_route_choice_payload.get("remaining_steps", 0))
	var directions: PackedInt32Array = _to_packed_int32_array(_pending_route_choice_payload.get("directions", PackedInt32Array()))
	var message: String = "P%d is choosing a route (%d steps left)" % [player_id + 1, remaining_steps]
	_update_event_label(message)
	_add_event_log_line(message)
	if NetworkManager.can_control_player(player_id):
		_ui.show_grid_route_actions(directions)
	else:
		_ui.hide_route_actions()
	_pending_route_choice_payload.clear()


func _register_visual_pieces() -> void:
	_visual_pieces_by_player_id.clear()
	if _pieces_root == null:
		push_error("StarQGame requires a Pieces child.")
		return

	for child in _pieces_root.get_children():
		var piece: PlayerPiece = child as PlayerPiece
		if piece != null:
			_visual_pieces_by_player_id[piece.player_id] = piece


func _sync_piece_positions() -> void:
	if GameManager.state == null:
		return

	for player_id in GameManager.state.player_order:
		var player_map_state: PlayerMapState = GameManager.state.get_player_map_state(player_id)
		if player_map_state != null:
			var player: PlayerState = GameManager.state.get_player(player_id)
			var piece: PlayerPiece = _get_visual_piece(player_id)
			if player != null and piece != null:
				piece.set_display_name(player.display_name)
			_place_piece_at(player_id, player_map_state.grid_position)


func _sync_property_owner_visuals() -> void:
	if _board != null and GameManager.state != null:
		_board.set_property_owners(GameManager.state.property_owner_by_tile)


func _place_piece_at(player_id: int, grid_position: Vector2i) -> void:
	var piece: PlayerPiece = _get_visual_piece(player_id)
	if piece != null:
		piece.move_to(_get_grid_canvas_position(grid_position) + _get_piece_offset(player_id))


func _get_grid_canvas_position(grid_position: Vector2i) -> Vector2:
	var grid_step: Vector2 = _board.tile_size * 0.5
	return Vector2(grid_position.x * grid_step.x, (grid_position.y - 1) * grid_step.y)


func _get_piece_offset(player_id: int) -> Vector2:
	return PIECE_OFFSETS[posmod(player_id, PIECE_OFFSETS.size())]


func _get_visual_piece(player_id: int) -> PlayerPiece:
	if not _visual_pieces_by_player_id.has(player_id):
		return null

	return _visual_pieces_by_player_id[player_id] as PlayerPiece


func _get_grid_positions(raw_positions: Variant) -> Array[Vector2i]:
	var grid_positions: Array[Vector2i] = []
	if not (raw_positions is Array):
		return grid_positions

	var position_entries: Array = raw_positions
	for raw_position in position_entries:
		if raw_position is Vector2i:
			grid_positions.append(raw_position)
		elif raw_position is Array:
			var position_values: Array = raw_position
			if position_values.size() == 2:
				grid_positions.append(Vector2i(int(position_values[0]), int(position_values[1])))

	return grid_positions


func _to_packed_int32_array(raw_values: Variant) -> PackedInt32Array:
	if raw_values is PackedInt32Array:
		return raw_values

	var values := PackedInt32Array()
	if raw_values is Array:
		for raw_value in raw_values:
			values.append(int(raw_value))

	return values


func _update_dice_label(dice_value: int) -> void:
	if _ui == null:
		return

	_ui.set_dice_text("Dice: -" if dice_value <= 0 else "Dice: %d" % dice_value)


func _update_tile_label(player_id: int, tile_name: String) -> void:
	if _ui == null:
		return

	_ui.set_tile_text("Landed: -" if player_id < 0 else "Player %d landed on %s" % [player_id + 1, tile_name])


func _update_money_label() -> void:
	if _ui == null or GameManager.state == null:
		return

	var money_text := ""
	for player_id in GameManager.state.player_order:
		var player: PlayerState = GameManager.state.get_player(player_id)
		if player == null:
			continue
		if not money_text.is_empty():
			money_text += "  "
		money_text += "P%d $%d" % [player_id + 1, player.money]

	_ui.set_money_text("Money: %s" % money_text)


func _update_event_label(message: String) -> void:
	if _ui != null:
		_ui.set_event_text("Event: -" if message.is_empty() else message)


func _update_log_label() -> void:
	if _ui == null:
		return

	_ui.set_log_text("Log: -" if _event_log.is_empty() else "\n".join(_event_log))


func _add_event_log_line(message: String) -> void:
	if message.is_empty():
		return

	_event_log.append(message)
	while _event_log.size() > MAX_EVENT_LOG_LINES:
		_event_log.remove_at(0)
	_update_log_label()


func _on_network_status_changed(message: String) -> void:
	if _ui != null:
		_ui.set_network_status_text("Network: %s" % message)
	if not NetworkManager.is_client():
		_clear_pending_client_intent()


func _on_network_intent_accepted(_intent_type: String, _request_id: int) -> void:
	_clear_pending_client_intent()
	_update_money_label()
	_update_roll_availability()
	_refresh_pending_action_controls()
	_refresh_card_hand()


func _on_network_intent_rejected(intent_type: String, reason: String, _request_id: int) -> void:
	_clear_pending_client_intent()
	if _is_stale_property_rejection(intent_type, reason):
		_update_roll_availability()
		_refresh_pending_action_controls()
		_refresh_card_hand()
		return

	var message := "Rejected %s: %s" % [intent_type, reason]
	_update_event_label(message)
	_add_event_log_line(message)
	_update_roll_availability()
	_refresh_pending_action_controls()
	_refresh_card_hand()


func _on_network_local_player_changed(_player_id: int) -> void:
	_update_roll_availability()
	_refresh_pending_action_controls()
	_refresh_card_hand()


func _on_network_state_snapshot_received(snapshot: Dictionary) -> void:
	var board_data := _get_board_data()
	if board_data == null:
		return

	_clear_pending_client_intent()
	var is_first_snapshot := not _has_received_network_snapshot
	_has_received_network_snapshot = true
	if is_first_snapshot and NetworkManager.is_client():
		_event_log.clear()
		_pending_route_choice_payload.clear()
		_map_animation_queue.clear()
		_is_animating_map_movement = false

	GameManager.restore_state_snapshot(snapshot, board_data)
	_refresh_from_state_snapshot(snapshot, is_first_snapshot and NetworkManager.is_client())
	if is_first_snapshot and NetworkManager.is_client():
		var revision := NetworkManager.get_snapshot_revision(snapshot)
		if revision >= 0:
			_add_event_log_line("Synced snapshot #%d from host" % revision)
		else:
			_add_event_log_line("Synced snapshot from host")


func _refresh_from_state_snapshot(snapshot: Dictionary = {}, apply_snapshot_log: bool = false) -> void:
	if GameManager.state == null:
		return

	if _ui != null:
		_ui.set_round_text("Round %d" % GameManager.state.current_round)
		var current_player_id := GameManager.state.get_current_player_id()
		if current_player_id >= 0:
			_ui.set_turn_text("Player %d Turn" % [current_player_id + 1])

	_update_money_label()
	_sync_property_owner_visuals()
	if not _is_animating_map_movement and _map_animation_queue.is_empty():
		_sync_piece_positions()
	_apply_snapshot_ui_summary(snapshot, apply_snapshot_log)

	_roll_is_ready = _can_local_roll()
	_refresh_pending_action_controls()
	_update_roll_availability()
	_refresh_card_hand()


func _apply_snapshot_ui_summary(snapshot: Dictionary, apply_snapshot_log: bool) -> void:
	var raw_summary: Variant = snapshot.get(GameManager.SNAPSHOT_UI_SUMMARY_KEY, {})
	if not (raw_summary is Dictionary):
		return

	var summary: Dictionary = raw_summary
	var raw_dice: Variant = summary.get(GameManager.UI_SUMMARY_LAST_DICE_KEY, {})
	if raw_dice is Dictionary:
		var dice_data: Dictionary = raw_dice
		if not dice_data.is_empty():
			_update_dice_label(int(dice_data.get("dice_value", 0)))

	var raw_landing: Variant = summary.get(GameManager.UI_SUMMARY_LAST_LANDING_KEY, {})
	if raw_landing is Dictionary:
		var landing_data: Dictionary = raw_landing
		if not landing_data.is_empty():
			var player_id: int = int(landing_data.get("player_id", -1))
			var tile_name: String = str(landing_data.get("tile_name", "Unknown"))
			_update_tile_label(player_id, tile_name)

	_update_event_label(str(summary.get(GameManager.UI_SUMMARY_EVENT_MESSAGE_KEY, "")))
	if apply_snapshot_log:
		_event_log.clear()
		var raw_log_lines: Variant = summary.get(GameManager.UI_SUMMARY_LOG_LINES_KEY, [])
		if raw_log_lines is Array:
			for raw_line in raw_log_lines:
				_add_event_log_line(str(raw_line))


func _refresh_pending_action_controls() -> void:
	if _ui == null or GameManager.state == null:
		return

	if GameManager.state.has_pending_property_purchase():
		var player_id := int(GameManager.state.pending_property_purchase.get("player_id", -1))
		if NetworkManager.can_control_player(player_id):
			_ui.show_property_actions()
		else:
			_ui.hide_property_actions()
		return

	_ui.hide_property_actions()
	if GameManager.state.has_pending_grid_movement() and GameManager.state.pending_grid_movement.is_waiting_for_route_choice():
		var movement_state: GridMovementState = GameManager.state.pending_grid_movement
		_pending_route_choice_payload = {
			"player_id": movement_state.player_id,
			"grid_position": movement_state.current_grid_position,
			"directions": movement_state.available_next_directions.duplicate(),
			"remaining_steps": movement_state.remaining_steps,
		}
		if not _is_animating_map_movement:
			_show_pending_route_choice()
		return

	_ui.hide_route_actions()
	_refresh_card_hand()


func _refresh_card_hand() -> void:
	if _ui == null:
		return

	var card_definition: CardDefinition = GameManager.card_service.create_prototype_pre_roll_card()
	var metadata: Dictionary = card_definition.get_visible_metadata()
	var is_playable := false
	var acting_player_id := -1
	var target_player_id := -1
	var window_id := CardDefinition.TIMING_PRE_ROLL

	if GameManager.state != null and GameManager.state.has_pending_intervention():
		var pending_intervention: Dictionary = GameManager.state.pending_intervention
		acting_player_id = int(pending_intervention.get("acting_player_id", -1))
		target_player_id = int(pending_intervention.get("target_player_id", -1))
		window_id = _get_string_name(pending_intervention.get("window_id", CardDefinition.TIMING_PRE_ROLL))
		var card_id := _get_string_name(pending_intervention.get("card_id", &""))
		is_playable = (
			card_id == CardService.CARD_PROTOTYPE_PRE_ROLL_GRANT
			and window_id == CardDefinition.TIMING_PRE_ROLL
			and acting_player_id >= 0
			and GameManager.state.has_card_in_hand(acting_player_id, card_id)
			and NetworkManager.can_control_player(acting_player_id)
			and not _has_pending_client_intent()
		)

	_ui.set_card_hand_state(metadata, is_playable, acting_player_id, window_id, target_player_id)


func _get_string_name(value: Variant) -> StringName:
	if value == null:
		return &""

	var text := str(value).strip_edges()
	if text.is_empty():
		return &""

	return StringName(text)


func _get_board_data() -> BoardData:
	if _board == null:
		return null

	return _board.board_data as BoardData


func _has_pending_client_intent() -> bool:
	return NetworkManager.is_client() and not _pending_network_intent_type.is_empty()


func _begin_pending_client_intent(intent_type: String) -> void:
	if not NetworkManager.is_client():
		return

	_pending_network_intent_type = intent_type
	match intent_type:
		NetworkManager.INTENT_ROLL:
			_roll_is_ready = false
		NetworkManager.INTENT_GRID_ROUTE_CHOICE:
			_pending_route_choice_payload.clear()
			if _ui != null:
				_ui.hide_route_actions()
		NetworkManager.INTENT_BUY_PROPERTY, NetworkManager.INTENT_SKIP_PROPERTY:
			if _ui != null:
				_ui.hide_property_actions()
		NetworkManager.INTENT_PLAY_CARD:
			_refresh_card_hand()

	_update_roll_availability()


func _clear_pending_client_intent() -> void:
	if _pending_network_intent_type.is_empty():
		return

	_pending_network_intent_type = ""


func _is_stale_property_rejection(intent_type: String, reason: String) -> bool:
	if reason != "no property decision pending":
		return false

	if intent_type != NetworkManager.INTENT_BUY_PROPERTY and intent_type != NetworkManager.INTENT_SKIP_PROPERTY:
		return false

	return GameManager.state != null and not GameManager.state.has_pending_property_purchase()


func _update_roll_availability() -> void:
	if _ui == null:
		return

	var can_control_current_player := true
	if GameManager.state != null:
		can_control_current_player = NetworkManager.can_control_player(GameManager.state.get_current_player_id())

	_ui.set_roll_allowed(_roll_is_ready and can_control_current_player and _can_local_roll() and not _has_pending_client_intent() and not _is_animating_map_movement and _pending_route_choice_payload.is_empty())


func _can_local_roll() -> bool:
	if GameManager.state == null:
		return false

	if not GameManager.turn_system.can_roll():
		return false

	if GameManager.state.has_pending_movement() or GameManager.state.has_pending_grid_movement():
		return false

	if GameManager.state.has_pending_property_purchase():
		return false

	return NetworkManager.can_control_player(GameManager.state.get_current_player_id())
