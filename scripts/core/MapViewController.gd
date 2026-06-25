extends Node2D
class_name MapViewController


@export var board_path: NodePath = NodePath("Board")
@export_range(0.1, 4.0, 0.05) var minimum_zoom: float = 0.4
@export_range(0.1, 4.0, 0.05) var maximum_zoom: float = 2.25
@export_range(1.01, 2.0, 0.01) var zoom_factor: float = 1.15
@export var fit_padding: Vector2 = Vector2(80.0, 80.0)

var _board: Board
var _is_dragging: bool = false


func _ready() -> void:
	_board = get_node_or_null(board_path) as Board
	if _board == null:
		push_error("MapViewController requires a Board child.")
		return

	call_deferred("reset_view")


func reset_view() -> void:
	if _board == null:
		return

	var content_rect := _board.get_content_rect()
	if content_rect.size.x <= 0.0 or content_rect.size.y <= 0.0:
		return

	var viewport_size := get_viewport_rect().size
	var available_size := viewport_size - fit_padding * 2.0
	var fitted_zoom := minf(
		available_size.x / content_rect.size.x,
		available_size.y / content_rect.size.y
	)
	var target_zoom := clampf(fitted_zoom, minimum_zoom, maximum_zoom)

	scale = Vector2.ONE * target_zoom
	position = (viewport_size - content_rect.size * target_zoom) * 0.5 - content_rect.position * target_zoom


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		_handle_mouse_button(event as InputEventMouseButton)
		return

	if event is InputEventMouseMotion and _is_dragging:
		position += (event as InputEventMouseMotion).relative
		get_viewport().set_input_as_handled()
		return

	if event is InputEventKey:
		var key_event := event as InputEventKey
		if key_event.pressed and not key_event.echo and key_event.keycode == KEY_HOME:
			reset_view()
			get_viewport().set_input_as_handled()


func _handle_mouse_button(event: InputEventMouseButton) -> void:
	if event.button_index == MOUSE_BUTTON_MIDDLE:
		_is_dragging = event.pressed
		get_viewport().set_input_as_handled()
		return

	if not event.pressed:
		return

	if event.button_index == MOUSE_BUTTON_WHEEL_UP:
		_zoom_at(event.position, zoom_factor)
		get_viewport().set_input_as_handled()
	elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
		_zoom_at(event.position, 1.0 / zoom_factor)
		get_viewport().set_input_as_handled()


func _zoom_at(screen_position: Vector2, factor: float) -> void:
	var map_position_at_cursor := to_local(screen_position)
	var target_zoom := clampf(scale.x * factor, minimum_zoom, maximum_zoom)
	if is_equal_approx(target_zoom, scale.x):
		return

	scale = Vector2.ONE * target_zoom
	position = screen_position - map_position_at_cursor * target_zoom
