class_name CatCharacterBuilder
extends RefCounted
# Builds and animates stylized Free Fire 3D anthropomorphic cat operatives,
# cat pet companions, realistic weapons, Gloo Walls, and the iconic Bermuda Red Bridge.

const HERO_SKINS := {
	"purple": {
		"name": "Sofai (Neon Shadow)",
		"primary": Color(0.58, 0.22, 0.98),       # Electric purple
		"secondary": Color(0.12, 0.08, 0.18),     # Dark obsidian tactical
		"accent": Color(0.0, 0.88, 1.0),          # Cyan glow
		"fur": Color(0.18, 0.16, 0.22),           # Dark sleek fur
		"inner_ear": Color(0.95, 0.45, 0.75),     # Pinkish glow
		"visor": Color(0.0, 0.95, 1.0),           # Cyan visor
	},
	"red": {
		"name": "Crimson (Fire Claw)",
		"primary": Color(0.95, 0.18, 0.22),       # Crimson combat red
		"secondary": Color(0.14, 0.10, 0.10),     # Matte tactical black
		"accent": Color(1.0, 0.65, 0.15),         # Fiery amber
		"fur": Color(0.24, 0.14, 0.14),           # Dark reddish charcoal fur
		"inner_ear": Color(1.0, 0.35, 0.35),      # Reddish pink
		"visor": Color(1.0, 0.75, 0.1),           # Amber visor
	},
	"blue": {
		"name": "Cobalt (Ghost Hunter)",
		"primary": Color(0.12, 0.48, 0.98),       # Cobalt cyber blue
		"secondary": Color(0.08, 0.12, 0.20),     # Navy spec-ops
		"accent": Color(0.3, 0.95, 0.85),         # Mint / teal
		"fur": Color(0.12, 0.15, 0.24),           # Navy fur
		"inner_ear": Color(0.4, 0.75, 1.0),       # Light blue
		"visor": Color(0.2, 0.9, 1.0),            # Cyan blue visor
	}
}

# ============================ Cat Operative Model ============================
static func build_cat_soldier(skin_key: String = "purple", weapon_key: String = "ak47") -> Node3D:
	var skin: Dictionary = HERO_SKINS.get(skin_key, HERO_SKINS["purple"])
	var root := Node3D.new()
	root.name = "CatSoldier"

	var mat_primary := _make_mat(skin.primary, true, skin.primary, 0.35)
	var mat_secondary := _make_mat(skin.secondary)
	var mat_accent := _make_mat(skin.accent, true, skin.accent, 1.2)
	var mat_fur := _make_mat(skin.fur)
	var mat_inner_ear := _make_mat(skin.inner_ear, true, skin.inner_ear, 0.3)
	var mat_visor := _make_mat(skin.visor, true, skin.visor, 1.6)
	var mat_metal := _make_mat(Color(0.25, 0.26, 0.30), false, Color.BLACK, 0.0, 0.8, 0.3)
	var mat_skin := _make_mat(Color(0.96, 0.80, 0.68))

	# 1. Torso Pivot (Y = 0.90 at hips, moves with breathing/running)
	var torso := Node3D.new()
	torso.name = "Torso"
	torso.position = Vector3(0, 0.92, 0)
	root.add_child(torso)

	# Main chest jacket (local Y: 0.35)
	_add_box(torso, Vector3(0.52, 0.52, 0.36), mat_primary, Vector3(0, 0.32, 0))
	# Chest armor plate / harness in front (-Z)
	_add_box(torso, Vector3(0.42, 0.36, 0.12), mat_secondary, Vector3(0, 0.35, -0.16))
	# Free Fire style glowing neon logo stripe in front (-Z)
	_add_box(torso, Vector3(0.28, 0.04, 0.02), mat_accent, Vector3(0, 0.42, -0.23))
	# Collar / hoodie neck
	_add_cylinder(torso, 0.20, 0.12, mat_primary, Vector3(0, 0.62, 0))

	# Belt & ammo pouches at hip line
	_add_box(torso, Vector3(0.54, 0.10, 0.38), mat_secondary, Vector3(0, 0.04, 0))
	_add_box(torso, Vector3(0.12, 0.12, 0.04), mat_accent, Vector3(0, 0.04, -0.20))
	for side in [-1, 1]:
		_add_box(torso, Vector3(0.10, 0.12, 0.14), mat_secondary, Vector3(side * 0.25, 0.04, -0.06))

	# Parachute Survival Pack on back (+Z)
	_add_box(torso, Vector3(0.38, 0.44, 0.20), mat_secondary, Vector3(0, 0.34, 0.22))
	_add_box(torso, Vector3(0.34, 0.06, 0.02), mat_accent, Vector3(0, 0.42, 0.33))
	_add_box(torso, Vector3(0.34, 0.06, 0.02), mat_accent, Vector3(0, 0.24, 0.33))

	# 2. Cat Head & Ears (child of Torso at Y: 0.78, facing -Z)
	var head_node := Node3D.new()
	head_node.name = "Head"
	head_node.position = Vector3(0, 0.78, 0)
	torso.add_child(head_node)

	# Cranium
	_add_sphere(head_node, 0.26, mat_fur, Vector3.ZERO)
	# Cat muzzle/snout in front (-Z)
	_add_box(head_node, Vector3(0.16, 0.12, 0.16), mat_skin, Vector3(0, -0.06, -0.20))
	# Nose in front (-Z)
	_add_box(head_node, Vector3(0.05, 0.04, 0.02), mat_inner_ear, Vector3(0, -0.03, -0.29))
	# Glowing cyber visor / cat eyes in front (-Z)
	_add_box(head_node, Vector3(0.34, 0.09, 0.10), mat_visor, Vector3(0, 0.06, -0.22))
	# Tactical headset
	_add_box(head_node, Vector3(0.54, 0.05, 0.14), mat_secondary, Vector3(0, 0.12, 0))
	for side in [-1, 1]:
		_add_cylinder(head_node, 0.07, 0.06, mat_metal, Vector3(side * 0.28, 0.04, 0), Vector3(0, 0, PI / 2.0))

	# Triangular cat ears with inner ear color
	for side in [-1, 1]:
		var ear_base := Node3D.new()
		ear_base.position = Vector3(side * 0.18, 0.24, -0.02)
		ear_base.rotation_degrees = Vector3(8, side * -12, side * -18)
		head_node.add_child(ear_base)
		_add_prism(ear_base, Vector3(0.18, 0.26, 0.12), mat_primary)
		_add_prism(ear_base, Vector3(0.12, 0.19, 0.06), mat_inner_ear, Vector3(0, -0.02, -0.04))
		_add_sphere(ear_base, 0.03, mat_accent, Vector3(0, 0.14, 0))

	# 3. Dynamic Cat Tail (child of Torso on back +Z)
	var tail_root := Node3D.new()
	tail_root.name = "TailRoot"
	tail_root.position = Vector3(0, 0.02, 0.18)
	torso.add_child(tail_root)

	var prev_seg = tail_root
	var seg_count := 5
	for i in range(seg_count):
		var seg := Node3D.new()
		seg.name = "Seg_%d" % i
		seg.position = Vector3(0, 0.07 if i > 0 else 0, 0.10 if i < 3 else 0.04)
		if i == 0:
			seg.rotation_degrees = Vector3(25, 0, 0)
		elif i == 2:
			seg.rotation_degrees = Vector3(-30, 0, 0)
		elif i == 4:
			seg.rotation_degrees = Vector3(-40, 0, 0)
		prev_seg.add_child(seg)
		var seg_mat = mat_accent if i == seg_count - 1 else mat_primary
		var radius = lerpf(0.065, 0.038, float(i) / float(seg_count))
		_add_sphere(seg, radius, seg_mat, Vector3.ZERO)
		prev_seg = seg

	# 4. Articulated Legs (pivots at hips Y: 0.90)
	var left_leg := Node3D.new()
	left_leg.name = "LeftLeg"
	left_leg.position = Vector3(-0.16, 0.90, 0)
	root.add_child(left_leg)
	_build_leg_mesh(left_leg, mat_primary, mat_secondary, mat_accent)

	var right_leg := Node3D.new()
	right_leg.name = "RightLeg"
	right_leg.position = Vector3(0.16, 0.90, 0)
	root.add_child(right_leg)
	_build_leg_mesh(right_leg, mat_primary, mat_secondary, mat_accent)

	# 5. Articulated Arms (children of Torso with shoulder pivots at Y: 0.48)
	var right_arm := Node3D.new()
	right_arm.name = "RightArm"
	right_arm.position = Vector3(0.32, 0.48, 0)
	torso.add_child(right_arm)
	_add_sphere(right_arm, 0.12, mat_primary, Vector3.ZERO) # Shoulder
	_add_capsule(right_arm, 0.08, 0.32, mat_secondary, Vector3(0.04, -0.16, -0.06))
	# Right Hand
	var right_hand := _add_box(right_arm, Vector3(0.13, 0.15, 0.15), mat_primary, Vector3(0.06, -0.32, -0.18))
	_add_sphere(right_hand, 0.035, mat_accent, Vector3(0, 0, -0.08))

	var left_arm := Node3D.new()
	left_arm.name = "LeftArm"
	left_arm.position = Vector3(-0.32, 0.48, 0)
	torso.add_child(left_arm)
	_add_sphere(left_arm, 0.12, mat_primary, Vector3.ZERO)
	_add_capsule(left_arm, 0.08, 0.32, mat_secondary, Vector3(-0.04, -0.16, -0.10))
	var left_hand := _add_box(left_arm, Vector3(0.13, 0.15, 0.15), mat_primary, Vector3(0.04, -0.28, -0.28))
	_add_sphere(left_hand, 0.035, mat_accent, Vector3(0, 0, -0.08))

	# 6. Weapon Mount (mounted to Torso/Right hand in front of body at -Z)
	var weapon_mount := Node3D.new()
	weapon_mount.name = "WeaponMount"
	weapon_mount.position = Vector3(0.22, 0.25, -0.34)
	torso.add_child(weapon_mount)

	var weapon_node := build_weapon(weapon_key)
	weapon_node.name = "EquippedWeapon"
	weapon_mount.add_child(weapon_node)

	# 7. Deployable Parachute Canopy
	var chute := build_parachute_canopy(skin.primary)
	chute.name = "ParachuteCanopy"
	chute.position = Vector3(0, 2.8, 0)
	chute.visible = false
	root.add_child(chute)

	return root

static func _build_leg_mesh(parent: Node3D, mat_pri: StandardMaterial3D, mat_sec: StandardMaterial3D, mat_acc: StandardMaterial3D) -> void:
	# Thigh (from hip down to -0.42)
	_add_capsule(parent, 0.11, 0.42, mat_sec, Vector3(0, -0.22, 0))
	# Knee Guard in front (-Z)
	_add_box(parent, Vector3(0.15, 0.13, 0.06), mat_pri, Vector3(0, -0.40, -0.11))
	# Shin & Combat Boot (from -0.42 down to -0.86)
	_add_box(parent, Vector3(0.17, 0.36, 0.22), mat_sec, Vector3(0, -0.66, -0.02))
	# Boot sole with neon tread pointing forward (-Z)
	_add_box(parent, Vector3(0.19, 0.06, 0.30), mat_acc, Vector3(0, -0.86, -0.05))

# ============================ Procedural Character Animator ============================
static func animate_operative(
	soldier: Node3D,
	velocity: Vector3,
	is_on_floor: bool,
	is_aiming: bool,
	aim_pitch: float,
	stride_time: float,
	delta: float
) -> void:
	if soldier == null or not is_instance_valid(soldier):
		return

	var torso: Node3D = soldier.get_node_or_null("Torso")
	var left_leg: Node3D = soldier.get_node_or_null("LeftLeg")
	var right_leg: Node3D = soldier.get_node_or_null("RightLeg")
	var right_arm: Node3D = soldier.get_node_or_null("Torso/RightArm")
	var left_arm: Node3D = soldier.get_node_or_null("Torso/LeftArm")
	var weapon_mount: Node3D = soldier.get_node_or_null("Torso/WeaponMount")
	var tail: Node3D = soldier.get_node_or_null("Torso/TailRoot")

	var horiz_speed := Vector2(velocity.x, velocity.z).length()
	var moving := horiz_speed > 0.15

	# 1. Walk & Run Leg Swing
	if is_on_floor and moving:
		var swing_amp := 0.70 if horiz_speed > 8.0 else 0.45
		var left_ang := sin(stride_time) * swing_amp
		var right_ang := -sin(stride_time) * swing_amp
		if left_leg:
			left_leg.rotation.x = lerpf(left_leg.rotation.x, left_ang, 22.0 * delta)
		if right_leg:
			right_leg.rotation.x = lerpf(right_leg.rotation.x, right_ang, 22.0 * delta)
		# Torso vertical bounce with stride
		if torso:
			var bob: float = absf(sin(stride_time)) * 0.04
			torso.position.y = lerpf(torso.position.y, 0.92 + bob, 18.0 * delta)
	elif is_on_floor:
		# Idle standing stance
		if left_leg:
			left_leg.rotation.x = lerpf(left_leg.rotation.x, 0.0, 14.0 * delta)
		if right_leg:
			right_leg.rotation.x = lerpf(right_leg.rotation.x, 0.0, 14.0 * delta)
		if torso:
			# Gentle idle breathing
			var breath := sin(Time.get_ticks_msec() * 0.0025) * 0.015
			torso.position.y = lerpf(torso.position.y, 0.92 + breath, 10.0 * delta)
	else:
		# In air / Jump: tuck legs slightly back
		if left_leg:
			left_leg.rotation.x = lerpf(left_leg.rotation.x, -0.35, 14.0 * delta)
		if right_leg:
			right_leg.rotation.x = lerpf(right_leg.rotation.x, -0.45, 14.0 * delta)

	# 2. Weapon Holding & Arm Poses (Positive X swings arms forward towards -Z)
	if is_aiming:
		# Aim Down Sights (ADS) pose: gun raised to eye level, torso pitches up/down
		if torso:
			torso.rotation.x = lerpf(torso.rotation.x, -aim_pitch, 20.0 * delta)
		if right_arm:
			right_arm.rotation_degrees = right_arm.rotation_degrees.lerp(Vector3(75, 12, 8), 22.0 * delta)
		if left_arm:
			left_arm.rotation_degrees = left_arm.rotation_degrees.lerp(Vector3(70, -32, -18), 22.0 * delta)
		if weapon_mount:
			weapon_mount.position = weapon_mount.position.lerp(Vector3(0.08, 0.42, -0.28), 22.0 * delta)
			weapon_mount.rotation_degrees = Vector3.ZERO
	elif moving and horiz_speed > 8.0:
		# Tactical Sprint: weapon lowered slightly, arms bobbing rhythmically
		if torso:
			torso.rotation.x = lerpf(torso.rotation.x, deg_to_rad(-10), 14.0 * delta)
		if right_arm:
			var r_swing := sin(stride_time) * 12.0
			right_arm.rotation_degrees = right_arm.rotation_degrees.lerp(Vector3(30 + r_swing, 16, 10), 18.0 * delta)
		if left_arm:
			var l_swing := -sin(stride_time) * 12.0
			left_arm.rotation_degrees = left_arm.rotation_degrees.lerp(Vector3(40 + l_swing, -28, -14), 18.0 * delta)
		if weapon_mount:
			weapon_mount.position = weapon_mount.position.lerp(Vector3(0.20, 0.20, -0.34), 16.0 * delta)
			weapon_mount.rotation_degrees = Vector3(-10, 0, 0)
	else:
		# Normal Hipfire / Combat Ready Idle
		if torso:
			torso.rotation.x = lerpf(torso.rotation.x, 0.0, 14.0 * delta)
		if right_arm:
			right_arm.rotation_degrees = right_arm.rotation_degrees.lerp(Vector3(45, 18, 10), 16.0 * delta)
		if left_arm:
			left_arm.rotation_degrees = left_arm.rotation_degrees.lerp(Vector3(55, -30, -16), 16.0 * delta)
		if weapon_mount:
			weapon_mount.position = weapon_mount.position.lerp(Vector3(0.22, 0.25, -0.34), 16.0 * delta)
			weapon_mount.rotation_degrees = Vector3.ZERO

	# 3. Dynamic Cat Tail Physics
	if tail:
		var wave_speed := 12.0 if moving else 4.0
		var wave_amp := 24.0 if moving else 12.0
		var wave := sin(Time.get_ticks_msec() * 0.001 * wave_speed) * wave_amp
		tail.rotation_degrees.y = lerpf(tail.rotation_degrees.y, wave, 15.0 * delta)
		# Tail lifts up when sprinting
		var lift := 20.0 if (moving and horiz_speed > 8.0) else 0.0
		tail.rotation_degrees.x = lerpf(tail.rotation_degrees.x, lift, 10.0 * delta)

# ============================ Cute Cat Pet Companion ============================
static func build_cat_pet() -> Node3D:
	var pet := Node3D.new()
	pet.name = "CatPet"

	var mat_fur := _make_mat(Color(0.48, 0.25, 0.88), true, Color(0.48, 0.25, 0.88), 0.2)
	var mat_belly := _make_mat(Color(0.95, 0.90, 1.0))
	var mat_ears := _make_mat(Color(0.98, 0.45, 0.75), true, Color(0.98, 0.45, 0.75), 0.4)
	var mat_eyes := _make_mat(Color(0.0, 0.95, 1.0), true, Color(0.0, 0.95, 1.0), 1.6)
	var mat_pack := _make_mat(Color(0.15, 0.12, 0.22))
	var mat_accent := _make_mat(Color(1.0, 0.75, 0.2), true, Color(1.0, 0.75, 0.2), 0.8)

	_add_sphere(pet, 0.26, mat_fur, Vector3(0, 0.32, 0))
	_add_sphere(pet, 0.20, mat_belly, Vector3(0, 0.30, -0.12))
	var head := _add_sphere(pet, 0.24, mat_fur, Vector3(0, 0.62, -0.06))

	for side in [-1, 1]:
		_add_sphere(head, 0.05, mat_eyes, Vector3(side * 0.10, 0.02, -0.21))
		var ear := _add_prism(head, Vector3(0.12, 0.16, 0.08), mat_fur, Vector3(side * 0.14, 0.22, 0))
		ear.rotation_degrees = Vector3(10, 0, side * -20)
		_add_prism(ear, Vector3(0.07, 0.11, 0.04), mat_ears, Vector3(0, -0.02, -0.03))

	var pack := _add_box(pet, Vector3(0.24, 0.22, 0.14), mat_pack, Vector3(0, 0.35, 0.22))
	_add_sphere(pack, 0.04, mat_accent, Vector3(0, 0, 0.08))

	var tail := Node3D.new()
	tail.name = "PetTail"
	tail.position = Vector3(0, 0.22, 0.24)
	tail.rotation_degrees = Vector3(-45, 0, 0)
	pet.add_child(tail)
	_add_capsule(tail, 0.04, 0.26, mat_fur, Vector3(0, 0.12, 0))
	_add_sphere(tail, 0.05, mat_accent, Vector3(0, 0.25, 0))

	for side in [-1, 1]:
		_add_sphere(pet, 0.09, mat_belly, Vector3(side * 0.14, 0.08, -0.14))
		_add_sphere(pet, 0.09, mat_belly, Vector3(side * 0.14, 0.08, 0.10))

	return pet

# ============================ Real Weapons Models ============================
static func build_weapon(weapon_key: String) -> Node3D:
	var root := Node3D.new()
	root.name = "Weapon_" + weapon_key

	var mat_gunmetal := _make_mat(Color(0.14, 0.15, 0.18), false, Color.BLACK, 0.0, 0.8, 0.2)
	var mat_steel := _make_mat(Color(0.32, 0.34, 0.38), false, Color.BLACK, 0.0, 0.9, 0.4)
	var mat_wood := _make_mat(Color(0.42, 0.22, 0.10), false, Color.BLACK, 0.0, 0.3, 0.7)
	var mat_neon := _make_mat(Color(0.65, 0.25, 1.0), true, Color(0.65, 0.25, 1.0), 1.2)
	var mat_lens := _make_mat(Color(0.0, 0.85, 1.0), true, Color(0.0, 0.85, 1.0), 1.5)

	match weapon_key:
		"ak47":
			_add_box(root, Vector3(0.07, 0.10, 0.42), mat_gunmetal, Vector3(0, 0, 0))
			_add_box(root, Vector3(0.06, 0.12, 0.30), mat_wood, Vector3(0, -0.03, 0.34))
			_add_cylinder(root, 0.022, 0.52, mat_steel, Vector3(0, 0.02, -0.42), Vector3(PI / 2.0, 0, 0))
			_add_box(root, Vector3(0.06, 0.07, 0.24), mat_wood, Vector3(0, 0.01, -0.28))
			var mag := _add_box(root, Vector3(0.05, 0.22, 0.10), mat_gunmetal, Vector3(0, -0.14, -0.06))
			mag.rotation_degrees = Vector3(18, 0, 0)
			_add_box(root, Vector3(0.02, 0.08, 0.04), mat_steel, Vector3(0, 0.07, -0.64))
			_add_box(root, Vector3(0.072, 0.015, 0.28), mat_neon, Vector3(0, 0.045, -0.02))

		"mp40":
			_add_box(root, Vector3(0.06, 0.08, 0.36), mat_gunmetal, Vector3(0, 0, 0))
			_add_box(root, Vector3(0.05, 0.08, 0.22), mat_steel, Vector3(0, -0.02, 0.26))
			_add_cylinder(root, 0.028, 0.38, mat_steel, Vector3(0, 0.01, -0.34), Vector3(PI / 2.0, 0, 0))
			_add_box(root, Vector3(0.045, 0.26, 0.06), mat_steel, Vector3(0, -0.16, -0.10))
			var grip := _add_box(root, Vector3(0.05, 0.14, 0.06), mat_gunmetal, Vector3(0, -0.10, 0.08))
			grip.rotation_degrees = Vector3(-15, 0, 0)
			_add_box(root, Vector3(0.064, 0.012, 0.20), mat_neon, Vector3(0, 0.038, -0.04))

		"awm":
			_add_box(root, Vector3(0.08, 0.11, 0.50), mat_gunmetal, Vector3(0, 0, 0))
			_add_box(root, Vector3(0.07, 0.14, 0.38), mat_steel, Vector3(0, -0.04, 0.40))
			_add_cylinder(root, 0.026, 0.85, mat_steel, Vector3(0, 0.02, -0.64), Vector3(PI / 2.0, 0, 0))
			_add_box(root, Vector3(0.06, 0.06, 0.10), mat_gunmetal, Vector3(0, 0.02, -1.06))
			var scope := _add_cylinder(root, 0.035, 0.34, mat_gunmetal, Vector3(0, 0.10, -0.04), Vector3(PI / 2.0, 0, 0))
			_add_cylinder(scope, 0.030, 0.02, mat_lens, Vector3(0, 0.17, 0))
			_add_box(root, Vector3(0.06, 0.16, 0.12), mat_gunmetal, Vector3(0, -0.12, -0.08))
			_add_box(root, Vector3(0.084, 0.018, 0.35), mat_neon, Vector3(0, 0.04, 0.05))

		"m1887":
			_add_cylinder(root, 0.022, 0.56, mat_steel, Vector3(-0.022, 0.02, -0.32), Vector3(PI / 2.0, 0, 0))
			_add_cylinder(root, 0.022, 0.56, mat_steel, Vector3(0.022, 0.02, -0.32), Vector3(PI / 2.0, 0, 0))
			_add_box(root, Vector3(0.08, 0.09, 0.22), mat_gunmetal, Vector3(0, 0, 0))
			var stock := _add_box(root, Vector3(0.06, 0.11, 0.26), mat_wood, Vector3(0, -0.06, 0.22))
			stock.rotation_degrees = Vector3(-12, 0, 0)
			_add_box(root, Vector3(0.03, 0.10, 0.10), mat_steel, Vector3(0, -0.08, 0.04))
			_add_box(root, Vector3(0.084, 0.015, 0.16), mat_neon, Vector3(0, 0.035, -0.08))

	var muzzle := Marker3D.new()
	muzzle.name = "MuzzlePoint"
	match weapon_key:
		"ak47":  muzzle.position = Vector3(0, 0.02, -0.70)
		"mp40":  muzzle.position = Vector3(0, 0.01, -0.56)
		"awm":   muzzle.position = Vector3(0, 0.02, -1.12)
		"m1887": muzzle.position = Vector3(0, 0.02, -0.62)
	root.add_child(muzzle)

	return root

# ============================ Free Fire Gloo Wall Barricade ============================
static func build_gloo_wall() -> StaticBody3D:
	var wall := StaticBody3D.new()
	wall.name = "GlooWall"
	wall.collision_layer = 1
	wall.collision_mask = 0

	var mat_gloo := _make_mat(Color(0.55, 0.15, 0.95), true, Color(0.55, 0.15, 0.95), 1.4)
	mat_gloo.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat_gloo.albedo_color.a = 0.88
	var mat_frame := _make_mat(Color(0.12, 0.08, 0.18))
	var mat_cyan := _make_mat(Color(0.0, 0.9, 1.0), true, Color(0.0, 0.9, 1.0), 1.8)

	# Curved tactical wall composed of 3 connected segments
	var angles = [-0.28, 0.0, 0.28]
	var positions = [Vector3(-1.8, 1.4, 0.25), Vector3(0, 1.4, 0.0), Vector3(1.8, 1.4, 0.25)]

	for i in range(3):
		# Collision shape
		var col := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = Vector3(1.9, 2.8, 0.25)
		col.shape = box
		col.position = positions[i]
		col.rotation.y = angles[i]
		wall.add_child(col)

		# Visual mesh
		var mi := _add_box(wall, Vector3(1.9, 2.7, 0.22), mat_gloo, positions[i])
		mi.rotation.y = angles[i]

		# Outer reinforcing frame
		var top_bar := _add_box(wall, Vector3(2.0, 0.12, 0.26), mat_frame, positions[i] + Vector3(0, 1.35, 0))
		top_bar.rotation.y = angles[i]
		var bot_bar := _add_box(wall, Vector3(2.0, 0.12, 0.26), mat_frame, positions[i] + Vector3(0, -1.35, 0))
		bot_bar.rotation.y = angles[i]

	# Central Glowing Free Fire Cat Skull Crest
	var crest := _add_cylinder(wall, 0.45, 0.06, mat_cyan, Vector3(0, 1.4, 0.15), Vector3(PI / 2.0, 0, 0))
	_add_box(crest, Vector3(0.5, 0.08, 0.08), mat_frame, Vector3(0, 0.1, 0))

	return wall

# ============================ Bermuda Red Suspension Bridge ============================
static func build_red_suspension_bridge(length: float = 65.0, width: float = 8.5) -> StaticBody3D:
	var bridge := StaticBody3D.new()
	bridge.name = "BermudaBridge"
	bridge.collision_layer = 1
	bridge.collision_mask = 0

	var mat_road := _make_mat(Color(0.18, 0.18, 0.20))
	var mat_stripe := _make_mat(Color(0.95, 0.95, 0.95))
	var mat_red := _make_mat(Color(0.88, 0.15, 0.15), true, Color(0.88, 0.15, 0.15), 0.3)
	var mat_cable := _make_mat(Color(0.35, 0.35, 0.38))
	var mat_light := _make_mat(Color(1.0, 0.85, 0.2), true, Color(1.0, 0.85, 0.2), 2.0)

	# 1. Road Deck
	var col := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(width, 0.8, length)
	col.shape = box
	bridge.add_child(col)

	var deck := _add_box(bridge, Vector3(width, 0.8, length), mat_road, Vector3.ZERO)

	# Center dashed lane divider
	var dash_count := int(length / 4.0)
	for i in range(dash_count):
		var z_pos := -length * 0.5 + 2.0 + float(i) * 4.0
		_add_box(deck, Vector3(0.22, 0.04, 2.0), mat_stripe, Vector3(0, 0.42, z_pos))

	# Road Guard Rails on sides
	for side in [-1, 1]:
		_add_box(bridge, Vector3(0.25, 1.1, length), mat_red, Vector3(side * (width * 0.5 - 0.2), 0.7, 0))

	# 2. Iconic Red Arch Towers (at Z = -length/4 and Z = +length/4)
	for tower_z in [-length * 0.25, length * 0.25]:
		var tower_h := 16.0
		for side in [-1, 1]:
			# Vertical pillar
			_add_box(bridge, Vector3(0.8, tower_h, 0.8), mat_red, Vector3(side * (width * 0.5 + 0.5), tower_h * 0.5, tower_z))
		# Top cross beam
		_add_box(bridge, Vector3(width + 2.0, 1.0, 0.8), mat_red, Vector3(0, tower_h, tower_z))
		# Arch diagonals
		_add_box(bridge, Vector3(width + 1.2, 0.6, 0.6), mat_red, Vector3(0, tower_h * 0.65, tower_z))
		# Tower top beacon light
		_add_sphere(bridge, 0.28, mat_light, Vector3(0, tower_h + 0.6, tower_z))

	# 3. Main Suspension Cables
	for side in [-1, 1]:
		var cable_x: float = float(side) * (width * 0.5 + 0.5)
		for i in range(12):
			var z_pos: float = -length * 0.45 + float(i) * (length * 0.9 / 11.0)
			var h: float = 1.5 + (1.0 - absf(z_pos / (length * 0.5))) * 8.0
			_add_cylinder(bridge, 0.03, h, mat_cable, Vector3(cable_x, h * 0.5, z_pos))

	return bridge

# ============================ 3D Dropship / Cargo Plane ============================
static func build_cargo_plane() -> Node3D:
	var plane := Node3D.new()
	plane.name = "DropshipPlane"

	var mat_hull := _make_mat(Color(0.16, 0.14, 0.22), false, Color.BLACK, 0.0, 0.7, 0.3)
	var mat_purple := _make_mat(Color(0.58, 0.22, 0.98), true, Color(0.58, 0.22, 0.98), 0.8)
	var mat_engines := _make_mat(Color(0.0, 0.85, 1.0), true, Color(0.0, 0.85, 1.0), 2.5)
	var mat_cockpit := _make_mat(Color(0.0, 0.85, 1.0), true, Color(0.0, 0.85, 1.0), 1.2)

	_add_box(plane, Vector3(3.6, 2.8, 14.0), mat_hull, Vector3(0, 0, 0))
	var nose := _add_prism(plane, Vector3(3.4, 2.4, 3.6), mat_hull, Vector3(0, 0, -8.2))
	nose.rotation_degrees = Vector3(-90, 0, 0)
	_add_box(plane, Vector3(2.6, 0.8, 1.2), mat_cockpit, Vector3(0, 0.8, -7.0))

	var wings := _add_box(plane, Vector3(26.0, 0.45, 4.2), mat_hull, Vector3(0, 0.4, -0.5))
	_add_box(wings, Vector3(0.5, 0.6, 0.8), mat_purple, Vector3(-13.0, 0, 0))
	_add_box(wings, Vector3(0.5, 0.6, 0.8), mat_purple, Vector3(13.0, 0, 0))

	var tail_fin := _add_box(plane, Vector3(0.4, 3.8, 3.4), mat_purple, Vector3(0, 3.0, 5.8))
	tail_fin.rotation_degrees = Vector3(-20, 0, 0)
	_add_box(plane, Vector3(9.0, 0.35, 2.4), mat_hull, Vector3(0, 1.2, 6.2))

	for side in [-1, 1]:
		var eng := _add_cylinder(plane, 0.9, 4.0, mat_hull, Vector3(side * 5.2, -0.6, -0.5), Vector3(PI / 2.0, 0, 0))
		_add_cylinder(eng, 0.75, 0.3, mat_engines, Vector3(0, 2.1, 0))

	var ramp := _add_box(plane, Vector3(3.0, 0.2, 3.2), mat_hull, Vector3(0, -1.2, 7.8))
	ramp.rotation_degrees = Vector3(-18, 0, 0)
	_add_box(plane, Vector3(0.3, 0.3, 0.3), mat_purple, Vector3(0, 0.8, 6.8))

	return plane

# ============================ Parachute Canopy ============================
static func build_parachute_canopy(primary_color: Color) -> Node3D:
	var canopy_root := Node3D.new()
	canopy_root.name = "Canopy"

	var mat_canopy := _make_mat(primary_color, true, primary_color, 0.4)
	var mat_stripes := _make_mat(Color(0.05, 0.05, 0.08))
	var mat_lines := _make_mat(Color(0.8, 0.8, 0.9))

	var dome := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 2.4
	sm.height = 1.4
	sm.is_hemisphere = true
	dome.mesh = sm
	dome.material_override = mat_canopy
	dome.position.y = 1.6
	canopy_root.add_child(dome)

	for ang in [-0.8, 0.0, 0.8]:
		var stripe := _add_box(canopy_root, Vector3(0.35, 0.04, 2.2), mat_stripes, Vector3(sin(ang) * 1.2, 1.8, cos(ang) * 0.4))
		stripe.rotation.y = ang

	for side_x in [-1.4, 1.4]:
		for side_z in [-1.2, 1.2]:
			var line := MeshInstance3D.new()
			var cm := CylinderMesh.new()
			cm.top_radius = 0.015
			cm.bottom_radius = 0.015
			cm.height = 2.2
			line.mesh = cm
			line.material_override = mat_lines
			line.position = Vector3(side_x * 0.5, 0.8, side_z * 0.5)
			line.rotation = Vector3(side_z * -0.22, 0, side_x * 0.22)
			canopy_root.add_child(line)

	return canopy_root

# ============================ Mesh Helpers ============================
static func _make_mat(albedo: Color, emit: bool = false, emit_col: Color = Color.BLACK, emit_energy: float = 0.0, metallic: float = 0.1, roughness: float = 0.5) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = albedo
	mat.metallic = metallic
	mat.roughness = roughness
	if emit:
		mat.emission_enabled = true
		mat.emission = emit_col
		mat.emission_energy_multiplier = emit_energy
	return mat

static func _add_box(parent: Node, size: Vector3, mat: StandardMaterial3D, pos := Vector3.ZERO) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.material_override = mat
	mi.position = pos
	parent.add_child(mi)
	return mi

static func _add_sphere(parent: Node, radius: float, mat: StandardMaterial3D, pos := Vector3.ZERO) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = radius
	sm.height = radius * 2.0
	mi.mesh = sm
	mi.material_override = mat
	mi.position = pos
	parent.add_child(mi)
	return mi

static func _add_cylinder(parent: Node, radius: float, height: float, mat: StandardMaterial3D, pos := Vector3.ZERO, rot := Vector3.ZERO) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = radius
	cm.bottom_radius = radius
	cm.height = height
	mi.mesh = cm
	mi.material_override = mat
	mi.position = pos
	mi.rotation = rot
	parent.add_child(mi)
	return mi

static func _add_capsule(parent: Node, radius: float, height: float, mat: StandardMaterial3D, pos := Vector3.ZERO) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var cm := CapsuleMesh.new()
	cm.radius = radius
	cm.height = height
	mi.mesh = cm
	mi.material_override = mat
	mi.position = pos
	parent.add_child(mi)
	return mi

static func _add_prism(parent: Node, size: Vector3, mat: StandardMaterial3D, pos := Vector3.ZERO) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var pm := PrismMesh.new()
	pm.size = size
	mi.mesh = pm
	mi.material_override = mat
	mi.position = pos
	parent.add_child(mi)
	return mi
