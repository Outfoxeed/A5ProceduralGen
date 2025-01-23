extends Node

var ended = false

func _on_body_entered(body: Node2D) -> void:
	if ended:
		return
	if body is not Player:
		return
	
	var player = body as Player
	if player.quest_manager.quests.size() == GameInstance.quests.size() and player.quest_manager.current_quests.is_empty():
		SignalBus.game_ended.emit()
			
