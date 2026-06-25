extends Resource
class_name BoardMapGridData


const BACKGROUND_NODE_ID := 233


@export var width: int = 0
@export var height: int = 0
@export var node_ids: PackedInt32Array = PackedInt32Array()
@export var node_directions_by_id: Dictionary = {}
@export var walkable_node_ids: Dictionary = {}
@export var junction_directions_by_node_id: Dictionary = {}


func is_inside(grid_position: Vector2i) -> bool:
	return grid_position.x >= 0 and grid_position.x < width and grid_position.y >= 0 and grid_position.y < height


func get_node_id(grid_position: Vector2i) -> int:
	if not is_inside(grid_position):
		return BACKGROUND_NODE_ID

	return node_ids[grid_position.y * width + grid_position.x]


func get_grid_position_for_node_id(node_id: int) -> Vector2i:
	var flat_index: int = node_ids.find(node_id)
	if flat_index == -1 or width <= 0:
		return Vector2i(-1, -1)

	return Vector2i(flat_index % width, flat_index / width)


func is_walkable(grid_position: Vector2i) -> bool:
	var node_id := get_node_id(grid_position)
	if node_id == BACKGROUND_NODE_ID:
		return false

	return node_id == 0 or walkable_node_ids.is_empty() or walkable_node_ids.has(node_id)


func is_landing_node(grid_position: Vector2i) -> bool:
	var node_id := get_node_id(grid_position)
	return node_id != 0 and node_id != BACKGROUND_NODE_ID and (walkable_node_ids.is_empty() or walkable_node_ids.has(node_id))


func get_node_directions(node_id: int) -> PackedInt32Array:
	var direction_value: Variant = node_directions_by_id.get(node_id, PackedInt32Array())
	if direction_value is PackedInt32Array:
		return direction_value

	return PackedInt32Array()


func get_junction_directions(node_id: int) -> PackedInt32Array:
	var direction_value: Variant = junction_directions_by_node_id.get(node_id, PackedInt32Array())
	if direction_value is PackedInt32Array:
		return direction_value

	return PackedInt32Array()


func get_validation_messages() -> PackedStringArray:
	var messages := PackedStringArray()
	if width <= 0 or height <= 0:
		messages.append("Board map grid must have positive dimensions.")
		return messages

	var expected_cell_count := width * height
	if node_ids.size() != expected_cell_count:
		messages.append("Board map grid has %d cells, but %d are required." % [node_ids.size(), expected_cell_count])

	for node_id in junction_directions_by_node_id:
		var directions := get_junction_directions(int(node_id))
		if directions.is_empty():
			messages.append("Board map junction %d has no directions." % int(node_id))
			continue

		for direction in directions:
			if direction < BoardConnectionData.Direction.RIGHT or direction > BoardConnectionData.Direction.DOWN:
				messages.append("Board map junction %d has invalid direction %d." % [int(node_id), direction])

	for node_id in walkable_node_ids:
		if get_node_directions(int(node_id)).is_empty():
			messages.append("Board map walkable node %d has no directions." % int(node_id))

	return messages
