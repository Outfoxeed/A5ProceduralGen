class_name QuestGenerator_Recovery extends QuestGenerator

@export_category("Recovery")
@export var collectible_scene : PackedScene
@export var not_collected_title : String = "Trouve l'objet perdu"
@export var collected_title : String = "Ramène l'objet perdu à son propriétaire"

func generate_quest() -> Quest:
	return Quest_Recovery.new(
		_generate_dialogues(),
		_get_wanted_room(),
		collectible_scene,
		not_collected_title,
		collected_title
	)
