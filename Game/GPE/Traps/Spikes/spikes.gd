extends Area2D


func _on_body_entered(body:Node2D) -> void:
	if Player.Instance == null:
		return
	
	if body != Player.Instance:
		return

	Player.Instance.apply_hit(null)
