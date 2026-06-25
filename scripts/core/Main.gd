extends Node


const MAX_EVENT_LOG_LINES: int = 100
const PIECE_OFFSETS: Array[Vector2] = [
	Vector2(-16.0, -12.0),
	Vector2(16.0, 12.0),
]
const ROUTE_DIRECTION_UP := "up"
const ROUTE_DIRECTION_RIGHT := "right"
const ROUTE_DIRECTION_DOWN := "down"
const ROUTE_DIRECTION_LEFT := "left"


@onready var board: Board = $Board as Board
@onready var pieces_root: Node2D = $Pieces as Node2D
@onready var ui: GameUI = $UI as GameUI

var _visual_pieces_by_player_id: Dictionary = {}
var _event_log: Array[String] = []


func _ready() -> void:
	_register_visual_pieces()
	_connect_ui_actions()
	EventBus.game_event_emitted.connect(_on_game_event)
	_start_local_game()


func _start_local_game() -> void:
	if board == null:
		push_error("Main requires a Board child.")
		return

	var board_data: BoardData = board.board_data as BoardData
	if board_data == null:
		push_error("Board requires BoardData.")
		return

	for message in board_data.get_player_spawn_validation_messages():
		push_warning(message)

	GameManager.start_local_game(_create_initial_player_states(board_data), board_data)


func _create_initial_player_states(board_data: BoardData) -> Array[PlayerState]:
	var players: Array[PlayerState] = []
	var player_ids: Array[int] = []
	for key in _visual_pieces_by_player_id.keys():
		player_ids.append(int(key))

	player_ids.sort()
	for player_id in player_ids:
		var spawn_tile_index: int = board_data.get_player_spawn_tile_index(player_id)
		players.append(PlayerState.new(player_id, "Player %d" % [player_id + 1], 1500, spawn_tile_index))

	return players


func _connect_ui_actions() -> void:
	if ui == null:
		push_error("Main requires a GameUI child.")
		return

	ui.roll_pressed.connect(_on_roll_button_pressed)
	ui.property_buy_pressed.connect(_on_property_buy_pressed)
	ui.property_skip_pressed.connect(_on_property_skip_pressed)
	ui.route_choice_pressed.connect(_on_route_choice_pressed)


func _on_roll_button_pressed() -> void:
	GameManager.request_roll()


func _on_property_buy_pressed() -> void:
	GameManager.request_buy_pending_property()


func _on_property_skip_pressed() -> void:
	GameManager.request_skip_pending_property()


func _on_route_choice_pressed(tile_index: int) -> void:
	GameManager.request_route_choice(tile_index)


func _on_game_event(event: GameEvent) -> void:
	match event.type:
		GameEvent.GAME_STARTED:
			_handle_game_started()
		GameEvent.ROUND_STARTED:
			_handle_round_started(event.payload)
		GameEvent.TURN_STARTED:
			_handle_turn_started(event.payload)
		GameEvent.DICE_ROLLED:
			_handle_dice_rolled(event.payload)
		GameEvent.PLAYER_MOVED:
			_handle_player_moved(event.payload)
		GameEvent.PLAYER_LANDED:
			_handle_player_landed(event.payload)
		GameEvent.ROUTE_CHOICE_REQUESTED:
			_handle_route_choice_requested(event.payload)
		GameEvent.RENT_PAID:
			_handle_rent_paid(event.payload)
		GameEvent.PROPERTY_PURCHASE_OFFERED:
			_handle_property_purchase_offered(event.payload)
		GameEvent.PROPERTY_PURCHASED:
			_handle_property_purchased(event.payload)
		GameEvent.PROPERTY_PURCHASE_SKIPPED:
			_handle_property_purchase_skipped(event.payload)


func _handle_game_started() -> void:
	_event_log.clear()
	_update_log_label()
	_update_dice_label(0)
	_update_tile_label(-1, "", "")
	_update_event_label("")
	_update_money_label()
	_sync_piece_positions()
	_sync_property_owner_visuals()
	if ui != null:
		ui.hide_route_actions()


func _handle_round_started(payload: Dictionary) -> void:
	var round: int = int(payload.get("round", 1))
	if ui != null:
		ui.set_round_text("Round %d" % round)

	if round > 1:
		_add_event_log_line("Round %d begins" % round)


func _handle_turn_started(payload: Dictionary) -> void:
	var player_id: int = int(payload.get("player_id", -1))
	if ui != null and player_id >= 0:
		ui.set_turn_text("Player %d Turn" % [player_id + 1])


func _handle_dice_rolled(payload: Dictionary) -> void:
	_update_dice_label(int(payload.get("dice_value", 0)))


func _handle_player_moved(payload: Dictionary) -> void:
	var player_id: int = int(payload.get("player_id", -1))
	var tile_index: int = int(payload.get("to_tile_index", 0))
	_move_player_piece_visual(player_id, tile_index)
	if ui != null:
		ui.hide_route_actions()


func _handle_player_landed(payload: Dictionary) -> void:
	var player_id: int = int(payload.get("player_id", -1))
	var tile_index: int = int(payload.get("tile_index", -1))
	var tile_name: String = str(payload.get("tile_name", "Unknown"))
	var dice_value: int = int(payload.get("dice_value", 0))

	_update_event_label("")
	_update_tile_label(player_id, "%02d" % tile_index, tile_name)
	_add_event_log_line("P%d rolled %d -> tile %02d %s" % [player_id + 1, dice_value, tile_index, tile_name])


func _handle_route_choice_requested(payload: Dictionary) -> void:
	var player_id: int = int(payload.get("player_id", -1))
	var tile_index: int = int(payload.get("tile_index", -1))
	var remaining_steps: int = int(payload.get("remaining_steps", 0))
	var next_tile_indices: Array = payload.get("next_tile_indices", [])
	var message: String = "P%d is choosing a route at tile %02d (%d steps left)" % [player_id + 1, tile_index, remaining_steps]
	_update_event_label(message)
	_add_event_log_line(message)
	if ui != null:
		ui.show_route_actions(_get_route_options_by_direction(tile_index, next_tile_indices))


func _handle_rent_paid(payload: Dictionary) -> void:
	var payer_id: int = int(payload.get("payer_id", -1))
	var owner_id: int = int(payload.get("owner_id", -1))
	var amount: int = int(payload.get("amount", 0))
	var tile_name: String = str(payload.get("tile_name", "property"))
	var message: String = "P%d paid P%d $%d rent for %s" % [payer_id + 1, owner_id + 1, amount, tile_name]
	_update_money_label()
	_update_event_label(message)
	_add_event_log_line(message)


func _handle_property_purchase_offered(payload: Dictionary) -> void:
	var player_id: int = int(payload.get("player_id", -1))
	var tile_name: String = str(payload.get("tile_name", "property"))
	var price: int = int(payload.get("price", 0))
	var message: String = "P%d can buy %s for $%d" % [player_id + 1, tile_name, price]
	_update_event_label(message)
	_add_event_log_line(message)
	if ui != null:
		ui.show_property_actions()


func _handle_property_purchased(payload: Dictionary) -> void:
	var player_id: int = int(payload.get("player_id", -1))
	var tile_index: int = int(payload.get("tile_index", -1))
	var tile_name: String = str(payload.get("tile_name", "property"))
	var price: int = int(payload.get("price", 0))
	var message: String = "P%d bought %s for $%d" % [player_id + 1, tile_name, price]
	if board != null and tile_index >= 0:
		board.set_property_owner(tile_index, player_id)
	_update_money_label()
	_update_event_label(message)
	_add_event_log_line(message)
	if ui != null:
		ui.hide_property_actions()


func _handle_property_purchase_skipped(payload: Dictionary) -> void:
	var player_id: int = int(payload.get("player_id", -1))
	var tile_name: String = str(payload.get("tile_name", "property"))
	var reason: String = str(payload.get("reason", "skipped"))
	var message: String = "P%d skipped %s" % [player_id + 1, tile_name]
	if reason == "insufficient_funds":
		message = "P%d cannot afford %s" % [player_id + 1, tile_name]

	_update_event_label(message)
	_add_event_log_line(message)
	if ui != null:
		ui.hide_property_actions()


func _register_visual_pieces() -> void:
	_visual_pieces_by_player_id.clear()
	if pieces_root == null:
		push_error("Main requires a Pieces child.")
		return

	var pieces: Array[Node] = pieces_root.get_children()
	for child in pieces:
		var piece: PlayerPiece = child as PlayerPiece
		if piece != null:
			_visual_pieces_by_player_id[piece.player_id] = piece


func _sync_piece_positions() -> void:
	if GameManager.state == null:
		return

	for player_id in GameManager.state.player_order:
		var player: PlayerState = GameManager.state.get_player(player_id)
		if player != null:
			_move_player_piece_visual(player.player_id, player.tile_index)


func _sync_property_owner_visuals() -> void:
	if board == null or GameManager.state == null:
		return

	board.set_property_owners(GameManager.state.property_owner_by_tile)


func _move_player_piece_visual(player_id: int, tile_index: int) -> void:
	var piece: PlayerPiece = _get_visual_piece(player_id)
	if piece == null or board == null or pieces_root == null:
		return

	var tile_position: Vector2 = pieces_root.to_local(board.to_global(board.get_tile_position(tile_index)))
	var piece_offset: Vector2 = PIECE_OFFSETS[posmod(player_id, PIECE_OFFSETS.size())]
	piece.move_to(tile_position + piece_offset)


func _get_route_options_by_direction(from_tile_index: int, next_tile_indices: Array) -> Dictionary:
	var route_options_by_direction: Dictionary = {}
	if board == null:
		return route_options_by_direction

	var from_position: Vector2 = board.get_tile_position(from_tile_index)
	for next_tile_index_value in next_tile_indices:
		var next_tile_index: int = int(next_tile_index_value)
		var direction: String = _get_route_direction(from_position, board.get_tile_position(next_tile_index))
		if route_options_by_direction.has(direction):
			push_warning("Multiple route options map to %s at tile %d." % [direction, from_tile_index])
			continue

		route_options_by_direction[direction] = next_tile_index

	return route_options_by_direction


func _get_route_direction(from_position: Vector2, to_position: Vector2) -> String:
	var offset: Vector2 = to_position - from_position
	if absf(offset.x) >= absf(offset.y):
		return ROUTE_DIRECTION_RIGHT if offset.x >= 0.0 else ROUTE_DIRECTION_LEFT

	return ROUTE_DIRECTION_DOWN if offset.y >= 0.0 else ROUTE_DIRECTION_UP


func _get_visual_piece(player_id: int) -> PlayerPiece:
	if not _visual_pieces_by_player_id.has(player_id):
		return null

	return _visual_pieces_by_player_id[player_id] as PlayerPiece


func _update_dice_label(dice_value: int) -> void:
	if ui == null:
		return

	if dice_value <= 0:
		ui.set_dice_text("Dice: -")
		return

	ui.set_dice_text("Dice: %d" % dice_value)


func _update_tile_label(player_id: int, tile_index: String, tile_name: String) -> void:
	if ui == null:
		return

	if player_id < 0:
		ui.set_tile_text("Landed: -")
		return

	ui.set_tile_text("Player %d landed on %s %s" % [player_id + 1, tile_index, tile_name])


func _update_money_label() -> void:
	if ui == null or GameManager.state == null:
		return

	var money_text: String = ""
	for player_id in GameManager.state.player_order:
		var player: PlayerState = GameManager.state.get_player(player_id)
		if player == null:
			continue

		if not money_text.is_empty():
			money_text += "  "
		money_text += "P%d $%d" % [player_id + 1, player.money]

	ui.set_money_text("Money: %s" % money_text)


func _update_event_label(message: String) -> void:
	if ui == null:
		return

	if message.is_empty():
		ui.set_event_text("Event: -")
		return

	ui.set_event_text(message)


func _update_log_label() -> void:
	if ui == null:
		return

	if _event_log.is_empty():
		ui.set_log_text("Log: -")
		return

	var log_text: String = ""
	for line in _event_log:
		if not log_text.is_empty():
			log_text += "\n"
		log_text += line

	ui.set_log_text(log_text)


func _add_event_log_line(message: String) -> void:
	if message.is_empty():
		return

	_event_log.append(message)
	while _event_log.size() > MAX_EVENT_LOG_LINES:
		_event_log.remove_at(0)

	_update_log_label()
