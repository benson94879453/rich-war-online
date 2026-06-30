extends RefCounted
class_name SnapshotSummaryTracker


const LAST_DICE_KEY := "last_dice_roll"
const LAST_LANDING_KEY := "last_landing"
const EVENT_MESSAGE_KEY := "event_message"
const LOG_LINES_KEY := "log_lines"
const LOG_LINE_LIMIT := 20
const GameEventScript := preload("res://scripts/core/GameEvent.gd")


var _last_dice_roll: Dictionary = {}
var _last_landing: Dictionary = {}
var _last_event_message: String = ""
var _log_lines: Array[String] = []


func reset() -> void:
	_last_dice_roll.clear()
	_last_landing.clear()
	_last_event_message = ""
	_log_lines.clear()


func to_dict() -> Dictionary:
	return {
		LAST_DICE_KEY: _last_dice_roll.duplicate(true),
		LAST_LANDING_KEY: _last_landing.duplicate(true),
		EVENT_MESSAGE_KEY: _last_event_message,
		LOG_LINES_KEY: _log_lines.duplicate(),
	}


func restore(summary: Variant) -> void:
	reset()
	if not (summary is Dictionary):
		return

	var summary_data: Dictionary = summary
	var raw_dice: Variant = summary_data.get(LAST_DICE_KEY, {})
	if raw_dice is Dictionary:
		var dice_summary: Dictionary = raw_dice
		_last_dice_roll = dice_summary.duplicate(true)

	var raw_landing: Variant = summary_data.get(LAST_LANDING_KEY, {})
	if raw_landing is Dictionary:
		var landing_summary: Dictionary = raw_landing
		_last_landing = landing_summary.duplicate(true)

	_last_event_message = str(summary_data.get(EVENT_MESSAGE_KEY, ""))
	var raw_log_lines: Variant = summary_data.get(LOG_LINES_KEY, [])
	if raw_log_lines is Array:
		for raw_line in raw_log_lines:
			_append_log_line(str(raw_line))


func record_event(event_type: String, payload: Dictionary) -> void:
	match event_type:
		GameEventScript.ROUND_STARTED:
			_record_round_started(payload)
		GameEventScript.DICE_ROLLED:
			_last_dice_roll = payload.duplicate(true)
		GameEventScript.PLAYER_LANDED:
			_last_landing = payload.duplicate(true)
			_last_event_message = ""
			_append_log_line(_get_player_landed_summary(payload))
		GameEventScript.MAP_PLAYER_LANDED:
			_last_landing = payload.duplicate(true)
			_last_event_message = ""
			_append_log_line(_get_map_player_landed_summary(payload))
		GameEventScript.TILE_EFFECT_RESOLVED:
			_set_event_message(_get_tile_effect_summary(payload))
		GameEventScript.RENT_PAID:
			_set_event_message(_get_rent_paid_summary(payload))
		GameEventScript.PROPERTY_PURCHASE_OFFERED:
			_set_event_message(_get_property_purchase_offered_summary(payload))
		GameEventScript.PROPERTY_PURCHASED:
			_set_event_message(_get_property_purchased_summary(payload))
		GameEventScript.PROPERTY_PURCHASE_SKIPPED:
			_set_event_message(_get_property_purchase_skipped_summary(payload))


func _record_round_started(payload: Dictionary) -> void:
	var round_number: int = int(payload.get("round", 1))
	if round_number > 1:
		_append_log_line("Round %d begins" % round_number)


func _get_player_landed_summary(payload: Dictionary) -> String:
	var player_id: int = int(payload.get("player_id", -1))
	var dice_value: int = int(payload.get("dice_value", 0))
	var tile_index: int = int(payload.get("tile_index", -1))
	var tile_name: String = str(payload.get("tile_name", "Unknown"))
	return "P%d rolled %d -> tile %02d %s" % [player_id + 1, dice_value, tile_index, tile_name]


func _get_map_player_landed_summary(payload: Dictionary) -> String:
	var player_id: int = int(payload.get("player_id", -1))
	var dice_value: int = int(payload.get("dice_value", 0))
	var node_id: int = int(payload.get("node_id", -1))
	var tile_name: String = str(payload.get("tile_name", "Unknown"))
	return "P%d rolled %d -> node %d %s" % [player_id + 1, dice_value, node_id, tile_name]


func _get_tile_effect_summary(payload: Dictionary) -> String:
	var player_id: int = int(payload.get("player_id", -1))
	var tile_name: String = str(payload.get("tile_name", "tile"))
	var money_delta: int = int(payload.get("money_delta", 0))
	var delta_text: String = "+$%d" % money_delta if money_delta >= 0 else "-$%d" % abs(money_delta)
	var verb: String = "received" if money_delta >= 0 else "lost"
	return "P%d %s %s on %s" % [player_id + 1, verb, delta_text, tile_name]


func _get_rent_paid_summary(payload: Dictionary) -> String:
	var payer_id: int = int(payload.get("payer_id", -1))
	var owner_id: int = int(payload.get("owner_id", -1))
	var amount: int = int(payload.get("amount", 0))
	var tile_name: String = str(payload.get("tile_name", "property"))
	return "P%d paid P%d $%d rent for %s" % [payer_id + 1, owner_id + 1, amount, tile_name]


func _get_property_purchase_offered_summary(payload: Dictionary) -> String:
	var player_id: int = int(payload.get("player_id", -1))
	var tile_name: String = str(payload.get("tile_name", "property"))
	var price: int = int(payload.get("price", 0))
	return "P%d can buy %s for $%d" % [player_id + 1, tile_name, price]


func _get_property_purchased_summary(payload: Dictionary) -> String:
	var player_id: int = int(payload.get("player_id", -1))
	var tile_name: String = str(payload.get("tile_name", "property"))
	var price: int = int(payload.get("price", 0))
	return "P%d bought %s for $%d" % [player_id + 1, tile_name, price]


func _get_property_purchase_skipped_summary(payload: Dictionary) -> String:
	var player_id: int = int(payload.get("player_id", -1))
	var tile_name: String = str(payload.get("tile_name", "property"))
	var reason: String = str(payload.get("reason", "skipped"))
	if reason == "insufficient_funds":
		return "P%d cannot afford %s" % [player_id + 1, tile_name]

	return "P%d skipped %s" % [player_id + 1, tile_name]


func _set_event_message(message: String) -> void:
	_last_event_message = message
	_append_log_line(message)


func _append_log_line(message: String) -> void:
	if message.is_empty():
		return

	_log_lines.append(message)
	while _log_lines.size() > LOG_LINE_LIMIT:
		_log_lines.remove_at(0)
