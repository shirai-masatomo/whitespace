extends Node
## Original synthesized water and interaction cues. No downloaded recordings.
const Model = preload("res://game/dive_model.gd")
const SAMPLE_RATE := 22050
const LOOP_NAMES := ["surface", "underwater", "movement"]
const CUE_NAMES := ["entry", "refill", "warning", "rescue", "land", "goal", "distant"]
static var bank: Dictionary = {}
var players: Dictionary = {}
var muted := false
var suspended := false
var previous_mode := Model.Mode.DIVING
var previous_oxygen := 100.0
var previous_grounded := 0
var was_wet := false
var warning_timer := 0.0
var refill_timer := 0.0
var events: Array[String] = []
var mix := {"surface": 0.0, "underwater": 0.0, "movement": 0.0}
var output_enabled := false
var distant_timer := 0.0


func _ready() -> void:
	# Dummy is used by headless and non-interfering GPU automation. Keep PCM and
	# feedback state testable without queuing playback to an inactive output device.
	output_enabled = AudioServer.get_driver_name() != "Dummy"
	for label in LOOP_NAMES + CUE_NAMES:
		if not bank.has(label):
			bank[label] = synthesize(label)
		var player := AudioStreamPlayer.new()
		player.stream = bank[label]
		player.volume_db = -80
		add_child(player)
		players[label] = player
		if label in LOOP_NAMES and output_enabled:
			player.play()


func _exit_tree() -> void:
	for player in players.values():
		player.stop()
		player.stream = null
	players.clear()
	# Static Resource caches otherwise retain the script at engine shutdown.
	bank.clear()


func reset(model) -> void:
	previous_mode = model.mode
	previous_oxygen = model.oxygen
	previous_grounded = model.grounded
	was_wet = model.position.y < -1
	warning_timer = 0
	refill_timer = 0
	distant_timer = 0
	events.clear()
	for label in CUE_NAMES:
		players[label].stop()


func set_muted(value: bool) -> void:
	muted = value
	for label in players:
		if label in CUE_NAMES and muted:
			players[label].stop()
	apply_mix()


func suspend(value: bool) -> void:
	suspended = value
	for player in players.values():
		player.stream_paused = value


func observe(model, delta: float) -> void:
	if suspended:
		return
	var wet: bool = model.position.y < -1
	warning_timer = maxf(0, warning_timer - delta)
	refill_timer = maxf(0, refill_timer - delta)
	distant_timer = maxf(0, distant_timer - delta)
	if model.config.discovery_enabled and model.depth > 60 and model.depth < 180:
		if distant_timer <= 0 and model.mode == Model.Mode.DIVING:
			cue("distant")
			distant_timer = 16
	if wet and not was_wet and model.mode == Model.Mode.DIVING:
		cue("entry")
	if model.mode == Model.Mode.RETURNING and previous_mode != model.mode:
		cue("rescue")
	elif model.mode == Model.Mode.COMPLETE and previous_mode != model.mode:
		cue("goal")
	elif model.mode == Model.Mode.DIVING:
		if model.oxygen > previous_oxygen + .5 and previous_mode == model.mode and wet:
			if refill_timer <= 0:
				cue("refill")
				refill_timer = 1.5
		if model.oxygen < 25 and warning_timer <= 0:
			cue("warning")
			warning_timer = 2.5
		if model.grounded >= 0 and previous_grounded < 0 and previous_mode == model.mode:
			cue("land")
	var immersion := 1.0 - smoothstep(-2.5, .5, model.position.y + 1.4)
	if model.in_air_pocket():
		immersion *= .15
	var speed: float = model.velocity.length()
	var target := {
		"surface": (1 - immersion) * .28,
		"underwater": immersion * .30,
		"movement": immersion * clampf(speed / 20.0, 0, 1) * .33
	}
	for label in LOOP_NAMES:
		mix[label] = lerpf(mix[label], target[label], 1 - exp(-delta * 5))
	apply_mix()
	previous_mode = model.mode
	previous_oxygen = model.oxygen
	previous_grounded = model.grounded
	was_wet = wet


func apply_mix() -> void:
	for label in LOOP_NAMES:
		players[label].volume_linear = 0 if muted else mix[label]
	for label in CUE_NAMES:
		players[label].volume_linear = 0 if muted else .42


func cue(label: String) -> void:
	events.append(label)
	if events.size() > 16:
		events.pop_front()
	if not muted and output_enabled:
		players[label].volume_linear = .42
		players[label].play()


static func synthesize(label: String) -> AudioStreamWAV:
	var looping: bool = label in LOOP_NAMES
	var duration := 6.0 if looping else (.85 if label in ["entry", "rescue", "goal"] else .45)
	var count := int(SAMPLE_RATE * duration)
	var data := PackedByteArray()
	data.resize(count * 4)
	var rng := RandomNumberGenerator.new()
	rng.seed = 918 + label.hash()
	var low := Vector2.ZERO
	var slow := Vector2.ZERO
	for frame in range(count):
		var t := frame / float(SAMPLE_RATE)
		var envelope := minf(1, t * 80) * minf(1, (duration - t) * 25)
		for channel in range(2):
			var noise := rng.randf_range(-1, 1)
			low[channel] = lerpf(low[channel], noise, .16)
			slow[channel] = lerpf(slow[channel], noise, .008)
			var sample := sample_at(label, t, low[channel], slow[channel]) * envelope
			data.encode_s16((frame * 2 + channel) * 2, roundi(clampf(sample, -.9, .9) * 32767))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.stereo = true
	stream.data = data
	if looping:
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		stream.loop_end = count
	return stream


static func sample_at(label: String, t: float, noise: float, low: float) -> float:
	match label:
		"surface":
			return noise * (.32 + .15 * sin(t * TAU / 6)) + low * .6
		"underwater":
			return low * 1.6 + sin(t * TAU * 64) * .009
		"movement":
			return (noise - low) * .35 * (.85 + .15 * sin(t * TAU * 3))
		"entry":
			return (noise * .9 + low * 2) * exp(-t * 4)
		"refill":
			var bubble := sin(TAU * (380 * t + 380 * t * t))
			return bubble * .20 * exp(-t * 8) + noise * .20 * exp(-t * 5)
		"warning":
			var pulse := exp(-t * 24) + exp(-absf(t - .2) * 28) * .6
			return sin(TAU * 180 * t) * .17 * pulse
		"rescue":
			return (noise * .5 + sin(TAU * (110 * t + 200 * t * t)) * .06) * exp(-t * 2)
		"land":
			return (sin(TAU * 90 * t) * .15 + noise * .2) * exp(-t * 16)
		"goal":
			return (sin(TAU * 392 * t) + sin(TAU * 587.33 * t) * .5) * .14 * exp(-t * 3)
		"distant":
			return sin(TAU * (62 * t - 12 * t * t)) * .07 * sin(t * PI / .45)
	return 0
