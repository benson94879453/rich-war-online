extends RefCounted
class_name BoardMoveResult


var start_tile_index: int = -1
var path_tile_indices: Array[int] = []
var current_tile_index: int = -1
var remaining_steps: int = 0
var blocked_tile_index: int = -1
var route_choice_tile_indices: Array[int] = []


func _init(start_tile_index_value: int = -1) -> void:
	start_tile_index = start_tile_index_value
	current_tile_index = start_tile_index_value


func record_step(tile_index: int) -> void:
	path_tile_indices.append(tile_index)
	current_tile_index = tile_index


func mark_blocked(tile_index: int) -> void:
	blocked_tile_index = tile_index
	current_tile_index = tile_index


func require_route_choice(tile_indices: Array[int]) -> void:
	route_choice_tile_indices = tile_indices.duplicate()


func finish(tile_index: int, steps_remaining: int) -> void:
	current_tile_index = tile_index
	remaining_steps = steps_remaining


func is_complete() -> bool:
	return blocked_tile_index == -1 and route_choice_tile_indices.is_empty() and remaining_steps <= 0


func is_blocked() -> bool:
	return blocked_tile_index != -1


func requires_route_choice() -> bool:
	return not route_choice_tile_indices.is_empty()


func to_dict() -> Dictionary:
	return {
		"start_tile_index": start_tile_index,
		"path_tile_indices": path_tile_indices.duplicate(),
		"current_tile_index": current_tile_index,
		"remaining_steps": remaining_steps,
		"blocked_tile_index": blocked_tile_index,
		"route_choice_tile_indices": route_choice_tile_indices.duplicate(),
	}
