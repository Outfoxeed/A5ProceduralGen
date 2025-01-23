class_name Room extends Node2D

enum RoomType {NONE, START, HALLWAY, COMMON, END}
enum Direction {NONE, TOP, RIGHT, DOWN, LEFT}

@export var is_start_room : bool = false
# Position of the room in index coordinates. Coordinates {0,0} are the coordinates of the central room. Room {1,0} is on the right side of room {0,0}.
@export var room_pos : Vector2i = Vector2i.ZERO
# Size of the room in index coordinates. By default : {1,1}.
@export var room_size : Vector2i = Vector2i.ONE
@export var tilemap_layers : Array[TileMapLayer]

static var all_rooms : Array[Room]

var room_type : RoomType
var doors : Array[Door]

@export_group("Spawns")
@export var spawn_points : Dictionary = {}
@export var wanted_spawn : Dictionary = {}

@export_group("Door tile definition")
@export var door_source_id : int = 2
@export var door_atlas_coord : Vector2i = Vector2.ZERO
@export var door_alternative_tile : int = 3

@export_group("Floor tile definition")
@export var floor_source_id : int = 10
@export var floor_atlas_coord : Vector2i = Vector2(4,9)
@export var floor_alternative_tile : int = 0


func _ready() -> void:
	all_rooms.push_back(self)
	
	for tile_map_layer in tilemap_layers:
		tile_map_layer.update_internals()
	
	for x in wanted_spawn:
		request_spawn(x, wanted_spawn[x])
	
	if is_start_room and Player.Instance != null:
		Player.Instance.enter_room(self)
		

func get_local_bounds() -> Rect2:
	var room_bounds = Rect2()
	if tilemap_layers == null || tilemap_layers.size() == 0:
		return room_bounds
	## Encapsulate all tilemap_layers
	for tilemap in tilemap_layers:
		var bounds = tilemap.get_used_rect() # Gives rect in nb of tiles not pixels
		var size_pixel = tilemap.tile_set.tile_size
		bounds.position = Vector2i(bounds.position.x * size_pixel.x, bounds.position.y * size_pixel.y)
		bounds.size = Vector2i(bounds.size.x * size_pixel.x, bounds.size.y * size_pixel.y)
		room_bounds = room_bounds.merge(bounds)
	return room_bounds


func get_world_bounds() -> Rect2:
	var result = get_local_bounds()
	result.position += position
	return result


func contains(point : Vector2) -> bool:
	var bounds = get_world_bounds()
	return bounds.has_point(point)


func on_enter_room(from : Room) -> void:
	pass


func get_adjacent_room(orientation : Utils.ORIENTATION, from : Vector2) -> Room:
	var dir : Vector2i = Utils.OrientationToDir(orientation)
	var adjacent_pos : Vector2i = room_pos + dir + get_position_offset(from)

	for room in all_rooms:
		if is_room_adjacent(room, adjacent_pos):
			return room
			
	return null


func is_room_adjacent(room : Room, adjacent_pos : Vector2) -> bool:
	return (
		adjacent_pos.x >= room.room_pos.x
		&& adjacent_pos.y >= room.room_pos.y
		&& adjacent_pos.x < room.room_pos.x + room.room_size.x
		&& adjacent_pos.y < room.room_pos.y + room.room_size.y
	)


func get_door(orientation : Utils.ORIENTATION, from : Vector2) -> Door:
	var door_position : Vector2i = Vector2i(position) + get_position_offset(from)
	for door in doors:
		var offsetPos = Vector2i(position) + get_position_offset(door.position)
		if door_position == offsetPos && door.orientation == orientation:
			return door
	return null


func get_position_offset(world_point : Vector2) -> Vector2i:
	if room_size.x <= 1 && room_size.y <= 1:
		return Vector2i.ZERO

	var offset : Vector2i = Vector2i.ZERO
	var bounds : Rect2 = get_world_bounds()
	var local_point : Vector2 = world_point - bounds.position

	if room_size.x > 1:
		offset.x = clampi(int(local_point.x / (bounds.size.x / room_size.x)), 0, room_size.x - 1)
	if room_size.y > 1:
		offset.y = clampi(int(local_point.y / (bounds.size.y / room_size.y)), 0, room_size.y - 1)
	return offset

func add_spawn_point(spawn_point: RoomObjectSpawnPoint) -> void:
	if spawn_points.has(spawn_point.linked_scene):
		(spawn_points[spawn_point.linked_scene] as Array[RoomObjectSpawnPoint]).append(spawn_point)
		return
	spawn_points[spawn_point.linked_scene] = [spawn_point] as Array[RoomObjectSpawnPoint]
	
func request_spawn(scene: PackedScene, amount : int = 1) -> Array[Node]:
	if amount == 0:
		return []
	if scene == null:
		printerr("[ROOM] Wanted scene to spawn is null")
		return []
	if not spawn_points.has(scene):
		printerr("[ROOM] "+ name + " has no spawn points for '" + scene.resource_path + "'")
		return []
		
	var array : Array[RoomObjectSpawnPoint] = spawn_points[scene]
	if amount >= array.size():
		var result : Array[Node]= []
		for spawn_point : RoomObjectSpawnPoint in array:
			result.append(spawn_point.spawn_scene())
		return result
	
	var wanted_spawn_points : Array[RoomObjectSpawnPoint] = []
	for i in range(0, amount):
		var random_spawn_point = array.pick_random()
		while random_spawn_point in wanted_spawn_points:
			random_spawn_point = array.pick_random()
		wanted_spawn_points.push_back(random_spawn_point)
	
	var result : Array[Node] = []
	for wanted_spawn_point in wanted_spawn_points:
		result.append(wanted_spawn_point.spawn_scene())
	return result
		

func spawn_doors(top: bool, right: bool, down: bool, left: bool) -> void:
	var rect : Rect2i = tilemap_layers[0].get_used_rect()
	if top:
		_spawn_door(Room.Direction.TOP)
	if right:
		_spawn_door(Room.Direction.RIGHT)
	if down:
		_spawn_door(Room.Direction.DOWN)
	if left:
		_spawn_door(Room.Direction.LEFT)

func _spawn_door(direction: Room.Direction) -> void:
	var rect : Rect2i = tilemap_layers[0].get_used_rect()
	var door_cell_pos : Vector2i = rect.position
	match direction:
		Room.Direction.TOP:
			door_cell_pos += Vector2i(rect.size.x / 2, 0)
		Room.Direction.RIGHT:
			door_cell_pos += Vector2i(rect.size.x - 1, rect.size.y / 2)
		Room.Direction.DOWN:
			door_cell_pos += Vector2i(rect.size.x / 2, rect.size.y - 1)
		Room.Direction.LEFT:
			door_cell_pos += Vector2i(0, rect.size.y / 2)
			
	for tilemap_layer in tilemap_layers:
		tilemap_layer.set_cell(door_cell_pos, -1, -Vector2.ONE, -1)
	tilemap_layers[0].set_cell(door_cell_pos, floor_source_id,
		 floor_atlas_coord, floor_alternative_tile)
	tilemap_layers[1].set_cell(door_cell_pos, door_source_id,
		 door_atlas_coord, door_alternative_tile)
		

func _exit_tree() -> void:
	all_rooms.erase(self)
