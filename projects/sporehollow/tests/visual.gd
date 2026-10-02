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
	assert(game.world.phase == "shop" and game.buttons.advance.visible)
	await capture("shop")
	await click("trade_hen_-1")
	assert(game.world.campaign.animals.size() == 2 and game.world.campaign.gold == 11)
	await click("shop_train")
	await click("name_1")
	game.name_edit.text = "こむぎ"
	await click("save_name")
	assert(game.world.campaign.animals[0].name == "こむぎ")
	await click("advance")
	assert(game.world.phase == "prepare")
	await mouse(game.screen_cell(Vector2(19, 8)))
	assert(game.group == 1 and game.tool == "" and game.selected_animals.is_empty())
	await mouse(game.screen_cell(Vector2(18, 8)))
	assert(not game.world.animals[0].placed)
	await key(KEY_TAB)
	await key(KEY_TAB, false)
	assert(game.selected_animal == 1 and game.tool == "place_animal")
	await key(KEY_TAB)
	await key(KEY_TAB, false)
	assert(game.selected_animal == 2)
	await key(KEY_TAB)
	await key(KEY_TAB, false)
	assert(game.tool == "" and game.selected_animal == -1)
	await key(KEY_TAB, true, true)
	await key(KEY_TAB, false, true)
	assert(game.selected_animal == 2)
	await mouse(game.screen_cell(Vector2(20, 12)))
	await click("animal1")
	await mouse(game.screen_cell(Vector2(18, 8)))
	await click("group0")
	assert(not game.buttons.has("kennel"))
	await click("wall")
	await mouse(game.screen_cell(Vector2(14, 10)))
	await step(4)
	assert(game.world.structures[Vector2i(14, 10)].status == "ready")
	await key(KEY_KP_SUBTRACT)
	await key(KEY_KP_SUBTRACT, false)
	assert(game.speed == 0.5)
	await key(KEY_KP_ADD)
	await key(KEY_KP_ADD, false)
	assert(game.speed == 1.0)
	await key(KEY_KP_ADD)
	await key(KEY_KP_ADD, false)
	assert(game.speed == 2.0)
	await key(KEY_SPACE)
	await key(KEY_SPACE, false)
	var paused_tick = game.world.tick
	await step(8)
	assert(game.world.tick == paused_tick)
	await key(KEY_SPACE)
	await key(KEY_SPACE, false)
	var combat = false
	while not game.world.early_clear and game.world.phase == "defend" and game.world.tick < 720:
		await step()
		if not combat and game.world.combat_log.any(func(hit): return hit.source == "animal"):
			await capture("combat")
			combat = true
	assert(combat and game.world.early_clear and game.world.phase == "defend")
	await step(12) # Let the repelled raider move away from the ground drop.
	var plan = game.world.field_items.filter(func(item): return item.kind == "kennel_plan")[0].pos
	assert("kennel" not in game.world.campaign.unlocked_blueprints)
	await mouse(game.screen_cell(Vector2(plan)))
	await capture("blueprint")
	await mouse(game.screen_cell(Vector2(plan)))
	assert("kennel" in game.world.campaign.unlocked_blueprints)
	await click("group0")
	assert(game.buttons.has("kennel"))
	await step(40) # Deliberately choose ten extra seconds of ranch work.
	var before_finish = compact_observation()
	await click("advance")
	assert(game.world.phase == "dawn" and game.world.early_finish_bonus > 0)
	await capture("dawn")
	var dawn = compact_observation()
	assert(game.world.dawn_summary.eggs == 1 and game.world.campaign.animals[0].lv == 1)
	await click("advance")
	assert(game.world.phase == "shop" and game.world.campaign.day == 2 and game.world.stage == 1)
	await click("shop_train")
	await click("train_1")
	assert(game.world.campaign.animals[0].lv == 2)
	var trained = game.world.campaign.duplicate(true)
	await click("advance")
	await mouse(game.screen_cell(Vector2(19, 8)))
	await click("group0")
	await click("wall")
	await mouse(game.screen_cell(Vector2(12, 10)))
	await key(KEY_ESCAPE)
	await key(KEY_ESCAPE, false)
	await click("menu_retry")
	assert(game.world.phase == "prepare" and game.world.campaign.animals[0].lv == 2 and game.world.materials == trained.resources.soil)
	var record = {"commit_sha": OS.get_environment("REVIEW_COMMIT") if OS.has_environment("REVIEW_COMMIT") else "WORKTREE",
		"branch": "codex/sporehollow-prototype", "seed": 17, "screenshots": captures,
		"before_early_finish": before_finish, "dawn": dawn,
		"checks": {"starts_shopping": true, "tab_candidates_and_none": true, "reverse_tab": true, "speed_keys": true,
			"no_accidental_deployment": true, "manual_blueprint": true, "work_after_clear": true,
			"named_animal": true, "manual_exp_training": true, "stage1_reused": true, "night_checkpoint_retry": true}}
	var file = FileAccess.open("res://review/current/stage1-observation.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(record, "	"))
	file.close()
	print("PASS: first-day shop, named animals, Tab deployment, speed, night, dropped blueprint, continued work, dawn eggs, pooled training and checkpoint")
	quit()
func compact_observation() -> Dictionary:
	var full = game.world.observation()
	var result = {}
	for id in ["seed", "stage", "day", "tick", "phase", "remaining_night", "early_clear", "early_clear_tick", "early_finish_bonus", "exp_pool", "dawn", "field_items", "score", "resources", "metrics", "milestones", "combat", "ai_settings", "decision_counts"]:
		result[id] = full[id]
	result.decision_log = full.decision_log.slice(-12)
	result.decision_log_note = "Last12 decisions; counts cover the night. Full trace remains available through F8."
	result.animals = []
	for a in full.animals:
		var item = {}
		for key in ["id", "species", "name", "lv", "hp", "max_hp", "state", "placed", "affinity", "unavailable_through_day", "rescuing"]:
			item[key] = a[key]
		result.animals.append(item)
	result.unlocked_blueprints = full.campaign.unlocked_blueprints
	result.unavailable_next_day = full.campaign.animals.filter(func(a): return a.unavailable_through_day >= full.day + 1).map(func(a): return a.id)
	return result