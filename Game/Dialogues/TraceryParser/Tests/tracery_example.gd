extends Node

func _ready():
	const FILE_PATH = "res://Game/Dialogues/TraceryParser/Tests/dialogues.json"
	for i in range( 0, 5 ):
		print(TraceryHelpers.simple_generation(FILE_PATH, "sentence"))
