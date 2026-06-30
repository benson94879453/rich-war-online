extends Resource
class_name CardDefinition


const TIMING_PRE_ROLL := &"pre_roll"
const TARGET_CURRENT_PLAYER := &"current_player"


@export var card_id: StringName = &""
@export var display_name: String = ""
@export_multiline var description: String = ""
@export var timing_window: StringName = &""
@export var target_rule: StringName = &""
@export var effect_id: StringName = &""
@export var money_delta: int = 0


func _init(
		new_card_id: StringName = &"",
		new_display_name: String = "",
		new_timing_window: StringName = &"",
		new_target_rule: StringName = &"",
		new_effect_id: StringName = &"",
		new_money_delta: int = 0
) -> void:
	card_id = new_card_id
	display_name = new_display_name
	timing_window = new_timing_window
	target_rule = new_target_rule
	effect_id = new_effect_id
	money_delta = new_money_delta


func has_money_effect() -> bool:
	return money_delta != 0
