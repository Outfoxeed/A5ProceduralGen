class_name MacroGenerator
extends Node2D

enum WalkerState {NONE, WALKING, COMMON_ROOMS, STOPPED, END}
enum TurnDirection {NONE, FORWARD, RIGHT, BACKWARD, LEFT}

#=========================
#==== VARIABLES
#=========================

@export_category("Procedural Params")
@export var pcg_seed 	: int = 0
@export var min_steps 	: int = 10 # Min number of hallway cells
@export var max_steps 	: int = 20 # Max number of hallway cells
@export var main_hallway_quests_only : bool = true
@export_range(0, 100, 1) var forward_chance 	: int = 75  # Chance for the walker to keep going forward (repeat the previous direction) each step
@export_range(0, 100, 1) var common_room_chance : int = 30  # Chance for a common room to spawn at the sides of a hallway

@export_category("Rooms")
@export var start_rooms 	: Array[PackedScene] = [preload("res://Game/Rooms/Room_Starts/room_start_template.tscn")]
@export var hallway_rooms 	: Array[PackedScene] = [preload("res://Game/Rooms/Room_Hallways/room_hallway_template.tscn")]
@export var common_rooms 	: Array[PackedScene] = [preload("res://Game/Rooms/Room_Common/room_template.tscn")]
@export var end_rooms 		: Array[PackedScene] = [preload("res://Game/Rooms/Room_Ends/room_end_template.tscn")]

@export_category("Debug")
@export var draw_debugs : bool = true
@export var debug_room 	: PackedScene = preload("res://Game/Rooms/Tests/room_debug.tscn")
@export_range(0, 1, 0.05) var time_between_steps : float = 0

var debug_rooms : Node2D
var debug_paths : Node2D
var rooms_parent : Node2D
var rng : RandomNumberGenerator

var previous_state 	: WalkerState = WalkerState.NONE
var current_state 	: WalkerState = WalkerState.NONE:
	set(value):
		previous_state = current_state
		current_state = value

var current_position 	: Vector2i = Vector2i.ZERO
var previous_position 	: Vector2i = Vector2i.MAX
var current_direction 	: Vector2i = Vector2i.UP
var previous_direction 	: Vector2i = Vector2i.MAX

var steps_nb 			: int = 0 # Number of steps to do, between min_steps and max_steps
var current_steps_nb 	: int = 0
var current_quest_index : int = 0
var quests_nb 			: int = 3 # Number of quests to generate

var step_cooldown 	: float = 0

var current_quest : Quest
var current_quest_room_spawned : bool = false

var previous_turns 			: Array[TurnDirection]
var main_hallway_positions 	: Array[Vector2i]
var all_hallway_positions 	: Array[Vector2i]
var quests 					: Array[Quest]

var rooms_dic = {} # Positions - Room Resources dictionary

#=========================
#====  PRIVATE FUNCS
#=========================

func generate_level(in_quests: Array[Quest]):
	# seed initialization
	if pcg_seed == 0:
		pcg_seed = randi()
	
	print("Generating level using seed :\n", pcg_seed)
	seed(pcg_seed)
	
	rng = RandomNumberGenerator.new()
	rng.seed = pcg_seed
	
	quests = in_quests
	quests_nb = quests.size() - 1
	
	# steps initialization TODO: chopper les max_steps min_steps de la quete
	if min_steps > max_steps:
		var tmp = min_steps
		min_steps = max_steps
		max_steps = tmp
	
	steps_nb = randi_range(min_steps, max_steps)
	steps_nb = clamp(steps_nb, min_steps, max_steps)
	
	# state initialization
	current_state = WalkerState.WALKING

#=========================
#====  PRIVATE FUNCS
#=========================

func _spawn_real_rooms() -> void:
	for pos in rooms_dic:
		var room : Room
		match rooms_dic[pos].room_type:
			Room.RoomType.START:
				room = start_rooms.pick_random().instantiate()
			Room.RoomType.HALLWAY:
				room = hallway_rooms.pick_random().instantiate()
			Room.RoomType.COMMON:
				room = common_rooms.pick_random().instantiate()
			Room.RoomType.END:
				room = end_rooms.pick_random().instantiate()
			_:
				push_error("Macro Generator : Unexpected room type.")
			
		if room:
			rooms_parent.add_child(room)
			var paths : int = rooms_dic[pos].paths_hex
			
			if room is not HallwayRoom:
				room.spawn_doors(paths & 0x1, paths & 0x2, paths & 0x4, paths & 0x8)
			else:
				var holes : int = 0
				var doors : int = 0
				for dir in hex_to_directions(paths):
					if !rooms_dic.has(pos + dir):
						continue
					
					if rooms_dic[pos + dir].room_type == Room.RoomType.HALLWAY:
						holes |= _direction_to_hex(dir)
					else:
						doors |= _direction_to_hex(dir)
				
				room.spawn_doors(doors & 0x1, doors & 0x2, doors & 0x4, doors & 0x8)
				(room as HallwayRoom).delete_walls(holes & 0x1, holes & 0x2, holes & 0x4, holes & 0x8)
				
			var dimensions : Rect2i = room.get_world_bounds()
			room.position = Vector2i(pos.x * dimensions.size.x, pos.y * dimensions.size.y)



func _debug_draw_paths() -> void:
	for pos in rooms_dic:
		var paths : int = rooms_dic[pos].paths_hex;
		if paths & 0x1:
			var line : Line2D = Line2D.new()
			line.default_color = Color.WHITE
			line.add_point(pos * 32 + Vector2i(1, -1) * 16, 100)
			line.add_point(pos * 32 + Vector2i(1, -1) * 16 + Vector2i.UP * 16, 100)
			debug_paths.add_child(line)
			line.z_index = 100
		if paths & 0x2:
			var line : Line2D = Line2D.new()
			line.default_color = Color.WHITE
			line.add_point(pos * 32 + Vector2i(1, -1) * 16, 100)
			line.add_point(pos * 32 + Vector2i(1, -1) * 16 + Vector2i.RIGHT * 16, 100)
			debug_paths.add_child(line)
			line.z_index = 100
		if paths & 0x4:
			var line : Line2D = Line2D.new()
			line.default_color = Color.WHITE
			line.add_point(pos * 32 + Vector2i(1, -1) * 16, 100)
			line.add_point(pos * 32 + Vector2i(1, -1) * 16 + Vector2i.DOWN * 16, 100)
			debug_paths.add_child(line)
			line.z_index = 100
		if paths & 0x8:
			var line : Line2D = Line2D.new()
			line.default_color = Color.WHITE
			line.add_point(pos * 32 + Vector2i(1, -1) * 16, 100)
			line.add_point(pos * 32 + Vector2i(1, -1) * 16 + Vector2i.LEFT * 16, 100)
			debug_paths.add_child(line)
			line.z_index = 100



func _paths_hex_to_string(paths: int) -> String:
	var ret_string : String = ""
	if paths & 0x1:
		ret_string += " UP "
	if paths & 0x2:
		ret_string += " RIGHT "
	if paths & 0x4:
		ret_string += " DOWN "
	if paths & 0x8:
		ret_string += " LEFT "

	return ret_string



func hex_to_directions(hex: int) -> Array[Vector2i]:
	var arr : Array[Vector2i]
	
	if hex & 0x1:
		arr.append(Vector2i.UP)
	if hex & 0x2:
		arr.append(Vector2i.RIGHT)
	if hex & 0x4:
		arr.append(Vector2i.DOWN)
	if hex & 0x8:
		arr.append(Vector2i.LEFT)
	
	return arr



func _direction_to_hex(dir: Vector2i) -> int:
	if dir == Vector2i.UP:
		return 0x1
	if dir == Vector2i.RIGHT:
		return 0x2
	if dir == Vector2i.DOWN:
		return 0x4
	if dir == Vector2i.LEFT:
		return 0x8
	
	return 0x0



# returns false if the generation should end.
func _reset():
	steps_nb = randi_range(min_steps * 0.5, max_steps * 0.5) # Changer par le nombre de steps d'une quete
	steps_nb = clamp(steps_nb, min_steps * 0.5, max_steps * 0.5)
	current_steps_nb = 0
	previous_position = Vector2i.MAX
	current_direction = Vector2i(0, 1)
	previous_direction = Vector2i.MAX
	current_position = main_hallway_positions.pick_random() if main_hallway_quests_only else all_hallway_positions.pick_random() 
	main_hallway_positions.erase(current_position)
	all_hallway_positions.erase(current_position)
	rooms_dic.erase(current_position)
	current_quest_index += 1
	current_state = WalkerState.WALKING



func _get_opposite_turn(turn : TurnDirection) -> TurnDirection:
	match turn:
		TurnDirection.FORWARD:
			return TurnDirection.BACKWARD
		TurnDirection.BACKWARD:
			return TurnDirection.FORWARD
		TurnDirection.RIGHT:
			return TurnDirection.LEFT
		TurnDirection.LEFT:
			return TurnDirection.RIGHT
		_:
			return TurnDirection.NONE



# returns an array of turn directions based one probability
# and feasability (can't have same turn twice in a row)
func _get_turn_dirs() -> Dictionary:
	if current_steps_nb == 0:
		return {TurnDirection.FORWARD: 25, TurnDirection.RIGHT: 25, TurnDirection.BACKWARD: 25, TurnDirection.LEFT: 25}
	else:
		var turns_dic = {}
		var previous_turn : TurnDirection = TurnDirection.NONE if previous_turns.is_empty() else previous_turns[-1]
		for n in range(1, 5):
			var turn_candidate : TurnDirection = n as TurnDirection
			
			if turn_candidate == TurnDirection.BACKWARD:
				continue
			elif turn_candidate == TurnDirection.FORWARD:
				turns_dic[turn_candidate] = forward_chance
			else:
				turns_dic[turn_candidate] = (100 - forward_chance) / 2
		
		# vampirisation de chance au cas ou un turn a deja ete fait
		for turnDir in turns_dic:
			if turnDir == TurnDirection.FORWARD:
				continue
			if turnDir == previous_turn:
				var chance : float = turns_dic[turnDir]
				turns_dic[turnDir] = 0
				turns_dic[_get_opposite_turn(turnDir)] += chance
				
		if previous_turn != TurnDirection.FORWARD:
			turns_dic.erase(previous_turn)
				
		return turns_dic



func _rotate_direction(dir: Vector2i, turn: TurnDirection) -> Vector2i:
	var angle : float = 0
	match turn:
		TurnDirection.RIGHT:
			angle = -PI / 2
		TurnDirection.LEFT:
			angle = PI / 2
		TurnDirection.BACKWARD:
			angle = PI
		TurnDirection.LEFT:
			return dir

	return Vector2i(dir.x * cos(angle) - dir.y * sin(angle), dir.x * sin(angle) + dir.y * cos(angle))



# returns Vector2i.MAX if no suitable position was found
func _get_next_position() -> Vector2i:
	var turns_dic = _get_turn_dirs()
	
	while !turns_dic.is_empty():
		var turns = turns_dic.keys()
		var chances = turns_dic.values()
		var turn_candidate : TurnDirection = turns[rng.rand_weighted(chances)]
		var direction_candidate : Vector2i = _rotate_direction(current_direction, turn_candidate)
		var pos_candidate : Vector2i = current_position + direction_candidate
		
		if rooms_dic.has(pos_candidate): # position already filled
			turns_dic.erase(turn_candidate)
		else:
			previous_turns.append(turn_candidate)
			previous_direction = current_direction
			current_direction = direction_candidate
			return pos_candidate
	
	previous_direction = current_direction
	return Vector2i.MAX



func _spawn_common_rooms() -> void:
	for pos in all_hallway_positions:
		# Check unused paths at position and try to place a common room
		# in the direction of the unused path.
		var paths : Array[Vector2i] = hex_to_directions(rooms_dic[pos].paths_hex)
		
		for dir in [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]:
			if paths.has(dir):
				continue
			
			# Check if space is available
			var pos_candidate : Vector2i = pos + dir
			if rooms_dic.has(pos_candidate):
				continue
			
			# Roll the dice
			if randi_range(1, 100) > common_room_chance:
				continue
			
			# Spawn common room
			rooms_dic[pos_candidate] = RoomResource.new()
			rooms_dic[pos_candidate].room_type = Room.RoomType.COMMON
			
			if draw_debugs:
				var debug_room_clone = debug_room.instantiate() as Node2D
				debug_room_clone.modulate = Color.PURPLE
				debug_room_clone.position = pos_candidate * 32
				debug_room_clone.z_index = 50
				debug_rooms.add_child(debug_room_clone)
			
			rooms_dic[pos].paths_hex |= _direction_to_hex(dir)
			rooms_dic[pos_candidate].paths_hex = _direction_to_hex(-dir)
	
	current_state = WalkerState.STOPPED



func _do_step() -> void:
	var room_type = Room.RoomType.NONE
	var debug_color : Color
	var next_pos = _get_next_position()
	
	if current_steps_nb == steps_nb - 1 or next_pos == Vector2i.MAX:
		if current_quest_index == 0:
			room_type = Room.RoomType.END
			debug_color = Color.GREEN
		else:
			room_type = Room.RoomType.COMMON
			debug_color = Color.PURPLE
			
		current_state = WalkerState.STOPPED
	elif current_steps_nb == 0:
		room_type = Room.RoomType.START
		debug_color = Color.RED if current_quest_index == 0 else Color.MAGENTA
	else:
		room_type = Room.RoomType.HALLWAY
		debug_color = Color.BLUE if current_quest_index == 0 else Color.CYAN
	
	rooms_dic[current_position] = RoomResource.new()
	rooms_dic[current_position].room_type = room_type
	
	if previous_direction != Vector2i.MAX:
		if current_steps_nb != 0:
			rooms_dic[current_position].paths_hex |= _direction_to_hex(-previous_direction)
	
		if previous_position != Vector2i.MAX:
			rooms_dic[previous_position].paths_hex |= _direction_to_hex(previous_direction)
	
	if room_type == Room.RoomType.HALLWAY:
		if current_quest_index == 0:
			main_hallway_positions.append(current_position)
		
		all_hallway_positions.append(current_position)

	if draw_debugs:
		var debug_room_clone = debug_room.instantiate() as Node2D
		debug_room_clone.modulate = debug_color
		debug_room_clone.position = current_position * 32
		debug_room_clone.z_index = 50
		debug_rooms.add_child(debug_room_clone)
		#print("Current path : ", _paths_hex_to_string(room_paths_dic[current_position]))
		#if previous_position != Vector2i.MAX:
			#print("Previous path : ", _paths_hex_to_string(room_paths_dic[previous_position]))

	if current_state != WalkerState.STOPPED:
		previous_position = current_position if current_position != Vector2i.MAX else previous_position
		current_position = next_pos
		
	current_steps_nb += 1

func _ready() -> void:
	var one   : Quest
	var two   : Quest
	var three : Quest
	debug_rooms = $DebugVisualizer/DebugRooms
	debug_paths = $DebugVisualizer/DebugPaths
	rooms_parent = $RoomsParent
	generate_level([one, two, three])

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if current_state == WalkerState.END:
		return
	
	if current_state == WalkerState.WALKING:
		_do_step()
		if time_between_steps == 0:
			_process(delta)
		else:
			OS.delay_msec(time_between_steps * 1000)
	elif current_state == WalkerState.STOPPED and previous_state == WalkerState.WALKING and current_quest_index != quests_nb:
		_reset()
	elif current_state == WalkerState.STOPPED and previous_state == WalkerState.WALKING and current_quest_index == quests_nb:
		current_state = WalkerState.COMMON_ROOMS
		_spawn_common_rooms()
	elif current_state == WalkerState.STOPPED and previous_state == WalkerState.COMMON_ROOMS:
		_spawn_real_rooms()
		if draw_debugs:
			_debug_draw_paths()
		current_state = WalkerState.END
