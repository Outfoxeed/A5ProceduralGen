extends CollectibleBase

func on_collect() -> void:
	super()
	Player.Instance.give_speed_buff()
