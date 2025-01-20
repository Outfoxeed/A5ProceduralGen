extends Node2D

func _ready() -> void:
	var a : Dictionary = TraceryImporter.parse_dialogues()
	print("TraceryParser result: ")
	print(a as Dictionary)
	
	await get_tree().create_timer(1).timeout
	
	var b : Dictionary = TraceryImporter.parse_dialogues()
	print("TraceryParser result: ")
	print(a as Dictionary)
	
