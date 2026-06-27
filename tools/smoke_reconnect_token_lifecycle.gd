extends SceneTree


var _failure_count: int = 0


func _init() -> void:
	_run_smoke_check.call_deferred()


func _run_smoke_check() -> void:
	var first_token := NetworkManager.get_local_reconnect_token()
	var second_token := NetworkManager.get_local_reconnect_token()
	NetworkManager.stop_network()
	var token_after_stop := NetworkManager.get_local_reconnect_token()

	_expect_true(not first_token.is_empty(), "reconnect token is generated")
	_expect_equal(second_token, first_token, "reconnect token is stable across repeated reads")
	_expect_equal(token_after_stop, first_token, "reconnect token survives stop_network in the same session")

	if _failure_count == 0:
		print("PASS: Reconnect token lifecycle smoke check")
		quit(0)
	else:
		push_error("FAIL: Reconnect token lifecycle smoke check had %d failure(s)" % _failure_count)
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
