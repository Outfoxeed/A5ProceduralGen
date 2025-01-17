class_name Enemy extends CharacterBase

static var all_enemies : Array[Enemy]

@export var attack_warm_up : float = 0.5
@export var attack_distance : float = 0.5

var _state_timer : float = 0.0


func _ready() -> void:
	all_enemies.push_back(self)
	for room in Room.all_rooms:
		if room.contains(global_position):
			_room = room
			break
	_set_state(STATE.IDLE)


func _process(delta: float) -> void:
	super(delta)
	update_AI()


func _exit_tree() -> void:
	all_enemies.erase(self)


func update_AI() -> void:
	if _can_move() && Player.Instance._room == _room:
		var enemy_to_player = Player.Instance.global_position - global_position
		if enemy_to_player.length() < attack_distance:
			_attack()
		else:
			_direction = enemy_to_player.normalized()
	else:
		_direction = Vector2.ZERO


func _set_state(state : STATE) -> void:
	super(state)
	_state_timer = 0.0

	match _state:
		STATE.STUNNED:
			_current_movement = stunned_movemement
		STATE.DEAD:
			_end_blink()
			queue_free()
		_:
			_current_movement = default_movement

	if !_can_move():
		_direction = Vector2.ZERO


func _update_state(delta : float) -> void:
	super(delta)
	_state_timer += delta
	match _state:
		STATE.ATTACKING:
			if _state_timer >= attack_warm_up:
				_spawn_attack_scene()
				_set_state(STATE.IDLE)
