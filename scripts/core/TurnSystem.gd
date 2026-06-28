extends RefCounted
class_name TurnSystem


enum Phase {
	ROLL = 0,
	PROPERTY_DECISION = 1,
	ROUTE_DECISION = 2,
	TURN_START = 3,
	PRE_ROLL_WINDOW = 4,
	MOVEMENT = 5,
	LANDING_RESOLVE = 6,
	TURN_END = 7,
	GAME_OVER = 8,
}


var phase: int = Phase.ROLL


func reset() -> void:
	request_transition(Phase.ROLL)


func get_phase() -> int:
	return phase


func restore_phase(value: int) -> void:
	if not is_valid_phase(value):
		reset()
		return

	phase = value


func is_valid_phase(value: int) -> bool:
	return value >= Phase.ROLL and value <= Phase.GAME_OVER


func request_transition(next_phase: int) -> bool:
	if not is_valid_phase(next_phase):
		return false

	phase = next_phase
	return true


func get_phase_name(value: int = phase) -> String:
	match value:
		Phase.ROLL:
			return "ROLL"
		Phase.PROPERTY_DECISION:
			return "PROPERTY_DECISION"
		Phase.ROUTE_DECISION:
			return "ROUTE_DECISION"
		Phase.TURN_START:
			return "TURN_START"
		Phase.PRE_ROLL_WINDOW:
			return "PRE_ROLL_WINDOW"
		Phase.MOVEMENT:
			return "MOVEMENT"
		Phase.LANDING_RESOLVE:
			return "LANDING_RESOLVE"
		Phase.TURN_END:
			return "TURN_END"
		Phase.GAME_OVER:
			return "GAME_OVER"

	return "UNKNOWN"


func can_roll() -> bool:
	return phase == Phase.ROLL


func begin_property_decision() -> void:
	request_transition(Phase.PROPERTY_DECISION)


func can_resolve_property_decision() -> bool:
	return phase == Phase.PROPERTY_DECISION


func begin_route_decision() -> void:
	request_transition(Phase.MOVEMENT)


func can_resolve_route_choice() -> bool:
	return phase == Phase.MOVEMENT or phase == Phase.ROUTE_DECISION


func continue_after_route_choice() -> void:
	request_transition(Phase.MOVEMENT)


func begin_turn_start() -> void:
	request_transition(Phase.TURN_START)


func begin_pre_roll_window() -> void:
	request_transition(Phase.PRE_ROLL_WINDOW)


func begin_roll() -> void:
	request_transition(Phase.ROLL)


func begin_movement() -> void:
	request_transition(Phase.MOVEMENT)


func begin_landing_resolve() -> void:
	request_transition(Phase.LANDING_RESOLVE)


func begin_turn_end() -> void:
	request_transition(Phase.TURN_END)


func begin_game_over() -> void:
	request_transition(Phase.GAME_OVER)


func complete_turn(state: GameState) -> bool:
	begin_turn_end()
	var began_new_round := state.advance_turn()
	begin_roll()
	return began_new_round
