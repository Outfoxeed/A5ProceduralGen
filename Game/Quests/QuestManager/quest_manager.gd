class_name QuestManager extends Node

signal new_quest_received(quest: Quest)
signal quest_finished(quest: Quest)

var quests : Array[Quest]
var current_quests : Array[Quest]

func add_quest(quest: Quest):
	quests.append(quest)
	new_quest_received.emit(quest)
	_start_quest(quest)

func _start_quest(quest: Quest):
	quest.current_state = Quest.State.IN_PROGRESS
	current_quests.append(quest)
	quest.state_changed.connect(_on_quest_state_changed.bind(quest))
	quest.activate()

func _on_quest_state_changed(quest: Quest, new_state: Quest.State) -> void:
	print("Quest's state changed to " + str(new_state))
	if new_state == Quest.State.FINISHED:
		quest.deactivate()
		current_quests.erase(quest)
		quest_finished.emit(quest)
