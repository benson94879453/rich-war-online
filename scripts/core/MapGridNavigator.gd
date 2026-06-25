extends RefCounted
class_name MapGridNavigator


const DIRECTION_OFFSETS := {
	# The StarQ source map stores directions in isometric screen order:
	# 1 = southeast, 2 = southwest, 3 = northwest, 4 = northeast.
	BoardConnectionData.Direction.RIGHT: Vector2i(1, 1),
	BoardConnectionData.Direction.UP: Vector2i(-1, 1),
	BoardConnectionData.Direction.LEFT: Vector2i(-1, -1),
	BoardConnectionData.Direction.DOWN: Vector2i(1, -1),
}
const OPPOSITE_DIRECTIONS := {
	BoardConnectionData.Direction.RIGHT: BoardConnectionData.Direction.LEFT,
	BoardConnectionData.Direction.UP: BoardConnectionData.Direction.DOWN,
	BoardConnectionData.Direction.LEFT: BoardConnectionData.Direction.RIGHT,
	BoardConnectionData.Direction.DOWN: BoardConnectionData.Direction.UP,
}


var _map_grid: BoardMapGridData


func set_map_grid(map_grid: BoardMapGridData) -> void:
	_map_grid = map_grid


func get_next_grid_position(grid_position: Vector2i, direction: int) -> Vector2i:
	var route_positions := get_route_positions(grid_position, direction)
	if route_positions.is_empty():
		return Vector2i(-1, -1)

	return route_positions[route_positions.size() - 1]


func get_route_positions(grid_position: Vector2i, direction: int) -> Array[Vector2i]:
	if _map_grid == null or not DIRECTION_OFFSETS.has(direction):
		return []

	var node_id := _map_grid.get_node_id(grid_position)
	var allow_junction_transition: bool = not _map_grid.get_junction_directions(node_id).is_empty()
	var next_position: Vector2i = grid_position + DIRECTION_OFFSETS[direction]
	var route_positions: Array[Vector2i] = []
	while _map_grid.is_inside(next_position):
		var next_node_id := _map_grid.get_node_id(next_position)
		if next_node_id == BoardMapGridData.BACKGROUND_NODE_ID:
			return []

		if _map_grid.is_landing_node(next_position):
			route_positions.append(next_position)
			return route_positions

		if next_node_id == 0:
			route_positions.append(next_position)

		if not allow_junction_transition:
			return []

		next_position += DIRECTION_OFFSETS[direction]

	return []


func get_available_directions(grid_position: Vector2i, current_direction: int) -> PackedInt32Array:
	if _map_grid == null or not _map_grid.is_walkable(grid_position):
		return PackedInt32Array()

	var node_id := _map_grid.get_node_id(grid_position)
	var junction_directions := _map_grid.get_junction_directions(node_id)
	if junction_directions.is_empty():
		return _get_automatic_direction(grid_position, current_direction, node_id)

	var opposite_direction: int = OPPOSITE_DIRECTIONS.get(current_direction, BoardConnectionData.Direction.NONE)
	var available_directions := PackedInt32Array()
	for direction in junction_directions:
		if direction == opposite_direction:
			continue

		if not get_route_positions(grid_position, direction).is_empty():
			available_directions.append(direction)

	return available_directions


func _get_automatic_direction(grid_position: Vector2i, current_direction: int, _node_id: int) -> PackedInt32Array:
	if not get_route_positions(grid_position, current_direction).is_empty():
		return PackedInt32Array([current_direction])

	# A non-junction node's source direction describes its attached building,
	# not the path the player should turn onto. Only junction direction arrays
	# are allowed to change the current travel direction.
	return PackedInt32Array()
