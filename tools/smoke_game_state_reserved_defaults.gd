extends SceneTree


var _failure_count: int = 0


func _init() -> void:
	_run_smoke_check()
	if _failure_count == 0:
		print("PASS: GameState reserved defaults smoke check")
		quit(0)
	else:
		push_error("FAIL: GameState reserved defaults smoke check had %d failure(s)" % _failure_count)
		quit(1)


func _run_smoke_check() -> void:
	var state := GameState.new()
	state.initialize([
		PlayerState.new(0, "Player 1", 1500, 0, -1),
		PlayerState.new(1, "Player 2", 1500, 0, -1),
	])

	_expect_equal(state.hands_by_player_id, {}, "hands default empty")
	_expect_equal(state.deck_states, {}, "deck states default empty")
	_expect_equal(state.discard_piles, {}, "discard piles default empty")
	_expect_equal(state.status_by_player_id, {}, "statuses default empty")
	_expect_equal(state.pending_intervention, {}, "pending intervention default empty")
	_expect_true(not state.game_over, "game over default false")
	_expect_equal(state.winner_player_id, -1, "winner default unset")
	_expect_equal(state.round_limit, 20, "round limit default")

	var restored := GameState.from_dict(state.to_dict())
	_expect_equal(restored.hands_by_player_id, {}, "hands default survives restore")
	_expect_equal(restored.deck_states, {}, "deck states default survives restore")
	_expect_equal(restored.discard_piles, {}, "discard piles default survives restore")
	_expect_equal(restored.status_by_player_id, {}, "statuses default survives restore")
	_expect_equal(restored.pending_intervention, {}, "pending intervention default survives restore")
	_expect_true(not restored.game_over, "game over default survives restore")
	_expect_equal(restored.winner_player_id, -1, "winner default survives restore")
	_expect_equal(restored.round_limit, 20, "round limit default survives restore")

	var legacy_restored := GameState.from_dict({})
	_expect_equal(legacy_restored.hands_by_player_id, {}, "legacy snapshot gets hands default")
	_expect_equal(legacy_restored.deck_states, {}, "legacy snapshot gets deck states default")
	_expect_equal(legacy_restored.discard_piles, {}, "legacy snapshot gets discard piles default")
	_expect_equal(legacy_restored.status_by_player_id, {}, "legacy snapshot gets statuses default")
	_expect_equal(legacy_restored.pending_intervention, {}, "legacy snapshot gets pending intervention default")
	_expect_true(not legacy_restored.game_over, "legacy snapshot gets game over default")
	_expect_equal(legacy_restored.winner_player_id, -1, "legacy snapshot gets winner default")
	_expect_equal(legacy_restored.round_limit, 20, "legacy snapshot gets round limit default")


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
