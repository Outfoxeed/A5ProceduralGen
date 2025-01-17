extends Node2D

@export var room_to_spawn : PackedScene

@export_category("RoomObject spawn")
@export var wanted_room_object : PackedScene = null
@export var wanted_room_object_amount : int = 1

func _ready() -> void:
	var room : Room = room_to_spawn.instantiate()
	room.global_position = Vector2.ZERO
	
	print("[TEST SPAWN ROOM] Before add_child: \n" + str(room.spawn_points))
	await get_tree().process_frame
	print("[TEST SPAWN ROOM] Before add_child + wait a frame: \n" + str(room.spawn_points))
	
	self.add_child(room)
	
	print("[TEST SPAWN ROOM] After add_child: \n" + str(room.spawn_points))
	await get_tree().process_frame
	print("[TEST SPAWN ROOM] After add_child + wait frame: \n" + str(room.spawn_points))
	
	room.request_spawn(wanted_room_object, wanted_room_object_amount)
