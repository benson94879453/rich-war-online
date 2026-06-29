extends SceneTree


const TurnSystemScript := preload("res://scripts/core/TurnSystem.gd")


var _failure_count: int = 0


func _init() -> void:
	_run_smoke_check()
	if _failure_count == 0:
		print("PASS: TurnSystem FSM smoke check")
		quit(0)
	else:
		push_error("FAIL: TurnSystem FSM smoke check had %d failure(s)" % _failure_count)
		quit(1)


func _run_smoke_check() -> void:
	var turn_system: Variant = TurnSystemScript.new()
	_expect_equal(turn_system.get_phase(), TurnSystemScript.Phase.ROLL, "default phase is roll")
	_expect_equal(turn_system.get_phase_name(), "ROLL", "default phase name is roll")
	_expect_true(turn_system.can_roll(), "roll is available in roll phase")

	turn_system.begin_pre_roll_window()
	_expect_equal(turn_system.get_phase(), TurnSystemScript.Phase.PRE_ROLL_WINDOW, "pre-roll window phase exists")
	_expect_true(not turn_system.can_roll(), "roll is blocked during pre-roll window")

	turn_system.begin_roll()
	_expect_true(turn_system.can_roll(), "roll resumes after entering roll phase")

	turn_system.begin_movement()
	_expect_equal(turn_system.get_phase(), TurnSystemScript.Phase.MOVEMENT, "movement phase exists")
	_expect_true(not turn_system.can_roll(), "roll is blocked during movement")
	_expect_true(turn_system.can_resolve_route_choice(), "route choice is allowed during movement phase")

	turn_system.continue_after_route_choice()
	_expect_equal(turn_system.get_phase(), TurnSystemScript.Phase.MOVEMENT, "route continuation stays in movement phase")

	turn_system.begin_landing_resolve()
	_expect_equal(turn_system.get_phase(), TurnSystemScript.Phase.LANDING_RESOLVE, "landing resolve phase exists")

	turn_system.begin_property_decision()
	_expect_true(turn_system.can_resolve_property_decision(), "property decision phase still works")

	turn_system.restore_phase(TurnSystemScript.Phase.ROUTE_DECISION)
	_expect_true(turn_system.can_resolve_route_choice(), "legacy route decision snapshot can still resolve route choice")

	_expect_true(not turn_system.request_transition(999), "invalid transition is rejected")
	_expect_equal(turn_system.get_phase(), TurnSystemScript.Phase.ROUTE_DECISION, "invalid transition does not mutate phase")

	turn_system.restore_phase(999)
	_expect_equal(turn_system.get_phase(), TurnSystemScript.Phase.ROLL, "invalid restored phase falls back to roll")

	var state := GameState.new()
	state.initialize([
		PlayerState.new(0, "Player 1", 1500, 0, -1),
		PlayerState.new(1, "Player 2", 1500, 0, -1),
	])
	turn_system.begin_turn_end()
	var began_new_round: bool = turn_system.complete_turn(state)
	_expect_true(not began_new_round, "first turn completion does not start a new round")
	_expect_equal(state.get_current_player_id(), 1, "turn completion advances current player")
	_expect_equal(turn_system.get_phase(), TurnSystemScript.Phase.ROLL, "turn completion returns to roll phase")


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
