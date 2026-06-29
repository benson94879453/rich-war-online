extends SceneTree


const EventDefinitionScript := preload("res://scripts/core/EventDefinition.gd")
const EventServiceScript := preload("res://scripts/core/EventService.gd")


var _failure_count: int = 0


func _init() -> void:
	_run_smoke_check()
	if _failure_count == 0:
		print("PASS: EventService smoke check")
		quit(0)
	else:
		push_error("FAIL: EventService smoke check had %d failure(s)" % _failure_count)
		quit(1)


func _run_smoke_check() -> void:
	var service: Variant = EventServiceScript.new()
	var player := PlayerState.new(0, "Player 1", 1000, 0, -1)
	var money_event: Variant = EventDefinitionScript.new(
		&"prototype_bonus",
		"Prototype bonus",
		&"money_delta",
		75
	)

	var money_result: Variant = service.apply_event(money_event, {
		EventServiceScript.CONTEXT_PLAYER: player,
	})
	_expect_true(money_result.was_applied, "money event applies")
	_expect_equal(player.money, 1075, "money event changes player money")
	_expect_equal(money_result.effect_id, &"prototype_bonus", "money event result preserves event id")
	_expect_equal(money_result.source_type, EventServiceScript.SOURCE_EVENT, "money event records event source type")
	_expect_equal(money_result.source_id, &"prototype_bonus", "money event records event source id")
	_expect_equal(money_result.money_delta, 75, "money event records delta")
	_expect_equal(money_result.money_after, 1075, "money event records money after")

	var noop_event: Variant = EventDefinitionScript.new(
		&"prototype_noop",
		"Prototype no-op",
		&"money_delta",
		0
	)
	var noop_result: Variant = service.apply_event(noop_event, {
		EventServiceScript.CONTEXT_PLAYER: player,
	})
	_expect_true(not noop_result.was_applied, "zero money event is a no-op")
	_expect_true(not noop_result.is_rejected(), "zero money event no-op is not rejected")
	_expect_equal(noop_result.source_id, &"prototype_noop", "zero money event records source id")
	_expect_equal(player.money, 1075, "zero money event does not change player money")

	var unsupported_result: Variant = service.apply_event(null, {
		EventServiceScript.CONTEXT_PLAYER: player,
	})
	_expect_true(not unsupported_result.was_applied, "missing event does not apply")
	_expect_true(unsupported_result.is_rejected(), "missing event is rejected")
	_expect_equal(unsupported_result.rejection_reason, "missing event definition", "missing event rejection reason is explicit")
	_expect_equal(player.money, 1075, "missing event does not change player money")


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
