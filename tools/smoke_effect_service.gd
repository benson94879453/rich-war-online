extends SceneTree


var _failure_count: int = 0


func _init() -> void:
	_run_smoke_check()
	if _failure_count == 0:
		print("PASS: EffectService smoke check")
		quit(0)
	else:
		push_error("FAIL: EffectService smoke check had %d failure(s)" % _failure_count)
		quit(1)


func _run_smoke_check() -> void:
	var service := EffectService.new()
	var player := PlayerState.new(0, "Player 1", 1000, 0, -1)
	var money_tile := BoardTileData.new()
	money_tile.index = 12
	money_tile.display_name = "Ticket"
	money_tile.money_delta = 30
	money_tile.effect_id = &"starq_ticket"

	var money_result: EffectResult = service.apply_tile_effect(player, money_tile)
	_expect_true(money_result.was_applied, "money tile effect applies")
	_expect_equal(player.money, 1030, "money tile changes player money")
	_expect_equal(money_result.effect_id, &"starq_ticket", "money tile preserves tile effect id")
	_expect_equal(money_result.source_type, EffectService.SOURCE_TILE, "money tile records tile source type")
	_expect_equal(money_result.source_id, &"starq_ticket", "money tile records tile source id")
	_expect_equal(money_result.money_delta, 30, "money delta is recorded")
	_expect_equal(money_result.money_after, 1030, "money after is recorded")

	var safe_tile := BoardTileData.new()
	safe_tile.index = 13
	safe_tile.display_name = "Safe"
	safe_tile.effect_id = &"safe"
	var safe_result: EffectResult = service.apply_tile_effect(player, safe_tile)
	_expect_true(not safe_result.was_applied, "non-money tile effect is a no-op")
	_expect_true(not safe_result.is_rejected(), "non-money tile no-op is not rejected")
	_expect_equal(player.money, 1030, "non-money tile does not change player money")

	var unsupported_result: EffectResult = service.apply_effect(&"unsupported_effect")
	_expect_true(not unsupported_result.was_applied, "unsupported effect does not apply")
	_expect_true(unsupported_result.is_rejected(), "unsupported effect is rejected")
	_expect_equal(unsupported_result.rejection_reason, "unsupported effect", "unsupported effect rejection reason is explicit")


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
