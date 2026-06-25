extends Node2D
class_name StarQMapDemo


const TEST_PLAYER_ID := 0
const TEST_STEP_COUNT := 100
const TEST_STEP_DURATION := 0.55


@onready var _board: Board = $MapView/Board
@onready var _test_piece: PlayerPiece = $MapView/TestPiece
@onready var _route_choice_panel: GridRouteChoicePanel = $RouteChoiceLayer/RouteChoicePanel

var _board_data: BoardData
var _map_grid: BoardMapGridData
var _movement_system := GridMovementSystem.new()
var _player_map_state: PlayerMapState
var _pending_movement_state: GridMovementState


func _ready() -> void:
	_board_data = _board.board_data as BoardData
	if _board_data == null:
		push_error("StarQ map test requires BoardData.")
		return

	_map_grid = _board_data.get_map_grid()
	_player_map_state = _board_data.get_player_map_spawn(TEST_PLAYER_ID)
	if _map_grid == null or _player_map_state == null or not _player_map_state.is_valid() or not _map_grid.is_landing_node(_player_map_state.grid_position):
		push_error("StarQ map test requires a valid player grid spawn.")
		return

	_movement_system.set_map_grid(_map_grid)
	_place_piece_at(_player_map_state.grid_position)
	_route_choice_panel.direction_chosen.connect(_on_route_direction_chosen)
	call_deferred("_run_test_route")


func _run_test_route() -> void:
	await get_tree().create_timer(TEST_STEP_DURATION).timeout
	_pending_movement_state = GridMovementState.new(TEST_PLAYER_ID, _player_map_state.grid_position, _player_map_state.direction, TEST_STEP_COUNT)
	await _advance_pending_movement()


func _on_route_direction_chosen(direction: int) -> void:
	if _pending_movement_state == null:
		return

	_route_choice_panel.hide_choices()
	var move_result := _movement_system.choose_route(_pending_movement_state, direction)
	await _handle_movement_result(move_result)


func _advance_pending_movement() -> void:
	if _pending_movement_state == null:
		return

	var move_result := _movement_system.advance_movement(_pending_movement_state)
	await _handle_movement_result(move_result)


func _handle_movement_result(move_result: GridMoveResult) -> void:
	if move_result.is_blocked():
		var blocked_node_id: int = _map_grid.get_node_id(move_result.blocked_grid_position)
		push_error("StarQ map test route is blocked at node %d (%d, %d)." % [blocked_node_id, move_result.blocked_grid_position.x, move_result.blocked_grid_position.y])
		_pending_movement_state = null
		return

	await _animate_path(move_result.visual_path_grid_positions)
	if move_result.requires_route_choice():
		_route_choice_panel.show_choices(move_result.route_choice_directions)
		return

	if not move_result.is_complete():
		await _advance_pending_movement()
		return

	if _pending_movement_state == null:
		return

	_player_map_state.move_to(_pending_movement_state.current_grid_position, _pending_movement_state.travel_direction)
	_pending_movement_state = null


func _animate_path(grid_positions: Array[Vector2i]) -> void:
	for grid_position in grid_positions:
		var tween := create_tween()
		tween.tween_property(_test_piece, "position", _get_grid_canvas_position(grid_position), TEST_STEP_DURATION)
		await tween.finished


func _place_piece_at(grid_position: Vector2i) -> void:
	_test_piece.move_to(_get_grid_canvas_position(grid_position))


func _get_grid_canvas_position(grid_position: Vector2i) -> Vector2:
	var grid_step := _board.tile_size * 0.5
	return Vector2(grid_position.x * grid_step.x, (grid_position.y - 1) * grid_step.y)
