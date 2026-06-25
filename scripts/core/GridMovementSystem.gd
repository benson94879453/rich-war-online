extends RefCounted
class_name GridMovementSystem


var _navigator: MapGridNavigator = MapGridNavigator.new()


func set_map_grid(map_grid: BoardMapGridData) -> void:
	_navigator.set_map_grid(map_grid)


func advance_movement(movement_state: GridMovementState) -> GridMoveResult:
	var start_grid_position := Vector2i(-1, -1)
	if movement_state != null:
		start_grid_position = movement_state.current_grid_position

	var result := GridMoveResult.new(start_grid_position)
	if movement_state == null:
		result.mark_blocked(start_grid_position)
		return result

	if movement_state.is_complete():
		result.finish(movement_state.current_grid_position, movement_state.remaining_steps)
		return result

	if movement_state.is_waiting_for_route_choice():
		result.require_route_choice(movement_state.available_next_directions)
		result.finish(movement_state.current_grid_position, movement_state.remaining_steps)
		return result

	while not movement_state.is_complete():
		if movement_state.has_pending_route_positions():
			_consume_pending_route_position(movement_state, result)
			if result.is_blocked():
				result.finish(movement_state.current_grid_position, movement_state.remaining_steps)
				return result
			continue

		var available_directions := _navigator.get_available_directions(movement_state.current_grid_position, movement_state.travel_direction)
		if available_directions.is_empty():
			result.mark_blocked(movement_state.current_grid_position)
			result.finish(movement_state.current_grid_position, movement_state.remaining_steps)
			return result

		if available_directions.size() > 1:
			movement_state.wait_for_route_choice(available_directions)
			result.require_route_choice(available_directions)
			result.finish(movement_state.current_grid_position, movement_state.remaining_steps)
			return result

		_queue_route_in_direction(movement_state, available_directions[0], result)
		if result.is_blocked():
			result.finish(movement_state.current_grid_position, movement_state.remaining_steps)
			return result

	result.finish(movement_state.current_grid_position, movement_state.remaining_steps)
	return result


func choose_route(movement_state: GridMovementState, direction: int) -> GridMoveResult:
	var start_grid_position := Vector2i(-1, -1)
	if movement_state != null:
		start_grid_position = movement_state.current_grid_position

	var result := GridMoveResult.new(start_grid_position)
	if movement_state == null or not movement_state.is_waiting_for_route_choice():
		result.mark_blocked(start_grid_position)
		return result

	if not movement_state.available_next_directions.has(direction):
		result.mark_blocked(start_grid_position)
		return result

	movement_state.clear_route_choice()
	_queue_route_in_direction(movement_state, direction, result)
	if not result.is_blocked():
		_consume_pending_route_position(movement_state, result)
	result.finish(movement_state.current_grid_position, movement_state.remaining_steps)
	return result


func _queue_route_in_direction(movement_state: GridMovementState, direction: int, result: GridMoveResult) -> void:
	var route_positions := _navigator.get_route_positions(movement_state.current_grid_position, direction)
	if route_positions.is_empty():
		result.mark_blocked(movement_state.current_grid_position)
		return

	movement_state.queue_route_positions(route_positions, direction)


func _consume_pending_route_position(movement_state: GridMovementState, result: GridMoveResult) -> void:
	var next_grid_position: Vector2i = movement_state.take_next_route_position()
	if next_grid_position == Vector2i(-1, -1):
		result.mark_blocked(movement_state.current_grid_position)
		return

	movement_state.move_to(next_grid_position, movement_state.travel_direction)
	result.record_step(next_grid_position)
