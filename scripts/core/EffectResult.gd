extends RefCounted
class_name EffectResult


var was_applied: bool = false
var effect_id: StringName = &""
var source_type: StringName = &""
var source_id: StringName = &""
var rejection_reason: String = ""
var money_delta: int = 0
var money_after: int = 0


func configure(new_effect_id: StringName, new_source_type: StringName = &"", new_source_id: StringName = &"") -> void:
	effect_id = new_effect_id
	source_type = new_source_type
	source_id = new_source_id


func apply_money_change(delta: int, resulting_money: int) -> void:
	was_applied = true
	money_delta = delta
	money_after = resulting_money


func reject(reason: String) -> void:
	was_applied = false
	rejection_reason = reason


func is_rejected() -> bool:
	return not rejection_reason.is_empty()
