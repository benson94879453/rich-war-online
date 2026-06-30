extends SceneTree


const CardServiceScript := preload("res://scripts/core/CardService.gd")


var _failure_count: int = 0


func _init() -> void:
	_run_smoke_check()
	if _failure_count == 0:
		print("PASS: GameState card state smoke check")
		quit(0)
	else:
		push_error("FAIL: GameState card state smoke check had %d failure(s)" % _failure_count)
		quit(1)


func _run_smoke_check() -> void:
	var state := GameState.new()
	state.initialize([
		PlayerState.new(0, "Player 1", 1500, 0, -1),
		PlayerState.new(1, "Player 2", 1500, 0, -1),
	])

	var prototype_card: StringName = CardServiceScript.CARD_PROTOTYPE_PRE_ROLL_GRANT
	state.add_card_to_hand(0, prototype_card)
	state.add_card_to_hand(0, &"prototype_shield")
	state.set_player_hand(1, [&"prototype_swap"])

	_expect_equal(state.get_player_hand(0), [prototype_card, &"prototype_shield"], "player 1 hand helper stores cards")
	_expect_true(state.has_card_in_hand(0, prototype_card), "hand helper finds card")
	_expect_true(state.remove_card_from_hand(0, prototype_card), "hand helper removes card")
	_expect_true(not state.remove_card_from_hand(0, prototype_card), "hand helper rejects missing card removal")
	_expect_equal(state.get_player_hand(0), [&"prototype_shield"], "hand helper persists removal")

	state.set_deck_cards(&"intervention", [prototype_card, &"prototype_shield"])
	_expect_equal(state.get_deck_cards(&"intervention"), [prototype_card, &"prototype_shield"], "deck helper stores card list")

	state.add_card_to_discard(&"intervention", prototype_card)
	state.add_card_to_discard(&"intervention", &"prototype_shield")
	_expect_equal(state.get_discard_pile(&"intervention"), [prototype_card, &"prototype_shield"], "discard helper stores card list")

	state.begin_pending_intervention(&"pre_roll", 1, [0], 0, prototype_card)
	_expect_true(state.has_pending_intervention(), "pending intervention helper marks pending")
	_expect_equal(state.pending_intervention, {
		"window_id": &"pre_roll",
		"acting_player_id": 1,
		"eligible_players": [0],
		"target_player_id": 0,
		"card_id": prototype_card,
	}, "pending intervention helper stores metadata")

	var restored := GameState.from_dict(state.to_dict())
	_expect_equal(restored.get_player_hand(0), [&"prototype_shield"], "player hand survives snapshot round-trip")
	_expect_equal(restored.get_player_hand(1), [&"prototype_swap"], "second player hand survives snapshot round-trip")
	_expect_equal(restored.get_deck_cards(&"intervention"), [prototype_card, &"prototype_shield"], "deck cards survive snapshot round-trip")
	_expect_equal(restored.get_discard_pile(&"intervention"), [prototype_card, &"prototype_shield"], "discard pile survives snapshot round-trip")
	_expect_true(restored.has_pending_intervention(), "pending intervention survives snapshot round-trip")
	_expect_equal(restored.pending_intervention.get("card_id", &""), prototype_card, "pending intervention card id survives snapshot round-trip")

	restored.clear_pending_intervention()
	_expect_true(not restored.has_pending_intervention(), "pending intervention helper clears state")
	_expect_equal(restored.pending_intervention, {}, "pending intervention dictionary is empty after clear")

	var exported_hand: Array = restored.get_player_hand(0)
	exported_hand.append(&"external_mutation")
	_expect_equal(restored.get_player_hand(0), [&"prototype_shield"], "hand getter returns defensive copy")


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
