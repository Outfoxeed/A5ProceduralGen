class_name Player extends CharacterBase

static var Instance : Player

signal room_entered(new_room: Room, old_room: Room)

@export var quest_manager: QuestManager

@export_group("Input")
@export_range (0.0, 1.0) var controller_dead_zone : float = 0.3


# Collectible
var key_count : int


func _init() -> void:
	Instance = self


func _ready() -> void:
	_set_state(STATE.IDLE)


func _process(delta: float) -> void:
	super(delta)
	_update_inputs()
	_update_room()
	_update_rotation()


func enter_room(room : Room) -> void:
	var previous = _room
	_room = room
	_room.on_enter_room(previous)
	room_entered.emit(_room, previous)


func _update_room() -> void:
	var room_bounds : Rect2 = _room.get_world_bounds()
	var next_room : Room = null
	if position.x > room_bounds.end.x:
		next_room = _room.get_adjacent_room(Utils.ORIENTATION.EAST, position)
	elif position.x < room_bounds.position.x:
		next_room = _room.get_adjacent_room(Utils.ORIENTATION.WEST, position)
	elif position.y < room_bounds.position.y:
		next_room = _room.get_adjacent_room(Utils.ORIENTATION.NORTH, position)
	elif position.y > room_bounds.end.y:
		next_room = _room.get_adjacent_room(Utils.ORIENTATION.SOUTH, position)

	if next_room != null:
		enter_room(next_room)


func _update_inputs() -> void:
	if _can_move():
		_direction = Vector2(Input.get_axis("Left", "Right"), Input.get_axis("Up", "Down"))
		if _direction.length() < controller_dead_zone:
			_direction = Vector2.ZERO
		else:
			_direction = _direction.normalized()

		if Input.is_action_pressed("Attack"):
			_attack()
	else:
		_direction = Vector2.ZERO

func _update_rotation() -> void:
	if _can_move():
		main_sprite.look_at(get_global_mouse_position())

func _set_state(state : STATE) -> void:
	super(state)
	match _state:
		STATE.STUNNED:
			_current_movement = stunned_movemement
		STATE.DEAD:
			_end_blink()
			_set_color(dead_color)
		_:
			_current_movement = default_movement

	if !_can_move():
		_direction = Vector2.ZERO


func _update_state(delta : float) -> void:
	super(delta)
	match _state:
		STATE.ATTACKING:
			_spawn_attack_scene()
			_set_state(STATE.IDLE)
			
func get_room() -> Room:
	return _room
