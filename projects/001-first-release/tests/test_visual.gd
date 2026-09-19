extends SceneTree
## Viewport captures from an actual continuous input-driven journey, no teleports.
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
	for frame in range(3):
		await process_frame
		await RenderingServer.frame_post_draw
	var shot := root.get_texture().get_image()
	# Catch actual GPU regressions: node visibility alone missed disappearing buttons.
	if label == "goal":
		for point in [Vector2i(320, 500), Vector2i(750, 500)]:
			var color := shot.get_pixelv(point)
			if color.g < 0.6 or color.b < 0.5:
				failed = true
				push_error("Goal replay/exit buttons must render above the deep ocean")
	var result := shot.save_png("res://artifacts/%s.png" % label)
	if result != OK:
		failed = true
		push_error("Screenshot failed: " + label)


func step_toward(index: int, descent_override: float = -2, ascend: bool = false) -> void:
	var command := Driver.input_for(game.model, index)
	game.advance(
		1.0 / 60,
		Vector2(command.x, command.z),
		command.y if descent_override == -2 else descent_override,
		ascend
	)


func steer(index: int) -> bool:
	for frame in range(2400):
		step_toward(index)
		if game.model.grounded == index:
			if not game.model.platforms[index].oxygen or game.model.at_oxygen():
				return true
		if game.model.mode == Model.Mode.RETURNING:
			failed = true
			push_error("Visual route failed at platform %d" % index)
			return false
	failed = true
	push_error("Visual route timeout")
	return false


func run() -> void:
	game = SCENE.instantiate()
	root.add_child(game)
	await process_frame
	game.set_physics_process(false)
	await capture("title")
	game.begin()
	await capture("01-surface-start")
	for frame in range(600):
		step_toward(1)
		if game.model.grounded < 0 and game.model.position.y < 2:
			break
	await capture("02-water-entry")
	for frame in range(600):
		step_toward(1)
		if game.model.depth > 12:
			break
	game.pitch = 0.1
	await capture("03-sunlight")
	game.pitch = -0.2
	game.yaw = -0.48
	await capture("04-open-ocean")
	game.pitch = -0.65
	game.yaw = 0
	if not steer(1):
		quit(1)
		return
	await capture("05-platform")
	game.third_person = false
	await capture("camera-first-person")
	game.third_person = true
	await capture("camera-third-person")
	for frame in range(1200):
		step_toward(2)
		if game.model.depth > 38:
			break
	await capture("06-sinking")
	for frame in range(60):
		step_toward(2, 1)
	await capture("07-fast-descent")
	for frame in range(180):
		step_toward(2, 0, true)
	if game.model.velocity.y < 5:
		failed = true
		push_error("Space capture must actually show upward movement")
	await capture("08-space-ascent")
	if not steer(2):
		quit(1)
		return
	await capture("09-oxygen")
	Input.action_press("survey")
	await capture("route-survey")
	Input.action_release("survey")
	if not steer(3):
		quit(1)
		return
	for frame in range(1600):
		game.advance(1.0 / 60, Vector2.ZERO)
		if game.model.oxygen < 4:
			break
	await capture("low-oxygen")
	for frame in range(300):
		game.advance(1.0 / 60, Vector2.ZERO)
		if game.model.mode == Model.Mode.RETURNING:
			break
	for frame in range(25):
		game.advance(1.0 / 60, Vector2.ZERO)
	await capture("emergency-ascent")
	for frame in range(1800):
		game.advance(1.0 / 60, Vector2.ZERO)
		if game.model.mode == Model.Mode.DIVING:
			break
	await capture("retry")
	if game.model.grounded != 2 or game.model.depth_losses.size() != 1:
		failed = true
		push_error("Emergency ascent must return to oxygen 01")
	for index in [3, 4, 5, 6, 7, 8, 9]:
		if not steer(index):
			break
		if index == 5:
			await capture("moving-container")
		if index == 8:
			game.pitch = -0.15
			await capture("10-deep-ocean")
			game.pitch = -0.65
	await capture("goal")
	if game.model.mode != Model.Mode.COMPLETE:
		failed = true
		push_error("Visual route must finish after rescue")
	game.hud.primary.pressed.emit()
	root.size = Vector2i(960, 540)
	game.toggle_pause()
	await capture("pause-960")
	print("Visual: surface, sun, movement, refill, platform, rescue, goal; failures=%s" % failed)
	game.queue_free()
	await process_frame
	quit(1 if failed else 0)
