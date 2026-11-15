extends Node

@export var music_track: AudioStreamMP3 = preload("res://assets/sounds/music.mp3")
@export var shot_sound: AudioStream = preload("res://assets/sounds/shoot.mp3")
@export var pickup_sound: AudioStream = preload("res://assets/sounds/reload.mp3")

@onready var music: AudioStreamPlayer = $music
@onready var shoot: AudioStreamPlayer = $shoot
@onready var pickup: AudioStreamPlayer = $pickup


func _ready() -> void:
	music_track.loop = true
	music.stream = music_track
	shoot.stream = shot_sound
	pickup.stream = pickup_sound
	shoot.max_polyphony = 4
	music.play()


func play_shot() -> void:
	shoot.play()


func play_pickup() -> void:
	pickup.play()


func set_music_volume(percent: float) -> void:
	_set_volume(&"Music", percent)


func set_sfx_volume(percent: float) -> void:
	_set_volume(&"SFX", percent)


func _set_volume(bus_name: StringName, percent: float) -> void:
	var bus := AudioServer.get_bus_index(bus_name)
	if bus == -1:
		return

	var volume := clampf(percent / 100.0, 0.0, 1.0)
	AudioServer.set_bus_mute(bus, volume == 0.0)
	AudioServer.set_bus_volume_linear(bus, maxf(volume, 0.0001))
