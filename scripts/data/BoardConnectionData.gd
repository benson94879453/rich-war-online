extends Resource
class_name BoardConnectionData


enum Direction {
	NONE,
	RIGHT,
	UP,
	LEFT,
	DOWN,
}


@export var from_tile_index: int = -1
@export var to_tile_index: int = -1
@export var direction: Direction = Direction.NONE


func has_valid_direction() -> bool:
	return direction >= Direction.RIGHT and direction <= Direction.DOWN
