class_name QuestsDisplayer extends Control

var quest_manager: QuestManager

@export var quests_container: Control
@export var quest_displayer_scene : PackedScene

func set_quest_manager(quest_manager: QuestManager) -> void:
	if self.quest_manager != null:
		self.quest_manager.new_quest_received.disconnect(_on_new_quest_received)
	self.quest_manager = quest_manager
	self.quest_manager.new_quest_received.connect(_on_new_quest_received)

func _delete_quest_displayers() -> void:
	for child in quests_container.get_children():
		child.queue_free()
		
func _on_new_quest_received(quest: Quest) -> void:
	var quest_displayer = quest_displayer_scene.instantiate() as QuestDisplayer
	quests_container.add_child(quest_displayer)
	quest_displayer.set_quest(quest)
