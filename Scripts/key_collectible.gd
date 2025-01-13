extends CollectibleBase


func on_collect() -> void:
	super()
	Player.Instance.key_count += 1


func _on_body_entered(body:Node2D) -> void:
	super(body)
