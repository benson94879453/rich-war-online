extends SceneTree


var _failure_count: int = 0


func _init() -> void:
	_run_smoke_check.call_deferred()


func _run_smoke_check() -> void:
	_run_matching_token_reassign_check()
	_run_unknown_token_join_check()

	var network_manager: Variant = _get_network_manager()
	if network_manager != null:
		network_manager.stop_network()
	if _failure_count == 0:
		print("PASS: Reconnect reserved seat reassign smoke check")
		quit(0)
	else:
		push_error("FAIL: Reconnect reserved seat reassign smoke check had %d failure(s)" % _failure_count)
		quit(1)


func _run_matching_token_reassign_check() -> void:
	_prepare_host_reservation("known-client")
	var network_manager: Variant = _get_network_manager()
	if network_manager == null:
		_failure_count += 1
		push_error("NetworkManager autoload is not available.")
		return

	var reconnect_peer_id := 202
	var temporary_player_id: int = network_manager._get_next_available_player_id()
	network_manager._assign_peer_to_player(reconnect_peer_id, temporary_player_id)

	_expect_equal(temporary_player_id, 2, "reconnecting peer first receives next non-reserved seat")
	network_manager._handle_peer_reconnect_token(reconnect_peer_id, "known-client", false)

	_expect_equal(network_manager._player_id_by_peer_id.get(reconnect_peer_id, -1), 1, "matching token reclaims reserved seat")
	_expect_equal(network_manager._peer_id_by_player_id.get(1, -1), reconnect_peer_id, "reserved seat maps to reconnecting peer")
	_expect_true(not network_manager._is_player_seat_reserved(1), "reclaimed seat is no longer reserved")
	_expect_true(not network_manager._peer_id_by_player_id.has(2), "temporary seat is released after reclaim")
	_expect_equal(network_manager._get_next_available_player_id(), 2, "released temporary seat becomes available")
	_expect_true(network_manager._can_peer_control_player(reconnect_peer_id, 1), "reconnected peer controls reclaimed seat")
	_expect_true(not network_manager._can_peer_control_player(reconnect_peer_id, 2), "reconnected peer does not control temporary seat")


func _run_unknown_token_join_check() -> void:
	_prepare_host_reservation("known-client")
	var network_manager: Variant = _get_network_manager()
	if network_manager == null:
		_failure_count += 1
		push_error("NetworkManager autoload is not available.")
		return

	var new_peer_id := 303
	var assigned_player_id: int = network_manager._get_next_available_player_id()
	network_manager._assign_peer_to_player(new_peer_id, assigned_player_id)
	network_manager._handle_peer_reconnect_token(new_peer_id, "unknown-client", false)

	_expect_equal(assigned_player_id, 2, "unknown token receives next non-reserved seat")
	_expect_equal(network_manager._player_id_by_peer_id.get(new_peer_id, -1), 2, "unknown token keeps assigned open seat")
	_expect_true(network_manager._is_player_seat_reserved(1), "unknown token does not claim reserved seat")
	_expect_equal(network_manager._player_id_by_reconnect_token.get("unknown-client", -1), 2, "unknown token is bound to new assigned seat")


func _prepare_host_reservation(reconnect_token: String) -> void:
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
	network_manager._reconnect_token_by_peer_id[101] = reconnect_token
	network_manager._assign_peer_to_player(101, 1)
	network_manager._on_peer_disconnected(101)

	_expect_true(network_manager._is_player_seat_reserved(1), "setup reserves known client seat")
	_expect_equal(network_manager._get_next_available_player_id(), 2, "setup skips reserved seat")


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
