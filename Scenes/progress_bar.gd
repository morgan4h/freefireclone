extends ProgressBar

func _ready() -> void:
	# Ensure min and max values are set correctly in the Inspector (0 to 100)
	value = 0.0
	
	# Animate the progress bar value from 0 to 100 over 3 seconds
	var tween = create_tween()
	tween.tween_property(self, "value", 100.0, 3.0)
