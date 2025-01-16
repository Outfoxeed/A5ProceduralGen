extends Node2D

func _ready() -> void:
	var a : Dictionary = TraceryParser.parse_dialogues()
