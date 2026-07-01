extends Resource
class_name CardDefinition


const TIMING_PRE_ROLL := &"pre_roll"
const TARGET_CURRENT_PLAYER := &"current_player"


@export var card_id: StringName = &""
@export var display_name: String = ""
@export_multiline var description: String = ""
@export var timing_window: StringName = &""
@export var target_rule: StringName = &""
@export var target_summary: String = ""
@export var effect_id: StringName = &""
@export var effect_summary: String = ""
@export var money_delta: int = 0
@export var art_path: String = ""


func _init(
		new_card_id: StringName = &"",
		new_display_name: String = "",
		new_timing_window: StringName = &"",
		new_target_rule: StringName = &"",
		new_effect_id: StringName = &"",
		new_money_delta: int = 0,
		new_description: String = "",
		new_effect_summary: String = "",
		new_target_summary: String = "",
		new_art_path: String = ""
) -> void:
	card_id = new_card_id
	display_name = new_display_name
	description = new_description
	timing_window = new_timing_window
	target_rule = new_target_rule
	target_summary = new_target_summary
	effect_id = new_effect_id
	effect_summary = new_effect_summary
	money_delta = new_money_delta
	art_path = new_art_path


func has_money_effect() -> bool:
	return money_delta != 0


func get_visible_metadata() -> Dictionary:
	return {
		"card_id": card_id,
		"display_name": display_name,
		"description": description,
		"timing_window": timing_window,
		"target_rule": target_rule,
		"target_summary": get_target_summary(),
		"effect_id": effect_id,
		"effect_summary": get_effect_summary(),
		"money_delta": money_delta,
		"art_path": get_art_path(),
		"has_art_path": has_art_path(),
	}


func get_effect_summary() -> String:
	if not effect_summary.strip_edges().is_empty():
		return effect_summary

	if has_money_effect():
		if money_delta > 0:
			return "+$%d" % money_delta
		return "-$%d" % abs(money_delta)

	return ""


func get_target_summary() -> String:
	if not target_summary.strip_edges().is_empty():
		return target_summary

	if target_rule == TARGET_CURRENT_PLAYER:
		return "Current player"

	return ""


func get_art_path() -> String:
	return art_path.strip_edges()


func has_art_path() -> bool:
	return not get_art_path().is_empty()
