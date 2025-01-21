extends Node2D

@export var room_to_spawn : PackedScene
@export var hallway_to_spawn : PackedScene

@export_category("RoomObject spawn")
@export var wanted_room_object : PackedScene = null
@export var wanted_room_object_amount : int = 1

func _ready() -> void:
	_spawn_room(room_to_spawn, Vector2.ZERO)
	_spawn_room(hallway_to_spawn, Vector2(0, 300))
	
func _spawn_room(room_scene: PackedScene, room_pos: Vector2) -> void:
	var room : Room = room_scene.instantiate()
	room.global_position = room_pos
	
	#print("[TEST SPAWN ROOM] Before add_child: \n" + str(room.spawn_points))
	await get_tree().process_frame
	#print("[TEST SPAWN ROOM] Before add_child + wait a frame: \n" + str(room.spawn_points))
	
	self.add_child(room)
	
	#print("[TEST SPAWN ROOM] After add_child: \n" + str(room.spawn_points))
	await get_tree().process_frame
	#print("[TEST SPAWN ROOM] After add_child + wait frame: \n" + str(room.spawn_points))
	
	room.request_spawn(wanted_room_object, wanted_room_object_amount)
	var rng : RandomNumberGenerator = RandomNumberGenerator.new()
	room.spawn_doors(rng.randi() % 2 == 0, rng.randi() % 2 == 0, 
	rng.randi() % 2 == 0, rng.randi() % 2 == 0)
	#room.spawn_doors(true, true, true, true)
