extends SceneTree


const UI_SCENE_PATH := "res://scenes/UI.tscn"
const CardServiceScript := preload("res://scripts/core/CardService.gd")
const CardDefinitionScript := preload("res://scripts/core/CardDefinition.gd")


var _failure_count: int = 0
var _last_play_payload: Dictionary = {}


func _init() -> void:
	_run_smoke.call_deferred()


func _run_smoke() -> void:
	var ui_scene := load(UI_SCENE_PATH) as PackedScene
	if ui_scene == null:
		_fail("Could not load UI scene: %s" % UI_SCENE_PATH)
		_finish()
		return

	var ui := ui_scene.instantiate() as GameUI
	if ui == null:
		_fail("UI scene did not instantiate as GameUI.")
		_finish()
		return

	root.add_child(ui)
	await process_frame

	var card_service := CardServiceScript.new()
	var metadata: Dictionary = card_service.create_prototype_pre_roll_card().get_visible_metadata()
	var panel := ui.get_node_or_null("CardHandPanel") as CardHandPanel
	var play_button := ui.get_node_or_null("CardHandPanel/HandPanel/HandMargin/HandRow/PlayCardButton") as Button

	_expect_true(panel != null, "card hand panel exists")
	_expect_true(play_button != null, "play card button exists")
	if panel == null or play_button == null:
		_finish()
		return

	ui.card_play_pressed.connect(_on_card_play_pressed)
	ui.set_card_hand_state(metadata, false, 1, CardDefinitionScript.TIMING_PRE_ROLL, 0)
	await process_frame
	_expect_true(panel.visible, "card hand panel remains visible while inactive")
	_expect_true(play_button.disabled, "play button is disabled while inactive")

	ui.set_card_hand_state(metadata, true, 1, CardDefinitionScript.TIMING_PRE_ROLL, 0)
	await process_frame
	_expect_false(play_button.disabled, "play button is enabled while active")
	play_button.emit_signal("pressed")
	await process_frame

	_expect_equal(1, int(_last_play_payload.get("player_id", -1)), "play signal carries acting player")
	_expect_equal(CardServiceScript.CARD_PROTOTYPE_PRE_ROLL_GRANT, _last_play_payload.get("card_id", &""), "play signal carries card id")
	_expect_equal(CardDefinitionScript.TIMING_PRE_ROLL, _last_play_payload.get("window_id", &""), "play signal carries window id")
	_expect_equal(0, int(_last_play_payload.get("target_player_id", -1)), "play signal carries target player")

	ui.queue_free()
	_finish()


func _on_card_play_pressed(player_id: int, card_id: StringName, window_id: StringName, target_player_id: int) -> void:
	_last_play_payload = {
		"player_id": player_id,
		"card_id": card_id,
		"window_id": window_id,
		"target_player_id": target_player_id,
	}


func _finish() -> void:
	if _failure_count == 0:
		print("PASS: Card hand UI smoke")
		quit(0)
	else:
		push_error("FAIL: Card hand UI smoke had %d failure(s)" % _failure_count)
		quit(1)


func _expect_true(value: bool, label: String) -> void:
	if value:
		return

	_fail("Expected true: %s" % label)


func _expect_false(value: bool, label: String) -> void:
	if not value:
		return

	_fail("Expected false: %s" % label)


func _expect_equal(actual: Variant, expected: Variant, label: String) -> void:
	if actual == expected:
		return

	_fail("%s: expected %s, got %s" % [label, str(expected), str(actual)])


func _fail(message: String) -> void:
	_failure_count += 1
	push_error(message)
