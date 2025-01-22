class_name Quest_Recovery extends Quest

var collectible_scene : PackedScene
var collected: bool = false

var not_collected_title : String = "Trouve l'objet perdu"
var collected_title : String = "Ramène l'objet perdu à son propriétaire"

func _init(dialogues: Dictionary, wanted_room_scene: PackedScene,
	collectible_scene: PackedScene, not_collected_message: String,
	collected_message: String) -> void:
	super._init(dialogues, wanted_room_scene)
	self.collectible_scene = collectible_scene
	self.not_collected_title = not_collected_message
	self.collected_title = collected_message

func get_recap_message() -> String:
	return collected_title if collected else not_collected_title

func activate() -> void:
	super.activate()
	_spawn_collectible()
	SignalBus.player_entered_pnj_area.connect(_on_player_enetered_pnj_area)

func deactivate() -> void:
	super.deactivate()
	SignalBus.player_entered_pnj_area.disconnect(_on_player_enetered_pnj_area)
	
func _spawn_collectible() -> void:
	if spawned_room == null:
		push_error("Quest_Recovery needs a spawned room. Can't activate properly")
		return
	var collectible_node = spawned_room.request_spawn(collectible_scene, 1)[0]
	var collectible = collectible_node as CollectibleBase
	if collectible == null:
		push_error("Quest_Recovery: collectibl_scene can't be casted to CollectibleBase")
		return
	collectible.collected.connect(_on_collectible_collected)

func _on_collectible_collected() -> void:
	collected = true
	
func _on_player_enetered_pnj_area(pnj: QuestPNJ) -> void:
	if not collected: 
		return
	if pnj.quest != self:
		return
	current_state = Quest.State.FINISHED
		
	
