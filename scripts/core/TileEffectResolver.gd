extends RefCounted
class_name TileEffectResolver


func resolve(player: PlayerState, tile_data: BoardTileData) -> TileEffectResolution:
	var resolution := TileEffectResolution.new()
	if player == null or tile_data == null or not tile_data.has_money_effect():
		return resolution

	player.add_money(tile_data.money_delta)
	resolution.apply_money_change(tile_data.money_delta, player.money)
	return resolution
