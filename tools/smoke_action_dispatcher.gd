extends SceneTree


const ActionDispatcherScript := preload("res://scripts/core/ActionDispatcher.gd")


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
