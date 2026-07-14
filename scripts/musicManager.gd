extends Node

@onready var music_player: AudioStreamPlayer = AudioStreamPlayer.new()

var current_track: AudioStream = null

func _ready() -> void:
	add_child(music_player)
	music_player.bus = "Music"


func play_music(track: AudioStream) -> void:
	if track == null:
		return
		
	if current_track == track and music_player.playing:
		return
		
	current_track = track
	music_player.stream = track
	music_player.play()
	
func stop_music() -> void:
	music_player.stop()
	current_track = null
