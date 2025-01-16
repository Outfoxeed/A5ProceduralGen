class_name RoomObject extends Node2D

var owner_room : Room

func _ready() -> void:
	_add_self_to_room()
	visible = false
	
func get_owner_room() -> Room:
	if owner_room != null:
		return owner_room
		
	var node : Node2D = owner
	while node is not Room:
		node = node.owner
	owner_room = node as Room
	return owner_room
	
func _add_self_to_room() -> void:
	pass
