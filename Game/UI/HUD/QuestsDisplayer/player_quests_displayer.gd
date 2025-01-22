extends QuestsDisplayer

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	while Player.Instance == null:
		await get_tree().create_timer(0.5).timeout
	set_quest_manager(Player.Instance.quest_manager)
