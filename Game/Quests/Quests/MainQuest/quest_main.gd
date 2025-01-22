class_name Quest_Main extends Quest

@export var title = "Va voir le proviseur"

func _init() -> void:
	super._init({}, null)

func get_recap_message() -> String:
	return title
