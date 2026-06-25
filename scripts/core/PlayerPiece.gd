extends Node2D
class_name PlayerPiece


@export var player_id: int = -1
@export var piece_color: Color = Color(0.96, 0.23, 0.2)
@export var radius: float = 11.0
@export var display_name: String = ""


func _ready() -> void:
	queue_redraw()


func set_player_id(value: int) -> void:
	player_id = value
	queue_redraw()


func move_to(target_position: Vector2) -> void:
	position = target_position


func set_piece_color(value: Color) -> void:
	piece_color = value
	queue_redraw()


func set_display_name(value: String) -> void:
	display_name = value
	queue_redraw()


func _draw() -> void:
	draw_circle(Vector2.ZERO, radius, piece_color)
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 32, Color.WHITE, 2.0)
	_draw_nameplate()


func _draw_nameplate() -> void:
	if display_name.is_empty():
		return

	var font: Font = ThemeDB.fallback_font
	var font_size := 12
	var text_width: float = font.get_string_size(display_name, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size).x
	var label_width: float = maxf(28.0, text_width + 10.0)
	var label_rect := Rect2(Vector2(-label_width * 0.5, -radius - 24.0), Vector2(label_width, 18.0))
	draw_rect(label_rect, Color(0.05, 0.06, 0.07, 0.9), true)
	draw_rect(label_rect, piece_color.lightened(0.18), false, 1.0)
	draw_string(
		font,
		Vector2(label_rect.position.x, label_rect.position.y + 13.0),
		display_name,
		HORIZONTAL_ALIGNMENT_CENTER,
		label_rect.size.x,
		font_size,
		Color.WHITE
	)
