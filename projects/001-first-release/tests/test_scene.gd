extends SceneTree

const SCENE = preload("res://game/main.tscn")
const Model = preload("res://game/dive_model.gd")
var failures: int = 0
var checks: int = 0


func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(message)


func _initialize() -> void:
	run.call_deferred()


func run() -> void:
	var game = SCENE.instantiate()
	root.add_child(game)
	await process_frame
	game.set_physics_process(false)
	check(not game.started and game.hud.primary.visible, "Initial instructions must be visible")
	game.hud.primary.pressed.emit()
	check(game.started and not game.paused, "Start button must start play")
	Input.action_press("dive")
	Input.action_press("right")
	for frame in range(120):
		game._physics_process(1.0 / 60)
	Input.action_release("dive")
	Input.action_release("right")
	check(
		game.model.depth > 20 and game.camera.position.y < -20,
		"Input must update model and camera depth"
	)
	check(game.swimmer.x > 5, "Horizontal movement must work")
	var event := InputEventMouseMotion.new()
	event.relative = Vector2(100, 10)
	game._unhandled_input(event)
	check(game.yaw < 0 and game.pitch < -0.42, "Mouse motion must update view")
	game.toggle_pause()
	var paused_depth: float = game.model.depth
	var paused_pressure: float = game.model.pressure
	Input.action_press("dive")
	game._physics_process(1.0)
	Input.action_release("dive")
	check(
		game.model.depth == paused_depth and game.model.pressure == paused_pressure,
		"Pause must freeze risk and progress"
	)
	game.begin()
	game._notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	check(game.paused, "Focus loss must pause instead of continuing unseen")
	game.begin()
	for frame in range(300):
		game.advance(1.0 / 60, Vector2.ONE, 0, false)
	check(
		Vector2(game.swimmer.x, game.swimmer.z).length() <= 23.001,
		"Player must remain inside test volume"
	)
	var recovering := false
	for frame in range(60 * 180):
		if game.model.pressure > 65:
			recovering = true
		elif game.model.pressure < 15:
			recovering = false
		game.advance(1.0 / 60, Vector2.ZERO, 0 if recovering else 1, false)
		if game.model.mode == Model.Mode.COMPLETE:
			break
	check(
		game.model.mode == Model.Mode.COMPLETE and game.hud.primary.visible,
		"Goal must offer replay in same scene"
	)
	var scene_id: int = game.get_instance_id()
	game.hud.primary.pressed.emit()
	check(
		game.model.depth == 0 and game.get_instance_id() == scene_id, "Replay must reuse the scene"
	)
	game.queue_free()
	await process_frame
	print("Scene: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
