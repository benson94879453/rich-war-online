extends Node


const SNAPSHOT_TURN_PHASE_KEY := "turn_phase"
const SNAPSHOT_UI_SUMMARY_KEY := "ui_summary"
const UI_SUMMARY_LAST_DICE_KEY := "last_dice_roll"
const UI_SUMMARY_LAST_LANDING_KEY := "last_landing"
const UI_SUMMARY_EVENT_MESSAGE_KEY := "event_message"
const UI_SUMMARY_LOG_LINES_KEY := "log_lines"
const UI_SUMMARY_LOG_LINE_LIMIT := 20


var state: GameState
var board_data: BoardData
var board_navigator: BoardNavigator = BoardNavigator.new()
var grid_movement_system: GridMovementSystem = GridMovementSystem.new()
var tile_effect_resolver: TileEffectResolver = TileEffectResolver.new()
var turn_system: TurnSystem = TurnSystem.new()
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _last_dice_roll: Dictionary = {}
var _last_landing: Dictionary = {}
var _last_event_message: String = ""
var _snapshot_log_lines: Array[String] = []


func _ready() -> void:
	_rng.randomize()


func start_local_game(players: Array[PlayerState], data: BoardData) -> void:
	_reset_snapshot_ui_summary()
	state = GameState.new()
	state.initialize(players)
	board_data = data
	board_navigator.set_board_data(data)
	var map_grid: BoardMapGridData = data.get_map_grid()
	if map_grid != null:
		grid_movement_system.set_map_grid(map_grid)
		state.initialize_player_map_states(data)
	turn_system.reset()
	if state.has_pending_movement() and state.pending_movement.is_waiting_for_route_choice():
		turn_system.begin_route_decision()

	_emit(GameEvent.GAME_STARTED, {"state": state.to_dict()})
	_emit(GameEvent.ROUND_STARTED, {"round": state.current_round})
	_emit_current_turn_started()


func request_roll() -> bool:
	if state == null or board_data == null or not turn_system.can_roll() or state.has_pending_movement() or state.has_pending_grid_movement():
		return false

	if _uses_grid_map():
		return _request_grid_roll()

	var player_id: int = state.get_current_player_id()
	var player: PlayerState = state.get_current_player()
	if player == null:
		return false

	var dice_value: int = _rng.randi_range(1, 6)
	_emit(GameEvent.DICE_ROLLED, {
		"player_id": player_id,
		"dice_value": dice_value,
	})
	state.begin_movement(MovementState.new(player_id, player.tile_index, player.entered_from_tile_index, dice_value))
	return _advance_pending_movement()


func request_route_choice(next_tile_index: int) -> bool:
	if _uses_grid_map():
		return false

	if state == null or board_data == null or not turn_system.can_resolve_route_choice():
		return false

	if not state.has_pending_movement():
		return false

	var movement_state: MovementState = state.pending_movement
	if movement_state.player_id != state.get_current_player_id():
		return false

	var player: PlayerState = state.get_player(movement_state.player_id)
	if player == null:
		state.clear_pending_movement()
		return false

	var previous_tile_index: int = player.tile_index
	var choice_result: BoardMoveResult = board_navigator.choose_route(movement_state, next_tile_index)
	if choice_result.is_blocked():
		return false

	player.move_to_tile(movement_state.current_tile_index, movement_state.entered_from_tile_index)
	_emit(GameEvent.PLAYER_MOVED, {
		"player_id": player.player_id,
		"from_tile_index": previous_tile_index,
		"to_tile_index": movement_state.current_tile_index,
		"path_tile_indices": choice_result.path_tile_indices.duplicate(),
	})
	turn_system.continue_after_route_choice()
	return _advance_pending_movement()


func request_grid_route_choice(direction: int) -> bool:
	if state == null or board_data == null or not _uses_grid_map() or not turn_system.can_resolve_route_choice():
		return false

	if not state.has_pending_grid_movement():
		return false

	var movement_state: GridMovementState = state.pending_grid_movement
	if movement_state.player_id != state.get_current_player_id():
		return false

	var player_map_state: PlayerMapState = state.get_player_map_state(movement_state.player_id)
	if player_map_state == null:
		state.clear_pending_grid_movement()
		return false

	var previous_grid_position: Vector2i = player_map_state.grid_position
	var choice_result: GridMoveResult = grid_movement_system.choose_route(movement_state, direction)
	if choice_result.is_blocked():
		return false

	_update_player_map_state_from_movement(movement_state)
	_emit_grid_movement_if_needed(movement_state.player_id, previous_grid_position, choice_result)
	turn_system.continue_after_route_choice()
	return _advance_pending_grid_movement()


func request_buy_pending_property() -> bool:
	if state == null or board_data == null or not turn_system.can_resolve_property_decision():
		return false

	if not state.has_pending_property_purchase():
		return false

	var player_id: int = int(state.pending_property_purchase["player_id"])
	var tile_index: int = int(state.pending_property_purchase["tile_index"])
	var player: PlayerState = state.get_player(player_id)
	var tile_data: BoardTileData = board_data.get_tile(tile_index)
	if player == null or tile_data == null:
		_complete_property_decision(player_id)
		return true

	if player.money < tile_data.price:
		_emit(GameEvent.PROPERTY_PURCHASE_SKIPPED, {
			"player_id": player_id,
			"tile_index": tile_index,
			"tile_name": tile_data.display_name,
			"reason": "insufficient_funds",
		})
		_complete_property_decision(player_id)
		return true

	player.add_money(-tile_data.price)
	state.set_property_owner(tile_index, player_id)
	_emit(GameEvent.PROPERTY_PURCHASED, {
		"player_id": player_id,
		"tile_index": tile_index,
		"tile_name": tile_data.display_name,
		"price": tile_data.price,
		"money": player.money,
	})
	_complete_property_decision(player_id)
	return true


func request_skip_pending_property() -> bool:
	if state == null or board_data == null or not turn_system.can_resolve_property_decision():
		return false

	if not state.has_pending_property_purchase():
		return false

	var player_id: int = int(state.pending_property_purchase["player_id"])
	var tile_index: int = int(state.pending_property_purchase["tile_index"])
	var tile_data: BoardTileData = board_data.get_tile(tile_index)
	_emit(GameEvent.PROPERTY_PURCHASE_SKIPPED, {
		"player_id": player_id,
		"tile_index": tile_index,
		"tile_name": _get_tile_name(tile_data),
		"reason": "skipped",
	})
	_complete_property_decision(player_id)
	return true


func get_state_snapshot() -> Dictionary:
	if state == null:
		return {}

	var snapshot := state.to_dict()
	snapshot[SNAPSHOT_TURN_PHASE_KEY] = turn_system.get_phase()
	snapshot[SNAPSHOT_UI_SUMMARY_KEY] = _get_snapshot_ui_summary()
	return snapshot


func restore_state_snapshot(snapshot: Dictionary, data: BoardData) -> void:
	state = GameState.from_dict(snapshot)
	board_data = data
	board_navigator.set_board_data(data)
	var map_grid: BoardMapGridData = data.get_map_grid()
	if map_grid != null:
		grid_movement_system.set_map_grid(map_grid)
	_restore_turn_phase_from_snapshot(snapshot)
	_restore_snapshot_ui_summary(snapshot)


func _restore_turn_phase_from_snapshot(snapshot: Dictionary) -> void:
	if snapshot.has(SNAPSHOT_TURN_PHASE_KEY):
		turn_system.restore_phase(int(snapshot.get(SNAPSHOT_TURN_PHASE_KEY, TurnSystem.Phase.ROLL)))
		return

	turn_system.reset()
	if state.has_pending_property_purchase():
		turn_system.begin_property_decision()
	elif state.has_pending_movement() and state.pending_movement.is_waiting_for_route_choice():
		turn_system.begin_route_decision()
	elif state.has_pending_grid_movement() and state.pending_grid_movement.is_waiting_for_route_choice():
		turn_system.begin_route_decision()


func _request_grid_roll() -> bool:
	var player_id: int = state.get_current_player_id()
	var player_map_state: PlayerMapState = state.get_player_map_state(player_id)
	if player_map_state == null or not player_map_state.is_valid():
		return false

	var dice_value: int = _rng.randi_range(1, 6)
	_emit(GameEvent.DICE_ROLLED, {
		"player_id": player_id,
		"dice_value": dice_value,
	})
	state.begin_grid_movement(GridMovementState.new(player_id, player_map_state.grid_position, player_map_state.direction, dice_value))
	return _advance_pending_grid_movement()


func _advance_pending_grid_movement() -> bool:
	if state == null or not state.has_pending_grid_movement():
		return false

	var movement_state: GridMovementState = state.pending_grid_movement
	var player: PlayerState = state.get_player(movement_state.player_id)
	var player_map_state: PlayerMapState = state.get_player_map_state(movement_state.player_id)
	if player == null or player_map_state == null:
		state.clear_pending_grid_movement()
		return false

	var previous_grid_position: Vector2i = player_map_state.grid_position
	var move_result: GridMoveResult = grid_movement_system.advance_movement(movement_state)
	if move_result.is_blocked():
		var map_grid: BoardMapGridData = board_data.get_map_grid()
		var blocked_node_id: int = map_grid.get_node_id(move_result.blocked_grid_position) if map_grid != null else -1
		push_error("Map movement is blocked at node %d (%d, %d)." % [blocked_node_id, move_result.blocked_grid_position.x, move_result.blocked_grid_position.y])
		state.clear_pending_grid_movement()
		return false

	_update_player_map_state_from_movement(movement_state)
	_emit_grid_movement_if_needed(movement_state.player_id, previous_grid_position, move_result)

	if move_result.requires_route_choice():
		turn_system.begin_route_decision()
		_emit(GameEvent.MAP_ROUTE_CHOICE_REQUESTED, {
			"player_id": player.player_id,
			"grid_position": movement_state.current_grid_position,
			"directions": move_result.route_choice_directions.duplicate(),
			"remaining_steps": movement_state.remaining_steps,
		})
		return true

	if not move_result.is_complete():
		push_warning("Grid movement accepted but did not complete or request a route choice.")
		return true

	state.clear_pending_grid_movement()
	_resolve_grid_landing(player, player_map_state, movement_state.rolled_steps)
	return true


func _update_player_map_state_from_movement(movement_state: GridMovementState) -> void:
	var player_map_state: PlayerMapState = state.get_player_map_state(movement_state.player_id)
	if player_map_state != null:
		player_map_state.move_to(movement_state.current_grid_position, movement_state.travel_direction)


func _emit_grid_movement_if_needed(player_id: int, previous_grid_position: Vector2i, move_result: GridMoveResult) -> void:
	if move_result.path_grid_positions.is_empty():
		return

	_emit(GameEvent.MAP_PLAYER_MOVED, {
		"player_id": player_id,
		"from_grid_position": previous_grid_position,
		"to_grid_position": move_result.current_grid_position,
		"path_grid_positions": move_result.visual_path_grid_positions.duplicate(),
	})


func _resolve_grid_landing(player: PlayerState, player_map_state: PlayerMapState, dice_value: int) -> void:
	var map_grid: BoardMapGridData = board_data.get_map_grid()
	var node_id: int = map_grid.get_node_id(player_map_state.grid_position) if map_grid != null else -1
	var tile_index: int = board_data.get_tile_index_for_source_node_id(node_id)
	var tile_data: BoardTileData = board_data.get_tile(tile_index) if tile_index >= 0 else null
	if tile_data != null:
		player.move_to_tile(tile_index)

	_emit(GameEvent.MAP_PLAYER_LANDED, {
		"player_id": player.player_id,
		"grid_position": player_map_state.grid_position,
		"node_id": node_id,
		"tile_index": tile_index,
		"tile_name": _get_tile_name(tile_data) if tile_data != null else "Road",
		"dice_value": dice_value,
	})
	if _begin_property_purchase_if_available(player.player_id, tile_data):
		return

	_apply_rent_if_owed(player, tile_data)
	_resolve_tile_effect(player, tile_data)
	_complete_turn(player.player_id)


func _uses_grid_map() -> bool:
	return board_data != null and board_data.get_map_grid() != null


func _advance_pending_movement() -> bool:
	if state == null or not state.has_pending_movement():
		return false

	var movement_state: MovementState = state.pending_movement
	var player: PlayerState = state.get_player(movement_state.player_id)
	if player == null:
		state.clear_pending_movement()
		return false

	var previous_tile_index: int = player.tile_index
	var move_result: BoardMoveResult = board_navigator.advance_movement(movement_state)
	if move_result.is_blocked():
		push_error("Movement is blocked at tile %d." % move_result.blocked_tile_index)
		state.clear_pending_movement()
		return false

	if not move_result.path_tile_indices.is_empty():
		player.move_to_tile(movement_state.current_tile_index, movement_state.entered_from_tile_index)
		_emit(GameEvent.PLAYER_MOVED, {
			"player_id": player.player_id,
			"from_tile_index": previous_tile_index,
			"to_tile_index": movement_state.current_tile_index,
			"path_tile_indices": move_result.path_tile_indices.duplicate(),
		})

	if move_result.requires_route_choice():
		turn_system.begin_route_decision()
		_emit(GameEvent.ROUTE_CHOICE_REQUESTED, {
			"player_id": player.player_id,
			"tile_index": movement_state.current_tile_index,
			"next_tile_indices": move_result.route_choice_tile_indices.duplicate(),
			"remaining_steps": movement_state.remaining_steps,
		})
		return true

	if not move_result.is_complete():
		push_warning("Movement accepted but did not complete or request a route choice.")
		return true

	state.clear_pending_movement()
	_resolve_landing(player, movement_state.rolled_steps)
	return true


func _resolve_landing(player: PlayerState, dice_value: int) -> void:
	var landed_tile_data: BoardTileData = board_data.get_tile(player.tile_index)
	_emit(GameEvent.PLAYER_LANDED, {
		"player_id": player.player_id,
		"tile_index": player.tile_index,
		"tile_name": _get_tile_name(landed_tile_data),
		"dice_value": dice_value,
	})

	if _begin_property_purchase_if_available(player.player_id, landed_tile_data):
		return

	_apply_rent_if_owed(player, landed_tile_data)
	_resolve_tile_effect(player, landed_tile_data)
	_complete_turn(player.player_id)


func _begin_property_purchase_if_available(player_id: int, tile_data: BoardTileData) -> bool:
	if tile_data == null or not tile_data.is_property():
		return false

	if state.get_property_owner(tile_data.index) != -1:
		return false

	state.begin_property_purchase(player_id, tile_data.index)
	turn_system.begin_property_decision()
	_emit(GameEvent.PROPERTY_PURCHASE_OFFERED, {
		"player_id": player_id,
		"tile_index": tile_data.index,
		"tile_name": tile_data.display_name,
		"price": tile_data.price,
	})
	return true


func _apply_rent_if_owed(payer: PlayerState, tile_data: BoardTileData) -> void:
	if payer == null or tile_data == null or not tile_data.is_property():
		return

	var owner_id: int = state.get_property_owner(tile_data.index)
	if owner_id == -1 or owner_id == payer.player_id:
		return

	var property_owner: PlayerState = state.get_player(owner_id)
	var rent_amount: int = tile_data.get_base_rent()
	if property_owner == null or rent_amount <= 0:
		return

	payer.add_money(-rent_amount)
	property_owner.add_money(rent_amount)
	_emit(GameEvent.RENT_PAID, {
		"payer_id": payer.player_id,
		"owner_id": owner_id,
		"tile_index": tile_data.index,
		"tile_name": tile_data.display_name,
		"amount": rent_amount,
		"payer_money": payer.money,
		"owner_money": property_owner.money,
	})


func _resolve_tile_effect(player: PlayerState, tile_data: BoardTileData) -> void:
	var resolution: TileEffectResolution = tile_effect_resolver.resolve(player, tile_data)
	if not resolution.was_applied:
		return

	_emit(GameEvent.TILE_EFFECT_RESOLVED, {
		"player_id": player.player_id,
		"tile_index": tile_data.index,
		"tile_name": tile_data.display_name,
		"effect_id": tile_data.effect_id,
		"money_delta": resolution.money_delta,
		"money_after": resolution.money_after,
	})


func _complete_property_decision(player_id: int) -> void:
	state.clear_pending_property_purchase()
	_complete_turn(player_id)


func _complete_turn(player_id: int) -> void:
	_emit(GameEvent.TURN_ENDED, {"player_id": player_id})
	var began_new_round: bool = turn_system.complete_turn(state)
	if began_new_round:
		_emit(GameEvent.ROUND_STARTED, {"round": state.current_round})

	_emit_current_turn_started()


func _emit_current_turn_started() -> void:
	_emit(GameEvent.TURN_STARTED, {
		"player_id": state.get_current_player_id(),
		"round": state.current_round,
	})


func _reset_snapshot_ui_summary() -> void:
	_last_dice_roll.clear()
	_last_landing.clear()
	_last_event_message = ""
	_snapshot_log_lines.clear()


func _get_snapshot_ui_summary() -> Dictionary:
	return {
		UI_SUMMARY_LAST_DICE_KEY: _last_dice_roll.duplicate(true),
		UI_SUMMARY_LAST_LANDING_KEY: _last_landing.duplicate(true),
		UI_SUMMARY_EVENT_MESSAGE_KEY: _last_event_message,
		UI_SUMMARY_LOG_LINES_KEY: _snapshot_log_lines.duplicate(),
	}


func _restore_snapshot_ui_summary(snapshot: Dictionary) -> void:
	_reset_snapshot_ui_summary()
	var raw_summary: Variant = snapshot.get(SNAPSHOT_UI_SUMMARY_KEY, {})
	if not (raw_summary is Dictionary):
		return

	var summary: Dictionary = raw_summary
	var raw_dice: Variant = summary.get(UI_SUMMARY_LAST_DICE_KEY, {})
	if raw_dice is Dictionary:
		var dice_summary: Dictionary = raw_dice
		_last_dice_roll = dice_summary.duplicate(true)

	var raw_landing: Variant = summary.get(UI_SUMMARY_LAST_LANDING_KEY, {})
	if raw_landing is Dictionary:
		var landing_summary: Dictionary = raw_landing
		_last_landing = landing_summary.duplicate(true)

	_last_event_message = str(summary.get(UI_SUMMARY_EVENT_MESSAGE_KEY, ""))
	var raw_log_lines: Variant = summary.get(UI_SUMMARY_LOG_LINES_KEY, [])
	if raw_log_lines is Array:
		for raw_line in raw_log_lines:
			_append_snapshot_log_line(str(raw_line))


func _record_snapshot_ui_summary(event_type: String, payload: Dictionary) -> void:
	match event_type:
		GameEvent.ROUND_STARTED:
			_record_round_started_summary(payload)
		GameEvent.DICE_ROLLED:
			_last_dice_roll = payload.duplicate(true)
		GameEvent.PLAYER_LANDED:
			_last_landing = payload.duplicate(true)
			_last_event_message = ""
			_append_snapshot_log_line(_get_player_landed_summary(payload))
		GameEvent.MAP_PLAYER_LANDED:
			_last_landing = payload.duplicate(true)
			_last_event_message = ""
			_append_snapshot_log_line(_get_map_player_landed_summary(payload))
		GameEvent.TILE_EFFECT_RESOLVED:
			_set_snapshot_event_message(_get_tile_effect_summary(payload))
		GameEvent.RENT_PAID:
			_set_snapshot_event_message(_get_rent_paid_summary(payload))
		GameEvent.PROPERTY_PURCHASE_OFFERED:
			_set_snapshot_event_message(_get_property_purchase_offered_summary(payload))
		GameEvent.PROPERTY_PURCHASED:
			_set_snapshot_event_message(_get_property_purchased_summary(payload))
		GameEvent.PROPERTY_PURCHASE_SKIPPED:
			_set_snapshot_event_message(_get_property_purchase_skipped_summary(payload))


func _record_round_started_summary(payload: Dictionary) -> void:
	var round_number: int = int(payload.get("round", 1))
	if round_number > 1:
		_append_snapshot_log_line("Round %d begins" % round_number)


func _get_player_landed_summary(payload: Dictionary) -> String:
	var player_id: int = int(payload.get("player_id", -1))
	var dice_value: int = int(payload.get("dice_value", 0))
	var tile_index: int = int(payload.get("tile_index", -1))
	var tile_name: String = str(payload.get("tile_name", "Unknown"))
	return "P%d rolled %d -> tile %02d %s" % [player_id + 1, dice_value, tile_index, tile_name]


func _get_map_player_landed_summary(payload: Dictionary) -> String:
	var player_id: int = int(payload.get("player_id", -1))
	var dice_value: int = int(payload.get("dice_value", 0))
	var node_id: int = int(payload.get("node_id", -1))
	var tile_name: String = str(payload.get("tile_name", "Unknown"))
	return "P%d rolled %d -> node %d %s" % [player_id + 1, dice_value, node_id, tile_name]


func _get_tile_effect_summary(payload: Dictionary) -> String:
	var player_id: int = int(payload.get("player_id", -1))
	var tile_name: String = str(payload.get("tile_name", "tile"))
	var money_delta: int = int(payload.get("money_delta", 0))
	var delta_text: String = "+$%d" % money_delta if money_delta >= 0 else "-$%d" % abs(money_delta)
	var verb: String = "received" if money_delta >= 0 else "lost"
	return "P%d %s %s on %s" % [player_id + 1, verb, delta_text, tile_name]


func _get_rent_paid_summary(payload: Dictionary) -> String:
	var payer_id: int = int(payload.get("payer_id", -1))
	var owner_id: int = int(payload.get("owner_id", -1))
	var amount: int = int(payload.get("amount", 0))
	var tile_name: String = str(payload.get("tile_name", "property"))
	return "P%d paid P%d $%d rent for %s" % [payer_id + 1, owner_id + 1, amount, tile_name]


func _get_property_purchase_offered_summary(payload: Dictionary) -> String:
	var player_id: int = int(payload.get("player_id", -1))
	var tile_name: String = str(payload.get("tile_name", "property"))
	var price: int = int(payload.get("price", 0))
	return "P%d can buy %s for $%d" % [player_id + 1, tile_name, price]


func _get_property_purchased_summary(payload: Dictionary) -> String:
	var player_id: int = int(payload.get("player_id", -1))
	var tile_name: String = str(payload.get("tile_name", "property"))
	var price: int = int(payload.get("price", 0))
	return "P%d bought %s for $%d" % [player_id + 1, tile_name, price]


func _get_property_purchase_skipped_summary(payload: Dictionary) -> String:
	var player_id: int = int(payload.get("player_id", -1))
	var tile_name: String = str(payload.get("tile_name", "property"))
	var reason: String = str(payload.get("reason", "skipped"))
	if reason == "insufficient_funds":
		return "P%d cannot afford %s" % [player_id + 1, tile_name]

	return "P%d skipped %s" % [player_id + 1, tile_name]


func _set_snapshot_event_message(message: String) -> void:
	_last_event_message = message
	_append_snapshot_log_line(message)


func _append_snapshot_log_line(message: String) -> void:
	if message.is_empty():
		return

	_snapshot_log_lines.append(message)
	while _snapshot_log_lines.size() > UI_SUMMARY_LOG_LINE_LIMIT:
		_snapshot_log_lines.remove_at(0)


func _emit(event_type: String, payload: Dictionary) -> void:
	_record_snapshot_ui_summary(event_type, payload)
	EventBus.emit_game_event(GameEvent.new(event_type, payload))


func _get_tile_name(tile_data: BoardTileData) -> String:
	if tile_data == null:
		return "Unknown"

	return tile_data.display_name
