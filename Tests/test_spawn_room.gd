extends Node2D

@export var room_to_spawn : PackedScene

@export_category("RoomObject spawn")
@export var wanted_room_object : PackedScene = null
@export var wanted_room_object_amount : int = 1

func _ready() -> void:
	var room : Room = room_to_spawn.instantiate()
	room.global_position = Vector2.ZERO
	self.add_child(room)
	print(room.spawn_points)
	
	room.request_spawn(wanted_room_object, wanted_room_object_amount)
