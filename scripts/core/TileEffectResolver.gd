extends RefCounted
class_name TileEffectResolver


var _effect_service: EffectService = EffectService.new()


func resolve(player: PlayerState, tile_data: BoardTileData) -> TileEffectResolution:
	var resolution := TileEffectResolution.new()
	var result: EffectResult = _effect_service.apply_tile_effect(player, tile_data)
	if not result.was_applied:
		return resolution

	resolution.apply_money_change(result.money_delta, result.money_after)
	return resolution
