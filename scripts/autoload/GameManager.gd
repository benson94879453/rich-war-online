extends Node


const SNAPSHOT_TURN_PHASE_KEY := "turn_phase"
const SNAPSHOT_UI_SUMMARY_KEY := "ui_summary"
const SnapshotSummaryTrackerScript := preload("res://scripts/core/SnapshotSummaryTracker.gd")
const PropertyResolutionServiceScript := preload("res://scripts/core/PropertyResolutionService.gd")
const LandingResolutionServiceScript := preload("res://scripts/core/LandingResolutionService.gd")
const UI_SUMMARY_LAST_DICE_KEY := SnapshotSummaryTrackerScript.LAST_DICE_KEY
const UI_SUMMARY_LAST_LANDING_KEY := SnapshotSummaryTrackerScript.LAST_LANDING_KEY
const UI_SUMMARY_EVENT_MESSAGE_KEY := SnapshotSummaryTrackerScript.EVENT_MESSAGE_KEY
const UI_SUMMARY_LOG_LINES_KEY := SnapshotSummaryTrackerScript.LOG_LINES_KEY
const UI_SUMMARY_LOG_LINE_LIMIT := SnapshotSummaryTrackerScript.LOG_LINE_LIMIT
const EffectServiceScript := preload("res://scripts/core/EffectService.gd")
const EventServiceScript := preload("res://scripts/core/EventService.gd")
const GameEventScript := preload("res://scripts/core/GameEvent.gd")


var state: GameState
var board_data: BoardData
var board_navigator: BoardNavigator = BoardNavigator.new()
var grid_movement_system: GridMovementSystem = GridMovementSystem.new()
var effect_service: Variant = EffectServiceScript.new()
var event_service: Variant = EventServiceScript.new()
var property_service: Variant = PropertyResolutionServiceScript.new()
var landing_resolution_service: Variant = LandingResolutionServiceScript.new()
var turn_system: TurnSystem = TurnSystem.new()
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _snapshot_summary: SnapshotSummaryTracker = SnapshotSummaryTrackerScript.new()


func _ready() -> void:
	_rng.randomize()


func start_local_game(players: Array[PlayerState], data: BoardData) -> void:
	_snapshot_summary.reset()
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

	_emit(GameEventScript.GAME_STARTED, {"state": state.to_dict()})
	_emit(GameEventScript.ROUND_STARTED, {"round": state.current_round})
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
	_emit(GameEventScript.DICE_ROLLED, {
		"player_id": player_id,
		"dice_value": dice_value,
	})
	state.begin_movement(MovementState.new(player_id, player.tile_index, player.entered_from_tile_index, dice_value))
	turn_system.begin_movement()
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
	_emit(GameEventScript.PLAYER_MOVED, {
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

	return _finish_property_resolution(property_service.buy_pending_property(state, board_data))


func request_skip_pending_property() -> bool:
	if state == null or board_data == null or not turn_system.can_resolve_property_decision():
		return false

	if not state.has_pending_property_purchase():
		return false

	return _finish_property_resolution(property_service.skip_pending_property(state, board_data))


func get_state_snapshot() -> Dictionary:
	if state == null:
		return {}

	var snapshot := state.to_dict()
	snapshot[SNAPSHOT_TURN_PHASE_KEY] = turn_system.get_phase()
	snapshot[SNAPSHOT_UI_SUMMARY_KEY] = _snapshot_summary.to_dict()
	return snapshot


func restore_state_snapshot(snapshot: Dictionary, data: BoardData) -> void:
	state = GameState.from_dict(snapshot)
	board_data = data
	board_navigator.set_board_data(data)
	var map_grid: BoardMapGridData = data.get_map_grid()
	if map_grid != null:
		grid_movement_system.set_map_grid(map_grid)
	_restore_turn_phase_from_snapshot(snapshot)
	_snapshot_summary.restore(snapshot.get(SNAPSHOT_UI_SUMMARY_KEY, {}))


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
	_emit(GameEventScript.DICE_ROLLED, {
		"player_id": player_id,
		"dice_value": dice_value,
	})
	state.begin_grid_movement(GridMovementState.new(player_id, player_map_state.grid_position, player_map_state.direction, dice_value))
	turn_system.begin_movement()
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
		_emit(GameEventScript.MAP_ROUTE_CHOICE_REQUESTED, {
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

	_emit(GameEventScript.MAP_PLAYER_MOVED, {
		"player_id": player_id,
		"from_grid_position": previous_grid_position,
		"to_grid_position": move_result.current_grid_position,
		"path_grid_positions": move_result.visual_path_grid_positions.duplicate(),
	})


func _resolve_grid_landing(player: PlayerState, player_map_state: PlayerMapState, dice_value: int) -> void:
	turn_system.begin_landing_resolve()
	_finish_landing_resolution(landing_resolution_service.resolve_grid_landing(
		state,
		board_data,
		player,
		player_map_state,
		dice_value,
		property_service,
		effect_service,
		event_service
	))


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
		_emit(GameEventScript.PLAYER_MOVED, {
			"player_id": player.player_id,
			"from_tile_index": previous_tile_index,
			"to_tile_index": movement_state.current_tile_index,
			"path_tile_indices": move_result.path_tile_indices.duplicate(),
		})

	if move_result.requires_route_choice():
		turn_system.begin_route_decision()
		_emit(GameEventScript.ROUTE_CHOICE_REQUESTED, {
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
	turn_system.begin_landing_resolve()
	_finish_landing_resolution(landing_resolution_service.resolve_board_landing(
		state,
		board_data,
		player,
		dice_value,
		property_service,
		effect_service,
		event_service
	))


func _finish_landing_resolution(result: Dictionary) -> void:
	_emit_landing_warnings(result)
	if bool(result.get(LandingResolutionServiceScript.RESULT_PAUSES_FOR_PROPERTY, false)):
		turn_system.begin_property_decision()
		_emit_landing_events(result)
		return

	_emit_landing_events(result)
	if bool(result.get(LandingResolutionServiceScript.RESULT_COMPLETES_TURN, false)):
		_complete_turn(int(result.get(LandingResolutionServiceScript.RESULT_PLAYER_ID, -1)))


func _emit_landing_warnings(result: Dictionary) -> void:
	for warning in result.get(LandingResolutionServiceScript.RESULT_WARNINGS, []):
		push_warning(str(warning))


func _emit_landing_events(result: Dictionary) -> void:
	for event in result.get(LandingResolutionServiceScript.RESULT_EVENTS, []):
		_emit(str(event.get(LandingResolutionServiceScript.EVENT_TYPE, "")), event.get(LandingResolutionServiceScript.EVENT_PAYLOAD, {}))


func _finish_property_resolution(result: Dictionary) -> bool:
	if not bool(result.get(PropertyResolutionServiceScript.RESULT_HANDLED, false)):
		return false

	_emit_property_event(result)
	if bool(result.get(PropertyResolutionServiceScript.RESULT_COMPLETES_TURN, false)):
		_complete_turn(int(result.get(PropertyResolutionServiceScript.RESULT_PLAYER_ID, -1)))

	return true


func _emit_property_event(result: Dictionary) -> void:
	var event_type: String = str(result.get(PropertyResolutionServiceScript.RESULT_EVENT_TYPE, ""))
	if event_type.is_empty():
		return

	var event_payload: Dictionary = result.get(PropertyResolutionServiceScript.RESULT_EVENT_PAYLOAD, {})
	_emit(event_type, event_payload)


func _resolve_tile_effect(player: PlayerState, tile_data: BoardTileData) -> void:
	var result: Dictionary = landing_resolution_service.resolve_tile_effect(player, tile_data, effect_service, event_service)
	_emit_landing_warnings(result)
	_emit_landing_events(result)


func _complete_property_decision(player_id: int) -> void:
	state.clear_pending_property_purchase()
	_complete_turn(player_id)


func _complete_turn(player_id: int) -> void:
	_emit(GameEventScript.TURN_ENDED, {"player_id": player_id})
	var began_new_round: bool = turn_system.complete_turn(state)
	if began_new_round:
		_emit(GameEventScript.ROUND_STARTED, {"round": state.current_round})

	_emit_current_turn_started()


func _emit_current_turn_started() -> void:
	_emit(GameEventScript.TURN_STARTED, {
		"player_id": state.get_current_player_id(),
		"round": state.current_round,
	})


func _emit(event_type: String, payload: Dictionary) -> void:
	_snapshot_summary.record_event(event_type, payload)
	var event_bus: Variant = _get_event_bus()
	if event_bus != null:
		event_bus.emit_game_event(GameEventScript.new(event_type, payload))


func _get_event_bus() -> Variant:
	return get_node_or_null("/root/EventBus")
