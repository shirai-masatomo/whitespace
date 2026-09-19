extends SceneTree
## Actual rendered scene. All route/failure screenshots follow simulated input;
## no teleport, replacement scene, or edited image is used for the review gallery.

const SCENE = preload("res://game/main.tscn")
const Model = preload("res://game/dive_model.gd")
const Driver = preload("res://tests/route_driver.gd")
var game
var failed: bool = false


func _initialize() -> void:
	run.call_deferred()


func capture(label: String) -> void:
	game._update_camera()
	game.hud.queue_redraw()
	await process_frame
	await RenderingServer.frame_post_draw
	var result := root.get_texture().get_image().save_png("res://artifacts/%s.png" % label)
	if result != OK:
		failed = true
		push_error("Screenshot failed: " + label)


func steer(index: int) -> bool:
	for frame in range(2400):
		var command := Driver.input_for(game.model, index)
		game.advance(1.0 / 60, Vector2(command.x, command.z), command.y)
		if game.model.grounded == index:
			if not game.model.platforms[index].oxygen or game.model.at_oxygen():
				return true
		if game.model.mode == Model.Mode.RETURNING:
			failed = true
			push_error("Visual route failed at platform %d" % index)
			return false
	return false


func run() -> void:
	game = SCENE.instantiate()
	root.add_child(game)
	await process_frame
	game.set_physics_process(false)
	await capture("title")
	game.begin()
	await capture("01-start")
	# Look from the starting platform across the open ocean.
	game.pitch = -0.20
	game.yaw = -0.48
	await capture("02-ocean")
	game.pitch = -0.65
	game.yaw = 0
	if not steer(1):
		quit(1)
		return
	await capture("03-platform")
	# Compare both cameras at exactly the same player position and view angles.
	game.third_person = false
	await capture("camera-first-person")
	game.third_person = true
	await capture("camera-third-person")
	for frame in range(2400):
		var command := Driver.input_for(game.model, 2)
		game.advance(1.0 / 60, Vector2(command.x, command.z), command.y)
		if game.model.depth > 42:
			break
	await capture("04-sinking")
	if not steer(2):
		quit(1)
		return
	await capture("05-oxygen")
	Driver.refill(game.model)
	if not steer(3):
		quit(1)
		return
	# Waiting on a normal platform consumes oxygen; the start/oxygen spots do not.
	for frame in range(1600):
		game.advance(1.0 / 60, Vector2.ZERO)
		if game.model.oxygen < 4:
			break
	await capture("06-low-oxygen")
	for frame in range(300):
		game.advance(1.0 / 60, Vector2.ZERO)
		if game.model.mode == Model.Mode.RETURNING:
			break
	for frame in range(25):
		game.advance(1.0 / 60, Vector2.ZERO)
	await capture("07-ascent")
	for frame in range(1800):
		game.advance(1.0 / 60, Vector2.ZERO)
		if game.model.mode == Model.Mode.DIVING:
			break
	await capture("08-retry")
	if game.model.grounded != 2 or game.model.depth_losses.size() != 1:
		failed = true
		push_error("Emergency ascent must return to oxygen 01")
	for index in range(3, game.model.platforms.size()):
		if not steer(index):
			failed = true
			break
		if game.model.platforms[index].oxygen:
			Driver.refill(game.model)
	await capture("goal")
	if game.model.mode != Model.Mode.COMPLETE:
		failed = true
		push_error("Visual route must reach the goal after rescue")
	game.hud.primary.pressed.emit()
	root.size = Vector2i(960, 540)
	game.toggle_pause()
	await capture("pause-960")
	print(
		(
			"Visual: eight review states, camera A/B, goal after rescue, replay, 960x540 pause; failures=%s"
			% failed
		)
	)
	game.queue_free()
	await process_frame
	quit(1 if failed else 0)
