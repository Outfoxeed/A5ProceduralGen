class_name QuestGenerator extends Resource

@export_category("Dialogue")
@export_multiline var dialogue_tracery : String
@export var start_sentence_key : String
@export var in_progress_sentence_key : String
@export var end_sentence_key : String

@export_category("Rooms")
@export var wanted_rooms: Array[PackedScene] = []

func generate_quest() -> Quest:
	return null

func _generate_dialogues() -> Dictionary:
	var dialogues : Dictionary = {}
	_generate_state_dialogue(dialogues, Quest.State.NONE, start_sentence_key)
	_generate_state_dialogue(dialogues, Quest.State.IN_PROGRESS, in_progress_sentence_key)
	_generate_state_dialogue(dialogues, Quest.State.FINISHED, end_sentence_key)
	return dialogues
	
func _generate_state_dialogue(dialogues: Dictionary, quest_state: Quest.State, flatten_key: String) -> void:
	if flatten_key.is_empty():
		return
	dialogues[quest_state] = DialogueData.new([
		TraceryHelpers.simple_generation(dialogue_tracery, flatten_key)
	])
	
func _get_wanted_room() -> PackedScene:
	if wanted_rooms.is_empty():
		return null
	return wanted_rooms.pick_random()
