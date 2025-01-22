class_name Quest_KillEnemies extends Quest

var _enemies_count
var _killed_count: int = 0

func _init(dialogues: Dictionary, wanted_room: PackedScene, enemies_count: int) -> void:
	super._init(dialogues, wanted_room)
	_enemies_count = enemies_count
	
func get_recap_message() -> String:
	return "Kill enemies (" + str(_killed_count) + "/" + str(_enemies_count) + ")"
