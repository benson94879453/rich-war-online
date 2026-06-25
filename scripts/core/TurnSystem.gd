extends RefCounted
class_name TurnSystem


enum Phase {
	ROLL,
	PROPERTY_DECISION,
	ROUTE_DECISION,
}


var phase: int = Phase.ROLL


func reset() -> void:
	phase = Phase.ROLL


func can_roll() -> bool:
	return phase == Phase.ROLL


func begin_property_decision() -> void:
	phase = Phase.PROPERTY_DECISION


func can_resolve_property_decision() -> bool:
	return phase == Phase.PROPERTY_DECISION


func begin_route_decision() -> void:
	phase = Phase.ROUTE_DECISION


func can_resolve_route_choice() -> bool:
	return phase == Phase.ROUTE_DECISION


func continue_after_route_choice() -> void:
	phase = Phase.ROLL


func complete_turn(state: GameState) -> bool:
	phase = Phase.ROLL
	return state.advance_turn()
