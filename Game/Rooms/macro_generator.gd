class_name MacroGenerator
extends Node2D

enum WalkerState {NONE, WALKING, STOPPED, END}
enum TurnDirection {NONE, FORWARD, RIGHT, BACKWARD, LEFT}

#=========================
#==== VARIABLES
#=========================

@export_category("Procedural Params")
@export var pcg_seed : int = 0
@export var min_steps : int = 1 # Min number of hallway cells
@export var max_steps : int = 10 # Max number of hallway cells
@export var main_hallway_quests_only : bool = true
@export_range(0, 100, 1) var forward_chance : int = 75  # Chance for the walker to keep going forward (repeat the previous direction) each step

@export_category("Rooms")
@export var hallway_rooms : Array[PackedScene]
@export var start_rooms : Array[PackedScene]
@export var end_rooms : Array[PackedScene]

@export_category("Debug")
@export var draw_debugs : bool = true
@export_range(0, 1, 0.1) var time_between_steps : float = 1
@export var debug_room : PackedScene
@export var quests_nb : int = 3 # Number of quests to generate

var debug_visualizer : Node2D
var current_state : WalkerState = WalkerState.NONE
var current_position : Vector2i = Vector2i.ZERO
var previous_position : Vector2i = Vector2i.MAX
var current_direction : Vector2i = Vector2i.UP
var previous_direction : Vector2i = Vector2i.MAX
var previous_turns : Array[TurnDirection]
var steps_nb : int = 0 # Number of steps to do, between min_steps and max_steps
var current_steps_nb : int = 0
var rng : RandomNumberGenerator
var step_cooldown : float = 0
var current_quest_nb : int = 0
var hallway_positions : Array[Vector2i]

var room_types_dic = {} # Positions - Room Types dictionary
var room_paths_dic = {} # Positions - Possible paths dictionary 0x0 = None, 0x1 = UP, 0x2 = RIGHT, 0x4 = DOWN, 0x8 = LEFT
#var rooms_dic = {} # Positions - Room dictionary

#=========================
#==== FUNCS
#=========================

func _spawn_rooms() -> void:
	for pos in room_types_dic:
		var room : Room
		match room_types_dic[pos]:
			Room.RoomType.START:
				room = start_rooms.pick_random().instantiate()
			Room.RoomType.HALLWAY:
				room = hallway_rooms.pick_random().instantiate()
			Room.RoomType.END:
				room = end_rooms.pick_random().instantiate()
			_:
				push_error("Macro Generator : Unexpected room type.")
			
		if room:
			add_child(room)
			var paths = room_paths_dic[pos]
			room.spawn_doors(paths & 0x1, paths & 0x2, paths & 0x4, paths & 0x8)
			var dimensions : Rect2i = room.get_world_bounds()
			room.position = Vector2i(pos.x * dimensions.size.x, pos.y * dimensions.size.y)
	
	

func _debug_draw_paths() -> void:
	for pos in room_paths_dic:
		if room_paths_dic[pos] & 0x1:
			var line : Line2D = Line2D.new()
			line.default_color = Color.WHITE
			line.add_point(pos * 32 + Vector2i(1, -1) * 16, 100)
			line.add_point(pos * 32 + Vector2i(1, -1) * 16 + Vector2i.UP * 16, 100)
			add_child(line)
			line.z_index = 100
		if room_paths_dic[pos] & 0x2:
			var line : Line2D = Line2D.new()
			line.default_color = Color.WHITE
			line.add_point(pos * 32 + Vector2i(1, -1) * 16, 100)
			line.add_point(pos * 32 + Vector2i(1, -1) * 16 + Vector2i.RIGHT * 16, 100)
			add_child(line)
			line.z_index = 100
		if room_paths_dic[pos] & 0x4:
			var line : Line2D = Line2D.new()
			line.default_color = Color.WHITE
			line.add_point(pos * 32 + Vector2i(1, -1) * 16, 100)
			line.add_point(pos * 32 + Vector2i(1, -1) * 16 + Vector2i.DOWN * 16, 100)
			add_child(line)
			line.z_index = 100
		if room_paths_dic[pos] & 0x8:
			var line : Line2D = Line2D.new()
			line.default_color = Color.WHITE
			line.add_point(pos * 32 + Vector2i(1, -1) * 16, 100)
			line.add_point(pos * 32 + Vector2i(1, -1) * 16 + Vector2i.LEFT * 16, 100)
			add_child(line)
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
	current_position = hallway_positions.pick_random()
	current_direction = Vector2i(0, 1)
	previous_direction = Vector2i.MAX
	hallway_positions.erase(current_position)
	room_types_dic.erase(current_position)
	current_quest_nb += 1
	current_state = WalkerState.WALKING
	if draw_debugs:
		print("RESET")



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
		
		if room_types_dic.has(pos_candidate): # position already filled
			turns_dic.erase(turn_candidate)
		else:
			previous_turns.append(turn_candidate)
			previous_direction = current_direction
			current_direction = direction_candidate
			return pos_candidate
	
	previous_direction = current_direction
	return Vector2i.MAX



func _do_step() -> void:
	var room_type = Room.RoomType.NONE
	var debug_color : Color
	var next_pos = _get_next_position()
	
	if current_steps_nb == steps_nb - 1 or next_pos == Vector2i.MAX:
		if current_quest_nb == 0:
			room_type = Room.RoomType.END
			debug_color = Color.GREEN
		else:
			room_type = Room.RoomType.HALLWAY
			debug_color = Color.CYAN
			
		current_state = WalkerState.STOPPED
	elif current_steps_nb == 0:
		room_type = Room.RoomType.START
		debug_color = Color.RED if current_quest_nb == 0 else Color.MAGENTA
	else:
		room_type = Room.RoomType.HALLWAY
		debug_color = Color.BLUE if current_quest_nb == 0 else Color.CYAN
	
	room_types_dic[current_position] = room_type
	
	if !room_paths_dic.has(current_position):
		room_paths_dic[current_position] = 0 # Initialisation
	
	if previous_direction != Vector2i.MAX:
		if current_steps_nb != 0:
			room_paths_dic[current_position] |= _direction_to_hex(-previous_direction)
	
		if previous_position != Vector2i.MAX:
			room_paths_dic[previous_position] |= _direction_to_hex(previous_direction)
	
	if room_type == Room.RoomType.HALLWAY and ((main_hallway_quests_only and current_quest_nb == 0) or !main_hallway_quests_only):
		hallway_positions.append(current_position)


	if draw_debugs:
		var debug_room_clone = debug_room.instantiate() as Node2D
		debug_room_clone.modulate = debug_color
		debug_room_clone.position = current_position * 32
		debug_room_clone.z_index = 50
		debug_visualizer.add_child(debug_room_clone)
		print("Current path : ", _paths_hex_to_string(room_paths_dic[current_position]))
		if previous_position != Vector2i.MAX:
			print("Previous path : ", _paths_hex_to_string(room_paths_dic[previous_position]))

	if current_state != WalkerState.STOPPED:
		previous_position = current_position if current_position != Vector2i.MAX else previous_position
		current_position = next_pos
		
	current_steps_nb += 1



# Init values
func _ready() -> void:
	debug_visualizer = $DebugVisualizer
	
	# seed initialization
	if pcg_seed == 0:
		pcg_seed = randi()
		
	seed(pcg_seed)
	
	rng = RandomNumberGenerator.new()
	rng.seed = pcg_seed
	
	# steps initialization
	if min_steps > max_steps:
		var tmp = min_steps
		min_steps = max_steps
		max_steps = tmp
	
	steps_nb = randi_range(min_steps, max_steps)
	steps_nb = clamp(steps_nb, min_steps, max_steps)
	
	# state initialization
	current_state = WalkerState.WALKING



# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if current_state == WalkerState.WALKING:
		if time_between_steps == 0:
			_do_step()
		else:
			step_cooldown -= delta
			if step_cooldown <= 0:
				_do_step()
				step_cooldown = time_between_steps
	elif current_state == WalkerState.STOPPED and current_quest_nb != quests_nb:
		_reset()
	elif current_state == WalkerState.STOPPED and current_quest_nb == quests_nb:
		current_state = WalkerState.END
		_spawn_rooms()
		if draw_debugs:
			_debug_draw_paths()
