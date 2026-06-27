extends SceneTree


var _failure_count: int = 0


func _init() -> void:
	_run_smoke_check.call_deferred()


func _run_smoke_check() -> void:
	NetworkManager.stop_network()

	NetworkManager._assign_local_player(1, NetworkManager.ASSIGNMENT_STATUS_JOINED)
	_expect_equal(NetworkManager.get_status_message(), "Connected as P2", "fresh join status identifies player seat")
	_expect_equal(NetworkManager._get_snapshot_status_message(3), "Connected as P2; synced snapshot #3", "fresh join status includes snapshot revision")

	NetworkManager._assign_local_player(1, NetworkManager.ASSIGNMENT_STATUS_RECONNECTED)
	_expect_equal(NetworkManager.get_status_message(), "Reconnected as P2", "reconnect status identifies reclaimed player seat")
	_expect_equal(NetworkManager._get_snapshot_status_message(4), "Reconnected as P2; synced snapshot #4", "reconnect status includes fresh snapshot revision")

	NetworkManager._assign_local_player(-1, NetworkManager.ASSIGNMENT_STATUS_SPECTATOR)
	_expect_equal(NetworkManager.get_status_message(), "Connected as spectator", "spectator status is visible")
	_expect_equal(NetworkManager._get_snapshot_status_message(5), "Connected as spectator; synced snapshot #5", "spectator status includes snapshot revision")

	NetworkManager._local_assignment_status_message = ""
	_expect_equal(NetworkManager._get_snapshot_status_message(6), "Synced snapshot #6", "snapshot-only status is readable")

	NetworkManager.stop_network()
	if _failure_count == 0:
		print("PASS: Reconnect status snapshot smoke check")
		quit(0)
	else:
		push_error("FAIL: Reconnect status snapshot smoke check had %d failure(s)" % _failure_count)
		quit(1)


func _expect_equal(actual: Variant, expected: Variant, label: String) -> void:
	if actual == expected:
		return

	_failure_count += 1
	push_error("%s: expected %s, got %s" % [label, str(expected), str(actual)])
