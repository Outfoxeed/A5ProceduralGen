class_name Quest extends Resource

enum State { NONE, IN_PROGRESS, FINISHED }
var current_state : Quest.State = Quest.State.NONE:
	set(value):
		current_state = value
		state_changed.emit(current_state)

signal state_changed(new_state: Quest.State)

var _dialogues : Dictionary

func _init(dialogues: Dictionary) -> void:
	_dialogues = dialogues 

# ---------------
func get_dialogue_data() -> DialogueData:
	if _dialogues.has(current_state):
		return _dialogues[current_state]
	return null
	
func get_recap_message() -> String:
	return "quest"

# ----------------
# Listening
# ----------------
func start_listening() -> void:
	pass

func stop_listening() -> void:
	pass

# ----------------
# Specific room
# ----------------
func has_specific_room() -> bool:
	return false

func get_specific_room() -> PackedScene:
	return null
