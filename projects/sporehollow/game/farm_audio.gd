extends Node
## Synthesized effects and user-supplied daytime music. No simulation RNG.
const DAY_MUSIC=preload("res://assets/audio/Porch_Swing_Serenade.mp3")
const DAY_VOLUME_DB=-16.0
const MENU_VOLUME_DB=-23.0
const MUSIC_FADE_IN_SECONDS=7.0
const NIGHT_FADE_OUT_SECONDS=4.0
const NIGHT_GAP_SECONDS=0.35
const NIGHT_AMBIENT_FADE_SECONDS=1.5
var night_transition=-1.0
var night_ambient_started=false
var ambient_target_db=-19.0
const MUSIC_FADE_OUT_SECONDS=2.0
const MUSIC_SOFT_FADE_SECONDS=1.0
var music: AudioStreamPlayer
var music_enabled=false
var music_soft=false
var music_level=0.0
var music_resume=0.0
var music_target=0.0
var music_fade_from=0.0
var music_fade_elapsed=0.0
var music_fade_duration=MUSIC_FADE_IN_SECONDS
var voices: Array = []
var ambient: AudioStreamPlayer
var cache: Dictionary = {}
var last_play: Dictionary = {}
var played: Dictionary = {}
var seconds = 0.0
var night = false
var birds: AudioStreamPlayer
var ambience_rng = RandomNumberGenerator.new()
var next_bird = 12.0
var danger_until = 0.0

func _ready():
	for i in range(3):
		var player = AudioStreamPlayer.new()
		player.volume_db = -6 if i == 2 else (-12 if i == 1 else -2)
		add_child(player)
		voices.append(player)
	for kind in ["whistle", "build", "repair", "remove", "collect", "gate", "attack", "object", "bark", "invasion", "restrained", "carried", "rescue", "win", "lose", "animal_danger", "auto_start", "early_clear", "merchant"]:
		cache[kind] = synth(kind, 0.85 if kind in ["win", "rescue", "invasion", "carried", "early_clear", "merchant"] else 0.22)
	ambient = AudioStreamPlayer.new()
	ambient.stream = synth("ambient", 8.0)
	cache.ambient = ambient.stream
	cache.night = synth("night", 8.0)
	ambient.volume_db = -19
	add_child(ambient)
	ambient.play()
	birds = AudioStreamPlayer.new()
	birds.stream = synth("bird", 0.32)
	birds.volume_db = -23
	add_child(birds)
	ambience_rng.seed = 371
	music=AudioStreamPlayer.new();music.name="DayMusic"
	music.stream=DAY_MUSIC.duplicate();music.stream.loop=true;music.stream.loop_offset=0.0
	music.max_polyphony=1;music.volume_db=-80
	add_child(music)

func _process(delta):
	seconds += delta
	var target=db_to_linear(MENU_VOLUME_DB if music_soft else DAY_VOLUME_DB) if music_enabled else 0.0
	if not is_equal_approx(target,music_target):
		music_fade_from=music_level;music_fade_elapsed=0.0
		music_fade_duration=(NIGHT_FADE_OUT_SECONDS if night else MUSIC_FADE_OUT_SECONDS) if target==0 else (MUSIC_FADE_IN_SECONDS if music_target<=0 else MUSIC_SOFT_FADE_SECONDS)
		music_target=target
	music_fade_elapsed=minf(music_fade_duration,music_fade_elapsed+maxf(0,delta))
	music_level=lerpf(music_fade_from,music_target,smoothstep(0.0,1.0,music_fade_elapsed/music_fade_duration))
	if music.playing:
		music.volume_db=linear_to_db(maxf(0.0001,music_level*seam_gain(music.get_playback_position(),music.stream.get_length())))
		if not music_enabled and music_level<=0.0001:
			music_resume=music.get_playback_position();music.stop()
	update_ambience(delta)
	if seconds >= next_bird:
		next_bird = seconds + ambience_rng.randf_range(8, 20)
		if not night: birds.play()

static func seam_gain(position: float,length: float) -> float:
	# Keep the original recording intact; soften its non-silent beginning at loop boundaries.
	return minf(clampf(position/0.12,0.0,1.0),clampf((length-position)/0.5,0.0,1.0))

func set_context(phase: String,soft: bool=false):
	set_night(phase=="defend")
	music_enabled=phase in ["shop","day","dawn"]
	music_soft=soft
	if music_enabled and not music.playing:
		music_level=0.0;music_target=-1.0;music_fade_from=0.0;music_fade_elapsed=0.0
		music.volume_db=-80;music.play(music_resume)

func set_night(value: bool):
	if night == value: return
	night = value
	birds.stop()
	next_bird = seconds + ambience_rng.randf_range(8, 20)
	night_transition=0.0 if night else -1.0
	night_ambient_started=false
	if not night:
		ambient.stream=cache.ambient;ambient.volume_db=ambient_target_db;ambient.play()

func tension(active: bool):
	ambient_target_db=-25 if active else -19

func update_ambience(delta: float):
	if night_transition<0:ambient.volume_db=ambient_target_db;return
	night_transition+=maxf(0,delta)
	var gain=1.0-smoothstep(0.0,NIGHT_FADE_OUT_SECONDS,night_transition)
	if night_transition>=NIGHT_FADE_OUT_SECONDS+NIGHT_GAP_SECONDS:
		if not night_ambient_started:
			ambient.stream=cache.night;ambient.play();night_ambient_started=true
		gain=smoothstep(0.0,NIGHT_AMBIENT_FADE_SECONDS,night_transition-NIGHT_FADE_OUT_SECONDS-NIGHT_GAP_SECONDS)
	ambient.volume_db=linear_to_db(maxf(0.0001,db_to_linear(ambient_target_db)*gain))

func cue(kind: String):
	if not cache.has(kind): return
	var urgent = kind in ["carried", "restrained", "lose", "animal_danger"]
	if kind in ["invasion", "auto_start"] and seconds < danger_until: return
	if urgent: danger_until = seconds + 0.9
	if seconds - last_play.get(kind, -100.0) < (0.4 if kind in ["attack", "object", "bark"] else 0.12): return
	last_play[kind] = seconds
	played[kind] = played.get(kind, 0) + 1
	var channel = 2 if kind in ["attack", "object", "bark"] else (0 if kind in ["invasion", "carried", "restrained", "rescue", "win", "lose", "animal_danger", "early_clear"] else 1)
	voices[channel].volume_db = (-1 if urgent else -4) if channel == 0 else (-7 if channel == 2 else -12)
	voices[channel].stream = cache[kind]
	voices[channel].play()

func synth(kind: String, length: float) -> AudioStreamWAV:
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = 22050
	var count = int(length * stream.mix_rate)
	var bytes = PackedByteArray()
	bytes.resize(count * 2)
	var rng = RandomNumberGenerator.new()
	rng.seed = 913
	var wind = 0.0
	for i in range(count):
		var t = float(i) / stream.mix_rate
		var noise = rng.randf_range(-1, 1)
		wind = lerpf(wind, noise, 0.012)
		var envelope = minf(t * 100, 1) * pow(maxf(0, 1 - t / length), 2)
		var value = 0.0
		match kind:
			"night":
				var seam = minf(1, minf(t, length - t) * 5)
				var chirp = fmod(t, 1.7)
				value = wind * 0.8 * seam
				if chirp < 0.42: value += sin(t * TAU * 3300) * pow(maxf(0, sin(chirp * 80)), 4) * 0.06 * seam
			"ambient":
				var seam = minf(1, minf(t, length - t) * 5)
				value = wind * 1.8 * seam
			"whistle": value = sin(TAU*(1800*t+8*sin(t*25))) * envelope * 0.35
			"bird": value = sin(TAU * (1700 * t + 65 * sin(t * 18))) * sin(t / length * PI) * 0.22
			"invasion":
				value = wooden_bell(t, 146) * 0.85
			"merchant":
				value = wooden_bell(t, 660) * 0.5
				if t >= 0.25: value += wooden_bell(t - 0.25, 880) * 0.3
			"restrained":
				value = (wooden_bell(t, 220) + noise * exp(-t * 42) * 0.25) * 0.9
			"carried":
				value = wooden_bell(t, 196) * 0.65
				if t >= 0.28: value += wooden_bell(t - 0.28, 246) * 0.9
			"rescue", "win", "early_clear":
				value = wooden_bell(t, 392) * 0.55
				if t >= 0.15: value += wooden_bell(t - 0.15, 494) * 0.45
				if t >= 0.30: value += wooden_bell(t - 0.30, 587) * 0.45
			"bark": value = (sin(TAU * (185 * t - 140 * t * t)) + noise * 0.5) * sin(fmod(t, 0.11) / 0.11 * PI) * envelope * 0.55
			"build", "remove", "object": value = (noise * 0.45 + sin(t * TAU * 95) * 0.55) * envelope
			"repair", "gate": value = (sin(t * TAU * (370 if kind == "repair" else 210)) * 0.6 + noise * 0.1) * envelope
			"collect": value = sin(TAU * (720 * t + 600 * t * t)) * envelope * 0.5
			"attack":
				var impact = maxf(0, 1 - (t - 0.065) / 0.12) if t >= 0.065 else 0.0
				value = noise * envelope * 0.18 + sin(t * TAU * 125) * impact * 0.55
			_:
				var danger = kind in ["carried", "restrained", "lose", "animal_danger"]
				var resolve = kind in ["rescue", "win"]
				var hz = (330.0 if danger else 520.0) * (1.5 if resolve and t > length * 0.5 else 1.0)
				value = (sin(t * TAU * hz) + sin(t * TAU * hz * (1.07 if danger else 1.5)) * 0.3) * envelope * 0.5
		bytes.encode_s16(i * 2, int(clampf(value, -1, 1) * 9000))
	stream.data = bytes
	if kind in ["ambient", "night"]:
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		stream.loop_end = count
	return stream

func wooden_bell(t: float, hz: float) -> float:
	return minf(1, t * 200) * (sin(TAU * hz * t) * exp(-t * 6) + sin(TAU * hz * 2.76 * t) * exp(-t * 16) * 0.32 + sin(TAU * hz * 4.1 * t) * exp(-t * 25) * 0.12)
