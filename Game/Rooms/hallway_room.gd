class_name HallwayRoom extends Room

func delete_walls(top: bool, right: bool, down: bool, left: bool) -> void:
	var rect : Rect2i = tilemap_layers[0].get_used_rect()
	var start_cell_pos : Vector2i = rect.position
	
	if top:
		_delete_cells(start_cell_pos + Vector2i(1,0), Vector2i.RIGHT, rect.size.x - 2)
	if right:
		_delete_cells(start_cell_pos + Vector2i(rect.size.x - 1, 1), Vector2i.DOWN, rect.size.y - 2)
	if down:
		_delete_cells(start_cell_pos + Vector2i(1, rect.size.y - 1), Vector2i.RIGHT, rect.size.x - 2)
	if left:
		_delete_cells(start_cell_pos + Vector2i(0, 1), Vector2i.DOWN, rect.size.y - 2)

	# We don't want to delete the corners and so we commented out this code
	#if top and left:
		#_delete_cell(start_cell_pos)
	#if top and right:
		#_delete_cell(start_cell_pos + Vector2i(rect.size.x - 1, 0))
	#if down and left:
		#_delete_cell(start_cell_pos + Vector2i(0, rect.size.y - 1))
	#if down and right:
		#_delete_cell(start_cell_pos + rect.size - Vector2i.ONE)

func _delete_cell(cell_pos: Vector2i) -> void:
	for tilemap_layer in tilemap_layers:
		tilemap_layer.set_cell(cell_pos, door_source_id, 
		 door_atlas_coord, door_alternative_tile)
	
func _delete_cells(start: Vector2i, step: Vector2i, step_amount: int) -> void:
	for i in range(0, step_amount):
		_delete_cell(start + step * i)
