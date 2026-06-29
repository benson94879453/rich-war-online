extends SceneTree


const BOARD_RESOURCE_PATH := "res://resources/maps/starq_board.tres"
const MAX_SEED_ATTEMPTS := 4096
const ActionDispatcherScript := preload("res://scripts/core/ActionDispatcher.gd")
const EventServiceScript := preload("res://scripts/core/EventService.gd")


var _failure_count: int = 0
var _dispatcher := ActionDispatcherScript.new()


func _init() -> void:
	_run_scenario.call_deferred()


func _run_scenario() -> void:
	var network_manager: Variant = _get_network_manager()
	var game_manager: Variant = _get_game_manager()
	if network_manager == null or game_manager == null:
		_fail("Required autoloads are not available.")
		_finish()
		return

	network_manager.stop_network()

	var board_data: BoardData = load(BOARD_RESOURCE_PATH) as BoardData
	if board_data == null:
		_fail("Could not load active board resource: %s" % BOARD_RESOURCE_PATH)
		_finish()
		return

	var chance_tile: BoardTileData = _find_tile_by_effect_id(board_data, EventServiceScript.EVENT_STARQ_CHANCE)
	if chance_tile == null:
		_fail("Active board does not include %s." % str(EventServiceScript.EVENT_STARQ_CHANCE))
		_finish()
		return

	var roll_setup: Dictionary = _find_direct_roll_setup(board_data, chance_tile)
	if roll_setup.is_empty():
		_fail("Could not find a deterministic grid roll path to tile %d." % chance_tile.index)
		_finish()
		return

	var expected_roll := int(roll_setup.get("roll", 0))
	var rng_seed := _find_seed_for_roll(expected_roll)
	if rng_seed < 0:
		_fail("Could not find RNG seed for roll %d." % expected_roll)
		_finish()
		return

	var players: Array[PlayerState] = [
		PlayerState.new(0, "Player 1", 1500, 0, -1),
		PlayerState.new(1, "Player 2", 1500, 0, -1),
	]
	game_manager.start_local_game(players, board_data)
	_prepare_player_for_roll(game_manager, roll_setup, rng_seed)

	var player: PlayerState = game_manager.state.get_player(0)
	var money_before: int = player.money
	if _submit_action(ActionDispatcherScript.ACTION_ROLL, {}, "roll into event landing"):
		_expect_event_landing_result(game_manager, board_data, chance_tile, money_before, expected_roll)

	network_manager.stop_network()
	_finish()


func _prepare_player_for_roll(game_manager: Variant, roll_setup: Dictionary, rng_seed: int) -> void:
	var player_map_state: PlayerMapState = game_manager.state.get_player_map_state(0)
	if player_map_state == null:
		_fail("Player 1 has no active map state.")
		return

	player_map_state.move_to(roll_setup.get("start_grid_position", Vector2i(-1, -1)), int(roll_setup.get("direction", BoardConnectionData.Direction.NONE)))
	game_manager._rng.seed = rng_seed


func _expect_event_landing_result(game_manager: Variant, board_data: BoardData, chance_tile: BoardTileData, money_before: int, expected_roll: int) -> void:
	var player: PlayerState = game_manager.state.get_player(0)
	var expected_money := money_before + EventServiceScript.PROTOTYPE_CHANCE_MONEY_DELTA
	var target_grid_position := board_data.get_grid_position_for_tile_index(chance_tile.index)
	var player_map_state: PlayerMapState = game_manager.state.get_player_map_state(0)

	_expect_equal(player.money, expected_money, "event landing applies exactly one prototype money delta")
	_expect_equal(player.tile_index, chance_tile.index, "event landing updates player tile index")
	_expect_equal(player_map_state.grid_position, target_grid_position, "event landing updates player map position")
	_expect_equal(game_manager.state.get_current_player_id(), 1, "event landing completes turn and advances active player")
	_expect_true(_is_idle_for_next_roll(game_manager), "event landing drains pending turn state")

	var snapshot: Dictionary = game_manager.get_state_snapshot()
	var ui_summary: Dictionary = snapshot.get(game_manager.SNAPSHOT_UI_SUMMARY_KEY, {})
	var event_message := str(ui_summary.get(game_manager.UI_SUMMARY_EVENT_MESSAGE_KEY, ""))
	var landing_summary: Dictionary = ui_summary.get(game_manager.UI_SUMMARY_LAST_LANDING_KEY, {})

	_expect_true(event_message.contains("received"), "snapshot event message records gain verb")
	_expect_true(event_message.contains(str(EventServiceScript.PROTOTYPE_CHANCE_MONEY_DELTA)), "snapshot event message records prototype delta")
	_expect_true(event_message.contains(chance_tile.display_name), "snapshot event message records selected event tile")
	_expect_equal(int(landing_summary.get("tile_index", -1)), chance_tile.index, "snapshot landing summary records selected tile")
	_expect_equal(int(landing_summary.get("dice_value", 0)), expected_roll, "snapshot landing summary records deterministic roll")
	_expect_snapshot_round_trip(game_manager, snapshot, chance_tile, expected_money, target_grid_position)


func _expect_snapshot_round_trip(game_manager: Variant, snapshot: Dictionary, chance_tile: BoardTileData, expected_money: int, target_grid_position: Vector2i) -> void:
	var restored := GameState.from_dict(snapshot)
	var restored_player: PlayerState = restored.get_player(0)
	var restored_map_state: PlayerMapState = restored.get_player_map_state(0)

	_expect_true(restored_player != null, "snapshot round-trip restores event player")
	if restored_player != null:
		_expect_equal(restored_player.money, expected_money, "snapshot round-trip preserves event money result")
		_expect_equal(restored_player.tile_index, chance_tile.index, "snapshot round-trip preserves event tile")

	_expect_true(restored_map_state != null, "snapshot round-trip restores event map state")
	if restored_map_state != null:
		_expect_equal(restored_map_state.grid_position, target_grid_position, "snapshot round-trip preserves event map position")

	_expect_equal(restored.current_round, game_manager.state.current_round, "snapshot round-trip preserves current round")
	_expect_equal(restored.get_current_player_id(), game_manager.state.get_current_player_id(), "snapshot round-trip preserves active player")
	_expect_true(not restored.has_pending_property_purchase(), "snapshot round-trip has no pending property decision")
	_expect_true(not restored.has_pending_movement(), "snapshot round-trip has no legacy pending movement")
	_expect_true(not restored.has_pending_grid_movement(), "snapshot round-trip has no pending grid movement")


func _find_direct_roll_setup(board_data: BoardData, target_tile: BoardTileData) -> Dictionary:
	var map_grid: BoardMapGridData = board_data.get_map_grid()
	if map_grid == null:
		return {}

	var target_grid_position := board_data.get_grid_position_for_tile_index(target_tile.index)
	if target_grid_position == Vector2i(-1, -1):
		return {}

	var movement_system := GridMovementSystem.new()
	movement_system.set_map_grid(map_grid)
	for y in range(map_grid.height):
		for x in range(map_grid.width):
			var start_grid_position := Vector2i(x, y)
			if start_grid_position == target_grid_position or not map_grid.is_walkable(start_grid_position):
				continue

			for direction in _movement_directions():
				for roll in range(1, 7):
					var movement_state := GridMovementState.new(0, start_grid_position, direction, roll)
					var move_result: GridMoveResult = movement_system.advance_movement(movement_state)
					if move_result.is_complete() and move_result.current_grid_position == target_grid_position:
						return {
							"start_grid_position": start_grid_position,
							"direction": direction,
							"roll": roll,
						}

	return {}


func _find_seed_for_roll(target_roll: int) -> int:
	for seed in range(1, MAX_SEED_ATTEMPTS + 1):
		var rng := RandomNumberGenerator.new()
		rng.seed = seed
		if rng.randi_range(1, 6) == target_roll:
			return seed

	return -1


func _find_tile_by_effect_id(board_data: BoardData, effect_id: StringName) -> BoardTileData:
	for tile in board_data.tiles:
		if tile != null and tile.effect_id == effect_id:
			return tile

	return null


func _movement_directions() -> Array[int]:
	return [
		BoardConnectionData.Direction.RIGHT,
		BoardConnectionData.Direction.UP,
		BoardConnectionData.Direction.LEFT,
		BoardConnectionData.Direction.DOWN,
	]


func _submit_action(action_type: String, payload: Dictionary, label: String) -> bool:
	var result: Dictionary = _dispatcher.submit_action(1, action_type, payload, Callable(self, "_can_control_player"))
	if bool(result.get(ActionDispatcherScript.RESULT_ACCEPTED, false)):
		return true

	_fail("%s rejected: %s" % [label, str(result.get(ActionDispatcherScript.RESULT_REJECTION_REASON, "unknown rejection"))])
	return false


func _can_control_player(_sender_peer_id: int, _player_id: int) -> bool:
	return true


func _is_idle_for_next_roll(game_manager: Variant) -> bool:
	return game_manager != null \
		and game_manager.state != null \
		and game_manager.turn_system.can_roll() \
		and not game_manager.state.has_pending_property_purchase() \
		and not game_manager.state.has_pending_movement() \
		and not game_manager.state.has_pending_grid_movement()


func _get_game_manager() -> Variant:
	return root.get_node_or_null("/root/GameManager")


func _get_network_manager() -> Variant:
	return root.get_node_or_null("/root/NetworkManager")


func _finish() -> void:
	if _failure_count == 0:
		print("PASS: Event landing pipeline scenario")
		quit(0)
	else:
		push_error("FAIL: Event landing pipeline scenario had %d failure(s)" % _failure_count)
		quit(1)


func _expect_true(value: bool, label: String) -> void:
	if value:
		return

	_fail("Expected true: %s" % label)


func _expect_equal(actual: Variant, expected: Variant, label: String) -> void:
	if actual == expected:
		return

	_fail("%s: expected %s, got %s" % [label, str(expected), str(actual)])


func _fail(message: String) -> void:
	_failure_count += 1
	push_error(message)
