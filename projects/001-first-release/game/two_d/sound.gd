extends Node
## Reuse our original synthesized sounds; no edits to the frozen 3D game.
const Synth = preload("res://game/ocean_audio.gd")
var players: Dictionary = {}
var muted := false
var last_wet := false
var last_rescue := false
var last_oxygen := 100.0
var warning_timer := 0.0
var last_stage := 0
var goal_played := false


func _ready() -> void:
	for label in [
		"surface",
		"underwater",
		"movement",
		"entry",
		"refill",
		"warning",
		"rescue",
		"goal",
		"deep_call"
	]:
		var player := AudioStreamPlayer.new()
		player.stream = Synth.synthesize(label)
		player.volume_db = -80
		add_child(player)
		players[label] = player
		if (
			label in ["surface", "underwater", "movement"]
			and AudioServer.get_driver_name() != "Dummy"
		):
			player.play()


func observe(game: Node2D, delta: float) -> void:
	var quiet: bool = muted or game.paused or not game.started
	var wet: bool = (
		game.player.position.y > game.Terrain.SURFACE
		and not game.encounters.air_at(game.player.position)
	)
	players.surface.volume_db = -80 if quiet or wet else -22
	players.underwater.volume_db = -80 if quiet or not wet else -12
	players.movement.volume_db = (
		-80 if quiet or not wet else lerpf(-45, -23, minf(1, game.player.velocity.length() / 190))
	)
	for player in players.values():
		player.stream_paused = quiet
	if quiet:
		return
	warning_timer = maxf(0, warning_timer - delta)
	if wet and not last_wet:
		cue("entry")
	if game.rescuing and not last_rescue:
		cue("rescue")
	if game.oxygen > last_oxygen + 10:
		cue("refill")
	if game.oxygen < 25 and warning_timer == 0:
		cue("warning")
		warning_timer = 6
	if game.encounters.stage > last_stage:
		cue("deep_call")
	if game.complete and not goal_played:
		cue("goal")
		goal_played = true
	last_wet = wet
	last_oxygen = game.oxygen
	last_rescue = game.rescuing
	last_stage = game.encounters.stage


func cue(label: String) -> void:
	if not muted and AudioServer.get_driver_name() != "Dummy":
		players[label].volume_db = -16
		players[label].play()
