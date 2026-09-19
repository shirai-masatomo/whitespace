extends SceneTree

const SCENE = preload("res://game/main.tscn")
const Model = preload("res://game/dive_model.gd")
const Driver = preload("res://tests/route_driver.gd")
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
	check(
		ProjectSettings.get_setting("rendering/anti_aliasing/quality/msaa_3d") == 2,
		"3D MSAA configured in rendering section"
	)
	var game = SCENE.instantiate()
	root.add_child(game)
	await process_frame
	game.set_physics_process(false)
	check(not game.started and game.hud.primary.visible, "Initial instructions visible")
	game.hud.primary.pressed.emit()
	check(game.started and not game.paused, "Start button starts play")
	Input.action_press("dive")
	Input.action_press("right")
	for frame in range(180):
		game._physics_process(1.0 / 60)
	Input.action_release("dive")
	Input.action_release("right")
	check(game.model.depth > 5 and game.model.position.x > 15, "Inputs move and sink after edge")
	check(game.avatar.position == game.model.position, "Avatar follows simulation")
	Input.action_press("ascend")
	for frame in range(150):
		game._physics_process(1.0 / 60)
	Input.action_release("ascend")
	check(game.model.velocity.y > 5, "Space input ascends underwater")
	check(game.model.oxygen_rate == 4, "Ascent consumes normal oxygen")
	for frame in range(90):
		game._physics_process(1.0 / 60)
	check(game.model.velocity.y == -5, "Space release resumes sinking")

	var event := InputEventMouseMotion.new()
	event.relative = Vector2(100, 10)
	game._unhandled_input(event)
	check(game.yaw < 0 and game.pitch < -0.25, "Mouse moves view")
	var key := InputEventKey.new()
	key.keycode = KEY_V
	key.pressed = true
	game._unhandled_input(key)
	game._update_camera()
	check(not game.third_person and not game.avatar.visible, "V toggles first person")
	check(
		game.camera.position.distance_to(game.model.position + Vector3.UP * 1.4) < 0.01,
		"First person uses eye position"
	)
	game._unhandled_input(key)
	game._update_camera()
	check(game.third_person and game.avatar.visible, "V restores third person")
	game.toggle_pause()
	var paused_position: Vector3 = game.model.position
	var paused_oxygen: float = game.model.oxygen
	game._physics_process(1)
	check(
		game.model.position == paused_position and game.model.oxygen == paused_oxygen,
		"Pause freezes risk and movement"
	)
	game.begin()
	game._notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	check(game.paused, "Focus loss pauses game")
	game.restart()
	for index in game.model.Layout.routes().platforms:
		check(Driver.reach(game.model, index), "Scene route platform %d" % index)
		if game.model.platforms[index].oxygen:
			Driver.refill(game.model)
	game.advance(0, Vector2.ZERO)
	check(game.model.mode == Model.Mode.COMPLETE and game.hud.primary.visible, "Goal offers replay")
	var scene_id: int = game.get_instance_id()
	game.hud.primary.pressed.emit()
	check(
		game.model.position.y == 6 and game.get_instance_id() == scene_id, "Replay uses same scene"
	)
	var target_before: int = game.next_platform()
	key.keycode = KEY_TAB
	game._unhandled_input(key)
	check(game.next_platform() != target_before, "Tab changes target")
	game.yaw = atan2(-14.0, 18.0) + PI
	check(
		game.Navigation.bearing(game.model, 1, game.yaw) == "後方 / 振り向く",
		"Offscreen target has behind-camera guidance"
	)
	Input.action_press("survey")
	game._update_camera()
	check(game.camera.position.y > game.model.position.y + 25, "F shows survey camera")
	check(game.camera.position.y > 6, "Outdoor survey remains above the surface")
	Input.action_release("survey")
	game._update_camera()
	check(
		game.camera.position.y < game.model.position.y + 20, "Releasing F returns to normal camera"
	)
	game.restart()
	check(game.next_platform() == 1, "Replay restores first suggested target")
	_test_ledge_view(game)
	game.queue_free()
	await process_frame
	print("Scene: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)


func _test_ledge_view(game) -> void:
	game.model = Model.new()
	for target in [1, 2, 3]:
		check(Driver.reach(game.model, target), "Camera fixture reaches its platform")
		for angle in [-.3, -.4, -.65, -1.2]:
			for heading in [0.0, 1.7, -2.3]:
				game.yaw = heading
				game.pitch = angle
				game._update_camera()
				var focus: Vector3 = game.model.position + Vector3.UP
				check(
					not game.camera.is_position_behind(focus), "Ledge view retains diver in front"
				)
				check(
					Rect2(0, 0, 1280, 720).has_point(game.camera.unproject_position(focus)),
					"Ledge view keeps diver framed through mouse pitch and yaw"
				)
				check(game.yaw == heading, "Ledge view never rotates the player's horizontal input")
	game.pitch = -.65
	game._update_camera()
	var before: Vector3 = game.camera.position - game.model.position
	game.model.grounded = -1
	game._update_camera(1.0 / 60)
	var after: Vector3 = game.camera.position - game.model.position
	check(before.distance_to(after) < 5, "Leaving a ledge blends the camera instead of jumping")
