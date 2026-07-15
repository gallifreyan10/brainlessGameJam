extends Node


func play_sfx(sound: AudioStream, volume_db: float = 0.0) -> void:
	if sound == null:
		return
		
	var player := AudioStreamPlayer.new()
	add_child(player)
	
	player.bus = "SFX"
	player.stream = sound
	player.volume_db = volume_db
	player.play()
	
	player.finished.connect(
		func() -> void: player.queue_free()
)
