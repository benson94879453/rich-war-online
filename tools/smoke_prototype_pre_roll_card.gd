extends SceneTree


const ActionDispatcherScript := preload("res://scripts/core/ActionDispatcher.gd")
const CardServiceScript := preload("res://scripts/core/CardService.gd")
const CardDefinitionScript := preload("res://scripts/core/CardDefinition.gd")
const PROTOTYPE_CARD_DISCARD_PILE := &"prototype_card_discard"


var _failure_count: int = 0
var _dispatcher := ActionDispatcherScript.new()
var _allowed_player_id: int = -1


func _init() -> void:
	_run_smoke_check.call_deferred()


func _run_smoke_check() -> void:
	var network_manager: Variant = _get_network_manager()
	var game_manager: Variant = _get_game_manager()
	if network_manager == null or game_manager == null:
		_failure_count += 1
		push_error("Required autoloads are not available.")
		return

	network_manager.stop_network()
	_start_local_game()
	_expect_initial_window(game_manager)
	_expect_snapshot_round_trip(game_manager)
	_expect_invalid_timing_rejected(game_manager)

	_start_local_game()
	_expect_successful_card_play(game_manager)

	_start_local_game()
	_expect_unused_window_does_not_block_roll(game_manager)

	network_manager.stop_network()
	if _failure_count == 0:
		print("PASS: Prototype pre-roll card smoke check")
		quit(0)
	else:
		push_error("FAIL: Prototype pre-roll card smoke check had %d failure(s)" % _failure_count)
		quit(1)


func _start_local_game() -> void:
	var board_data: BoardData = load("res://resources/maps/starq_board.tres") as BoardData
	var players: Array[PlayerState] = [
		PlayerState.new(0, "Player 1", 1500, 0, -1),
		PlayerState.new(1, "Player 2", 1500, 0, -1),
	]
	var game_manager: Variant = _get_game_manager()
	if game_manager != null:
		game_manager.start_local_game(players, board_data)


func _expect_initial_window(game_manager: Variant) -> void:
	_expect_true(game_manager.turn_system.can_roll(), "prototype card window leaves turn phase roll-ready")
	_expect_true(game_manager.state.has_pending_intervention(), "prototype pre-roll window is represented")
	_expect_true(game_manager.state.has_card_in_hand(1, CardServiceScript.CARD_PROTOTYPE_PRE_ROLL_GRANT), "prototype actor starts with the fixed card")

	var pending_intervention: Dictionary = game_manager.state.pending_intervention
	_expect_equal(CardDefinitionScript.TIMING_PRE_ROLL, pending_intervention.get("window_id", &""), "pre-roll window id is set")
	_expect_equal(1, int(pending_intervention.get("acting_player_id", -1)), "prototype actor is the non-current player")
	_expect_equal(0, int(pending_intervention.get("target_player_id", -1)), "prototype target is the current player")
	_expect_equal(CardServiceScript.CARD_PROTOTYPE_PRE_ROLL_GRANT, pending_intervention.get("card_id", &""), "prototype card id is fixed")


func _expect_snapshot_round_trip(game_manager: Variant) -> void:
	var snapshot: Dictionary = game_manager.get_state_snapshot()
	var restored_state: GameState = GameState.from_dict(snapshot)
	_expect_true(restored_state.has_pending_intervention(), "snapshot preserves pending card window")
	_expect_true(restored_state.has_card_in_hand(1, CardServiceScript.CARD_PROTOTYPE_PRE_ROLL_GRANT), "snapshot preserves prototype hand card")

	var pending_intervention: Dictionary = restored_state.pending_intervention
	_expect_equal(CardDefinitionScript.TIMING_PRE_ROLL, pending_intervention.get("window_id", &""), "snapshot preserves pre-roll window id")
	_expect_equal(0, int(pending_intervention.get("target_player_id", -1)), "snapshot preserves card target")


func _expect_invalid_timing_rejected(game_manager: Variant) -> void:
	game_manager.turn_system.begin_movement()
	_allowed_player_id = 1
	_expect_rejected(
		_dispatcher.submit_action(1, ActionDispatcherScript.ACTION_PLAY_CARD, _create_card_payload(), Callable(self, "_can_control_player")),
		"card window is not available",
		"card play rejects outside the roll-ready timing window"
	)
	game_manager.turn_system.begin_roll()


func _expect_successful_card_play(game_manager: Variant) -> void:
	var target_player: PlayerState = game_manager.state.get_player(0)
	var initial_money := target_player.money

	_allowed_player_id = 1
	_expect_accepted(
		_dispatcher.submit_action(1, ActionDispatcherScript.ACTION_PLAY_CARD, _create_card_payload(), Callable(self, "_can_control_player")),
		"valid prototype pre-roll card play is accepted"
	)

	_expect_equal(initial_money + 50, target_player.money, "prototype card applies deterministic money effect to target")
	_expect_false(game_manager.state.has_card_in_hand(1, CardServiceScript.CARD_PROTOTYPE_PRE_ROLL_GRANT), "prototype card is consumed from hand")
	_expect_true(game_manager.state.get_discard_pile(PROTOTYPE_CARD_DISCARD_PILE).has(CardServiceScript.CARD_PROTOTYPE_PRE_ROLL_GRANT), "prototype card moves to discard")
	_expect_false(game_manager.state.has_pending_intervention(), "successful card play clears the pending window")

	_expect_rejected(
		_dispatcher.submit_action(1, ActionDispatcherScript.ACTION_PLAY_CARD, _create_card_payload(), Callable(self, "_can_control_player")),
		"no card intervention pending",
		"used prototype card cannot be replayed without a new window"
	)


func _expect_unused_window_does_not_block_roll(game_manager: Variant) -> void:
	_allowed_player_id = 0
	_expect_true(game_manager.state.has_pending_intervention(), "unused pre-roll window exists before roll")
	_expect_accepted(
		_dispatcher.submit_action(1, ActionDispatcherScript.ACTION_ROLL, {}, Callable(self, "_can_control_player")),
		"current player can roll without using the prototype card window"
	)
	_expect_false(game_manager.state.has_pending_intervention(), "rolling clears the unused pre-roll window")


func _create_card_payload() -> Dictionary:
	return {
		ActionDispatcherScript.PAYLOAD_PLAYER_ID: 1,
		ActionDispatcherScript.PAYLOAD_CARD_ID: CardServiceScript.CARD_PROTOTYPE_PRE_ROLL_GRANT,
		ActionDispatcherScript.PAYLOAD_WINDOW_ID: CardDefinitionScript.TIMING_PRE_ROLL,
		ActionDispatcherScript.PAYLOAD_TARGET_PLAYER_ID: 0,
	}


func _get_game_manager() -> Variant:
	return root.get_node_or_null("/root/GameManager")


func _get_network_manager() -> Variant:
	return root.get_node_or_null("/root/NetworkManager")


func _can_control_player(_sender_peer_id: int, player_id: int) -> bool:
	return player_id == _allowed_player_id


func _expect_accepted(result: Dictionary, label: String) -> void:
	if bool(result.get(ActionDispatcherScript.RESULT_ACCEPTED, false)):
		return

	_failure_count += 1
	push_error("%s: expected accepted, got %s" % [label, str(result)])


func _expect_rejected(result: Dictionary, expected_reason: String, label: String) -> void:
	if not bool(result.get(ActionDispatcherScript.RESULT_ACCEPTED, false)) and str(result.get(ActionDispatcherScript.RESULT_REJECTION_REASON, "")) == expected_reason:
		return

	_failure_count += 1
	push_error("%s: expected rejection %s, got %s" % [label, expected_reason, str(result)])


func _expect_true(value: bool, label: String) -> void:
	if value:
		return

	_failure_count += 1
	push_error("%s: expected true" % label)


func _expect_false(value: bool, label: String) -> void:
	if not value:
		return

	_failure_count += 1
	push_error("%s: expected false" % label)


func _expect_equal(expected_value: Variant, actual_value: Variant, label: String) -> void:
	if expected_value == actual_value:
		return

	_failure_count += 1
	push_error("%s: expected %s, got %s" % [label, str(expected_value), str(actual_value)])
