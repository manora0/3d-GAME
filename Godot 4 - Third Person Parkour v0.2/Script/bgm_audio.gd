extends Node3D

@export var bgm_audio1 : AudioStreamPlayer
@export var bgm_audio2 : AudioStreamPlayer

var audio_test_01 : AudioStream = preload("res://Sound/Bgm sound 01.mp3")
var audio_test_02 : AudioStream = preload("res://Sound/Bgm sound 02.mp3")

# Called when the node enters the scene tree for the first time.
func _ready():
	bgm_audio1.set_stream(audio_test_01)
	bgm_audio2.set_stream(audio_test_02)
	bgm_audio1.play()
	bgm_audio2.play()
	pass # Replace with function body.


func _on_bgm_finished():
	bgm_audio1.play()
	bgm_audio2.play()
	pass # Replace with function body.
