class_name RoomObject extends Node2D

var owner_room : Room

func _ready() -> void:
	_add_self_to_room()
	visible = false
	
func get_owner_room() -> Room:
	if owner_room != null:
		return owner_room
	
	var node : Node = get_parent()
	while node is not Room:
		node = node.get_parent()
	owner_room = node as Room
	
	if owner_room == null:
		push_error("[ROOM OBJECT] " + name + "'s owner room is null")
		return
	return owner_room
	
func _add_self_to_room() -> void:
	pass
