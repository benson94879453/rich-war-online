extends SceneTree


const SnapshotSummaryTrackerScript := preload("res://scripts/core/SnapshotSummaryTracker.gd")
const GameEventScript := preload("res://scripts/core/GameEvent.gd")


var _failure_count: int = 0


func _init() -> void:
	_run_smoke_check()
	if _failure_count == 0:
		print("PASS: Snapshot summary tracker smoke check")
		quit(0)
	else:
		push_error("FAIL: Snapshot summary tracker smoke check had %d failure(s)" % _failure_count)
		quit(1)


func _run_smoke_check() -> void:
	var tracker: SnapshotSummaryTracker = SnapshotSummaryTrackerScript.new()
	tracker.record_event(GameEventScript.ROUND_STARTED, {"round": 2})
	tracker.record_event(GameEventScript.DICE_ROLLED, {
		"player_id": 0,
		"dice_value": 4,
	})
	tracker.record_event(GameEventScript.MAP_PLAYER_LANDED, {
		"player_id": 0,
		"dice_value": 4,
		"node_id": 98,
		"tile_index": 98,
		"tile_name": "运气事件",
	})
	tracker.record_event(GameEventScript.TILE_EFFECT_RESOLVED, {
		"player_id": 0,
		"tile_name": "运气事件",
		"money_delta": 25,
	})

	var summary: Dictionary = tracker.to_dict()
	_expect_equal(summary.get(SnapshotSummaryTrackerScript.LAST_DICE_KEY, {}), {
		"player_id": 0,
		"dice_value": 4,
	}, "dice summary payload shape is preserved")
	_expect_equal(int(summary.get(SnapshotSummaryTrackerScript.LAST_LANDING_KEY, {}).get("tile_index", -1)), 98, "landing summary payload shape is preserved")
	_expect_equal(summary.get(SnapshotSummaryTrackerScript.EVENT_MESSAGE_KEY, ""), "P1 received +$25 on 运气事件", "event message format is preserved")

	var log_lines: Array = summary.get(SnapshotSummaryTrackerScript.LOG_LINES_KEY, [])
	_expect_true(log_lines.has("Round 2 begins"), "round summary is logged")
	_expect_true(log_lines.has("P1 rolled 4 -> node 98 运气事件"), "map landing summary is logged")
	_expect_true(log_lines.has("P1 received +$25 on 运气事件"), "effect summary is logged")

	var restored: SnapshotSummaryTracker = SnapshotSummaryTrackerScript.new()
	restored.restore(summary)
	_expect_equal(restored.to_dict(), summary, "summary survives restore round-trip")

	for index in range(SnapshotSummaryTrackerScript.LOG_LINE_LIMIT + 3):
		restored.record_event(GameEventScript.ROUND_STARTED, {"round": index + 3})

	var limited_lines: Array = restored.to_dict().get(SnapshotSummaryTrackerScript.LOG_LINES_KEY, [])
	_expect_equal(limited_lines.size(), SnapshotSummaryTrackerScript.LOG_LINE_LIMIT, "log line limit is preserved")

	restored.reset()
	var reset_summary: Dictionary = restored.to_dict()
	_expect_equal(reset_summary.get(SnapshotSummaryTrackerScript.LAST_DICE_KEY, {}), {}, "reset clears dice summary")
	_expect_equal(reset_summary.get(SnapshotSummaryTrackerScript.LAST_LANDING_KEY, {}), {}, "reset clears landing summary")
	_expect_equal(reset_summary.get(SnapshotSummaryTrackerScript.EVENT_MESSAGE_KEY, ""), "", "reset clears event message")
	_expect_equal(reset_summary.get(SnapshotSummaryTrackerScript.LOG_LINES_KEY, []), [], "reset clears log lines")


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
