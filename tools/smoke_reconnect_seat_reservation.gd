extends SceneTree


var _failure_count: int = 0


func _init() -> void:
	_run_smoke_check.call_deferred()


func _run_smoke_check() -> void:
	var network_manager: Variant = _get_network_manager()
	if network_manager == null:
		_failure_count += 1
		push_error("NetworkManager autoload is not available.")
		return

	network_manager.stop_network()
	network_manager.mode = network_manager.NetworkMode.HOST
	network_manager.local_player_id = 0
	network_manager.host_can_control_open_seats = true
	network_manager._assign_peer_to_player(1, 0)

	network_manager._reconnect_token_by_peer_id[101] = "known-client"
	network_manager._assign_peer_to_player(101, 1)
	_expect_equal(network_manager._player_id_by_reconnect_token.get("known-client", -1), 1, "token maps to assigned player")
	_expect_equal(network_manager._reconnect_token_by_player_id.get(1, ""), "known-client", "assigned player maps back to token")

	network_manager._on_peer_disconnected(101)
	_expect_true(network_manager._is_player_seat_reserved(1), "known client disconnect reserves seat")
	_expect_true(not network_manager._peer_id_by_player_id.has(1), "reserved seat has no active peer")
	_expect_equal(network_manager._player_id_by_reconnect_token.get("known-client", -1), 1, "reserved seat keeps token mapping")
	_expect_equal(network_manager._get_next_available_player_id(), 2, "reserved seat is skipped by open-seat assignment")
	_expect_true(not network_manager.can_control_player(1), "host open-seat control cannot control reserved seat")
	_expect_true(network_manager.can_control_player(2), "host open-seat control can still control truly open seat")

	network_manager._assign_peer_to_player(102, 2)
	network_manager._on_peer_disconnected(102)
	_expect_true(not network_manager._is_player_seat_reserved(2), "unknown client disconnect does not reserve seat")
	_expect_equal(network_manager._get_next_available_player_id(), 2, "unreserved disconnected seat becomes available")

	network_manager.stop_network()
	if _failure_count == 0:
		print("PASS: Reconnect seat reservation smoke check")
		quit(0)
	else:
		push_error("FAIL: Reconnect seat reservation smoke check had %d failure(s)" % _failure_count)
		quit(1)


func _get_network_manager() -> Variant:
	return root.get_node_or_null("/root/NetworkManager")


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
