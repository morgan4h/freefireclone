extends Control
# SOFAI 4H splash — full-screen brand art fades in, title animates, then transitions.

const SPLASH = preload("res://Assets/sofai4h.png")

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	# Solid black base so fade-in works from zero
	var base := ColorRect.new()
	base.set_anchors_preset(Control.PRESET_FULL_RECT)
	base.color = Color(0.027, 0.016, 0.047, 1.0)
	add_child(base)

	# Full-screen splash image (the skydive art)
	var splash := TextureRect.new()
	splash.set_anchors_preset(Control.PRESET_FULL_RECT)
	splash.texture = SPLASH
	splash.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	splash.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	splash.modulate.a = 0.0
	add_child(splash)

	# Dark vignette so text is always readable
	var vignette := ColorRect.new()
	vignette.set_anchors_preset(Control.PRESET_FULL_RECT)
	vignette.color = Color(0.027, 0.016, 0.047, 0.42)
	add_child(vignette)

	# "SOFAI 4H" title — top-left matching the brand art logo position
	var title := Label.new()
	title.text = "SOFAI 4H"
	title.set_anchors_preset(Control.PRESET_TOP_LEFT)
	title.offset_left = 56
	title.offset_top  = 44
	title.offset_right  = 700
	title.offset_bottom = 130
	title.add_theme_font_size_override("font_size", 72)
	title.add_theme_color_override("font_color", ThemeManager.COL_TEXT)
	title.add_theme_color_override("font_shadow_color", ThemeManager.COL_PURPLE)
	title.add_theme_constant_override("shadow_outline_size", 4)
	title.add_theme_constant_override("shadow_offset_x", 0)
	title.add_theme_constant_override("shadow_offset_y", 0)
	title.modulate.a = 0.0
	add_child(title)

	# Tagline
	var tag := Label.new()
	tag.text = "BATTLE FOR SURVIVAL"
	tag.set_anchors_preset(Control.PRESET_TOP_LEFT)
	tag.offset_left   = 60
	tag.offset_top    = 128
	tag.offset_right  = 600
	tag.offset_bottom = 162
	tag.add_theme_font_size_override("font_size", 20)
	tag.add_theme_color_override("font_color", ThemeManager.COL_CYAN)
	tag.modulate.a = 0.0
	add_child(tag)

	# Purple accent bar under the title (like the lightning bolt in the logo)
	var bar := ColorRect.new()
	bar.set_anchors_preset(Control.PRESET_TOP_LEFT)
	bar.offset_left   = 56
	bar.offset_top    = 158
	bar.offset_right  = 56
	bar.offset_bottom = 164
	bar.color = ThemeManager.COL_PURPLE
	add_child(bar)

	# Animate: splash fades in, title types on, bar slides out, then we transition
	var tw := create_tween()
	tw.tween_property(splash, "modulate:a", 1.0, 0.9)
	tw.tween_property(title,  "modulate:a", 1.0, 0.5)
	tw.parallel().tween_property(tag, "modulate:a", 1.0, 0.7)
	# slide the accent bar in
	tw.tween_property(bar, "offset_right", 300.0, 0.4)
	tw.tween_interval(1.4)
	# fade everything out
	tw.tween_property(splash,   "modulate:a", 0.0, 0.5)
	tw.parallel().tween_property(title, "modulate:a", 0.0, 0.5)
	tw.parallel().tween_property(tag,   "modulate:a", 0.0, 0.5)
	tw.parallel().tween_property(bar,   "modulate:a", 0.0, 0.5)
	tw.tween_callback(_go)

func _go() -> void:
	SceneManager.change_scene("res://Scenes/loading_screen.tscn")
