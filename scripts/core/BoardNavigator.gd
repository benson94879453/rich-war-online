extends RefCounted
class_name BoardNavigator


var _board_data: BoardData


func _init(data: BoardData = null) -> void:
	_board_data = data


func set_board_data(data: BoardData) -> void:
	_board_data = data


func advance_movement(movement_state: MovementState) -> BoardMoveResult:
	var start_tile_index: int = -1
	if movement_state != null:
		start_tile_index = movement_state.current_tile_index

	var result := BoardMoveResult.new(start_tile_index)
	if _board_data == null or movement_state == null:
		result.mark_blocked(start_tile_index)
		return result

	if movement_state.is_complete():
		result.finish(movement_state.current_tile_index, movement_state.remaining_steps)
		return result

	movement_state.current_tile_index = _board_data.normalize_index(movement_state.current_tile_index)
	if movement_state.current_tile_index == -1:
		result.mark_blocked(start_tile_index)
		return result

	if movement_state.is_waiting_for_route_choice():
		result.require_route_choice(movement_state.available_next_tile_indices)
		result.finish(movement_state.current_tile_index, movement_state.remaining_steps)
		return result

	while not movement_state.is_complete():
		var next_tile_indices: Array[int] = _get_legal_next_tile_indices(movement_state)
		if next_tile_indices.is_empty():
			result.mark_blocked(movement_state.current_tile_index)
			result.finish(movement_state.current_tile_index, movement_state.remaining_steps)
			return result

		if next_tile_indices.size() > 1:
			movement_state.wait_for_route_choice(next_tile_indices)
			result.require_route_choice(next_tile_indices)
			result.finish(movement_state.current_tile_index, movement_state.remaining_steps)
			return result

		movement_state.move_to(next_tile_indices[0])
		result.record_step(movement_state.current_tile_index)

	result.finish(movement_state.current_tile_index, movement_state.remaining_steps)
	return result


func choose_route(movement_state: MovementState, next_tile_index: int) -> BoardMoveResult:
	var start_tile_index: int = -1
	if movement_state != null:
		start_tile_index = movement_state.current_tile_index

	var result := BoardMoveResult.new(start_tile_index)
	if movement_state == null or not movement_state.is_waiting_for_route_choice():
		result.mark_blocked(start_tile_index)
		return result

	if not movement_state.available_next_tile_indices.has(next_tile_index):
		result.mark_blocked(start_tile_index)
		return result

	movement_state.clear_route_choice()
	movement_state.move_to(next_tile_index)
	result.record_step(movement_state.current_tile_index)
	result.finish(movement_state.current_tile_index, movement_state.remaining_steps)
	return result


func _get_legal_next_tile_indices(movement_state: MovementState) -> Array[int]:
	var legal_next_tile_indices: Array[int] = []
	var next_tile_indices: Array[int] = _board_data.get_next_tile_indices(movement_state.current_tile_index)
	for tile_index in next_tile_indices:
		if tile_index != movement_state.entered_from_tile_index:
			legal_next_tile_indices.append(tile_index)

	return legal_next_tile_indices
