extends Control
# SOFAI 4H — Free Fire Battle Royale Lobby
# Authentic Free Fire layout inspired by reference screenshots:
# Center 3D stage with 3D Cat Operative & Cat Pet, Left Free Fire icon drawer
# (STORE, LUCK ROYALE, CHARACTER, VAULT, PET, WEAPON), Weapon Loadout wall,
# Top currency banner (Coins & Diamonds), and Bottom-Right Golden START button.

const BG_ART = preload("res://Assets/ffa.png")
const BGM    = preload("res://Assets/Gar.mp3")
const SFX    = preload("res://Assets/Start.mp3")

var mode := "br"
var preview_viewport: SubViewport
var preview_container: SubViewportContainer
var preview_stage: Node3D
var char_instance: Node3D
var pet_instance: Node3D
var preview_dragging := false
var character_yaw := PI
const PREVIEW_DRAG_SENSITIVITY := 0.012
const PREVIEW_KEY_TURN := PI / 12.0

var toast: Label
var toast_timer := 0.0

# UI Controls
var username_label: Label
var avatar_label: Label
var level_label: Label
var xp_bar: ProgressBar
var coins_label: Label
var diamonds_label: Label
var mode_label: Label
var mode_sub_label: Label
var char_panel: PanelContainer
var weapon_panel: PanelContainer
var nav_buttons: Dictionary = {}
var character_buttons: Dictionary = {}
var weapon_buttons: Dictionary = {}
var bgm_player: AudioStreamPlayer
var sfx_player: AudioStreamPlayer

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	theme = ThemeManager.theme

	_setup_audio()
	_build_background()
	_build_topbar()
	_build_3d_showcase()
	_build_left_freefire_menu()
	_build_character_drawer()
	_build_weapon_drawer()
	_build_bottom_start_area()
	_build_toast()
	_refresh_profile()
	_update_mode_ui()

func _setup_audio() -> void:
	bgm_player = AudioStreamPlayer.new()
	bgm_player.stream = BGM
	bgm_player.volume_db = -8.0
	bgm_player.autoplay = true
	add_child(bgm_player)

	sfx_player = AudioStreamPlayer.new()
	sfx_player.stream = SFX
	add_child(sfx_player)

func _process(delta: float) -> void:
	var turn_axis := 0.0
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		turn_axis += 1.0
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		turn_axis -= 1.0
	if turn_axis != 0.0:
		_rotate_character(turn_axis * delta * 1.8)

	# Tail wagging and breathing
	if char_instance:
		var tail = char_instance.get_node_or_null("Torso/TailRoot")
		if tail:
			tail.rotation_degrees.y = sin(Time.get_ticks_msec() * 0.003) * 16.0
		var torso = char_instance.get_node_or_null("Torso")
		if torso:
			torso.position.y = 0.92 + sin(Time.get_ticks_msec() * 0.0025) * 0.012

	if pet_instance:
		var ptail = pet_instance.get_node_or_null("PetTail")
		if ptail:
			ptail.rotation_degrees.z = sin(Time.get_ticks_msec() * 0.005) * 24.0

	if toast_timer > 0.0:
		toast_timer -= delta
		if toast_timer <= 0.0:
			toast.visible = false
		elif toast_timer < 0.5:
			toast.modulate.a = toast_timer / 0.5

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and preview_dragging:
		_rotate_character(-event.relative.x * PREVIEW_DRAG_SENSITIVITY)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		preview_dragging = false

func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	match event.physical_keycode:
		KEY_LEFT, KEY_A:
			_rotate_character(PREVIEW_KEY_TURN)
		KEY_RIGHT, KEY_D:
			_rotate_character(-PREVIEW_KEY_TURN)

func _rotate_character(amount: float) -> void:
	if not char_instance or not is_instance_valid(char_instance):
		return
	character_yaw = wrapf(character_yaw + amount, -PI, PI)
	char_instance.rotation.y = character_yaw

func _on_preview_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		preview_dragging = event.pressed

func _turn_preview_step(direction: float) -> void:
	_rotate_character(direction * PREVIEW_KEY_TURN)
	SFXSynthesizer.play_sound(self, "click", -8.0)

# ============================ Background Art ============================
func _build_background() -> void:
	var base := ColorRect.new()
	base.set_anchors_preset(Control.PRESET_FULL_RECT)
	base.color = ThemeManager.COL_BG
	add_child(base)

	var art := TextureRect.new()
	art.set_anchors_preset(Control.PRESET_FULL_RECT)
	art.texture = BG_ART
	art.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	art.modulate.a = 0.60
	add_child(art)

	var dim := ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(ThemeManager.COL_BG.r, ThemeManager.COL_BG.g, ThemeManager.COL_BG.b, 0.40)
	add_child(dim)

	var top_strip := ColorRect.new()
	top_strip.anchor_left = 0.0; top_strip.anchor_top = 0.0
	top_strip.anchor_right = 1.0; top_strip.anchor_bottom = 0.0
	top_strip.offset_bottom = 3
	top_strip.color = ThemeManager.COL_PURPLE
	add_child(top_strip)

	var bot_strip := ColorRect.new()
	bot_strip.anchor_left = 0.0; bot_strip.anchor_top = 1.0
	bot_strip.anchor_right = 1.0; bot_strip.anchor_bottom = 1.0
	bot_strip.offset_top = -3
	bot_strip.color = ThemeManager.COL_PURPLE_2
	add_child(bot_strip)

# ============================ Free Fire Top Bar ============================
func _build_topbar() -> void:
	var shell := PanelContainer.new()
	shell.anchor_left = 0.0; shell.anchor_top = 0.0
	shell.anchor_right = 1.0; shell.anchor_bottom = 0.0
	shell.offset_left = 18; shell.offset_top = 12
	shell.offset_right = -18; shell.offset_bottom = 82
	shell.add_theme_stylebox_override("panel", ThemeManager.card_stylebox(16, 0.92))
	shell.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(shell)

	var bar := HBoxContainer.new()
	bar.custom_minimum_size = Vector2(0, 62)
	bar.add_theme_constant_override("separation", 14)
	shell.add_child(bar)

	# Avatar badge
	var avatar := PanelContainer.new()
	avatar.custom_minimum_size = Vector2(54, 54)
	var asb := StyleBoxFlat.new()
	asb.bg_color = ThemeManager.COL_PURPLE
	asb.border_color = ThemeManager.COL_PURPLE_2
	asb.set_border_width_all(1)
	asb.set_corner_radius_all(6)
	asb.shadow_color = Color(ThemeManager.COL_PURPLE.r, ThemeManager.COL_PURPLE.g, ThemeManager.COL_PURPLE.b, 0.6)
	asb.shadow_size = 8
	avatar.add_theme_stylebox_override("panel", asb)
	avatar_label = Label.new()
	avatar_label.text = "S"
	avatar_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	avatar_label.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	avatar_label.add_theme_font_size_override("font_size", 24)
	avatar_label.add_theme_color_override("font_color", ThemeManager.COL_TEXT)
	avatar.add_child(avatar_label)
	bar.add_child(avatar)

	# Profile Info
	var prof := VBoxContainer.new()
	prof.add_theme_constant_override("separation", 2)
	prof.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	username_label = Label.new()
	username_label.add_theme_font_size_override("font_size", 19)
	username_label.add_theme_color_override("font_color", ThemeManager.COL_TEXT)
	prof.add_child(username_label)

	var lvl_row := HBoxContainer.new()
	lvl_row.add_theme_constant_override("separation", 8)
	level_label = Label.new()
	level_label.add_theme_color_override("font_color", ThemeManager.COL_PURPLE_2)
	level_label.add_theme_font_size_override("font_size", 14)
	lvl_row.add_child(level_label)

	xp_bar = ProgressBar.new()
	xp_bar.min_value = 0.0
	xp_bar.max_value = 100.0
	xp_bar.custom_minimum_size = Vector2(140, 7)
	xp_bar.show_percentage = false
	xp_bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var xf := StyleBoxFlat.new()
	xf.bg_color = ThemeManager.COL_PURPLE
	xf.set_corner_radius_all(4)
	var xbg := StyleBoxFlat.new()
	xbg.bg_color = ThemeManager.COL_PANEL_2
	xbg.set_corner_radius_all(4)
	xp_bar.add_theme_stylebox_override("fill", xf)
	xp_bar.add_theme_stylebox_override("background", xbg)
	lvl_row.add_child(xp_bar)
	prof.add_child(lvl_row)
	bar.add_child(prof)

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.add_child(spacer)

	# Currency Badges (Coins & Diamonds)
	bar.add_child(_currency_pill(ThemeManager.COL_AMBER, "coins", "🪙"))
	bar.add_child(_currency_pill(ThemeManager.COL_CYAN,  "diamonds", "💎"))

	var gear := Button.new()
	gear.text = "⚙"
	gear.custom_minimum_size = Vector2(44, 44)
	gear.add_theme_font_size_override("font_size", 20)
	ThemeManager.ghost_button(gear)
	gear.pressed.connect(_nav_toast.bind("Settings"))
	bar.add_child(gear)

func _currency_pill(color: Color, key: String, icon: String) -> Control:
	var pill := PanelContainer.new()
	pill.add_theme_stylebox_override("panel", ThemeManager.card_stylebox(18, 0.92))
	pill.custom_minimum_size = Vector2(94 if key == "coins" else 112, 50)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 0)
	pill.add_child(col)
	var title := Label.new()
	title.text = "COINS" if key == "coins" else "DIAMONDS"
	title.add_theme_font_size_override("font_size", 9)
	title.add_theme_color_override("font_color", ThemeManager.COL_TEXT_DIM)
	col.add_child(title)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 5)
	var ic := Label.new()
	ic.text = icon
	ic.add_theme_font_size_override("font_size", 14)
	ic.add_theme_color_override("font_color", color)
	row.add_child(ic)
	var lbl := Label.new()
	lbl.add_theme_font_size_override("font_size", 16)
	lbl.add_theme_color_override("font_color", ThemeManager.COL_TEXT)
	row.add_child(lbl)
	col.add_child(row)
	if key == "coins":
		coins_label = lbl
	else:
		diamonds_label = lbl
	return pill

func _refresh_profile() -> void:
	if username_label:
		username_label.text = PlayerData.username.left(16)
		username_label.tooltip_text = PlayerData.username
	if avatar_label:
		avatar_label.text = PlayerData.username.substr(0, 1).to_upper() if not PlayerData.username.is_empty() else "S"
	if level_label:    level_label.text    = "Lv. %d" % PlayerData.level
	if xp_bar:         xp_bar.value        = PlayerData.xp_progress() * 100.0
	if coins_label:    coins_label.text    = str(PlayerData.coins)
	if diamonds_label: diamonds_label.text = str(PlayerData.diamonds)

# ============================ 3D Pedestal Showcase ============================
func _build_3d_showcase() -> void:
	preview_container = SubViewportContainer.new()
	preview_container.set_anchors_preset(Control.PRESET_CENTER)
	preview_container.offset_left   = -270
	preview_container.offset_right  =  270
	preview_container.offset_top    = -230
	preview_container.offset_bottom =  190
	preview_container.stretch = true
	preview_container.mouse_default_cursor_shape = Control.CURSOR_MOVE
	preview_container.gui_input.connect(_on_preview_gui_input)
	add_child(preview_container)

	preview_viewport = SubViewport.new()
	preview_viewport.transparent_bg = true
	preview_viewport.size = Vector2i(540, 420)
	preview_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	preview_container.add_child(preview_viewport)

	var world := Node3D.new()
	preview_viewport.add_child(world)

	var cam := Camera3D.new()
	cam.position = Vector3(0, 1.45, 4.4)
	cam.fov = 34
	cam.current = true
	world.add_child(cam)

	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-42, -28, 0)
	light.light_energy = 1.2
	world.add_child(light)

	var fill := OmniLight3D.new()
	fill.position = Vector3(-2.8, 1.8, 1.8)
	fill.light_color = ThemeManager.COL_PURPLE
	fill.light_energy = 2.0
	fill.omni_range = 10.0
	world.add_child(fill)

	var rim := OmniLight3D.new()
	rim.position = Vector3(2.5, 1.6, -2.0)
	rim.light_color = ThemeManager.COL_CYAN
	rim.light_energy = 1.6
	rim.omni_range = 8.0
	world.add_child(rim)

	var env_node := WorldEnvironment.new()
	var env := Environment.new()
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.24, 0.18, 0.36)
	env.ambient_light_energy = 0.65
	env_node.environment = env
	world.add_child(env_node)

	preview_stage = Node3D.new()
	world.add_child(preview_stage)

	pet_instance = CatCharacterBuilder.build_cat_pet()
	pet_instance.position = Vector3(-0.72, 0.0, 0.28)
	pet_instance.rotation_degrees.y = 215.0
	preview_stage.add_child(pet_instance)

	_refresh_3d_operative()
	_build_preview_controls()

func _build_preview_controls() -> void:
	var dock := PanelContainer.new()
	dock.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	dock.offset_left = -166
	dock.offset_top = -178
	dock.offset_right = 166
	dock.offset_bottom = -126
	dock.add_theme_stylebox_override("panel", ThemeManager.card_stylebox(18, 0.95))
	dock.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(dock)

	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 8)
	dock.add_child(row)

	var left := Button.new()
	left.text = "‹"
	left.tooltip_text = "Turn character left (A or Left Arrow)"
	left.custom_minimum_size = Vector2(38, 36)
	left.add_theme_font_size_override("font_size", 22)
	left.focus_mode = Control.FOCUS_NONE
	ThemeManager.ghost_button(left)
	left.pressed.connect(_turn_preview_step.bind(1.0))
	row.add_child(left)

	var hint := Label.new()
	hint.text = "DRAG TO TURN  ·  A/D OR ARROWS"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 11)
	hint.add_theme_color_override("font_color", ThemeManager.COL_TEXT_DIM)
	row.add_child(hint)

	var right := Button.new()
	right.text = "›"
	right.tooltip_text = "Turn character right (D or Right Arrow)"
	right.custom_minimum_size = Vector2(38, 36)
	right.add_theme_font_size_override("font_size", 22)
	right.focus_mode = Control.FOCUS_NONE
	ThemeManager.ghost_button(right)
	right.pressed.connect(_turn_preview_step.bind(-1.0))
	row.add_child(right)

func _refresh_3d_operative() -> void:
	if char_instance and is_instance_valid(char_instance):
		char_instance.queue_free()

	char_instance = CatCharacterBuilder.build_cat_soldier(PlayerData.selected_character, PlayerData.selected_weapon)
	char_instance.position = Vector3(0.08, 0.0, 0.0)
	char_instance.rotation.y = character_yaw
	preview_stage.add_child(char_instance)
	_refresh_drawer_selection()

# ============================ Left Free Fire Menu ============================
func _build_left_freefire_menu() -> void:
	var nav := VBoxContainer.new()
	nav.anchor_left = 0.0; nav.anchor_top = 0.5
	nav.anchor_right = 0.0; nav.anchor_bottom = 0.5
	nav.offset_left = 20; nav.offset_top = -174
	nav.offset_right = 180; nav.offset_bottom = 174
	nav.add_theme_constant_override("separation", 7)
	add_child(nav)

	var items = [
		{"label": "STORE",       "icon": "🛒"},
		{"label": "LUCK ROYALE", "icon": "🎰"},
		{"label": "CHARACTER",   "icon": "🐱"},
		{"label": "VAULT",       "icon": "🎒"},
		{"label": "PET",         "icon": "🐾"},
		{"label": "WEAPON",      "icon": "🔫"},
	]

	for it in items:
		var btn := Button.new()
		btn.text = "%s  %s" % [it["icon"], it["label"]]
		btn.custom_minimum_size = Vector2(156, 46)
		btn.add_theme_font_size_override("font_size", 13)
		ThemeManager.ghost_button(btn)
		nav_buttons[it["label"]] = btn

		if it["label"] == "CHARACTER":
			btn.pressed.connect(_toggle_character_drawer)
		elif it["label"] == "WEAPON":
			btn.pressed.connect(_toggle_weapon_drawer)
		elif it["label"] == "PET":
			btn.pressed.connect(func(): _toast("Kitty 4H Companion is Active on Stage!"))
		else:
			btn.pressed.connect(_nav_toast.bind(it["label"]))

		nav.add_child(btn)

func _nav_toast(label: String) -> void:
	SFXSynthesizer.play_sound(self, "click", 0.0)
	_toast(label + " — Active in current build")

# ============================ Character & Weapon Drawers ============================
func _build_character_drawer() -> void:
	char_panel = PanelContainer.new()
	char_panel.anchor_left = 0.0; char_panel.anchor_top = 0.5
	char_panel.anchor_right = 0.0; char_panel.anchor_bottom = 0.5
	char_panel.offset_left = 175; char_panel.offset_top = -130
	char_panel.offset_right = 360; char_panel.offset_bottom = 110
	char_panel.add_theme_stylebox_override("panel", ThemeManager.panel_stylebox(14, 0.95))
	add_child(char_panel)
	char_panel.visible = false

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	char_panel.add_child(vbox)

	var header := Label.new()
	header.text = "SELECT CAT OPERATIVE"
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header.add_theme_font_size_override("font_size", 13)
	header.add_theme_color_override("font_color", ThemeManager.COL_PURPLE_2)
	vbox.add_child(header)

	var characters = [
		{"key": "purple", "name": "SOFAI", "sub": "Neon Shadow (Purple)"},
		{"key": "red",    "name": "CRIMSON", "sub": "Fire Claw (Red)"},
		{"key": "blue",   "name": "COBALT", "sub": "Ghost Hunter (Blue)"}
	]

	for c in characters:
		var btn := Button.new()
		btn.text = "%s\n%s" % [c["name"], c["sub"]]
		btn.custom_minimum_size = Vector2(0, 48)
		btn.add_theme_font_size_override("font_size", 13)
		ThemeManager.ghost_button(btn)
		btn.set_meta("base_text", btn.text)
		character_buttons[c["key"]] = btn
		btn.pressed.connect(_select_character.bind(c["key"]))
		vbox.add_child(btn)
	_refresh_drawer_selection()

func _toggle_character_drawer() -> void:
	char_panel.visible = not char_panel.visible
	if char_panel.visible and weapon_panel:
		weapon_panel.visible = false
	_update_nav_selection()
	SFXSynthesizer.play_sound(self, "click", -8.0)

func _select_character(key: String) -> void:
	PlayerData.selected_character = key
	PlayerData.save_data()
	SFXSynthesizer.play_sound(self, "click", 2.0)
	_refresh_3d_operative()
	_refresh_drawer_selection()
	_toast("Equipped " + CatCharacterBuilder.HERO_SKINS[key]["name"])

func _build_weapon_drawer() -> void:
	weapon_panel = PanelContainer.new()
	weapon_panel.anchor_left = 1.0; weapon_panel.anchor_top = 0.5
	weapon_panel.anchor_right = 1.0; weapon_panel.anchor_bottom = 0.5
	weapon_panel.offset_left = -220; weapon_panel.offset_top = -140
	weapon_panel.offset_right = -20; weapon_panel.offset_bottom = 120
	weapon_panel.add_theme_stylebox_override("panel", ThemeManager.panel_stylebox(14, 0.95))
	add_child(weapon_panel)
	weapon_panel.visible = false

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	weapon_panel.add_child(vbox)

	var header := Label.new()
	header.text = "WEAPON SHOWCASE"
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header.add_theme_font_size_override("font_size", 13)
	header.add_theme_color_override("font_color", ThemeManager.COL_PURPLE_2)
	vbox.add_child(header)

	var weapons = [
		{"key": "ak47",  "name": "AK47",  "desc": "Assault Rifle"},
		{"key": "mp40",  "name": "MP40",  "desc": "Submachine Gun"},
		{"key": "awm",   "name": "AWM",   "desc": "Sniper Rifle"},
		{"key": "m1887", "name": "M1887", "desc": "Double Shotgun"}
	]

	for w in weapons:
		var btn := Button.new()
		btn.text = "%s  —  %s" % [w["name"], w["desc"]]
		btn.custom_minimum_size = Vector2(0, 42)
		btn.add_theme_font_size_override("font_size", 12)
		ThemeManager.ghost_button(btn)
		btn.set_meta("base_text", btn.text)
		weapon_buttons[w["key"]] = btn
		btn.pressed.connect(_select_weapon.bind(w["key"]))
		vbox.add_child(btn)
	_refresh_drawer_selection()

func _toggle_weapon_drawer() -> void:
	weapon_panel.visible = not weapon_panel.visible
	if weapon_panel.visible and char_panel:
		char_panel.visible = false
	_update_nav_selection()
	SFXSynthesizer.play_sound(self, "click", -8.0)

func _select_weapon(key: String) -> void:
	PlayerData.selected_weapon = key
	PlayerData.save_data()
	SFXSynthesizer.play_sound(self, key, 0.0)
	_refresh_3d_operative()
	_refresh_drawer_selection()
	_toast("Equipped " + key.to_upper())

func _refresh_drawer_selection() -> void:
	for key in character_buttons:
		var btn: Button = character_buttons[key]
		var selected: bool = key == PlayerData.selected_character
		btn.text = ("✓  " if selected else "") + str(btn.get_meta("base_text"))
		_set_button_selected_style(btn, selected)
	for key in weapon_buttons:
		var btn: Button = weapon_buttons[key]
		var selected: bool = key == PlayerData.selected_weapon
		btn.text = ("✓  " if selected else "") + str(btn.get_meta("base_text"))
		_set_button_selected_style(btn, selected)

func _update_nav_selection() -> void:
	if nav_buttons.has("CHARACTER"):
		_set_button_selected_style(nav_buttons["CHARACTER"], char_panel.visible)
	if nav_buttons.has("WEAPON"):
		_set_button_selected_style(nav_buttons["WEAPON"], weapon_panel.visible)

func _set_button_selected_style(button: Button, selected: bool) -> void:
	if not selected:
		ThemeManager.ghost_button(button)
		return
	var active := StyleBoxFlat.new()
	active.bg_color = Color(ThemeManager.COL_PURPLE.r, ThemeManager.COL_PURPLE.g, ThemeManager.COL_PURPLE.b, 0.30)
	active.border_color = ThemeManager.COL_PURPLE
	active.set_border_width_all(1)
	active.set_corner_radius_all(10)
	active.set_content_margin_all(10)
	active.shadow_color = Color(ThemeManager.COL_PURPLE.r, ThemeManager.COL_PURPLE.g, ThemeManager.COL_PURPLE.b, 0.32)
	active.shadow_size = 7
	button.add_theme_stylebox_override("normal", active)

# ============================ Bottom Mode & Golden START Button ============================
func _build_bottom_start_area() -> void:
	# Mode Selection Card (Bottom-Right, adjacent to START)
	var mode_card := Button.new()
	mode_card.anchor_left = 1.0; mode_card.anchor_top = 1.0
	mode_card.anchor_right = 1.0; mode_card.anchor_bottom = 1.0
	mode_card.offset_left = -530; mode_card.offset_top = -106
	mode_card.offset_right = -270; mode_card.offset_bottom = -26
	mode_card.tooltip_text = "Click to switch between Battle Royale and Clash Squad"
	ThemeManager.ghost_button(mode_card)

	var mv := VBoxContainer.new()
	mv.alignment = BoxContainer.ALIGNMENT_CENTER
	mv.add_theme_constant_override("separation", 2)
	mv.mouse_filter = Control.MOUSE_FILTER_IGNORE

	mode_label = Label.new()
	mode_label.text = "BATTLE ROYALE"
	mode_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	mode_label.add_theme_font_size_override("font_size", 17)
	mode_label.add_theme_color_override("font_color", ThemeManager.COL_PURPLE_2)

	mode_sub_label = Label.new()
	mode_sub_label.text = "Bermuda Island (Plane Drop)"
	mode_sub_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	mode_sub_label.add_theme_font_size_override("font_size", 11)
	mode_sub_label.add_theme_color_override("font_color", ThemeManager.COL_TEXT_DIM)

	mv.add_child(mode_label)
	mv.add_child(mode_sub_label)
	mode_card.add_child(mv)
	mode_card.pressed.connect(_toggle_mode)
	add_child(mode_card)

	# Golden Free Fire START Button (Like reference images 1, 2, 5!)
	var start := Button.new()
	start.anchor_left = 1.0; start.anchor_top = 1.0
	start.anchor_right = 1.0; start.anchor_bottom = 1.0
	start.offset_left = -250; start.offset_top = -112
	start.offset_right = -20;  start.offset_bottom = -22
	start.text = "▶  START"
	start.add_theme_font_size_override("font_size", 30)
	start.tooltip_text = "Start the selected game mode"

	var sb := StyleBoxFlat.new()
	sb.bg_color = ThemeManager.COL_PURPLE
	sb.border_color = ThemeManager.COL_PURPLE_2
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(12)
	sb.set_content_margin_all(14)
	sb.shadow_color = Color(ThemeManager.COL_PURPLE.r, ThemeManager.COL_PURPLE.g, ThemeManager.COL_PURPLE.b, 0.75)
	sb.shadow_size = 16
	sb.shadow_offset = Vector2(0, 3)

	var sbh := StyleBoxFlat.new()
	sbh.bg_color = ThemeManager.COL_PURPLE_2
	sbh.border_color = ThemeManager.COL_TEXT
	sbh.set_border_width_all(1)
	sbh.set_corner_radius_all(10)
	sbh.set_content_margin_all(14)
	sbh.shadow_color = Color(ThemeManager.COL_PURPLE.r, ThemeManager.COL_PURPLE.g, ThemeManager.COL_PURPLE.b, 0.95)
	sbh.shadow_size = 18
	var sbp := StyleBoxFlat.new()
	sbp.bg_color = ThemeManager.COL_PURPLE_DK
	sbp.border_color = ThemeManager.COL_PURPLE_2
	sbp.set_border_width_all(1)
	sbp.set_corner_radius_all(12)
	sbp.set_content_margin_all(14)

	start.add_theme_stylebox_override("normal",  sb)
	start.add_theme_stylebox_override("hover",   sbh)
	start.add_theme_stylebox_override("pressed", sbp)
	start.add_theme_stylebox_override("focus", sbh)
	start.add_theme_color_override("font_color", ThemeManager.COL_TEXT)
	start.add_theme_color_override("font_hover_color", ThemeManager.COL_TEXT)
	start.pressed.connect(_on_start)
	add_child(start)

func _toggle_mode() -> void:
	mode = "clash" if mode == "br" else "br"
	_update_mode_ui()
	SFXSynthesizer.play_sound(self, "click", 0.0)

func _update_mode_ui() -> void:
	if mode == "br":
		mode_label.text = "BATTLE ROYALE"
		mode_sub_label.text = "Bermuda Island (Plane Drop)"
		mode_label.add_theme_color_override("font_color", ThemeManager.COL_PURPLE_2)
	else:
		mode_label.text = "CLASH SQUAD"
		mode_sub_label.text = "5v5 Tactical Skirmish"
		mode_label.add_theme_color_override("font_color", ThemeManager.COL_PURPLE_2)

func _on_start() -> void:
	if sfx_player:
		sfx_player.play()
	GameManager.reset_match(mode)
	await get_tree().create_timer(0.35).timeout
	get_tree().change_scene_to_file("res://Scenes/BattleMap.tscn")

# ============================ Toast ============================
func _build_toast() -> void:
	toast = Label.new()
	toast.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	toast.offset_top = -68; toast.offset_bottom = -38
	toast.add_theme_font_size_override("font_size", 17)
	toast.add_theme_color_override("font_color", ThemeManager.COL_PURPLE_2)
	toast.visible = false
	add_child(toast)

func _toast(text: String) -> void:
	toast.text = text
	toast.visible = true
	toast.modulate.a = 1.0
	toast_timer = 2.4
