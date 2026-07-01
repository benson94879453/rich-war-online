extends CanvasLayer
class_name GameUI


signal roll_pressed
signal property_buy_pressed
signal property_skip_pressed
signal route_choice_pressed(tile_index: int)
signal grid_route_choice_pressed(direction: int)
signal network_host_pressed
signal network_join_pressed(address: String)
signal host_open_seat_control_toggled(enabled: bool)
signal card_play_pressed(player_id: int, card_id: StringName, window_id: StringName, target_player_id: int)


@onready var network_status_label: Label = $NetworkPanel/NetworkMargin/NetworkColumn/NetworkStatusLabel as Label
@onready var network_address_input: LineEdit = $NetworkPanel/NetworkMargin/NetworkColumn/NetworkAddressInput as LineEdit
@onready var host_open_seat_check_box: CheckBox = $NetworkPanel/NetworkMargin/NetworkColumn/HostOpenSeatCheckBox as CheckBox
@onready var host_button: Button = $NetworkPanel/NetworkMargin/NetworkColumn/NetworkActions/HostButton as Button
@onready var join_button: Button = $NetworkPanel/NetworkMargin/NetworkColumn/NetworkActions/JoinButton as Button
@onready var turn_label: Label = $StatusPanel/StatusMargin/StatusColumn/TurnLabel as Label
@onready var round_label: Label = $StatusPanel/StatusMargin/StatusColumn/RoundLabel as Label
@onready var dice_label: Label = $StatusPanel/StatusMargin/StatusColumn/DiceLabel as Label
@onready var tile_label: Label = $StatusPanel/StatusMargin/StatusColumn/TileLabel as Label
@onready var money_label: Label = $StatusPanel/StatusMargin/StatusColumn/MoneyLabel as Label
@onready var event_label: Label = $StatusPanel/StatusMargin/StatusColumn/EventLabel as Label
@onready var roll_button: Button = $StatusPanel/StatusMargin/StatusColumn/RollButton as Button
@onready var route_actions: HBoxContainer = $StatusPanel/StatusMargin/StatusColumn/RouteActions as HBoxContainer
@onready var up_button: Button = $StatusPanel/StatusMargin/StatusColumn/RouteActions/UpButton as Button
@onready var right_button: Button = $StatusPanel/StatusMargin/StatusColumn/RouteActions/RightButton as Button
@onready var down_button: Button = $StatusPanel/StatusMargin/StatusColumn/RouteActions/DownButton as Button
@onready var left_button: Button = $StatusPanel/StatusMargin/StatusColumn/RouteActions/LeftButton as Button
@onready var property_actions: HBoxContainer = $StatusPanel/StatusMargin/StatusColumn/PropertyActions as HBoxContainer
@onready var buy_button: Button = $StatusPanel/StatusMargin/StatusColumn/PropertyActions/BuyButton as Button
@onready var skip_button: Button = $StatusPanel/StatusMargin/StatusColumn/PropertyActions/SkipButton as Button
@onready var log_scroll: ScrollContainer = $LogPanel/LogMargin/LogScroll as ScrollContainer
@onready var log_label: Label = $LogPanel/LogMargin/LogScroll/LogContent/LogLabel as Label
@onready var log_bottom_marker: Control = $LogPanel/LogMargin/LogScroll/LogContent/LogBottomMarker as Control
@onready var card_hand_panel: CardHandPanel = $CardHandPanel as CardHandPanel

var _route_options_by_direction: Dictionary = {}
var _grid_route_directions_by_button: Dictionary = {}
var _roll_allowed: bool = true


func _ready() -> void:
	if host_button != null:
		host_button.pressed.connect(_on_host_button_pressed)
	if join_button != null:
		join_button.pressed.connect(_on_join_button_pressed)
	if network_address_input != null:
		network_address_input.text_submitted.connect(_on_network_address_submitted)
	if host_open_seat_check_box != null:
		host_open_seat_check_box.toggled.connect(_on_host_open_seat_toggled)
	if card_hand_panel != null:
		card_hand_panel.play_card_pressed.connect(_on_card_play_pressed)
	if roll_button != null:
		roll_button.pressed.connect(_on_roll_button_pressed)
	if buy_button != null:
		buy_button.pressed.connect(_on_buy_button_pressed)
	if skip_button != null:
		skip_button.pressed.connect(_on_skip_button_pressed)
	if up_button != null:
		up_button.pressed.connect(_on_route_button_pressed.bind("up"))
	if right_button != null:
		right_button.pressed.connect(_on_route_button_pressed.bind("right"))
	if down_button != null:
		down_button.pressed.connect(_on_route_button_pressed.bind("down"))
	if left_button != null:
		left_button.pressed.connect(_on_route_button_pressed.bind("left"))
	hide_property_actions()
	hide_route_actions()


func set_turn_text(value: String) -> void:
	if turn_label != null:
		turn_label.text = value


func set_round_text(value: String) -> void:
	if round_label != null:
		round_label.text = value


func set_dice_text(value: String) -> void:
	if dice_label != null:
		dice_label.text = value


func set_tile_text(value: String) -> void:
	if tile_label != null:
		tile_label.text = value


func set_money_text(value: String) -> void:
	if money_label != null:
		money_label.text = value


func set_event_text(value: String) -> void:
	if event_label != null:
		event_label.text = value


func set_network_status_text(value: String) -> void:
	if network_status_label != null:
		network_status_label.text = value


func set_network_address_text(value: String) -> void:
	if network_address_input != null:
		network_address_input.text = value


func set_host_open_seat_control_enabled(value: bool) -> void:
	if host_open_seat_check_box != null:
		host_open_seat_check_box.button_pressed = value


func show_property_actions() -> void:
	if property_actions != null:
		property_actions.visible = true
	hide_route_actions()
	_update_roll_button_state()


func hide_property_actions() -> void:
	if property_actions != null:
		property_actions.visible = false
	_update_roll_button_state()


func show_route_actions(route_options_by_direction: Dictionary) -> void:
	_route_options_by_direction = route_options_by_direction.duplicate()
	_grid_route_directions_by_button.clear()
	_set_route_button_state(up_button, "up")
	_set_route_button_state(right_button, "right")
	_set_route_button_state(down_button, "down")
	_set_route_button_state(left_button, "left")
	if route_actions != null:
		route_actions.visible = not _route_options_by_direction.is_empty()
	hide_property_actions()
	_update_roll_button_state()


func hide_route_actions() -> void:
	_route_options_by_direction.clear()
	_grid_route_directions_by_button.clear()
	if route_actions != null:
		route_actions.visible = false
	_update_roll_button_state()


func show_grid_route_actions(directions: PackedInt32Array) -> void:
	_route_options_by_direction.clear()
	_grid_route_directions_by_button = {
		"up": BoardConnectionData.Direction.LEFT,
		"right": BoardConnectionData.Direction.DOWN,
		"down": BoardConnectionData.Direction.RIGHT,
		"left": BoardConnectionData.Direction.UP,
	}
	_set_grid_route_button_state(up_button, "up", directions)
	_set_grid_route_button_state(right_button, "right", directions)
	_set_grid_route_button_state(down_button, "down", directions)
	_set_grid_route_button_state(left_button, "left", directions)
	if route_actions != null:
		route_actions.visible = not directions.is_empty()
	hide_property_actions()
	_update_roll_button_state()


func set_roll_allowed(value: bool) -> void:
	_roll_allowed = value
	_update_roll_button_state()


func set_log_text(value: String) -> void:
	if log_label != null:
		log_label.text = value
		_scroll_log_to_bottom_after_layout()


func set_card_hand_state(
		metadata: Dictionary,
		is_playable: bool,
		acting_player_id: int,
		window_id: StringName,
		target_player_id: int
) -> void:
	if card_hand_panel != null:
		card_hand_panel.set_card_state(metadata, is_playable, acting_player_id, window_id, target_player_id)


func _on_host_button_pressed() -> void:
	network_host_pressed.emit()


func _on_join_button_pressed() -> void:
	_emit_join_pressed()


func _on_network_address_submitted(_value: String) -> void:
	_emit_join_pressed()


func _on_host_open_seat_toggled(enabled: bool) -> void:
	host_open_seat_control_toggled.emit(enabled)


func _on_card_play_pressed(player_id: int, card_id: StringName, window_id: StringName, target_player_id: int) -> void:
	card_play_pressed.emit(player_id, card_id, window_id, target_player_id)


func _on_roll_button_pressed() -> void:
	roll_pressed.emit()


func _on_buy_button_pressed() -> void:
	property_buy_pressed.emit()


func _on_skip_button_pressed() -> void:
	property_skip_pressed.emit()


func _emit_join_pressed() -> void:
	var address := ""
	if network_address_input != null:
		address = network_address_input.text
	network_join_pressed.emit(address)


func _on_route_button_pressed(direction: String) -> void:
	if _grid_route_directions_by_button.has(direction):
		grid_route_choice_pressed.emit(int(_grid_route_directions_by_button[direction]))
		return

	if not _route_options_by_direction.has(direction):
		return

	route_choice_pressed.emit(int(_route_options_by_direction[direction]))


func _set_route_button_state(button: Button, direction: String) -> void:
	if button == null:
		return

	button.visible = true
	button.disabled = not _route_options_by_direction.has(direction)


func _set_grid_route_button_state(button: Button, button_direction: String, directions: PackedInt32Array) -> void:
	if button == null:
		return

	var map_direction: int = int(_grid_route_directions_by_button.get(button_direction, BoardConnectionData.Direction.NONE))
	button.visible = directions.has(map_direction)
	button.disabled = not button.visible


func _update_roll_button_state() -> void:
	if roll_button == null:
		return

	var property_actions_visible: bool = property_actions != null and property_actions.visible
	var route_actions_visible: bool = route_actions != null and route_actions.visible
	roll_button.disabled = not _roll_allowed or property_actions_visible or route_actions_visible


func _scroll_log_to_bottom() -> void:
	if log_scroll == null:
		return

	if log_bottom_marker != null:
		log_scroll.ensure_control_visible(log_bottom_marker)

	var vertical_scroll_bar: VScrollBar = log_scroll.get_v_scroll_bar()
	if vertical_scroll_bar == null:
		return

	log_scroll.set_deferred("scroll_vertical", int(vertical_scroll_bar.max_value))


func _scroll_log_to_bottom_after_layout() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	_scroll_log_to_bottom()
