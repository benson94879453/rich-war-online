extends Resource
class_name BoardTileData


enum TileType {
	START,
	PROPERTY,
	STOCK_MARKET,
	DRAW_CARD,
	CHANCE,
	FATE,
	BLESSING,
	CURSE,
	SPECIAL,
	SAFE,
}


const DEFAULT_PROPERTY_RENT_RATE := 0.15


@export var index: int = 0
@export var source_node_id: int = -1
@export_enum("Start", "Property", "Stock Market", "Draw Card", "Chance", "Fate", "Blessing", "Curse", "Special", "Safe") var tile_type: int = TileType.SAFE
@export var display_name: String = ""
@export_multiline var description: String = ""
@export var color: Color = Color.WHITE

@export_group("Economy")
@export var price: int = 0
@export var base_rent: int = 0
@export var salary: int = 0
@export var money_delta: int = 0

@export_group("Deck")
@export var deck_id: StringName = &""

@export_group("Effect")
@export var effect_id: StringName = &""


func is_property() -> bool:
	return tile_type == TileType.PROPERTY


func get_base_rent() -> int:
	if base_rent > 0:
		return base_rent

	if not is_property() or price <= 0:
		return 0

	return ceili(float(price) * DEFAULT_PROPERTY_RENT_RATE)


func has_money_effect() -> bool:
	return money_delta != 0
