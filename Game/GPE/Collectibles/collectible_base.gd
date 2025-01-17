class_name CollectibleBase extends Node


func on_collect() -> void:
	pass

func _on_body_entered(body:Node2D) -> void:
	if !body is Player:
		return

	on_collect()
	queue_free()
