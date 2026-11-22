extends Node3D
# SOFAI 4H — Free Fire Battle Royale Arena
# Expanded Bermuda Island with Red Suspension Bridge, Town buildings, Factory,
# Dropship plane flight & skydiving, 360° compass bar, floating damage numbers,
# Gloo Wall tactical shields, dual HP/EP health bars, dynamic red crosshair & 8x sniper scope.

const PlayerScript = preload("res://scripts/player.gd")
const BotScript = preload("res://scripts/bot.gd")
const MinimapScript = preload("res://scripts/minimap.gd")

const BOT_NAMES := [
	"Rusher_Cat", "Sniper99_FF", "Ghost_Paw", "ProKiller_4H", "Venom_Claw",
	"Blaze_Cat", "Falcon_X", "Shadow_Kitty", "Viper_4H", "Hunter_FF",
	"Ace_Paw", "Cobra_Cat", "Havoc_OP", "Nova_Claw", "Saber_4H",
	"Reaper_Cat", "Jinx_Paw", "Specter_FF", "Titan_Cat", "Zephyr_Claw"
]

const MAP_HALF := 130.0

var mode := "br"
var player: CharacterBody3D
var bots: Array = []
var alive_bots := 0
var result_open := false
var frozen := false

# Airplane & Drop System
var plane: Node3D
var plane_cam: Camera3D
var flight_active := false
var flight_start := Vector3(-160.0, 95.0, -45.0)
var flight_end   := Vector3(160.0, 95.0, 45.0)
var flight_progress := 0.0
var flight_duration := 22.0
var player_dropped := false
var bot_drop_schedules: Array = []

# Zone System
var zone_center := Vector3.ZERO
var zone_radius := 135.0
var zone_target_radius := 135.0
var zone_shrink_start := 135.0
var zone_shrink_duration := 0.0
var zone_phase := 0
var zone_shrinking := false
var zone_phase_timer := 0.0
var zone_phases := []
var zone_ring: MeshInstance3D

# Supply Loot & Ground Pickups
var supply_crates: Array = []
var ground_pickups: Array = []
var airdrops: Array = []
var airdrop_timer := 34.0

# HUD Elements
var hud: CanvasLayer
var hud_root: Control
var minimap: Control
var alive_label: Label
var kills_label: Label
var zone_label: Label
var compass_bar: CompassBar
var health_bar: ProgressBar
var ep_bar: ProgressBar
var armor_bar: ProgressBar
var hp_label: Label
var ep_label: Label
var ammo_label: Label
var reserve_label: Label
var reload_label: Label
var weapon_name_label: Label
var weapon_slot_cards: Array = []
var gloo_btn: Button
var kill_feed: VBoxContainer
var crosshair: FreeFireCrosshair
var sniper_scope: SniperScopeOverlay
var hit_marker: HitMarker
var damage_vignette: ColorRect
var drop_hud: Control
var drop_alt_label: Label
var drop_speed_label: Label
var drop_eject_btn: Button
var interact_label: Label
var toast_label: Label
var toast_timer := 0.0
var mobile_controls_enabled := false
var mobile_ui_scale := 1.0
var mobile_joystick: Control
var mobile_jump_button: Button
var gloo_card: PanelContainer

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	mobile_controls_enabled = OS.has_feature("android") or OS.has_feature("ios") or DisplayServer.is_touchscreen_available()
	mode = GameManager.mode
	_setup_zone_config()
	_build_expanded_environment()
	_build_zone_ring()
	_build_hud()
	_build_characters()
	_build_mobile_controls()
	_build_supply_crates()
	_build_ground_loot()

	if mode == "br":
		_init_airplane_flight()
	else:
		_start_ground_mode()

# ============================ Zone Configuration ============================
func _setup_zone_config() -> void:
	if mode == "br":
		zone_phases = [
			{"wait": 30.0, "shrink": 24.0, "radius": 95.0, "dmg": 2.0},
			{"wait": 24.0, "shrink": 20.0, "radius": 60.0, "dmg": 4.5},
			{"wait": 18.0, "shrink": 16.0, "radius": 35.0, "dmg": 7.5},
			{"wait": 15.0, "shrink": 12.0, "radius": 18.0, "dmg": 11.0},
			{"wait": 12.0, "shrink": 10.0, "radius": 7.5,  "dmg": 16.0},
			{"wait": 10.0, "shrink": 8.0,  "radius": 2.5,  "dmg": 24.0},
		]
		zone_radius = 135.0
		zone_phase_timer = zone_phases[0].wait
	else:
		zone_phases = []
		zone_radius = 350.0

# ============================ Expanded Bermuda Battlefield ============================
func _build_expanded_environment() -> void:
	var world := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	var mat_sky := ProceduralSkyMaterial.new()
	mat_sky.sky_top_color = Color(0.20, 0.42, 0.82)
	mat_sky.sky_horizon_color = Color(0.74, 0.80, 0.90)
	mat_sky.ground_bottom_color = Color(0.16, 0.14, 0.20)
	sky.sky_material = mat_sky
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_color = Color(0.66, 0.74, 0.88)
	env.ambient_light_energy = 0.6
	env.fog_enabled = true
	env.fog_light_color = Color(0.70, 0.80, 0.92)
	env.fog_density = 0.004
	env.glow_enabled = true
	env.glow_intensity = 0.55
	world.environment = env
	add_child(world)

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-48, -32, 0)
	sun.light_energy = 1.2
	sun.shadow_enabled = true
	add_child(sun)

	# 1. Main Island Terrain (320m x 320m)
	var ground := StaticBody3D.new()
	ground.collision_layer = 1
	ground.collision_mask = 0
	var col := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(320, 1, 320)
	col.shape = box
	ground.add_child(col)
	var mesh := MeshInstance3D.new()
	var gbox := BoxMesh.new()
	gbox.size = Vector3(320, 1, 320)
	mesh.mesh = gbox
	var gmat := StandardMaterial3D.new()
	gmat.albedo_color = Color(0.24, 0.46, 0.28) # Bermuda lush grass
	mesh.material_override = gmat
	ground.add_child(mesh)
	ground.position.y = -0.5
	add_child(ground)

	# 2. Central River Canal (cutting through X: -10 to +10)
	var river := MeshInstance3D.new()
	var rmesh := BoxMesh.new()
	rmesh.size = Vector3(20.0, 0.35, 310.0)
	river.mesh = rmesh
	var rmat := StandardMaterial3D.new()
	rmat.albedo_color = Color(0.12, 0.38, 0.65, 0.85)
	rmat.roughness = 0.1
	rmat.metallic = 0.6
	river.material_override = rmat
	river.position = Vector3(0, 0.02, 0)
	add_child(river)

	# 3. Iconic Bermuda Red Suspension Bridge (Connecting east & west islands)
	var bridge := CatCharacterBuilder.build_red_suspension_bridge(74.0, 9.2)
	bridge.position = Vector3(0, 0.4, 0)
	add_child(bridge)

	# Asphalt roads extending from bridge
	for side in [-1, 1]:
		var road := MeshInstance3D.new()
		var r_bm := BoxMesh.new()
		r_bm.size = Vector3(9.2, 0.06, 90.0)
		road.mesh = r_bm
		var rd_mat := StandardMaterial3D.new()
		rd_mat.albedo_color = Color(0.18, 0.18, 0.20)
		road.material_override = rd_mat
		road.position = Vector3(side * 82.0, 0.03, 0)
		road.rotation.y = PI / 2.0
		add_child(road)

	# 4. Bermuda Town District (Clock Tower & Houses on West Side)
	for i in range(8):
		var b_pos := Vector3(randf_range(-115, -45), 0, randf_range(-90, 90))
		_build_town_house(b_pos, randf_range(0, PI))

	# 5. Factory & Industrial District (Containers & Warehouses on East Side)
	for i in range(12):
		var c_pos := Vector3(randf_range(45, 115), 0, randf_range(-90, 90))
		_build_cargo_container_stack(c_pos)

	# 6. Peak High Grounds (Watchtowers & Pine Forests)
	for i in range(4):
		var tower_pos := Vector3(randf_range(-90, 90), 0, randf_range(80, 115))
		_build_watchtower(tower_pos)

	# Pine Trees & Rocks throughout the island
	for i in range(48):
		var t_pos := Vector3(randf_range(-MAP_HALF + 10, MAP_HALF - 10), 0, randf_range(-MAP_HALF + 10, MAP_HALF - 10))
		if abs(t_pos.x) < 14.0:
			continue
		_build_tree(t_pos)

	for i in range(24):
		var r_pos := Vector3(randf_range(-MAP_HALF + 10, MAP_HALF - 10), 0, randf_range(-MAP_HALF + 10, MAP_HALF - 10))
		if abs(r_pos.x) < 14.0:
			continue
		_build_rock(r_pos)

	# 7. Red Sports Motorbike Prop parked near bridge
	_build_sports_bike(Vector3(12.0, 0.4, 6.0))

func _build_town_house(pos: Vector3, rot_y: float) -> void:
	var house := StaticBody3D.new()
	house.collision_layer = 1
	house.collision_mask = 0
	house.position = pos
	house.rotation.y = rot_y

	var w := randf_range(9.0, 13.0)
	var h := randf_range(6.5, 9.0)
	var d := randf_range(8.0, 12.0)

	var col := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(w, h, d)
	col.shape = box
	col.position.y = h * 0.5
	house.add_child(col)

	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = box.size
	mi.mesh = bm
	mi.position.y = h * 0.5
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(randf_range(0.72, 0.85), randf_range(0.68, 0.78), randf_range(0.60, 0.70))
	mi.material_override = mat
	house.add_child(mi)

	# Balcony / Roof cover
	var roof_trim := MeshInstance3D.new()
	var r_bm := BoxMesh.new()
	r_bm.size = Vector3(w + 0.8, 0.4, d + 0.8)
	roof_trim.mesh = r_bm
	roof_trim.position.y = h + 0.2
	var r_mat := StandardMaterial3D.new()
	r_mat.albedo_color = Color(0.45, 0.20, 0.15)
	roof_trim.material_override = r_mat
	house.add_child(roof_trim)

	add_child(house)

func _build_cargo_container_stack(pos: Vector3) -> void:
	var container := StaticBody3D.new()
	container.collision_layer = 1
	container.collision_mask = 0
	container.position = pos

	var colors = [Color(0.18, 0.42, 0.82), Color(0.85, 0.22, 0.22), Color(0.92, 0.75, 0.18), Color(0.18, 0.65, 0.38)]
	var col_c: Color = colors[randi() % colors.size()]

	var col := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(3.2, 3.0, 7.5)
	col.shape = box
	col.position.y = 1.5
	container.add_child(col)

	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = box.size
	mi.mesh = bm
	mi.position.y = 1.5
	var mat := StandardMaterial3D.new()
	mat.albedo_color = col_c
	mat.metallic = 0.6
	mat.roughness = 0.4
	mi.material_override = mat
	container.add_child(mi)

	add_child(container)

func _build_watchtower(pos: Vector3) -> void:
	var tower := StaticBody3D.new()
	tower.collision_layer = 1
	tower.collision_mask = 0
	tower.position = pos

	var col := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(4.5, 12.0, 4.5)
	col.shape = box
	col.position.y = 6.0
	tower.add_child(col)

	var mat_wood := StandardMaterial3D.new()
	mat_wood.albedo_color = Color(0.38, 0.24, 0.16)

	for side_x in [-1.8, 1.8]:
		for side_z in [-1.8, 1.8]:
			var leg := MeshInstance3D.new()
			var cm := CylinderMesh.new()
			cm.top_radius = 0.18
			cm.bottom_radius = 0.24
			cm.height = 11.0
			leg.mesh = cm
			leg.material_override = mat_wood
			leg.position = Vector3(side_x, 5.5, side_z)
			tower.add_child(leg)

	var platform := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(4.6, 0.4, 4.6)
	platform.mesh = bm
	platform.material_override = mat_wood
	platform.position.y = 10.8
	tower.add_child(platform)

	add_child(tower)

func _build_sports_bike(pos: Vector3) -> void:
	var bike := Node3D.new()
	bike.name = "SportsBike"
	bike.position = pos

	var mat_red := StandardMaterial3D.new()
	mat_red.albedo_color = Color(0.95, 0.18, 0.20)
	mat_red.metallic = 0.8
	var mat_tire := StandardMaterial3D.new()
	mat_tire.albedo_color = Color(0.08, 0.08, 0.08)

	# Frame & Cowling
	var frame := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(0.6, 0.7, 2.2)
	frame.mesh = bm
	frame.material_override = mat_red
	frame.position.y = 0.65
	bike.add_child(frame)

	# Wheels
	for z in [-0.85, 0.85]:
		var wheel := MeshInstance3D.new()
		var cm := CylinderMesh.new()
		cm.top_radius = 0.38
		cm.bottom_radius = 0.38
		cm.height = 0.28
		wheel.mesh = cm
		wheel.material_override = mat_tire
		wheel.rotation.z = PI / 2.0
		wheel.position = Vector3(0, 0.38, z)
		bike.add_child(wheel)

	add_child(bike)

func _build_tree(pos: Vector3) -> void:
	var trunk := StaticBody3D.new()
	trunk.collision_layer = 1
	trunk.collision_mask = 0
	trunk.position = pos

	var tc := CollisionShape3D.new()
	var cyl := CylinderShape3D.new()
	cyl.radius = 0.36
	cyl.height = 3.6
	tc.shape = cyl
	trunk.add_child(tc)

	var tmi := MeshInstance3D.new()
	var tm := CylinderMesh.new()
	tm.top_radius = 0.36
	tm.bottom_radius = 0.36
	tm.height = 3.6
	tmi.mesh = tm
	var tmat := StandardMaterial3D.new()
	tmat.albedo_color = Color(0.35, 0.22, 0.14)
	tmi.material_override = tmat
	tmi.position.y = 1.8
	trunk.add_child(tmi)

	var foliage := MeshInstance3D.new()
	var fm := SphereMesh.new()
	fm.radius = 2.6
	fm.height = 5.2
	foliage.mesh = fm
	var fmat := StandardMaterial3D.new()
	fmat.albedo_color = Color(0.16, 0.42, 0.20)
	foliage.material_override = fmat
	foliage.position.y = 5.6
	trunk.add_child(foliage)

	add_child(trunk)

func _build_rock(pos: Vector3) -> void:
	var r := StaticBody3D.new()
	r.collision_layer = 1
	r.collision_mask = 0
	r.position = pos

	var rad := randf_range(1.0, 2.2)
	var rc := CollisionShape3D.new()
	var sph := SphereShape3D.new()
	sph.radius = rad
	rc.shape = sph
	r.add_child(rc)

	var rmi := MeshInstance3D.new()
	var rm := SphereMesh.new()
	rm.radius = rad
	rm.height = rad * 1.4
	rmi.mesh = rm
	var rmat := StandardMaterial3D.new()
	rmat.albedo_color = Color(0.44, 0.44, 0.48)
	rmi.material_override = rmat
	rmi.position.y = rad * 0.4
	r.add_child(rmi)

	add_child(r)

func _build_zone_ring() -> void:
	zone_ring = MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = zone_radius - 0.8
	torus.outer_radius = zone_radius + 0.8
	zone_ring.mesh = torus
	zone_ring.rotation.x = PI / 2.0
	zone_ring.position.y = 0.15
	var mat := StandardMaterial3D.new()
	mat.albedo_color = ThemeManager.COL_PURPLE
	mat.emission_enabled = true
	mat.emission = ThemeManager.COL_PURPLE
	mat.emission_energy_multiplier = 1.6
	mat.no_depth_test = true
	zone_ring.material_override = mat
	add_child(zone_ring)

# ============================ Characters & Bots Setup ============================
func _build_characters() -> void:
	player = CharacterBody3D.new()
	player.set_script(PlayerScript)
	player.collision_layer = 2
	player.collision_mask = 1
	var pc := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 0.45
	cap.height = 1.8
	pc.shape = cap
	player.add_child(pc)

	player.died.connect(_on_player_died)
	player.hit_landed.connect(_on_player_hit)
	player.took_damage.connect(_on_player_took_damage)
	player.reloaded.connect(_on_player_reload)
	player.weapon_changed.connect(_on_player_weapon_changed)
	player.ads_changed.connect(_on_player_ads_changed)
	player.aim_target_changed.connect(_on_player_aim_target_changed)
	player.drop_state_changed.connect(_on_player_drop_state_changed)
	player.gloo_wall_count_changed.connect(_on_gloo_count_changed)
	add_child(player)

	var count := 19
	var skin_options := ["purple", "red", "blue"]
	for i in range(count):
		var bot: CharacterBody3D = CharacterBody3D.new()
		bot.set_script(BotScript)
		bot.collision_layer = 2
		bot.collision_mask = 1
		bot.char_name = BOT_NAMES[i % BOT_NAMES.size()]
		bot.zone_center = zone_center
		bot.zone_radius = zone_radius
		bot.setup_visual(skin_options[i % skin_options.size()])

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

	var everyone := bots.duplicate()
	everyone.append(player)
	for b in bots:
		b.set_enemies(everyone)

func _build_supply_crates() -> void:
	for i in range(12):
		var pos := Vector3(randf_range(-MAP_HALF + 15, MAP_HALF - 15), 0.4, randf_range(-MAP_HALF + 15, MAP_HALF - 15))
		if abs(pos.x) < 12.0:
			pos.x = 25.0
		_spawn_crate(pos)

func _spawn_crate(pos: Vector3) -> void:
	var crate := MeshInstance3D.new()
	var m := BoxMesh.new()
	m.size = Vector3(1.1, 0.9, 1.1)
	crate.mesh = m
	var mat := StandardMaterial3D.new()
	mat.albedo_color = ThemeManager.COL_AMBER
	mat.emission_enabled = true
	mat.emission = ThemeManager.COL_AMBER
	mat.emission_energy_multiplier = 0.8
	crate.material_override = mat
	crate.position = pos
	add_child(crate)
	supply_crates.append({"node": crate, "pos": Vector3(pos.x, 0, pos.z)})

func _build_ground_loot() -> void:
	# Scatter tactical pickups (Gloo Walls, Medkits, Armor)
	for i in range(16):
		var pos := Vector3(randf_range(-MAP_HALF + 15, MAP_HALF - 15), 0.2, randf_range(-MAP_HALF + 15, MAP_HALF - 15))
		if abs(pos.x) < 12.0:
			continue
		var loot_type = ["gloo", "medkit", "ammo", "armor"][i % 4]
		_spawn_ground_pickup(pos, loot_type)

func _spawn_ground_pickup(pos: Vector3, type: String) -> void:
	var mi := MeshInstance3D.new()
	var mat := StandardMaterial3D.new()
	mat.emission_enabled = true
	mat.emission_energy_multiplier = 1.4

	match type:
		"gloo":
			var bm := BoxMesh.new()
			bm.size = Vector3(0.5, 0.5, 0.5)
			mi.mesh = bm
			mat.albedo_color = ThemeManager.COL_PURPLE
			mat.emission = ThemeManager.COL_PURPLE
		"medkit":
			var bm := BoxMesh.new()
			bm.size = Vector3(0.6, 0.4, 0.6)
			mi.mesh = bm
			mat.albedo_color = ThemeManager.COL_GREEN
			mat.emission = ThemeManager.COL_GREEN
		"ammo":
			var bm := BoxMesh.new()
			bm.size = Vector3(0.4, 0.3, 0.5)
			mi.mesh = bm
			mat.albedo_color = ThemeManager.COL_AMBER
			mat.emission = ThemeManager.COL_AMBER
		"armor":
			var cm := CylinderMesh.new()
			cm.top_radius = 0.35
			cm.bottom_radius = 0.35
			cm.height = 0.4
			mi.mesh = cm
			mat.albedo_color = ThemeManager.COL_CYAN
			mat.emission = ThemeManager.COL_CYAN

	mi.material_override = mat
	mi.position = pos
	add_child(mi)
	ground_pickups.append({"node": mi, "pos": Vector3(pos.x, 0, pos.z), "type": type})

# ============================ Airplane Flight & Drop System ============================
func _init_airplane_flight() -> void:
	flight_active = true
	player_dropped = false
	flight_progress = 0.0

	var ang := randf_range(-0.35, 0.35)
	flight_start = Vector3(cos(ang) * -160.0 - sin(ang) * -45.0, 95.0, sin(ang) * -160.0 + cos(ang) * -45.0)
	flight_end   = Vector3(cos(ang) * 160.0 - sin(ang) * 45.0, 95.0, sin(ang) * 160.0 + cos(ang) * 45.0)

	plane = CatCharacterBuilder.build_cargo_plane()
	add_child(plane)
	plane.position = flight_start
	plane.look_at(flight_end, Vector3.UP)

	plane_cam = Camera3D.new()
	plane_cam.name = "PlaneCamera"
	plane_cam.fov = 78.0
	plane_cam.position = Vector3(0, 6.0, 20.0)
	plane.add_child(plane_cam)
	plane_cam.current = true

	player.drop_state = PlayerScript.DropState.IN_PLANE
	player.position = flight_start

	bot_drop_schedules.clear()
	for i in range(bots.size()):
		var b = bots[i]
		b.drop_state = PlayerScript.DropState.IN_PLANE
		b.position = flight_start
		var drop_t := randf_range(0.10, 0.90)
		bot_drop_schedules.append({"bot": b, "time": drop_t, "dropped": false})

	drop_hud.visible = true
	crosshair.visible = false
	_show_toast("AIRPLANE IN FLIGHT — PRESS SPACE OR CLICK EJECT TO DROP!")

func _start_ground_mode() -> void:
	flight_active = false
	drop_hud.visible = false
	crosshair.visible = true
	player.position = Vector3(-15.0, 2.0, 0)
	player.drop_state = PlayerScript.DropState.GROUND
	for b in bots:
		var ang := randf() * TAU
		var r := randf_range(20.0, MAP_HALF - 15.0)
		b.position = Vector3(cos(ang) * r, 2, sin(ang) * r)
		b.drop_state = PlayerScript.DropState.GROUND

func _physics_process(delta: float) -> void:
	if result_open:
		return

	if flight_active:
		_process_airplane_flight(delta)

	_update_zone(delta)
	_update_zone_ring()
	_update_supply(delta)
	_update_ground_pickups()
	_update_hud()

	if Input.is_action_just_pressed("interact"):
		_try_open_crate()

	if alive_bots <= 0 and is_instance_valid(player) and player.alive and player.drop_state == PlayerScript.DropState.GROUND:
		_win()
	elif is_instance_valid(player) and not player.alive and not result_open:
		_lose()

func _process_airplane_flight(delta: float) -> void:
	flight_progress += delta / flight_duration
	if plane and is_instance_valid(plane):
		plane.position = flight_start.lerp(flight_end, clampf(flight_progress, 0.0, 1.0))
		plane.look_at(flight_end, Vector3.UP)

	minimap.flight_active = flight_active
	minimap.flight_start = flight_start
	minimap.flight_end = flight_end
	minimap.plane_pos = plane.global_position if plane else Vector3.ZERO

	if not player_dropped:
		player.global_position = plane.global_position
		drop_alt_label.text = "ALTITUDE: 1000m"
		drop_speed_label.text = "FLIGHT SPEED: 240 km/h"
		if Input.is_action_just_pressed("eject") or Input.is_action_just_pressed("jump") or flight_progress >= 0.95:
			_player_eject()

	for s in bot_drop_schedules:
		if not s["dropped"] and flight_progress >= s["time"]:
			s["dropped"] = true
			var b = s["bot"]
			if is_instance_valid(b) and b.alive:
				var drop_pos = plane.global_position + Vector3(randf_range(-4, 4), -2.0, randf_range(2, 6))
				var land_target = Vector3(randf_range(-MAP_HALF + 15, MAP_HALF - 15), 0, randf_range(-MAP_HALF + 15, MAP_HALF - 15))
				b.start_skydiving(drop_pos, land_target)

	if flight_progress >= 1.2:
		flight_active = false
		minimap.flight_active = false
		if plane and is_instance_valid(plane):
			plane.queue_free()

func _player_eject() -> void:
	if player_dropped:
		return
	player_dropped = true
	var eject_pos := plane.global_position + Vector3(0, -3.0, 4.0)
	player.start_skydiving(eject_pos)
	if plane_cam:
		plane_cam.current = false
	if player.camera:
		player.camera.current = true

	drop_eject_btn.text = "DEPLOY PARACHUTE (SPACE)"
	_show_toast("FREEFALLING — DIVE WITH W/S, PRESS SPACE FOR PARACHUTE!")

# ============================ HUD Construction ============================
func _build_hud() -> void:
	hud = CanvasLayer.new()
	add_child(hud)
	hud_root = Control.new()
	hud_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	hud_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud_root.theme = ThemeManager.theme
	hud.add_child(hud_root)

	# 1. Top 360° Compass Bar (From Free Fire!)
	compass_bar = CompassBar.new()
	compass_bar.set_anchors_preset(Control.PRESET_CENTER_TOP)
	compass_bar.offset_left = -240; compass_bar.offset_right = 240
	compass_bar.offset_top = 8; compass_bar.offset_bottom = 36
	compass_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud_root.add_child(compass_bar)

	# 2. Top-Left Status Card (Alive, Kills, Zone)
	var top_left := PanelContainer.new()
	top_left.set_anchors_preset(Control.PRESET_TOP_LEFT)
	top_left.position = Vector2(20, 18)
	top_left.add_theme_stylebox_override("panel", ThemeManager.card_stylebox(12, 0.88))
	var tlv := VBoxContainer.new()
	tlv.add_theme_constant_override("separation", 3)
	top_left.add_child(tlv)
	alive_label = _label("ALIVE 20", 22, ThemeManager.COL_PURPLE_2)
	kills_label = _label("KILLS 0", 16, ThemeManager.COL_TEXT)
	zone_label  = _label("Zone shrinks in 30s", 13, ThemeManager.COL_CYAN)
	tlv.add_child(alive_label)
	tlv.add_child(kills_label)
	tlv.add_child(zone_label)
	hud_root.add_child(top_left)

	# 3. Minimap (Top-Right)
	minimap = Control.new()
	minimap.set_script(MinimapScript)
	minimap.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	minimap.offset_left = -196; minimap.offset_top = 18
	minimap.offset_right = -20; minimap.offset_bottom = 194
	minimap.size = Vector2(176, 176)
	minimap.clip_contents = true
	minimap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud_root.add_child(minimap)

	# 4. Kill Feed
	kill_feed = VBoxContainer.new()
	kill_feed.set_anchors_preset(Control.PRESET_TOP_LEFT)
	kill_feed.position = Vector2(20, 134)
	kill_feed.add_theme_constant_override("separation", 4)
	hud_root.add_child(kill_feed)

	# 5. Bottom Dual HP / EP Health Bars & Armor (From Free Fire!)
	var health_container := VBoxContainer.new()
	health_container.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	health_container.offset_left = -180; health_container.offset_right = 180
	health_container.offset_top = -88; health_container.offset_bottom = -14
	health_container.add_theme_constant_override("separation", 4)
	hud_root.add_child(health_container)

	# Top yellow/amber EP Bar
	var ep_row := HBoxContainer.new()
	ep_row.add_theme_constant_override("separation", 6)
	ep_label = _label("EP 100/200", 12, ThemeManager.COL_AMBER)
	ep_bar = _make_bar(ThemeManager.COL_AMBER, 6)
	ep_bar.max_value = 200.0
	ep_bar.value = 100.0
	ep_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ep_row.add_child(ep_label)
	ep_row.add_child(ep_bar)
	health_container.add_child(ep_row)

	# Main Green HP Bar & Vest
	var hp_row := HBoxContainer.new()
	hp_row.add_theme_constant_override("separation", 6)
	hp_label = _label("HP 200/200", 16, ThemeManager.COL_GREEN)
	health_bar = _make_bar(ThemeManager.COL_GREEN, 14)
	health_bar.max_value = 100.0
	health_bar.value = 100.0
	health_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hp_row.add_child(hp_label)
	hp_row.add_child(health_bar)
	health_container.add_child(hp_row)

	# Vest & Helmet icons row
	var icon_row := HBoxContainer.new()
	icon_row.alignment = BoxContainer.ALIGNMENT_CENTER
	icon_row.add_theme_constant_override("separation", 16)
	var helmet_lbl := _label("🪖 Lv.3 HELMET", 11, ThemeManager.COL_TEXT_DIM)
	var vest_lbl   := _label("🛡️ Lv.3 VEST", 11, ThemeManager.COL_CYAN)
	icon_row.add_child(helmet_lbl)
	icon_row.add_child(vest_lbl)
	health_container.add_child(icon_row)

	# 6. Gloo Wall Tactical Shield Button (Bottom-Left)
	gloo_card = PanelContainer.new()
	gloo_card.anchor_left = 0.0; gloo_card.anchor_top = 1.0
	gloo_card.anchor_right = 0.0; gloo_card.anchor_bottom = 1.0
	gloo_card.offset_left = 20; gloo_card.offset_top = -88
	gloo_card.offset_right = 160; gloo_card.offset_bottom = -20
	gloo_card.add_theme_stylebox_override("panel", ThemeManager.card_stylebox(10, 0.90))
	hud_root.add_child(gloo_card)

	gloo_btn = Button.new()
	gloo_btn.text = "GLOO WALL  x3" if mobile_controls_enabled else "GLOO WALL [G]  x3"
	gloo_btn.add_theme_font_size_override("font_size", 12)
	gloo_btn.add_theme_color_override("font_color", ThemeManager.COL_CYAN)
	ThemeManager.ghost_button(gloo_btn)
	gloo_btn.pressed.connect(_on_gloo_button_pressed)
	gloo_card.add_child(gloo_btn)

	# 7. Bottom-Right Real Weapons Card
	var br := PanelContainer.new()
	br.anchor_left = 1.0; br.anchor_top = 1.0
	br.anchor_right = 1.0; br.anchor_bottom = 1.0
	br.offset_left = -310; br.offset_top = -120
	br.offset_right = -20; br.offset_bottom = -18
	br.add_theme_stylebox_override("panel", ThemeManager.card_stylebox(12, 0.90))
	var brv := VBoxContainer.new()
	brv.alignment = BoxContainer.ALIGNMENT_END
	brv.add_theme_constant_override("separation", 4)
	br.add_child(brv)

	weapon_name_label = _label("AK47 — ASSAULT RIFLE", 14, ThemeManager.COL_PURPLE_2)
	brv.add_child(weapon_name_label)

	var slots_row := HBoxContainer.new()
	slots_row.add_theme_constant_override("separation", 6)
	brv.add_child(slots_row)
	var slot_keys = ["AK47", "MP40", "AWM", "M1887"]
	for i in range(slot_keys.size()):
		var slot_btn := Button.new()
		slot_btn.text = "%d %s" % [i + 1, slot_keys[i]]
		slot_btn.tooltip_text = "Select weapon slot %d" % (i + 1)
		slot_btn.custom_minimum_size = Vector2(62, 44 if mobile_controls_enabled else 28)
		slot_btn.add_theme_font_size_override("font_size", 11)
		_style_weapon_slot_button(slot_btn)
		slot_btn.pressed.connect(_on_slot_clicked.bind(i))
		slots_row.add_child(slot_btn)
		weapon_slot_cards.append(slot_btn)

	var ammo_row := HBoxContainer.new()
	ammo_row.alignment = BoxContainer.ALIGNMENT_END
	ammo_row.add_theme_constant_override("separation", 5)
	ammo_label = _label("30", 32, ThemeManager.COL_AMBER)
	reserve_label = _label("/ 150", 18, ThemeManager.COL_TEXT_DIM)
	reserve_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	ammo_row.add_child(ammo_label)
	ammo_row.add_child(reserve_label)
	brv.add_child(ammo_row)

	reload_label = _label("QUICK RELOAD", 13, ThemeManager.COL_CYAN)
	reload_label.visible = false
	brv.add_child(reload_label)
	hud_root.add_child(br)

	# 8. Center Crosshair, Scope, & Hit Marker
	crosshair = FreeFireCrosshair.new()
	crosshair.set_anchors_preset(Control.PRESET_CENTER)
	crosshair.offset_left = -30; crosshair.offset_right = 30
	crosshair.offset_top = -30; crosshair.offset_bottom = 30
	crosshair.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud_root.add_child(crosshair)

	sniper_scope = SniperScopeOverlay.new()
	sniper_scope.set_anchors_preset(Control.PRESET_FULL_RECT)
	sniper_scope.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sniper_scope.visible = false
	hud_root.add_child(sniper_scope)

	hit_marker = HitMarker.new()
	hit_marker.set_anchors_preset(Control.PRESET_CENTER)
	hit_marker.offset_left = -26; hit_marker.offset_right = 26
	hit_marker.offset_top = -26; hit_marker.offset_bottom = 26
	hit_marker.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud_root.add_child(hit_marker)

	# 9. Airplane Drop HUD
	drop_hud = Control.new()
	drop_hud.set_anchors_preset(Control.PRESET_FULL_RECT)
	drop_hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	drop_hud.visible = false
	hud_root.add_child(drop_hud)

	var drop_banner := PanelContainer.new()
	drop_banner.set_anchors_preset(Control.PRESET_CENTER_TOP)
	drop_banner.offset_left = -220; drop_banner.offset_right = 220
	drop_banner.offset_top = 50; drop_banner.offset_bottom = 114
	drop_banner.add_theme_stylebox_override("panel", ThemeManager.panel_stylebox(14, 0.92))
	drop_hud.add_child(drop_banner)

	var db_vbox := VBoxContainer.new()
	db_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	drop_banner.add_child(db_vbox)
	drop_alt_label = _label("ALTITUDE: 1000m", 18, ThemeManager.COL_CYAN)
	drop_alt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	drop_speed_label = _label("FLIGHT SPEED: 240 km/h", 14, ThemeManager.COL_TEXT_DIM)
	drop_speed_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	db_vbox.add_child(drop_alt_label)
	db_vbox.add_child(drop_speed_label)

	drop_eject_btn = Button.new()
	drop_eject_btn.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	drop_eject_btn.offset_left = -170; drop_eject_btn.offset_right = 170
	drop_eject_btn.offset_top = -140; drop_eject_btn.offset_bottom = -80
	drop_eject_btn.text = "EJECT / DROP (SPACE)"
	drop_eject_btn.add_theme_font_size_override("font_size", 22)
	var esb := StyleBoxFlat.new()
	esb.bg_color = ThemeManager.COL_AMBER
	esb.set_corner_radius_all(10)
	esb.shadow_color = Color(ThemeManager.COL_AMBER.r, ThemeManager.COL_AMBER.g, ThemeManager.COL_AMBER.b, 0.7)
	esb.shadow_size = 12
	drop_eject_btn.add_theme_stylebox_override("normal", esb)
	drop_eject_btn.pressed.connect(_on_drop_button_clicked)
	drop_hud.add_child(drop_eject_btn)

	damage_vignette = ColorRect.new()
	damage_vignette.set_anchors_preset(Control.PRESET_FULL_RECT)
	damage_vignette.color = Color(1.0, 0.05, 0.05, 0.0)
	damage_vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud_root.add_child(damage_vignette)

	interact_label = _label("Press E to open supply crate", 18, ThemeManager.COL_AMBER)
	interact_label.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	interact_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	interact_label.offset_top = -135; interact_label.offset_bottom = -100
	interact_label.visible = false
	hud_root.add_child(interact_label)

	toast_label = _label("", 19, ThemeManager.COL_PURPLE_2)
	toast_label.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	toast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	toast_label.offset_top = -95; toast_label.offset_bottom = -60
	toast_label.visible = false
	hud_root.add_child(toast_label)

func _build_mobile_controls() -> void:
	if not mobile_controls_enabled or not is_instance_valid(player):
		return
	var viewport_size := get_viewport().get_visible_rect().size
	mobile_ui_scale = clampf(viewport_size.y / 720.0, 0.65, 1.0)

	gloo_card.offset_left = 194 * mobile_ui_scale
	gloo_card.offset_top = -94 * mobile_ui_scale
	gloo_card.offset_right = 354 * mobile_ui_scale
	gloo_card.offset_bottom = -20 * mobile_ui_scale
	gloo_btn.text = "GLOO WALL  x%d" % player.gloo_walls
	gloo_btn.custom_minimum_size = Vector2(152, 54) * mobile_ui_scale

	var controls := Control.new()
	controls.set_anchors_preset(Control.PRESET_FULL_RECT)
	controls.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud_root.add_child(controls)

	var look_area := MobileLookArea.new()
	look_area.anchor_left = 0.38
	look_area.anchor_top = 0.32
	look_area.anchor_right = 1.0
	look_area.anchor_bottom = 1.0
	look_area.offset_bottom = -150 * mobile_ui_scale
	look_area.player = player
	controls.add_child(look_area)

	mobile_joystick = MobileJoystick.new()
	mobile_joystick.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	mobile_joystick.offset_left = 28 * mobile_ui_scale
	mobile_joystick.offset_top = -194 * mobile_ui_scale
	mobile_joystick.offset_right = 188 * mobile_ui_scale
	mobile_joystick.offset_bottom = -34 * mobile_ui_scale
	mobile_joystick.custom_minimum_size = Vector2(160, 160) * mobile_ui_scale
	mobile_joystick.value_changed.connect(Callable(player, "set_mobile_move_vector"))
	controls.add_child(mobile_joystick)

	var fire_button := _mobile_button("FIRE", -132, -268, -24, -160, 104, 104)
	fire_button.add_theme_font_size_override("font_size", maxi(12, int(16 * mobile_ui_scale)))
	fire_button.button_down.connect(Callable(player, "set_mobile_shooting").bind(true))
	fire_button.button_up.connect(Callable(player, "set_mobile_shooting").bind(false))
	controls.add_child(fire_button)

	var aim_button := _mobile_button("AIM", -236, -252, -156, -172, 80, 80)
	aim_button.button_down.connect(Callable(player, "set_mobile_aiming").bind(true))
	aim_button.button_up.connect(Callable(player, "set_mobile_aiming").bind(false))
	controls.add_child(aim_button)

	var reload_button := _mobile_button("RELOAD", -236, -340, -156, -270, 80, 70)
	reload_button.pressed.connect(Callable(player, "start_reload"))
	controls.add_child(reload_button)

	var run_button := _mobile_button("RUN", -354, -198, -278, -122, 76, 76)
	run_button.button_down.connect(Callable(player, "set_mobile_sprinting").bind(true))
	run_button.button_up.connect(Callable(player, "set_mobile_sprinting").bind(false))
	controls.add_child(run_button)

	mobile_jump_button = _mobile_button("JUMP", -354, -282, -278, -206, 76, 76)
	mobile_jump_button.pressed.connect(_on_mobile_jump_pressed)
	controls.add_child(mobile_jump_button)

	var swap_button := _mobile_button("SWAP", -354, -366, -278, -294, 76, 72)
	swap_button.pressed.connect(func() -> void:
		player.select_weapon_by_slot((player.weapon_index + 1) % player.inventory.size())
	)
	controls.add_child(swap_button)

	var use_button := _mobile_button("USE", -354, -450, -278, -378, 76, 72)
	use_button.pressed.connect(_try_open_crate)
	controls.add_child(use_button)

func _mobile_button(label: String, left: float, top: float, right: float, bottom: float, width: float, height: float) -> Button:
	var button := Button.new()
	button.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	button.offset_left = left * mobile_ui_scale
	button.offset_top = top * mobile_ui_scale
	button.offset_right = right * mobile_ui_scale
	button.offset_bottom = bottom * mobile_ui_scale
	button.custom_minimum_size = Vector2(width, height) * mobile_ui_scale
	button.text = label
	button.add_theme_font_size_override("font_size", maxi(10, int(13 * mobile_ui_scale)))
	button.tooltip_text = label
	ThemeManager.ghost_button(button)
	return button

func _style_weapon_slot_button(button: Button) -> void:
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0.08, 0.06, 0.12, 0.92)
	normal.border_color = ThemeManager.COL_DIVIDER
	normal.set_border_width_all(1)
	normal.set_corner_radius_all(6)
	normal.set_content_margin_all(4)
	button.add_theme_stylebox_override("normal", normal)
	var hover := StyleBoxFlat.new()
	hover.bg_color = ThemeManager.COL_PANEL_2
	hover.border_color = ThemeManager.COL_PURPLE
	hover.set_border_width_all(1)
	hover.set_corner_radius_all(6)
	hover.set_content_margin_all(4)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", normal)
	button.add_theme_stylebox_override("focus", hover)

func _on_mobile_jump_pressed() -> void:
	if not is_instance_valid(player):
		return
	if player.drop_state == PlayerScript.DropState.IN_PLANE:
		_player_eject()
	elif player.drop_state == PlayerScript.DropState.FREEFALL:
		player.deploy_parachute()
	else:
		player.request_mobile_jump()

func _on_gloo_button_pressed() -> void:
	if is_instance_valid(player):
		player.deploy_gloo_wall()

func _on_slot_clicked(idx: int) -> void:
	if is_instance_valid(player):
		player.select_weapon_by_slot(idx)

func _on_drop_button_clicked() -> void:
	if not player_dropped:
		_player_eject()
	elif is_instance_valid(player) and player.drop_state == PlayerScript.DropState.FREEFALL:
		player.deploy_parachute()

func _label(text: String, size: int, color: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.6))
	l.add_theme_constant_override("shadow_offset_x", 0)
	l.add_theme_constant_override("shadow_offset_y", 2)
	return l

func _make_bar(color: Color, h: int) -> ProgressBar:
	var bar := ProgressBar.new()
	bar.custom_minimum_size = Vector2(180, h)
	bar.min_value = 0.0
	bar.max_value = 100.0
	bar.value = 100.0
	bar.show_percentage = false
	var fill := StyleBoxFlat.new()
	fill.bg_color = color
	fill.set_corner_radius_all(3)
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.04, 0.03, 0.06, 0.85)
	bg.set_border_width_all(1)
	bg.border_color = ThemeManager.COL_DIVIDER
	bg.set_corner_radius_all(4)
	bar.add_theme_stylebox_override("fill", fill)
	bar.add_theme_stylebox_override("background", bg)
	return bar

# ============================ HUD Updates ============================
func _update_hud() -> void:
	if not is_instance_valid(player):
		return

	alive_label.text = "ALIVE %d" % (alive_bots + (1 if player.alive else 0))
	kills_label.text = "KILLS %d" % GameManager.kills
	hp_label.text = "HP %d/200" % int(round(player.health * 2.0))
	hp_label.add_theme_color_override("font_color", _hp_color(player.health))
	health_bar.value = player.health
	ammo_label.text = str(player.ammo)
	reserve_label.text = "/ %d" % player.reserve_ammo
	reload_label.visible = player.is_reloading
	if mobile_jump_button:
		match player.drop_state:
			PlayerScript.DropState.IN_PLANE:
				mobile_jump_button.text = "DROP"
			PlayerScript.DropState.FREEFALL:
				mobile_jump_button.text = "CHUTE"
			PlayerScript.DropState.PARACHUTING:
				mobile_jump_button.visible = false
			PlayerScript.DropState.GROUND:
				mobile_jump_button.visible = true
				mobile_jump_button.text = "JUMP"

	# Compass update
	if compass_bar:
		var cam_yaw = player.get("cam_yaw")
		if cam_yaw != null:
			compass_bar.set_heading(float(cam_yaw))

	var w_cfg: Dictionary = player.WEAPONS.get(player.current_weapon_key, {})
	weapon_name_label.text = "%s — %s" % [w_cfg.get("name", "WEAPON"), w_cfg.get("category", "").to_upper()]

	for i in range(weapon_slot_cards.size()):
		var b: Button = weapon_slot_cards[i]
		var cur_idx = player.get("weapon_index")
		var sel: bool = (cur_idx != null and i == int(cur_idx))
		var sb := StyleBoxFlat.new()
		sb.set_corner_radius_all(6)
		if sel:
			sb.bg_color = Color(ThemeManager.COL_PURPLE.r, ThemeManager.COL_PURPLE.g, ThemeManager.COL_PURPLE.b, 0.95)
			sb.border_color = ThemeManager.COL_CYAN
			sb.set_border_width_all(2)
		else:
			sb.bg_color = Color(0.08, 0.06, 0.12, 0.85)
			sb.border_color = ThemeManager.COL_DIVIDER
			sb.set_border_width_all(1)
		b.add_theme_stylebox_override("normal", sb)

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
		return ThemeManager.COL_AMBER
	return ThemeManager.COL_RED

# ============================ Zone & Damage ============================
func _update_zone(delta: float) -> void:
	if mode != "br" or zone_phases.is_empty():
		return
	if zone_phase >= zone_phases.size():
		_apply_outside_damage(delta, 22.0)
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
			torus.inner_radius = maxf(0.5, zone_radius - 0.8)
			torus.outer_radius = zone_radius + 0.8

func _apply_outside_damage(delta: float, dmg: float) -> void:
	if dmg <= 0.0:
		return
	if player and player.alive and player.drop_state == PlayerScript.DropState.GROUND:
		if _flat_dist(player.global_position, zone_center) > zone_radius:
			player.take_damage(dmg * delta, null)
	for b in bots:
		if is_instance_valid(b) and b.alive and b.drop_state == PlayerScript.DropState.GROUND:
			if _flat_dist(b.global_position, zone_center) > zone_radius:
				b.take_damage(dmg * delta, null)

func _flat_dist(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x - b.x, a.z - b.z).length()

func _update_supply(delta: float) -> void:
	airdrop_timer -= delta
	if airdrop_timer <= 0.0:
		airdrop_timer = randf_range(32.0, 48.0)
		var drop := Vector3(randf_range(-zone_radius + 10, zone_radius - 10), 0, randf_range(-zone_radius + 10, zone_radius - 10))
		_spawn_crate(drop)
		airdrops.append(drop)
		_show_toast("SUPPLY AIRDROP INCOMING!")

	var near := false
	if is_instance_valid(player) and not frozen and player.drop_state == PlayerScript.DropState.GROUND:
		for c in supply_crates:
			if _flat_dist(player.global_position, c["pos"]) < 3.5:
				near = true
				break
	interact_label.visible = near

func _update_ground_pickups() -> void:
	if not is_instance_valid(player) or player.drop_state != PlayerScript.DropState.GROUND:
		return
	for i in range(ground_pickups.size() - 1, -1, -1):
		var p = ground_pickups[i]
		if _flat_dist(player.global_position, p["pos"]) < 2.0:
			match p["type"]:
				"gloo":
					player.add_gloo_walls(1)
					_show_toast("Picked up Gloo Wall +1")
				"medkit":
					player.heal(40.0)
					_show_toast("Used Medkit (+40 HP)")
				"ammo":
					player.add_ammo(60)
					_show_toast("Picked up Ammo +60")
				"armor":
					player.add_armor(50.0)
					_show_toast("Equipped Level 3 Vest")
			if is_instance_valid(p["node"]):
				p["node"].queue_free()
			ground_pickups.remove_at(i)

func _try_open_crate() -> void:
	if not is_instance_valid(player) or player.drop_state != PlayerScript.DropState.GROUND:
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
	player.add_ammo(90)
	player.add_armor(50.0)
	player.heal(50.0)
	player.add_gloo_walls(2)
	_show_toast("SUPPLY CRATE: AMMO + VEST + GLOO WALLS + MEDKIT!")

# ============================ Player Signals ============================
func _on_player_hit(_target: Node, damage: float, headshot: bool, hit_pos: Vector3) -> void:
	hit_marker.show_marker()
	_spawn_floating_damage(hit_pos, damage, headshot)
	if headshot:
		_show_toast("HEADSHOT!")

func _spawn_floating_damage(pos: Vector3, dmg: float, headshot: bool) -> void:
	var label3d := Label3D.new()
	label3d.text = str(int(round(dmg)))
	label3d.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label3d.font_size = 48 if headshot else 34
	label3d.modulate = Color(1.0, 0.15, 0.15) if headshot else Color(1.0, 0.90, 0.25)
	label3d.outline_size = 6
	label3d.outline_modulate = Color(0, 0, 0, 0.85)
	label3d.position = pos + Vector3(randf_range(-0.3, 0.3), randf_range(0.2, 0.5), randf_range(-0.3, 0.3))
	add_child(label3d)

	var tw := label3d.create_tween()
	tw.tween_property(label3d, "position:y", label3d.position.y + 1.6, 0.75).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(label3d, "modulate:a", 0.0, 0.75)
	tw.tween_callback(label3d.queue_free)

func _on_gloo_count_changed(count: int) -> void:
	if gloo_btn:
		gloo_btn.text = "GLOO WALL  x%d" % count if mobile_controls_enabled else "GLOO WALL [G]  x%d" % count

func _on_player_took_damage(amount: float, _from_pos: Vector3) -> void:
	damage_vignette.color.a = minf(0.7, damage_vignette.color.a + amount * 0.015)

func _on_player_reload() -> void:
	crosshair.set_reload(player.is_reloading)

func _on_player_weapon_changed(_key: String) -> void:
	_update_hud()

func _on_player_ads_changed(ads: bool, is_sniper: bool) -> void:
	if is_sniper and ads:
		sniper_scope.visible = true
		crosshair.visible = false
	else:
		sniper_scope.visible = false
		crosshair.visible = (player.drop_state == PlayerScript.DropState.GROUND)

func _on_player_aim_target_changed(has_target: bool, is_head: bool) -> void:
	crosshair.set_on_target(has_target, is_head)

func _on_player_drop_state_changed(d_state: int, alt: float, spd: float) -> void:
	match d_state:
		PlayerScript.DropState.FREEFALL:
			drop_hud.visible = true
			crosshair.visible = false
			drop_alt_label.text = "ALTITUDE: %dm" % int(alt)
			drop_speed_label.text = "DIVING SPEED: %d km/h" % int(spd)
			drop_eject_btn.text = "DEPLOY PARACHUTE (SPACE)"
		PlayerScript.DropState.PARACHUTING:
			drop_hud.visible = true
			crosshair.visible = false
			drop_alt_label.text = "ALTITUDE: %dm" % int(alt)
			drop_speed_label.text = "GLIDING SPEED: %d km/h" % int(spd)
			drop_eject_btn.text = "PARACHUTING..."
		PlayerScript.DropState.GROUND:
			drop_hud.visible = false
			crosshair.visible = true
			_show_toast("TOUCHDOWN! GRAB WEAPONS AND SURVIVE!")

func _on_bot_eliminated(bot: Node, killer_name: String) -> void:
	var victim_name: String = str(bot.get("char_name")) if bot != null else "Enemy"
	alive_bots = maxi(0, alive_bots - 1)
	if is_instance_valid(bot):
		bot.queue_free()
	var is_player_kill := is_instance_valid(player) and killer_name == String(player.char_name)
	if is_player_kill:
		GameManager.register_kill()
		_add_kill("You", victim_name)
		_show_toast("ELIMINATED %s" % victim_name)
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
	var sb := ThemeManager.card_stylebox(8, 0.85)
	sb.set_content_margin_all(8)
	sb.content_margin_left = 12
	sb.content_margin_right = 12
	entry.add_theme_stylebox_override("normal", sb)
	kill_feed.add_child(entry)
	while kill_feed.get_child_count() > 5:
		var old := kill_feed.get_child(0)
		kill_feed.remove_child(old)
		old.queue_free()
	var tw := create_tween()
	tw.tween_interval(3.2)
	tw.tween_property(entry, "modulate:a", 0.0, 1.0)
	tw.tween_callback(entry.queue_free)

func _show_toast(text: String) -> void:
	toast_label.text = text
	toast_label.visible = true
	toast_label.modulate.a = 1.0
	toast_timer = 2.4

func _process(delta: float) -> void:
	if toast_timer > 0.0:
		toast_timer -= delta
		if toast_timer <= 0.0:
			toast_label.visible = false
		elif toast_timer < 0.6:
			toast_label.modulate.a = toast_timer / 0.6
	if damage_vignette and damage_vignette.color.a > 0.0:
		damage_vignette.color.a = move_toward(damage_vignette.color.a, 0.0, 0.6 * delta)

# ============================ Match End Results ============================
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
	var reward: Dictionary = PlayerData.add_match_result(kills, placement, 20, damage)

	var overlay := Control.new()
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	hud.add_child(overlay)

	var dim := ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.03, 0.02, 0.05, 0.88)
	overlay.add_child(dim)

	var card := PanelContainer.new()
	card.set_anchors_preset(Control.PRESET_CENTER)
	card.offset_left = -260; card.offset_right = 260
	card.offset_top = -240; card.offset_bottom = 240
	card.add_theme_stylebox_override("panel", ThemeManager.panel_stylebox(18, 0.98))
	overlay.add_child(card)

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 14)
	card.add_child(col)

	var title := Label.new()
	title.text = "BOOYAH!" if won else "ELIMINATED"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 58)
	title.add_theme_color_override("font_color", ThemeManager.COL_PURPLE_2 if won else ThemeManager.COL_RED)
	col.add_child(title)

	var place := Label.new()
	place.text = "#%d / 20" % placement
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
	_result_row(grid, "Damage Dealt", str(damage))
	_result_row(grid, "XP Gain", "+%d" % int(reward["xp"]))
	_result_row(grid, "Coins", "+%d" % int(reward["coins"]), ThemeManager.COL_AMBER)
	_result_row(grid, "Diamonds", "+%d" % int(reward["diamonds"]), ThemeManager.COL_CYAN)

	var lvl := Label.new()
	lvl.text = "Level %d   ·   XP %d / %d" % [PlayerData.level, PlayerData.xp, PlayerData.XP_PER_LEVEL]
	lvl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lvl.add_theme_color_override("font_color", ThemeManager.COL_TEXT_DIM)
	col.add_child(lvl)

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

# ============================ Mobile Touch Controls ============================
class MobileLookArea extends Control:
	var player: Node
	var active_touch := -1

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_STOP

	func _gui_input(event: InputEvent) -> void:
		if event is InputEventScreenTouch:
			if event.pressed and active_touch == -1:
				active_touch = event.index
				accept_event()
			elif not event.pressed and event.index == active_touch:
				active_touch = -1
				accept_event()
		elif event is InputEventScreenDrag and event.index == active_touch:
			if is_instance_valid(player):
				player.call("apply_touch_look", event.screen_relative)
			accept_event()

class MobileJoystick extends Control:
	signal value_changed(value: Vector2)

	var value := Vector2.ZERO
	var active_touch := -1

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_STOP
		queue_redraw()

	func _gui_input(event: InputEvent) -> void:
		if event is InputEventScreenTouch:
			if event.pressed and active_touch == -1:
				active_touch = event.index
				_update_from_position(event.position)
				accept_event()
			elif not event.pressed and event.index == active_touch:
				active_touch = -1
				_set_value(Vector2.ZERO)
				accept_event()
		elif event is InputEventScreenDrag and event.index == active_touch:
			_update_from_position(event.position)
			accept_event()

	func _update_from_position(position: Vector2) -> void:
		var radius := maxf(1.0, minf(size.x, size.y) * 0.42)
		var next_value := ((position - size * 0.5) / radius).limit_length(1.0)
		if next_value.length() < 0.12:
			next_value = Vector2.ZERO
		_set_value(next_value)

	func _set_value(next_value: Vector2) -> void:
		value = next_value
		value_changed.emit(value)
		queue_redraw()

	func _draw() -> void:
		var center := size * 0.5
		var radius := minf(size.x, size.y) * 0.42
		draw_circle(center, radius, Color(0.04, 0.03, 0.07, 0.48))
		draw_arc(center, radius, 0.0, TAU, 48, Color(ThemeManager.COL_PURPLE.r, ThemeManager.COL_PURPLE.g, ThemeManager.COL_PURPLE.b, 0.82), 3.0, true)
		draw_circle(center + value * radius * 0.62, radius * 0.38, Color(ThemeManager.COL_PURPLE.r, ThemeManager.COL_PURPLE.g, ThemeManager.COL_PURPLE.b, 0.72))

# ============================ Horizontal 360° Compass Bar ============================
class CompassBar extends Control:
	var current_deg := 0.0

	func set_heading(rad: float) -> void:
		var deg := rad_to_deg(rad)
		deg = fmod(deg, 360.0)
		if deg < 0.0:
			deg += 360.0
		if abs(current_deg - deg) > 0.5:
			current_deg = deg
			queue_redraw()

	func _draw() -> void:
		var size := get_size()
		var center_x := size.x * 0.5
		var bar_h := size.y

		# Semi-transparent backing
		draw_rect(Rect2(Vector2.ZERO, size), Color(0.04, 0.03, 0.07, 0.65))

		# Center indicator needle
		draw_polygon(
			PackedVector2Array([Vector2(center_x - 5, bar_h), Vector2(center_x + 5, bar_h), Vector2(center_x, bar_h - 8)]),
			PackedColorArray([ThemeManager.COL_AMBER, ThemeManager.COL_AMBER, ThemeManager.COL_AMBER])
		)

		# Draw ticks and cardinal directions
		var pixels_per_deg := size.x / 120.0
		var min_d := current_deg - 60.0
		var max_d := current_deg + 60.0

		for d_int in range(int(floor(min_d / 15.0)) * 15, int(ceil(max_d / 15.0)) * 15 + 1, 15):
			var norm_deg := fmod(float(d_int), 360.0)
			if norm_deg < 0.0:
				norm_deg += 360.0
			var offset_deg := float(d_int) - current_deg
			var x := center_x + offset_deg * pixels_per_deg

			if x < 4.0 or x > size.x - 4.0:
				continue

			var tag := ""
			match int(round(norm_deg)):
				0, 360: tag = "N"
				45:     tag = "NE"
				90:     tag = "E"
				135:    tag = "SE"
				180:    tag = "S"
				225:    tag = "SW"
				270:    tag = "W"
				315:    tag = "NW"
				_:      tag = str(int(round(norm_deg)))

			var is_cardinal := (tag in ["N", "E", "S", "W", "NE", "SE", "SW", "NW"])
			var col := ThemeManager.COL_AMBER if is_cardinal else Color(0.85, 0.85, 0.90, 0.75)
			draw_line(Vector2(x, bar_h - 4), Vector2(x, bar_h - 10 if is_cardinal else bar_h - 7), col, 1.5)

# ============================ Free Fire Dynamic Crosshair & Scope ============================
class FreeFireCrosshair extends Control:
	var gap := 8.0
	var len := 10.0
	var thick := 2.2
	var on_target := false
	var is_head := false
	var reloading := false

	func _draw() -> void:
		var c := Color(1, 1, 1, 0.9)
		if reloading:
			c = Color(1.0, 0.7, 0.1, 0.95)
		elif on_target:
			c = Color(1.0, 0.15, 0.15, 1.0) # Free Fire Red Aim lock

		var s := get_size() * 0.5
		var ht := thick * 0.5
		var cur_gap := gap * (1.3 if not on_target else 0.8)

		draw_rect(Rect2(s.x - ht, s.y - cur_gap - len, thick, len), c)
		draw_rect(Rect2(s.x - ht, s.y + cur_gap, thick, len), c)
		draw_rect(Rect2(s.x - cur_gap - len, s.y - ht, len, thick), c)
		draw_rect(Rect2(s.x + cur_gap, s.y - ht, len, thick), c)
		draw_circle(s, 1.8 if not on_target else 2.6, c)

	func set_on_target(target: bool, head: bool) -> void:
		if on_target != target or is_head != head:
			on_target = target
			is_head = head
			queue_redraw()

	func set_reload(r: bool) -> void:
		if reloading != r:
			reloading = r
			queue_redraw()

class SniperScopeOverlay extends Control:
	func _draw() -> void:
		var vp_size := get_size()
		var center := vp_size * 0.5
		var radius := minf(center.x, center.y) * 0.78

		draw_rect(Rect2(Vector2.ZERO, vp_size), Color(0.01, 0.01, 0.02, 0.95))
		draw_arc(center, radius, 0, TAU, 128, Color(0.1, 0.85, 1.0, 0.85), 3.0, true)
		draw_arc(center, radius + 2.0, 0, TAU, 128, Color(0, 0, 0, 1.0), 4.0, true)

		var line_col := Color(0.0, 0.0, 0.0, 0.9)
		var center_col := Color(1.0, 0.15, 0.15, 0.95)

		draw_line(Vector2(center.x - radius, center.y), Vector2(center.x + radius, center.y), line_col, 2.0)
		draw_line(Vector2(center.x, center.y - radius), Vector2(center.x, center.y + radius), line_col, 2.0)

		for offset in [-120, -60, 60, 120]:
			draw_circle(Vector2(center.x + offset, center.y), 2.2, line_col)
			draw_circle(Vector2(center.x, center.y + offset), 2.2, line_col)

		draw_circle(center, 3.2, center_col)

class HitMarker extends Control:
	var alpha := 0.0
	func _draw() -> void:
		if alpha <= 0.0:
			return
		var s := get_size() * 0.5
		var c := Color(1, 0.2, 0.2, alpha)
		for ang in [PI / 4.0, 3.0 * PI / 4.0, 5.0 * PI / 4.0, 7.0 * PI / 4.0]:
			var d := Vector2(cos(ang), sin(ang))
			draw_line(s + d * 5.0, s + d * 12.0, c, 2.5)
	func show_marker() -> void:
		alpha = 1.0
		queue_redraw()
	func _process(delta: float) -> void:
		if alpha > 0.0:
			alpha = maxf(0.0, alpha - delta * 3.5)
			queue_redraw()
