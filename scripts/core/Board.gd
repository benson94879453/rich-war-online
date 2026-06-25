extends Node2D
class_name Board


const DEFAULT_BOARD_DATA := preload("res://resources/tiles/default_board.tres")
const EXPECTED_EDGE_TILE_COUNT := 10
const OWNER_COLORS: Array[Color] = [
	Color(0.96, 0.23, 0.2),
	Color(0.18, 0.45, 0.95),
	Color(0.2, 0.72, 0.35),
	Color(0.94, 0.72, 0.2),
]

enum TileShape {
	RECTANGLE,
	DIAMOND,
}


@export var board_data: Resource
@export var tile_size: Vector2 = Vector2(116.0, 76.0)
@export var tile_gap: float = 6.0
@export var origin: Vector2 = Vector2.ZERO
@export var tile_shape: TileShape = TileShape.RECTANGLE
@export var show_tile_indices: bool = true
@export var show_tile_names: bool = true
@export_range(8, 32, 1) var tile_index_font_size: int = 16
@export_range(8, 32, 1) var tile_name_font_size: int = 14

var _tile_positions: Array[Vector2] = []
var _property_owner_by_tile: Dictionary = {}


func _ready() -> void:
	build_board()


func build_board() -> void:
	var data := _get_board_data()
	if data == null:
		push_error("BoardData is missing.")
		return

	if not data.has_explicit_placements() and not data.has_expected_tile_count():
		push_warning("BoardData should contain 40 tiles, but has %d." % data.get_tile_count())

	_tile_positions = _calculate_tile_positions(data)
	for message in data.get_placement_validation_messages():
		push_warning(message)
	for message in data.get_property_decoration_validation_messages():
		push_warning(message)
	for message in data.get_map_grid_validation_messages():
		push_warning(message)
	for message in data.get_source_node_validation_messages():
		push_warning(message)
	for message in data.get_connection_validation_messages():
		push_warning(message)
	queue_redraw()


func get_tile_count() -> int:
	var data := _get_board_data()
	if data == null:
		return 0

	return data.get_tile_count()


func get_tile_data(tile_index: int) -> BoardTileData:
	var data := _get_board_data()
	if data == null:
		return null

	return data.get_tile(tile_index)


func get_tile_position(tile_index: int) -> Vector2:
	if _tile_positions.is_empty():
		var data := _get_board_data()
		if data != null:
			_tile_positions = _calculate_tile_positions(data)

	if _tile_positions.is_empty():
		return origin

	return _tile_positions[posmod(tile_index, _tile_positions.size())] + tile_size * 0.5


func get_content_rect() -> Rect2:
	var data := _get_board_data()
	if data == null:
		return Rect2()

	if _tile_positions.is_empty():
		_tile_positions = _calculate_tile_positions(data)

	var content_rect := Rect2()
	var has_content: bool = false
	for tile_position in _tile_positions:
		var tile_rect := Rect2(tile_position, tile_size)
		content_rect = tile_rect if not has_content else content_rect.merge(tile_rect)
		has_content = true

	for decoration in data.get_property_decorations():
		var decoration_rect := Rect2(origin + decoration.center_position - tile_size * 0.5, tile_size)
		content_rect = decoration_rect if not has_content else content_rect.merge(decoration_rect)
		has_content = true

	return content_rect


func set_property_owner(tile_index: int, player_id: int) -> void:
	var tile_count: int = get_tile_count()
	if tile_count <= 0:
		return

	_property_owner_by_tile[posmod(tile_index, tile_count)] = player_id
	queue_redraw()


func set_property_owners(owners_by_tile: Dictionary) -> void:
	_property_owner_by_tile.clear()
	var tile_count: int = get_tile_count()
	if tile_count <= 0:
		queue_redraw()
		return

	for tile_index in owners_by_tile:
		_property_owner_by_tile[posmod(int(tile_index), tile_count)] = int(owners_by_tile[tile_index])

	queue_redraw()


func _draw() -> void:
	var data := _get_board_data()
	if data == null or _tile_positions.is_empty():
		return

	var font := ThemeDB.fallback_font
	_draw_property_decorations(data)
	for tile_index in range(data.get_tile_count()):
		var tile_data := data.get_tile(tile_index)
		var tile_position := _tile_positions[tile_index]
		var tile_rect := Rect2(tile_position, tile_size)
		var tile_color := Color.DIM_GRAY
		if tile_data != null:
			tile_color = tile_data.color

		_draw_tile_shape(tile_rect, tile_color)
		_draw_owner_marker(font, tile_index, tile_position, tile_data)
		_draw_tile_outline(tile_rect)

		if font == null or tile_data == null:
			continue

		_draw_tile_text(font, tile_position, tile_data)


func _draw_owner_marker(font: Font, tile_index: int, tile_position: Vector2, tile_data: BoardTileData) -> void:
	if font == null or tile_data == null or not tile_data.is_property():
		return

	if not _property_owner_by_tile.has(tile_index):
		return

	var owner_id: int = int(_property_owner_by_tile[tile_index])
	var marker_rect := Rect2(tile_position + Vector2(4.0, 57.0), Vector2(tile_size.x - 8.0, 15.0))
	draw_rect(marker_rect, _get_owner_color(owner_id), true)
	draw_string(
		font,
		marker_rect.position + Vector2(6.0, 12.0),
		"P%d" % [owner_id + 1],
		HORIZONTAL_ALIGNMENT_LEFT,
		marker_rect.size.x - 12.0,
		12,
		Color.WHITE
	)


func _get_owner_color(owner_id: int) -> Color:
	return OWNER_COLORS[posmod(owner_id, OWNER_COLORS.size())]


func _draw_property_decorations(data: BoardData) -> void:
	for decoration in data.get_property_decorations():
		var tile_data := data.get_tile(decoration.tile_index)
		if tile_data == null or not tile_data.is_property():
			continue

		_draw_property_building(origin + decoration.center_position, tile_data.color)


func _draw_property_building(center_position: Vector2, building_color: Color) -> void:
	var building_width := tile_size.x * 0.38
	var building_height := tile_size.y * 0.28
	var base_rect := Rect2(
		center_position + Vector2(-building_width * 0.5, -building_height * 0.12),
		Vector2(building_width, building_height)
	)
	var roof_points := PackedVector2Array([
		center_position + Vector2(0.0, -tile_size.y * 0.42),
		Vector2(base_rect.end.x, base_rect.position.y),
		Vector2(base_rect.position.x, base_rect.position.y),
	])
	var outline_color := Color(0.08, 0.09, 0.1)

	draw_rect(base_rect, building_color.darkened(0.16), true)
	draw_rect(base_rect, outline_color, false, 1.5)
	draw_colored_polygon(roof_points, building_color.lightened(0.18))
	for point_index in range(roof_points.size()):
		draw_line(roof_points[point_index], roof_points[(point_index + 1) % roof_points.size()], outline_color, 1.5, true)


func _draw_tile_shape(tile_rect: Rect2, tile_color: Color) -> void:
	if tile_shape == TileShape.DIAMOND:
		draw_colored_polygon(_get_diamond_points(tile_rect), tile_color)
		return

	draw_rect(tile_rect, tile_color, true)


func _draw_tile_outline(tile_rect: Rect2) -> void:
	var outline_color := Color(0.08, 0.09, 0.1)
	if tile_shape == TileShape.DIAMOND:
		var points := _get_diamond_points(tile_rect)
		for point_index in range(points.size()):
			draw_line(points[point_index], points[(point_index + 1) % points.size()], outline_color, 2.0, true)
		return

	draw_rect(tile_rect, outline_color, false, 2.0)


func _draw_tile_text(font: Font, tile_position: Vector2, tile_data: BoardTileData) -> void:
	if tile_shape == TileShape.DIAMOND:
		if show_tile_names:
			var compact_name := tile_data.display_name.left(6)
			draw_string(
				font,
				tile_position + Vector2(5.0, tile_size.y * 0.5 + tile_name_font_size * 0.35),
				compact_name,
				HORIZONTAL_ALIGNMENT_CENTER,
				tile_size.x - 10.0,
				tile_name_font_size,
				Color.WHITE
			)
		return

	if show_tile_indices:
		draw_string(
			font,
			tile_position + Vector2(8.0, 20.0),
			"%02d" % tile_data.index,
			HORIZONTAL_ALIGNMENT_LEFT,
			tile_size.x - 16.0,
			tile_index_font_size,
			Color.WHITE
		)

	if show_tile_names:
		draw_string(
			font,
			tile_position + Vector2(8.0, 49.0),
			tile_data.display_name,
			HORIZONTAL_ALIGNMENT_LEFT,
			tile_size.x - 16.0,
			tile_name_font_size,
			Color.WHITE
		)


func _get_diamond_points(tile_rect: Rect2) -> PackedVector2Array:
	var center := tile_rect.get_center()
	return PackedVector2Array([
		Vector2(center.x, tile_rect.position.y),
		Vector2(tile_rect.end.x, center.y),
		Vector2(center.x, tile_rect.end.y),
		Vector2(tile_rect.position.x, center.y),
	])


func _calculate_tile_positions(data: BoardData) -> Array[Vector2]:
	var positions: Array[Vector2] = _calculate_loop_positions(data.get_tile_count())
	for tile_index in range(data.get_tile_count()):
		if data.has_tile_placement(tile_index):
			var center_position: Vector2 = data.get_tile_placement_center_position(tile_index)
			positions[tile_index] = origin + center_position - tile_size * 0.5

	return positions


func _calculate_loop_positions(tile_count: int) -> Array[Vector2]:
	var positions: Array[Vector2] = []
	if tile_count <= 0:
		return positions

	var step := tile_size + Vector2(tile_gap, tile_gap)
	for tile_index in range(tile_count):
		var grid_position := _get_loop_grid_position(tile_index)
		positions.append(origin + Vector2(grid_position.x * step.x, grid_position.y * step.y))

	return positions


func _get_board_data() -> BoardData:
	var data_resource: Resource = board_data
	if data_resource == null:
		data_resource = DEFAULT_BOARD_DATA

	if data_resource is BoardData:
		return data_resource as BoardData

	return null


func _get_loop_grid_position(tile_index: int) -> Vector2i:
	if tile_index <= EXPECTED_EDGE_TILE_COUNT:
		return Vector2i(0, EXPECTED_EDGE_TILE_COUNT - tile_index)

	if tile_index <= EXPECTED_EDGE_TILE_COUNT * 2:
		return Vector2i(tile_index - EXPECTED_EDGE_TILE_COUNT, 0)

	if tile_index <= EXPECTED_EDGE_TILE_COUNT * 3:
		return Vector2i(EXPECTED_EDGE_TILE_COUNT, tile_index - EXPECTED_EDGE_TILE_COUNT * 2)

	return Vector2i(EXPECTED_EDGE_TILE_COUNT * 4 - tile_index, EXPECTED_EDGE_TILE_COUNT)
