extends Node

@export_category("Quests")
@export var quest_generators: Array[QuestGenerator]
@export var quest_number_range: Vector2i = Vector2i(2, 2)

@export_category("Components")
@export var macro_generator: MacroGenerator

func _ready() -> void:
	var quests : Array[Quest] = _generate_quests()
	# TODO: pass the quests to the macro generator 
		
func _generate_quests() -> Array[Quest]:
	var result : Array[Quest] = []
	var quest_count : int = randi_range(quest_number_range.x, quest_number_range.y)
	for i in range(0, quest_count):
		result.append(quest_generators.pick_random().generate_quest())
	return result
