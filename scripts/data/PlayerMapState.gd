extends RefCounted
class_name PlayerMapState


const INVALID_GRID_POSITION := Vector2i(-1, -1)


var grid_position: Vector2i
var direction: int


func _init(grid_position_value: Vector2i = INVALID_GRID_POSITION, direction_value: int = BoardConnectionData.Direction.NONE) -> void:
	grid_position = grid_position_value
	direction = direction_value


func is_valid() -> bool:
	return grid_position.x >= 0 and grid_position.y >= 0 and _has_valid_direction(direction)


func move_to(grid_position_value: Vector2i, direction_value: int) -> void:
	grid_position = grid_position_value
	direction = direction_value


func to_dict() -> Dictionary:
	return {
		"grid_position": [grid_position.x, grid_position.y],
		"direction": direction,
	}


static func from_dict(data: Dictionary) -> PlayerMapState:
	var serialized_position: Array = data.get("grid_position", [])
	var grid_position_value := INVALID_GRID_POSITION
	if serialized_position.size() == 2:
		grid_position_value = Vector2i(int(serialized_position[0]), int(serialized_position[1]))

	return PlayerMapState.new(grid_position_value, int(data.get("direction", BoardConnectionData.Direction.NONE)))


func _has_valid_direction(value: int) -> bool:
	return value >= BoardConnectionData.Direction.RIGHT and value <= BoardConnectionData.Direction.DOWN
