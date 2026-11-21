extends Node
# Global match state + clean input map (built in code so project.godot stays editable by the UI).

signal player_count_changed(alive: int)

var match_active := false
var mode := "br"          # "br" = Battle Royale, "clash" = Clash Squad
var total_players := 50
var alive_count := 50
var kills := 0
var placement := 50

func _ready() -> void:
	_setup_input()

# ---- Input map (idempotent; keeps the default ui_* actions intact) ----
func _setup_input() -> void:
	_add_key_action("move_forward", [KEY_W, KEY_UP])
	_add_key_action("move_back",    [KEY_S, KEY_DOWN])
	_add_key_action("move_left",    [KEY_A, KEY_LEFT])
	_add_key_action("move_right",   [KEY_D, KEY_RIGHT])
	_add_key_action("sprint",       [KEY_SHIFT])
	_add_key_action("jump",         [KEY_SPACE])
	_add_key_action("reload",       [KEY_R])
	_add_key_action("interact",      [KEY_E])
	_add_key_action("toggle_mouse", [KEY_ESCAPE])
	_add_mouse_action("shoot",       [MOUSE_BUTTON_LEFT])
	_add_mouse_action("aim",         [MOUSE_BUTTON_RIGHT])

func _add_key_action(action: String, keys: Array) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	for k in keys:
		var ev := InputEventKey.new()
		ev.physical_keycode = k
		InputMap.action_add_event(action, ev)

func _add_mouse_action(action: String, buttons: Array) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	for b in buttons:
		var ev := InputEventMouseButton.new()
		ev.button_index = b
		InputMap.action_add_event(action, ev)

func reset_match(p_mode := "br") -> void:
	mode = p_mode
	match_active = true
	kills = 0
	if mode == "br":
		total_players = 50
		alive_count = 50
		placement = 50
	else:
		total_players = 10
		alive_count = 10
		placement = 10

func end_match(won: bool) -> void:
	match_active = false

func set_alive(n: int) -> void:
	alive_count = n
	player_count_changed.emit(n)

func register_kill() -> void:
	kills += 1
