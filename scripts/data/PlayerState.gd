extends RefCounted
class_name PlayerState


var player_id: int
var display_name: String
var money: int
var tile_index: int
var entered_from_tile_index: int


func _init(id: int = -1, name: String = "", starting_money: int = 1500, starting_tile_index: int = 0, starting_entered_from_tile_index: int = -1) -> void:
	player_id = id
	display_name = name
	money = starting_money
	tile_index = starting_tile_index
	entered_from_tile_index = starting_entered_from_tile_index


func add_money(amount: int) -> void:
	money += amount


func move_to_tile(value: int, entered_from_value: int = -1) -> void:
	tile_index = value
	entered_from_tile_index = entered_from_value


func to_dict() -> Dictionary:
	return {
		"player_id": player_id,
		"display_name": display_name,
		"money": money,
		"tile_index": tile_index,
		"entered_from_tile_index": entered_from_tile_index,
	}


static func from_dict(data: Dictionary) -> PlayerState:
	return PlayerState.new(
		int(data.get("player_id", -1)),
		str(data.get("display_name", "")),
		int(data.get("money", 1500)),
		int(data.get("tile_index", 0)),
		int(data.get("entered_from_tile_index", -1))
	)
