class_name TraceryHelpers extends RefCounted

static func simple_generation(text: String, flatten_key: String) -> String:
	var dict : Dictionary
	if text.begins_with("res"):
		dict = TraceryImporter.parse_dialogues_from_file(text)
	else:
		dict = TraceryImporter.parse_dialogues_from_text(text)
	
	var grammar = Tracery.Grammar.new( dict )
	grammar.add_modifiers(Tracery.UniversalModifiers.get_modifiers())
	return grammar.flatten("#" + flatten_key + "#")
