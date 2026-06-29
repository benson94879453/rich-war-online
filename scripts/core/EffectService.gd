extends RefCounted
class_name EffectService


const EFFECT_MONEY_DELTA := &"money_delta"
const SOURCE_TILE := &"tile"

const CONTEXT_PLAYER := "player"
const CONTEXT_TILE_DATA := "tile_data"
const CONTEXT_SOURCE_TYPE := "source_type"
const CONTEXT_SOURCE_ID := "source_id"
const EffectResultScript := preload("res://scripts/core/EffectResult.gd")


func apply_tile_effect(player: PlayerState, tile_data: BoardTileData) -> Variant:
	var result: Variant = EffectResultScript.new()
	if tile_data != null:
		result.configure(tile_data.effect_id, SOURCE_TILE, tile_data.effect_id)

	if player == null or tile_data == null:
		return result

	if not tile_data.has_money_effect():
		return result

	result = apply_effect(EFFECT_MONEY_DELTA, {
		CONTEXT_PLAYER: player,
		CONTEXT_TILE_DATA: tile_data,
		CONTEXT_SOURCE_TYPE: SOURCE_TILE,
		CONTEXT_SOURCE_ID: tile_data.effect_id,
	})
	result.effect_id = tile_data.effect_id
	return result


func apply_effect(effect_id: StringName, context: Dictionary = {}) -> Variant:
	var result: Variant = EffectResultScript.new()
	result.configure(
		effect_id,
		_get_string_name(context.get(CONTEXT_SOURCE_TYPE, &"")),
		_get_string_name(context.get(CONTEXT_SOURCE_ID, effect_id))
	)

	match effect_id:
		EFFECT_MONEY_DELTA:
			_apply_money_delta(result, context)
		_:
			result.reject("unsupported effect")

	return result


func _apply_money_delta(result: Variant, context: Dictionary) -> void:
	var player: PlayerState = context.get(CONTEXT_PLAYER, null) as PlayerState
	var tile_data: BoardTileData = context.get(CONTEXT_TILE_DATA, null) as BoardTileData
	if player == null or tile_data == null:
		result.reject("missing money effect context")
		return

	if not tile_data.has_money_effect():
		return

	player.add_money(tile_data.money_delta)
	result.apply_money_change(tile_data.money_delta, player.money)


func _get_string_name(value: Variant) -> StringName:
	if value is StringName:
		return value

	return StringName(str(value))
