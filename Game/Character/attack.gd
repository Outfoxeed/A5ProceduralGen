class_name Attack extends Area2D


@export var damages : int = 1
@export var has_infinite_lifetime : bool
@export var lifetime : float = 0.3
@export var knockback_speed : float = 3.0
@export var knockback_duration : float = 0.5

var attack_owner : Node


func _process(delta: float) -> void:
	if has_infinite_lifetime:
		return
		
	lifetime -= delta
	if lifetime <= 0.0:
		queue_free()


func _on_body_entered(_body:Node2D) -> void:
	if _body is CharacterBase && _body != attack_owner:
		_body.apply_hit(self)
		queue_free()
