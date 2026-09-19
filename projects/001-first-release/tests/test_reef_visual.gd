extends "res://tests/test_visual.gd"
## Continuous coast and offshore journeys, without scene jumps.


func run() -> void:
	sequence_limit_seconds = 140
	root.unfocusable = true
	capture_root = "res://artifacts/reef-" + RenderingServer.get_current_rendering_method()
	DirAccess.make_dir_recursive_absolute(capture_root + "/sequence")
	DirAccess.make_dir_recursive_absolute("res://artifacts/sequence")
	game = SCENE.instantiate()
	game.automated_input = true
	root.add_child(game)
	await process_frame
	game.set_physics_process(false)
	game.set_process_unhandled_input(false)
	game.begin()
	game.pitch = -.65
	await capture("26-unmarked-sea")
	for target in Model.Layout.routes().cliff_walk:
		if not await steer(target):
			break
		if target == 11:
			await watch_ray()
			await capture("27-ray-and-coast")
			game.yaw = 0
			game.pitch = -.65
		if target == 13:
			await shelf_walk()
			game.pitch = -.35
			await capture("28-cliff-garden")
			game.pitch = -.65
		if target == 14:
			game.pitch = -.22
			game.yaw = -.8
			await capture("29-rock-passage")
			game.yaw = 0
			game.pitch = -.65
		if target == 15:
			game.pitch = -.35
			await capture("30-open-water-again")
			game.pitch = -.65
		if target == 21:
			game.pitch = -.3
			game.yaw = -.5
			await capture("33-deep-rift")
			game.pitch = -.65
			game.yaw = 0
		if target == 25:
			await capture("34-rift-opening")
	if game.model.mode != Model.Mode.COMPLETE:
		failed = true
		push_error("Cliff journey must reach the goal")
	record_sequence = false
	game.restart()
	game.pitch = -.65
	for target in Model.Layout.routes().rift_offshore:
		if not await steer(target, true):
			break
		if target == 17:
			await capture("31-offshore-jelly")
		if target == 16:
			await capture("32-drifting-refuge")
		if target == 24:
			await capture("35-updraft-bypass")
	if game.model.mode != Model.Mode.COMPLETE:
		failed = true
		push_error("Offshore journey must reach the goal")
	var record := FileAccess.open(capture_root + "/sequence/frames.json", FileAccess.WRITE)
	record.store_string(JSON.stringify(sequence, "  "))
	record.close()
	game.queue_free()
	await process_frame
	await create_timer(.1).timeout
	print("Reef GPU: cliff walk and offshore life, failures=%s" % failed)
	quit(1 if failed else 0)


func shelf_walk() -> void:
	var shelf: Vector3 = game.model.platforms[13].position
	for offset_x in [10.0, 0.0]:
		for frame in range(240):
			var target := shelf + Vector3(offset_x, 0, 0)
			var offset := Vector2(
				target.x - game.model.position.x, target.z - game.model.position.z
			)
			game.advance(1.0 / 60, (offset * 1.6 / 7.0).limit_length())
			await render_step()
		if (
			game.model.grounded != 13
			or game.model.position.distance_to(shelf + Vector3(offset_x, 0, 0)) > 1
		):
			failed = true
			push_error("Cliff shelf should be walkable out and back")


func watch_ray() -> void:
	var spotted := false
	for frame in range(480):
		game.advance(1.0 / 60, Vector2.ZERO)
		var ray_point: Vector3 = game.world.life.rays[0].global_position
		var offset: Vector3 = ray_point - game.model.position
		game.pitch = atan2(offset.y - 1.4, Vector2(offset.x, offset.z).length())
		game.yaw = atan2(-offset.x, -offset.z)
		await render_step()
		var sight := PhysicsRayQueryParameters3D.create(game.camera.global_position, ray_point, 1)
		var block: Dictionary = game.get_world_3d().direct_space_state.intersect_ray(sight)
		if not game.camera.is_position_behind(ray_point) and block.is_empty():
			var pixel: Vector2 = game.camera.unproject_position(ray_point)
			if Rect2(200, 120, 750, 480).has_point(pixel):
				spotted = true
				break
	if not spotted:
		failed = true
		push_error("An observant player should see the passing ray from the garden")
