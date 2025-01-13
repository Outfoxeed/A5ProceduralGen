extends CollectibleBase


func on_collect() -> void:
	super()
	Player.Instance.life += 1