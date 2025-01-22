extends Node2D

@export var pnj : QuestPNJ
@export var quest_generator : QuestGenerator

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pnj.quest = quest_generator.generate_quest()
