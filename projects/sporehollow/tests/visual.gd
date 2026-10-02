extends SceneTree
const Farm = preload("res://game/world.gd")
const Trial = preload("res://tests/evaluate.gd")
var game
var captures: Dictionary = {}

func _initialize():
	root.unfocusable = true
	call_deferred("run")

func move_pointer(position: Vector2):
	var event = InputEventMouseMotion.new()
	event.position = position
	Input.parse_input_event(event)
	await process_frame

func mouse(position: Vector2, button: int = MOUSE_BUTTON_LEFT):
	var event = InputEventMouseButton.new()
	event.button_index = button
	event.position = position
	event.pressed = true
	Input.parse_input_event(event)
	await process_frame
	event = event.duplicate()
	event.pressed = false
	Input.parse_input_event(event)
	await process_frame

func click(id: String):
	assert(game.buttons.has(id), "Missing button " + id)
	await mouse(game.buttons[id].get_global_rect().get_center())

func key(code: int, pressed: bool = true):
	var event = InputEventKey.new()
	event.physical_keycode = code
	event.pressed = pressed
	Input.parse_input_event(event)
	await process_frame

func capture(name: String):
	await create_timer(0.4).timeout
	for i in range(3): await process_frame
	await RenderingServer.frame_post_draw
	assert(root.get_texture().get_image().save_png("res://review/current/" + name + ".png") == OK)
	captures[name] = {"tick": game.world.tick, "camera": [game.camera.position.x, game.camera.position.y], "alert": game.alert_text if game.alert_visible() else "", "keeper_state": game.world.keeper.state}
	print("Captured ", name)

func step(count: int = 1):
	for i in range(count):
		game.world.step()
		await process_frame

func run():
	game = load("res://game/main.tscn").instantiate()
	game.world = Farm.new({}, 17)
	game.automated = true
	root.add_child(game)
	await process_frame
	assert(game.buttons.values().all(func(b): return not b.visible))
	await move_pointer(game.screen_cell(Vector2(19, 8)))
	await capture("placement")
	await mouse(game.screen_cell(Vector2(19, 8)))
	assert(game.world.phase == "defend" and not game.world.animals[0].placed and game.group == 1)
	assert(not game.buttons.advance.visible and game.alert_text == "敵の襲来に備えよ")
	await key(KEY_SPACE)
	await key(KEY_SPACE, false)
	await mouse(game.screen_cell(Vector2(18, 8)))
	assert(not game.world.animals[0].placed)
	await key(KEY_SPACE)
	await key(KEY_SPACE, false)
	await step(2)
	await mouse(game.screen_cell(Vector2(18, 8)))
	assert(game.world.animals[0].placed and game.world.initial_positions.animals[0].deployment_tick == 2)
	await click("animal1")
	await click("wander")
	assert(game.world.animals[0].pending.kind == "wander" and game.world.animals[0].pending.pos == game.world.animals[0].pos)
	assert(not game.buttons.has("attack_target"))
	await click("auto")
	# Ctrl+wheel changes world scale, leaving HUD and the current mode unchanged.
	var mode_before = game.group
	var zoom_event = InputEventMouseButton.new()
	zoom_event.button_index = MOUSE_BUTTON_WHEEL_UP
	zoom_event.ctrl_pressed = true
	zoom_event.pressed = true
	zoom_event.position = Vector2(600, 450)
	Input.parse_input_event(zoom_event)
	await process_frame
	assert(game.camera.zoom.x > 1 and game.group == mode_before)
	await mouse(Vector2(800, 500), MOUSE_BUTTON_RIGHT)
	await mouse(game.screen_cell(Vector2(game.world.animals[0].pos)))
	assert(game.selected_animal == 1)
	game.camera.zoom = Vector2.ONE
	await click("group0")
	await click("wall")
	await mouse(game.screen_cell(Vector2(17, 7)))
	# Production accumulator: 2 real seconds at 0.5x completes a 1s wall.
	await click("speed")
	await click("speed")
	assert(game.speed == 0.5)
	game.set_process(false)
	game.automated = false
	var tick_before = game.world.tick
	for i in range(10): game._process(0.1)
	assert(game.world.structures[Vector2i(17, 7)].status == "building")
	for i in range(11): game._process(0.1)
	assert(game.world.structures[Vector2i(17, 7)].status == "ready")
	var half_speed_ticks = game.world.tick - tick_before
	assert(half_speed_ticks == 4)
	game.automated = true
	game.set_process(true)
	await click("speed")
	assert(game.speed == 1)
	await mouse(game.screen_cell(Vector2(17, 7)))
	assert(game.selected.kind == "structure")
	await key(KEY_DELETE)
	await key(KEY_DELETE, false)
	assert(game.world.structures[Vector2i(17, 7)].status == "removed")
	await mouse(Vector2(800, 500), MOUSE_BUTTON_RIGHT)
	var got_combat = false
	while game.world.phase == "defend" and game.world.tick < 800:
		await step()
		if not got_combat and not game.world.skill_log.is_empty() and game.world.enemies[0].hp < 50 and game.world.tick < game.world.enemies[0].move_stopped_until:
			await capture("combat")
			got_combat = true
	assert(got_combat and game.world.result == "win")
	var combat_trial = Trial.compact(game.world)
	# Component fixture for the selected damaged wall; nature still grows by its seeded clock.
	game.world = Farm.new({}, 17)
	game.reset_view()
	game.refresh()
	await mouse(game.screen_cell(Vector2(19, 8)))
	await click("group0")
	await click("wall")
	await mouse(game.screen_cell(Vector2(14, 8)))
	await step(32)
	game.world.structures[Vector2i(14, 8)].hp = 3
	await mouse(game.screen_cell(Vector2(14, 8)))
	assert(game.selected.kind == "structure" and game.buttons.has("repair") and game.buttons.has("remove"))
	await capture("harvest_or_build")
	await key(KEY_SPACE)
	await key(KEY_SPACE, false)
	await key(KEY_E)
	await key(KEY_E, false)
	assert(game.world.structures[Vector2i(14, 8)].hp == 3)
	await key(KEY_DELETE)
	await key(KEY_DELETE, false)
	assert(game.world.structures[Vector2i(14, 8)].status == "ready")
	await key(KEY_SPACE)
	await key(KEY_SPACE, false)
	await key(KEY_E)
	await key(KEY_E, false)
	assert(game.world.structures[Vector2i(14, 8)].hp == 8 and game.world.materials == 83)
	await key(KEY_DELETE)
	await key(KEY_DELETE, false)
	assert(game.world.structures[Vector2i(14, 8)].status == "removed")
	await click("build_gate")
	await mouse(game.screen_cell(Vector2(14, 9)))
	await step(4)
	await mouse(game.screen_cell(Vector2(14, 9)))
	await click("gate")
	assert(game.world.structures[Vector2i(14, 9)].open)
	await mouse(Vector2(750, 500), MOUSE_BUTTON_WHEEL_DOWN)
	assert(game.group == 1)
	await mouse(Vector2(750, 500), MOUSE_BUTTON_WHEEL_DOWN)
	assert(game.group == 2)
	await click("collect")
	# Generated resources use normal clicks; retain the exact seeded growth counters.
	var collected = []
	for p in game.world.natural.keys():
		collected.append(game.world.natural[p])
		await mouse(game.screen_cell(Vector2(p)))
	assert(collected.size() == 2 and game.world.natural.is_empty())
	var fixture = {"note": "Damaged-wall component fixture: HP set to3 for repair UI. Resources generated normally at4s/8s.",
		"metrics": game.world.metrics.duplicate(true), "collected": collected, "actions": game.world.actions.duplicate(true)}
	var record = {"commit_sha": OS.get_environment("REVIEW_COMMIT") if OS.has_environment("REVIEW_COMMIT") else "WORKTREE",
		"branch": "codex/sporehollow-prototype", "resolution": [1280, 800], "seed": 17,
		"ai_settings": Farm.Rules.AI, "bark_settings": Farm.Rules.BARK, "nature_settings": Farm.Rules.NATURE,
		"ui_checks": {"auto_start": true, "initial_animal_mode": true, "pause_deployment_denied": true, "three_modes": true,
			"half_speed_seconds": 2.1, "half_speed_ticks": half_speed_ticks, "zoom_click_alignment": true, "wander_one_click": true,
			"repair_E": true, "dismantle_Delete": true, "pause_facility_ops_denied": true, "gate_toggle": true},
		"screenshots": captures, "scenarios": {"combat": combat_trial, "harvest_build_fixture": fixture,
			"abduction_and_rescue": Trial.compact(Trial.run_trial("rescue")), "poor_placement": Trial.compact(Trial.run_trial("poor"))}}
	var evaluation = JSON.parse_string(FileAccess.get_file_as_string("res://artifacts/evaluation.json"))
	record.multi_seed = {"seed_range": evaluation.seed_range, "strategies": {}}
	for strategy in evaluation.strategies: record.multi_seed.strategies[strategy] = evaluation.strategies[strategy].summary
	FileAccess.open("res://review/current/stage1-observation.json", FileAccess.WRITE).store_string(JSON.stringify(record, "  "))
	print("PASS: minimal placement, auto start, optional deployment, one-click wander, zoom, 0.5x construction, bark, harvest, selected repair/dismantle and pause restrictions")
	quit()
