extends SceneTree


var _failure_count: int = 0


func _init() -> void:
	_run_smoke_check()
	if _failure_count == 0:
		print("PASS: GameState snapshot smoke check")
		quit(0)
	else:
		push_error("FAIL: GameState snapshot smoke check had %d failure(s)" % _failure_count)
		quit(1)


func _run_smoke_check() -> void:
	var state := GameState.new()
	var players: Array[PlayerState] = [
		PlayerState.new(0, "Player 1", 1500, 10, 9),
		PlayerState.new(1, "Player 2", 1325, 20, 19),
		PlayerState.new(2, "Player 3", 1710, 30, 29),
		PlayerState.new(3, "Player 4", 980, 40, 39),
	]
	state.initialize(players)
	state.current_player_order_index = 2
	state.current_round = 4
	state.set_property_owner(12, 1)
	state.set_property_owner(24, 3)
	state.begin_property_purchase(2, 36)
	state.hands_by_player_id = {
		0: [&"dice_plus_1", &"skip_toll"],
		2: [&"shield"],
	}
	state.deck_states = {
		&"intervention": {
			"draw": [&"dice_plus_1"],
			"discard": [&"skip_toll"],
		},
	}
	state.discard_piles = {
		&"chance": [&"gain_100"],
	}
	state.status_by_player_id = {
		1: [&"shielded"],
	}
	state.pending_intervention = {
		"window_id": &"pre_roll",
		"acting_player_id": 2,
		"eligible_players": [0, 1, 3],
	}
	state.game_over = true
	state.winner_player_id = 1
	state.round_limit = 12
	state.player_map_states_by_id[0] = PlayerMapState.new(Vector2i(3, 4), BoardConnectionData.Direction.RIGHT)
	state.player_map_states_by_id[1] = PlayerMapState.new(Vector2i(5, 6), BoardConnectionData.Direction.DOWN)

	var grid_movement := GridMovementState.new(2, Vector2i(7, 8), BoardConnectionData.Direction.UP, 5)
	grid_movement.move_to(Vector2i(7, 7), BoardConnectionData.Direction.UP)
	grid_movement.wait_for_route_choice(PackedInt32Array([
		BoardConnectionData.Direction.LEFT,
		BoardConnectionData.Direction.RIGHT,
	]))
	grid_movement.queue_route_positions([
		Vector2i(6, 7),
		Vector2i(5, 7),
	], BoardConnectionData.Direction.LEFT)
	state.begin_grid_movement(grid_movement)

	var restored := GameState.from_dict(state.to_dict())

	_expect_equal(restored.player_order, [0, 1, 2, 3], "player order survives restore")
	_expect_equal(restored.current_player_order_index, 2, "current player index survives restore")
	_expect_equal(restored.get_current_player_id(), 2, "current player id survives restore")
	_expect_equal(restored.current_round, 4, "current round survives restore")
	_expect_equal(restored.get_player(1).money, 1325, "player money survives restore")
	_expect_equal(restored.get_player(3).tile_index, 40, "player tile survives restore")
	_expect_equal(restored.get_property_owner(12), 1, "first property owner survives restore")
	_expect_equal(restored.get_property_owner(24), 3, "second property owner survives restore")
	_expect_true(restored.has_pending_property_purchase(), "pending property purchase survives restore")
	_expect_equal(int(restored.pending_property_purchase.get("player_id", -1)), 2, "pending purchase player survives restore")
	_expect_equal(int(restored.pending_property_purchase.get("tile_index", -1)), 36, "pending purchase tile survives restore")
	_expect_equal(restored.hands_by_player_id, {
		0: [&"dice_plus_1", &"skip_toll"],
		2: [&"shield"],
	}, "reserved hands survive restore")
	_expect_equal(restored.deck_states, {
		&"intervention": {
			"draw": [&"dice_plus_1"],
			"discard": [&"skip_toll"],
		},
	}, "reserved deck states survive restore")
	_expect_equal(restored.discard_piles, {
		&"chance": [&"gain_100"],
	}, "reserved discard piles survive restore")
	_expect_equal(restored.status_by_player_id, {
		1: [&"shielded"],
	}, "reserved statuses survive restore")
	_expect_equal(restored.pending_intervention, {
		"window_id": &"pre_roll",
		"acting_player_id": 2,
		"eligible_players": [0, 1, 3],
	}, "reserved pending intervention survives restore")
	_expect_true(restored.game_over, "reserved game over survives restore")
	_expect_equal(restored.winner_player_id, 1, "reserved winner survives restore")
	_expect_equal(restored.round_limit, 12, "reserved round limit survives restore")

	var restored_map_state := restored.get_player_map_state(1)
	_expect_true(restored_map_state != null, "player map state survives restore")
	if restored_map_state != null:
		_expect_equal(restored_map_state.grid_position, Vector2i(5, 6), "player map grid position survives restore")
		_expect_equal(restored_map_state.direction, BoardConnectionData.Direction.DOWN, "player map direction survives restore")

	_expect_true(restored.has_pending_grid_movement(), "pending grid movement survives restore")
	var restored_grid_movement: GridMovementState = restored.pending_grid_movement
	if restored_grid_movement != null:
		_expect_equal(restored_grid_movement.player_id, 2, "grid movement player survives restore")
		_expect_equal(restored_grid_movement.current_grid_position, Vector2i(7, 7), "grid movement position survives restore")
		_expect_equal(restored_grid_movement.remaining_steps, 4, "grid movement remaining steps survives restore")
		_expect_equal(Array(restored_grid_movement.available_next_directions), [
			BoardConnectionData.Direction.LEFT,
			BoardConnectionData.Direction.RIGHT,
		], "grid route directions survive restore")
		_expect_equal(restored_grid_movement.pending_route_positions, [
			Vector2i(6, 7),
			Vector2i(5, 7),
		], "pending route positions survive restore")


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
