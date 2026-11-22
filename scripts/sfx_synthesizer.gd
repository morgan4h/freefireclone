class_name SFXSynthesizer
extends RefCounted
# Generates authentic combat and UI audio clips entirely in procedural PCM.
# No external sound files needed — always loads instantly and plays cleanly.

static var _cache: Dictionary = {}

static func get_stream(key: String) -> AudioStreamWAV:
	if _cache.has(key):
		return _cache[key]
	var stream: AudioStreamWAV = null
	match key:
		"ak47":
			stream = _make_gunshot(110.0, 0.22, 0.85, 0.3)
		"mp40":
			stream = _make_gunshot(180.0, 0.12, 0.75, 0.45)
		"awm":
			stream = _make_gunshot(65.0, 0.65, 1.0, 0.15)
		"m1887":
			stream = _make_gunshot(85.0, 0.36, 0.95, 0.2)
		"hit":
			stream = _make_tone(1100.0, 0.06, 0.5)
		"headshot":
			stream = _make_headshot()
		"reload":
			stream = _make_reload()
		"parachute":
			stream = _make_parachute()
		"eject":
			stream = _make_eject()
		"click":
			stream = _make_tone(1600.0, 0.04, 0.4)
		_:
			stream = _make_tone(880.0, 0.08, 0.5)
	_cache[key] = stream
	return stream

static func play_sound(node: Node, key: String, volume_db: float = 0.0) -> AudioStreamPlayer:
	if node == null or not is_instance_valid(node):
		return null
	var player := AudioStreamPlayer.new()
	player.stream = get_stream(key)
	player.volume_db = volume_db
	node.add_child(player)
	player.play()
	player.finished.connect(player.queue_free)
	return player

static func play_3d_sound(node: Node3D, key: String, pos: Vector3, volume_db: float = 0.0) -> AudioStreamPlayer3D:
	if node == null or not is_instance_valid(node):
		return null
	var p3d := AudioStreamPlayer3D.new()
	p3d.stream = get_stream(key)
	p3d.position = pos
	p3d.volume_db = volume_db
	p3d.max_distance = 60.0
	node.add_child(p3d)
	p3d.play()
	p3d.finished.connect(p3d.queue_free)
	return p3d

# ---- Synthesizers ----

static func _make_gunshot(base_freq: float, duration: float, volume: float, noise_mix: float) -> AudioStreamWAV:
	var sample_rate := 22050
	var total_samples := int(sample_rate * duration)
	var data := PackedByteArray()
	data.resize(total_samples * 2)

	var phase := 0.0
	for i in range(total_samples):
		var t := float(i) / float(total_samples)
		var env := exp(-t * 9.0)
		var cur_freq := base_freq * (1.0 + 3.0 * exp(-t * 22.0))
		phase += cur_freq / sample_rate * TAU
		var tone := sin(phase)
		var noise := randf_range(-1.0, 1.0)
		var sample_val := lerpf(tone, noise, noise_mix) * env * volume
		sample_val = clampf(sample_val, -1.0, 1.0)
		var int_val := int(sample_val * 32767.0)
		data.encode_s16(i * 2, int_val)

	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = sample_rate
	wav.stereo = false
	wav.data = data
	return wav

static func _make_tone(freq: float, duration: float, volume: float) -> AudioStreamWAV:
	var sample_rate := 22050
	var total_samples := int(sample_rate * duration)
	var data := PackedByteArray()
	data.resize(total_samples * 2)

	var phase := 0.0
	for i in range(total_samples):
		var t := float(i) / float(total_samples)
		var env := 1.0 - t
		phase += freq / sample_rate * TAU
		var sample_val := sin(phase) * env * volume
		var int_val := int(clampf(sample_val, -1.0, 1.0) * 32767.0)
		data.encode_s16(i * 2, int_val)

	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = sample_rate
	wav.stereo = false
	wav.data = data
	return wav

static func _make_headshot() -> AudioStreamWAV:
	# Free Fire crisp dual bell sound (ding-ding!)
	var sample_rate := 22050
	var duration := 0.22
	var total_samples := int(sample_rate * duration)
	var data := PackedByteArray()
	data.resize(total_samples * 2)

	var p1 := 0.0
	var p2 := 0.0
	for i in range(total_samples):
		var t := float(i) / float(total_samples)
		var env := exp(-t * 8.0)
		p1 += 1760.0 / sample_rate * TAU
		p2 += 2640.0 / sample_rate * TAU
		var sample_val := (sin(p1) * 0.6 + sin(p2) * 0.4) * env * 0.8
		var int_val := int(clampf(sample_val, -1.0, 1.0) * 32767.0)
		data.encode_s16(i * 2, int_val)

	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = sample_rate
	wav.stereo = false
	wav.data = data
	return wav

static func _make_reload() -> AudioStreamWAV:
	# Double metallic click
	var sample_rate := 22050
	var duration := 0.35
	var total_samples := int(sample_rate * duration)
	var data := PackedByteArray()
	data.resize(total_samples * 2)

	for i in range(total_samples):
		var t := float(i) / float(sample_rate)
		var sample_val := 0.0
		# Click 1 at 0.05s
		if t >= 0.04 and t < 0.12:
			var dt := (t - 0.04) / 0.08
			sample_val += randf_range(-0.8, 0.8) * exp(-dt * 18.0)
		# Click 2 at 0.20s
		if t >= 0.18 and t < 0.30:
			var dt := (t - 0.18) / 0.12
			sample_val += randf_range(-0.9, 0.9) * exp(-dt * 15.0)
		var int_val := int(clampf(sample_val, -1.0, 1.0) * 32767.0)
		data.encode_s16(i * 2, int_val)

	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = sample_rate
	wav.stereo = false
	wav.data = data
	return wav

static func _make_parachute() -> AudioStreamWAV:
	# Canopy flap / rushing air sound
	var sample_rate := 22050
	var duration := 0.55
	var total_samples := int(sample_rate * duration)
	var data := PackedByteArray()
	data.resize(total_samples * 2)

	var filter := 0.0
	for i in range(total_samples):
		var t := float(i) / float(total_samples)
		var env := sin(t * PI)
		var noise := randf_range(-1.0, 1.0)
		filter = filter * 0.85 + noise * 0.15
		var sample_val := filter * env * 0.7
		var int_val := int(clampf(sample_val, -1.0, 1.0) * 32767.0)
		data.encode_s16(i * 2, int_val)

	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = sample_rate
	wav.stereo = false
	wav.data = data
	return wav

static func _make_eject() -> AudioStreamWAV:
	# High speed air burst when exiting plane
	var sample_rate := 22050
	var duration := 0.40
	var total_samples := int(sample_rate * duration)
	var data := PackedByteArray()
	data.resize(total_samples * 2)

	for i in range(total_samples):
		var t := float(i) / float(total_samples)
		var env := exp(-t * 5.0)
		var noise := randf_range(-1.0, 1.0)
		var sample_val := noise * env * 0.75
		var int_val := int(clampf(sample_val, -1.0, 1.0) * 32767.0)
		data.encode_s16(i * 2, int_val)

	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = sample_rate
	wav.stereo = false
	wav.data = data
	return wav
