class_name CameraFollow extends Node2D


@export var lerp_speed : float = 5.0

var _bounds : Rect2 = Rect2(Vector2.ZERO, Vector2.INF)
var _target_position : Vector2 = Vector2.ZERO
var _target : Node2D = null


func _ready() -> void:
	position = _target_position
	_target = Player.Instance


func _process(delta: float) -> void:
	refresh_target_position()
	position = lerp(position, _target_position, delta * lerp_speed)


func set_bounds(bounds : Rect2) -> void:
	var cam = get_viewport().get_camera_2d()
	var cam_size = 	get_viewport().get_visible_rect().size / cam.zoom
	cam_size = Vector2(min(cam_size.x, bounds.size.x), min(cam_size.y, bounds.size.y))
	_bounds = bounds.grow_individual(-cam_size.x / 2, -cam_size.y / 2, -cam_size.x / 2, -cam_size.y / 2)
	_target_position = keep_in_bounds(_target_position)


func snap_to_target() -> void:
	refresh_target_position()
	position = _target_position


func refresh_target_position() -> void:
	if _target == null:
		return
	_target_position = keep_in_bounds(_target.position)


func keep_in_bounds(point : Vector2) -> Vector2:
	if !_bounds.has_point(point):
		point = Utils.get_closest_point_rect2(_bounds, point)
	return point
