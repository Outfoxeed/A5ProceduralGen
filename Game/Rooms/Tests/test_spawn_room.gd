extends Node2D

@export var room_to_spawn : PackedScene
@export var hallway_to_spawn : PackedScene

@export_category("RoomObject spawn")
@export var wanted_room_object : PackedScene = null
@export var wanted_room_object_amount : int = 1

func _ready() -> void:
	var rng : RandomNumberGenerator = RandomNumberGenerator.new()
	
	# First room
	var room : Room = await _spawn_room(room_to_spawn, Vector2.ZERO)
	room.request_spawn(wanted_room_object, wanted_room_object_amount)
	room.spawn_doors(rng.randi() % 2 == 0, rng.randi() % 2 == 0, 
	rng.randi() % 2 == 0, rng.randi() % 2 == 0)
	#room.spawn_doors(true, true, true, true)
	
	room.position -= Vector2(500, 0)
	
	# Hallway room
	var hallway_room : HallwayRoom = await _spawn_room(hallway_to_spawn, Vector2(0, 300))
	hallway_room.delete_walls(rng.randi() % 2 == 0, rng.randi() % 2 == 0, 
	rng.randi() % 2 == 0, rng.randi() % 2 == 0)
	
func _spawn_room(room_scene: PackedScene, room_pos: Vector2) -> Room:
	var room : Room = room_scene.instantiate()
	room.global_position = room_pos
	
	#print("[TEST SPAWN ROOM] Before add_child: \n" + str(room.spawn_points))
	await get_tree().process_frame
	#print("[TEST SPAWN ROOM] Before add_child + wait a frame: \n" + str(room.spawn_points))
	
	self.add_child(room)
	
	#print("[TEST SPAWN ROOM] After add_child: \n" + str(room.spawn_points))
	await get_tree().process_frame
	#print("[TEST SPAWN ROOM] After add_child + wait frame: \n" + str(room.spawn_points))
	
	return room
