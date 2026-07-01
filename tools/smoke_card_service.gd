extends SceneTree


const CardDefinitionScript := preload("res://scripts/core/CardDefinition.gd")
const CardServiceScript := preload("res://scripts/core/CardService.gd")
const EffectServiceScript := preload("res://scripts/core/EffectService.gd")


var _failure_count: int = 0


func _init() -> void:
	_run_smoke_check()
	if _failure_count == 0:
		print("PASS: CardService smoke check")
		quit(0)
	else:
		push_error("FAIL: CardService smoke check had %d failure(s)" % _failure_count)
		quit(1)


func _run_smoke_check() -> void:
	var service: Variant = CardServiceScript.new()
	var card: CardDefinition = service.create_prototype_pre_roll_card(60)
	_expect_equal(card.card_id, CardServiceScript.CARD_PROTOTYPE_PRE_ROLL_GRANT, "prototype card id")
	_expect_equal(card.timing_window, CardDefinitionScript.TIMING_PRE_ROLL, "prototype timing window")
	_expect_equal(card.target_rule, CardDefinitionScript.TARGET_CURRENT_PLAYER, "prototype target rule")
	_expect_equal(card.effect_id, EffectServiceScript.EFFECT_MONEY_DELTA, "prototype effect id")
	_expect_equal(card.money_delta, 60, "prototype money delta")
	_expect_equal(card.display_name, "Prototype pre-roll grant", "prototype display name")
	_expect_true(not card.description.is_empty(), "prototype description is visible metadata")
	_expect_equal(card.get_effect_summary(), "+$60 to current player", "prototype effect summary")
	_expect_equal(card.get_target_summary(), "Current player", "prototype target summary")
	_expect_equal(card.get_art_path(), CardServiceScript.PROTOTYPE_PRE_ROLL_GRANT_ART_PATH, "prototype art path")
	_expect_true(card.has_art_path(), "prototype card has default test art reference")
	_expect_equal(service.validate_card_definition(card), "", "prototype card validates")

	var metadata: Dictionary = card.get_visible_metadata()
	_expect_equal(metadata.get("display_name", ""), "Prototype pre-roll grant", "metadata includes display name")
	_expect_equal(metadata.get("description", ""), card.description, "metadata includes description")
	_expect_equal(metadata.get("effect_summary", ""), "+$60 to current player", "metadata includes effect summary")
	_expect_equal(metadata.get("target_summary", ""), "Current player", "metadata includes target summary")
	_expect_equal(metadata.get("art_path", ""), CardServiceScript.PROTOTYPE_PRE_ROLL_GRANT_ART_PATH, "metadata includes art path")
	_expect_true(bool(metadata.get("has_art_path", false)), "metadata marks art path present")

	var no_art_card: CardDefinition = service.create_prototype_pre_roll_card(60, "")
	_expect_equal(no_art_card.get_art_path(), "", "empty art path is allowed")
	_expect_true(not no_art_card.has_art_path(), "empty art path is reported as absent")
	_expect_equal(service.validate_card_definition(no_art_card), "", "prototype card validates without art")

	var target := PlayerState.new(1, "Player 2", 900, 0, -1)
	var result: Variant = service.apply_card(card, {
		CardServiceScript.CONTEXT_TARGET_PLAYER: target,
	})
	_expect_true(result.was_applied, "prototype card applies")
	_expect_equal(target.money, 960, "prototype card changes target money")
	_expect_equal(result.effect_id, CardServiceScript.CARD_PROTOTYPE_PRE_ROLL_GRANT, "card result preserves card id")
	_expect_equal(result.source_type, CardServiceScript.SOURCE_CARD, "card result records card source type")
	_expect_equal(result.source_id, CardServiceScript.CARD_PROTOTYPE_PRE_ROLL_GRANT, "card result records card source id")
	_expect_equal(result.money_delta, 60, "card result records money delta")
	_expect_equal(result.money_after, 960, "card result records money after")

	var missing_target_result: Variant = service.apply_card(card, {})
	_expect_true(not missing_target_result.was_applied, "missing target does not apply")
	_expect_true(missing_target_result.is_rejected(), "missing target is rejected")
	_expect_equal(missing_target_result.rejection_reason, "missing target player", "missing target rejection reason")

	var malformed_card := CardDefinitionScript.new(
		&"bad_card",
		"Bad card",
		CardDefinitionScript.TIMING_PRE_ROLL,
		CardDefinitionScript.TARGET_CURRENT_PLAYER,
		&"unsupported_effect",
		10
	)
	var malformed_result: Variant = service.apply_card(malformed_card, {
		CardServiceScript.CONTEXT_TARGET_PLAYER: target,
	})
	_expect_true(not malformed_result.was_applied, "unsupported card does not apply")
	_expect_true(malformed_result.is_rejected(), "unsupported card is rejected")
	_expect_equal(malformed_result.rejection_reason, "unsupported card effect", "unsupported card rejection reason")
	_expect_equal(target.money, 960, "unsupported card does not change target money")

	var zero_money_card: CardDefinition = service.create_prototype_pre_roll_card(0)
	_expect_equal(service.validate_card_definition(zero_money_card), "missing money effect", "zero money card is invalid")

	var missing_card_result: Variant = service.apply_card(null, {
		CardServiceScript.CONTEXT_TARGET_PLAYER: target,
	})
	_expect_true(missing_card_result.is_rejected(), "missing card is rejected")
	_expect_equal(missing_card_result.rejection_reason, "missing card definition", "missing card rejection reason")


func _expect_true(value: bool, label: String) -> void:
	if value:
		return

	_failure_count += 1
	push_error("Expected true: %s" % label)


func _expect_equal(actual: Variant, expected: Variant, label: String) -> void:
	if actual == expected:
		return

	_failure_count += 1
	push_error("%s: expected %s, got %s" % [label, str(expected), str(actual)])
