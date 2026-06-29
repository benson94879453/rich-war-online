extends RefCounted
class_name PropertyResolutionService


const RESULT_HANDLED := "handled"
const RESULT_COMPLETES_TURN := "completes_turn"
const RESULT_PLAYER_ID := "player_id"
const RESULT_EVENT_TYPE := "event_type"
const RESULT_EVENT_PAYLOAD := "event_payload"
const GameEventScript := preload("res://scripts/core/GameEvent.gd")


func create_purchase_offer(state: GameState, player_id: int, tile_data: BoardTileData) -> Dictionary:
	if state == null or tile_data == null or not tile_data.is_property():
		return _not_handled()

	if state.get_property_owner(tile_data.index) != -1:
		return _not_handled()

	state.begin_property_purchase(player_id, tile_data.index)
	return _with_event(GameEventScript.PROPERTY_PURCHASE_OFFERED, {
		"player_id": player_id,
		"tile_index": tile_data.index,
		"tile_name": tile_data.display_name,
		"price": tile_data.price,
	}, player_id, false)


func buy_pending_property(state: GameState, board_data: BoardData) -> Dictionary:
	if state == null or board_data == null or not state.has_pending_property_purchase():
		return _not_handled()

	var player_id: int = int(state.pending_property_purchase["player_id"])
	var tile_index: int = int(state.pending_property_purchase["tile_index"])
	var player: PlayerState = state.get_player(player_id)
	var tile_data: BoardTileData = board_data.get_tile(tile_index)
	state.clear_pending_property_purchase()
	if player == null or tile_data == null:
		return _completed_without_event(player_id)

	if player.money < tile_data.price:
		return _with_event(GameEventScript.PROPERTY_PURCHASE_SKIPPED, {
			"player_id": player_id,
			"tile_index": tile_index,
			"tile_name": tile_data.display_name,
			"reason": "insufficient_funds",
		}, player_id, true)

	player.add_money(-tile_data.price)
	state.set_property_owner(tile_index, player_id)
	return _with_event(GameEventScript.PROPERTY_PURCHASED, {
		"player_id": player_id,
		"tile_index": tile_index,
		"tile_name": tile_data.display_name,
		"price": tile_data.price,
		"money": player.money,
	}, player_id, true)


func skip_pending_property(state: GameState, board_data: BoardData) -> Dictionary:
	if state == null or board_data == null or not state.has_pending_property_purchase():
		return _not_handled()

	var player_id: int = int(state.pending_property_purchase["player_id"])
	var tile_index: int = int(state.pending_property_purchase["tile_index"])
	var tile_data: BoardTileData = board_data.get_tile(tile_index)
	state.clear_pending_property_purchase()
	return _with_event(GameEventScript.PROPERTY_PURCHASE_SKIPPED, {
		"player_id": player_id,
		"tile_index": tile_index,
		"tile_name": _get_tile_name(tile_data),
		"reason": "skipped",
	}, player_id, true)


func apply_rent_if_owed(state: GameState, payer: PlayerState, tile_data: BoardTileData) -> Dictionary:
	if state == null or payer == null or tile_data == null or not tile_data.is_property():
		return _not_handled()

	var owner_id: int = state.get_property_owner(tile_data.index)
	if owner_id == -1 or owner_id == payer.player_id:
		return _not_handled()

	var property_owner: PlayerState = state.get_player(owner_id)
	var rent_amount: int = tile_data.get_base_rent()
	if property_owner == null or rent_amount <= 0:
		return _not_handled()

	payer.add_money(-rent_amount)
	property_owner.add_money(rent_amount)
	return _with_event(GameEventScript.RENT_PAID, {
		"payer_id": payer.player_id,
		"owner_id": owner_id,
		"tile_index": tile_data.index,
		"tile_name": tile_data.display_name,
		"amount": rent_amount,
		"payer_money": payer.money,
		"owner_money": property_owner.money,
	}, payer.player_id, false)


func _with_event(event_type: String, event_payload: Dictionary, player_id: int, completes_turn: bool) -> Dictionary:
	return {
		RESULT_HANDLED: true,
		RESULT_COMPLETES_TURN: completes_turn,
		RESULT_PLAYER_ID: player_id,
		RESULT_EVENT_TYPE: event_type,
		RESULT_EVENT_PAYLOAD: event_payload.duplicate(true),
	}


func _completed_without_event(player_id: int) -> Dictionary:
	return {
		RESULT_HANDLED: true,
		RESULT_COMPLETES_TURN: true,
		RESULT_PLAYER_ID: player_id,
		RESULT_EVENT_TYPE: "",
		RESULT_EVENT_PAYLOAD: {},
	}


func _not_handled() -> Dictionary:
	return {
		RESULT_HANDLED: false,
		RESULT_COMPLETES_TURN: false,
		RESULT_PLAYER_ID: -1,
		RESULT_EVENT_TYPE: "",
		RESULT_EVENT_PAYLOAD: {},
	}


func _get_tile_name(tile_data: BoardTileData) -> String:
	if tile_data == null:
		return "Unknown"

	return tile_data.display_name
