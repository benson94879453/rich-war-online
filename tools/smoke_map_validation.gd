extends SceneTree


const ACTIVE_BOARD_RESOURCE_PATH := "res://resources/maps/starq_board.tres"
const EXPECTED_ACTIVE_SCENE := "res://scenes/StarQGame.tscn"
const EXPECTED_PLAYER_IDS := [0, 1, 2, 3]


var _failures := PackedStringArray()
var _helper_check_count: int = 0


func _init() -> void:
	_run_smoke_check()
	if _failures.is_empty():
		print("PASS: Map validation smoke check")
		quit(0)
	else:
		for failure in _failures:
			push_error(failure)
		push_error("FAIL: Map validation smoke check had %d failure(s)" % _failures.size())
		quit(1)


func _run_smoke_check() -> void:
	print("Map validation smoke check")
	print("Active scene: %s" % EXPECTED_ACTIVE_SCENE)
	print("Active board resource: %s" % ACTIVE_BOARD_RESOURCE_PATH)

	var board_data := _load_board_data()
	if board_data == null:
		_print_summary()
		return

	_run_helper_checks(board_data)

	var map_grid := board_data.get_map_grid()
	_expect_true(map_grid != null, "Board resource has BoardMapGridData.")
	if map_grid == null:
		_print_summary()
		return

	var navigator := MapGridNavigator.new()
	navigator.set_map_grid(map_grid)

	_check_expected_player_spawns(board_data, map_grid, navigator)
	_check_tile_source_nodes(board_data, map_grid)
	_check_property_decorations(board_data)
	_check_junction_routes(map_grid, navigator)
	_print_summary()


func _load_board_data() -> BoardData:
	var resource := load(ACTIVE_BOARD_RESOURCE_PATH)
	if resource == null:
		_record_failure("Could not load active board resource: %s" % ACTIVE_BOARD_RESOURCE_PATH)
		return null

	var board_data := resource as BoardData
	if board_data == null:
		_record_failure("Active board resource is not BoardData: %s" % ACTIVE_BOARD_RESOURCE_PATH)
		return null

	return board_data


func _run_helper_checks(board_data: BoardData) -> void:
	_run_helper_check("BoardData.get_player_spawn_validation_messages()", board_data.get_player_spawn_validation_messages())
	_run_helper_check("BoardData.get_map_grid_validation_messages()", board_data.get_map_grid_validation_messages())
	_run_helper_check("BoardData.get_source_node_validation_messages()", board_data.get_source_node_validation_messages())
	_run_helper_check("BoardData.get_placement_validation_messages()", board_data.get_placement_validation_messages())
	_run_helper_check("BoardData.get_property_decoration_validation_messages()", board_data.get_property_decoration_validation_messages())
	_run_helper_check("BoardData.get_connection_validation_messages()", board_data.get_connection_validation_messages())


func _run_helper_check(label: String, messages: PackedStringArray) -> void:
	_helper_check_count += 1
	for message in messages:
		_record_failure("%s: %s" % [label, message])


func _check_expected_player_spawns(board_data: BoardData, map_grid: BoardMapGridData, navigator: MapGridNavigator) -> void:
	var spawns_by_player_id := {}
	for spawn_resource in board_data.player_spawns:
		var spawn := spawn_resource as BoardPlayerSpawnData
		if spawn == null:
			continue

		var player_spawns: Array = spawns_by_player_id.get(spawn.player_id, [])
		player_spawns.append(spawn)
		spawns_by_player_id[spawn.player_id] = player_spawns

	for player_id in EXPECTED_PLAYER_IDS:
		var player_spawns: Array = spawns_by_player_id.get(player_id, [])
		if player_spawns.size() != 1:
			_record_failure("Expected exactly one spawn for player %d, found %d." % [player_id, player_spawns.size()])
			continue

		var spawn := player_spawns[0] as BoardPlayerSpawnData
		if not spawn.has_grid_spawn():
			_record_failure("Player %d spawn does not use a grid position." % player_id)
			continue

		if not map_grid.is_inside(spawn.grid_position):
			_record_failure("Player %d spawn grid position is outside the grid: %s." % [player_id, str(spawn.grid_position)])
			continue

		var node_id := map_grid.get_node_id(spawn.grid_position)
		if not map_grid.is_landing_node(spawn.grid_position):
			_record_failure("Player %d spawn is not on a landing node: node %d at %s." % [player_id, node_id, str(spawn.grid_position)])
			continue

		var directions := navigator.get_available_directions(spawn.grid_position, spawn.initial_direction)
		if directions.is_empty():
			_record_failure("Player %d spawn at node %d has no available movement direction from initial direction %d." % [player_id, node_id, spawn.initial_direction])


func _check_tile_source_nodes(board_data: BoardData, map_grid: BoardMapGridData) -> void:
	for tile_index in range(board_data.tiles.size()):
		var tile := board_data.get_tile(tile_index)
		if tile == null:
			_record_failure("Tile index %d is not BoardTileData." % tile_index)
			continue

		if tile.source_node_id < 0:
			continue

		var grid_position := map_grid.get_grid_position_for_node_id(tile.source_node_id)
		if grid_position == Vector2i(-1, -1):
			_record_failure("Tile %d source node %d does not exist in the map grid." % [tile_index, tile.source_node_id])
			continue

		if not map_grid.is_landing_node(grid_position):
			_record_failure("Tile %d source node %d is not a landing node at %s." % [tile_index, tile.source_node_id, str(grid_position)])


func _check_property_decorations(board_data: BoardData) -> void:
	for decoration_resource in board_data.property_decorations:
		var decoration := decoration_resource as BoardPropertyDecorationData
		if decoration == null:
			continue

		if decoration.tile_index < 0 or decoration.tile_index >= board_data.tiles.size():
			continue

		var tile := board_data.tiles[decoration.tile_index] as BoardTileData
		if tile == null:
			_record_failure("Property decoration references tile %d, but that entry is not BoardTileData." % decoration.tile_index)
			continue

		if not tile.is_property():
			_record_failure("Property decoration references non-property tile %d (%s, type %d)." % [decoration.tile_index, tile.display_name, tile.tile_type])


func _check_junction_routes(map_grid: BoardMapGridData, navigator: MapGridNavigator) -> void:
	for node_id_value in map_grid.junction_directions_by_node_id:
		var node_id := int(node_id_value)
		var grid_position := map_grid.get_grid_position_for_node_id(node_id)
		if grid_position == Vector2i(-1, -1):
			_record_failure("Junction node %d does not exist in the map grid." % node_id)
			continue

		var directions := map_grid.get_junction_directions(node_id)
		for direction in directions:
			if navigator.get_route_positions(grid_position, direction).is_empty():
				_record_failure("Junction node %d at %s has no route positions for direction %d." % [node_id, str(grid_position), direction])


func _print_summary() -> void:
	print("Helper-backed checks run: %d" % _helper_check_count)
	print("Failures collected: %d" % _failures.size())


func _expect_true(value: bool, label: String) -> void:
	if value:
		return

	_record_failure(label)


func _record_failure(message: String) -> void:
	_failures.append(message)
