extends Node


signal connection_status_changed(message: String)
signal intent_accepted(intent_type: String, request_id: int)
signal intent_rejected(intent_type: String, reason: String, request_id: int)
signal local_player_changed(player_id: int)
signal state_snapshot_received(snapshot: Dictionary)


const DEFAULT_PORT := 8910
const DEFAULT_URL := "ws://127.0.0.1:%d" % DEFAULT_PORT

const ActionDispatcherScript := preload("res://scripts/core/ActionDispatcher.gd")
const GameEventScript := preload("res://scripts/core/GameEvent.gd")
const INTENT_ROLL := ActionDispatcherScript.ACTION_ROLL
const INTENT_GRID_ROUTE_CHOICE := ActionDispatcherScript.ACTION_GRID_ROUTE_CHOICE
const INTENT_BUY_PROPERTY := ActionDispatcherScript.ACTION_BUY_PROPERTY
const INTENT_SKIP_PROPERTY := ActionDispatcherScript.ACTION_SKIP_PROPERTY
const INTENT_PLAY_CARD := ActionDispatcherScript.ACTION_PLAY_CARD
const SNAPSHOT_REVISION_KEY := "_network_state_revision"
const ASSIGNMENT_STATUS_JOINED := "joined"
const ASSIGNMENT_STATUS_RECONNECTED := "reconnected"
const ASSIGNMENT_STATUS_SPECTATOR := "spectator"
const LOCAL_RECONNECT_TOKEN_PATH := "user://reconnect_token.txt"

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
var _reconnect_token_by_peer_id: Dictionary = {}
var _player_id_by_reconnect_token: Dictionary = {}
var _reconnect_token_by_player_id: Dictionary = {}
var _reserved_player_ids: Dictionary = {}
var _local_reconnect_token: String = ""
var _next_request_id: int = 1
var _state_revision: int = 0
var _last_received_state_revision: int = -1
var _local_assignment_status_message: String = ""
var _status_message: String = "Offline"
var _action_dispatcher := ActionDispatcherScript.new()


func _ready() -> void:
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)
	var event_bus: Variant = _get_event_bus()
	if event_bus != null:
		event_bus.game_event_emitted.connect(_on_game_event)
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
	_ensure_local_reconnect_token()
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
	_local_assignment_status_message = ""
	_player_id_by_peer_id.clear()
	_peer_id_by_player_id.clear()
	_reconnect_token_by_peer_id.clear()
	_player_id_by_reconnect_token.clear()
	_reconnect_token_by_player_id.clear()
	_reserved_player_ids.clear()
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


func submit_play_card(player_id: int, card_id: StringName, window_id: StringName, target_player_id: int = -1) -> bool:
	var payload := {
		ActionDispatcherScript.PAYLOAD_PLAYER_ID: player_id,
		ActionDispatcherScript.PAYLOAD_CARD_ID: card_id,
		ActionDispatcherScript.PAYLOAD_WINDOW_ID: window_id,
	}
	if target_player_id >= 0:
		payload[ActionDispatcherScript.PAYLOAD_TARGET_PLAYER_ID] = target_player_id

	return submit_intent(INTENT_PLAY_CARD, payload)


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


func get_local_reconnect_token() -> String:
	return _ensure_local_reconnect_token()


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
		return player_id == local_player_id or (host_can_control_open_seats and _is_player_seat_open(player_id))

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


@rpc("any_peer", "call_remote", "reliable")
func _register_reconnect_token(reconnect_token: String) -> void:
	if not is_host():
		return

	var sender_peer_id := multiplayer.get_remote_sender_id()
	var clean_token := reconnect_token.strip_edges()
	if clean_token.is_empty():
		_emit_status("Peer %d did not provide a reconnect token" % sender_peer_id)
		return

	_handle_peer_reconnect_token(sender_peer_id, clean_token)


@rpc("authority", "call_remote", "reliable")
func _assign_local_player(player_id: int, assignment_status: String = ASSIGNMENT_STATUS_JOINED) -> void:
	local_player_id = player_id
	local_player_changed.emit(local_player_id)
	_local_assignment_status_message = _get_local_assignment_status_message(local_player_id, assignment_status)
	_emit_status(_local_assignment_status_message)


@rpc("authority", "call_remote", "reliable")
func _receive_game_event(event_data: Dictionary) -> void:
	var event_bus: Variant = _get_event_bus()
	if event_bus != null:
		event_bus.emit_game_event(GameEventScript.from_dict(event_data))


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
	_emit_status(_get_snapshot_status_message(revision))
	state_snapshot_received.emit(snapshot)


@rpc("authority", "call_remote", "reliable")
func _receive_intent_rejected_with_request(intent_type: String, reason: String, request_id: int) -> void:
	intent_rejected.emit(intent_type, reason, request_id)
	_emit_status("Rejected %s: %s" % [intent_type, reason])


func _execute_intent(sender_peer_id: int, request_id: int, intent_type: String, payload: Dictionary = {}) -> bool:
	var dispatch_result := _action_dispatcher.submit_action(sender_peer_id, intent_type, payload, Callable(self, "_can_peer_control_player"))
	if not bool(dispatch_result.get(ActionDispatcherScript.RESULT_ACCEPTED, false)):
		var rejection_reason := str(dispatch_result.get(ActionDispatcherScript.RESULT_REJECTION_REASON, "game rejected intent"))
		_reject_intent(sender_peer_id, intent_type, rejection_reason, request_id)
		return false

	_accept_intent(sender_peer_id, intent_type, request_id)
	if is_host():
		_state_revision += 1
		_broadcast_state_snapshot()

	return true


func _on_peer_connected(peer_id: int) -> void:
	if not is_host():
		return

	var player_id := _get_next_available_player_id()
	if player_id >= 0:
		_assign_peer_to_player(peer_id, player_id)

	var assignment_status := ASSIGNMENT_STATUS_SPECTATOR if player_id < 0 else ASSIGNMENT_STATUS_JOINED
	_assign_local_player.rpc_id(peer_id, player_id, assignment_status)
	_send_state_snapshot(peer_id)
	if player_id >= 0:
		_emit_status("Peer %d joined as P%d" % [peer_id, player_id + 1])
	else:
		_emit_status("Peer %d joined as spectator" % [peer_id])


func _on_peer_disconnected(peer_id: int) -> void:
	var reconnect_token := str(_reconnect_token_by_peer_id.get(peer_id, ""))
	_reconnect_token_by_peer_id.erase(peer_id)
	if _player_id_by_peer_id.has(peer_id):
		var player_id := int(_player_id_by_peer_id[peer_id])
		_player_id_by_peer_id.erase(peer_id)
		_peer_id_by_player_id.erase(player_id)
		if not reconnect_token.is_empty():
			_reserve_player_seat(player_id, reconnect_token)
		if is_host():
			var reservation_text := " and reserved seat" if _is_player_seat_reserved(player_id) else ""
			_emit_status("Peer %d disconnected from P%d%s" % [peer_id, player_id + 1, reservation_text])


func _on_connected_to_server() -> void:
	_emit_status("Connected, waiting for seat")
	_register_reconnect_token.rpc_id(1, _ensure_local_reconnect_token())
	_request_state_snapshot.rpc_id(1)


func _on_connection_failed() -> void:
	stop_network()
	_emit_status("Connection failed")


func _on_server_disconnected() -> void:
	stop_network()
	_emit_status("Server disconnected")


func _on_game_event(event: Variant) -> void:
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
		return mode == NetworkMode.HOST and host_can_control_open_seats and _is_player_seat_open(player_id)

	return int(_player_id_by_peer_id.get(peer_id, -1)) == player_id


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
	_reserved_player_ids.erase(player_id)
	if _reconnect_token_by_peer_id.has(peer_id):
		_bind_reconnect_token_to_player(str(_reconnect_token_by_peer_id[peer_id]), player_id)
	if peer_id == multiplayer.get_unique_id():
		local_player_id = player_id
		local_player_changed.emit(local_player_id)


func _release_peer_assignment(peer_id: int) -> void:
	if not _player_id_by_peer_id.has(peer_id):
		return

	var player_id := int(_player_id_by_peer_id[peer_id])
	_player_id_by_peer_id.erase(peer_id)
	if int(_peer_id_by_player_id.get(player_id, -1)) == peer_id:
		_peer_id_by_player_id.erase(player_id)


func _get_next_available_player_id() -> int:
	var game_manager: Variant = _get_game_manager()
	if game_manager != null and game_manager.state != null:
		for player_id in game_manager.state.player_order:
			if _is_player_seat_open(int(player_id)):
				return int(player_id)

	for player_id in range(4):
		if _is_player_seat_open(player_id):
			return player_id

	return -1


func _send_state_snapshot(peer_id: int) -> void:
	var game_manager: Variant = _get_game_manager()
	if game_manager == null or game_manager.state == null:
		return

	_receive_state_snapshot.rpc_id(peer_id, _create_state_snapshot())


func _broadcast_state_snapshot() -> void:
	var game_manager: Variant = _get_game_manager()
	if game_manager == null or game_manager.state == null:
		return

	_receive_state_snapshot.rpc(_create_state_snapshot())


func _create_state_snapshot() -> Dictionary:
	var game_manager: Variant = _get_game_manager()
	if game_manager == null:
		return {}

	var snapshot: Dictionary = game_manager.get_state_snapshot()
	snapshot[SNAPSHOT_REVISION_KEY] = _state_revision
	return snapshot


func _get_game_manager() -> Variant:
	return get_node_or_null("/root/GameManager")


func _get_event_bus() -> Variant:
	return get_node_or_null("/root/EventBus")


func _ensure_local_reconnect_token() -> String:
	if _local_reconnect_token.is_empty():
		_local_reconnect_token = _load_local_reconnect_token()
	if _local_reconnect_token.is_empty():
		_local_reconnect_token = _create_local_reconnect_token()
		_save_local_reconnect_token(_local_reconnect_token)

	return _local_reconnect_token


func _load_local_reconnect_token() -> String:
	if not FileAccess.file_exists(LOCAL_RECONNECT_TOKEN_PATH):
		return ""

	var token_file := FileAccess.open(LOCAL_RECONNECT_TOKEN_PATH, FileAccess.READ)
	if token_file == null:
		return ""

	return token_file.get_as_text().strip_edges()


func _save_local_reconnect_token(reconnect_token: String) -> void:
	if reconnect_token.strip_edges().is_empty():
		return

	var token_file := FileAccess.open(LOCAL_RECONNECT_TOKEN_PATH, FileAccess.WRITE)
	if token_file == null:
		return

	token_file.store_string(reconnect_token.strip_edges())


func _create_local_reconnect_token() -> String:
	var token_rng := RandomNumberGenerator.new()
	token_rng.randomize()
	return "%d-%d-%d-%d" % [
		int(Time.get_unix_time_from_system()),
		Time.get_ticks_usec(),
		token_rng.randi(),
		token_rng.randi(),
	]


func _handle_peer_reconnect_token(peer_id: int, reconnect_token: String, send_remote_updates: bool = true) -> void:
	if peer_id <= 0 or reconnect_token.is_empty():
		return

	_reconnect_token_by_peer_id[peer_id] = reconnect_token
	var reserved_player_id := _get_reserved_player_id_for_reconnect_token(reconnect_token)
	if reserved_player_id >= 0:
		_reassign_peer_to_reserved_player(peer_id, reserved_player_id, reconnect_token, send_remote_updates)
		_emit_status("Peer %d reconnected as P%d" % [peer_id, reserved_player_id + 1])
		return

	if _player_id_by_peer_id.has(peer_id):
		_bind_reconnect_token_to_player(reconnect_token, int(_player_id_by_peer_id[peer_id]))
	_emit_status("Peer %d registered reconnect token" % peer_id)


func _get_reserved_player_id_for_reconnect_token(reconnect_token: String) -> int:
	if not _player_id_by_reconnect_token.has(reconnect_token):
		return -1

	var player_id := int(_player_id_by_reconnect_token[reconnect_token])
	if not _is_player_seat_reserved(player_id):
		return -1

	if _peer_id_by_player_id.has(player_id):
		return -1

	return player_id


func _reassign_peer_to_reserved_player(peer_id: int, player_id: int, reconnect_token: String, send_remote_updates: bool = true) -> void:
	_release_peer_assignment(peer_id)
	_reconnect_token_by_peer_id[peer_id] = reconnect_token
	_assign_peer_to_player(peer_id, player_id)
	_bind_reconnect_token_to_player(reconnect_token, player_id)
	if send_remote_updates:
		_state_revision += 1
		_assign_local_player.rpc_id(peer_id, player_id, ASSIGNMENT_STATUS_RECONNECTED)
		_send_state_snapshot(peer_id)


func _bind_reconnect_token_to_player(reconnect_token: String, player_id: int) -> void:
	if reconnect_token.is_empty() or player_id < 0:
		return

	_player_id_by_reconnect_token[reconnect_token] = player_id
	_reconnect_token_by_player_id[player_id] = reconnect_token


func _reserve_player_seat(player_id: int, reconnect_token: String) -> void:
	if player_id < 0 or reconnect_token.is_empty():
		return

	_bind_reconnect_token_to_player(reconnect_token, player_id)
	_reserved_player_ids[player_id] = true


func _is_player_seat_reserved(player_id: int) -> bool:
	return _reserved_player_ids.has(player_id)


func _is_player_seat_open(player_id: int) -> bool:
	if _peer_id_by_player_id.has(player_id):
		return false

	if _is_player_seat_reserved(player_id):
		return false

	return true


func _get_local_assignment_status_message(player_id: int, assignment_status: String) -> String:
	if player_id < 0:
		return "Connected as spectator"

	if assignment_status == ASSIGNMENT_STATUS_RECONNECTED:
		return "Reconnected as P%d" % [player_id + 1]

	return "Connected as P%d" % [player_id + 1]


func _get_snapshot_status_message(revision: int) -> String:
	var snapshot_text := "synced snapshot"
	if revision >= 0:
		snapshot_text = "synced snapshot #%d" % revision

	if _local_assignment_status_message.is_empty():
		return "Synced snapshot" if revision < 0 else "Synced snapshot #%d" % revision

	return "%s; %s" % [_local_assignment_status_message, snapshot_text]


func _emit_status(message: String) -> void:
	_status_message = message
	connection_status_changed.emit(message)
