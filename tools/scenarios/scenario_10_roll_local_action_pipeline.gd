extends SceneTree


const TARGET_ROLL_COUNT := 10
const MAX_ACTION_COUNT := 120
const BOARD_RESOURCE_PATH := "res://resources/maps/starq_board.tres"
const ActionDispatcherScript := preload("res://scripts/core/ActionDispatcher.gd")


var _failure_count: int = 0
var _dispatcher := ActionDispatcherScript.new()
var _roll_count: int = 0
var _route_choice_count: int = 0
var _property_decision_count: int = 0


func _init() -> void:
	_run_scenario.call_deferred()


func _run_scenario() -> void:
	var network_manager: Variant = _get_network_manager()
	var game_manager: Variant = _get_game_manager()
	if network_manager == null or game_manager == null:
		_fail("Required autoloads are not available.")
		quit(1)
		return

	network_manager.stop_network()
	_start_local_game()

	for _action_index in range(MAX_ACTION_COUNT):
		if _roll_count >= TARGET_ROLL_COUNT and _is_idle_for_next_roll():
			break

		if game_manager.state == null:
			_fail("Game state became null during scenario.")
			break

		if game_manager.state.has_pending_property_purchase():
			if _submit_action(ActionDispatcherScript.ACTION_SKIP_PROPERTY, {}, "skip pending property"):
				_property_decision_count += 1
			continue

		if _has_pending_grid_route_choice():
			var directions: PackedInt32Array = game_manager.state.pending_grid_movement.available_next_directions
			if directions.is_empty():
				_fail("Grid route choice is pending with no directions.")
				break

			if _submit_action(ActionDispatcherScript.ACTION_GRID_ROUTE_CHOICE, {"direction": int(directions[0])}, "choose grid route"):
				_route_choice_count += 1
			continue

		if game_manager.turn_system.can_roll():
			if _submit_action(ActionDispatcherScript.ACTION_ROLL, {}, "roll"):
				_roll_count += 1
			continue

		_fail("Scenario reached a stuck state in phase %s." % game_manager.turn_system.get_phase_name())
		break

	_expect_equal(_roll_count, TARGET_ROLL_COUNT, "scenario completes target roll count")
	_expect_true(_is_idle_for_next_roll(), "scenario drains pending actions after target roll count")
	_expect_snapshot_round_trip()

	network_manager.stop_network()
	if _failure_count == 0:
		print("PASS: 10-roll local action pipeline scenario")
		quit(0)
	else:
		push_error("FAIL: 10-roll local action pipeline scenario had %d failure(s)" % _failure_count)
		quit(1)


func _start_local_game() -> void:
	var board_data: BoardData = load(BOARD_RESOURCE_PATH) as BoardData
	if board_data == null:
		_fail("Could not load active board resource: %s" % BOARD_RESOURCE_PATH)
		return

	var players: Array[PlayerState] = [
		PlayerState.new(0, "Player 1", 1500, 0, -1),
		PlayerState.new(1, "Player 2", 1500, 0, -1),
		PlayerState.new(2, "Player 3", 1500, 0, -1),
		PlayerState.new(3, "Player 4", 1500, 0, -1),
	]
	var game_manager: Variant = _get_game_manager()
	if game_manager != null:
		game_manager.start_local_game(players, board_data)


func _submit_action(action_type: String, payload: Dictionary, label: String) -> bool:
	var result: Dictionary = _dispatcher.submit_action(1, action_type, payload, Callable(self, "_can_control_player"))
	if bool(result.get(ActionDispatcherScript.RESULT_ACCEPTED, false)):
		return true

	_fail("%s rejected: %s" % [label, str(result.get(ActionDispatcherScript.RESULT_REJECTION_REASON, "unknown rejection"))])
	return false


func _can_control_player(_sender_peer_id: int, _player_id: int) -> bool:
	return true


func _has_pending_grid_route_choice() -> bool:
	var game_manager: Variant = _get_game_manager()
	return game_manager != null \
		and game_manager.state != null \
		and game_manager.state.has_pending_grid_movement() \
		and game_manager.state.pending_grid_movement.is_waiting_for_route_choice()


func _is_idle_for_next_roll() -> bool:
	var game_manager: Variant = _get_game_manager()
	return game_manager != null \
		and game_manager.state != null \
		and game_manager.turn_system.can_roll() \
		and not game_manager.state.has_pending_property_purchase() \
		and not game_manager.state.has_pending_movement() \
		and not game_manager.state.has_pending_grid_movement()


func _expect_snapshot_round_trip() -> void:
	var game_manager: Variant = _get_game_manager()
	if game_manager == null or game_manager.state == null:
		_fail("Cannot snapshot null game state.")
		return

	var restored := GameState.from_dict(game_manager.get_state_snapshot())
	_expect_equal(restored.current_round, game_manager.state.current_round, "scenario snapshot preserves current round")
	_expect_equal(restored.get_current_player_id(), game_manager.state.get_current_player_id(), "scenario snapshot preserves current player")
	_expect_equal(restored.players_by_id.size(), game_manager.state.players_by_id.size(), "scenario snapshot preserves player count")
	_expect_equal(restored.property_owner_by_tile, game_manager.state.property_owner_by_tile, "scenario snapshot preserves property ownership")


func _get_game_manager() -> Variant:
	return root.get_node_or_null("/root/GameManager")


func _get_network_manager() -> Variant:
	return root.get_node_or_null("/root/NetworkManager")


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
