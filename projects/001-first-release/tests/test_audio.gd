extends SceneTree
## Validate PCM headroom, lifecycle and game feedback without opening an audio device.
const Sound = preload("res://game/ocean_audio.gd")
const Model = preload("res://game/dive_model.gd")
var failures := 0
var checks := 0


func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(message)


func _initialize() -> void:
	run.call_deferred()


func run() -> void:
	var sound := Sound.new()
	root.add_child(sound)
	await process_frame
	var metrics := {}
	for label in Sound.bank:
		var stream: AudioStreamWAV = Sound.bank[label]
		var bytes := stream.data
		var peak := 0.0
		var energy := 0.0
		for offset in range(0, bytes.size(), 2):
			var sample := bytes.decode_s16(offset) / 32768.0
			peak = maxf(peak, absf(sample))
			energy += sample * sample
		var rms := sqrt(energy / (bytes.size() / 2))
		check(peak < .89 and rms > .001, label + " is audible PCM with headroom, not clipped")
		check(absf(bytes.decode_s16(0)) < 2, label + " starts without an amplitude step")
		check(absf(bytes.decode_s16(bytes.size() - 2)) < 10, label + " ends without a click")
		metrics[label] = {"peak": peak, "rms": rms, "seconds": stream.get_length()}
		stream.save_to_wav("res://artifacts/audio-" + label + ".wav")
	var worst_mix: float = metrics.surface.peak * .28 + metrics.underwater.peak * .30
	worst_mix += metrics.movement.peak * .33
	for label in Sound.CUE_NAMES:
		worst_mix += metrics[label].peak * .42
	check(worst_mix < .98, "Even coincident cue peaks retain master output headroom")
	var model = Model.new()
	sound.reset(model)
	sound.observe(model, .1)
	check(sound.events.is_empty(), "Starting above water does not play a splash or refill")
	model.position.y = -5
	model.grounded = -1
	model.velocity.y = -15
	model.oxygen = 70
	sound.observe(model, .1)
	check(sound.events == ["entry"], "Entering water cues once")
	for frame in range(60):
		sound.observe(model, 1.0 / 60)
	check(sound.events.size() == 1, "Remaining underwater does not repeat entry")
	check(sound.mix.underwater > sound.mix.surface, "Underwater mix replaces surface waves")
	var fast_mix: float = sound.mix.movement
	model.velocity.y = -5
	for frame in range(60):
		sound.observe(model, 1.0 / 60)
	check(sound.mix.movement < fast_mix, "Fast descent has more movement sound than sinking")
	model.oxygen = 100
	sound.observe(model, .1)
	check(sound.events[-1] == "refill", "Instant oxygen refill gives one audible response")
	for frame in range(30):
		sound.observe(model, 1.0 / 60)
	check(sound.events.count("refill") == 1, "Waiting at algae does not spam refill sound")
	model.oxygen = 20
	sound.observe(model, .1)
	check(sound.events[-1] == "warning", "Low oxygen is communicated without reading HUD")
	for frame in range(60):
		sound.observe(model, 1.0 / 60)
	check(sound.events.count("warning") == 1, "Warning has a quiet interval")
	model.begin_return("test")
	sound.observe(model, .1)
	check(sound.events[-1] == "rescue", "Rescue has a distinct cue")
	sound.observe(model, .1)
	check(sound.events.count("rescue") == 1, "Rescue does not restart its sound each tick")
	sound.set_muted(true)
	for player in sound.players.values():
		check(player.volume_linear == 0, "Mute reaches every audio layer")
	sound.suspend(true)
	check(
		(
			sound.suspended
			and (
				sound.players.underwater.stream_paused
				if sound.output_enabled
				else not sound.players.underwater.playing
			)
		),
		"Pause silences playback or keeps Dummy inactive"
	)
	if AudioServer.get_driver_name() == "Dummy":
		check(not sound.output_enabled, "Automation never queues playback on the Dummy driver")
	var before := sound.events.size()
	sound.observe(model, 10)
	check(sound.events.size() == before, "Paused game cannot produce more cues")
	sound.suspend(false)
	sound.set_muted(false)
	check(sound.players.underwater.volume_linear > 0, "Unmute restores existing mix")
	model.reset()
	sound.reset(model)
	sound.observe(model, .1)
	check(sound.events.is_empty(), "Replay clears old rescue and oxygen transition state")
	var file := FileAccess.open("res://artifacts/audio-metrics.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(metrics, "  "))
	print("Audio: %d checks, %d failures" % [checks, failures])
	sound.queue_free()
	await process_frame
	# Give the audio thread one mix block to release queued playback handles.
	await create_timer(.1).timeout
	quit(1 if failures else 0)
