extends "res://tests/test_discovery.gd"
## Save/reload edited Nodes, then use real player collision and oxygen logic.


func run() -> void:
	root.unfocusable = true
	var edited: Node3D = load("res://game/levels/l1_editable.tscn").instantiate()
	var rock: Node3D = edited.get_node("RocksAndOxygen/Rock_02_kelp")
	rock.position = Vector3(-180, -80, 70)
	rock.rotation.y = .45
	rock.get_node("OxygenAlgae").position = Vector3(2, 0, 1)
	var garden: Node3D = edited.get_node("OxygenGardens/OxygenGarden0")
	garden.position = Vector3(-150, -65, 70)
	var moving: Node3D = edited.get_node("RocksAndOxygen/Rock_05_buoy")
	moving.position += Vector3(-120, 0, 120)
	moving.rotation.y = PI / 2
	var animal: Node3D = edited.get_node("Animals/Ray_0")
	animal.position += Vector3(-40, 2, 12)
	var animal_transform := animal.transform
	var packed := PackedScene.new()
	check(packed.pack(edited) == OK, "Pack edited level")
	check(ResourceSaver.save(packed, "res://artifacts/edited-level.scn") == OK, "Save edits")
	edited.free()
	game = SCENE.instantiate()
	game.get_node("EditableCoast").free()
	var loaded: Node3D = load("res://artifacts/edited-level.scn").instantiate()
	game.add_child(loaded)
	game.automated_input = true
	root.add_child(game)
	await process_frame
	await physics_frame
	game.set_physics_process(false)
	game.begin()
	rock = loaded.get_node("RocksAndOxygen/Rock_02_kelp")
	var saved := rock.global_transform
	check(game.model.platforms[2].origin == saved.origin, "Gameplay uses saved position")
	fixture(saved.origin + Vector3.UP * 5)
	game.model.velocity.y = -15
	for frame in range(90):
		await tick(Vector2.ZERO, 1)
	check(game.model.grounded == 2, "Fast landing hits the moved, rotated rock")
	check(game.model.position.y > saved.origin.y - 1, "No fall through edited collision")
	var oxygen_point: Vector3 = rock.get_node("OxygenAlgae").global_position
	fixture(oxygen_point)
	game.model.oxygen = 20
	await tick()
	check(game.model.oxygen == 100, "Moved algae refill at saved location")
	fixture(Vector3(-8, -60, -35))
	check(game.model.oxygen_contact() != 2, "Old oxygen location is inactive")
	fixture(Vector3(-150, -65, 70))
	game.model.oxygen = 20
	await tick()
	check(game.model.oxygen == 100, "Independent moved garden refills")
	check(game.model.visited_gardens.has(0), "Moved garden can become a rescue location")
	check(game.model.garden_at(Vector3(27, -30, -31)) == -1, "Old garden no longer refills")
	fixture(Vector3(-180, -60, 70))
	for frame in range(60):
		await tick(Vector2.ZERO, 0, true)
	print("Space ascent in first second: ", game.model.position.y + 60, " m")
	check(game.model.position.y > -55.4, "Space has a modestly stronger ascent")
	game._update_camera()
	var moving_data: Dictionary = game.model.platforms[5]
	var movement: Vector3 = game.world.platforms[5].global_position - moving_data.origin
	check(
		absf(movement.x) < .01 and absf(movement.z) > .1, "Moving rock uses the saved rotated axis"
	)
	check(rock.global_transform.is_equal_approx(saved), "Camera update preserves rock rotation")
	check(
		loaded.get_node("Animals/Ray_0").transform.is_equal_approx(animal_transform),
		"Animal animation preserves its authored anchor"
	)
	game.restart()
	game._update_camera()
	check(game.model.platforms[2].origin == saved.origin, "Restart preserves edited layout")
	check(rock.global_transform.is_equal_approx(saved), "Restart does not reset saved Transform")
	game.queue_free()
	await process_frame
	print("Editor authoring: ", checks, " checks, failed=", failed)
	quit(1 if failed else 0)
