extends RefCounted
class_name TileEffectResolution


var was_applied: bool = false
var money_delta: int = 0
var money_after: int = 0


func apply_money_change(delta: int, resulting_money: int) -> void:
	was_applied = true
	money_delta = delta
	money_after = resulting_money
