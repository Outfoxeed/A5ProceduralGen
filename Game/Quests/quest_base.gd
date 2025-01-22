class_name Quest extends Resource

signal state_changed(new_state: Quest.State)

enum State { NONE, IN_PROGRESS, FINISHED }
var current_state : Quest.State = Quest.State.NONE:
	set(value):
		current_state = value
		state_changed.emit(current_state)
var _dialogues : Dictionary

var wanted_room_scene : PackedScene = null
var spawned_room: Room = null

func _init(dialogues: Dictionary, wanted_room_scene: PackedScene) -> void:
	self._dialogues = dialogues 
	self.wanted_room_scene = wanted_room_scene
	
func set_wanted_room_scene(wanted_room_scene: PackedScene) -> void:
	self.wanted_room_scene = wanted_room_scene

# ---------------
func get_dialogue_data() -> DialogueData:
	if _dialogues.has(current_state):
		return _dialogues[current_state]
	return null
	
func get_recap_message() -> String:
	return "quest"

# ----------------
# Activation/Deactivation
# ----------------
func activate() -> void:
	pass

func deactivate() -> void:
	pass

# ----------------
# Specific room
# ----------------
func has_specific_room() -> bool:
	return wanted_room_scene != null

func get_specific_room() -> PackedScene:
	return wanted_room_scene
	
func set_spawned_room(spawned_room: Room) -> void:
	self.spawned_room = spawned_room
