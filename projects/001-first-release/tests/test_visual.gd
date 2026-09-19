extends SceneTree
## Rendered integration test: use the actual scene, input actions, and rules.
## Run without --headless. Images are disposable artifacts, not game assets.

const SCENE = preload("res://game/main.tscn")
const Model = preload("res://game/dive_model.gd")
var game


func _initialize() -> void:
	run.call_deferred()


func capture(label: String) -> void:
	game._update_camera()
	game.hud.queue_redraw()
	await process_frame
	await RenderingServer.frame_post_draw
	var result := root.get_texture().get_image().save_png("res://artifacts/%s.png" % label)
	if result != OK:
		push_error("Screenshot failed: " + label)
		quit(1)


func run() -> void:
	game = SCENE.instantiate()
	root.add_child(game)
	await process_frame
	game.set_physics_process(false)
	await capture("title")
	game.begin()
	# Exercise the same action mapping used by physical E, Shift and D input.
	Input.action_press("dive")
	Input.action_press("surge")
	Input.action_press("right")
	for frame in range(30):
		game._physics_process(1.0 / 60)
	Input.action_release("right")
	for frame in range(1000):
		game._physics_process(1.0 / 60)
		if game.model.pressure >= 75:
			break
	await capture("pressure-warning")
	for frame in range(1000):
		game._physics_process(1.0 / 60)
		if game.model.mode == Model.Mode.RETURNING:
			break
	await capture("forced-ascent")
	Input.action_release("dive")
	Input.action_release("surge")
	for frame in range(300):
		game._physics_process(1.0 / 60)
	await capture("recovered")
	var recovering := false
	for frame in range(60 * 180):
		if game.model.pressure > 65:
			recovering = true
		elif game.model.pressure < 15:
			recovering = false
		game.advance(1.0 / 60, Vector2.ZERO, 0 if recovering else 1, false)
		if game.model.mode == Model.Mode.COMPLETE:
			break
	await capture("goal")
	if game.model.mode != Model.Mode.COMPLETE or game.model.setbacks != 1:
		push_error("Rendered playthrough did not reach the goal after one setback")
		quit(1)
		return
	game.hud.primary.pressed.emit()
	await capture("replay")
	root.size = Vector2i(960, 540)
	game.toggle_pause()
	await capture("pause-960")
	print("Visual playthrough: warning, forced ascent, recovery, goal, replay, resize OK")
	game.queue_free()
	await process_frame
	quit()
