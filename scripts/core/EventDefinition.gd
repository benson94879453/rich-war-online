extends Resource
class_name EventDefinition


@export var event_id: StringName = &""
@export var display_name: String = ""
@export_multiline var description: String = ""
@export var effect_id: StringName = &""
@export var money_delta: int = 0


func _init(
		new_event_id: StringName = &"",
		new_display_name: String = "",
		new_effect_id: StringName = &"",
		new_money_delta: int = 0
) -> void:
	event_id = new_event_id
	display_name = new_display_name
	effect_id = new_effect_id
	money_delta = new_money_delta


func has_money_effect() -> bool:
	return money_delta != 0
