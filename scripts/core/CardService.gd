extends RefCounted
class_name CardService


const CARD_PROTOTYPE_PRE_ROLL_GRANT := &"prototype_pre_roll_grant"
const SOURCE_CARD := &"card"
const PROTOTYPE_PRE_ROLL_GRANT_ART_PATH := "res://assets/cards/test/prototype_pre_roll_grant.png"

const CONTEXT_TARGET_PLAYER := "target_player"

const EffectServiceScript := preload("res://scripts/core/EffectService.gd")
const CardDefinitionScript := preload("res://scripts/core/CardDefinition.gd")


var _effect_service: Variant = EffectServiceScript.new()


func create_prototype_pre_roll_card(money_delta: int = 50, art_path: String = PROTOTYPE_PRE_ROLL_GRANT_ART_PATH) -> CardDefinition:
	return CardDefinitionScript.new(
		CARD_PROTOTYPE_PRE_ROLL_GRANT,
		"Prototype pre-roll grant",
		CardDefinitionScript.TIMING_PRE_ROLL,
		CardDefinitionScript.TARGET_CURRENT_PLAYER,
		EffectServiceScript.EFFECT_MONEY_DELTA,
		money_delta,
		"Grants money to the current player during the prototype pre-roll window.",
		"+$%d to current player" % money_delta,
		"Current player",
		art_path
	)


func validate_card_definition(card_definition: CardDefinition) -> String:
	if card_definition == null:
		return "missing card definition"

	if card_definition.card_id == &"":
		return "missing card id"

	if card_definition.timing_window == &"":
		return "missing timing window"

	if card_definition.target_rule == &"":
		return "missing target rule"

	if card_definition.effect_id != EffectServiceScript.EFFECT_MONEY_DELTA:
		return "unsupported card effect"

	if not card_definition.has_money_effect():
		return "missing money effect"

	return ""


func apply_card(card_definition: CardDefinition, context: Dictionary = {}) -> Variant:
	var validation_error: String = validate_card_definition(card_definition)
	if not validation_error.is_empty():
		return _reject_card(card_definition, validation_error)

	var target_player: PlayerState = context.get(CONTEXT_TARGET_PLAYER, null) as PlayerState
	if target_player == null:
		return _reject_card(card_definition, "missing target player")

	var result: Variant = _effect_service.apply_effect(EffectServiceScript.EFFECT_MONEY_DELTA, {
		EffectServiceScript.CONTEXT_PLAYER: target_player,
		EffectServiceScript.CONTEXT_MONEY_DELTA: card_definition.money_delta,
		EffectServiceScript.CONTEXT_SOURCE_TYPE: SOURCE_CARD,
		EffectServiceScript.CONTEXT_SOURCE_ID: card_definition.card_id,
	})
	result.effect_id = card_definition.card_id
	return result


func _reject_card(card_definition: CardDefinition, reason: String) -> Variant:
	var card_id: StringName = card_definition.card_id if card_definition != null else &""
	var result: Variant = _effect_service.create_result(card_id, SOURCE_CARD, card_id)
	result.reject(reason)
	return result
