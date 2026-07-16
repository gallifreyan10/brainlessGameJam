extends Area2D

signal mineralCaptured(mineral: MineralPrize)

func _on_body_entered(body: Node2D) -> void:

	if not body is AlienPrize and not body is MineralPrize:
		return
	if not body.get_meta("can_score_in_chute",false):
		var parent := body.get_parent()
		
		if parent != null and parent.has_method("reset_prize"):
			parent.call_deferred("reset_prize", body)
			
		return
		
	if body is AlienPrize:
		var alien := body as AlienPrize
		
		if alien.alien_data == null:
			push_warning("Captured alien has no AlienData.")
			return
			
		if not alien.try_mark_captured():
			return
			
		var errors := alien.alien_data.get_validation_errors()
		print("Validation error count:", errors.size())
		
		for error: String in errors:
			print("VALIDATION ERROR: ", error)
			push_warning(error)
			
		AlienCollection.collect_alien(alien.alien_data)
		alien.queue_free()
		return
		
	var mineral := body as MineralPrize
	
	if mineral.mineral_data == null:
		push_warning("Mineral entered the chute without MineralData" + mineral.name)
		return
		
	#Prevent duplicate capture events
	if not mineral.try_mark_captured():
		return
		
	var context : Dictionary = RunEconomy.build_capture_context()
	
	#Economy recieves the mineral before it is removed
	RunEconomy.capture_mineral(mineral.mineral_data, context)
	
	mineralCaptured.emit(mineral)
	mineral.queue_free()
