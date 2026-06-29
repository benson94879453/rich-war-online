extends SceneTree


const PropertyResolutionServiceScript := preload("res://scripts/core/PropertyResolutionService.gd")
const GameEventScript := preload("res://scripts/core/GameEvent.gd")


var _failure_count: int = 0
var _service: PropertyResolutionService = PropertyResolutionServiceScript.new()


func _init() -> void:
	_run_smoke_check()
	if _failure_count == 0:
		print("PASS: Property resolution service smoke check")
		quit(0)
	else:
		push_error("FAIL: Property resolution service smoke check had %d failure(s)" % _failure_count)
		quit(1)


func _run_smoke_check() -> void:
	_verify_purchase_offer_and_buy()
	_verify_skip()
	_verify_insufficient_funds()
	_verify_rent()


func _verify_purchase_offer_and_buy() -> void:
	var state := _create_state(1000, 1000)
	var board_data := _create_board_data("Alpha", 300, 45)
	var tile: BoardTileData = board_data.get_tile(0)

	var offer: Dictionary = _service.create_purchase_offer(state, 0, tile)
	_expect_true(bool(offer.get(PropertyResolutionServiceScript.RESULT_HANDLED, false)), "unowned property creates purchase offer")
	_expect_equal(offer.get(PropertyResolutionServiceScript.RESULT_EVENT_TYPE, ""), GameEventScript.PROPERTY_PURCHASE_OFFERED, "purchase offer event type")
	_expect_equal(offer.get(PropertyResolutionServiceScript.RESULT_EVENT_PAYLOAD, {}), {
		"player_id": 0,
		"tile_index": 0,
		"tile_name": "Alpha",
		"price": 300,
	}, "purchase offer payload")
	_expect_true(state.has_pending_property_purchase(), "purchase offer records pending property decision")

	var buy_result: Dictionary = _service.buy_pending_property(state, board_data)
	_expect_equal(buy_result.get(PropertyResolutionServiceScript.RESULT_EVENT_TYPE, ""), GameEventScript.PROPERTY_PURCHASED, "buy event type")
	_expect_equal(buy_result.get(PropertyResolutionServiceScript.RESULT_EVENT_PAYLOAD, {}), {
		"player_id": 0,
		"tile_index": 0,
		"tile_name": "Alpha",
		"price": 300,
		"money": 700,
	}, "buy payload")
	_expect_equal(state.get_player(0).money, 700, "buy deducts property price")
	_expect_equal(state.get_property_owner(0), 0, "buy assigns property owner")
	_expect_true(not state.has_pending_property_purchase(), "buy clears pending property decision")


func _verify_skip() -> void:
	var state := _create_state(1000, 1000)
	var board_data := _create_board_data("Beta", 200, 30)
	state.begin_property_purchase(1, 0)

	var skip_result: Dictionary = _service.skip_pending_property(state, board_data)
	_expect_equal(skip_result.get(PropertyResolutionServiceScript.RESULT_EVENT_TYPE, ""), GameEventScript.PROPERTY_PURCHASE_SKIPPED, "skip event type")
	_expect_equal(skip_result.get(PropertyResolutionServiceScript.RESULT_EVENT_PAYLOAD, {}), {
		"player_id": 1,
		"tile_index": 0,
		"tile_name": "Beta",
		"reason": "skipped",
	}, "skip payload")
	_expect_equal(state.get_property_owner(0), -1, "skip does not assign property owner")
	_expect_true(not state.has_pending_property_purchase(), "skip clears pending property decision")


func _verify_insufficient_funds() -> void:
	var state := _create_state(50, 1000)
	var board_data := _create_board_data("Gamma", 200, 30)
	state.begin_property_purchase(0, 0)

	var result: Dictionary = _service.buy_pending_property(state, board_data)
	_expect_equal(result.get(PropertyResolutionServiceScript.RESULT_EVENT_TYPE, ""), GameEventScript.PROPERTY_PURCHASE_SKIPPED, "insufficient funds event type")
	_expect_equal(result.get(PropertyResolutionServiceScript.RESULT_EVENT_PAYLOAD, {}), {
		"player_id": 0,
		"tile_index": 0,
		"tile_name": "Gamma",
		"reason": "insufficient_funds",
	}, "insufficient funds payload")
	_expect_equal(state.get_player(0).money, 50, "insufficient funds keeps player money")
	_expect_equal(state.get_property_owner(0), -1, "insufficient funds does not assign owner")
	_expect_true(not state.has_pending_property_purchase(), "insufficient funds clears pending property decision")


func _verify_rent() -> void:
	var state := _create_state(500, 800)
	var board_data := _create_board_data("Delta", 300, 45)
	var tile: BoardTileData = board_data.get_tile(0)
	state.set_property_owner(0, 1)

	var result: Dictionary = _service.apply_rent_if_owed(state, state.get_player(0), tile)
	_expect_equal(result.get(PropertyResolutionServiceScript.RESULT_EVENT_TYPE, ""), GameEventScript.RENT_PAID, "rent event type")
	_expect_equal(result.get(PropertyResolutionServiceScript.RESULT_EVENT_PAYLOAD, {}), {
		"payer_id": 0,
		"owner_id": 1,
		"tile_index": 0,
		"tile_name": "Delta",
		"amount": 45,
		"payer_money": 455,
		"owner_money": 845,
	}, "rent payload")
	_expect_equal(state.get_player(0).money, 455, "rent deducts payer money")
	_expect_equal(state.get_player(1).money, 845, "rent adds owner money")

	var owner_result: Dictionary = _service.apply_rent_if_owed(state, state.get_player(1), tile)
	_expect_true(not bool(owner_result.get(PropertyResolutionServiceScript.RESULT_HANDLED, false)), "owner landing does not pay rent")


func _create_state(player_1_money: int, player_2_money: int) -> GameState:
	var state := GameState.new()
	state.initialize([
		PlayerState.new(0, "Player 1", player_1_money, 0, -1),
		PlayerState.new(1, "Player 2", player_2_money, 0, -1),
	])
	return state


func _create_board_data(tile_name: String, price: int, base_rent: int) -> BoardData:
	var board_data := BoardData.new()
	var tile := BoardTileData.new()
	tile.index = 0
	tile.display_name = tile_name
	tile.tile_type = BoardTileData.TileType.PROPERTY
	tile.price = price
	tile.base_rent = base_rent
	board_data.tiles = [tile]
	return board_data


func _expect_true(value: bool, label: String) -> void:
	if value:
		return

	_failure_count += 1
	push_error("Expected true: %s" % label)


func _expect_equal(actual: Variant, expected: Variant, label: String) -> void:
	if actual == expected:
		return

	_failure_count += 1
	push_error("%s: expected %s, got %s" % [label, str(expected), str(actual)])
