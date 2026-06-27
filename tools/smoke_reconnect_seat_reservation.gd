extends SceneTree


var _failure_count: int = 0


func _init() -> void:
	_run_smoke_check.call_deferred()


func _run_smoke_check() -> void:
	NetworkManager.stop_network()
	NetworkManager.mode = NetworkManager.NetworkMode.HOST
	NetworkManager.local_player_id = 0
	NetworkManager.host_can_control_open_seats = true
	NetworkManager._assign_peer_to_player(1, 0)

	NetworkManager._reconnect_token_by_peer_id[101] = "known-client"
	NetworkManager._assign_peer_to_player(101, 1)
	_expect_equal(NetworkManager._player_id_by_reconnect_token.get("known-client", -1), 1, "token maps to assigned player")
	_expect_equal(NetworkManager._reconnect_token_by_player_id.get(1, ""), "known-client", "assigned player maps back to token")

	NetworkManager._on_peer_disconnected(101)
	_expect_true(NetworkManager._is_player_seat_reserved(1), "known client disconnect reserves seat")
	_expect_true(not NetworkManager._peer_id_by_player_id.has(1), "reserved seat has no active peer")
	_expect_equal(NetworkManager._player_id_by_reconnect_token.get("known-client", -1), 1, "reserved seat keeps token mapping")
	_expect_equal(NetworkManager._get_next_available_player_id(), 2, "reserved seat is skipped by open-seat assignment")
	_expect_true(not NetworkManager.can_control_player(1), "host open-seat control cannot control reserved seat")
	_expect_true(NetworkManager.can_control_player(2), "host open-seat control can still control truly open seat")

	NetworkManager._assign_peer_to_player(102, 2)
	NetworkManager._on_peer_disconnected(102)
	_expect_true(not NetworkManager._is_player_seat_reserved(2), "unknown client disconnect does not reserve seat")
	_expect_equal(NetworkManager._get_next_available_player_id(), 2, "unreserved disconnected seat becomes available")

	NetworkManager.stop_network()
	if _failure_count == 0:
		print("PASS: Reconnect seat reservation smoke check")
		quit(0)
	else:
		push_error("FAIL: Reconnect seat reservation smoke check had %d failure(s)" % _failure_count)
		quit(1)


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
