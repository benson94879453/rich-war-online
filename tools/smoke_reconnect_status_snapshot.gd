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

	network_manager._assign_local_player(1, network_manager.ASSIGNMENT_STATUS_JOINED)
	_expect_equal(network_manager.get_status_message(), "Connected as P2", "fresh join status identifies player seat")
	_expect_equal(network_manager._get_snapshot_status_message(3), "Connected as P2; synced snapshot #3", "fresh join status includes snapshot revision")

	network_manager._assign_local_player(1, network_manager.ASSIGNMENT_STATUS_RECONNECTED)
	_expect_equal(network_manager.get_status_message(), "Reconnected as P2", "reconnect status identifies reclaimed player seat")
	_expect_equal(network_manager._get_snapshot_status_message(4), "Reconnected as P2; synced snapshot #4", "reconnect status includes fresh snapshot revision")

	network_manager._assign_local_player(-1, network_manager.ASSIGNMENT_STATUS_SPECTATOR)
	_expect_equal(network_manager.get_status_message(), "Connected as spectator", "spectator status is visible")
	_expect_equal(network_manager._get_snapshot_status_message(5), "Connected as spectator; synced snapshot #5", "spectator status includes snapshot revision")

	network_manager._local_assignment_status_message = ""
	_expect_equal(network_manager._get_snapshot_status_message(6), "Synced snapshot #6", "snapshot-only status is readable")

	network_manager.stop_network()
	if _failure_count == 0:
		print("PASS: Reconnect status snapshot smoke check")
		quit(0)
	else:
		push_error("FAIL: Reconnect status snapshot smoke check had %d failure(s)" % _failure_count)
		quit(1)


func _get_network_manager() -> Variant:
	return root.get_node_or_null("/root/NetworkManager")


func _expect_equal(actual: Variant, expected: Variant, label: String) -> void:
	if actual == expected:
		return

	_failure_count += 1
	push_error("%s: expected %s, got %s" % [label, str(expected), str(actual)])
