extends Control
# Circular, north-up minimap with Free Fire airplane flight path, safe zone,
# enemy detection dots, airdrops, and player directional indicator.

var player: CharacterBody3D
var bots: Array = []
var zone_center := Vector3.ZERO
var zone_radius := 58.0
var airdrops: Array = []
var view_range := 80.0

# Free Fire Flight path tracking
var flight_active := false
var flight_start := Vector3.ZERO
var flight_end := Vector3.ZERO
var plane_pos := Vector3.ZERO

func _draw() -> void:
	var size := get_size()
	var center := size * 0.5
	var radius := minf(center.x, center.y) - 2.0
	var scale := radius / view_range

	# Base circular radar disc
	draw_circle(center, radius + 2.0, Color(0.04, 0.03, 0.07, 0.92))
	draw_arc(center, radius, 0, TAU, 64, Color(0.57, 0.25, 1.0, 0.7), 2.0, true)

	var ref_pos := Vector3.ZERO
	if flight_active and plane_pos != Vector3.ZERO:
		ref_pos = plane_pos
	elif player != null and is_instance_valid(player):
		ref_pos = player.global_position
	else:
		return

	# Flight path trajectory line (Free Fire yellow/white dashed line)
	if flight_active:
		var p1 := center + Vector2((flight_start.x - ref_pos.x) * scale, (flight_start.z - ref_pos.z) * scale)
		var p2 := center + Vector2((flight_end.x - ref_pos.x) * scale, (flight_end.z - ref_pos.z) * scale)
		draw_line(p1, p2, Color(1.0, 0.85, 0.2, 0.85), 2.0)

		# Plane icon on minimap
		var plane_screen := center + Vector2((plane_pos.x - ref_pos.x) * scale, (plane_pos.z - ref_pos.z) * scale)
		if plane_screen.distance_to(center) <= radius:
			# Draw simple airplane triangle
			var fwd := (flight_end - flight_start).normalized()
			var pang := atan2(fwd.x, fwd.z)
			var tip := plane_screen + Vector2(sin(pang), cos(pang)) * 9.0
			var l := plane_screen + Vector2(sin(pang + 2.5), cos(pang + 2.5)) * 7.0
			var r := plane_screen + Vector2(sin(pang - 2.5), cos(pang - 2.5)) * 7.0
			draw_colored_polygon(PackedVector2Array([tip, l, r]), Color(1.0, 0.9, 0.2, 1.0))

	# Safe zone circle
	var zc := center + Vector2((zone_center.x - ref_pos.x) * scale, (zone_center.z - ref_pos.z) * scale)
	var zr := zone_radius * scale
	if zr > 2.0:
		draw_arc(zc, zr, 0, TAU, 96, Color(0.68, 0.38, 1.0, 0.9), 2.0, true)

	# Airdrop supply crates
	for a in airdrops:
		if a is Vector3:
			var ap := center + Vector2((a.x - ref_pos.x) * scale, (a.z - ref_pos.z) * scale)
			if ap.distance_to(center) <= radius:
				draw_rect(Rect2(ap - Vector2(5, 5), Vector2(10, 10)), Color(1.0, 0.78, 0.24, 1.0))

	# Enemy dots
	for b in bots:
		if b == null or not is_instance_valid(b) or not b.get("alive"):
			continue
		var bp := center + Vector2((b.global_position.x - ref_pos.x) * scale, (b.global_position.z - ref_pos.z) * scale)
		var d := bp.distance_to(center)
		if d <= radius:
			var alpha := clampf(1.0 - (d / radius) * 0.55, 0.35, 1.0)
			draw_circle(bp, 4.0, Color(1.0, 0.30, 0.30, alpha))

	# Player arrow indicator
	if player != null and is_instance_valid(player):
		var pp := center + Vector2((player.global_position.x - ref_pos.x) * scale, (player.global_position.z - ref_pos.z) * scale)
		if pp.distance_to(center) <= radius:
			var fwd := -player.global_transform.basis.z
			var angle := atan2(fwd.x, fwd.z)
			var col := Color(0.0, 0.85, 1.0, 1.0) # Electric cyan
			var tip := pp + Vector2(sin(angle), cos(angle)) * 9.0
			var left := pp + Vector2(sin(angle + 2.4), cos(angle + 2.4)) * 7.0
			var right := pp + Vector2(sin(angle - 2.4), cos(angle - 2.4)) * 7.0
			var pts := PackedVector2Array([tip, left, right])
			draw_colored_polygon(pts, col)
			draw_circle(pp, 2.5, Color(1, 1, 1, 0.95))
