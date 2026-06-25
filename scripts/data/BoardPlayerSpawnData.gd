extends Resource
class_name BoardPlayerSpawnData


@export var player_id: int = -1
@export var tile_index: int = -1
@export var grid_position: Vector2i = Vector2i(-1, -1)
@export_enum("None", "Right", "Up", "Left", "Down") var initial_direction: int = BoardConnectionData.Direction.NONE


func has_grid_spawn() -> bool:
	return grid_position.x >= 0 and grid_position.y >= 0
