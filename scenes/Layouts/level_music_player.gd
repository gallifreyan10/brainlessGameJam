extends Sprite2D

@export var level_music: AudioStream

func _ready() -> void:
	MusicManager.play_music(level_music)
