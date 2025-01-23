class_name QuestDisplayer extends Control

var quest: Quest

@export var label : Label

func set_quest(quest: Quest) -> void:
	if self.quest != null:
		self.quest.state_changed.disconnect(_on_quest_state_changed)
	self.quest = quest
	self.quest.state_changed.connect(_on_quest_state_changed) 
	
func _process(delta: float) -> void:
	if quest == null:
		return
	label.text = quest.get_recap_message()
	
func _on_quest_state_changed(new_state: Quest.State) -> void:
	match new_state:
		Quest.State.FINISHED:
			# TODO: make the text overlined ?
			pass
