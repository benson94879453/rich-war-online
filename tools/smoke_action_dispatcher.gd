extends SceneTree


var _failure_count: int = 0
var _dispatcher := ActionDispatcher.new()
var _allowed_player_id: int = -1


func _init() -> void:
	_run_smoke_check.call_deferred()


func _run_smoke_check() -> void:
	NetworkManager.stop_network()
	GameManager.state = null
	_expect_rejected(
		_dispatcher.submit_action(1, ActionDispatcher.ACTION_ROLL),
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
		_dispatcher.submit_action(1, ActionDispatcher.ACTION_ROLL, {}, Callable(self, "_can_control_player")),
		"not your turn",
		"roll rejects when peer cannot control current player"
	)

	_allowed_player_id = 0
	_expect_accepted(
		_dispatcher.submit_action(1, ActionDispatcher.ACTION_ROLL, {}, Callable(self, "_can_control_player")),
		"roll dispatches through GameManager when control is valid"
	)

	NetworkManager.stop_network()
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
	GameManager.start_local_game(players, board_data)


func _can_control_player(_sender_peer_id: int, player_id: int) -> bool:
	return player_id == _allowed_player_id


func _expect_accepted(result: Dictionary, label: String) -> void:
	if bool(result.get(ActionDispatcher.RESULT_ACCEPTED, false)):
		return

	_failure_count += 1
	push_error("%s: expected accepted, got %s" % [label, str(result)])


func _expect_rejected(result: Dictionary, expected_reason: String, label: String) -> void:
	if not bool(result.get(ActionDispatcher.RESULT_ACCEPTED, false)) and str(result.get(ActionDispatcher.RESULT_REJECTION_REASON, "")) == expected_reason:
		return

	_failure_count += 1
	push_error("%s: expected rejection %s, got %s" % [label, expected_reason, str(result)])
