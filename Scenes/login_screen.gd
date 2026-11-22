extends Control
# Single entry screen: one backdrop, the selected cat operative, player name, and Start Game.

const BG = preload("res://Assets/sofai4h.png")
const BGM = preload("res://Assets/Gar.mp3")
const SFX = preload("res://Assets/Start.mp3")

var name_edit: LineEdit
var character_name_label: Label
var preview_container: SubViewportContainer
var preview_viewport: SubViewport
var preview_camera: Camera3D
var login_card: PanelContainer
var login_title: Label
var login_hint: Label
var start_button: Button
var sfx_player: AudioStreamPlayer
var start_requested := false

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	theme = ThemeManager.theme
	_build_background()
	_setup_audio()
	_build_character_preview()
	_build_login_card()
	_layout_login()

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_layout_login()

func _build_background() -> void:
	var bg := TextureRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.texture = BG
	bg.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	var shade := ColorRect.new()
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	shade.color = Color(0.025, 0.015, 0.05, 0.20)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(shade)

func _setup_audio() -> void:
	var bgm := AudioStreamPlayer.new()
	bgm.stream = BGM
	bgm.autoplay = true
	bgm.volume_db = -8.0
	add_child(bgm)

	sfx_player = AudioStreamPlayer.new()
	sfx_player.stream = SFX
	add_child(sfx_player)

func _build_character_preview() -> void:
	preview_container = SubViewportContainer.new()
	preview_container.set_anchors_preset(Control.PRESET_CENTER_RIGHT)
	preview_container.offset_left = -510
	preview_container.offset_right = -20
	preview_container.offset_top = -310
	preview_container.offset_bottom = 120
	preview_container.stretch = true
	preview_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(preview_container)

	preview_viewport = SubViewport.new()
	preview_viewport.size = Vector2i(490, 430)
	preview_viewport.transparent_bg = true
	preview_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	preview_container.add_child(preview_viewport)

	var world := Node3D.new()
	preview_viewport.add_child(world)

	preview_camera = Camera3D.new()
	preview_camera.position = Vector3(0, 1.45, 4.5)
	preview_camera.fov = 36.0
	preview_camera.current = true
	world.add_child(preview_camera)

	var key_light := DirectionalLight3D.new()
	key_light.rotation_degrees = Vector3(-35, -25, 0)
	key_light.light_energy = 1.2
	world.add_child(key_light)

	var purple_fill := OmniLight3D.new()
	purple_fill.position = Vector3(-2.2, 2.0, 2.0)
	purple_fill.light_color = ThemeManager.COL_PURPLE
	purple_fill.light_energy = 1.5
	purple_fill.omni_range = 9.0
	world.add_child(purple_fill)

	var stage := Node3D.new()
	world.add_child(stage)

	var pet := CatCharacterBuilder.build_cat_pet()
	pet.position = Vector3(-0.72, 0.0, 0.24)
	pet.rotation_degrees.y = 210.0
	stage.add_child(pet)

	var hero := CatCharacterBuilder.build_cat_soldier(PlayerData.selected_character, PlayerData.selected_weapon)
	hero.position = Vector3(0.12, 0.0, 0.0)
	hero.rotation.y = PI
	stage.add_child(hero)

	character_name_label = Label.new()
	character_name_label.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	character_name_label.offset_left = -520
	character_name_label.offset_top = 112
	character_name_label.offset_right = -44
	character_name_label.offset_bottom = 150
	character_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	character_name_label.add_theme_font_size_override("font_size", 17)
	character_name_label.add_theme_color_override("font_color", ThemeManager.COL_PURPLE_2)
	character_name_label.add_theme_color_override("font_shadow_color", ThemeManager.COL_DARK)
	character_name_label.add_theme_constant_override("shadow_outline_size", 2)
	character_name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(character_name_label)
	_refresh_character_name()

func _build_login_card() -> void:
	login_card = PanelContainer.new()
	login_card.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	login_card.offset_left = -514
	login_card.offset_top = -260
	login_card.offset_right = -32
	login_card.offset_bottom = -26
	login_card.add_theme_stylebox_override("panel", ThemeManager.panel_stylebox(18, 0.96))
	add_child(login_card)

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 8)
	login_card.add_child(col)

	login_title = Label.new()
	login_title.text = "PLAYER PROFILE"
	login_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	login_title.add_theme_font_size_override("font_size", 23)
	login_title.add_theme_color_override("font_color", ThemeManager.COL_PURPLE_2)
	col.add_child(login_title)

	login_hint = Label.new()
	login_hint.text = "Choose your name to enter the lobby"
	login_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	login_hint.add_theme_font_size_override("font_size", 13)
	login_hint.add_theme_color_override("font_color", ThemeManager.COL_TEXT_DIM)
	col.add_child(login_hint)

	name_edit = LineEdit.new()
	name_edit.placeholder_text = "PLAYER NAME"
	name_edit.text = PlayerData.username if PlayerData.username != "Guest" else ""
	name_edit.max_length = 16
	name_edit.alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_edit.custom_minimum_size = Vector2(0, 44)
	name_edit.text_submitted.connect(func(_text: String) -> void: _on_start())
	col.add_child(name_edit)

	start_button = Button.new()
	start_button.text = "START GAME"
	start_button.custom_minimum_size = Vector2(0, 56)
	start_button.add_theme_font_size_override("font_size", 23)
	start_button.tooltip_text = "Save your name and open the lobby"
	start_button.pressed.connect(_on_start)
	col.add_child(start_button)

func _layout_login() -> void:
	if not is_instance_valid(preview_container) or not is_instance_valid(login_card):
		return
	var viewport_size := get_viewport_rect().size
	var compact := viewport_size.x < 900.0 or viewport_size.y < 520.0
	if compact:
		preview_container.set_anchors_preset(Control.PRESET_TOP_RIGHT)
		preview_container.offset_left = -380
		preview_container.offset_right = -16
		preview_container.offset_top = 12
		preview_container.offset_bottom = minf(250.0, viewport_size.y - 210.0)
		preview_viewport.size = Vector2i(364, maxi(138, int(preview_container.offset_bottom - preview_container.offset_top)))
		preview_camera.fov = 46.0
		login_card.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
		login_card.offset_left = 16
		login_card.offset_top = -202
		login_card.offset_right = 304
		login_card.offset_bottom = -16
		login_title.add_theme_font_size_override("font_size", 20)
		login_hint.add_theme_font_size_override("font_size", 12)
		name_edit.custom_minimum_size.y = 40
		start_button.custom_minimum_size.y = 48
		start_button.add_theme_font_size_override("font_size", 20)
	else:
		preview_container.set_anchors_preset(Control.PRESET_CENTER_RIGHT)
		preview_container.offset_left = -510
		preview_container.offset_right = -20
		preview_container.offset_top = -310
		preview_container.offset_bottom = 120
		preview_viewport.size = Vector2i(490, 430)
		preview_camera.fov = 36.0
		login_card.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
		login_card.offset_left = -514
		login_card.offset_top = -260
		login_card.offset_right = -32
		login_card.offset_bottom = -26
		login_title.add_theme_font_size_override("font_size", 23)
		login_hint.add_theme_font_size_override("font_size", 13)
		name_edit.custom_minimum_size.y = 44
		start_button.custom_minimum_size.y = 56
		start_button.add_theme_font_size_override("font_size", 23)
	character_name_label.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	character_name_label.offset_left = -376 if compact else -520
	character_name_label.offset_top = 12 if compact else 112
	character_name_label.offset_right = -16 if compact else -44
	character_name_label.offset_bottom = 42 if compact else 150
	character_name_label.add_theme_font_size_override("font_size", 13 if compact else 17)

func _refresh_character_name() -> void:
	var skin: Dictionary = CatCharacterBuilder.HERO_SKINS.get(PlayerData.selected_character, CatCharacterBuilder.HERO_SKINS["purple"])
	character_name_label.text = str(skin["name"]).to_upper() + "  ·  CAT OPERATIVE"

func _on_start() -> void:
	if start_requested:
		return
	start_requested = true
	if start_button:
		start_button.disabled = true
	var player_name := name_edit.text.strip_edges()
	if not player_name.is_empty():
		PlayerData.username = player_name
		PlayerData.save_data()
	if sfx_player:
		sfx_player.play()
	await get_tree().create_timer(0.25).timeout
	get_tree().change_scene_to_file("res://Scenes/Lobby.tscn")
