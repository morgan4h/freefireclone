extends Control
# SOFAI 4H loading screen — splash art background, purple progress bar, cyan tips.

const SPLASH = preload("res://Assets/sofai4h.png")

const TIPS := [
	"Parachute into the zone — pick your landing spot carefully.",
	"Headshots deal double damage. Aim above the shoulders.",
	"Open supply crates for ammo, armor, and medkits.",
	"The safe zone shrinks in phases — watch the purple ring.",
	"Last one standing wins!  SOFAI 4H — BATTLE FOR SURVIVAL.",
	"Bots fight each other too — let them thin the numbers.",
]

var bar: ProgressBar
var pct_label: Label
var tip_label: Label
var tip_index := 0
var tip_timer := 0.0

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	theme = ThemeManager.theme

	# Background art
	var bg := TextureRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.texture = SPLASH
	bg.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	add_child(bg)

	# Dark overlay so UI pops
	var dim := ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.027, 0.016, 0.047, 0.62)
	add_child(dim)

	# SOFAI 4H wordmark — top left (matches the art's logo placement)
	var brand := Label.new()
	brand.text = "SOFAI 4H"
	brand.set_anchors_preset(Control.PRESET_TOP_LEFT)
	brand.offset_left   = 52
	brand.offset_top    = 40
	brand.offset_right  = 500
	brand.offset_bottom = 110
	brand.add_theme_font_size_override("font_size", 60)
	brand.add_theme_color_override("font_color", ThemeManager.COL_TEXT)
	brand.add_theme_color_override("font_shadow_color", ThemeManager.COL_PURPLE)
	brand.add_theme_constant_override("shadow_outline_size", 4)
	add_child(brand)

	var sub := Label.new()
	sub.text = "BATTLE FOR SURVIVAL"
	sub.set_anchors_preset(Control.PRESET_TOP_LEFT)
	sub.offset_left   = 56
	sub.offset_top    = 108
	sub.offset_right  = 500
	sub.offset_bottom = 136
	sub.add_theme_font_size_override("font_size", 16)
	sub.add_theme_color_override("font_color", ThemeManager.COL_CYAN)
	add_child(sub)

	# Tip label
	tip_label = Label.new()
	tip_label.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	tip_label.offset_left   = 60
	tip_label.offset_top    = -106
	tip_label.offset_right  = -60
	tip_label.offset_bottom = -74
	tip_label.text = "TIP  " + TIPS[0]
	tip_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	tip_label.add_theme_font_size_override("font_size", 15)
	tip_label.add_theme_color_override("font_color", ThemeManager.COL_TEXT_DIM)
	add_child(tip_label)

	# Progress bar — purple neon fill
	bar = ProgressBar.new()
	bar.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	bar.offset_left   = 60
	bar.offset_top    = -68
	bar.offset_right  = -60
	bar.offset_bottom = -38
	bar.min_value = 0.0
	bar.max_value = 100.0
	bar.value = 0.0
	bar.show_percentage = false
	var fill := StyleBoxFlat.new()
	fill.bg_color = ThemeManager.COL_PURPLE
	fill.set_corner_radius_all(5)
	fill.shadow_color = Color(ThemeManager.COL_PURPLE.r, ThemeManager.COL_PURPLE.g,
			ThemeManager.COL_PURPLE.b, 0.7)
	fill.shadow_size = 7
	var bg2 := StyleBoxFlat.new()
	bg2.bg_color = Color(0.027, 0.016, 0.047, 0.75)
	bg2.border_color = ThemeManager.COL_DIVIDER
	bg2.set_border_width_all(1)
	bg2.set_corner_radius_all(6)
	bar.add_theme_stylebox_override("fill", fill)
	bar.add_theme_stylebox_override("background", bg2)
	add_child(bar)

	# Percentage label
	pct_label = Label.new()
	pct_label.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	pct_label.offset_left   = -120
	pct_label.offset_top    = -100
	pct_label.offset_right  = -60
	pct_label.offset_bottom = -72
	pct_label.text = "0%"
	pct_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	pct_label.add_theme_font_size_override("font_size", 15)
	pct_label.add_theme_color_override("font_color", ThemeManager.COL_PURPLE_2)
	add_child(pct_label)

	# Animate progress
	var tw := create_tween()
	tw.tween_property(bar, "value", 100.0, 3.8)
	tw.tween_callback(_go)

func _process(delta: float) -> void:
	if pct_label and bar:
		pct_label.text = "%d%%" % int(bar.value)
	tip_timer += delta
	if tip_timer > 2.4 and tip_label:
		tip_timer = 0.0
		tip_index = (tip_index + 1) % TIPS.size()
		tip_label.text = "TIP  " + TIPS[tip_index]

func _go() -> void:
	SceneManager.change_scene("res://Scenes/login_screen.tscn")
