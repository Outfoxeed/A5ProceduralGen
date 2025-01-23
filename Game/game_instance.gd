extends Node

@export_category("Quests")
@export var quest_main : Quest_Main = null
@export var quest_generators: Array[QuestGenerator]
@export var quest_number_range: Vector2i = Vector2i(2, 2)

@export_category("Components")
@export var macro_generator : MacroGenerator
@export var player: Player
@export var player_camera: PackedScene

func _ready() -> void:
	var quests : Array[Quest] = _generate_quests()
	await get_tree().process_frame
	# TODO: pass the quests to the macro generator
	player.quest_manager.add_quest(quest_main)
	macro_generator.on_generation_completed.connect(_on_generation_completed.bind())
	macro_generator.generate_level(quests)

func _generate_quests() -> Array[Quest]:
	var result : Array[Quest] = [quest_main]
	var quest_count : int = randi_range(quest_number_range.x, quest_number_range.y)
	for i in range(0, quest_count):
		result.append(quest_generators.pick_random().generate_quest())
	return result

func _on_generation_completed() -> void:
	add_child(player_camera.instantiate())
