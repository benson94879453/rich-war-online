extends Control
class_name CardHandPanel


signal play_card_pressed(player_id: int, card_id: StringName, window_id: StringName, target_player_id: int)


const HAND_PANEL_SIZE := Vector2(720.0, 220.0)
const HAND_CARD_SIZE := Vector2(120.0, 168.0)
const INSPECT_CARD_SIZE := Vector2(240.0, 336.0)
const PANEL_PADDING := 18
const CARD_PADDING := 10
const DISABLED_ALPHA := 0.45
const INACTIVE_PANEL_COLOR := Color(0.12, 0.13, 0.14, 0.78)
const ACTIVE_PANEL_COLOR := Color(0.13, 0.18, 0.2, 0.9)
const INACTIVE_CARD_COLOR := Color(0.25, 0.25, 0.25, 0.88)
const ACTIVE_CARD_COLOR := Color(0.17, 0.23, 0.27, 0.96)
const INSPECT_CARD_COLOR := Color(0.16, 0.2, 0.24, 0.98)
const INACTIVE_BORDER_COLOR := Color(0.42, 0.42, 0.42, 0.85)
const ACTIVE_BORDER_COLOR := Color(0.94, 0.78, 0.28, 1.0)
const FALLBACK_ART_COLOR := Color(0.08, 0.1, 0.12, 1.0)


var _metadata: Dictionary = {}
var _is_playable: bool = false
var _acting_player_id: int = -1
var _target_player_id: int = -1
var _window_id: StringName = &""
var _inspect_pinned: bool = false
var _hand_panel: PanelContainer
var _hand_view: Dictionary = {}
var _inspect_panel: PanelContainer
var _inspect_view: Dictionary = {}
var _play_button: Button


func _ready() -> void:
	_build_ui()
	set_card_state({}, false, -1, &"", -1)


func set_card_state(
		metadata: Dictionary,
		is_playable: bool,
		acting_player_id: int,
		window_id: StringName,
		target_player_id: int
) -> void:
	_metadata = metadata.duplicate(true)
	_is_playable = is_playable
	_acting_player_id = acting_player_id
	_window_id = window_id
	_target_player_id = target_player_id
	_inspect_pinned = false
	_sync_views()


func clear_inspect() -> void:
	_inspect_pinned = false
	if _inspect_panel != null:
		_inspect_panel.visible = false


func _build_ui() -> void:
	custom_minimum_size = HAND_PANEL_SIZE
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	_hand_panel = PanelContainer.new()
	_hand_panel.name = "HandPanel"
	_hand_panel.custom_minimum_size = HAND_PANEL_SIZE
	_hand_panel.add_theme_stylebox_override("panel", _make_panel_style(false))
	add_child(_hand_panel)

	var hand_margin := MarginContainer.new()
	hand_margin.name = "HandMargin"
	hand_margin.add_theme_constant_override("margin_left", PANEL_PADDING)
	hand_margin.add_theme_constant_override("margin_top", PANEL_PADDING)
	hand_margin.add_theme_constant_override("margin_right", PANEL_PADDING)
	hand_margin.add_theme_constant_override("margin_bottom", PANEL_PADDING)
	_hand_panel.add_child(hand_margin)

	var hand_row := HBoxContainer.new()
	hand_row.name = "HandRow"
	hand_row.alignment = BoxContainer.ALIGNMENT_CENTER
	hand_row.add_theme_constant_override("separation", 18)
	hand_margin.add_child(hand_row)

	_hand_view = _create_card_view(HAND_CARD_SIZE, 14, 12)
	var hand_card: Control = _hand_view["root"] as Control
	hand_card.mouse_filter = Control.MOUSE_FILTER_STOP
	hand_card.mouse_entered.connect(_show_inspect)
	hand_card.mouse_exited.connect(_hide_hover_inspect)
	hand_card.gui_input.connect(_on_card_gui_input)
	hand_row.add_child(hand_card)

	_play_button = Button.new()
	_play_button.name = "PlayCardButton"
	_play_button.custom_minimum_size = Vector2(140.0, 48.0)
	_play_button.text = "Play Card"
	_play_button.tooltip_text = "Play the active pre-roll card"
	_play_button.pressed.connect(_on_play_button_pressed)
	hand_row.add_child(_play_button)

	_inspect_view = _create_card_view(INSPECT_CARD_SIZE, 24, 18)
	_inspect_panel = _inspect_view["root"] as PanelContainer
	_inspect_panel.name = "InspectCard"
	_inspect_panel.visible = false
	_inspect_panel.z_index = 20
	_inspect_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_inspect_panel)
	_position_inspect_panel()


func _create_card_view(card_size: Vector2, title_font_size: int, body_font_size: int) -> Dictionary:
	var card := PanelContainer.new()
	card.custom_minimum_size = card_size
	card.add_theme_stylebox_override("panel", _make_card_style(false, false))

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", CARD_PADDING)
	margin.add_theme_constant_override("margin_top", CARD_PADDING)
	margin.add_theme_constant_override("margin_right", CARD_PADDING)
	margin.add_theme_constant_override("margin_bottom", CARD_PADDING)
	card.add_child(margin)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 6)
	margin.add_child(column)

	var title := Label.new()
	title.custom_minimum_size = Vector2(card_size.x - 2.0 * CARD_PADDING, card_size.y * 0.2)
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", title_font_size)
	column.add_child(title)

	var art_box := PanelContainer.new()
	art_box.custom_minimum_size = Vector2(card_size.x - 2.0 * CARD_PADDING, card_size.y * 0.36)
	art_box.add_theme_stylebox_override("panel", _make_flat_style(FALLBACK_ART_COLOR, Color.TRANSPARENT, 0))
	column.add_child(art_box)

	var art_center := CenterContainer.new()
	art_box.add_child(art_center)

	var art_texture := TextureRect.new()
	art_texture.custom_minimum_size = art_box.custom_minimum_size
	art_texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	art_center.add_child(art_texture)

	var fallback_label := Label.new()
	fallback_label.text = "No test art"
	fallback_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	fallback_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	fallback_label.add_theme_font_size_override("font_size", body_font_size)
	art_center.add_child(fallback_label)

	var effect := Label.new()
	effect.custom_minimum_size = Vector2(card_size.x - 2.0 * CARD_PADDING, card_size.y * 0.18)
	effect.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	effect.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	effect.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	effect.add_theme_font_size_override("font_size", body_font_size)
	column.add_child(effect)

	var target := Label.new()
	target.custom_minimum_size = Vector2(card_size.x - 2.0 * CARD_PADDING, card_size.y * 0.14)
	target.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	target.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	target.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	target.add_theme_font_size_override("font_size", body_font_size)
	column.add_child(target)

	return {
		"root": card,
		"title": title,
		"texture": art_texture,
		"fallback": fallback_label,
		"effect": effect,
		"target": target,
	}


func _sync_views() -> void:
	if _hand_panel == null:
		return

	_hand_panel.add_theme_stylebox_override("panel", _make_panel_style(_is_playable))
	_sync_card_view(_hand_view, _is_playable, false)
	_sync_card_view(_inspect_view, true, true)
	_position_inspect_panel()

	if _play_button != null:
		_play_button.disabled = not _is_playable
		_play_button.modulate = Color.WHITE if _is_playable else Color(0.72, 0.72, 0.72, DISABLED_ALPHA)

	if _inspect_panel != null:
		_inspect_panel.visible = false


func _sync_card_view(view: Dictionary, active: bool, inspect: bool) -> void:
	if view.is_empty():
		return

	var root: PanelContainer = view["root"] as PanelContainer
	var title: Label = view["title"] as Label
	var texture: TextureRect = view["texture"] as TextureRect
	var fallback: Label = view["fallback"] as Label
	var effect: Label = view["effect"] as Label
	var target: Label = view["target"] as Label

	root.add_theme_stylebox_override("panel", _make_card_style(active, inspect))
	root.modulate = Color.WHITE if active else Color(0.8, 0.8, 0.8, DISABLED_ALPHA)
	title.text = _get_display_name()
	effect.text = _get_effect_summary()
	target.text = "Target: %s" % _get_target_summary()

	var art_path := _get_art_path()
	var art_texture := _load_card_texture(art_path)
	texture.texture = art_texture
	texture.visible = art_texture != null
	fallback.visible = art_texture == null


func _make_panel_style(active: bool) -> StyleBoxFlat:
	var bg_color := ACTIVE_PANEL_COLOR if active else INACTIVE_PANEL_COLOR
	return _make_flat_style(bg_color, ACTIVE_BORDER_COLOR if active else INACTIVE_BORDER_COLOR, 2)


func _make_card_style(active: bool, inspect: bool) -> StyleBoxFlat:
	var bg_color := INSPECT_CARD_COLOR if inspect else ACTIVE_CARD_COLOR if active else INACTIVE_CARD_COLOR
	var border_color := ACTIVE_BORDER_COLOR if active or inspect else INACTIVE_BORDER_COLOR
	return _make_flat_style(bg_color, border_color, 2)


func _make_flat_style(bg_color: Color, border_color: Color, border_width: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg_color
	style.border_color = border_color
	style.set_border_width_all(border_width)
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	return style


func _position_inspect_panel() -> void:
	if _inspect_panel == null:
		return

	_inspect_panel.position = Vector2(
		(HAND_PANEL_SIZE.x - INSPECT_CARD_SIZE.x) * 0.5,
		-INSPECT_CARD_SIZE.y - 16.0
	)


func _show_inspect() -> void:
	if _inspect_panel != null:
		_inspect_panel.visible = true


func _hide_hover_inspect() -> void:
	if _inspect_panel != null and not _inspect_pinned:
		_inspect_panel.visible = false


func _on_card_gui_input(event: InputEvent) -> void:
	var mouse_event := event as InputEventMouseButton
	if mouse_event == null or not mouse_event.pressed or mouse_event.button_index != MOUSE_BUTTON_LEFT:
		return

	_inspect_pinned = not _inspect_pinned
	if _inspect_panel != null:
		_inspect_panel.visible = _inspect_pinned


func _on_play_button_pressed() -> void:
	if not _is_playable:
		return

	play_card_pressed.emit(_acting_player_id, _get_card_id(), _window_id, _target_player_id)


func _get_display_name() -> String:
	var display_name := str(_metadata.get("display_name", "")).strip_edges()
	return "Prototype card" if display_name.is_empty() else display_name


func _get_effect_summary() -> String:
	var effect_summary := str(_metadata.get("effect_summary", "")).strip_edges()
	return "No active effect" if effect_summary.is_empty() else effect_summary


func _get_target_summary() -> String:
	var target_summary := str(_metadata.get("target_summary", "")).strip_edges()
	return "-" if target_summary.is_empty() else target_summary


func _get_art_path() -> String:
	return str(_metadata.get("art_path", "")).strip_edges()


func _get_card_id() -> StringName:
	var card_id: Variant = _metadata.get("card_id", &"")
	if card_id is StringName:
		return card_id

	return StringName(str(card_id).strip_edges())


func _load_card_texture(art_path: String) -> Texture2D:
	if art_path.is_empty() or not ResourceLoader.exists(art_path):
		return null

	return load(art_path) as Texture2D
