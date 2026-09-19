extends SceneTree
## Viewport captures from an actual continuous input-driven journey, no teleports.
const SCENE = preload("res://game/main.tscn")
const Model = preload("res://game/dive_model.gd")
const Driver = preload("res://tests/route_driver.gd")
var game
var failed: bool = false
var simulation_frames: int = 0
var sequence: Array[Dictionary] = []
var record_sequence := true
var capture_root: String


func _initialize() -> void:
	run.call_deferred()


func capture(label: String) -> void:
	game._update_camera()
	game.hud.queue_redraw()
	for frame in range(20):
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
	if label == "20-pier-lookdown":
		# Fixed overhead scene: sample ocean outside the pier and HUD.
		var bright_pixels := 0
		for x in range(25, 105):
			for y in range(150, 580):
				for point in [Vector2i(x, y), Vector2i(1280 - x, y)]:
					var color := shot.get_pixelv(point)
					if color.r > .65 and color.g > .7 and color.b > .7:
						bright_pixels += 1
		print("Overhead water bright pixels: %d" % bright_pixels)
		if bright_pixels > 12:
			failed = true
			push_error("Overhead water must not contain bright noise-grid streaks")
	var source := capture_root + "/%s.png" % label
	var result := shot.save_png(source)
	mirror_capture(source, "res://artifacts/%s.png" % label)
	if result != OK:
		failed = true
		push_error("Screenshot failed: " + label)


func step_toward(
	index: int, descent_override: float = -2, ascend: bool = false, fast_route: bool = false
) -> void:
	var command := Driver.input_for(game.model, index, fast_route)
	game.advance(
		1.0 / 60,
		Vector2(command.x, command.z),
		command.y if descent_override == -2 else descent_override,
		ascend
	)

	await render_step()


func render_step() -> void:
	game._update_camera(1.0 / 60)
	game.hud.queue_redraw()
	await process_frame
	await RenderingServer.frame_post_draw
	simulation_frames += 1
	if record_sequence and simulation_frames % 120 == 0 and game.model.elapsed <= 65:
		var filename := "frame-%03d.jpg" % sequence.size()
		var result := root.get_texture().get_image().save_jpg(
			capture_root + "/sequence/" + filename, .85
		)
		mirror_capture(
			capture_root + "/sequence/" + filename, "res://artifacts/sequence/" + filename
		)
		if result != OK:
			failed = true
		sequence.append(
			{
				"file": filename,
				"seconds": snappedf(game.model.elapsed, .01),
				"depth": snappedf(game.model.depth, .1),
				"pose": game.avatar.pose
			}
		)


func steer(index: int, fast_route: bool = false) -> bool:
	for frame in range(2400):
		await step_toward(index, -2, false, fast_route)
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
	root.unfocusable = true
	capture_root = "res://artifacts/" + RenderingServer.get_current_rendering_method()
	DirAccess.make_dir_recursive_absolute(capture_root + "/sequence")
	DirAccess.make_dir_recursive_absolute("res://artifacts/sequence")
	game = SCENE.instantiate()
	game.automated_input = true
	root.add_child(game)
	await process_frame
	game.set_physics_process(false)
	game.set_process_unhandled_input(false)
	await capture("title")
	game.begin()
	if Input.mouse_mode != Input.MOUSE_MODE_VISIBLE or not root.unfocusable:
		push_error("GPU automation must not capture the desktop mouse or take focus")
		quit(1)
		return
	await capture("01-surface-start")
	game.pitch = -.65
	await capture("20-pier-lookdown")
	if "--water-only" in OS.get_cmdline_user_args():
		game.queue_free()
		await process_frame
		quit(1 if failed else 0)
		return
	game.pitch = -.25
	for frame in range(600):
		await step_toward(1)
		if game.model.grounded < 0 and game.model.position.y < 2:
			break
	await capture("02-water-entry")
	for frame in range(600):
		await step_toward(1)
		if game.model.depth > 12:
			break
	game.pitch = 0.55
	await capture("03-sunlight")
	game.pitch = -0.2
	game.yaw = -0.48
	await capture("04-open-ocean")
	game.pitch = -0.65
	game.yaw = 0
	if not await steer(1):
		quit(1)
		return
	await capture("05-platform")
	game.pitch = -.15
	game.yaw = 1.0
	await capture("11-cliff")
	game.yaw = PI
	game.pitch = -.12
	await capture("12-protagonist")
	game.yaw = 0
	game.pitch = -.65
	game.third_person = false
	await capture("camera-first-person")
	game.third_person = true
	await capture("camera-third-person")
	for frame in range(1200):
		await step_toward(2)
		if game.model.depth > 38:
			break
	await capture("06-sinking")
	game.pitch = -.25
	await capture("13-current-particles")
	game.pitch = -.65
	for frame in range(60):
		await step_toward(2, 1)
	await capture("07-fast-descent")
	for frame in range(180):
		await step_toward(2, 0, true)
	if game.model.velocity.y < 5:
		failed = true
		push_error("Space capture must actually show upward movement")
	await capture("08-space-ascent")
	if not await steer(2):
		quit(1)
		return
	await capture("09-oxygen")
	Input.action_press("survey")
	await capture("route-survey")
	await capture("15-real-layer-overview")
	Input.action_release("survey")
	if not await steer(3):
		quit(1)
		return
	# Walk to the curved edge and back with player inputs, without repositioning.
	for goal_offset in [5.6, 0.0]:
		for frame in range(120):
			var target: Vector3 = game.model.platforms[3].position + Vector3(0, 0, goal_offset)
			var offset := Vector2(
				target.x - game.model.position.x, target.z - game.model.position.z
			)
			game.advance(1.0 / 60, (offset * 1.6 / 7.0).limit_length())
			await render_step()
		if goal_offset > 0:
			if game.model.grounded != 3 or game.model.position.y >= -90.2:
				failed = true
				push_error("Feet must follow the curved wood edge during an actual walk")
			game.yaw = 1.4
			game.pitch = -.2
			await capture("21-driftwood-edge")
			game.yaw = 0
			game.pitch = -.65
	for frame in range(1600):
		game.advance(1.0 / 60, Vector2.ZERO)
		await render_step()
		if game.model.oxygen < 4:
			break
	await capture("low-oxygen")
	for frame in range(300):
		game.advance(1.0 / 60, Vector2.ZERO)
		await render_step()
		if game.model.mode == Model.Mode.RETURNING:
			break
	for frame in range(25):
		game.advance(1.0 / 60, Vector2.ZERO)
		await render_step()
	await capture("emergency-ascent")
	for frame in range(1800):
		game.advance(1.0 / 60, Vector2.ZERO)
		await render_step()
		if game.model.mode == Model.Mode.DIVING:
			break
	await capture("retry")
	if game.model.grounded != 2 or game.model.depth_losses.size() != 1:
		failed = true
		push_error("Emergency ascent must return to oxygen 01")
	for index in [3, 4, 5, 6, 7, 8, 9]:
		if not await steer(index):
			break
		if index == 4:
			game.pitch = -.35
			await capture("14-jelly")
			game.pitch = -.65
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
	# A second real journey covers new optional gardens and the current corridor.
	record_sequence = false
	game.hud.primary.pressed.emit()
	game.pitch = -.65
	for target in Model.Layout.routes().safe_gardens:
		if not await steer(target, true):
			break
		if target == 2:
			for frame in range(60):
				game.advance(1.0 / 60, Vector2.ZERO)
				await render_step()
			await capture("16-route-choices")
			game.pitch = -.18
			await capture("17-oxygen-algae")
			game.pitch = -.65
		if target == 11:
			await capture("18-current-garden")
		if target == 12:
			await capture("19-safe-detour")
	if game.model.mode != Model.Mode.COMPLETE:
		failed = true
		push_error("Safe garden route must also finish on GPU")
	game.hud.primary.pressed.emit()
	root.size = Vector2i(960, 540)
	game.toggle_pause()
	await capture("pause-960")
	print("Visual: surface, sun, movement, refill, platform, rescue, goal; failures=%s" % failed)
	var record := FileAccess.open(capture_root + "/sequence/frames.json", FileAccess.WRITE)
	record.store_string(JSON.stringify(sequence, "  "))
	record.close()
	mirror_capture(capture_root + "/sequence/frames.json", "res://artifacts/sequence/frames.json")
	game.queue_free()
	await process_frame
	quit(1 if failed else 0)


func mirror_capture(source: String, destination: String) -> void:
	var result := DirAccess.copy_absolute(
		ProjectSettings.globalize_path(source), ProjectSettings.globalize_path(destination)
	)
	if result != OK:
		failed = true
		push_error("Cannot preserve renderer-specific capture: " + source)
