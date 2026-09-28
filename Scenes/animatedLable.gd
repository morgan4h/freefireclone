extends Label

func _ready() -> void:
	# Ensure all text is set
	text = "4H ARABIC"
	
	# Start with 0 visible characters
	visible_characters = 0
	
	# Create a tween to animate visible_characters up to the total text length
	var tween = create_tween()
	var total_chars = text.length()
	
	# Animate from 0 to total_chars over 2.0 seconds
	tween.tween_property(self, "visible_characters", total_chars, 2.0)
