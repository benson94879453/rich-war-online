extends SceneTree


const BOARD_RESOURCE_PATH := "res://resources/maps/starq_board.tres"
const ActionDispatcherScript := preload("res://scripts/core/ActionDispatcher.gd")
const CardServiceScript := preload("res://scripts/core/CardService.gd")
const CardDefinitionScript := preload("res://scripts/core/CardDefinition.gd")
const PROTOTYPE_CARD_DISCARD_PILE := &"prototype_card_discard"


var _failure_count: int = 0
var _dispatcher := ActionDispatcherScript.new()
var _allowed_player_id: int = -1


func _init() -> void:
	_run_scenario.call_deferred()


func _run_scenario() -> void:
	var network_manager: Variant = _get_network_manager()
	var game_manager: Variant = _get_game_manager()
	if network_manager == null or game_manager == null:
		_fail("Required autoloads are not available.")
		_finish()
		return

	network_manager.stop_network()
	var board_data: BoardData = load(BOARD_RESOURCE_PATH) as BoardData
	if board_data == null:
		_fail("Could not load active board resource: %s" % BOARD_RESOURCE_PATH)
		_finish()
		return

	_start_local_game(game_manager, board_data)
	_expect_initial_card_window(game_manager)
	_expect_invalid_actor_rejected()
	_expect_snapshot_round_trip(game_manager, "before card play")
	_expect_valid_card_play(game_manager)
	_expect_snapshot_round_trip(game_manager, "after card play")
	_expect_turn_continues_after_card(game_manager)

	network_manager.stop_network()
	_finish()


func _start_local_game(game_manager: Variant, board_data: BoardData) -> void:
	var players: Array[PlayerState] = [
		PlayerState.new(0, "Player 1", 1500, 0, -1),
		PlayerState.new(1, "Player 2", 1500, 0, -1),
	]
	game_manager.start_local_game(players, board_data)


func _expect_initial_card_window(game_manager: Variant) -> void:
	_expect_true(game_manager.turn_system.can_roll(), "card window keeps the turn roll-ready")
	_expect_true(game_manager.state.has_pending_intervention(), "card window is represented")
	_expect_true(game_manager.state.has_card_in_hand(1, CardServiceScript.CARD_PROTOTYPE_PRE_ROLL_GRANT), "acting player has the prototype card")

	var pending_intervention: Dictionary = game_manager.state.pending_intervention
	_expect_equal(CardDefinitionScript.TIMING_PRE_ROLL, pending_intervention.get("window_id", &""), "pending window is pre-roll")
	_expect_equal(1, int(pending_intervention.get("acting_player_id", -1)), "pending actor is Player 2")
	_expect_equal(0, int(pending_intervention.get("target_player_id", -1)), "pending target is Player 1")
	_expect_equal(CardServiceScript.CARD_PROTOTYPE_PRE_ROLL_GRANT, pending_intervention.get("card_id", &""), "pending card is the prototype card")


func _expect_invalid_actor_rejected() -> void:
	_allowed_player_id = 0
	var result: Dictionary = _dispatcher.submit_action(
		1,
		ActionDispatcherScript.ACTION_PLAY_CARD,
		_create_card_payload(),
		Callable(self, "_can_control_player")
	)
	_expect_rejected(result, "not your card action", "card play rejects when the sender cannot control the actor")


func _expect_valid_card_play(game_manager: Variant) -> void:
	var target_player: PlayerState = game_manager.state.get_player(0)
	var money_before := target_player.money

	_allowed_player_id = 1
	var result: Dictionary = _dispatcher.submit_action(
		1,
		ActionDispatcherScript.ACTION_PLAY_CARD,
		_create_card_payload(),
		Callable(self, "_can_control_player")
	)
	_expect_accepted(result, "valid card play is accepted through the action pipeline")

	_expect_equal(money_before + 50, target_player.money, "card play applies the prototype money delta")
	_expect_false(game_manager.state.has_card_in_hand(1, CardServiceScript.CARD_PROTOTYPE_PRE_ROLL_GRANT), "card play consumes the card from hand")
	_expect_true(game_manager.state.get_discard_pile(PROTOTYPE_CARD_DISCARD_PILE).has(CardServiceScript.CARD_PROTOTYPE_PRE_ROLL_GRANT), "card play moves the card to discard")
	_expect_false(game_manager.state.has_pending_intervention(), "card play clears the pending window")


func _expect_turn_continues_after_card(game_manager: Variant) -> void:
	_allowed_player_id = 0
	var result: Dictionary = _dispatcher.submit_action(
		1,
		ActionDispatcherScript.ACTION_ROLL,
		{},
		Callable(self, "_can_control_player")
	)
	_expect_accepted(result, "current player can roll after the card window resolves")
	_expect_false(game_manager.state.has_pending_intervention(), "roll continuation does not leave the used card window pending")


func _expect_snapshot_round_trip(game_manager: Variant, label: String) -> void:
	var snapshot: Dictionary = game_manager.get_state_snapshot()
	var restored := GameState.from_dict(snapshot)
	_expect_equal(game_manager.state.current_round, restored.current_round, "%s snapshot preserves current round" % label)
	_expect_equal(game_manager.state.get_current_player_id(), restored.get_current_player_id(), "%s snapshot preserves current player" % label)
	_expect_equal(game_manager.state.hands_by_player_id, restored.hands_by_player_id, "%s snapshot preserves hands" % label)
	_expect_equal(game_manager.state.discard_piles, restored.discard_piles, "%s snapshot preserves discard piles" % label)
	_expect_equal(game_manager.state.pending_intervention, restored.pending_intervention, "%s snapshot preserves pending card window" % label)


func _create_card_payload() -> Dictionary:
	return {
		ActionDispatcherScript.PAYLOAD_PLAYER_ID: 1,
		ActionDispatcherScript.PAYLOAD_CARD_ID: CardServiceScript.CARD_PROTOTYPE_PRE_ROLL_GRANT,
		ActionDispatcherScript.PAYLOAD_WINDOW_ID: CardDefinitionScript.TIMING_PRE_ROLL,
		ActionDispatcherScript.PAYLOAD_TARGET_PLAYER_ID: 0,
	}


func _can_control_player(_sender_peer_id: int, player_id: int) -> bool:
	return player_id == _allowed_player_id


func _get_game_manager() -> Variant:
	return root.get_node_or_null("/root/GameManager")


func _get_network_manager() -> Variant:
	return root.get_node_or_null("/root/NetworkManager")


func _finish() -> void:
	if _failure_count == 0:
		print("PASS: Card window pipeline scenario")
		quit(0)
	else:
		push_error("FAIL: Card window pipeline scenario had %d failure(s)" % _failure_count)
		quit(1)


func _expect_accepted(result: Dictionary, label: String) -> void:
	if bool(result.get(ActionDispatcherScript.RESULT_ACCEPTED, false)):
		return

	_fail("%s: expected accepted, got %s" % [label, str(result)])


func _expect_rejected(result: Dictionary, expected_reason: String, label: String) -> void:
	if not bool(result.get(ActionDispatcherScript.RESULT_ACCEPTED, false)) and str(result.get(ActionDispatcherScript.RESULT_REJECTION_REASON, "")) == expected_reason:
		return

	_fail("%s: expected rejection %s, got %s" % [label, expected_reason, str(result)])


func _expect_true(value: bool, label: String) -> void:
	if value:
		return

	_fail("Expected true: %s" % label)


func _expect_false(value: bool, label: String) -> void:
	if not value:
		return

	_fail("Expected false: %s" % label)


func _expect_equal(actual: Variant, expected: Variant, label: String) -> void:
	if actual == expected:
		return

	_fail("%s: expected %s, got %s" % [label, str(expected), str(actual)])


func _fail(message: String) -> void:
	_failure_count += 1
	push_error(message)
