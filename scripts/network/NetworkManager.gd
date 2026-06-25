extends Node


signal connection_status_changed(message: String)
signal intent_accepted(intent_type: String, request_id: int)
signal intent_rejected(intent_type: String, reason: String, request_id: int)
signal local_player_changed(player_id: int)
signal state_snapshot_received(snapshot: Dictionary)


const DEFAULT_PORT := 8910
const DEFAULT_URL := "ws://127.0.0.1:%d" % DEFAULT_PORT

const INTENT_ROLL := "roll"
const INTENT_GRID_ROUTE_CHOICE := "grid_route_choice"
const INTENT_BUY_PROPERTY := "buy_property"
const INTENT_SKIP_PROPERTY := "skip_property"
const SNAPSHOT_REVISION_KEY := "_network_state_revision"

enum NetworkMode {
	OFFLINE,
	HOST,
	CLIENT,
}


var mode: int = NetworkMode.OFFLINE
var local_player_id: int = -1
var host_can_control_open_seats: bool = true
var _player_id_by_peer_id: Dictionary = {}
var _peer_id_by_player_id: Dictionary = {}
var _next_request_id: int = 1
var _state_revision: int = 0
var _last_received_state_revision: int = -1
var _status_message: String = "Offline"


func _ready() -> void:
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)
	EventBus.game_event_emitted.connect(_on_game_event)
	_emit_status(_status_message)


func start_host(port: int = DEFAULT_PORT) -> bool:
	stop_network()
	var peer := WebSocketMultiplayerPeer.new()
	var error := peer.create_server(port)
	if error != OK:
		_emit_status("Host failed: %s" % error_string(error))
		return false

	multiplayer.multiplayer_peer = peer
	mode = NetworkMode.HOST
	_next_request_id = 1
	_state_revision = 0
	_last_received_state_revision = -1
	_assign_peer_to_player(multiplayer.get_unique_id(), 0)
	_emit_status("Hosting on ws://127.0.0.1:%d" % port)
	return true


func join_host(url: String = DEFAULT_URL) -> bool:
	stop_network()
	var resolved_url := url.strip_edges()
	if resolved_url.is_empty():
		resolved_url = DEFAULT_URL

	var peer := WebSocketMultiplayerPeer.new()
	var error := peer.create_client(resolved_url)
	if error != OK:
		_emit_status("Join failed: %s" % error_string(error))
		return false

	multiplayer.multiplayer_peer = peer
	mode = NetworkMode.CLIENT
	local_player_id = -1
	_next_request_id = 1
	_last_received_state_revision = -1
	local_player_changed.emit(local_player_id)
	_emit_status("Connecting to %s" % resolved_url)
	return true


func stop_network() -> void:
	if multiplayer.multiplayer_peer != null:
		multiplayer.multiplayer_peer.close()
	multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()
	mode = NetworkMode.OFFLINE
	local_player_id = -1
	_next_request_id = 1
	_state_revision = 0
	_last_received_state_revision = -1
	_player_id_by_peer_id.clear()
	_peer_id_by_player_id.clear()
	local_player_changed.emit(local_player_id)
	_emit_status("Offline")


func submit_roll() -> bool:
	return submit_intent(INTENT_ROLL)


func submit_grid_route_choice(direction: int) -> bool:
	return submit_intent(INTENT_GRID_ROUTE_CHOICE, {"direction": direction})


func submit_buy_property() -> bool:
	return submit_intent(INTENT_BUY_PROPERTY)


func submit_skip_property() -> bool:
	return submit_intent(INTENT_SKIP_PROPERTY)


func submit_intent(intent_type: String, payload: Dictionary = {}) -> bool:
	var request_id := _take_next_request_id()
	if mode == NetworkMode.OFFLINE:
		return _execute_intent(1, request_id, intent_type, payload)

	if mode == NetworkMode.HOST:
		return _execute_intent(multiplayer.get_unique_id(), request_id, intent_type, payload)

	if mode == NetworkMode.CLIENT:
		if multiplayer.multiplayer_peer == null:
			_emit_status("Not connected")
			return false
		_submit_intent.rpc_id(1, request_id, intent_type, payload)
		return true

	return false


func is_network_active() -> bool:
	return mode != NetworkMode.OFFLINE


func is_host() -> bool:
	return mode == NetworkMode.HOST


func is_client() -> bool:
	return mode == NetworkMode.CLIENT


func set_host_can_control_open_seats(value: bool) -> void:
	host_can_control_open_seats = value
	if mode == NetworkMode.HOST:
		var state_text := "off"
		if value:
			state_text = "on"
		_emit_status("Host open seat control: %s" % state_text)


func can_control_player(player_id: int) -> bool:
	if mode == NetworkMode.OFFLINE:
		return true

	if mode == NetworkMode.CLIENT:
		return player_id == local_player_id

	if mode == NetworkMode.HOST:
		return player_id == local_player_id or (host_can_control_open_seats and not _peer_id_by_player_id.has(player_id))

	return false


func get_status_message() -> String:
	return _status_message


func get_snapshot_revision(snapshot: Dictionary) -> int:
	return int(snapshot.get(SNAPSHOT_REVISION_KEY, -1))


@rpc("any_peer", "call_remote", "reliable")
func _submit_intent(request_id: int, intent_type: String, payload: Dictionary = {}) -> void:
	if not is_host():
		return

	var sender_peer_id := multiplayer.get_remote_sender_id()
	_execute_intent(sender_peer_id, request_id, intent_type, payload)


@rpc("any_peer", "call_remote", "reliable")
func _request_state_snapshot() -> void:
	if not is_host():
		return

	_send_state_snapshot(multiplayer.get_remote_sender_id())


@rpc("authority", "call_remote", "reliable")
func _assign_local_player(player_id: int) -> void:
	local_player_id = player_id
	local_player_changed.emit(local_player_id)
	var status := "Connected as spectator"
	if local_player_id >= 0:
		status = "Connected as P%d" % [local_player_id + 1]
	_emit_status(status)


@rpc("authority", "call_remote", "reliable")
func _receive_game_event(event_data: Dictionary) -> void:
	EventBus.emit_game_event(GameEvent.from_dict(event_data))


@rpc("authority", "call_remote", "reliable")
func _receive_intent_accepted(intent_type: String, request_id: int) -> void:
	intent_accepted.emit(intent_type, request_id)


@rpc("authority", "call_remote", "reliable")
func _receive_state_snapshot(snapshot: Dictionary) -> void:
	var revision := get_snapshot_revision(snapshot)
	if revision >= 0 and revision <= _last_received_state_revision:
		return

	if revision >= 0:
		_last_received_state_revision = revision
	state_snapshot_received.emit(snapshot)


@rpc("authority", "call_remote", "reliable")
func _receive_intent_rejected_with_request(intent_type: String, reason: String, request_id: int) -> void:
	intent_rejected.emit(intent_type, reason, request_id)
	_emit_status("Rejected %s: %s" % [intent_type, reason])


func _execute_intent(sender_peer_id: int, request_id: int, intent_type: String, payload: Dictionary = {}) -> bool:
	var rejection_reason := _get_intent_rejection_reason(sender_peer_id, intent_type)
	if not rejection_reason.is_empty():
		_reject_intent(sender_peer_id, intent_type, rejection_reason, request_id)
		return false

	var accepted := false
	match intent_type:
		INTENT_ROLL:
			accepted = GameManager.request_roll()
		INTENT_GRID_ROUTE_CHOICE:
			accepted = GameManager.request_grid_route_choice(int(payload.get("direction", BoardConnectionData.Direction.NONE)))
		INTENT_BUY_PROPERTY:
			accepted = GameManager.request_buy_pending_property()
		INTENT_SKIP_PROPERTY:
			accepted = GameManager.request_skip_pending_property()
		_:
			accepted = false

	if not accepted:
		_reject_intent(sender_peer_id, intent_type, "game rejected intent", request_id)
		return false

	_accept_intent(sender_peer_id, intent_type, request_id)
	if accepted and is_host():
		_state_revision += 1
		_broadcast_state_snapshot()

	return accepted


func _get_intent_rejection_reason(sender_peer_id: int, intent_type: String) -> String:
	if GameManager.state == null:
		return "game not ready"

	if mode == NetworkMode.OFFLINE:
		return ""

	if not _is_known_intent(intent_type):
		return "unknown intent"

	match intent_type:
		INTENT_ROLL:
			var current_player_id := GameManager.state.get_current_player_id()
			if not _can_peer_control_player(sender_peer_id, current_player_id):
				return "not your turn"
			if not GameManager.turn_system.can_roll():
				return "roll is not available"
			if GameManager.state.has_pending_movement() or GameManager.state.has_pending_grid_movement():
				return "movement is pending"
		INTENT_GRID_ROUTE_CHOICE:
			var route_player_id := GameManager.state.get_current_player_id()
			if not _can_peer_control_player(sender_peer_id, route_player_id):
				return "not your route choice"
			if not GameManager.turn_system.can_resolve_route_choice():
				return "route choice is not available"
			if not GameManager.state.has_pending_grid_movement():
				return "no grid movement pending"
		INTENT_BUY_PROPERTY, INTENT_SKIP_PROPERTY:
			if not GameManager.state.has_pending_property_purchase():
				return "no property decision pending"
			var property_player_id := int(GameManager.state.pending_property_purchase.get("player_id", -1))
			if not _can_peer_control_player(sender_peer_id, property_player_id):
				return "not your property decision"
			if not GameManager.turn_system.can_resolve_property_decision():
				return "property decision is not available"

	return ""


func _on_peer_connected(peer_id: int) -> void:
	if not is_host():
		return

	var player_id := _get_next_available_player_id()
	if player_id >= 0:
		_assign_peer_to_player(peer_id, player_id)

	_assign_local_player.rpc_id(peer_id, player_id)
	_send_state_snapshot(peer_id)
	if player_id >= 0:
		_emit_status("Peer %d joined as P%d" % [peer_id, player_id + 1])
	else:
		_emit_status("Peer %d joined as spectator" % [peer_id])


func _on_peer_disconnected(peer_id: int) -> void:
	if _player_id_by_peer_id.has(peer_id):
		var player_id := int(_player_id_by_peer_id[peer_id])
		_player_id_by_peer_id.erase(peer_id)
		_peer_id_by_player_id.erase(player_id)
		if is_host():
			_emit_status("Peer %d disconnected from P%d" % [peer_id, player_id + 1])


func _on_connected_to_server() -> void:
	_emit_status("Connected, waiting for seat")
	_request_state_snapshot.rpc_id(1)


func _on_connection_failed() -> void:
	stop_network()
	_emit_status("Connection failed")


func _on_server_disconnected() -> void:
	stop_network()
	_emit_status("Server disconnected")


func _on_game_event(event: GameEvent) -> void:
	if is_host():
		_receive_game_event.rpc(event.to_dict())


func _can_peer_control_player(peer_id: int, player_id: int) -> bool:
	if player_id < 0:
		return false

	if mode == NetworkMode.OFFLINE:
		return true

	if peer_id == multiplayer.get_unique_id():
		if player_id == local_player_id:
			return true
		return mode == NetworkMode.HOST and host_can_control_open_seats and not _peer_id_by_player_id.has(player_id)

	return int(_player_id_by_peer_id.get(peer_id, -1)) == player_id


func _is_known_intent(intent_type: String) -> bool:
	match intent_type:
		INTENT_ROLL, INTENT_GRID_ROUTE_CHOICE, INTENT_BUY_PROPERTY, INTENT_SKIP_PROPERTY:
			return true

	return false


func _accept_intent(peer_id: int, intent_type: String, request_id: int) -> void:
	if mode == NetworkMode.HOST and peer_id != multiplayer.get_unique_id():
		_receive_intent_accepted.rpc_id(peer_id, intent_type, request_id)
	else:
		intent_accepted.emit(intent_type, request_id)


func _reject_intent(peer_id: int, intent_type: String, reason: String, request_id: int) -> void:
	if mode == NetworkMode.HOST and peer_id != multiplayer.get_unique_id():
		_receive_intent_rejected_with_request.rpc_id(peer_id, intent_type, reason, request_id)
	else:
		intent_rejected.emit(intent_type, reason, request_id)

	if mode == NetworkMode.HOST:
		_emit_status("Rejected %s from peer %d: %s" % [intent_type, peer_id, reason])


func _take_next_request_id() -> int:
	var request_id := _next_request_id
	_next_request_id += 1
	return request_id


func _assign_peer_to_player(peer_id: int, player_id: int) -> void:
	_player_id_by_peer_id[peer_id] = player_id
	_peer_id_by_player_id[player_id] = peer_id
	if peer_id == multiplayer.get_unique_id():
		local_player_id = player_id
		local_player_changed.emit(local_player_id)


func _get_next_available_player_id() -> int:
	if GameManager.state != null:
		for player_id in GameManager.state.player_order:
			if not _peer_id_by_player_id.has(player_id):
				return int(player_id)

	for player_id in range(4):
		if not _peer_id_by_player_id.has(player_id):
			return player_id

	return -1


func _send_state_snapshot(peer_id: int) -> void:
	if GameManager.state == null:
		return

	_receive_state_snapshot.rpc_id(peer_id, _create_state_snapshot())


func _broadcast_state_snapshot() -> void:
	if GameManager.state == null:
		return

	_receive_state_snapshot.rpc(_create_state_snapshot())


func _create_state_snapshot() -> Dictionary:
	var snapshot := GameManager.get_state_snapshot()
	snapshot[SNAPSHOT_REVISION_KEY] = _state_revision
	return snapshot


func _emit_status(message: String) -> void:
	_status_message = message
	connection_status_changed.emit(message)
