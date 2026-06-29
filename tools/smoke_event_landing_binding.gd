extends SceneTree


const BOARD_RESOURCE_PATH := "res://resources/maps/starq_board.tres"
const EventServiceScript := preload("res://scripts/core/EventService.gd")


var _failure_count: int = 0


func _init() -> void:
	_run_smoke_check.call_deferred()


func _run_smoke_check() -> void:
	var game_manager: Variant = root.get_node_or_null("/root/GameManager")
	var network_manager: Variant = root.get_node_or_null("/root/NetworkManager")
	if game_manager == null or network_manager == null:
		_fail("Required autoloads are not available.")
		_finish()
		return

	network_manager.stop_network()
	var board_data: BoardData = load(BOARD_RESOURCE_PATH) as BoardData
	if board_data == null:
		_fail("Could not load active board resource: %s" % BOARD_RESOURCE_PATH)
		_finish()
		return

	var players: Array[PlayerState] = [
		PlayerState.new(0, "Player 1", 1500, 0, -1),
		PlayerState.new(1, "Player 2", 1500, 0, -1),
	]
	game_manager.start_local_game(players, board_data)

	var chance_tile: BoardTileData = _find_tile_by_effect_id(board_data, EventServiceScript.EVENT_STARQ_CHANCE)
	if chance_tile == null:
		_fail("Active board does not include %s." % str(EventServiceScript.EVENT_STARQ_CHANCE))
		_finish()
		return

	var player: PlayerState = game_manager.state.get_player(0)
	var money_before: int = player.money
	game_manager._resolve_tile_effect(player, chance_tile)

	_expect_equal(player.money, money_before + EventServiceScript.PROTOTYPE_CHANCE_MONEY_DELTA, "starq chance landing applies prototype event money")
	var snapshot: Dictionary = game_manager.get_state_snapshot()
	var ui_summary: Dictionary = snapshot.get(game_manager.SNAPSHOT_UI_SUMMARY_KEY, {})
	_expect_true(str(ui_summary.get(game_manager.UI_SUMMARY_EVENT_MESSAGE_KEY, "")).contains("received"), "event landing updates snapshot event message")

	network_manager.stop_network()
	_finish()


func _find_tile_by_effect_id(board_data: BoardData, effect_id: StringName) -> BoardTileData:
	for tile in board_data.tiles:
		if tile != null and tile.effect_id == effect_id:
			return tile

	return null


func _finish() -> void:
	if _failure_count == 0:
		print("PASS: Event landing binding smoke check")
		quit(0)
	else:
		push_error("FAIL: Event landing binding smoke check had %d failure(s)" % _failure_count)
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
