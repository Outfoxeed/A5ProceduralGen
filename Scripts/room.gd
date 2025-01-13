class_name Room extends Node2D

@export var is_start_room : bool
# Position of the room in index coordinates. Coordinates {0,0} are the coordinates of the central room. Room {1,0} is on the right side of room {0,0}.
@export var room_pos : Vector2i = Vector2i.ZERO
# Size of the room in index coordinates. By default : {1,1}.
@export var room_size : Vector2i = Vector2i.ONE
@export var tilemap_layers : Array[TileMapLayer]

static var all_rooms : Array[Room]

var doors : Array[Door]

@onready var _cam : CameraFollow = $/root/MainScene/Camera2D


func _ready() -> void:
	all_rooms.push_back(self)
	if is_start_room:
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
	var camera_bounds = get_world_bounds()
	_cam.set_bounds(camera_bounds)


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


func _exit_tree() -> void:
	all_rooms.erase(self)
