class_name CharacterBase extends RigidBody2D

signal life_changed(current_life : int)

enum ORIENTATION {FREE, DPAD_8, DPAD_4}
enum STATE {IDLE, ATTACKING, STUNNED, DEAD}

@export_group("Life")
@export var life : int = 5 :
	set(value) :
		life = min(value, max_health)
		life_changed.emit(life)
@export var max_health : int = 5
@export var invincibility_duration : float = 1.0
@export var invincibility_blink_period : float = 0.2
@export var dead_color : Color = Color.GRAY
@export var sprites : Array[Sprite2D] = []

@export_group("Movement")
@export var default_movement : MovementParameters
@export var stunned_movemement : MovementParameters
@export var rotate_towards_movement : bool = true

@export_group("Attack")
@export var attack_scene : PackedScene
@export var attack_spawn_point : Node2D
@export var attack_cooldown : float = 0.3
@export var orientation : ORIENTATION = ORIENTATION.FREE

@export_group("Animations")
@onready var main_sprite : Sprite2D = $"BodySprite"
@export var animation_player : AnimationPlayer
@export var walk_north : String = "WalkPlayerNorth"
@export var walk_south : String = "WalkPlayerSouth"
@export var walk_east : String = "WalkPlayerEast"
@export var walk_west : String = "WalkPlayerWest"

# Life
var _last_hit_time : float

# Movement
var _direction : Vector2
var _current_movement : MovementParameters

# Attack
var _last_attack_time : float
var _has_to_apply_knockback : bool
var _knockback_value : Vector2

# State
var _state : STATE = STATE.IDLE
var _is_blinking : bool

# Dungeon position
var _room : Room



func _process(delta: float) -> void:
	_update_state(delta)


func apply_hit(attack : Attack) -> void:
	if Time.get_unix_time_from_system() - _last_hit_time < invincibility_duration:
		return
	_last_hit_time = Time.get_unix_time_from_system()

	life -= attack.damages if attack != null else 1
	if life <= 0:
		_set_state(STATE.DEAD)
	else:
		if attack != null && attack.knockback_duration > 0.0:
			apply_knockback(attack.knockback_duration, (attack.position - position).normalized() * attack.knockback_speed)
		_end_blink()
		blink()


func apply_knockback(duration : float, velocity : Vector2) -> void:
	_set_state(STATE.STUNNED)
	_has_to_apply_knockback = true
	_knockback_value = velocity
	await get_tree().create_timer(duration).timeout
	_set_state(STATE.IDLE)


func _update_state(delta : float) -> void:
	pass


func _set_state(state : STATE) -> void:
	_state = state
	if _state == STATE.DEAD:
		self.modulate = dead_color
		if animation_player != null:
			animation_player.play("RESET")
			animation_player.stop()


func _integrate_forces(state: PhysicsDirectBodyState2D) -> void:
	if _has_to_apply_knockback:
		state.linear_velocity = _knockback_value
		_has_to_apply_knockback = false

	if _direction.length() > 0.000001:
		state.linear_velocity = _current_movement.speed_max * _direction.normalized()
	else:
		state.linear_velocity = Vector2.ZERO
	_handle_animations()
		

func _handle_animations() -> void:
	var moving = _direction.length() > 0.000001
	if animation_player != null:
		if moving:
			if abs(_direction.x) > abs(_direction.y):
				if _direction.x > 0:
					animation_player.play(walk_east)
				elif _direction.x < 0:
					animation_player.play(walk_west)
			else:
				if _direction.y > 0:
					animation_player.play(walk_south)
				elif _direction.y < 0:
					animation_player.play(walk_north)
		else:
			animation_player.stop()
		return
		
	if rotate_towards_movement and moving:
		main_sprite.rotation = _compute_orientation_angle(_direction)


func blink() -> void:
	_is_blinking = true
	var invincibility_timer : float = 0.0
	while invincibility_timer < invincibility_duration:
		if !_is_blinking:
			return

		invincibility_timer += get_process_delta_time()
		var isVisible : bool = (int)(invincibility_timer/ invincibility_blink_period) % 2 == 1
		for sprite in sprites:
			sprite.visible = isVisible
		self.modulate = Color.WHITE if isVisible else Color.RED
		await get_tree().process_frame

	_end_blink()


func _end_blink() -> void:
	if !_is_blinking:
		return

	for sprite in sprites:
		sprite.visible = true

	_is_blinking = false


func _set_color(color : Color) -> void:
	for sprite in sprites:
		sprite.modulate = color


func _compute_orientation_angle(direction : Vector2) -> float:
	var angle = direction.angle()
	match orientation:
		ORIENTATION.DPAD_8:
			return Utils.DiscreteAngle(angle, 45)
		ORIENTATION.DPAD_4:
			return Utils.DiscreteAngle(angle, 90)
	return angle


func _attack() -> void:
	if Time.get_unix_time_from_system() - _last_attack_time < attack_cooldown:
		return

	_last_attack_time = Time.get_unix_time_from_system()
	_set_state(STATE.ATTACKING)


func _spawn_attack_scene() -> void:
	if attack_scene == null:
		return

	var spawn_position = attack_spawn_point.global_position if attack_spawn_point != null else global_position
	var spawn_rotation = attack_spawn_point.global_rotation if attack_spawn_point != null else global_rotation
	var spawned_attack = attack_scene.instantiate() as Attack
	get_tree().root.add_child(spawned_attack)
	spawned_attack.global_position = spawn_position
	spawned_attack.global_rotation = spawn_rotation
	spawned_attack.attack_owner = self

func _can_move() -> bool:
	return _state == STATE.IDLE
