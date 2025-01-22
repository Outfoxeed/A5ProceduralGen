class_name Quest_KillEnemies extends Quest

var _enemies_count
var _enemy_scene : PackedScene
var _killed_count: int = 0

func _init(dialogues: Dictionary, wanted_room: PackedScene, 
  enemies_count: int, enemy_scene: PackedScene) -> void:
	super._init(dialogues, wanted_room)
	self._enemies_count = enemies_count
	self._enemy_scene = enemy_scene
	
func get_recap_message() -> String:
	return "Tuer les ennemis de la salle (" + str(_killed_count) + "/" + str(_enemies_count) + ")"

func activate() -> void:
	super.activate()
	var spawned_nodes = spawned_room.request_spawn(_enemy_scene, _enemies_count)
	for spawned_node in spawned_nodes:
		var enemy = spawned_node as Enemy
		enemy.died.connect(_on_enemy_died)

func deactivate() -> void:
	super.deactivate()
	
func _on_enemy_died(enemy: Enemy) -> void:
	_killed_count += 1
	if _killed_count >= _enemies_count:
		current_state = Quest.State.FINISHED
