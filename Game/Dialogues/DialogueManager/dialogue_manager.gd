class_name DialogueManager extends Node

signal dialogue_started(dialogue: DialogueData)
signal dialogue_sentence_started(dialogue: DialogueData, sentence: int)
signal dialogue_ended(dialogue: DialogueData)

var playing_dialogue : bool:
	get:
		return current_dialogue != null

var current_dialogue : DialogueData
var current_sentence : int = 0

@export var _dialogue_interface : Node
@export var _dialogue_label : Label
@export var _dialogue_skip_button : Button

func _ready() -> void:
	_dialogue_interface.visible = false
	_dialogue_skip_button.pressed.connect(skip_sentence.bind())
	
func start_dialogue(dialogue: DialogueData) -> void:
	if current_dialogue != null:
		printerr("[DIALOGUE MANAGER] Dialogue is already in progress")
		return
	
	current_dialogue = dialogue
	current_sentence = 0
	_update_dialogue()
	
func skip_sentence():
	if current_dialogue == null:
		return
	current_sentence += 1; 	
	_update_dialogue()
	
func _update_dialogue():
	if current_dialogue == null:
		# should not happen
		return
	if current_sentence >= current_dialogue.sentences.size():
		_end_current_dialogue()
		return
	if not _dialogue_interface.visible:
		_dialogue_interface.visible = true
	if current_sentence == 0:
		dialogue_started.emit(current_dialogue)
	_dialogue_label.text = current_dialogue.sentences[current_sentence]
	dialogue_sentence_started.emit(current_dialogue, current_sentence)
	
func _end_current_dialogue() -> void:
	_dialogue_interface.visible = false
	_dialogue_label.text = ""
	dialogue_ended.emit(current_dialogue)
	current_dialogue = null
	current_sentence = 0
	
