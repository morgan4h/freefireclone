extends Control
# Circular, north-up minimap. Reads live state from the battle map each frame in _draw.

var player: CharacterBody3D
var bots: Array = []           # Array of CharacterBody3D
var zone_center := Vector3.ZERO
var zone_radius := 58.0
var airdrops: Array = []       # Array of Vector3
var view_range := 75.0        # world meters shown across the radius

func _draw() -> void:
	if player == null or not is_instance_valid(player):
		return
	var size := get_size()
	var center := size * 0.5
	var radius := minf(center.x, center.y) - 2.0
	var scale := radius / view_range

	# base disc
	draw_circle(center, radius + 2.0, Color(0.02, 0.03, 0.06, 0.92))
	draw_arc(center, radius, 0, TAU, 64, Color(0.165, 0.200, 0.314, 1.0), 2.0, true)

	var pp := player.global_position

	# safe zone circle (offset from player, scaled)
	var zc := center + Vector2((zone_center.x - pp.x) * scale, (zone_center.z - pp.z) * scale)
	var zr := zone_radius * scale
	if zr > 2.0:
		draw_arc(zc, zr, 0, TAU, 96, Color(0.608, 0.361, 1.000, 0.9), 2.0, true)

	# airdrop markers
	for a in airdrops:
		if a is Vector3:
			var ap := center + Vector2((a.x - pp.x) * scale, (a.z - pp.z) * scale)
			if ap.distance_to(center) <= radius:
				draw_rect(Rect2(ap - Vector2(5, 5), Vector2(10, 10)), Color(1.0, 0.78, 0.24, 1.0))

	# enemy dots
	for b in bots:
		if b == null or not is_instance_valid(b) or not b.get("alive"):
			continue
		var bp := center + Vector2((b.global_position.x - pp.x) * scale, (b.global_position.z - pp.z) * scale)
		var d := bp.distance_to(center)
		if d <= radius:
			var alpha := clampf(1.0 - (d / radius) * 0.55, 0.35, 1.0)
			draw_circle(bp, 4.0, Color(1.0, 0.30, 0.30, alpha))

	# player arrow at center, rotated to facing
	var fwd := -player.global_transform.basis.z
	var angle := atan2(fwd.x, fwd.z)
	var col := Color(0.302, 0.651, 1.000, 1.0)
	var tip := center + Vector2(sin(angle), cos(angle)) * 10.0
	var left := center + Vector2(sin(angle + 2.4), cos(angle + 2.4)) * 8.0
	var right := center + Vector2(sin(angle - 2.4), cos(angle - 2.4)) * 8.0
	var pts := PackedVector2Array([tip, left, right])
	draw_colored_polygon(pts, col)
	draw_circle(center, 2.5, Color(1, 1, 1, 0.95))
