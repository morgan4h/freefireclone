extends Control
# SOFAI 4H login screen — brand art background, purple card, callsign input.

const BG  = preload("res://Assets/sofai4h.png")   # skydive art as main backdrop
const BGM = preload("res://Assets/Gar.mp3")
const SFX = preload("res://Assets/Start.mp3")

var name_edit: LineEdit
var sfx_player: AudioStreamPlayer

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	theme = ThemeManager.theme

	# Full-screen background art
	var bg := TextureRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.texture = BG
	bg.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	add_child(bg)

	# Dark vignette — heavier at the bottom where the card sits
	var dim := ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.027, 0.016, 0.047, 0.55)
	add_child(dim)

	# Music
	var bgm := AudioStreamPlayer.new()
	bgm.stream = BGM
	bgm.autoplay = true
	bgm.volume_db = -6.0
	add_child(bgm)
	sfx_player = AudioStreamPlayer.new()
	sfx_player.stream = SFX
	add_child(sfx_player)

	# Brand wordmark — top left, matching the game art
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
	sub.offset_bottom = 134
	sub.add_theme_font_size_override("font_size", 15)
	sub.add_theme_color_override("font_color", ThemeManager.COL_CYAN)
	add_child(sub)

	# Login card — centered, slight right offset so it doesn't cover the character
	var card := PanelContainer.new()
	card.set_anchors_preset(Control.PRESET_CENTER_RIGHT)
	card.offset_left   = -310
	card.offset_right  = -48
	card.offset_top    = -180
	card.offset_bottom =  180
	var csb := ThemeManager.panel_stylebox(16, 0.94)
	card.add_theme_stylebox_override("panel", csb)
	add_child(card)

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 18)
	card.add_child(col)

	# Purple accent top bar on the card
	var accent_bar := ColorRect.new()
	accent_bar.custom_minimum_size = Vector2(0, 4)
	accent_bar.color = ThemeManager.COL_PURPLE
	col.add_child(accent_bar)

	var title := Label.new()
	title.text = "ENTER THE ARENA"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 26)
	title.add_theme_color_override("font_color", ThemeManager.COL_PURPLE_2)
	col.add_child(title)

	var hint := Label.new()
	hint.text = "Choose your callsign"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 14)
	hint.add_theme_color_override("font_color", ThemeManager.COL_TEXT_DIM)
	col.add_child(hint)

	name_edit = LineEdit.new()
	name_edit.placeholder_text = "Callsign"
	name_edit.text = PlayerData.username if PlayerData.username != "Guest" else ""
	name_edit.alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_edit.custom_minimum_size = Vector2(0, 46)
	col.add_child(name_edit)

	var start := Button.new()
	start.text = "DROP IN"
	start.custom_minimum_size = Vector2(0, 54)
	start.add_theme_font_size_override("font_size", 22)
	start.pressed.connect(_on_start)
	col.add_child(start)

	var ver := Label.new()
	ver.text = "v1.0  ·  SOFAI 4H"
	ver.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ver.add_theme_font_size_override("font_size", 12)
	ver.add_theme_color_override("font_color", ThemeManager.COL_TEXT_DIM)
	col.add_child(ver)

	name_edit.text_submitted.connect(func(_s: String) -> void: _on_start())

	# Fade the card in
	card.modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(card, "modulate:a", 1.0, 0.5)

func _on_start() -> void:
	var n := name_edit.text.strip_edges()
	if n.length() > 0:
		PlayerData.username = n
		PlayerData.save_data()
	if sfx_player:
		sfx_player.play()
	await get_tree().create_timer(0.4).timeout
	SceneManager.change_scene("res://Scenes/Lobby.tscn")
