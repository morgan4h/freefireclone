extends Control
# SOFAI 4H Lobby — dark hangar / purple-neon identity.
# Background: ffa.png (the garage/stadium art). Purple primary, cyan secondary, amber accent.

const BG_ART  = preload("res://Assets/ffa.png")   # hangar + stadium art

var mode := "br"
var preview_root: Node3D
var toast: Label
var toast_timer := 0.0
var mode_cards: Dictionary = {}
var username_label: Label
var level_label: Label
var xp_bar: ProgressBar
var coins_label: Label
var diamonds_label: Label

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	theme = ThemeManager.theme
	_build_background()
	_build_topbar()
	_build_preview()
	_build_left_nav()
	_build_right_nav()
	_build_mode_selector()
	_build_start_button()
	_build_toast()
	_refresh_profile()
	_select_mode("br")

func _process(delta: float) -> void:
	if preview_root:
		preview_root.rotate_y(delta * 0.55)
	if toast_timer > 0.0:
		toast_timer -= delta
		if toast_timer <= 0.0:
			toast.visible = false
		elif toast_timer < 0.5:
			toast.modulate.a = toast_timer / 0.5

# ============================ Background ============================
func _build_background() -> void:
	# Base dark fill
	var base := ColorRect.new()
	base.set_anchors_preset(Control.PRESET_FULL_RECT)
	base.color = ThemeManager.COL_BG
	add_child(base)

	# Background art — the garage/stadium image
	var art := TextureRect.new()
	art.set_anchors_preset(Control.PRESET_FULL_RECT)
	art.texture = BG_ART
	art.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	art.modulate.a = 0.55          # subtle — UI stays readable
	add_child(art)

	# Dark-to-transparent gradient overlay (top darker, center more open)
	var top_dim := ColorRect.new()
	top_dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	top_dim.color = Color(ThemeManager.COL_BG.r, ThemeManager.COL_BG.g, ThemeManager.COL_BG.b, 0.52)
	add_child(top_dim)

	# Purple neon accent strip at the very top
	var strip := ColorRect.new()
	strip.anchor_left   = 0.0; strip.anchor_top    = 0.0
	strip.anchor_right  = 1.0; strip.anchor_bottom = 0.0
	strip.offset_top    = 0;   strip.offset_bottom = 3
	strip.color = ThemeManager.COL_PURPLE
	add_child(strip)

	# Amber accent strip at the very bottom
	var bstrip := ColorRect.new()
	bstrip.anchor_left   = 0.0; bstrip.anchor_top    = 1.0
	bstrip.anchor_right  = 1.0; bstrip.anchor_bottom = 1.0
	bstrip.offset_top    = -3;  bstrip.offset_bottom = 0
	bstrip.color = ThemeManager.COL_AMBER
	add_child(bstrip)

# ============================ Top bar ============================
func _build_topbar() -> void:
	var bar := HBoxContainer.new()
	bar.anchor_left   = 0.0; bar.anchor_top    = 0.0
	bar.anchor_right  = 1.0; bar.anchor_bottom = 0.0
	bar.offset_left   = 20;  bar.offset_top    = 12
	bar.offset_right  = -20; bar.offset_bottom = 80
	bar.add_theme_constant_override("separation", 14)
	add_child(bar)

	# Avatar badge
	var avatar := PanelContainer.new()
	avatar.custom_minimum_size = Vector2(52, 52)
	var asb := StyleBoxFlat.new()
	asb.bg_color = ThemeManager.COL_PURPLE
	asb.set_corner_radius_all(26)
	asb.shadow_color = Color(ThemeManager.COL_PURPLE.r, ThemeManager.COL_PURPLE.g,
			ThemeManager.COL_PURPLE.b, 0.6)
	asb.shadow_size = 10
	avatar.add_theme_stylebox_override("panel", asb)
	var init_lbl := Label.new()
	init_lbl.text = PlayerData.username.substr(0, 1).to_upper() if PlayerData.username.length() > 0 else "?"
	init_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	init_lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	init_lbl.add_theme_font_size_override("font_size", 24)
	init_lbl.add_theme_color_override("font_color", ThemeManager.COL_DARK)
	avatar.add_child(init_lbl)
	bar.add_child(avatar)

	# Profile text stack
	var prof := VBoxContainer.new()
	prof.add_theme_constant_override("separation", 3)
	prof.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	username_label = Label.new()
	username_label.add_theme_font_size_override("font_size", 20)
	username_label.add_theme_color_override("font_color", ThemeManager.COL_TEXT)
	prof.add_child(username_label)
	var lvl_row := HBoxContainer.new()
	lvl_row.add_theme_constant_override("separation", 10)
	level_label = Label.new()
	level_label.add_theme_color_override("font_color", ThemeManager.COL_PURPLE_2)
	level_label.add_theme_font_size_override("font_size", 15)
	lvl_row.add_child(level_label)
	xp_bar = ProgressBar.new()
	xp_bar.min_value = 0.0
	xp_bar.max_value = 100.0
	xp_bar.custom_minimum_size = Vector2(150, 8)
	xp_bar.show_percentage = false
	xp_bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var xf := StyleBoxFlat.new()
	xf.bg_color = ThemeManager.COL_PURPLE
	xf.set_corner_radius_all(4)
	xf.shadow_color = Color(ThemeManager.COL_PURPLE.r, ThemeManager.COL_PURPLE.g,
			ThemeManager.COL_PURPLE.b, 0.5)
	xf.shadow_size = 5
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

	# Currency pills
	bar.add_child(_currency_pill(ThemeManager.COL_AMBER, "coins"))
	bar.add_child(_currency_pill(ThemeManager.COL_CYAN,  "diamonds"))

	# Settings
	var gear := Button.new()
	gear.text = "⚙"
	gear.custom_minimum_size = Vector2(48, 48)
	gear.add_theme_font_size_override("font_size", 22)
	ThemeManager.ghost_button(gear)
	gear.pressed.connect(_nav_toast.bind("Settings"))
	bar.add_child(gear)

func _currency_pill(color: Color, key: String) -> Control:
	var pill := PanelContainer.new()
	var psb := ThemeManager.card_stylebox(20, 0.90)
	pill.add_theme_stylebox_override("panel", psb)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	var dot := Panel.new()
	dot.custom_minimum_size = Vector2(16, 16)
	var dsb := StyleBoxFlat.new()
	dsb.bg_color = color
	dsb.set_corner_radius_all(8)
	dsb.shadow_color = Color(color.r, color.g, color.b, 0.5)
	dsb.shadow_size = 5
	dot.add_theme_stylebox_override("panel", dsb)
	row.add_child(dot)
	var lbl := Label.new()
	lbl.add_theme_font_size_override("font_size", 16)
	lbl.add_theme_color_override("font_color", ThemeManager.COL_TEXT)
	row.add_child(lbl)
	pill.add_child(row)
	if key == "coins":
		coins_label = lbl
	else:
		diamonds_label = lbl
	return pill

func _refresh_profile() -> void:
	if username_label: username_label.text = PlayerData.username
	if level_label:    level_label.text    = "Lv. %d" % PlayerData.level
	if xp_bar:         xp_bar.value        = PlayerData.xp_progress() * 100.0
	if coins_label:    coins_label.text    = str(PlayerData.coins)
	if diamonds_label: diamonds_label.text = str(PlayerData.diamonds)

# ============================ Character preview ============================
func _build_preview() -> void:
	var container := SubViewportContainer.new()
	container.set_anchors_preset(Control.PRESET_CENTER)
	container.offset_left   = -200
	container.offset_right  =  200
	container.offset_top    = -260
	container.offset_bottom =  200
	container.stretch = true
	add_child(container)

	var vp := SubViewport.new()
	vp.transparent_bg = true
	vp.size = Vector2i(400, 460)
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	container.add_child(vp)

	var world := Node3D.new()
	vp.add_child(world)

	var cam := Camera3D.new()
	cam.position = Vector3(0, 1.7, 5.5)
	cam.fov = 36
	cam.current = true
	world.add_child(cam)

	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-48, -30, 0)
	light.position = Vector3(0.5, 4.0, 3.0)
	light.light_energy = 1.1
	world.add_child(light)

	# Purple fill light from the left (neon hangar feel)
	var fill := OmniLight3D.new()
	fill.position = Vector3(-3, 2, 2)
	fill.light_color = ThemeManager.COL_PURPLE
	fill.light_energy = 1.8
	fill.omni_range = 12.0
	world.add_child(fill)

	# Cyan rim from behind-right
	var rim := OmniLight3D.new()
	rim.position = Vector3(2, 1.5, -2)
	rim.light_color = ThemeManager.COL_CYAN
	rim.light_energy = 1.2
	rim.omni_range = 10.0
	world.add_child(rim)

	var env_node := WorldEnvironment.new()
	var env := Environment.new()
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.25, 0.18, 0.40)
	env.ambient_light_energy = 0.6
	env_node.environment = env
	world.add_child(env_node)

	preview_root = Node3D.new()
	world.add_child(preview_root)

	# Body — purple suit matching the cat-girl aesthetic
	var body := MeshInstance3D.new()
	var bm := CapsuleMesh.new()
	bm.radius = 0.42
	bm.height = 1.25
	body.mesh = bm
	var bmat := StandardMaterial3D.new()
	bmat.albedo_color = ThemeManager.COL_PURPLE
	bmat.emission_enabled = true
	bmat.emission = ThemeManager.COL_PURPLE
	bmat.emission_energy_multiplier = 0.15
	body.material_override = bmat
	body.position.y = 0.9
	preview_root.add_child(body)

	# Head
	var head := MeshInstance3D.new()
	var hm := SphereMesh.new()
	hm.radius = 0.28
	head.mesh = hm
	var hmat := StandardMaterial3D.new()
	hmat.albedo_color = Color(0.95, 0.78, 0.62)
	head.material_override = hmat
	head.position.y = 1.76
	preview_root.add_child(head)

	# Cat ears (two small cones as spheres sitting above the head)
	for side in [-1, 1]:
		var ear := MeshInstance3D.new()
		var em := SphereMesh.new()
		em.radius = 0.11
		em.height = 0.22
		ear.mesh = em
		var emat := StandardMaterial3D.new()
		emat.albedo_color = ThemeManager.COL_PURPLE
		emat.emission_enabled = true
		emat.emission = ThemeManager.COL_PURPLE
		emat.emission_energy_multiplier = 0.3
		ear.material_override = emat
		ear.position = Vector3(side * 0.22, 2.08, 0.0)
		preview_root.add_child(ear)

	# Weapon
	var gun := MeshInstance3D.new()
	var gm := BoxMesh.new()
	gm.size = Vector3(0.12, 0.17, 0.68)
	gun.mesh = gm
	var gmat := StandardMaterial3D.new()
	gmat.albedo_color = Color(0.14, 0.11, 0.20)
	gmat.emission_enabled = true
	gmat.emission = ThemeManager.COL_PURPLE
	gmat.emission_energy_multiplier = 0.25
	gun.material_override = gmat
	gun.position = Vector3(0.30, 1.12, -0.34)
	preview_root.add_child(gun)

	# Ground ring — purple neon circle
	var ring := MeshInstance3D.new()
	var rm := TorusMesh.new()
	rm.inner_radius = 0.56
	rm.outer_radius = 0.70
	ring.mesh = rm
	ring.rotation.x = PI / 2.0
	ring.position.y = 0.04
	var rmat := StandardMaterial3D.new()
	rmat.albedo_color = ThemeManager.COL_PURPLE
	rmat.emission_enabled = true
	rmat.emission = ThemeManager.COL_PURPLE
	rmat.emission_energy_multiplier = 1.2
	ring.material_override = rmat
	preview_root.add_child(ring)

# ============================ Navigation ============================
func _build_left_nav() -> void:
	var nav := VBoxContainer.new()
	nav.set_anchors_preset(Control.PRESET_CENTER_LEFT)
	nav.offset_left   = 20
	nav.offset_right  = 174
	nav.offset_top    = -150
	nav.offset_bottom =  150
	nav.add_theme_constant_override("separation", 10)
	add_child(nav)
	for lbl in ["STORE", "LUCK ROYALE", "VAULT", "CLAN"]:
		var b := Button.new()
		b.text = lbl
		b.custom_minimum_size = Vector2(154, 44)
		ThemeManager.ghost_button(b)
		b.pressed.connect(_nav_toast.bind(lbl))
		nav.add_child(b)

func _build_right_nav() -> void:
	var nav := VBoxContainer.new()
	nav.set_anchors_preset(Control.PRESET_CENTER_RIGHT)
	nav.offset_left   = -174
	nav.offset_right  = -20
	nav.offset_top    = -150
	nav.offset_bottom =  150
	nav.add_theme_constant_override("separation", 10)
	add_child(nav)
	for lbl in ["FRIENDS", "MESSAGES", "PROFILE", "RANKED"]:
		var b := Button.new()
		b.text = lbl
		b.custom_minimum_size = Vector2(154, 44)
		ThemeManager.ghost_button(b)
		b.pressed.connect(_nav_toast.bind(lbl))
		nav.add_child(b)

func _nav_toast(label: String) -> void:
	_toast(label + " — coming soon")

# ============================ Mode selector ============================
func _build_mode_selector() -> void:
	var row := HBoxContainer.new()
	row.anchor_left   = 0.0; row.anchor_top    = 1.0
	row.anchor_right  = 1.0; row.anchor_bottom = 1.0
	row.offset_left   = 220; row.offset_top    = -122
	row.offset_right  = -300; row.offset_bottom = -28
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 20)
	add_child(row)
	row.add_child(_mode_card("br",    "BATTLE ROYALE",  "50 players · last one standing"))
	row.add_child(_mode_card("clash", "CLASH SQUAD",    "10 players · fast skirmish"))

func _mode_card(key: String, title: String, sub: String) -> Control:
	var card := Button.new()
	card.custom_minimum_size = Vector2(230, 94)
	card.text = ""
	ThemeManager.ghost_button(card)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 3)
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var t := Label.new()
	t.text = title
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t.add_theme_font_size_override("font_size", 18)
	t.add_theme_color_override("font_color", ThemeManager.COL_TEXT)
	var s := Label.new()
	s.text = sub
	s.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	s.add_theme_font_size_override("font_size", 12)
	s.add_theme_color_override("font_color", ThemeManager.COL_TEXT_DIM)
	col.add_child(t)
	col.add_child(s)
	card.add_child(col)
	card.pressed.connect(_select_mode.bind(key))
	mode_cards[key] = card
	return card

func _select_mode(key: String) -> void:
	mode = key
	for k in mode_cards.keys():
		var c: Button = mode_cards[k]
		var sel := String(k) == key
		var sb := StyleBoxFlat.new()
		if sel:
			sb.bg_color     = Color(0.22, 0.14, 0.38, 0.95)
			sb.border_color = ThemeManager.COL_PURPLE
			sb.set_border_width_all(2)
			sb.shadow_color = Color(ThemeManager.COL_PURPLE.r, ThemeManager.COL_PURPLE.g,
					ThemeManager.COL_PURPLE.b, 0.5)
			sb.shadow_size = 8
		else:
			sb.bg_color     = Color(0.102, 0.078, 0.161, 0.88)
			sb.border_color = ThemeManager.COL_DIVIDER
			sb.set_border_width_all(1)
		sb.set_corner_radius_all(10)
		sb.set_content_margin_all(14)
		c.add_theme_stylebox_override("normal", sb)
		c.add_theme_stylebox_override("hover",  sb)

# ============================ Start button ============================
func _build_start_button() -> void:
	var start := Button.new()
	start.anchor_left   = 1.0; start.anchor_top    = 1.0
	start.anchor_right  = 1.0; start.anchor_bottom = 1.0
	start.offset_left   = -270; start.offset_top    = -106
	start.offset_right  = -24;  start.offset_bottom = -28
	start.text = "DROP IN"
	start.add_theme_font_size_override("font_size", 26)
	# Override with a bigger purple neon button
	var sb := StyleBoxFlat.new()
	sb.bg_color = ThemeManager.COL_PURPLE
	sb.set_corner_radius_all(10)
	sb.set_content_margin_all(16)
	sb.shadow_color = Color(ThemeManager.COL_PURPLE.r, ThemeManager.COL_PURPLE.g,
			ThemeManager.COL_PURPLE.b, 0.75)
	sb.shadow_size = 14
	sb.shadow_offset = Vector2(0, 4)
	var sbh := StyleBoxFlat.new()
	sbh.bg_color = ThemeManager.COL_PURPLE_2
	sbh.set_corner_radius_all(10)
	sbh.set_content_margin_all(16)
	sbh.shadow_color = Color(ThemeManager.COL_PURPLE.r, ThemeManager.COL_PURPLE.g,
			ThemeManager.COL_PURPLE.b, 0.9)
	sbh.shadow_size = 18
	start.add_theme_stylebox_override("normal",  sb)
	start.add_theme_stylebox_override("hover",   sbh)
	start.add_theme_stylebox_override("pressed", _pressed_sb())
	start.pressed.connect(_on_start)
	add_child(start)

func _pressed_sb() -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = ThemeManager.COL_PURPLE_DK
	sb.set_corner_radius_all(10)
	sb.set_content_margin_all(16)
	return sb

func _on_start() -> void:
	GameManager.reset_match(mode)
	get_tree().change_scene_to_file("res://Scenes/BattleMap.tscn")

# ============================ Toast ============================
func _build_toast() -> void:
	toast = Label.new()
	toast.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	toast.offset_top    = -68
	toast.offset_bottom = -38
	toast.add_theme_font_size_override("font_size", 16)
	toast.add_theme_color_override("font_color", ThemeManager.COL_AMBER)
	toast.visible = false
	add_child(toast)

func _toast(text: String) -> void:
	toast.text = text
	toast.visible = true
	toast.modulate.a = 1.0
	toast_timer = 2.4
