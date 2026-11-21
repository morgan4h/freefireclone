extends Node
# Persistent local profile. Save format is forward/backward compatible (defaults fill new keys).

const SAVE_PATH := "user://player_data.cfg"
const XP_PER_LEVEL := 500

var username := "Guest"
var coins := 1000
var diamonds := 50
var xp := 0
var level := 1
var matches := 0
var wins := 0
var kills := 0
var losses := 0
var best_placement := 0
var total_damage := 0
var total_distance := 0

func _ready() -> void:
	load_data()

# Applies a match result, grants rewards, returns a summary for the results screen.
func add_match_result(match_kills: int, placement: int, pool: int, damage: int) -> Dictionary:
	matches += 1
	kills += match_kills
	total_damage += damage
	var won := placement == 1
	if won:
		wins += 1
	else:
		losses += 1
	if best_placement == 0 or placement < best_placement:
		best_placement = placement

	var xp_gain := 80 + match_kills * 30 + maxi(0, pool - placement) * 8
	var coin_gain := 40 + match_kills * 12 + maxi(0, pool - placement) * 4 + (250 if won else 0)
	var diamond_gain := 1 + (6 if won else 0)

	xp += xp_gain
	var levels_gained := 0
	while xp >= XP_PER_LEVEL:
		xp -= XP_PER_LEVEL
		level += 1
		levels_gained += 1
		coins += 75  # level-up bonus

	coins += coin_gain
	diamonds += diamond_gain
	save_data()

	return {
		"won": won,
		"placement": placement,
		"kills": match_kills,
		"damage": damage,
		"xp": xp_gain,
		"coins": coin_gain,
		"diamonds": diamond_gain,
		"levels": levels_gained,
		"pool": pool
	}

func xp_progress() -> float:
	return float(xp) / float(XP_PER_LEVEL)

func save_data() -> void:
	var config := ConfigFile.new()
	config.set_value("player", "username", username)
	config.set_value("stats", "coins", coins)
	config.set_value("stats", "diamonds", diamonds)
	config.set_value("stats", "xp", xp)
	config.set_value("stats", "level", level)
	config.set_value("stats", "matches", matches)
	config.set_value("stats", "wins", wins)
	config.set_value("stats", "kills", kills)
	config.set_value("stats", "losses", losses)
	config.set_value("stats", "best_placement", best_placement)
	config.set_value("stats", "total_damage", total_damage)
	config.set_value("stats", "total_distance", total_distance)
	config.save(SAVE_PATH)

func load_data() -> void:
	var config := ConfigFile.new()
	if config.load(SAVE_PATH) != OK:
		return
	username = str(config.get_value("player", "username", username))
	coins = int(config.get_value("stats", "coins", coins))
	diamonds = int(config.get_value("stats", "diamonds", diamonds))
	xp = int(config.get_value("stats", "xp", xp))
	level = int(config.get_value("stats", "level", level))
	matches = int(config.get_value("stats", "matches", matches))
	wins = int(config.get_value("stats", "wins", wins))
	kills = int(config.get_value("stats", "kills", kills))
	losses = int(config.get_value("stats", "losses", losses))
	best_placement = int(config.get_value("stats", "best_placement", best_placement))
	total_damage = int(config.get_value("stats", "total_damage", total_damage))
	total_distance = int(config.get_value("stats", "total_distance", total_distance))
