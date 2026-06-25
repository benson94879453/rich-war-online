extends RefCounted
class_name GridMovementState


var player_id: int = -1
var current_grid_position: Vector2i = Vector2i(-1, -1)
var travel_direction: int = BoardConnectionData.Direction.NONE
var rolled_steps: int = 0
var remaining_steps: int = 0
var travelled_grid_positions: Array[Vector2i] = []
var available_next_directions: PackedInt32Array = PackedInt32Array()
var pending_route_positions: Array[Vector2i] = []


func _init(player_id_value: int = -1, grid_position_value: Vector2i = Vector2i(-1, -1), direction_value: int = BoardConnectionData.Direction.NONE, remaining_steps_value: int = 0) -> void:
	player_id = player_id_value
	current_grid_position = grid_position_value
	travel_direction = direction_value
	rolled_steps = remaining_steps_value
	remaining_steps = remaining_steps_value


func move_to(grid_position: Vector2i, direction: int) -> void:
	if remaining_steps <= 0:
		return

	current_grid_position = grid_position
	travel_direction = direction
	remaining_steps -= 1
	travelled_grid_positions.append(grid_position)
	available_next_directions.clear()


func queue_route_positions(grid_positions: Array[Vector2i], direction: int) -> void:
	pending_route_positions = grid_positions.duplicate()
	travel_direction = direction


func has_pending_route_positions() -> bool:
	return not pending_route_positions.is_empty()


func take_next_route_position() -> Vector2i:
	if pending_route_positions.is_empty():
		return Vector2i(-1, -1)

	var next_grid_position: Vector2i = pending_route_positions[0]
	pending_route_positions.remove_at(0)
	return next_grid_position


func wait_for_route_choice(directions: PackedInt32Array) -> void:
	available_next_directions = directions.duplicate()


func clear_route_choice() -> void:
	available_next_directions.clear()


func is_waiting_for_route_choice() -> bool:
	return not available_next_directions.is_empty()


func is_complete() -> bool:
	return remaining_steps <= 0


func to_dict() -> Dictionary:
	return {
		"player_id": player_id,
		"current_grid_position": [current_grid_position.x, current_grid_position.y],
		"travel_direction": travel_direction,
		"rolled_steps": rolled_steps,
		"remaining_steps": remaining_steps,
		"travelled_grid_positions": _serialize_grid_positions(travelled_grid_positions),
		"available_next_directions": Array(available_next_directions),
		"pending_route_positions": _serialize_grid_positions(pending_route_positions),
	}


static func from_dict(data: Dictionary) -> GridMovementState:
	var movement_state := GridMovementState.new(
		int(data.get("player_id", -1)),
		_deserialize_grid_position(data.get("current_grid_position", [])),
		int(data.get("travel_direction", BoardConnectionData.Direction.NONE)),
		int(data.get("remaining_steps", 0))
	)
	movement_state.rolled_steps = int(data.get("rolled_steps", movement_state.remaining_steps))
	movement_state.travelled_grid_positions = _deserialize_grid_positions(data.get("travelled_grid_positions", []))
	movement_state.pending_route_positions = _deserialize_grid_positions(data.get("pending_route_positions", []))

	var serialized_directions: Array = data.get("available_next_directions", [])
	for direction in serialized_directions:
		movement_state.available_next_directions.append(int(direction))

	return movement_state


static func _serialize_grid_positions(grid_positions: Array[Vector2i]) -> Array[Array]:
	var serialized_positions: Array[Array] = []
	for grid_position in grid_positions:
		serialized_positions.append([grid_position.x, grid_position.y])

	return serialized_positions


static func _deserialize_grid_positions(serialized_positions: Array) -> Array[Vector2i]:
	var grid_positions: Array[Vector2i] = []
	for serialized_position in serialized_positions:
		if serialized_position is Array:
			var position_values: Array = serialized_position
			if position_values.size() == 2:
				grid_positions.append(Vector2i(int(position_values[0]), int(position_values[1])))

	return grid_positions


static func _deserialize_grid_position(serialized_position: Variant) -> Vector2i:
	if serialized_position is Array:
		var position_values: Array = serialized_position
		if position_values.size() == 2:
			return Vector2i(int(position_values[0]), int(position_values[1]))

	return Vector2i(-1, -1)
