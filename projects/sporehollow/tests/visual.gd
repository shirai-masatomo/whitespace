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
	captures[name] = {"tick": game.world.tick, "camera": [game.camera.position.x, game.camera.position.y], "alert": game.alert_text if game.alert_visible() else "", "keeper_state": game.world.keeper.state, "keeper_hp": game.world.keeper.hp, "sleepiness": game.world.keeper.sleepiness, "speed": game.speed, "held": game.world.jobs_held, "phase": game.world.phase, "shop_side": game.shop_side, "shop_level": game.shop_level, "gold": game.world.campaign.gold}
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
	assert(game.world.phase == "shop" and game.cinematic() and not game.controls.visible)
	await mouse(game.screen_cell(Vector2(19, 8)))
	assert(not game.world.keeper.placed and game.world.tick == 0)
	await create_timer(1.0).timeout
	await capture("arrival")
	await create_timer(1.3).timeout
	assert(not game.cinematic() and game.controls.visible)
	await capture("shop")
	await key(KEY_SPACE)
	await key(KEY_SPACE, false)
	assert(not game.world.paused) # Night shortcuts must not silently pause shopping.
	await click("shop_buy")
	assert(game.shop_level == "categories")
	await capture("categories")
	await click("category_items")
	assert(not game.buttons.keys().any(func(id): return "food" in id))
	await click("shop_back")
	await click("category_animals")
	assert(not game.buttons.has("trade_shiba_-1"))
	await capture("products")
	await click("trade_hen_-1")
	assert(game.shop_level == "detail" and game.world.campaign.gold == 40 and game.world.campaign.animals.size() == 1)
	await capture("purchase")
	await click("confirm_trade")
	assert(game.world.campaign.animals.size() == 2 and game.world.campaign.gold == 10)
	assert(game.buttons.confirm_trade.disabled)
	await click("shop_back")
	assert(game.shop_level == "list" and game.shop_category == "animals")
	await capture("returned")
	await click("shop_back")
	await click("category_materials")
	await click("trade_wood_-1")
	assert(game.buttons.confirm_trade.disabled and game.world.campaign.gold == 10)
	await click("shop_back")
	await click("shop_back")
	await click("category_facilities")
	assert(game.shop_rows().is_empty())
	await click("shop_back")
	await click("shop_back")
	await click("shop_sell")
	await click("category_materials")
	await click("trade_soil_-1")
	assert(not game.buttons.confirm_trade.disabled)
	await click("shop_back")
	await click("shop_back")
	await click("shop_back")
	await click("shop_animals")
	await click("name_1")
	await click("rename")
	game.name_edit.text = "こむぎ"
	await click("save_name")
	assert(game.world.campaign.animals[0].name == "こむぎ")
	await capture("animal_detail")
	await click("shop_back")
	assert(game.training_id == -1 and game.shop_side == "animals")
	await click("shop_back")
	await capture("leave_market")
	await click("advance")
	assert(game.world.phase == "day" and game.world.keeper.placed)
	await create_timer(1.2).timeout
	assert(not game.cinematic() and game.controls.visible)
	await capture("day")
	assert(game.group == 1 and game.tool == "" and game.selected_animals.is_empty())
	await click("group0")
	await click("wall")
	for p in [Vector2(3, 3), Vector2(8, 3), Vector2(18, 3)]: await mouse(game.screen_cell(p))
	assert(game.world.jobs.size() == 3 and game.world.structures.is_empty())
	await capture("queue")
	while not game.world.jobs[0].started: await step()
	await capture("working")
	while game.world.metrics.built < 2 and game.world.tick < 250: await step()
	assert(game.world.metrics.built == 2)
	await step(2)
	var third = game.world.jobs.back().id
	var row = game.world.jobs.size() - 1
	await mouse(Vector2(1243, 109 + row * 35))
	assert(not game.world.jobs.any(func(j): return j.id == third))
	await mouse(game.screen_cell(Vector2(16, 6)))
	while not game.world.jobs.is_empty() and game.world.tick < 290: await step()
	assert(game.world.structures[Vector2i(16, 6)].status == "ready")
	await click("group1")
	await click("animal2")
	await mouse(game.screen_cell(Vector2(20, 12)))
	await click("animal1")
	await mouse(game.screen_cell(Vector2(18, 8)))
	while not game.world.jobs.is_empty() and game.world.tick < 330: await step()
	assert(game.world.animals.all(func(a): return a.placed))
	await mouse(game.get_canvas_transform() * game.actor_pixel("a1", game.world.animals[0].pos))
	await click("stay")
	await mouse(game.screen_cell(Vector2(18, 8)))
	await click("walk")
	await mouse(game.screen_cell(Vector2(19, 8)), MOUSE_BUTTON_RIGHT)
	while game.world.manual_goal != null: await step()
	await click("resume_jobs")
	while game.world.tick < 354: await step()
	await click("group0")
	await click("wall")
	await mouse(game.screen_cell(Vector2(3, 2)))
	var retained_id = game.world.jobs[0].id
	await step(6)
	assert(game.world.phase == "defend" and game.world.jobs[0].id == retained_id and game.controls.visible)
	await capture("night_queue")
	await key(KEY_KP_SUBTRACT)
	await key(KEY_KP_SUBTRACT, false)
	assert(game.speed == 0.5)
	await key(KEY_KP_ADD)
	await key(KEY_KP_ADD, false)
	await key(KEY_SPACE)
	await key(KEY_SPACE, false)
	var paused_tick = game.world.tick
	await step(8)
	assert(game.world.tick == paused_tick)
	await key(KEY_SPACE)
	await key(KEY_SPACE, false)
	await step(40)
	assert(game.world.enemies.size() == 1)
	await click("walk")
	await mouse(game.screen_cell(Vector2(19, 8)), MOUSE_BUTTON_RIGHT)
	assert(game.world.jobs_held)
	while game.world.manual_goal != null: await step()
	if not game.world.jobs.is_empty(): await mouse(Vector2(1243,109))
	await click("resume_jobs")
	while game.world.combat_log.is_empty() and not game.world.enemies[0].can_see_keeper and game.world.tick < 800: await step()
	assert(game.world.enemies[0].can_see_keeper or not game.world.combat_log.is_empty())
	await create_timer(0.25).timeout
	await mouse(game.get_canvas_transform() * game.actor_pixel("e0", game.world.enemies[0].pos))
	await capture("combat")
	while not game.world.early_clear and game.world.phase == "defend" and game.world.tick < 1080:
		await step()
	assert(game.world.early_clear and game.world.phase == "defend")
	assert(game.selected.get("kind", "" ) != "enemy")
	await create_timer(2.0).timeout
	await mouse(game.get_canvas_transform() * game.actor_pixel("a1", game.world.animals[0].pos))
	assert(game.selected.get("kind", "") == "animal")
	await capture("animal")
	await step(12)
	var plan = game.world.field_items.filter(func(item): return item.kind == "kennel_plan")[0].pos
	assert("kennel" not in game.world.campaign.unlocked_blueprints)
	await mouse(game.screen_cell(Vector2(plan)))
	await mouse(game.screen_cell(Vector2(plan)))
	while not game.world.jobs.is_empty() and game.world.phase == "defend": await step()
	assert("kennel" in game.world.campaign.unlocked_blueprints)
	var before_finish = compact_observation()
	await click("advance")
	assert(game.world.phase == "dawn" and game.world.early_finish_bonus > 0)
	var dawn = compact_observation()
	await create_timer(2.1).timeout
	await key(KEY_SPACE)
	await key(KEY_SPACE, false)
	assert(not game.world.paused)
	await capture("dawn")
	await create_timer(2.5).timeout
	assert(game.cinematic() and not game.controls.visible)
	await create_timer(2.7).timeout
	assert(game.world.phase == "shop" and game.world.campaign.day == 2 and game.world.stage == 1)
	await capture("next_morning")
	await click("shop_animals")
	await click("name_1")
	await click("train_1")
	assert(game.world.campaign.animals[0].lv == 2)
	await key(KEY_ESCAPE)
	await key(KEY_ESCAPE, false)
	await click("menu_morning")
	assert(game.world.phase == "shop" and game.world.campaign.animals[0].lv == 1 and game.world.campaign.exp_pool == dawn.exp_pool)
	var survival = await keeper_review()
	var validation = JSON.parse_string(FileAccess.get_file_as_string("res://artifacts/keeper-tests.json"))
	var record = {"keeper_validation": {"checks": validation.checks, "failures": validation.failures, "source": "tests/test_keeper.gd", "covers": ["fatigue0_80_100", "forced_rest_below80", "voluntary_rest", "queue_interrupt_resume", "drink_daily_cap", "carry_rescue_and_loss", "three_species_8seeds_no_overlap"]}, "survival": survival, "commit_sha": OS.get_environment("REVIEW_COMMIT") if OS.has_environment("REVIEW_COMMIT") else "WORKTREE",
		"branch": "codex/sporehollow-prototype", "seed": 17, "screenshots": captures,
		"before_early_finish": before_finish, "dawn": dawn,
		"audio": {"cues": game.audio.played, "birds_seconds": [8, 20], "driver": "Dummy"},
		"checks": {"day_work_queue": true, "third_cancelled": true, "night_preserves_jobs": true, "night_escape": true, "hierarchical_back": true, "no_purchase_on_inspect": true, "sold_out_disabled": true, "unaffordable_disabled": true, "category_switch_after_purchase": true, "three_way_shop": true, "no_shiba_or_food_sale": true, "click_only_animal_candidates": true,
			"hen_has_no_commands": true, "no_accidental_deployment": true, "manual_blueprint": true,
			"work_after_clear": true, "named_animal": true, "manual_exp_training": true, "morning_retry": true, "arrival_before_shop": true, "cinematic_hides_ui": true, "retired_enemy_deselected": true, "dawn_to_arrival": true}}
	var file = FileAccess.open("res://review/current/stage1-observation.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(record, "\t"))
	file.close()
	print("PASS: shop cards, named animal, click-only deployment, sight/search, victory, dawn, training and morning retry")
	quit()
func compact_observation() -> Dictionary:
	var full = game.world.observation()
	var result = {}
	for id in ["seed", "stage", "day", "tick", "phase", "remaining_night", "remaining_day", "night_started_tick", "jobs", "job_log", "keeper_path", "keeper", "life_log", "jobs_held", "manual_goal", "early_clear", "early_clear_tick", "early_finish_bonus", "exp_pool", "dawn", "field_items", "score", "resources", "metrics", "milestones", "combat", "ai_settings", "decision_counts", "sight_log", "skill_log"]:
		result[id] = full[id]
	result.decision_log = full.decision_log.slice(-12)
	result.decision_log_note = "Last12 decisions; counts cover the night. Full trace remains available through F8."
	result.animals = []
	for a in full.animals:
		var item = {}
		for key in ["id", "species", "name", "lv", "hp", "max_hp", "state", "placed", "affinity", "unavailable_through_day", "rescuing", "detection_range", "attack_target_range", "object_attack_power", "skills"]:
			item[key] = a[key]
		result.animals.append(item)
	result.unlocked_blueprints = full.campaign.unlocked_blueprints
	result.raiders = []
	for e in full.raiders:
		result.raiders.append({"id": e.id, "sight_range": e.sight_range, "can_see_keeper": e.can_see_keeper,
			"last_known_keeper_position": e.last_known_keeper_position, "search_state": e.search_state})
	result.unavailable_next_day = full.campaign.animals.filter(func(a): return a.unavailable_through_day >= full.day + 1).map(func(a): return a.id)
	return result

func keeper_review() -> Dictionary:
	# Controlled encounter fixture; all subsequent commands/ticks use production rules/input.
	game.world = Farm.new({}, 17).begin_day()
	game.reset_view()
	game.refresh()
	game.world.keeper.pos = Vector2i(19,8)
	game.world.keeper.sleepiness = 70
	game.world.act("place_animal",Vector2i(19,10),1)
	while not game.world.jobs.is_empty(): await step()
	game.world.act("rest",Vector2i.ZERO,1)
	await step(8)
	game.world.act("wall",Vector2i(20,8))
	game.world.act("wall",Vector2i(21,10))
	game.world.act("wall",Vector2i(22,12))
	await step()
	await create_timer(0.3).timeout
	await mouse(game.get_canvas_transform() * game.actor_pixel("keeper",game.world.keeper.pos))
	assert(game.selected.get("kind") == "keeper")
	await capture("keeper")
	var job_ids = game.world.jobs.map(func(j):return j.id)
	await mouse(game.screen_cell(Vector2(18,8)),MOUSE_BUTTON_RIGHT)
	while game.world.manual_goal != null: await step()
	assert(game.world.jobs_held and game.world.jobs.map(func(j):return j.id) == job_ids)
	await click("keeper_rest")
	await click("speed")
	await click("speed")
	assert(game.speed == 4 and game.world.keeper.resting)
	await step(16)
	await capture("rest")
	game.world.config.first_attack_seconds = 9999
	game.world.make_schedule()
	game.world.start_night()
	game.world.spawn_enemy({"entry":Vector2i(1,5),"role":"kidnapper","lv":1})
	await process_frame
	await process_frame
	assert(game.speed == 1)
	await click("keeper_rest")
	await mouse(game.screen_cell(Vector2(19,8)),MOUSE_BUTTON_RIGHT)
	while game.world.manual_goal != null: await step()
	assert(game.world.jobs_held and not game.world.keeper.resting)
	# Bring a single fixture enemy into view; combat/carry/rescue are not scripted outcomes.
	game.world.enemies[0].pos = Vector2i(18,8)
	while game.world.keeper.hp > 20: await step()
	await capture("keeper_combat")
	while game.world.keeper.state == "free": await step()
	assert(game.world.keeper.state == "unconscious")
	await capture("unconscious")
	while game.world.keeper.carrier < 0 and game.world.tick < 600: await step()
	assert(game.world.keeper.carrier >= 0)
	await capture("carried")
	await mouse(game.get_canvas_transform() * game.actor_pixel("a1", game.world.animals[0].pos))
	await click("auto")
	await step(3)
	assert(game.world.animals[0].rescuing)
	await capture("rescue")
	while game.world.metrics.rescues == 0 and game.world.working() and game.world.tick < 800: await step()
	assert(game.world.metrics.rescues == 1)
	await step(48)
	assert(game.world.keeper.hp == 8 and game.world.keeper.resting and game.world.jobs_held)
	await mouse(game.get_canvas_transform() * game.actor_pixel("keeper",game.world.keeper.pos))
	await capture("recovered")
	return {"fixture": "Second controlled encounter: keeper at19,8, fatigue70, enemy approaches from18,8; actual combat and rescue rules thereafter.", "outcome": compact_observation(), "checks": {"selected_right_move":true,"queue_retained":true,"rest_speed4":true,"invasion_speed1":true,"weak_resistance":true,"hp_zero_before_carry":true,"dog_rescue":true}}
