extends Node3D
# Battle Royale / Clash Squad arena. Builds the world, spawns all combatants,
# runs the shrinking zone, supply loot, the HUD, kill feed, minimap and results.

const PlayerScript = preload("res://scripts/player.gd")
const BotScript = preload("res://scripts/bot.gd")
const MinimapScript = preload("res://scripts/minimap.gd")

const BOT_NAMES := [
	"Rusher", "Sniper99", "GhostOP", "ProKiller", "NoobSlayer", "VenomX", "Blaze",
	"Falcon", "Shadow", "Viper", "Rex", "Hunter", "Storm", "Ace", "Wolf",
	"Cobra", "Havoc", "Jet", "Riot", "Echo", "Onyx", "Fury", "Drift", "Nova",
	"Zenith", "Kilo", "Bandit", "Maverick", "Phantom", "Tango", "Saber", "Vortex",
	"Reaper", "Jinx", "Hex", "Razor", "Specter", "Comet", "Goliath", "Tracer",
	"Slayer", "Bolt", "Hawk", "Fang", "Rogue", "Spark", "Titan", "Zephyr", "Bison"
]

const MAP_HALF := 56.0

var mode := "br"
var player: CharacterBody3D
var bots: Array = []
var alive_bots := 0
var result_open := false
var frozen := true

# Zone
var zone_center := Vector3.ZERO
var zone_radius := 58.0
var zone_target_radius := 58.0
var zone_shrink_start := 58.0
var zone_shrink_duration := 0.0
var zone_phase := 0
var zone_shrinking := false
var zone_phase_timer := 0.0
var zone_phases := []
var zone_ring: MeshInstance3D

# Loot
var supply_crates: Array = []
var airdrops: Array = []           # Vector3 positions for the minimap
var airdrop_timer := 30.0

# HUD
var hud: CanvasLayer
var hud_root: Control
var minimap: Control
var alive_label: Label
var kills_label: Label
var zone_label: Label
var health_bar: ProgressBar
var armor_bar: ProgressBar
var hp_label: Label
var ammo_label: Label
var reserve_label: Label
var reload_label: Label
var kill_feed: VBoxContainer
var crosshair: Crosshair
var hit_marker: HitMarker
var damage_vignette: ColorRect
var intro_label: Label
var interact_label: Label
var toast_label: Label
var toast_timer := 0.0

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	mode = GameManager.mode
	_setup_zone_config()
	_build_environment()
	_build_zone_ring()
	_build_characters()
	_build_supply_crates()
	_build_hud()
	_start_intro()

# ============================ Setup ============================
func _setup_zone_config() -> void:
	if mode == "br":
		zone_phases = [
			{"wait": 22.0, "shrink": 18.0, "radius": 42.0, "dmg": 2.0},
			{"wait": 18.0, "shrink": 15.0, "radius": 30.0, "dmg": 4.0},
			{"wait": 15.0, "shrink": 12.0, "radius": 20.0, "dmg": 6.0},
			{"wait": 13.0, "shrink": 10.0, "radius": 12.0, "dmg": 9.0},
			{"wait": 11.0, "shrink": 9.0,  "radius": 6.0,  "dmg": 12.0},
			{"wait": 9.0,  "shrink": 8.0,  "radius": 2.5,  "dmg": 16.0},
		]
		zone_radius = 58.0
		zone_phase_timer = zone_phases[0].wait
	else:
		zone_phases = []
		zone_radius = 200.0

func _build_environment() -> void:
	var world := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	sky.sky_material = ProceduralSkyMaterial.new()
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_color = Color(0.6, 0.7, 0.85)
	env.ambient_light_energy = 0.5
	env.fog_enabled = true
	env.fog_light_color = Color(0.62, 0.74, 0.88)
	env.fog_light_energy = 0.35
	env.fog_density = 0.012
	env.glow_enabled = true
	env.glow_intensity = 0.6
	world.environment = env
	add_child(world)

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-52, -28, 0)
	sun.light_energy = 1.05
	sun.shadow_enabled = true
	add_child(sun)

	# Ground
	var ground := StaticBody3D.new()
	ground.collision_layer = 1
	ground.collision_mask = 0
	var col := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(150, 1, 150)
	col.shape = box
	ground.add_child(col)
	var mesh := MeshInstance3D.new()
	var gbox := BoxMesh.new()
	gbox.size = Vector3(150, 1, 150)
	mesh.mesh = gbox
	var gmat := StandardMaterial3D.new()
	gmat.albedo_color = Color(0.24, 0.49, 0.30)
	mesh.material_override = gmat
	ground.add_child(mesh)
	ground.position.y = -0.5
	add_child(ground)

	# Buildings (cover)
	for i in range(16):
		var h := randf_range(3.5, 8.0)
		var w := randf_range(5.0, 9.0)
		var b := StaticBody3D.new()
		b.collision_layer = 1
		b.collision_mask = 0
		var sc := CollisionShape3D.new()
		var sb := BoxShape3D.new()
		sb.size = Vector3(w, h, w)
		sc.shape = sb
		b.add_child(sc)
		var mi := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = sb.size
		mi.mesh = bm
		var m := StandardMaterial3D.new()
		m.albedo_color = Color(randf_range(0.55, 0.75), randf_range(0.5, 0.65), randf_range(0.45, 0.6))
		mi.material_override = m
		b.add_child(mi)
		b.position = Vector3(randf_range(-MAP_HALF, MAP_HALF), h * 0.5, randf_range(-MAP_HALF, MAP_HALF))
		add_child(b)

	# Trees
	for i in range(22):
		var pos := Vector3(randf_range(-MAP_HALF, MAP_HALF), 0, randf_range(-MAP_HALF, MAP_HALF))
		if pos.length() < 6.0:
			continue
		var trunk := StaticBody3D.new()
		trunk.collision_layer = 1
		trunk.collision_mask = 0
		var tc := CollisionShape3D.new()
		var cyl := CylinderShape3D.new()
		cyl.radius = 0.35
		cyl.height = 3.0
		tc.shape = cyl
		trunk.add_child(tc)
		var tmi := MeshInstance3D.new()
		var tm := CylinderMesh.new()
		tm.top_radius = 0.35
		tm.bottom_radius = 0.35
		tm.height = 3.0
		tmi.mesh = tm
		var tmat := StandardMaterial3D.new()
		tmat.albedo_color = Color(0.36, 0.24, 0.14)
		tmi.material_override = tmat
		tmi.position.y = 1.5
		trunk.add_child(tmi)
		var foliage := MeshInstance3D.new()
		var fm := SphereMesh.new()
		fm.radius = 2.2
		fm.height = 4.4
		foliage.mesh = fm
		var fmat := StandardMaterial3D.new()
		fmat.albedo_color = Color(0.18, 0.42, 0.22)
		foliage.material_override = fmat
		foliage.position.y = 5.0
		trunk.add_child(foliage)
		trunk.position = pos
		add_child(trunk)

	# Rocks
	for i in range(14):
		var r := StaticBody3D.new()
		r.collision_layer = 1
		r.collision_mask = 0
		var rc := CollisionShape3D.new()
		var sph := SphereShape3D.new()
		sph.radius = randf_range(0.8, 1.8)
		rc.shape = sph
		r.add_child(rc)
		var rmi := MeshInstance3D.new()
		var rm := SphereMesh.new()
		rm.radius = sph.radius
		rm.height = sph.radius * 1.4
		rmi.mesh = rm
		var rmat := StandardMaterial3D.new()
		rmat.albedo_color = Color(0.42, 0.42, 0.46)
		rmi.material_override = rmat
		r.add_child(rmi)
		r.position = Vector3(randf_range(-MAP_HALF, MAP_HALF), sph.radius * 0.5, randf_range(-MAP_HALF, MAP_HALF))
		add_child(r)

func _build_zone_ring() -> void:
	zone_ring = MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = zone_radius - 0.6
	torus.outer_radius = zone_radius + 0.6
	zone_ring.mesh = torus
	zone_ring.rotation.x = PI / 2.0
	zone_ring.position.y = 0.08
	var mat := StandardMaterial3D.new()
	mat.albedo_color = ThemeManager.COL_PURPLE
	mat.emission_enabled = true
	mat.emission = ThemeManager.COL_PURPLE
	mat.emission_energy_multiplier = 1.4
	mat.no_depth_test = true
	zone_ring.material_override = mat
	add_child(zone_ring)

func _build_characters() -> void:
	# Player
	player = CharacterBody3D.new()
	player.set_script(PlayerScript)
	player.position = Vector3(randf_range(-34, 34), 2, randf_range(-34, 34))
	player.collision_layer = 2
	player.collision_mask = 1
	player.char_name = PlayerData.username
	_add_character_visual(player, ThemeManager.COL_PURPLE, true)
	var pc := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 0.45
	cap.height = 1.8
	pc.shape = cap
	player.add_child(pc)
	var spring := SpringArm3D.new()
	spring.name = "SpringArm3D"
	spring.spring_length = 4.2
	spring.position = Vector3(0, 1.6, 0)
	spring.collision_mask = 1
	player.add_child(spring)
	var camera := Camera3D.new()
	camera.name = "Camera3D"
	camera.fov = 75
	spring.add_child(camera)
	var ray := RayCast3D.new()
	ray.name = "RayCast3D"
	ray.target_position = Vector3(0, 0, -200)
	ray.collision_mask = 3
	ray.add_exception(player)
	camera.add_child(ray)
	player.died.connect(_on_player_died)
	player.hit_landed.connect(_on_player_hit)
	player.took_damage.connect(_on_player_took_damage)
	player.reloaded.connect(_on_player_reload)
	add_child(player)

	# Bots
	var count := GameManager.total_players - 1
	for i in range(count):
		var bot: CharacterBody3D = CharacterBody3D.new()
		bot.set_script(BotScript)
		var ang := randf() * TAU
		var r := randf_range(10.0, MAP_HALF - 4.0)
		bot.position = Vector3(cos(ang) * r, 2, sin(ang) * r)
		bot.collision_layer = 2
		bot.collision_mask = 1
		bot.char_name = BOT_NAMES[i % BOT_NAMES.size()] + str(i + 1)
		bot.zone_center = zone_center
		bot.zone_radius = zone_radius
		var hue := randf_range(0.0, 0.07)  # reddish variants
		_add_character_visual(bot, Color.from_hsv(hue, 0.75, 0.95), false)
		var bc := CollisionShape3D.new()
		var bcap := CapsuleShape3D.new()
		bcap.radius = 0.45
		bcap.height = 1.7
		bc.shape = bcap
		bot.add_child(bc)
		bot.eliminated.connect(_on_bot_eliminated)
		add_child(bot)
		bots.append(bot)
	alive_bots = bots.size()

	# Everyone can target everyone (player included).
	var everyone := bots.duplicate()
	everyone.append(player)
	for b in bots:
		b.set_enemies(everyone)

func _add_character_visual(c: CharacterBody3D, body_color: Color, is_player: bool) -> void:
	var body := MeshInstance3D.new()
	var bm := CapsuleMesh.new()
	bm.radius = 0.38
	bm.height = 1.2
	body.mesh = bm
	var bmat := StandardMaterial3D.new()
	bmat.albedo_color = body_color
	body.material_override = bmat
	body.position.y = 0.9
	c.add_child(body)
	var head := MeshInstance3D.new()
	var hm := SphereMesh.new()
	hm.radius = 0.26
	head.mesh = hm
	var hmat := StandardMaterial3D.new()
	hmat.albedo_color = Color(0.95, 0.78, 0.62)
	head.material_override = hmat
	head.position.y = 1.72
	c.add_child(head)
	var gun := MeshInstance3D.new()
	var gm := BoxMesh.new()
	gm.size = Vector3(0.12, 0.16, 0.62)
	gun.mesh = gm
	var gmat := StandardMaterial3D.new()
	gmat.albedo_color = Color(0.12, 0.13, 0.16)
	gun.material_override = gmat
	gun.position = Vector3(0.26, 1.12, -0.34)
	c.add_child(gun)
	if is_player:
		var ring := MeshInstance3D.new()
		var rm := TorusMesh.new()
		rm.inner_radius = 0.5
		rm.outer_radius = 0.62
		ring.mesh = rm
		ring.rotation.x = PI / 2.0
		ring.position.y = 0.05
		var rmat := StandardMaterial3D.new()
		rmat.albedo_color = ThemeManager.COL_PURPLE
		rmat.emission_enabled = true
		rmat.emission = ThemeManager.COL_PURPLE
		rmat.emission_energy_multiplier = 1.2
		ring.material_override = rmat
		c.add_child(ring)

func _build_supply_crates() -> void:
	for i in range(8):
		_spawn_crate(Vector3(randf_range(-MAP_HALF + 6, MAP_HALF - 6), 0.3, randf_range(-MAP_HALF + 6, MAP_HALF - 6)))

func _spawn_crate(pos: Vector3) -> void:
	var crate := MeshInstance3D.new()
	var m := BoxMesh.new()
	m.size = Vector3(0.9, 0.9, 0.9)
	crate.mesh = m
	var mat2 := StandardMaterial3D.new()
	mat2.albedo_color = ThemeManager.COL_AMBER
	mat2.emission_enabled = true
	mat2.emission = ThemeManager.COL_AMBER
	mat2.emission_energy_multiplier = 0.9
	crate.material_override = mat2
	crate.position = pos
	add_child(crate)
	supply_crates.append({"node": crate, "pos": Vector3(pos.x, 0, pos.z)})

# ============================ HUD ============================
func _build_hud() -> void:
	hud = CanvasLayer.new()
	add_child(hud)
	hud_root = Control.new()
	hud_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	hud_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud_root.theme = ThemeManager.theme
	hud.add_child(hud_root)

	# Top-left status card
	var top_left := PanelContainer.new()
	top_left.set_anchors_preset(Control.PRESET_TOP_LEFT)
	top_left.position = Vector2(20, 18)
	top_left.add_theme_stylebox_override("panel", ThemeManager.card_stylebox(12, 0.82))
	var tlv := VBoxContainer.new()
	tlv.add_theme_constant_override("separation", 4)
	top_left.add_child(tlv)
	alive_label = _label("ALIVE 50", 22, ThemeManager.COL_PURPLE_2)
	kills_label = _label("KILLS 0", 16, ThemeManager.COL_TEXT)
	zone_label  = _label("Zone shrinks in 22s", 14, ThemeManager.COL_CYAN)
	tlv.add_child(alive_label)
	tlv.add_child(kills_label)
	tlv.add_child(zone_label)
	hud_root.add_child(top_left)

	# Minimap (top-right)
	minimap = Control.new()
	minimap.set_script(MinimapScript)
	minimap.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	minimap.offset_left = -196
	minimap.offset_top = 18
	minimap.offset_right = -20
	minimap.offset_bottom = 194
	minimap.size = Vector2(176, 176)
	minimap.clip_contents = true
	minimap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud_root.add_child(minimap)

	# Kill feed (top-left, below status card)
	kill_feed = VBoxContainer.new()
	kill_feed.set_anchors_preset(Control.PRESET_TOP_LEFT)
	kill_feed.position = Vector2(20, 132)
	kill_feed.add_theme_constant_override("separation", 4)
	hud_root.add_child(kill_feed)

	# Bottom-left health stack
	var bl := VBoxContainer.new()
	bl.anchor_left = 0.0
	bl.anchor_top = 1.0
	bl.anchor_right = 0.0
	bl.anchor_bottom = 1.0
	bl.offset_left = 20
	bl.offset_top = -120
	bl.offset_right = 240
	bl.offset_bottom = -16
	bl.add_theme_constant_override("separation", 5)
	armor_bar  = _make_bar(ThemeManager.COL_CYAN,     9)
	health_bar = _make_bar(ThemeManager.COL_GREEN,   16)
	var hp_row := HBoxContainer.new()
	hp_row.add_theme_constant_override("separation", 8)
	hp_label = _label("100", 26, ThemeManager.COL_GREEN)
	hp_row.add_child(hp_label)
	var hp_cap := _label("HP", 14, ThemeManager.COL_TEXT_DIM)
	hp_cap.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	hp_row.add_child(hp_cap)
	bl.add_child(armor_bar)
	bl.add_child(health_bar)
	bl.add_child(hp_row)
	hud_root.add_child(bl)

	# Bottom-right ammo card
	var br := PanelContainer.new()
	br.anchor_left = 1.0
	br.anchor_top = 1.0
	br.anchor_right = 1.0
	br.anchor_bottom = 1.0
	br.offset_left = -196
	br.offset_top = -96
	br.offset_right = -20
	br.offset_bottom = -18
	br.add_theme_stylebox_override("panel", ThemeManager.card_stylebox(12, 0.82))
	var brv := VBoxContainer.new()
	brv.alignment = BoxContainer.ALIGNMENT_END
	brv.add_theme_constant_override("separation", 2)
	br.add_child(brv)
	var ammo_row := HBoxContainer.new()
	ammo_row.alignment = BoxContainer.ALIGNMENT_END
	ammo_row.add_theme_constant_override("separation", 4)
	ammo_label    = _label("30",    34, ThemeManager.COL_AMBER)
	reserve_label = _label("/ 120", 18, ThemeManager.COL_TEXT_DIM)
	reserve_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	ammo_row.add_child(ammo_label)
	ammo_row.add_child(reserve_label)
	reload_label = _label("RELOADING", 14, ThemeManager.COL_CYAN)
	reload_label.visible = false
	brv.add_child(ammo_row)
	brv.add_child(reload_label)
	hud_root.add_child(br)

	# Crosshair + hit marker (center)
	crosshair = Crosshair.new()
	crosshair.set_anchors_preset(Control.PRESET_CENTER)
	crosshair.offset_left = -22
	crosshair.offset_right = 22
	crosshair.offset_top = -22
	crosshair.offset_bottom = 22
	crosshair.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud_root.add_child(crosshair)
	hit_marker = HitMarker.new()
	hit_marker.set_anchors_preset(Control.PRESET_CENTER)
	hit_marker.offset_left = -26
	hit_marker.offset_right = 26
	hit_marker.offset_top = -26
	hit_marker.offset_bottom = 26
	hit_marker.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud_root.add_child(hit_marker)

	# Damage vignette
	damage_vignette = ColorRect.new()
	damage_vignette.set_anchors_preset(Control.PRESET_FULL_RECT)
	damage_vignette.color = Color(1.0, 0.06, 0.06, 0.0)
	damage_vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud_root.add_child(damage_vignette)

	# Intro countdown
	intro_label = Label.new()
	intro_label.set_anchors_preset(Control.PRESET_CENTER)
	intro_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	intro_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	intro_label.offset_left = -300
	intro_label.offset_right = 300
	intro_label.offset_top = -60
	intro_label.offset_bottom = 60
	intro_label.add_theme_font_size_override("font_size", 72)
	intro_label.add_theme_color_override("font_color", ThemeManager.COL_PURPLE_2)
	intro_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.6))
	intro_label.add_theme_constant_override("shadow_offset_x", 0)
	intro_label.add_theme_constant_override("shadow_offset_y", 4)
	intro_label.add_theme_constant_override("shadow_outline_size", 6)
	intro_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud_root.add_child(intro_label)

	# Interact prompt + toast (bottom-center)
	interact_label = _label("Press E to open supply crate", 18, ThemeManager.COL_AMBER)
	interact_label.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	interact_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	interact_label.offset_top = -130
	interact_label.offset_bottom = -98
	interact_label.visible = false
	hud_root.add_child(interact_label)
	toast_label = _label("", 18, ThemeManager.COL_PURPLE_2)
	toast_label.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	toast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	toast_label.offset_top = -92
	toast_label.offset_bottom = -60
	toast_label.visible = false
	hud_root.add_child(toast_label)

func _label(text: String, size: int, color: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.55))
	l.add_theme_constant_override("shadow_offset_x", 0)
	l.add_theme_constant_override("shadow_offset_y", 2)
	return l

func _make_bar(color: Color, h: int) -> ProgressBar:
	var bar := ProgressBar.new()
	bar.custom_minimum_size = Vector2(220, h)
	bar.min_value = 0.0
	bar.max_value = 100.0
	bar.value = 100.0
	bar.show_percentage = false
	var fill := StyleBoxFlat.new()
	fill.bg_color = color
	fill.set_corner_radius_all(4)
	fill.shadow_color = Color(color.r, color.g, color.b, 0.65)
	fill.shadow_size = 5
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.027, 0.016, 0.047, 0.78)
	bg.set_border_width_all(1)
	bg.border_color = ThemeManager.COL_DIVIDER
	bg.set_corner_radius_all(5)
	bar.add_theme_stylebox_override("fill", fill)
	bar.add_theme_stylebox_override("background", bg)
	return bar

# ============================ Intro countdown ============================
func _start_intro() -> void:
	frozen = true
	player.frozen = true
	for b in bots:
		b.frozen = true
	intro_label.visible = true
	intro_label.text = "GET READY"
	await get_tree().create_timer(1.0).timeout
	for n in ["3", "2", "1", "GO!"]:
		if not is_instance_valid(self):
			return
		intro_label.text = n
		await get_tree().create_timer(0.6).timeout
	intro_label.visible = false
	frozen = false
	if is_instance_valid(player):
		player.frozen = false
	for b in bots:
		if is_instance_valid(b):
			b.frozen = false

# ============================ Per-frame logic ============================
func _physics_process(delta: float) -> void:
	if result_open:
		return
	_update_zone(delta)
	_update_zone_ring()
	_update_supply(delta)
	_update_hud()

	if not frozen and Input.is_action_just_pressed("interact"):
		_try_open_crate()

	if alive_bots <= 0 and is_instance_valid(player) and player.alive:
		_win()
	elif is_instance_valid(player) and not player.alive and not result_open:
		_lose()

func _update_zone(delta: float) -> void:
	if mode != "br" or zone_phases.is_empty():
		return
	if zone_phase >= zone_phases.size():
		_apply_outside_damage(delta, 16.0)
		zone_label.text = "Final zone — stay inside!"
		return
	var ph: Dictionary = zone_phases[zone_phase]
	zone_phase_timer -= delta
	if not zone_shrinking:
		zone_label.text = "Zone shrinks in %ds" % maxi(0, int(ceil(zone_phase_timer)))
		if zone_phase_timer <= 0.0:
			zone_shrinking = true
			zone_target_radius = ph["radius"]
			zone_shrink_start = zone_radius
			zone_shrink_duration = ph["shrink"]
			zone_phase_timer = ph["shrink"]
			zone_label.text = "Zone closing!"
	else:
		zone_label.text = "Zone closing!"
		var t := 1.0 - clampf(zone_phase_timer / maxf(0.001, zone_shrink_duration), 0.0, 1.0)
		zone_radius = lerpf(zone_shrink_start, zone_target_radius, t)
		if zone_phase_timer <= 0.0:
			zone_radius = zone_target_radius
			zone_shrinking = false
			zone_phase += 1
			if zone_phase < zone_phases.size():
				zone_phase_timer = zone_phases[zone_phase]["wait"]
	for b in bots:
		if is_instance_valid(b):
			b.zone_radius = zone_radius
	_apply_outside_damage(delta, ph["dmg"])

func _update_zone_ring() -> void:
	if zone_ring and is_instance_valid(zone_ring):
		var torus := zone_ring.mesh as TorusMesh
		if torus:
			torus.inner_radius = maxf(0.5, zone_radius - 0.6)
			torus.outer_radius = zone_radius + 0.6

func _apply_outside_damage(delta: float, dmg: float) -> void:
	if dmg <= 0.0:
		return
	if player and player.alive:
		if _flat_dist(player.global_position, zone_center) > zone_radius:
			player.take_damage(dmg * delta, null)
	for b in bots:
		if is_instance_valid(b) and b.alive:
			if _flat_dist(b.global_position, zone_center) > zone_radius:
				b.take_damage(dmg * delta, null)

func _flat_dist(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x - b.x, a.z - b.z).length()

func _update_supply(delta: float) -> void:
	airdrop_timer -= delta
	if airdrop_timer <= 0.0:
		airdrop_timer = randf_range(28.0, 42.0)
		var drop := Vector3(randf_range(-zone_radius + 4, zone_radius - 4), 0, randf_range(-zone_radius + 4, zone_radius - 4))
		_spawn_crate(drop)
		airdrops.append(drop)
		_show_toast("Supply drop incoming!")

	# interact prompt
	var near := false
	if is_instance_valid(player) and not frozen:
		for c in supply_crates:
			if _flat_dist(player.global_position, c["pos"]) < 3.5:
				near = true
				break
	interact_label.visible = near

func _try_open_crate() -> void:
	if not is_instance_valid(player):
		return
	var idx := -1
	var best := 3.5
	for i in range(supply_crates.size()):
		var d := _flat_dist(player.global_position, supply_crates[i]["pos"])
		if d < best:
			best = d
			idx = i
	if idx < 0:
		return
	var c = supply_crates[idx]
	if is_instance_valid(c["node"]):
		c["node"].queue_free()
	supply_crates.remove_at(idx)
	var roll := randf()
	if roll < 0.45:
		player.add_ammo(60)
		_show_toast("Picked up ammo +60")
	elif roll < 0.75:
		player.add_armor(50.0)
		_show_toast("Picked up vest +50 armor")
	else:
		player.heal(35.0)
		_show_toast("Picked up medkit +35 HP")

# ============================ HUD updates ============================
func _update_hud() -> void:
	if is_instance_valid(player):
		alive_label.text = "ALIVE %d" % (alive_bots + (1 if player.alive else 0))
		kills_label.text = "KILLS %d" % GameManager.kills
		hp_label.text = str(int(round(player.health)))
		hp_label.add_theme_color_override("font_color", _hp_color(player.health))
		health_bar.value = player.health
		armor_bar.value = player.armor
		ammo_label.text = str(player.ammo)
		reserve_label.text = "/ %d" % player.reserve_ammo
		reload_label.visible = player.is_reloading
		crosshair.set_reload(player.is_reloading)
	# low-health vignette pulse
	if is_instance_valid(player):
		var low := clampf((40.0 - player.health) / 40.0, 0.0, 1.0)
		damage_vignette.color.a = maxf(damage_vignette.color.a * 0.92, low * 0.25)
	# minimap
	minimap.player = player
	minimap.bots = bots
	minimap.zone_center = zone_center
	minimap.zone_radius = zone_radius
	minimap.airdrops = airdrops
	minimap.queue_redraw()

func _hp_color(hp: float) -> Color:
	if hp > 60.0:
		return ThemeManager.COL_GREEN
	elif hp > 30.0:
		return Color(1.0, 0.75, 0.2)
	return ThemeManager.COL_RED

# ============================ Signals ============================
func _on_player_hit(_target: Node, _damage: float, headshot: bool) -> void:
	hit_marker.show_marker()
	if headshot:
		_show_toast("HEADSHOT!")

func _on_player_took_damage(amount: float, from_pos: Vector3) -> void:
	damage_vignette.color.a = minf(0.65, damage_vignette.color.a + amount * 0.012)
	# direction hint: nudge vignette toward the attacker (skip for simplicity)

func _on_player_reload() -> void:
	crosshair.set_reload(player.is_reloading)

func _on_bot_eliminated(bot: Node, killer_name: String) -> void:
	var victim_name: String = str(bot.get("char_name")) if bot != null else "enemy"
	alive_bots = maxi(0, alive_bots - 1)
	if is_instance_valid(bot):
		bot.queue_free()
	var is_player_kill := is_instance_valid(player) and killer_name == String(player.char_name)
	if is_player_kill:
		GameManager.register_kill()
		_add_kill("You", victim_name)
		_show_toast("Knocked out %s" % victim_name)
	else:
		_add_kill(killer_name, victim_name)
	bots.erase(bot)

func _on_player_died() -> void:
	if result_open:
		return
	var killer: String = player.last_attacker_name
	if killer == "":
		killer = "the zone"
	_add_kill(killer, "You")
	GameManager.placement = alive_bots + 1

func _add_kill(killer: String, victim: String) -> void:
	var entry := Label.new()
	entry.text = "%s  >  %s" % [killer, victim]
	entry.add_theme_font_size_override("font_size", 14)
	var sb := ThemeManager.card_stylebox(8, 0.78)
	sb.set_content_margin_all(8)
	sb.content_margin_left = 10
	sb.content_margin_right = 10
	entry.add_theme_stylebox_override("normal", sb)
	kill_feed.add_child(entry)
	while kill_feed.get_child_count() > 5:
		var old := kill_feed.get_child(0)
		kill_feed.remove_child(old)
		old.queue_free()
	# fade + auto-free after a short delay
	var tw := create_tween()
	tw.tween_interval(3.0)
	tw.tween_property(entry, "modulate:a", 0.0, 1.2)
	tw.tween_callback(entry.queue_free)

# ============================ Toast ============================
func _show_toast(text: String) -> void:
	toast_label.text = text
	toast_label.visible = true
	toast_label.modulate.a = 1.0
	toast_timer = 2.2

func _process(delta: float) -> void:
	if toast_timer > 0.0:
		toast_timer -= delta
		if toast_timer <= 0.0:
			toast_label.visible = false
		elif toast_timer < 0.6:
			toast_label.modulate.a = toast_timer / 0.6

# ============================ End match ============================
func _win() -> void:
	if result_open:
		return
	GameManager.placement = 1
	_show_result(true, 1, GameManager.kills, int(player.total_damage_dealt))

func _lose() -> void:
	if result_open:
		return
	_show_result(false, GameManager.placement, GameManager.kills, int(player.total_damage_dealt))

func _show_result(won: bool, placement: int, kills: int, damage: int) -> void:
	if result_open:
		return
	result_open = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if is_instance_valid(player):
		player.frozen = true
	for b in bots:
		if is_instance_valid(b):
			b.frozen = true
	GameManager.end_match(won)
	GameManager.placement = placement
	var reward: Dictionary = PlayerData.add_match_result(kills, placement, GameManager.total_players, damage)

	var overlay := Control.new()
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	hud.add_child(overlay)
	var dim := ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.02, 0.03, 0.06, 0.82)
	overlay.add_child(dim)

	var card := PanelContainer.new()
	card.set_anchors_preset(Control.PRESET_CENTER)
	card.offset_left = -240
	card.offset_right = 240
	card.offset_top = -230
	card.offset_bottom = 230
	card.add_theme_stylebox_override("panel", ThemeManager.panel_stylebox(16, 1.0))
	overlay.add_child(card)

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 14)
	card.add_child(col)

	var title := Label.new()
	title.text = "BOOYAH!" if won else "ELIMINATED"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 56)
	title.add_theme_color_override("font_color", ThemeManager.COL_PURPLE_2 if won else ThemeManager.COL_RED)
	col.add_child(title)

	var place := Label.new()
	place.text = "#%d / %d" % [placement, GameManager.total_players]
	place.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	place.add_theme_font_size_override("font_size", 24)
	place.add_theme_color_override("font_color", ThemeManager.COL_TEXT_DIM)
	col.add_child(place)

	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 24)
	grid.add_theme_constant_override("v_separation", 8)
	col.add_child(grid)
	_result_row(grid, "Kills", str(kills))
	_result_row(grid, "Damage", str(damage))
	_result_row(grid, "XP", "+%d" % int(reward["xp"]))
	_result_row(grid, "Coins", "+%d" % int(reward["coins"]), ThemeManager.COL_AMBER)
	_result_row(grid, "Diamonds", "+%d" % int(reward["diamonds"]), ThemeManager.COL_CYAN)
	if int(reward["levels"]) > 0:
		_result_row(grid, "Level Up", "+%d" % int(reward["levels"]), ThemeManager.COL_GREEN)

	# XP progress
	var lvl := Label.new()
	lvl.text = "Level %d   ·   XP %d / %d" % [PlayerData.level, PlayerData.xp, PlayerData.XP_PER_LEVEL]
	lvl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lvl.add_theme_color_override("font_color", ThemeManager.COL_TEXT_DIM)
	col.add_child(lvl)
	var xpbar := ProgressBar.new()
	xpbar.min_value = 0.0
	xpbar.max_value = 100.0
	xpbar.value = PlayerData.xp_progress() * 100.0
	xpbar.custom_minimum_size = Vector2(360, 12)
	xpbar.show_percentage = false
	var xpf := StyleBoxFlat.new()
	xpf.bg_color = ThemeManager.COL_PURPLE
	xpf.set_corner_radius_all(5)
	xpf.shadow_color = Color(ThemeManager.COL_PURPLE.r, ThemeManager.COL_PURPLE.g,
			ThemeManager.COL_PURPLE.b, 0.6)
	xpf.shadow_size = 6
	var xpbg := StyleBoxFlat.new()
	xpbg.bg_color = ThemeManager.COL_DARK
	xpbg.border_color = ThemeManager.COL_DIVIDER
	xpbg.set_border_width_all(1)
	xpbg.set_corner_radius_all(6)
	xpbar.add_theme_stylebox_override("fill", xpf)
	xpbar.add_theme_stylebox_override("background", xpbg)
	col.add_child(xpbar)

	var btn := Button.new()
	btn.text = "RETURN TO LOBBY"
	btn.custom_minimum_size = Vector2(0, 52)
	btn.pressed.connect(_return_to_lobby)
	col.add_child(btn)

func _result_row(grid: GridContainer, key: String, val: String, color: Color = Color(0,0,0,0)) -> void:
	var k := Label.new()
	k.text = key
	k.add_theme_color_override("font_color", ThemeManager.COL_TEXT_DIM)
	k.add_theme_font_size_override("font_size", 18)
	k.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var v := Label.new()
	v.text = val
	v.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	v.add_theme_color_override("font_color", color if color != Color(0,0,0,0) else ThemeManager.COL_TEXT)
	v.add_theme_font_size_override("font_size", 20)
	grid.add_child(k)
	grid.add_child(v)

func _return_to_lobby() -> void:
	get_tree().change_scene_to_file("res://Scenes/Lobby.tscn")

# ============================ Inner widget classes ============================
class Crosshair extends Control:
	var gap := 7.0
	var len := 9.0
	var thick := 2.0
	var col := Color(1, 1, 1, 0.9)
	var reloading := false
	var flash := 0.0
	func _draw() -> void:
		var c := col
		if reloading:
			c = Color(1, 0.65, 0.1, 0.95)
		elif flash > 0.0:
			c = Color(1, 0.25, 0.25, 0.95)
		var s := get_size() * 0.5
		var ht := thick * 0.5
		draw_rect(Rect2(s.x - ht, s.y - gap - len, thick, len), c)
		draw_rect(Rect2(s.x - ht, s.y + gap, thick, len), c)
		draw_rect(Rect2(s.x - gap - len, s.y - ht, len, thick), c)
		draw_rect(Rect2(s.x + gap, s.y - ht, len, thick), c)
		draw_circle(s, 1.3, c)
	func set_reload(r: bool) -> void:
		if reloading != r:
			reloading = r
			queue_redraw()
	func do_flash() -> void:
		flash = 0.2
		queue_redraw()
	func _process(delta: float) -> void:
		if flash > 0.0:
			flash = maxf(0.0, flash - delta)
			queue_redraw()

class HitMarker extends Control:
	var alpha := 0.0
	func _draw() -> void:
		if alpha <= 0.0:
			return
		var s := get_size() * 0.5
		var c := Color(1, 1, 1, alpha)
		for ang in [PI / 4.0, 3.0 * PI / 4.0, 5.0 * PI / 4.0, 7.0 * PI / 4.0]:
			var d := Vector2(cos(ang), sin(ang))
			draw_line(s + d * 4.0, s + d * 10.0, c, 2.0)
	func show_marker() -> void:
		alpha = 1.0
		queue_redraw()
	func _process(delta: float) -> void:
		if alpha > 0.0:
			alpha = maxf(0.0, alpha - delta * 3.0)
			queue_redraw()
