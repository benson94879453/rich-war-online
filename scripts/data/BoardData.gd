extends Resource
class_name BoardData


const EXPECTED_TILE_COUNT := 40


@export var tiles: Array[Resource] = []
@export var connections: Array[Resource] = []
@export var placements: Array[Resource] = []
@export var property_decorations: Array[Resource] = []
@export var map_grid: Resource
@export var player_spawns: Array[Resource] = []


func get_tile_count() -> int:
	return tiles.size()


func has_expected_tile_count() -> bool:
	return tiles.size() == EXPECTED_TILE_COUNT


func has_explicit_placements() -> bool:
	return not placements.is_empty()


func normalize_index(tile_index: int) -> int:
	if tiles.is_empty():
		return -1

	return posmod(tile_index, tiles.size())


func has_tile_placement(tile_index: int) -> bool:
	return _get_tile_placement(tile_index) != null


func get_tile_placement_center_position(tile_index: int) -> Vector2:
	var placement: BoardTilePlacementData = _get_tile_placement(tile_index)
	if placement == null:
		return Vector2.ZERO

	return placement.center_position


func get_placement_validation_messages() -> PackedStringArray:
	var messages := PackedStringArray()
	var seen_tile_indices: Dictionary = {}
	for placement_resource in placements:
		var placement: BoardTilePlacementData = placement_resource as BoardTilePlacementData
		if placement == null:
			messages.append("Board placement entry is not BoardTilePlacementData.")
			continue

		if not _has_direct_tile_index(placement.tile_index):
			messages.append("Board placement references unknown tile %d." % placement.tile_index)
			continue

		if seen_tile_indices.has(placement.tile_index):
			messages.append("Board placement for tile %d is duplicated." % placement.tile_index)
			continue

		seen_tile_indices[placement.tile_index] = true

	return messages


func get_property_decorations() -> Array[BoardPropertyDecorationData]:
	var decorations: Array[BoardPropertyDecorationData] = []
	for decoration_resource in property_decorations:
		var decoration: BoardPropertyDecorationData = decoration_resource as BoardPropertyDecorationData
		if decoration != null:
			decorations.append(decoration)

	return decorations


func get_map_grid() -> BoardMapGridData:
	if map_grid is BoardMapGridData:
		return map_grid as BoardMapGridData

	return null


func get_map_grid_validation_messages() -> PackedStringArray:
	var grid := get_map_grid()
	if map_grid == null:
		return PackedStringArray()

	if grid == null:
		return PackedStringArray(["Board map grid is not BoardMapGridData."])

	return grid.get_validation_messages()


func get_property_decoration_validation_messages() -> PackedStringArray:
	var messages := PackedStringArray()
	for decoration_resource in property_decorations:
		var decoration: BoardPropertyDecorationData = decoration_resource as BoardPropertyDecorationData
		if decoration == null:
			messages.append("Board property decoration entry is not BoardPropertyDecorationData.")
			continue

		if not _has_direct_tile_index(decoration.tile_index):
			messages.append("Board property decoration references unknown tile %d." % decoration.tile_index)

	return messages


func get_connection_validation_messages() -> PackedStringArray:
	var messages := PackedStringArray()
	var seen_exits: Dictionary = {}
	for connection_resource in connections:
		var connection: BoardConnectionData = connection_resource as BoardConnectionData
		if connection == null:
			messages.append("Board connection entry is not BoardConnectionData.")
			continue

		if not _has_direct_tile_index(connection.from_tile_index):
			messages.append("Board connection references unknown source tile %d." % connection.from_tile_index)
			continue

		if not _has_direct_tile_index(connection.to_tile_index):
			messages.append("Board connection from tile %d references unknown destination tile %d." % [connection.from_tile_index, connection.to_tile_index])
			continue

		if not connection.has_valid_direction():
			messages.append("Board connection from tile %d to tile %d has no valid direction." % [connection.from_tile_index, connection.to_tile_index])
			continue

		var exit_key := "%d:%d" % [connection.from_tile_index, connection.direction]
		if seen_exits.has(exit_key):
			messages.append("Board tile %d has more than one connection for direction %d." % [connection.from_tile_index, connection.direction])
			continue

		seen_exits[exit_key] = true

	return messages


func get_source_node_validation_messages() -> PackedStringArray:
	var messages := PackedStringArray()
	var seen_source_node_ids: Dictionary = {}
	for tile_resource in tiles:
		var tile: BoardTileData = tile_resource as BoardTileData
		if tile == null or tile.source_node_id < 0:
			continue

		if seen_source_node_ids.has(tile.source_node_id):
			messages.append("Board source node %d maps to more than one tile." % tile.source_node_id)
			continue

		seen_source_node_ids[tile.source_node_id] = true

	return messages


func get_player_spawn_tile_index(player_id: int) -> int:
	for spawn_resource in player_spawns:
		var spawn: BoardPlayerSpawnData = spawn_resource as BoardPlayerSpawnData
		if spawn != null and spawn.player_id == player_id and _has_direct_tile_index(spawn.tile_index):
			return spawn.tile_index

	if _has_direct_tile_index(0):
		return 0

	return -1


func get_player_map_spawn(player_id: int) -> PlayerMapState:
	var map_grid_data: BoardMapGridData = get_map_grid()
	if map_grid_data == null:
		return PlayerMapState.new()

	for spawn_resource in player_spawns:
		var spawn: BoardPlayerSpawnData = spawn_resource as BoardPlayerSpawnData
		if spawn == null or spawn.player_id != player_id or not spawn.has_grid_spawn():
			continue

		return PlayerMapState.new(spawn.grid_position, spawn.initial_direction)

	return PlayerMapState.new()


func get_player_spawn_validation_messages() -> PackedStringArray:
	var messages := PackedStringArray()
	var seen_player_ids: Dictionary = {}
	var map_grid_data: BoardMapGridData = get_map_grid()
	for spawn_resource in player_spawns:
		var spawn: BoardPlayerSpawnData = spawn_resource as BoardPlayerSpawnData
		if spawn == null:
			messages.append("Board player spawn entry is not BoardPlayerSpawnData.")
			continue

		if spawn.has_grid_spawn():
			if map_grid_data == null or not map_grid_data.is_landing_node(spawn.grid_position):
				messages.append("Player %d grid spawn is not a landing node." % spawn.player_id)
			elif spawn.initial_direction < BoardConnectionData.Direction.RIGHT or spawn.initial_direction > BoardConnectionData.Direction.DOWN:
				messages.append("Player %d grid spawn has an invalid initial direction." % spawn.player_id)
		elif not _has_direct_tile_index(spawn.tile_index):
			messages.append("Player %d spawn references unknown tile %d." % [spawn.player_id, spawn.tile_index])
			continue

		if seen_player_ids.has(spawn.player_id):
			messages.append("Player %d has more than one board spawn." % spawn.player_id)
			continue

		seen_player_ids[spawn.player_id] = true

	return messages


func get_next_tile_indices(tile_index: int) -> Array[int]:
	var normalized_index: int = normalize_index(tile_index)
	if normalized_index == -1:
		return []

	var explicit_next_tile_indices: Array[int] = _get_explicit_next_tile_indices(normalized_index)
	if not explicit_next_tile_indices.is_empty():
		return explicit_next_tile_indices

	return [normalize_index(normalized_index + 1)]


func get_outgoing_connections(tile_index: int) -> Array[BoardConnectionData]:
	var normalized_index: int = normalize_index(tile_index)
	var outgoing_connections: Array[BoardConnectionData] = []
	if normalized_index == -1:
		return outgoing_connections

	for connection_resource in connections:
		var connection: BoardConnectionData = connection_resource as BoardConnectionData
		if connection == null or connection.from_tile_index != normalized_index:
			continue

		if _has_direct_tile_index(connection.to_tile_index):
			outgoing_connections.append(connection)

	return outgoing_connections


func get_next_tile_index_in_direction(tile_index: int, direction: int) -> int:
	for connection in get_outgoing_connections(tile_index):
		if connection.direction == direction:
			return connection.to_tile_index

	return -1


func get_connection_direction(from_tile_index: int, to_tile_index: int) -> int:
	for connection in get_outgoing_connections(from_tile_index):
		if connection.to_tile_index == to_tile_index:
			return connection.direction

	return BoardConnectionData.Direction.NONE


func get_tile_index_for_source_node_id(source_node_id: int) -> int:
	for tile_index in range(tiles.size()):
		var tile := get_tile(tile_index)
		if tile != null and tile.source_node_id == source_node_id:
			return tile_index

	return -1


func get_grid_position_for_tile_index(tile_index: int) -> Vector2i:
	var tile: BoardTileData = get_tile(tile_index)
	var grid: BoardMapGridData = get_map_grid()
	if tile == null or grid == null or tile.source_node_id < 0:
		return Vector2i(-1, -1)

	return grid.get_grid_position_for_node_id(tile.source_node_id)


func get_tile(tile_index: int) -> BoardTileData:
	var normalized_index := normalize_index(tile_index)
	if normalized_index == -1:
		return null

	var tile := tiles[normalized_index]
	if tile is BoardTileData:
		return tile as BoardTileData

	push_warning("Tile at index %d is not BoardTileData." % normalized_index)
	return null


func _get_explicit_next_tile_indices(from_tile_index: int) -> Array[int]:
	var next_tile_indices: Array[int] = []
	for connection in get_outgoing_connections(from_tile_index):
		if not next_tile_indices.has(connection.to_tile_index):
			next_tile_indices.append(connection.to_tile_index)

	return next_tile_indices


func _get_tile_placement(tile_index: int) -> BoardTilePlacementData:
	if not _has_direct_tile_index(tile_index):
		return null

	for placement_resource in placements:
		var placement: BoardTilePlacementData = placement_resource as BoardTilePlacementData
		if placement != null and placement.tile_index == tile_index:
			return placement

	return null


func _has_direct_tile_index(tile_index: int) -> bool:
	return tile_index >= 0 and tile_index < tiles.size() and tiles[tile_index] is BoardTileData
