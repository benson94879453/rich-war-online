extends RefCounted
class_name EventService


const EVENT_GAIN_MONEY := &"prototype_gain_money"
const SOURCE_EVENT := &"event"

const CONTEXT_PLAYER := "player"
const CONTEXT_EVENT_DEFINITION := "event_definition"

const EffectServiceScript := preload("res://scripts/core/EffectService.gd")
const EventDefinitionScript := preload("res://scripts/core/EventDefinition.gd")


var _effect_service: Variant = EffectServiceScript.new()


func apply_event(event_definition: Variant, context: Dictionary = {}) -> Variant:
	var player: PlayerState = context.get(CONTEXT_PLAYER, null) as PlayerState
	if event_definition == null:
		return _reject_missing_event()

	if not event_definition.has_money_effect():
		return _create_noop_result(event_definition)

	return _apply_money_event(player, event_definition)


func create_prototype_money_event(money_delta: int) -> Variant:
	return EventDefinitionScript.new(
		EVENT_GAIN_MONEY,
		"Prototype money event",
		EffectServiceScript.EFFECT_MONEY_DELTA,
		money_delta
	)


func _apply_money_event(player: PlayerState, event_definition: Variant) -> Variant:
	var result: Variant = _effect_service.apply_effect(EffectServiceScript.EFFECT_MONEY_DELTA, {
		EffectServiceScript.CONTEXT_PLAYER: player,
		EffectServiceScript.CONTEXT_MONEY_DELTA: int(event_definition.money_delta),
		EffectServiceScript.CONTEXT_SOURCE_TYPE: SOURCE_EVENT,
		EffectServiceScript.CONTEXT_SOURCE_ID: event_definition.event_id,
	})
	result.effect_id = event_definition.event_id
	return result


func _create_noop_result(event_definition: Variant) -> Variant:
	var result: Variant = _effect_service.create_result(
		event_definition.event_id,
		SOURCE_EVENT,
		event_definition.event_id
	)
	return result


func _reject_missing_event() -> Variant:
	var result: Variant = _effect_service.create_result(&"", SOURCE_EVENT, &"")
	result.reject("missing event definition")
	return result
