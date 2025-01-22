class_name QuestPNJ extends Node

@export var quest : Quest
@export var interaction_indicator : Node2D

var player_in_bounds : bool = false

func _ready() -> void:
	_update_interaction_indicator()

func _process(delta: float) -> void:
	if not player_in_bounds:
		return
	if not Input.is_action_just_pressed("Interact"):
		return
	if DialogueManager_Autoload.playing_dialogue:
		return	
	_start_dialogue()

func _start_dialogue() -> void:
	DialogueManager_Autoload.start_dialogue(quest.get_dialogue_data())
	DialogueManager_Autoload.dialogue_ended.connect(_on_dialogue_ended.bind())
	_update_interaction_indicator()

func _on_interaction_range_area_body_entered(body: Node2D) -> void:
	var player : Player = body as Player
	if player == null:
		return
	player_in_bounds = true
	_update_interaction_indicator()


func _on_interaction_range_area_body_exited(body: Node2D) -> void:
	var player : Player = body as Player
	if player == null:
		return
	player_in_bounds = false
	_update_interaction_indicator()
	
	
func _update_interaction_indicator():
	interaction_indicator.visible = player_in_bounds and (not DialogueManager_Autoload.playing_dialogue) 
	
	
func _on_dialogue_ended(dialogue: DialogueData):
	DialogueManager_Autoload.dialogue_ended.disconnect(_on_dialogue_ended.bind())
	interaction_indicator.visible = true
	
	if quest.current_state == Quest.State.NONE:
		Player.Instance.quest_manager.add_quest(quest)
	
