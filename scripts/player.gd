extends CharacterBody3D
# Responsive Free Fire Third-Person Player Controller:
# Independent camera look, smooth directional turning (no backward moonwalk),
# procedural running & weapon holding animations, ADS aiming, Gloo Wall tactical shield deployment.

signal died
signal shot_fired(weapon_key: String)
signal hit_landed(target: Node, damage: float, headshot: bool, hit_pos: Vector3)
signal reloaded
signal took_damage(amount: float, from_pos: Vector3)
signal weapon_changed(weapon_key: String)
signal ads_changed(is_ads: bool, is_sniper: bool)
signal aim_target_changed(has_target: bool, is_headshot: bool)
signal drop_state_changed(state: int, altitude: float, speed: float)
signal gloo_wall_count_changed(count: int)

enum DropState {
	IN_PLANE,
	FREEFALL,
	PARACHUTING,
	GROUND
}

const WEAPONS := {
	"ak47": {
		"name": "AK47",
		"category": "Assault Rifle",
		"damage": 36.0,
		"headshot_mult": 2.2,
		"fire_rate": 0.11,
		"mag_size": 30,
		"reserve_max": 210,
		"reload_time": 1.7,
		"recoil": 0.55,
		"spread_hip": 0.025,
		"spread_ads": 0.004,
		"range": 160.0,
		"ads_fov": 50.0,
		"is_sniper": false,
		"pellets": 1
	},
	"mp40": {
		"name": "MP40",
		"category": "SMG",
		"damage": 22.0,
		"headshot_mult": 2.0,
		"fire_rate": 0.075,
		"mag_size": 32,
		"reserve_max": 240,
		"reload_time": 1.35,
		"recoil": 0.38,
		"spread_hip": 0.038,
		"spread_ads": 0.008,
		"range": 75.0,
		"ads_fov": 58.0,
		"is_sniper": false,
		"pellets": 1
	},
	"awm": {
		"name": "AWM",
		"category": "Sniper Rifle",
		"damage": 150.0,
		"headshot_mult": 2.5,
		"fire_rate": 1.25,
		"mag_size": 5,
		"reserve_max": 35,
		"reload_time": 2.4,
		"recoil": 2.2,
		"spread_hip": 0.06,
		"spread_ads": 0.0008,
		"range": 350.0,
		"ads_fov": 26.0,
		"is_sniper": true,
		"pellets": 1
	},
	"m1887": {
		"name": "M1887",
		"category": "Shotgun",
		"damage": 19.0,
		"headshot_mult": 1.75,
		"fire_rate": 0.55,
		"mag_size": 2,
		"reserve_max": 40,
		"reload_time": 1.15,
		"recoil": 1.4,
		"spread_hip": 0.070,
		"spread_ads": 0.030,
		"range": 45.0,
		"ads_fov": 64.0,
		"is_sniper": false,
		"pellets": 6
	}
}

const MAX_HEALTH := 100.0
const MAX_ARMOR  := 100.0

var gravity: float = 24.0
var walk_speed: float = 7.0
var sprint_speed: float = 11.5
var health: float = MAX_HEALTH
var armor: float = 0.0

# Free Fire Tactical Gloo Walls
var gloo_walls: int = 3

# Weapons Inventory & Current State
var inventory: Array[String] = ["ak47", "mp40", "awm", "m1887"]
var weapon_index := 0
var current_weapon_key := "ak47"
var mag_ammo := {}
var res_ammo := {}

# Active weapon stats
var ammo: int = 30
var reserve_ammo: int = 150
var fire_timer: float = 0.0
var reload_timer: float = 0.0
var is_reloading := false
var is_ads := false
var target_fov: float = 75.0
var mobile_move_vector := Vector2.ZERO
var mobile_shooting := false
var mobile_aiming := false
var mobile_sprinting := false
var mobile_jump_requested := false

# Camera Angles (Independent from character mesh)
var cam_yaw: float = 0.0
var cam_pitch: float = deg_to_rad(-8.0)
var recoil_pitch := 0.0
var look_sensitivity: float = 0.0036
var target_mesh_yaw: float = 0.0
var stride_time: float = 0.0

# Aim assist & Free Fire red crosshair
var is_aiming_at_enemy := false
var is_aiming_at_head := false

# Drop state
var drop_state: DropState = DropState.GROUND
var freefall_speed: float = 35.0
var parachute_speed: float = 7.0

# General state
var mouse_captured := true
var last_damage_time: float = -999.0
var regen_rate: float = 7.0
var regen_delay: float = 5.0
var alive: bool = true
var frozen := false
var char_name := "You"
var last_attacker_name := ""
var total_damage_dealt := 0.0

# 3D Node references
var spring_arm: SpringArm3D
var camera: Camera3D
var ray: RayCast3D
var visual_root: Node3D
var weapon_mount: Node3D
var parachute_canopy: Node3D
var muzzle_point: Marker3D

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	char_name = PlayerData.username

	for key in WEAPONS.keys():
		var w: Dictionary = WEAPONS[key]
		mag_ammo[key] = w["mag_size"]
		res_ammo[key] = w["reserve_max"]

	current_weapon_key = PlayerData.selected_weapon if WEAPONS.has(PlayerData.selected_weapon) else "ak47"
	weapon_index = inventory.find(current_weapon_key)
	if weapon_index == -1:
		weapon_index = 0
		current_weapon_key = inventory[0]
	_sync_active_weapon_stats()

	_build_3d_hierarchy()
	_apply_character_skin(PlayerData.selected_character)

func _sync_active_weapon_stats() -> void:
	ammo = mag_ammo.get(current_weapon_key, 30)
	reserve_ammo = res_ammo.get(current_weapon_key, 120)

func _build_3d_hierarchy() -> void:
	spring_arm = get_node_or_null("SpringArm3D") as SpringArm3D
	if spring_arm == null:
		spring_arm = SpringArm3D.new()
		spring_arm.name = "SpringArm3D"
		spring_arm.spring_length = 3.2
		spring_arm.position = Vector3(0.55, 1.55, 0)
		spring_arm.collision_mask = 1
		add_child(spring_arm)

	camera = spring_arm.get_node_or_null("Camera3D") as Camera3D
	if camera == null:
		camera = Camera3D.new()
		camera.name = "Camera3D"
		camera.fov = 75.0
		spring_arm.add_child(camera)

	camera.current = true

	ray = camera.get_node_or_null("RayCast3D") as RayCast3D
	if ray == null:
		ray = RayCast3D.new()
		ray.name = "RayCast3D"
		ray.target_position = Vector3(0, 0, -350)
		ray.collision_mask = 3
		camera.add_child(ray)
	ray.add_exception(self)

func _apply_character_skin(skin_key: String) -> void:
	if visual_root and is_instance_valid(visual_root):
		visual_root.queue_free()

	visual_root = CatCharacterBuilder.build_cat_soldier(skin_key, current_weapon_key)
	add_child(visual_root)

	weapon_mount = visual_root.get_node_or_null("Torso/WeaponMount")
	parachute_canopy = visual_root.get_node_or_null("ParachuteCanopy")
	_find_muzzle_marker()

func _find_muzzle_marker() -> void:
	if weapon_mount:
		var cur_w = weapon_mount.get_node_or_null("EquippedWeapon")
		if cur_w:
			muzzle_point = cur_w.get_node_or_null("MuzzlePoint")

func get_char_name() -> String:
	return char_name

# ============================ Responsive Mouse Look ============================
func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if not mouse_captured:
			mouse_captured = true
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	if event is InputEventMouseMotion and mouse_captured:
		var sens := look_sensitivity * (0.60 if is_ads else 1.0)
		cam_yaw -= event.relative.x * sens
		cam_pitch = clampf(cam_pitch - event.relative.y * sens, deg_to_rad(-75), deg_to_rad(55))
	elif event.is_action_pressed("toggle_mouse"):
		mouse_captured = not mouse_captured
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED if mouse_captured else Input.MOUSE_MODE_VISIBLE

func apply_touch_look(screen_relative: Vector2) -> void:
	var sens := look_sensitivity * 0.7 * (0.60 if is_ads else 1.0)
	cam_yaw -= screen_relative.x * sens
	cam_pitch = clampf(cam_pitch - screen_relative.y * sens, deg_to_rad(-75), deg_to_rad(55))

func set_mobile_move_vector(value: Vector2) -> void:
	mobile_move_vector = value.limit_length(1.0)

func set_mobile_shooting(pressed: bool) -> void:
	mobile_shooting = pressed

func set_mobile_aiming(pressed: bool) -> void:
	mobile_aiming = pressed

func set_mobile_sprinting(pressed: bool) -> void:
	mobile_sprinting = pressed

func request_mobile_jump() -> void:
	mobile_jump_requested = true

func _movement_input() -> Vector2:
	var keyboard_input := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	return mobile_move_vector if mobile_move_vector.length() > keyboard_input.length() else keyboard_input

func _physics_process(delta: float) -> void:
	if not alive:
		return

	fire_timer -= delta
	recoil_pitch = move_toward(recoil_pitch, 0.0, deg_to_rad(16.0) * delta)

	# Update camera spring arm transform smoothly (centered pivot with yaw-rotated shoulder offset)
	if spring_arm:
		spring_arm.rotation = Vector3(clampf(cam_pitch + recoil_pitch, deg_to_rad(-75), deg_to_rad(55)), cam_yaw, 0)
		var shoulder_x: float = 0.52 if is_ads else 0.46
		var rot_offset: Vector3 = Basis(Vector3.UP, cam_yaw) * Vector3(shoulder_x, 0, 0)
		spring_arm.position = Vector3(rot_offset.x, 1.55, rot_offset.z)
		var target_len: float = 2.0 if is_ads else 3.2
		spring_arm.spring_length = lerpf(spring_arm.spring_length, target_len, 14.0 * delta)

	match drop_state:
		DropState.IN_PLANE:
			if spring_arm:
				spring_arm.spring_length = 9.0
				spring_arm.position = Vector3(0, 3.2, 0)
			return
		DropState.FREEFALL:
			_process_freefall(delta)
			return
		DropState.PARACHUTING:
			_process_parachute(delta)
			return
		DropState.GROUND:
			if not frozen:
				_process_ground_movement(delta)
				_process_combat(delta)
				_process_weapon_switching()
				_process_gloo_wall()

	_process_aim_detection()
	_process_camera_fov(delta)

	# Update procedural animations
	var horiz_spd := Vector2(velocity.x, velocity.z).length()
	stride_time += delta * horiz_spd * 2.2
	var combat_pose := is_ads or mobile_aiming or mobile_shooting or Input.is_action_pressed("shoot")
	CatCharacterBuilder.animate_operative(
		visual_root, velocity, is_on_floor(), combat_pose, cam_pitch, stride_time, delta
	)

	# Out-of-combat regeneration
	var now := Time.get_ticks_msec() / 1000.0
	if now - last_damage_time > regen_delay and health < MAX_HEALTH and alive:
		health = minf(MAX_HEALTH, health + regen_rate * delta)

# ============================ Responsive Movement & Rotation ============================
func _process_ground_movement(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= gravity * delta
	if (Input.is_action_just_pressed("jump") or mobile_jump_requested) and is_on_floor():
		velocity.y = 9.2
		SFXSynthesizer.play_sound(self, "click", -4.0)
		mobile_jump_requested = false
	elif mobile_jump_requested and drop_state == DropState.GROUND:
		mobile_jump_requested = false

	var input_dir := _movement_input()
	var sprinting := (Input.is_action_pressed("sprint") or mobile_sprinting) and input_dir.length() > 0.01 and not is_ads
	var cur_speed := sprint_speed if sprinting else (walk_speed * (0.6 if is_ads else 1.0))
	var accel := 28.0 if is_on_floor() else 6.0

	# Calculate movement vector relative to camera yaw
	var cam_basis := Basis(Vector3.UP, cam_yaw)
	var move_vec := (cam_basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	if move_vec.length() > 0.05:
		velocity.x = move_toward(velocity.x, move_vec.x * cur_speed, accel * delta)
		velocity.z = move_toward(velocity.z, move_vec.z * cur_speed, accel * delta)

		# Orientation logic:
		if is_ads or mobile_aiming or Input.is_action_pressed("shoot") or mobile_shooting:
			# When aiming/shooting: face exact camera crosshair heading
			target_mesh_yaw = cam_yaw
		else:
			# When free running: face the actual direction of motion!
			# When pressing S, target angle faces toward camera, running forward naturally!
			target_mesh_yaw = atan2(-move_vec.x, -move_vec.z)
	else:
		velocity.x = move_toward(velocity.x, 0.0, 24.0 * delta)
		velocity.z = move_toward(velocity.z, 0.0, 24.0 * delta)
		if is_ads or mobile_aiming or Input.is_action_pressed("shoot") or mobile_shooting:
			target_mesh_yaw = cam_yaw

	# Smoothly rotate the visual model toward the target heading
	if visual_root:
		visual_root.rotation.y = lerp_angle(visual_root.rotation.y, target_mesh_yaw, 18.0 * delta)

	move_and_slide()

# ============================ Gloo Wall Deployment ============================
func _process_gloo_wall() -> void:
	if Input.is_action_just_pressed("gloo_wall"):
		deploy_gloo_wall()

func deploy_gloo_wall() -> void:
	if gloo_walls <= 0 or drop_state != DropState.GROUND:
		return
	gloo_walls -= 1
	gloo_wall_count_changed.emit(gloo_walls)

	var wall := CatCharacterBuilder.build_gloo_wall()
	var forward := -Basis(Vector3.UP, cam_yaw).z
	var spawn_pos := global_position + forward * 3.2
	spawn_pos.y = global_position.y
	wall.position = spawn_pos
	wall.rotation.y = cam_yaw
	get_tree().root.add_child(wall)

	SFXSynthesizer.play_sound(self, "parachute", 3.0)

	# Auto-destroy wall after 25 seconds with shrink tween
	var tw := wall.create_tween()
	tw.tween_interval(25.0)
	tw.tween_property(wall, "scale", Vector3(0.01, 0.01, 0.01), 0.5)
	tw.tween_callback(wall.queue_free)

# ============================ Skydiving & Parachuting ============================
func start_skydiving(initial_pos: Vector3) -> void:
	global_position = initial_pos
	drop_state = DropState.FREEFALL
	is_ads = false
	if parachute_canopy:
		parachute_canopy.visible = false
	SFXSynthesizer.play_sound(self, "eject", 2.0)
	drop_state_changed.emit(drop_state, global_position.y, freefall_speed)

func deploy_parachute() -> void:
	if drop_state != DropState.FREEFALL:
		return
	drop_state = DropState.PARACHUTING
	if parachute_canopy:
		parachute_canopy.visible = true
	SFXSynthesizer.play_sound(self, "parachute", 3.0)
	drop_state_changed.emit(drop_state, global_position.y, parachute_speed)

func _process_freefall(delta: float) -> void:
	var input_dir := _movement_input()
	var dive_fast := input_dir.y < -0.1
	var glide := input_dir.y > 0.1

	var target_fall_speed := 55.0 if dive_fast else (26.0 if glide else 38.0)
	freefall_speed = move_toward(freefall_speed, target_fall_speed, 30.0 * delta)
	velocity.y = -freefall_speed

	var cam_basis := Basis(Vector3.UP, cam_yaw)
	var horiz_dir := (cam_basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	var forward_speed := 24.0 if glide else 12.0
	velocity.x = move_toward(velocity.x, horiz_dir.x * forward_speed, 20.0 * delta)
	velocity.z = move_toward(velocity.z, horiz_dir.z * forward_speed, 20.0 * delta)

	if horiz_dir.length() > 0.1 and visual_root:
		visual_root.rotation.y = lerp_angle(visual_root.rotation.y, atan2(-horiz_dir.x, -horiz_dir.z), 12.0 * delta)

	move_and_slide()
	drop_state_changed.emit(drop_state, global_position.y, freefall_speed * 3.6)

	if Input.is_action_just_pressed("jump") or mobile_jump_requested or Input.is_action_just_pressed("eject") or global_position.y <= 32.0:
		mobile_jump_requested = false
		deploy_parachute()

func _process_parachute(delta: float) -> void:
	var input_dir := _movement_input()
	velocity.y = -parachute_speed

	var cam_basis := Basis(Vector3.UP, cam_yaw)
	var horiz_dir := (cam_basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	velocity.x = move_toward(velocity.x, horiz_dir.x * 10.0, 15.0 * delta)
	velocity.z = move_toward(velocity.z, horiz_dir.z * 10.0, 15.0 * delta)

	if horiz_dir.length() > 0.1 and visual_root:
		visual_root.rotation.y = lerp_angle(visual_root.rotation.y, atan2(-horiz_dir.x, -horiz_dir.z), 12.0 * delta)

	move_and_slide()
	drop_state_changed.emit(drop_state, global_position.y, parachute_speed * 3.6)

	if is_on_floor() or global_position.y <= 1.2:
		_touchdown()

func _touchdown() -> void:
	drop_state = DropState.GROUND
	if parachute_canopy:
		parachute_canopy.visible = false
	velocity = Vector3.ZERO
	drop_state_changed.emit(drop_state, global_position.y, 0.0)

# ============================ Weapon Switching ============================
func _process_weapon_switching() -> void:
	if is_reloading:
		return
	if Input.is_action_just_pressed("slot_1"):
		select_weapon_by_slot(0)
	elif Input.is_action_just_pressed("slot_2"):
		select_weapon_by_slot(1)
	elif Input.is_action_just_pressed("slot_3"):
		select_weapon_by_slot(2)
	elif Input.is_action_just_pressed("slot_4"):
		select_weapon_by_slot(3)
	elif Input.is_action_just_pressed("next_weapon"):
		select_weapon_by_slot((weapon_index + 1) % inventory.size())
	elif Input.is_action_just_pressed("prev_weapon"):
		select_weapon_by_slot((weapon_index - 1 + inventory.size()) % inventory.size())

func select_weapon_by_slot(idx: int) -> void:
	if idx < 0 or idx >= inventory.size() or idx == weapon_index:
		return
	weapon_index = idx
	current_weapon_key = inventory[idx]
	_sync_active_weapon_stats()

	if weapon_mount:
		var old = weapon_mount.get_node_or_null("EquippedWeapon")
		if old:
			old.queue_free()
		var nw = CatCharacterBuilder.build_weapon(current_weapon_key)
		nw.name = "EquippedWeapon"
		weapon_mount.add_child(nw)
		_find_muzzle_marker()

	SFXSynthesizer.play_sound(self, "click", 0.0)
	weapon_changed.emit(current_weapon_key)

# ============================ Combat & Aiming ============================
func _process_combat(delta: float) -> void:
	var prev_ads := is_ads
	is_ads = Input.is_action_pressed("aim") or mobile_aiming
	if is_ads != prev_ads:
		var w_cfg: Dictionary = WEAPONS[current_weapon_key]
		ads_changed.emit(is_ads, w_cfg["is_sniper"])

	var w: Dictionary = WEAPONS[current_weapon_key]
	target_fov = w["ads_fov"] if is_ads else 75.0

	if Input.is_action_just_pressed("reload"):
		start_reload()
	if is_reloading:
		reload_timer -= delta
		if reload_timer <= 0.0:
			finish_reload()

	if (Input.is_action_pressed("shoot") or mobile_shooting) and not is_reloading:
		shoot()

func _process_camera_fov(delta: float) -> void:
	if camera:
		camera.fov = lerpf(camera.fov, target_fov, 16.0 * delta)

func _process_aim_detection() -> void:
	if ray == null:
		return
	# Keep the reticle detector centered after spread rays are used for firing.
	ray.target_position = Vector3(0, 0, -350)
	ray.force_raycast_update()
	var has_enemy := false
	var is_head := false
	if ray.is_colliding():
		var col := ray.get_collider()
		if col is CharacterBody3D and col != self:
			if col.has_method("take_damage"):
				has_enemy = true
				var base_y := (col as CharacterBody3D).global_position.y
				is_head = ray.get_collision_point().y - base_y > 1.45

	if has_enemy != is_aiming_at_enemy or is_head != is_aiming_at_head:
		is_aiming_at_enemy = has_enemy
		is_aiming_at_head = is_head
		aim_target_changed.emit(has_enemy, is_head)

func shoot() -> void:
	if fire_timer > 0.0:
		return
	var w: Dictionary = WEAPONS[current_weapon_key]
	if ammo <= 0:
		start_reload()
		return

	fire_timer = w["fire_rate"]
	ammo -= 1
	mag_ammo[current_weapon_key] = ammo

	SFXSynthesizer.play_sound(self, current_weapon_key, 2.0)
	shot_fired.emit(current_weapon_key)

	# Recoil is a short spring that settles back to the player's aim point.
	var recoil_kick: float = w["recoil"] * (0.45 if is_ads else 1.0)
	recoil_pitch = minf(recoil_pitch + deg_to_rad(recoil_kick * 0.9), deg_to_rad(12.0))

	var pellets: int = w["pellets"]
	var spread: float = w["spread_ads"] if is_ads else w["spread_hip"]
	var range_dist: float = w["range"]

	for i in range(pellets):
		_fire_single_ray(spread, range_dist, w)

	if ammo <= 0:
		start_reload()

func _fire_single_ray(spread: float, range_dist: float, w: Dictionary) -> void:
	var spread_offset := Vector3(randf_range(-spread, spread), randf_range(-spread, spread), 0)
	ray.target_position = Vector3(spread_offset.x * range_dist, spread_offset.y * range_dist, -range_dist)
	ray.force_raycast_update()

	var hit_pos: Vector3
	if ray.is_colliding():
		hit_pos = ray.get_collision_point()
		var collider := ray.get_collider()
		if collider is CharacterBody3D and collider != self:
			var cb := collider as CharacterBody3D
			var base_y := cb.global_position.y
			var headshot := hit_pos.y - base_y > 1.45
			if cb.has_method("take_damage"):
				var dmg: float = w["damage"] * (w["headshot_mult"] if headshot else 1.0)
				cb.call("take_damage", dmg, self)
				total_damage_dealt += dmg
				hit_landed.emit(cb, dmg, headshot, hit_pos)
				if headshot:
					SFXSynthesizer.play_sound(self, "headshot", 4.0)
				else:
					SFXSynthesizer.play_sound(self, "hit", 1.0)
	else:
		hit_pos = ray.global_position + ray.global_transform.basis * ray.target_position

	_spawn_tracer(hit_pos)

func _spawn_tracer(target_pos: Vector3) -> void:
	var start_pos := muzzle_point.global_position if (muzzle_point and is_instance_valid(muzzle_point)) else global_position + Vector3(0.25, 1.4, -0.4)
	var tracer := MeshInstance3D.new()
	var line_mesh := ImmediateMesh.new()
	line_mesh.surface_begin(Mesh.PRIMITIVE_LINES)
	line_mesh.surface_set_color(Color(1.0, 0.85, 0.3, 0.9))
	line_mesh.surface_add_vertex(start_pos)
	line_mesh.surface_add_vertex(target_pos)
	line_mesh.surface_end()
	tracer.mesh = line_mesh

	var tmat := StandardMaterial3D.new()
	tmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	tmat.albedo_color = Color(1.0, 0.9, 0.4, 0.9)
	tracer.material_override = tmat
	get_tree().root.add_child(tracer)

	var tw := tracer.create_tween()
	tw.tween_interval(0.06)
	tw.tween_callback(tracer.queue_free)

func start_reload() -> void:
	var w: Dictionary = WEAPONS[current_weapon_key]
	var mag_size: int = w["mag_size"]
	if is_reloading or ammo >= mag_size or reserve_ammo <= 0:
		return
	is_reloading = true
	reload_timer = w["reload_time"]
	SFXSynthesizer.play_sound(self, "reload", 1.0)
	reloaded.emit()

func finish_reload() -> void:
	is_reloading = false
	var w: Dictionary = WEAPONS[current_weapon_key]
	var mag_size: int = w["mag_size"]
	var need := mag_size - ammo
	var take := mini(need, reserve_ammo)
	ammo += take
	reserve_ammo -= take
	mag_ammo[current_weapon_key] = ammo
	res_ammo[current_weapon_key] = reserve_ammo
	reloaded.emit()

func take_damage(amount: float, attacker: Node = null) -> void:
	if not alive:
		return
	last_damage_time = Time.get_ticks_msec() / 1000.0
	if attacker != null and attacker.has_method("get_char_name"):
		last_attacker_name = attacker.call("get_char_name")
	var to_health := amount
	if armor > 0.0:
		var absorbed := minf(armor, amount * 0.5)
		armor -= absorbed
		to_health = amount - absorbed
	health -= to_health
	var from_pos := global_position
	if attacker != null:
		var ac := attacker as Node3D
		if ac != null:
			from_pos = ac.global_position
	took_damage.emit(amount, from_pos)
	if health <= 0.0:
		health = 0.0
		alive = false
		died.emit()

func add_ammo(reserve_amount: int) -> void:
	for k in WEAPONS.keys():
		res_ammo[k] = mini(res_ammo[k] + reserve_amount, WEAPONS[k]["reserve_max"] * 2)
	_sync_active_weapon_stats()

func heal(amount: float) -> void:
	health = minf(MAX_HEALTH, health + amount)

func add_armor(amount: float) -> void:
	armor = minf(MAX_ARMOR, armor + amount)

func add_gloo_walls(amount: int) -> void:
	gloo_walls = mini(gloo_walls + amount, 6)
	gloo_wall_count_changed.emit(gloo_walls)
