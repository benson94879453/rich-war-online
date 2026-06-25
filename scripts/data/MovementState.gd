extends RefCounted
class_name MovementState


var player_id: int = -1
var current_tile_index: int = -1
var entered_from_tile_index: int = -1
var rolled_steps: int = 0
var remaining_steps: int = 0
var travelled_tile_indices: Array[int] = []
var available_next_tile_indices: Array[int] = []


func _init(player_id_value: int = -1, current_tile_index_value: int = -1, entered_from_tile_index_value: int = -1, remaining_steps_value: int = 0) -> void:
	player_id = player_id_value
	current_tile_index = current_tile_index_value
	entered_from_tile_index = entered_from_tile_index_value
	rolled_steps = remaining_steps_value
	remaining_steps = remaining_steps_value


func move_to(tile_index: int) -> void:
	if remaining_steps <= 0:
		return

	entered_from_tile_index = current_tile_index
	current_tile_index = tile_index
	remaining_steps -= 1
	travelled_tile_indices.append(tile_index)
	available_next_tile_indices.clear()


func wait_for_route_choice(tile_indices: Array[int]) -> void:
	available_next_tile_indices = tile_indices.duplicate()


func clear_route_choice() -> void:
	available_next_tile_indices.clear()


func is_waiting_for_route_choice() -> bool:
	return not available_next_tile_indices.is_empty()


func is_complete() -> bool:
	return remaining_steps <= 0


func to_dict() -> Dictionary:
	return {
		"player_id": player_id,
		"current_tile_index": current_tile_index,
		"entered_from_tile_index": entered_from_tile_index,
		"rolled_steps": rolled_steps,
		"remaining_steps": remaining_steps,
		"travelled_tile_indices": travelled_tile_indices.duplicate(),
		"available_next_tile_indices": available_next_tile_indices.duplicate(),
	}


static func from_dict(data: Dictionary) -> MovementState:
	var movement_state := MovementState.new(
		int(data.get("player_id", -1)),
		int(data.get("current_tile_index", -1)),
		int(data.get("entered_from_tile_index", -1)),
		int(data.get("remaining_steps", 0))
	)
	var serialized_path: Array = data.get("travelled_tile_indices", [])
	for tile_index in serialized_path:
		movement_state.travelled_tile_indices.append(int(tile_index))

	if data.has("rolled_steps"):
		movement_state.rolled_steps = int(data["rolled_steps"])
	else:
		movement_state.rolled_steps = movement_state.remaining_steps + movement_state.travelled_tile_indices.size()

	var serialized_options: Array = data.get("available_next_tile_indices", [])
	for tile_index in serialized_options:
		movement_state.available_next_tile_indices.append(int(tile_index))

	return movement_state
