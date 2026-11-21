extends CharacterBody3D
# Local player controller: third-person movement, hitscan shooting, reload, armor, regen.

signal died
signal shot_fired
signal hit_landed(target: Node, damage: float, headshot: bool)
signal reloaded
signal took_damage(amount: float, from_pos: Vector3)

const MAX_HEALTH := 100.0
const MAX_ARMOR := 100.0
const MAG_SIZE := 30
const RELOAD_TIME := 1.7
const FIRE_COOLDOWN := 0.10
const DAMAGE := 32.0

var gravity: float = 24.0
var walk_speed: float = 6.8
var sprint_speed: float = 10.6
var health: float = MAX_HEALTH
var armor: float = 0.0
var ammo: int = MAG_SIZE
var reserve_ammo: int = 120
var fire_timer: float = 0.0
var reload_timer: float = 0.0
var is_reloading := false
var mouse_captured := true
var look_sensitivity: float = 0.0022
var last_damage_time: float = -999.0
var regen_rate: float = 7.0
var regen_delay: float = 5.0
var alive: bool = true
var frozen := false
var char_name := "You"
var last_attacker_name := ""
var total_damage_dealt := 0.0

@onready var spring_arm: SpringArm3D = $SpringArm3D
@onready var camera: Camera3D = $SpringArm3D/Camera3D
@onready var ray: RayCast3D = $SpringArm3D/Camera3D/RayCast3D

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	camera.current = true

func get_char_name() -> String:
	return char_name

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and mouse_captured:
		rotate_y(-event.relative.x * look_sensitivity)
		spring_arm.rotate_x(-event.relative.y * look_sensitivity)
		spring_arm.rotation.x = clamp(spring_arm.rotation.x, deg_to_rad(-72), deg_to_rad(40))
	elif event.is_action_pressed("toggle_mouse"):
		mouse_captured = not mouse_captured
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED if mouse_captured else Input.MOUSE_MODE_VISIBLE

func _physics_process(delta: float) -> void:
	if not alive:
		return
	fire_timer -= delta

	if not frozen:
		_process_movement(delta)
		_process_combat(delta)

	# out-of-combat regen (works even while frozen is false; harmless during countdown)
	var now := Time.get_ticks_msec() / 1000.0
	if now - last_damage_time > regen_delay and health < MAX_HEALTH and alive:
		health = minf(MAX_HEALTH, health + regen_rate * delta)

func _process_movement(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= gravity * delta
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = 8.8

	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	var sprinting := Input.is_action_pressed("sprint") and direction.length() > 0.01
	var speed := sprint_speed if sprinting else walk_speed
	var accel := 26.0 if is_on_floor() else 6.0
	if direction:
		velocity.x = move_toward(velocity.x, direction.x * speed, accel * delta)
		velocity.z = move_toward(velocity.z, direction.z * speed, accel * delta)
	else:
		velocity.x = move_toward(velocity.x, 0.0, 20.0 * delta)
		velocity.z = move_toward(velocity.z, 0.0, 20.0 * delta)
	move_and_slide()

func _process_combat(delta: float) -> void:
	if Input.is_action_just_pressed("reload"):
		start_reload()
	if is_reloading:
		reload_timer -= delta
		if reload_timer <= 0.0:
			finish_reload()
	if Input.is_action_pressed("shoot") and not is_reloading:
		shoot()

func shoot() -> void:
	if fire_timer > 0.0:
		return
	if ammo <= 0:
		start_reload()
		return
	fire_timer = FIRE_COOLDOWN
	ammo -= 1
	shot_fired.emit()
	# light recoil kick
	spring_arm.rotation.x = minf(spring_arm.rotation.x + deg_to_rad(0.45), deg_to_rad(40))

	ray.force_raycast_update()
	if ray.is_colliding():
		var collider := ray.get_collider()
		if collider is CharacterBody3D:
			var cb := collider as CharacterBody3D
			var base_y := cb.global_position.y
			var headshot := ray.get_collision_point().y - base_y > 1.45
			if cb.has_method("take_damage"):
				var dmg := DAMAGE * (2.0 if headshot else 1.0)
				cb.call("take_damage", dmg, self)
				total_damage_dealt += dmg
				hit_landed.emit(cb, dmg, headshot)
	if ammo <= 0:
		start_reload()

func start_reload() -> void:
	if is_reloading or ammo >= MAG_SIZE or reserve_ammo <= 0:
		return
	is_reloading = true
	reload_timer = RELOAD_TIME
	reloaded.emit()

func finish_reload() -> void:
	is_reloading = false
	var need := MAG_SIZE - ammo
	var take := mini(need, reserve_ammo)
	ammo += take
	reserve_ammo -= take
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
	reserve_ammo = mini(reserve_ammo + reserve_amount, 240)

func heal(amount: float) -> void:
	health = minf(MAX_HEALTH, health + amount)

func add_armor(amount: float) -> void:
	armor = minf(MAX_ARMOR, armor + amount)
