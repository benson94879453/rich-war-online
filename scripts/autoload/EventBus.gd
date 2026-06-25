extends Node


signal game_event_emitted(event: GameEvent)


func emit_game_event(event: GameEvent) -> void:
	game_event_emitted.emit(event)
