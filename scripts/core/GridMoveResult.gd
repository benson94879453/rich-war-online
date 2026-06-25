extends RefCounted
class_name GridMoveResult


var start_grid_position: Vector2i = Vector2i(-1, -1)
var path_grid_positions: Array[Vector2i] = []
var visual_path_grid_positions: Array[Vector2i] = []
var current_grid_position: Vector2i = Vector2i(-1, -1)
var remaining_steps: int = 0
var blocked_grid_position: Vector2i = Vector2i(-1, -1)
var route_choice_directions: PackedInt32Array = PackedInt32Array()


func _init(start_grid_position_value: Vector2i = Vector2i(-1, -1)) -> void:
	start_grid_position = start_grid_position_value
	current_grid_position = start_grid_position_value


func record_step(grid_position: Vector2i) -> void:
	path_grid_positions.append(grid_position)
	visual_path_grid_positions.append(grid_position)
	current_grid_position = grid_position


func mark_blocked(grid_position: Vector2i) -> void:
	blocked_grid_position = grid_position
	current_grid_position = grid_position


func require_route_choice(directions: PackedInt32Array) -> void:
	route_choice_directions = directions.duplicate()


func finish(grid_position: Vector2i, steps_remaining: int) -> void:
	current_grid_position = grid_position
	remaining_steps = steps_remaining


func is_complete() -> bool:
	return blocked_grid_position == Vector2i(-1, -1) and route_choice_directions.is_empty() and remaining_steps <= 0


func is_blocked() -> bool:
	return blocked_grid_position != Vector2i(-1, -1)


func requires_route_choice() -> bool:
	return not route_choice_directions.is_empty()
