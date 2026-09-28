extends Button

const NEXT_SCENE_PATH = "res://scenes/home_page.tscn"
@onready var audio_player: AudioStreamPlayer2D = $"../StartSound"

func _ready() -> void:
	# Connect the button's pressed signal to our function
	pressed.connect(_on_pressed)

func _on_pressed() -> void:
	# Play the sound effect first
	audio_player.play()
	
	# Wait for the audio to finish playing before changing scenes
	await audio_player.finished
	
	# Change to the new scene
	get_tree().change_scene_to_file(NEXT_SCENE_PATH)
