class_name RoomObjectSpawnPoint extends RoomObject

@export var linked_scene : PackedScene = null

func _add_self_to_room() -> void:
	super()
	get_owner_room().add_spawn_point(self)
	
func spawn_scene() -> void:
	if linked_scene == null:
		printerr("RoomObjectSpawnPoint: linked_scene should not be null")
	
	var node : Node2D = linked_scene.instantiate();
	node.global_position = self.global_position
	owner_room.add_child(node)
