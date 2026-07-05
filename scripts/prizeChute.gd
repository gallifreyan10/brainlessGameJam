extends Area2D

signal mineralCaptured(mineral: MineralPrize)

func _on_body_entered(body: Node2D) -> void:
	if not body is MineralPrize:
		return
		
	var mineral := body as MineralPrize
	
	if mineral.mineral_data == null:
		push_warning("Mineral entered the chute without MineralData" + mineral.name)
		return
		
	#Prevent duplicate capture events
	if not mineral.try_mark_captured():
		return
		
	var context := RunEconomy.build_capture_context()
	
	#Economy recieves the mineral before it is removed
	RunEconomy.capture_mineral(mineral.mineral_data, context)
	
	mineralCaptured.emit(mineral)
	mineral.queue_free()
