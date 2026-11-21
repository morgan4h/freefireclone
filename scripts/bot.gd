extends CharacterBody3D
# AI combatant. Acquires the nearest living enemy (player or other bots), closes in,
# fires probabilistically, retreats from the closing zone, and reports its killer on death.

signal eliminated(bot: Node, killer_name: String)

var char_name := "Bot"
var health: float = 100.0
var armor: float = 0.0
var gravity: float = 24.0
var speed: float = 3.6
var alive: bool = true
var frozen: bool = false

var target = null              # untyped: dynamic dispatch to take_damage / get("alive")
var enemies: Array = []
var zone_center := Vector3.ZERO
var zone_radius: float = 58.0

var roam_angle: float = 0.0
var shoot_timer: float = 1.5
var retarget_timer: float = 0.0
var accuracy: float = 0.22
var damage_min: float = 5.0
var damage_max: float = 12.0
var engage_range: float = 30.0
var detect_range: float = 50.0

func _ready() -> void:
	roam_angle = randf() * TAU

func get_char_name() -> String:
	return char_name

func set_enemies(list: Array) -> void:
	enemies = list

func _physics_process(delta: float) -> void:
	if not alive or frozen:
		return
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
				shoot_timer = randf_range(0.65, 1.5)
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
		alive = false
		var kname := "the zone"
		if attacker != null and attacker.has_method("get_char_name"):
			kname = attacker.call("get_char_name")
		eliminated.emit(self, kname)
