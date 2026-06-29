extends RefCounted
class_name LandingResolutionService


const RESULT_EVENTS := "events"
const RESULT_WARNINGS := "warnings"
const RESULT_PAUSES_FOR_PROPERTY := "pauses_for_property"
const RESULT_COMPLETES_TURN := "completes_turn"
const RESULT_PLAYER_ID := "player_id"
const EVENT_TYPE := "event_type"
const EVENT_PAYLOAD := "event_payload"

const GameEventScript := preload("res://scripts/core/GameEvent.gd")
const PropertyResolutionServiceScript := preload("res://scripts/core/PropertyResolutionService.gd")
const EventServiceScript := preload("res://scripts/core/EventService.gd")


func resolve_grid_landing(
	state: GameState,
	board_data: BoardData,
	player: PlayerState,
	player_map_state: PlayerMapState,
	dice_value: int,
	property_service: Variant,
	effect_service: Variant,
	event_service: Variant
) -> Dictionary:
	if state == null or board_data == null or player == null or player_map_state == null:
		return _no_turn_completion(-1)

	var map_grid: BoardMapGridData = board_data.get_map_grid()
	var node_id: int = map_grid.get_node_id(player_map_state.grid_position) if map_grid != null else -1
	var tile_index: int = board_data.get_tile_index_for_source_node_id(node_id)
	var tile_data: BoardTileData = board_data.get_tile(tile_index) if tile_index >= 0 else null
	if tile_data != null:
		player.move_to_tile(tile_index)

	var result := _new_result(player.player_id)
	_append_event(result, GameEventScript.MAP_PLAYER_LANDED, {
		"player_id": player.player_id,
		"grid_position": player_map_state.grid_position,
		"node_id": node_id,
		"tile_index": tile_index,
		"tile_name": _get_tile_name(tile_data, "Road"),
		"dice_value": dice_value,
	})
	_resolve_landing_rules(result, state, player, tile_data, property_service, effect_service, event_service)
	return result


func resolve_board_landing(
	state: GameState,
	board_data: BoardData,
	player: PlayerState,
	dice_value: int,
	property_service: Variant,
	effect_service: Variant,
	event_service: Variant
) -> Dictionary:
	if state == null or board_data == null or player == null:
		return _no_turn_completion(-1)

	var tile_data: BoardTileData = board_data.get_tile(player.tile_index)
	var result := _new_result(player.player_id)
	_append_event(result, GameEventScript.PLAYER_LANDED, {
		"player_id": player.player_id,
		"tile_index": player.tile_index,
		"tile_name": _get_tile_name(tile_data, "Unknown"),
		"dice_value": dice_value,
	})
	_resolve_landing_rules(result, state, player, tile_data, property_service, effect_service, event_service)
	return result


func resolve_tile_effect(player: PlayerState, tile_data: BoardTileData, effect_service: Variant, event_service: Variant) -> Dictionary:
	var result := _new_result(player.player_id if player != null else -1)
	_append_tile_effect_events(result, player, tile_data, effect_service, event_service)
	result[RESULT_COMPLETES_TURN] = false
	return result


func _resolve_landing_rules(
	result: Dictionary,
	state: GameState,
	player: PlayerState,
	tile_data: BoardTileData,
	property_service: Variant,
	effect_service: Variant,
	event_service: Variant
) -> void:
	var offer_result: Dictionary = property_service.create_purchase_offer(state, player.player_id, tile_data)
	if bool(offer_result.get(PropertyResolutionServiceScript.RESULT_HANDLED, false)):
		_append_property_event(result, offer_result)
		result[RESULT_PAUSES_FOR_PROPERTY] = true
		result[RESULT_COMPLETES_TURN] = false
		return

	var rent_result: Dictionary = property_service.apply_rent_if_owed(state, player, tile_data)
	_append_property_event(result, rent_result)
	_append_tile_effect_events(result, player, tile_data, effect_service, event_service)


func _append_tile_effect_events(result: Dictionary, player: PlayerState, tile_data: BoardTileData, effect_service: Variant, event_service: Variant) -> void:
	var effect_result: Variant = null
	var event_definition: Variant = event_service.create_event_for_tile(tile_data) if event_service != null else null
	if event_definition != null:
		effect_result = event_service.apply_event(event_definition, {
			EventServiceScript.CONTEXT_PLAYER: player,
		})
	elif effect_service != null:
		effect_result = effect_service.apply_tile_effect(player, tile_data)

	if effect_result == null:
		return

	if effect_result.is_rejected():
		result[RESULT_WARNINGS].append("Tile effect %s was rejected: %s" % [str(effect_result.effect_id), effect_result.rejection_reason])
		return

	if player == null or tile_data == null or not effect_result.was_applied:
		return

	_append_event(result, GameEventScript.TILE_EFFECT_RESOLVED, {
		"player_id": player.player_id,
		"tile_index": tile_data.index,
		"tile_name": tile_data.display_name,
		"effect_id": effect_result.effect_id,
		"source_type": effect_result.source_type,
		"source_id": effect_result.source_id,
		"money_delta": effect_result.money_delta,
		"money_after": effect_result.money_after,
	})


func _append_property_event(result: Dictionary, property_result: Dictionary) -> void:
	var event_type: String = str(property_result.get(PropertyResolutionServiceScript.RESULT_EVENT_TYPE, ""))
	if event_type.is_empty():
		return

	var event_payload: Dictionary = property_result.get(PropertyResolutionServiceScript.RESULT_EVENT_PAYLOAD, {})
	_append_event(result, event_type, event_payload)


func _append_event(result: Dictionary, event_type: String, event_payload: Dictionary) -> void:
	result[RESULT_EVENTS].append({
		EVENT_TYPE: event_type,
		EVENT_PAYLOAD: event_payload.duplicate(true),
	})


func _new_result(player_id: int) -> Dictionary:
	return {
		RESULT_EVENTS: [],
		RESULT_WARNINGS: [],
		RESULT_PAUSES_FOR_PROPERTY: false,
		RESULT_COMPLETES_TURN: true,
		RESULT_PLAYER_ID: player_id,
	}


func _no_turn_completion(player_id: int) -> Dictionary:
	var result := _new_result(player_id)
	result[RESULT_COMPLETES_TURN] = false
	return result


func _get_tile_name(tile_data: BoardTileData, fallback: String) -> String:
	if tile_data == null:
		return fallback

	return tile_data.display_name
