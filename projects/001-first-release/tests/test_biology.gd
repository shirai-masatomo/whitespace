extends "res://tests/test_discovery.gd"
## Real input from the pier through the single throat; only three review captures.
const Biology = preload("res://game/biology_layout.gd")


func run() -> void:
	gpu = DisplayServer.get_name() != "headless"
	root.unfocusable = true
	record_sequence = false
	capture_root = "res://artifacts/biology-" + RenderingServer.get_current_rendering_method()
	DirAccess.make_dir_recursive_absolute(capture_root)
	game = SCENE.instantiate()
	game.automated_input = true
	root.add_child(game)
	await process_frame
	await physics_frame
	game.set_physics_process(false)
	game.set_process_unhandled_input(false)
	game.begin()
	var scene_id: int = game.get_instance_id()
	# Short local iteration starts on the existing refuge; --full uses pier inputs.
	var route: Array = Model.Layout.biology_route()
	if "--full" in OS.get_cmdline_user_args():
		route = Model.Layout.routes().platforms
	else:
		fixture(Vector3(5, -449, -138))
		game.model.visited_oxygen.append(25)
		game.model.checkpoint = 25
	if not "--full" in OS.get_cmdline_user_args():
		check(await swim(Vector3(28, -453, -109)), "Swim around the gate's rocky shoulder")
		check(await swim(Vector3(38, -453, -114)), "Swim across the sandy seabed to the lip")
		await photo("116-sand-throat", Biology.PATH[1])
	for target in route:
		if target == 26:
			check(await swim(Vector3(25, -449, -109)), "Seabed route rounds the shoulder")
			check(await swim(Vector3(38, -451, -114)), "Converge at the one crevice")
		var arrived := false
		for frame in range(2400):
			var command := Driver.input_for(game.model, target)
			await tick(Vector2(command.x, command.z), command.y)
			if Driver.arrived(game.model, target):
				arrived = true
				break
			if game.model.mode == Model.Mode.RETURNING:
				break
		check(arrived, "Continuous input reaches %d at %s" % [target, game.model.position])
		if not arrived:
			for body in game.motion.contact_bodies:
				print("Blocked by ", body.get_path())
			break
		if target == 28:
			await photo("117-dark-throat", Biology.GLOBES[3])
		if target == 32:
			await photo("118-first-octopus", Biology.OCTOPUS)
	check(game.model.mode == Model.Mode.COMPLETE, "Reach the encounter prologue end")
	check(game.get_instance_id() == scene_id, "No scene or loading transition")
	check(game.model.setbacks == 0, "The connected prologue does not require a rescue")
	print("Continuous journey seconds: ", snappedf(game.model.elapsed, .01))
	if not gpu:
		await audit_contacts()
	game.queue_free()
	await process_frame
	print("Biology: %d checks, failed=%s" % [checks, failed])
	quit(1 if failed else 0)


func audit_contacts() -> void:
	# Drive the actual swept capsule into the sand and both sides of the throat.
	for entry in [
		[Vector3(15, -452, -110), Vector2.ZERO, 0.0, false, "SandFloor"],
		[Vector3(15, -452, -110), Vector2.ZERO, 1.0, false, "SandFloor"],
		[Vector3(38, -482, -133), Vector2.RIGHT, 0.0, false, "NarrowThroat"],
		[Vector3(38, -482, -133), Vector2.LEFT, 0.0, true, "NarrowThroat"],
		[Vector3(49, -640, -210), Vector2.RIGHT, 0.0, false, "GiantOctopus"]
	]:
		fixture(entry[0])
		var touched := false
		for frame in range(100):
			await tick(entry[1], entry[2], entry[3])
			for body in game.motion.contact_bodies:
				if str(body.get_path()).contains(entry[4]):
					touched = true
			if touched:
				break
		check(touched, "Swept capsule contacts " + entry[4])
	fixture(Vector3(43, -518, -123))
	game.model.visited_oxygen.append(26)
	game.model.oxygen = .001
	await tick()
	check(game.model.mode == Model.Mode.RETURNING, "Oxygen depletion starts seamless rescue")
	for frame in range(600):
		await tick()
		if game.model.mode == Model.Mode.DIVING:
			break
	check(game.model.depth < 480, "Rescue loses depth to the visited water globe")
	check(game.model.grounded == -1, "Water-globe rescue never creates an invisible ledge")
	check(game.model.mode == Model.Mode.DIVING, "Rescue restores control in the same world")
