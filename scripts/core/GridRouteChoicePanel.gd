extends PanelContainer
class_name GridRouteChoicePanel


signal direction_chosen(direction: int)


@onready var _up_button: Button = $Actions/UpButton
@onready var _right_button: Button = $Actions/RightButton
@onready var _down_button: Button = $Actions/DownButton
@onready var _left_button: Button = $Actions/LeftButton


func _ready() -> void:
	# Project the isometric map directions onto the familiar screen controls.
	_up_button.pressed.connect(_emit_direction.bind(BoardConnectionData.Direction.LEFT))
	_right_button.pressed.connect(_emit_direction.bind(BoardConnectionData.Direction.DOWN))
	_down_button.pressed.connect(_emit_direction.bind(BoardConnectionData.Direction.RIGHT))
	_left_button.pressed.connect(_emit_direction.bind(BoardConnectionData.Direction.UP))
	hide_choices()


func show_choices(directions: PackedInt32Array) -> void:
	_set_button_state(_up_button, BoardConnectionData.Direction.LEFT, directions)
	_set_button_state(_right_button, BoardConnectionData.Direction.DOWN, directions)
	_set_button_state(_down_button, BoardConnectionData.Direction.RIGHT, directions)
	_set_button_state(_left_button, BoardConnectionData.Direction.UP, directions)
	visible = not directions.is_empty()


func hide_choices() -> void:
	visible = false


func _set_button_state(button: Button, direction: int, directions: PackedInt32Array) -> void:
	button.visible = directions.has(direction)


func _emit_direction(direction: int) -> void:
	direction_chosen.emit(direction)
