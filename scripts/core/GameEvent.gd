extends RefCounted
class_name GameEvent


const GAME_STARTED := "game_started"
const ROUND_STARTED := "round_started"
const TURN_STARTED := "turn_started"
const DICE_ROLLED := "dice_rolled"
const PLAYER_MOVED := "player_moved"
const PLAYER_LANDED := "player_landed"
const ROUTE_CHOICE_REQUESTED := "route_choice_requested"
const MAP_PLAYER_MOVED := "map_player_moved"
const MAP_PLAYER_LANDED := "map_player_landed"
const MAP_ROUTE_CHOICE_REQUESTED := "map_route_choice_requested"
const TILE_EFFECT_RESOLVED := "tile_effect_resolved"
const RENT_PAID := "rent_paid"
const PROPERTY_PURCHASE_OFFERED := "property_purchase_offered"
const PROPERTY_PURCHASED := "property_purchased"
const PROPERTY_PURCHASE_SKIPPED := "property_purchase_skipped"
const TURN_ENDED := "turn_ended"


var type: String
var payload: Dictionary


func _init(event_type: String = "", event_payload: Dictionary = {}) -> void:
	type = event_type
	payload = event_payload.duplicate(true)


func to_dict() -> Dictionary:
	return {
		"type": type,
		"payload": payload.duplicate(true),
	}


static func from_dict(data: Dictionary) -> GameEvent:
	var event_payload: Dictionary = data.get("payload", {})
	return GameEvent.new(str(data.get("type", "")), event_payload)
