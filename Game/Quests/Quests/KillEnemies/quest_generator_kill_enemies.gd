class_name QuestGenerator_KillEnemies extends QuestGenerator

@export_category("Kill Enemies")
@export var enemy_count_min : int = 1
@export var enemy_count_max : int = 5
@export var enemy_scene : PackedScene

func generate_quest() -> Quest:
	return Quest_KillEnemies.new(
		_generate_dialogues(),
		_get_wanted_room(),
		randi_range(enemy_count_min, enemy_count_max),
		enemy_scene
	)
