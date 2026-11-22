extends CharacterBody3D
# Free Fire style AI combatant:
# 3D Cat operative model, skydiving & parachute drop capabilities,
# engaging enemies, zone retreat, tail sway, and gunfire sound synthesis.

signal eliminated(bot: Node, killer_name: String)

enum DropState {
	IN_PLANE,
	FREEFALL,
	PARACHUTING,
	GROUND
}

var char_name := "Bot"
var health: float = 100.0
var armor: float = 0.0
var gravity: float = 24.0
var speed: float = 4.2
var alive: bool = true
var frozen: bool = false

var weapon_key := "ak47"
var drop_state: DropState = DropState.GROUND
var freefall_speed: float = 30.0
var parachute_speed: float = 6.5
var drop_target: Vector3 = Vector3.ZERO

var target = null
var enemies: Array = []
var zone_center := Vector3.ZERO
var zone_radius: float = 58.0

var roam_angle: float = 0.0
var shoot_timer: float = 1.5
var retarget_timer: float = 0.0
var accuracy: float = 0.28
var damage_min: float = 8.0
var damage_max: float = 16.0
var engage_range: float = 32.0
var detect_range: float = 52.0

# 3D Node references
var visual_root: Node3D
var tail_root: Node3D
var parachute_canopy: Node3D
var stride_time: float = 0.0

func _ready() -> void:
	roam_angle = randf() * TAU
	var weapons_pool = ["ak47", "mp40", "awm", "m1887"]
	weapon_key = weapons_pool[randi() % weapons_pool.size()]

func setup_visual(skin_key: String) -> void:
	if visual_root and is_instance_valid(visual_root):
		visual_root.queue_free()
	visual_root = CatCharacterBuilder.build_cat_soldier(skin_key, weapon_key)
	add_child(visual_root)
	tail_root = visual_root.get_node_or_null("TailRoot")
	parachute_canopy = visual_root.get_node_or_null("ParachuteCanopy")
	if parachute_canopy:
		parachute_canopy.visible = false

func start_skydiving(initial_pos: Vector3, landing_pos: Vector3) -> void:
	global_position = initial_pos
	drop_target = landing_pos
	drop_state = DropState.FREEFALL
	if parachute_canopy:
		parachute_canopy.visible = false

func deploy_parachute() -> void:
	if drop_state != DropState.FREEFALL:
		return
	drop_state = DropState.PARACHUTING
	if parachute_canopy:
		parachute_canopy.visible = true

func get_char_name() -> String:
	return char_name

func set_enemies(list: Array) -> void:
	enemies = list

func _physics_process(delta: float) -> void:
	if not alive or frozen:
		return

	match drop_state:
		DropState.IN_PLANE:
			return
		DropState.FREEFALL:
			_process_bot_freefall(delta)
			return
		DropState.PARACHUTING:
			_process_bot_parachute(delta)
			return
		DropState.GROUND:
			_process_bot_ground(delta)

	var horiz_spd := Vector2(velocity.x, velocity.z).length()
	stride_time += delta * horiz_spd * 2.2
	var is_shooting: bool = (target != null and is_instance_valid(target) and bool(target.get("alive")) and global_position.distance_to(target.global_position) < engage_range)
	CatCharacterBuilder.animate_operative(visual_root, velocity, is_on_floor(), is_shooting, 0.0, stride_time, delta)

func _process_bot_freefall(delta: float) -> void:
	velocity.y = -freefall_speed
	var to_target := drop_target - global_position
	to_target.y = 0.0
	if to_target.length() > 2.0:
		var dir := to_target.normalized()
		velocity.x = dir.x * 16.0
		velocity.z = dir.z * 16.0
		look_at(Vector3(drop_target.x, global_position.y, drop_target.z), Vector3.UP)
	move_and_slide()

	if global_position.y <= randf_range(25.0, 35.0):
		deploy_parachute()

func _process_bot_parachute(delta: float) -> void:
	velocity.y = -parachute_speed
	var to_target := drop_target - global_position
	to_target.y = 0.0
	if to_target.length() > 2.0:
		var dir := to_target.normalized()
		velocity.x = dir.x * 8.0
		velocity.z = dir.z * 8.0
	move_and_slide()

	if is_on_floor() or global_position.y <= 1.2:
		drop_state = DropState.GROUND
		if parachute_canopy:
			parachute_canopy.visible = false
		velocity = Vector3.ZERO

func _process_bot_ground(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= gravity * delta

	retarget_timer -= delta
	if retarget_timer <= 0.0:
		retarget_timer = 0.45
		_acquire_target()

	var flat := global_position - zone_center
	flat.y = 0.0
	var dist_to_zone := flat.length()

	var direction: Vector3
	if dist_to_zone > zone_radius - 4.0:
		direction = -flat.normalized() if dist_to_zone > 0.01 else Vector3.FORWARD
	elif target != null and is_instance_valid(target) and target.get("alive"):
		var tpos: Vector3 = target.global_position
		var to_t := tpos - global_position
		to_t.y = 0.0
		var d := to_t.length()
		if d > 0.01:
			direction = to_t.normalized()
			look_at(Vector3(tpos.x, global_position.y, tpos.z), Vector3.UP)
			shoot_timer -= delta
			if d < engage_range and shoot_timer <= 0.0:
				shoot_timer = randf_range(0.75, 1.6)
				SFXSynthesizer.play_3d_sound(self, weapon_key, global_position, -2.0)
				if randf() < accuracy:
					target.call("take_damage", randf_range(damage_min, damage_max), self)
		else:
			direction = Vector3(cos(roam_angle), 0.0, sin(roam_angle))
			roam_angle += randf_range(-0.8, 0.8) * delta
	else:
		direction = Vector3(cos(roam_angle), 0.0, sin(roam_angle))
		roam_angle += randf_range(-0.8, 0.8) * delta

	velocity.x = move_toward(velocity.x, direction.x * speed, 7.0 * delta)
	velocity.z = move_toward(velocity.z, direction.z * speed, 7.0 * delta)
	move_and_slide()

func _acquire_target() -> void:
	var best = null
	var best_dist := detect_range
	for e in enemies:
		if e == null or e == self or not is_instance_valid(e):
			continue
		if not e.get("alive"):
			continue
		var ec: CharacterBody3D = e
		if ec == null:
			continue
		var d := global_position.distance_to(ec.global_position)
		if d < best_dist:
			best_dist = d
			best = ec
	target = best

func take_damage(amount: float, attacker: Node = null) -> void:
	if not alive:
		return
	var to_health := amount
	if armor > 0.0:
		var absorbed := minf(armor, amount * 0.4)
		armor -= absorbed
		to_health = amount - absorbed
	health -= to_health
	if attacker != null and (target == null or not is_instance_valid(target) or not target.get("alive")):
		var ac := attacker as CharacterBody3D
		if ac != null and ac != self:
			target = ac
	if health <= 0.0:
		health = 0.0
		alive = false
		var kname := "the zone"
		if attacker != null and attacker.has_method("get_char_name"):
			kname = attacker.call("get_char_name")
		eliminated.emit(self, kname)

func _process_tail_sway(delta: float) -> void:
	if tail_root == null:
		return
	var speed_mult := 10.0 if velocity.length() > 0.1 else 3.5
	var wave := sin(Time.get_ticks_msec() * 0.001 * speed_mult) * 16.0
	tail_root.rotation_degrees.y = wave
