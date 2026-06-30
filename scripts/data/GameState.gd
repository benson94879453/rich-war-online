extends RefCounted
class_name GameState


var players_by_id: Dictionary = {}
var player_order: Array[int] = []
var current_player_order_index: int = 0
var current_round: int = 1
var property_owner_by_tile: Dictionary = {}
var pending_property_purchase: Dictionary = {}
var pending_movement: MovementState
var player_map_states_by_id: Dictionary = {}
var pending_grid_movement: GridMovementState
var hands_by_player_id: Dictionary = {}
var deck_states: Dictionary = {}
var discard_piles: Dictionary = {}
var status_by_player_id: Dictionary = {}
var pending_intervention: Dictionary = {}
var game_over: bool = false
var winner_player_id: int = -1
var round_limit: int = 20


func initialize(players: Array[PlayerState]) -> void:
	players_by_id.clear()
	player_order.clear()
	property_owner_by_tile.clear()
	pending_property_purchase.clear()
	pending_movement = null
	player_map_states_by_id.clear()
	pending_grid_movement = null
	hands_by_player_id.clear()
	deck_states.clear()
	discard_piles.clear()
	status_by_player_id.clear()
	pending_intervention.clear()
	game_over = false
	winner_player_id = -1
	round_limit = 20

	for player in players:
		players_by_id[player.player_id] = player
		player_order.append(player.player_id)

	player_order.sort()
	current_player_order_index = 0
	current_round = 1


func get_player(player_id: int) -> PlayerState:
	if not players_by_id.has(player_id):
		return null

	return players_by_id[player_id] as PlayerState


func get_current_player_id() -> int:
	if player_order.is_empty():
		return -1

	return player_order[current_player_order_index]


func get_current_player() -> PlayerState:
	return get_player(get_current_player_id())


func advance_turn() -> bool:
	if player_order.is_empty():
		return false

	current_player_order_index = posmod(current_player_order_index + 1, player_order.size())
	if current_player_order_index != 0:
		return false

	current_round += 1
	return true


func begin_property_purchase(player_id: int, tile_index: int) -> void:
	pending_property_purchase = {
		"player_id": player_id,
		"tile_index": tile_index,
	}


func clear_pending_property_purchase() -> void:
	pending_property_purchase.clear()


func has_pending_property_purchase() -> bool:
	return not pending_property_purchase.is_empty()


func begin_movement(movement_state: MovementState) -> void:
	pending_movement = movement_state


func clear_pending_movement() -> void:
	pending_movement = null


func has_pending_movement() -> bool:
	return pending_movement != null


func initialize_player_map_states(data: BoardData) -> void:
	player_map_states_by_id.clear()
	if data == null:
		return

	for player_id in player_order:
		var map_state: PlayerMapState = data.get_player_map_spawn(player_id)
		if map_state != null and map_state.is_valid():
			player_map_states_by_id[player_id] = map_state


func get_player_map_state(player_id: int) -> PlayerMapState:
	if not player_map_states_by_id.has(player_id):
		return null

	return player_map_states_by_id[player_id] as PlayerMapState


func has_player_map_state(player_id: int) -> bool:
	return get_player_map_state(player_id) != null


func begin_grid_movement(movement_state: GridMovementState) -> void:
	pending_grid_movement = movement_state


func clear_pending_grid_movement() -> void:
	pending_grid_movement = null


func has_pending_grid_movement() -> bool:
	return pending_grid_movement != null


func get_property_owner(tile_index: int) -> int:
	if not property_owner_by_tile.has(tile_index):
		return -1

	return int(property_owner_by_tile[tile_index])


func set_property_owner(tile_index: int, player_id: int) -> void:
	property_owner_by_tile[tile_index] = player_id


func get_player_hand(player_id: int) -> Array:
	return _duplicate_array(hands_by_player_id.get(player_id, []))


func set_player_hand(player_id: int, card_ids: Array) -> void:
	hands_by_player_id[player_id] = _duplicate_array(card_ids)


func add_card_to_hand(player_id: int, card_id: StringName) -> void:
	var hand: Array = get_player_hand(player_id)
	hand.append(card_id)
	set_player_hand(player_id, hand)


func has_card_in_hand(player_id: int, card_id: StringName) -> bool:
	return get_player_hand(player_id).has(card_id)


func remove_card_from_hand(player_id: int, card_id: StringName) -> bool:
	var hand: Array = get_player_hand(player_id)
	var card_index: int = hand.find(card_id)
	if card_index < 0:
		return false

	hand.remove_at(card_index)
	set_player_hand(player_id, hand)
	return true


func get_deck_cards(deck_id: StringName) -> Array:
	var deck_state: Dictionary = deck_states.get(deck_id, {})
	return _duplicate_array(deck_state.get("cards", []))


func set_deck_cards(deck_id: StringName, card_ids: Array) -> void:
	var deck_state: Dictionary = deck_states.get(deck_id, {}).duplicate(true)
	deck_state["cards"] = _duplicate_array(card_ids)
	deck_states[deck_id] = deck_state


func get_discard_pile(pile_id: StringName) -> Array:
	return _duplicate_array(discard_piles.get(pile_id, []))


func set_discard_pile(pile_id: StringName, card_ids: Array) -> void:
	discard_piles[pile_id] = _duplicate_array(card_ids)


func add_card_to_discard(pile_id: StringName, card_id: StringName) -> void:
	var pile: Array = get_discard_pile(pile_id)
	pile.append(card_id)
	set_discard_pile(pile_id, pile)


func begin_pending_intervention(
		window_id: StringName,
		acting_player_id: int,
		eligible_player_ids: Array,
		target_player_id: int = -1,
		card_id: StringName = &""
) -> void:
	pending_intervention = {
		"window_id": window_id,
		"acting_player_id": acting_player_id,
		"eligible_players": _duplicate_array(eligible_player_ids),
	}
	if target_player_id >= 0:
		pending_intervention["target_player_id"] = target_player_id
	if card_id != &"":
		pending_intervention["card_id"] = card_id


func clear_pending_intervention() -> void:
	pending_intervention.clear()


func has_pending_intervention() -> bool:
	return not pending_intervention.is_empty()


func to_dict() -> Dictionary:
	var players: Array[Dictionary] = []
	var pending_movement_data: Dictionary = {}
	if pending_movement != null:
		pending_movement_data = pending_movement.to_dict()
	var pending_grid_movement_data: Dictionary = {}
	if pending_grid_movement != null:
		pending_grid_movement_data = pending_grid_movement.to_dict()
	var player_map_states: Dictionary = {}
	for player_id in player_order:
		var map_state: PlayerMapState = get_player_map_state(player_id)
		if map_state != null:
			player_map_states[player_id] = map_state.to_dict()
	for player_id in player_order:
		var player: PlayerState = get_player(player_id)
		if player != null:
			players.append(player.to_dict())

	return {
		"players": players,
		"player_order": player_order,
		"current_player_order_index": current_player_order_index,
		"current_round": current_round,
		"property_owner_by_tile": property_owner_by_tile,
		"pending_property_purchase": pending_property_purchase,
		"pending_movement": pending_movement_data,
		"player_map_states_by_id": player_map_states,
		"pending_grid_movement": pending_grid_movement_data,
		"hands_by_player_id": hands_by_player_id.duplicate(true),
		"deck_states": deck_states.duplicate(true),
		"discard_piles": discard_piles.duplicate(true),
		"status_by_player_id": status_by_player_id.duplicate(true),
		"pending_intervention": pending_intervention.duplicate(true),
		"game_over": game_over,
		"winner_player_id": winner_player_id,
		"round_limit": round_limit,
	}


static func from_dict(data: Dictionary) -> GameState:
	var state: GameState = GameState.new()
	var players: Array[PlayerState] = []
	var serialized_players: Array = data.get("players", [])
	for serialized_player in serialized_players:
		if serialized_player is Dictionary:
			players.append(PlayerState.from_dict(serialized_player))

	state.initialize(players)
	state.current_player_order_index = int(data.get("current_player_order_index", 0))
	state.current_round = int(data.get("current_round", 1))
	state.property_owner_by_tile = data.get("property_owner_by_tile", {})
	state.pending_property_purchase = data.get("pending_property_purchase", {})
	state.hands_by_player_id = _duplicate_dictionary(data.get("hands_by_player_id", {}))
	state.deck_states = _duplicate_dictionary(data.get("deck_states", {}))
	state.discard_piles = _duplicate_dictionary(data.get("discard_piles", {}))
	state.status_by_player_id = _duplicate_dictionary(data.get("status_by_player_id", {}))
	state.pending_intervention = _duplicate_dictionary(data.get("pending_intervention", {}))
	state.game_over = bool(data.get("game_over", false))
	state.winner_player_id = int(data.get("winner_player_id", -1))
	state.round_limit = int(data.get("round_limit", 20))
	var serialized_pending_movement: Dictionary = data.get("pending_movement", {})
	if not serialized_pending_movement.is_empty():
		state.pending_movement = MovementState.from_dict(serialized_pending_movement)
	var serialized_player_map_states: Dictionary = data.get("player_map_states_by_id", {})
	for player_id_value in serialized_player_map_states:
		var serialized_map_state_value: Variant = serialized_player_map_states[player_id_value]
		if serialized_map_state_value is Dictionary:
			var serialized_map_state: Dictionary = serialized_map_state_value
			state.player_map_states_by_id[int(player_id_value)] = PlayerMapState.from_dict(serialized_map_state)
	var serialized_pending_grid_movement: Dictionary = data.get("pending_grid_movement", {})
	if not serialized_pending_grid_movement.is_empty():
		state.pending_grid_movement = GridMovementState.from_dict(serialized_pending_grid_movement)
	return state


static func _duplicate_dictionary(value: Variant) -> Dictionary:
	if value is Dictionary:
		var dictionary: Dictionary = value
		return dictionary.duplicate(true)

	return {}


static func _duplicate_array(value: Variant) -> Array:
	if value is Array:
		var array: Array = value
		return array.duplicate(true)

	return []
