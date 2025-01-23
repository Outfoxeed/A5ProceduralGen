class_name RoomResource
extends Resource

var related_quest	: Quest
var room_type		: Room.RoomType = Room.RoomType.NONE
var is_hallway_end 	: bool = false
var is_main_hallway : bool = false
var is_quest_room	: bool = false
var paths_hex		: int
var debug_color		: Color = Color.WHITE
