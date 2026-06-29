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

	var first_token: String = network_manager.get_local_reconnect_token()
	var second_token: String = network_manager.get_local_reconnect_token()
	network_manager.stop_network()
	var token_after_stop: String = network_manager.get_local_reconnect_token()
	network_manager._local_reconnect_token = ""
	var token_after_memory_clear: String = network_manager.get_local_reconnect_token()

	_expect_true(not first_token.is_empty(), "reconnect token is generated")
	_expect_equal(second_token, first_token, "reconnect token is stable across repeated reads")
	_expect_equal(token_after_stop, first_token, "reconnect token survives stop_network in the same session")
	_expect_equal(token_after_memory_clear, first_token, "reconnect token is restored from local storage after process memory resets")

	if _failure_count == 0:
		print("PASS: Reconnect token lifecycle smoke check")
		quit(0)
	else:
		push_error("FAIL: Reconnect token lifecycle smoke check had %d failure(s)" % _failure_count)
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
