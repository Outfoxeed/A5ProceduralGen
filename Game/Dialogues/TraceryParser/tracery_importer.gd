class_name TraceryImporter extends RefCounted 

const PATH = "res://Resources/Dialogues/dialogues.json"
static var result : Dictionary

static func parse_dialogues() -> Dictionary:
	if result.size() > 0:
		return result
	
	if not FileAccess.file_exists(PATH):
		push_error("File JSON doesn't exist")
		return {}
	
	var file = FileAccess.open(PATH, FileAccess.READ)
	var text = file.get_as_text()
	var parsed_text = JSON.parse_string(text)
	
	if parsed_text == null || parsed_text is not Dictionary:
		push_error("Parsed JSON is null")
		return {}
	
	result = parsed_text
	return parsed_text
	
