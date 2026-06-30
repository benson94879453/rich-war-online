extends SceneTree


const ActionDispatcherScript := preload("res://scripts/core/ActionDispatcher.gd")
const CardServiceScript := preload("res://scripts/core/CardService.gd")
const CardDefinitionScript := preload("res://scripts/core/CardDefinition.gd")


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
	game_manager.state = null
	_expect_rejected(
		_dispatcher.submit_action(1, ActionDispatcherScript.ACTION_ROLL),
		"game not ready",
		"roll rejects when game is not ready"
	)

	_start_local_game()
	_expect_rejected(
		_dispatcher.submit_action(1, "unsupported_action", {}, Callable(self, "_can_control_player")),
		"unknown intent",
		"unknown action rejects clearly"
	)

	_allowed_player_id = 1
	_expect_rejected(
		_dispatcher.submit_action(1, ActionDispatcherScript.ACTION_ROLL, {}, Callable(self, "_can_control_player")),
		"not your turn",
		"roll rejects when peer cannot control current player"
	)

	game_manager.state.clear_pending_intervention()
	_expect_rejected(
		_dispatcher.submit_action(1, ActionDispatcherScript.ACTION_PLAY_CARD, _create_card_payload(1), Callable(self, "_can_control_player")),
		"no card intervention pending",
		"card play rejects when no intervention is pending"
	)
	_expect_false(
		network_manager.submit_play_card(1, CardServiceScript.CARD_PROTOTYPE_PRE_ROLL_GRANT, CardDefinitionScript.TIMING_PRE_ROLL, 0),
		"NetworkManager card envelope rejects when no intervention is pending"
	)

	_begin_card_intervention()

	_allowed_player_id = 0
	_expect_rejected(
		_dispatcher.submit_action(1, ActionDispatcherScript.ACTION_PLAY_CARD, _create_card_payload(1), Callable(self, "_can_control_player")),
		"not your card action",
		"card play rejects when peer cannot control the card player"
	)

	_allowed_player_id = 1
	_expect_rejected(
		_dispatcher.submit_action(1, ActionDispatcherScript.ACTION_PLAY_CARD, _create_card_payload(2), Callable(self, "_can_control_player")),
		"not your card action",
		"card play rejects when the actor does not match the pending intervention"
	)
	_expect_rejected(
		_dispatcher.submit_action(1, ActionDispatcherScript.ACTION_PLAY_CARD, _create_card_payload(1, &"missing_card"), Callable(self, "_can_control_player")),
		"card not in hand",
		"card play rejects when the player does not hold the card"
	)
	_expect_rejected(
		_dispatcher.submit_action(1, ActionDispatcherScript.ACTION_PLAY_CARD, _create_card_payload(1, CardServiceScript.CARD_PROTOTYPE_PRE_ROLL_GRANT, &"wrong_window"), Callable(self, "_can_control_player")),
		"card window mismatch",
		"card play rejects when the window does not match"
	)
	_expect_rejected(
		_dispatcher.submit_action(1, ActionDispatcherScript.ACTION_PLAY_CARD, _create_card_payload(1, CardServiceScript.CARD_PROTOTYPE_PRE_ROLL_GRANT, CardDefinitionScript.TIMING_PRE_ROLL, 1), Callable(self, "_can_control_player")),
		"invalid card target",
		"card play rejects when the target does not match"
	)
	_expect_accepted(
		_dispatcher.submit_action(1, ActionDispatcherScript.ACTION_PLAY_CARD, _create_card_payload(1), Callable(self, "_can_control_player")),
		"card play accepts a valid pending intervention envelope"
	)
	_begin_card_intervention()
	_expect_true(
		network_manager.submit_play_card(1, CardServiceScript.CARD_PROTOTYPE_PRE_ROLL_GRANT, CardDefinitionScript.TIMING_PRE_ROLL, 0),
		"NetworkManager card envelope accepts a valid pending intervention"
	)

	game_manager.state.clear_pending_intervention()
	game_manager.turn_system.begin_roll()

	_allowed_player_id = 0
	_expect_accepted(
		_dispatcher.submit_action(1, ActionDispatcherScript.ACTION_ROLL, {}, Callable(self, "_can_control_player")),
		"roll dispatches through game manager when control is valid"
	)

	network_manager.stop_network()
	if _failure_count == 0:
		print("PASS: ActionDispatcher smoke check")
		quit(0)
	else:
		push_error("FAIL: ActionDispatcher smoke check had %d failure(s)" % _failure_count)
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


func _begin_card_intervention() -> void:
	var game_manager: Variant = _get_game_manager()
	if game_manager == null or game_manager.state == null:
		return

	game_manager.state.add_card_to_hand(1, CardServiceScript.CARD_PROTOTYPE_PRE_ROLL_GRANT)
	game_manager.state.begin_pending_intervention(
		CardDefinitionScript.TIMING_PRE_ROLL,
		1,
		[1],
		0,
		CardServiceScript.CARD_PROTOTYPE_PRE_ROLL_GRANT
	)
	game_manager.turn_system.begin_pre_roll_window()


func _create_card_payload(
		player_id: int,
		card_id: StringName = CardServiceScript.CARD_PROTOTYPE_PRE_ROLL_GRANT,
		window_id: StringName = CardDefinitionScript.TIMING_PRE_ROLL,
		target_player_id: int = 0
) -> Dictionary:
	return {
		ActionDispatcherScript.PAYLOAD_PLAYER_ID: player_id,
		ActionDispatcherScript.PAYLOAD_CARD_ID: card_id,
		ActionDispatcherScript.PAYLOAD_WINDOW_ID: window_id,
		ActionDispatcherScript.PAYLOAD_TARGET_PLAYER_ID: target_player_id,
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


func _expect_rejected(result: Dictionary, expected_reason: String, label: String) -> void:
	if not bool(result.get(ActionDispatcherScript.RESULT_ACCEPTED, false)) and str(result.get(ActionDispatcherScript.RESULT_REJECTION_REASON, "")) == expected_reason:
		return

	_failure_count += 1
	push_error("%s: expected rejection %s, got %s" % [label, expected_reason, str(result)])
