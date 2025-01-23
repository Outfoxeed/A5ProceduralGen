class_name Door extends Node2D

enum STATE {OPEN = 0, CLOSED = 1, WALL = 2, SECRET = 3}

@export var closedNode : Node2D
@export var openNode : Node2D
@export var wallNode : Node2D
@export var secretNode : Node2D

var orientation : Utils.ORIENTATION
var state : STATE

var _room : Room

@onready var collision = $"StaticBody2D/CollisionShape2D"


func _ready() -> void:
	var node = self
	while (node != null && !node is Room):
		node = node.get_parent()

	if node == null:
		push_error(node == null, "The door is not in any room")
		return

	_room = node
	_room.doors.push_back(self)

	var room_bounds : Rect2 = _room.get_local_bounds()
	var ratio : float = room_bounds.size.x / room_bounds.size.y
	var dir : Vector2 = position - room_bounds.get_center()

	if abs(dir.x) > abs(dir.y) * ratio:
		orientation = Utils.ORIENTATION.EAST if dir.x > 0 else Utils.ORIENTATION.WEST
	else:
		orientation = Utils.ORIENTATION.NORTH if dir.y < 0 else Utils.ORIENTATION.SOUTH

	rotation_degrees = Utils.OrientationToAngle(orientation)
	if closedNode.visible:
		set_state(STATE.CLOSED)
	elif openNode.visible:
		set_state(STATE.OPEN)
	elif wallNode.visible:
		set_state(STATE.WALL)
	elif secretNode.visible:
		set_state(STATE.SECRET)
		
	openNode.global_rotation = 0


func _try_unlock() -> void:
	if state != STATE.CLOSED:
		return

	Player.Instance.key_count -= 1
	set_state(STATE.OPEN)

	var next_room = _room.get_adjacent_room(orientation, position)
	if next_room:
		var next_door = next_room.get_door(Utils.OppositeOrientation(orientation), position)
		if next_door != null:
			next_door.set_state(STATE.OPEN)


func set_state(new_state : STATE) -> void:
	closedNode.visible = false
	openNode.visible = false
	wallNode.visible = false
	secretNode.visible = false

	state = new_state
	match state:
		STATE.CLOSED:
			closedNode.visible = true
			collision.set_deferred("disabled", false)
		STATE.OPEN:
			openNode.visible = true
			collision.set_deferred("disabled", true)
		STATE.WALL:
			wallNode.visible = true
			collision.set_deferred("disabled", false)
		STATE.SECRET:
			secretNode.visible = true
			collision.set_deferred("disabled", true)


func _on_area_2d_body_entered(body:Node2D) -> void:
	if body != Player.Instance:
		return

	if state == STATE.CLOSED:
		_try_unlock()
		
func _exit_tree() -> void:
	if _room != null:
		_room.doors.erase(self)
