extends Node

func _ready() -> void:
	self.visible = false
	SignalBus.game_ended.connect(_on_game_ended)
	
func _on_game_ended() -> void:
	self.visible = true
	self.modulate = Color(1,1,1,0)
	get_tree().create_tween().tween_property(self, "modulate", Color.WHITE, 1)
