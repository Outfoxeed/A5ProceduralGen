extends Node

var ended = false

func _on_body_entered(body: Node2D) -> void:
	if !body is Player:
		return

	if ended:
		return
	
	var player = body as Player
	if player.quest_manager.quests.size() == GameInstance.quests.size() and player.quest_manager.current_quests.is_empty():
		SignalBus.game_ended.emit()
			
