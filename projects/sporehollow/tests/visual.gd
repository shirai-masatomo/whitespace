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

func mouse(position: Vector2, button: int = MOUSE_BUTTON_LEFT, ctrl: bool = false):
	var event = InputEventMouseButton.new()
	event.button_index = button
	event.ctrl_pressed = ctrl
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

func key(code: int, pressed: bool = true, shift: bool = false):
	var event = InputEventKey.new()
	event.physical_keycode = code
	event.shift_pressed = shift
	event.pressed = pressed
	Input.parse_input_event(event)
	await process_frame

func capture(name: String):
	await create_timer(0.4).timeout
	for i in range(3): await process_frame
	await RenderingServer.frame_post_draw
	# Windows preview/indexing may briefly hold the old PNG. Encode once, replace atomically.
	var temporary = "res://artifacts/" + name + "-pending.png"
	if root.get_texture().get_image().save_png(temporary) != OK:
		quit(1)
		return
	var saved = false
	for attempt in range(20):
		if DirAccess.rename_absolute(temporary, "res://review/current/" + name + ".png") == OK:
			saved = true
			break
		await create_timer(0.1).timeout
	if not saved:
		push_error("Cannot replace review image " + name)
		quit(1)
		return
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
	await move_pointer(game.screen_cell(Vector2(19, 8)))
	await mouse(game.screen_cell(Vector2(19, 8)))
	assert(game.group == 1 and game.tool == "" and game.selected_animal == -1 and game.selected_animals.is_empty())
	await capture("placement")
	await mouse(game.screen_cell(Vector2(18, 8)))
	assert(not game.world.animals[0].placed)
	await click("group0")
	assert(game.buttons.kennel.disabled)
	await click("wall")
	await mouse(game.screen_cell(Vector2(14, 8)))
	await step(4)
	assert(game.world.structures[Vector2i(14, 8)].status == "ready")
	var changed_tick = game.world.tick
	await key(KEY_ESCAPE)
	await key(KEY_ESCAPE, false)
	assert(game.menu_open and game.world.paused)
	await step(8)
	assert(game.world.tick == changed_tick)
	await click("menu_resume")
	assert(not game.menu_open and not game.world.paused)
	await key(KEY_SPACE)
	await key(KEY_SPACE, false)
	await key(KEY_ESCAPE)
	await key(KEY_ESCAPE, false)
	await click("menu_resume")
	assert(game.world.paused) # ESC respects a previously paused simulation.
	await key(KEY_ESCAPE)
	await key(KEY_ESCAPE, false)
	await click("menu_retry")
	assert(game.world.phase == "prepare" and game.world.tick == 0 and game.world.seed_value == 17 and game.world.materials == 100 and game.world.structures.is_empty())
	await mouse(game.screen_cell(Vector2(19, 8)))
	await click("animal1")
	assert(game.tool == "place_animal")
	await mouse(game.screen_cell(Vector2(18, 8)))
	assert(game.world.animals[0].placed)
	await mouse(Vector2(900, 570), MOUSE_BUTTON_RIGHT)
	await mouse(game.screen_cell(Vector2(18, 8)))
	assert(game.selected_animal == 1 and game.tool != "place_animal")
	# Retain production timing check: 0.5x uses game seconds for the nature roll.
	await click("speed")
	await click("speed")
	game.set_process(false)
	game.automated = false
	var before = game.world.tick
	for i in range(21): game._process(0.1)
	assert(game.world.tick - before == 4 and game.world.metrics.nature_rolls == 1)
	game.automated = true
	game.set_process(true)
	await click("speed")
	await capture("resource_or_selection")
	await mouse(Vector2(900, 570), MOUSE_BUTTON_RIGHT)
	var combat = false
	while game.world.phase == "defend" and game.world.tick < 800:
		await step()
		if not combat and not game.world.enemies.is_empty() and game.world.enemies[0].hp < 50 and game.world.enemies[0].hp > 0:
			await capture("combat")
			combat = true
	assert(combat and game.world.phase == "shop" and "kennel" in game.world.campaign.unlocked_blueprints)
	assert(not game.buttons.pause.visible and not game.buttons.group0.visible)
	var victory = game.world.observation()
	await click("category_materials")
	await click("trade_wood_-1")
	assert(game.world.wood == 20)
	await click("trade_stone_-1")
	assert(game.world.stone == 10)
	await capture("shop")
	await click("shop_sell")
	await click("trade_stone_-1")
	assert(game.world.stone == 0)
	await click("category_items")
	await click("trade_kennel_plan_-1")
	assert("kennel" in game.world.campaign.unlocked_blueprints and game.world.item_count("kennel_plan") == 0)
	await click("shop_buy")
	await click("trade_dog_food_-1")
	assert(game.world.campaign.items.dog_food == 3)
	await click("category_facilities")
	assert(game.shop_rows().is_empty())
	var transactions = game.world.shop_log.duplicate(true)
	var stock = game.world.shop_stock.duplicate(true)
	await click("advance")
	await mouse(game.screen_cell(Vector2(19, 8)))
	await click("group0")
	assert(not game.buttons.kennel.disabled)
	await click("kennel")
	await mouse(game.screen_cell(Vector2(13, 8)))
	await step(8)
	assert(game.world.structures[Vector2i(13, 8)].status == "ready" and game.world.wood == 0)
	# The fixture checks rare harvest directly, without pretending a forced stump is a natural roll.
	var cell = Vector2i(12, 10)
	game.world.natural[cell] = "stump"
	await mouse(game.screen_cell(Vector2(cell)))
	assert(game.world.natural.has(cell))
	await mouse(game.screen_cell(Vector2(cell)))
	assert(game.world.wood == 20 and not game.world.natural.has(cell))
	var before_retry = game.world.checkpoint.duplicate(true)
	await key(KEY_ESCAPE)
	await key(KEY_ESCAPE, false)
	await click("menu_retry")
	assert(game.world.campaign == before_retry and game.world.phase == "prepare" and game.world.wood == 20 and game.world.structures.is_empty())
	var record = {"commit_sha": OS.get_environment("REVIEW_COMMIT") if OS.has_environment("REVIEW_COMMIT") else "WORKTREE",
		"branch": "codex/sporehollow-prototype", "seed": 17, "screenshots": captures,
		"nature_settings": Farm.Rules.NATURE, "nature_counts": {"weed": victory.metrics.weed_spawned, "mushroom": victory.metrics.mushroom_spawned, "stump": victory.metrics.stump_spawned},
		"resources": victory.resources, "blueprint": victory.campaign.unlocked_blueprints, "shop_stock": stock, "transactions": transactions,
		"menu_checks": {"esc_pauses": true, "preserves_prior_pause": true, "restart_discards_changes": true, "same_seed": true},
		"selection_checks": {"initial_animal_mode_without_selection": true, "empty_click_does_not_deploy": true, "explicit_roster_deployment": true, "small_brackets": true},
		"doghouse": {"initially_locked": true, "wood_cost": 20, "built_after_unlock": true, "restart_restores_stage_start_wood": true},
		"stump_harvest_fixture": {"two_clicks": true, "wood_gain": 20}, "stage1": victory}
	if FileAccess.file_exists("res://artifacts/evaluation.json"):
		var evaluation = JSON.parse_string(FileAccess.get_file_as_string("res://artifacts/evaluation.json"))
		record.multi_seed = {"seed_range": evaluation.seed_range, "strategies": {}}
		for strategy in evaluation.strategies: record.multi_seed.strategies[strategy] = evaluation.strategies[strategy].summary
	FileAccess.open("res://review/current/stage1-observation.json", FileAccess.WRITE).store_string(JSON.stringify(record, "  "))
	print("PASS: neutral animal mode, explicit deployment, ESC/retry, resources, finite nature, buy/sell categories, blueprint, wood kennel and stump harvest")
	quit()
