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
	key.keycode = KEY_M
	game._unhandled_input(key)
	check(game.sound.muted, "M mutes game feedback")
	game._unhandled_input(key)
	check(not game.sound.muted, "M restores game feedback")
	game.toggle_pause()
	check(game.sound.suspended, "Game pause also pauses audio")
	var paused_position: Vector3 = game.model.position
	var paused_oxygen: float = game.model.oxygen
	game._physics_process(1)
	check(
		game.model.position == paused_position and game.model.oxygen == paused_oxygen,
		"Pause freezes risk and movement"
	)
	game.begin()
	check(not game.sound.suspended, "Resume restores sound playback")
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
	_test_pose_blending(game)
	_test_oxygen_algae(game)
	await physics_frame
	_test_driftwood_footing(game)
	game.queue_free()
	await process_frame
	print("Scene: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)


func _test_ledge_view(game) -> void:
	game.model = Model.new()
	for target in [0, 1, 2, 3]:
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


func _test_pose_blending(game) -> void:
	game.restart()
	for target in [1, 2]:
		check(Driver.reach(game.model, target), "Animation fixture reaches oxygen shelf")
	for frame in range(120):
		game.model.step(1.0 / 60, Vector2.ZERO)
		game.avatar.animate(game.model)
	check(game.avatar.pose == "idle", "Stationary shelf pose settles after landing")
	for leg in game.avatar.thighs + game.avatar.shins:
		check(absf(leg.rotation.x) < 0.01, "Idle feet stop cycling on the platform")
	var before: float = game.avatar.arms[0].rotation.x
	game.model.step(1.0 / 60, Vector2.ZERO, 0.0, true)
	game.avatar.animate(game.model)
	check(
		absf(game.avatar.arms[0].rotation.x - before) < 0.5,
		"Ascent arm pose blends instead of snapping on its first frame"
	)
	for frame in range(30):
		game.model.step(1.0 / 60, Vector2.ZERO, 0.0, true)
		game.avatar.animate(game.model)
	check(game.avatar.arms[0].rotation.x < -1.5, "Blended arms reach the ascent stroke")


func _test_oxygen_algae(game) -> void:
	game.restart()
	game.model.position = game.model.platforms[2].position
	var options: Array[int] = game.Navigation.candidates(game.model)
	check(
		options.has(3) and options.has(10),
		"Both the direct descent and refill detour can be selected"
	)
	for index in range(game.model.platforms.size()):
		if not game.model.platforms[index].oxygen:
			continue
		var fronds := game.world.platforms[index].get_node("OxygenAlgae/Fronds") as MeshInstance3D
		check(fronds != null, "Every refill has a visible rooted algae landmark")
		var vertices: PackedVector3Array = fronds.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
		var covered := true
		for vertex in vertices:
			# Include the largest possible shader displacement, not only the static mesh.
			if vertex.distance_to(Vector3.UP * 1.6) + .47 > game.model.config.oxygen_radius:
				covered = false
		check(covered, "Visible algae leaves remain inside the instant refill volume")
		game.model.position = game.model.platforms[index].position + Vector3.UP * 2
		game.model.grounded = -1
		game.model.oxygen = .01
		game.model.step(1.0 / 60, Vector2.ZERO)
		check(game.model.oxygen == 100, "Touching each algae stand refills without a waiting state")


func _test_driftwood_footing(game) -> void:
	var largest_error := 0.0
	var samples := 0
	for index in [3, 10]:
		var platform: Dictionary = game.model.platforms[index]
		for x in [-5.0, -3.0, 0.0, 3.0, 5.0]:
			for z in [-5.5, -4.5, -2.5, -1.0, 0.0, 1.0, 2.5, 4.5, 5.5]:
				var point: Vector3 = platform.position + Vector3(x, 0, z)
				var query := PhysicsRayQueryParameters3D.create(
					point + Vector3.UP * 8, point + Vector3.DOWN * 8, 2
				)
				var hit: Dictionary = game.get_world_3d().direct_space_state.intersect_ray(query)
				var floor_y: float = game.model.surface_height(point, platform)
				check(
					is_finite(floor_y) == (not hit.is_empty()),
					"Wood footprint agrees with mesh ray"
				)
				if hit.is_empty():
					continue
				var error: float = absf(floor_y - hit.position.y)
				largest_error = maxf(largest_error, error)
				samples += 1
				check(error < .03, "Wood foot height agrees with rendered trunk within 3cm")
	var corner: Vector3 = game.model.platforms[10].position + Vector3(0, 0, 6.8)
	check(
		not game.model.inside(corner, game.model.platforms[10]), "No invisible floor outside trunks"
	)
	check(samples > 60, "Footing test samples both actual rendered log rafts")
	print("Driftwood: %d mesh samples, max height error %.4fm" % [samples, largest_error])
