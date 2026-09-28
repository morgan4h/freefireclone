extends Control

# This function runs automatically the second the loading screen opens
func _ready() -> void:
	# Wait for 4 seconds to pretend it's loading assets
	await get_tree().create_timer(4.0).timeout
	
	# Once time is up, go to the Login screen
	SceneManager.change_scene("res://scenes/login_screen.tscn")	
