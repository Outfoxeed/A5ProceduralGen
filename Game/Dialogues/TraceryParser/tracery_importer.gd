class_name TraceryImporter extends RefCounted 

static func parse_dialogues_from_file(file_path: String) -> Dictionary:
	if not FileAccess.file_exists(file_path):
		push_error("File JSON doesn't exist")
		return {}
	var file = FileAccess.open(file_path, FileAccess.READ)
	return parse_dialogues_from_text(file.get_as_text())
	
static func parse_dialogues_from_text(text: String) -> Dictionary:
	var parsed_text = JSON.parse_string(text)
	
	if parsed_text == null || parsed_text is not Dictionary:
		push_error("Parsed JSON text is null")
		return {}
	return parsed_text
	
	
