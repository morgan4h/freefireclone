extends Control

func _on_timer_timeout() -> void:
	# Switch to the loading screen
	SceneManager.change_scene("res://scenes/loading_screen.tscn")
