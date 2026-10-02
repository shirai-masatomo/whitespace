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
	assert(not game.world.animals[0].placed)
	await mouse(game.screen_cell(Vector2(19, 8)))
	assert(game.world.keeper.placed and not game.world.animals[0].placed and not game.buttons.advance.disabled and game.group == 2)
	await click("animal1")
	await move_pointer(game.screen_cell(Vector2(18, 8)))
	await capture("placement")
	await mouse(game.screen_cell(Vector2(19, 8)))
	assert(not game.world.animals[0].placed)
	await mouse(game.screen_cell(Vector2(18, 8)))
	assert(not game.world.animals[0].placed)
	await click("advance")
	assert(game.world.phase == "defend" and not game.world.animals[0].placed and game.tool == "place_animal")
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
	assert(game.tool != "place_animal" and not game.world.act("place_animal", Vector2i(6, 6), 1))
	await click("group0")
	await click("wall")
	await mouse(game.screen_cell(Vector2(17, 7)))
	await step(2)
	assert(game.world.structures[Vector2i(17, 7)].status == "building")
	await step(2)
	await click("build_gate")
	await mouse(game.screen_cell(Vector2(19, 10)))
	await step(4)
	await mouse(Vector2(700, 500), MOUSE_BUTTON_WHEEL_DOWN)
	assert(game.group == 1)
	await click("gate")
	await mouse(game.screen_cell(Vector2(19, 10)))
	assert(game.world.structures[Vector2i(19, 10)].open)
	game.buttons.speed.grab_focus()
	var speed_before = game.speed
	await key(KEY_SPACE)
	await key(KEY_SPACE, false)
	assert(game.world.paused and game.speed == speed_before)
	await click("repair")
	await mouse(game.screen_cell(Vector2(17, 7)))
	assert(not game.world.actions.back().accepted and game.world.paused)
	await mouse(Vector2(700, 500), MOUSE_BUTTON_WHEEL_DOWN)
	assert(game.group == 2)
	await click("animal1")
	await click("stay")
	await mouse(game.screen_cell(Vector2(18, 8)))
	assert(game.world.animals[0].pending.kind == "stay")
	await click("auto")
	await key(KEY_SPACE)
	await key(KEY_SPACE, false)
	await mouse(Vector2(700, 500), MOUSE_BUTTON_RIGHT)
	assert(game.group == -1 and game.selected.is_empty())
	var camera_before: Vector2 = game.camera.position
	await key(KEY_D)
	game._process(0.2)
	await key(KEY_D, false)
	assert(game.camera.position.x > camera_before.x)
	# Clicking after camera movement must still select the actual world actor.
	await mouse(game.screen_cell(Vector2(game.world.animals[0].pos)))
	assert(game.selected_animal == 1)
	await click("home")
	await mouse(Vector2(700, 500), MOUSE_BUTTON_RIGHT)
	var got_combat = false
	while game.world.phase == "defend" and game.world.tick < 800:
		await step()
		if not got_combat and not game.world.enemies.is_empty() and game.world.enemies[0].hp <= 30:
			await capture("combat")
			got_combat = true
	assert(got_combat and game.world.result == "win" and game.world.animals[0].hp > 0)
	var combat_trial = Trial.compact(game.world)
	await click("buy_soil")
	var retained = game.world.campaign.facilities.duplicate(true)
	await click("advance")
	assert(game.world.stage == 2 and game.world.campaign.facilities == retained and not game.world.animals[0].placed)
	# A second real trial, different initial dog position and a stay command, produces a rescue.
	game.world = Farm.new()
	game.reset_view()
	game.refresh()
	await mouse(game.screen_cell(Vector2(19, 8)))
	await click("animal1")
	await click("advance")
	await mouse(game.screen_cell(Vector2(19, 13)))
	await click("group2")
	await click("animal1")
	await click("stay")
	await mouse(game.screen_cell(Vector2(19, 13)))
	await mouse(Vector2(700, 500), MOUSE_BUTTON_RIGHT)
	var got_abduction = false
	while game.world.phase == "defend" and game.world.tick < 800:
		await step()
		if not got_abduction and game.world.keeper.carrier >= 0 and game.world.animals[0].rescuing:
			assert(game.alert_kind == "carried")
			await capture("abduction")
			got_abduction = true
	assert(got_abduction and game.world.result == "win" and game.world.metrics.rescues == 1)
	var rescue_trial = Trial.compact(game.world)
	var record = {"commit_sha": OS.get_environment("REVIEW_COMMIT") if OS.has_environment("REVIEW_COMMIT") else "WORKTREE",
		"branch": "codex/sporehollow-prototype", "resolution": [1280, 800],
		"seed": game.world.seed_value, "ai_settings": Farm.Rules.AI,
		"numbers": {"shiba": Farm.Rules.SHIBA, "kidnapper": Farm.Rules.KIDNAPPER, "fixed_tick_seconds": Farm.DT, "actual_shiba_attack_seconds": 1.25},
		"screenshots": captures, "scenarios": {"combat": combat_trial, "abduction_and_rescue": rescue_trial, "poor_placement": Trial.compact(Trial.run_trial("poor"))}}
	var evaluation = JSON.parse_string(FileAccess.get_file_as_string("res://artifacts/evaluation.json"))
	record.multi_seed = {"seed_range": evaluation.seed_range, "strategies": {}}
	for strategy in evaluation.strategies: record.multi_seed.strategies[strategy] = evaluation.strategies[strategy].summary
	FileAccess.open("res://review/current/stage1-observation.json", FileAccess.WRITE).store_string(JSON.stringify(record, "  "))
	# Controlled component fixture: damage/repair, danger, and offscreen warnings; not review-trial data.
	game.world = Farm.new()
	Trial.deploy(game.world)
	game.reset_view()
	game.refresh()
	game.world.act("wall", Vector2i(10, 8))
	await step(4)
	game.world.structures[Vector2i(10, 8)].hp = 3
	await click("group1")
	await click("repair")
	await move_pointer(game.screen_cell(Vector2(10, 8)))
	assert(game.world.repair_quote(Vector2i(10, 8)) == {"hp": 5, "cost": 13})
	await mouse(game.screen_cell(Vector2(10, 8)))
	assert(game.world.structures[Vector2i(10, 8)].hp == 8 and game.world.materials == 67)
	game.world.animals[0].hp = 15
	game.world.spawn_enemy(game.world.spawn_schedule[0])
	game.world.enemies[0].pos = Vector2i(17, 8)
	game.world.enemies[0].counter_target = 1
	game.world.enemies[0].counter_until = 100
	game.world.enemies[0].attacker = 1
	game.world.enemies[0].threat_until = 100
	game.world.enemies[0].ai_context = "under_attack"
	game.world.enemies[0].intent = "counter"
	game.world.enemies[0].next_decision = 100
	game.world.enemy_step(game.world.enemies[0])
	await process_frame
	assert(game.alert_kind == "animal_danger")
	game.camera.position -= Vector2(500, 0)
	for i in range(8): await process_frame
	assert(game.screen_cell(game.world.animals[0].pos).x > 1256)
	await RenderingServer.frame_post_draw
	assert(not root.get_texture().get_image().is_empty())
	root.get_texture().get_image().save_png("res://artifacts/danger-ui.png")
	print("PASS: optional/late deployment, pause preview/no deployment, no reposition, grouped wheel, camera-aware input, repair, danger/edge indicators, seeded combat, abduction/rescue and retained farm")
	quit()
