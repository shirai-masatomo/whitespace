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
		assert(game.world.natural.has(p) and game.selected.kind == "resource")
		await mouse(game.screen_cell(Vector2(p)))
	assert(collected.size() == 2 and game.world.natural.is_empty())
	var fixture = {"note": "Damaged-wall component fixture: HP set to3 for repair UI. Resources generated normally at4s/8s.",
		"metrics": game.world.metrics.duplicate(true), "collected": collected, "actions": game.world.actions.duplicate(true)}
	var context_checks = await context_trial()
	var polish_checks = await polish_trial()
	var record = {"polish_checks": polish_checks, "context_checks": context_checks, "rest_settings": Farm.Rules.REST, "commit_sha": OS.get_environment("REVIEW_COMMIT") if OS.has_environment("REVIEW_COMMIT") else "WORKTREE",
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
	print("PASS: Stage1 input, context clicks, two-click harvest, Tab/Shift+Tab, Ctrl/drag selection, queued batch rest, kennel exclusivity and pause restrictions")
	quit()

func context_trial() -> Dictionary:
	var data = Farm.new_campaign()
	var second = data.animals[0].duplicate(true)
	second.id = 2
	data.animals.append(second)
	var config = Farm.StageData.STAGES[1].duplicate(true)
	config.first_attack_seconds = 999.0
	game.world = Farm.new(data, 17, config)
	game.reset_view()
	game.refresh()
	await mouse(game.screen_cell(Vector2(19, 8)))
	await mouse(game.screen_cell(Vector2(12, 8)))
	await click("animal2")
	await mouse(game.screen_cell(Vector2(12, 10)))
	await click("group0")
	await key(KEY_TAB)
	await key(KEY_TAB, false)
	assert(game.tool == "wall")
	await key(KEY_TAB)
	await key(KEY_TAB, false)
	assert(game.tool == "build_gate")
	await key(KEY_TAB)
	await key(KEY_TAB, false)
	assert(game.tool == "kennel")
	await key(KEY_TAB, true, true)
	await key(KEY_TAB, false, true)
	assert(game.tool == "build_gate" and game.speed == 1)
	await click("kennel")
	await mouse(game.screen_cell(Vector2(13, 8)))
	await step(8)
	# Direct animal click wins over the armed construction tool.
	await mouse(game.screen_cell(Vector2(game.world.animals[0].pos)))
	assert(game.group == 1 and game.selected_animals == [1])
	await mouse(game.screen_cell(Vector2(game.world.animals[1].pos)), MOUSE_BUTTON_LEFT, true)
	assert(game.selected_animals == [1, 2])
	await mouse(game.screen_cell(Vector2(game.world.animals[0].pos)), MOUSE_BUTTON_LEFT, true)
	assert(game.selected_animals == [2])
	await mouse(game.screen_cell(Vector2(game.world.animals[0].pos)))
	assert(game.selected_animals == [1])
	# Shift drag selects from rendered world positions; no OS mouse control.
	var drag = InputEventMouseButton.new()
	drag.button_index = MOUSE_BUTTON_LEFT
	drag.shift_pressed = true
	drag.pressed = true
	drag.position = game.screen_cell(Vector2(11, 7))
	Input.parse_input_event(drag)
	await process_frame
	await move_pointer(game.screen_cell(Vector2(14, 11)))
	drag = drag.duplicate()
	drag.pressed = false
	drag.position = game.screen_cell(Vector2(14, 11))
	Input.parse_input_event(drag)
	await process_frame
	assert(game.selected_animals == [1, 2] and not game.dragging)
	await key(KEY_SPACE)
	await key(KEY_SPACE, false)
	for i in range(3):
		await key(KEY_TAB)
		await key(KEY_TAB, false)
	assert(game.tool == "rest" and game.world.animals.all(func(a): return a.pending.is_empty()))
	await mouse(game.screen_cell(Vector2(15, 9)))
	assert(game.world.animals.all(func(a): return a.pending.kind == "rest" and a.mode == "auto"))
	for a in game.world.animals: a.hp = 20
	await key(KEY_SPACE)
	await key(KEY_SPACE, false)
	await step(12)
	assert(game.world.animals.all(func(a): return a.mode == "rest"))
	assert(game.world.animals[0].kennel_id >= 0 and game.world.animals[1].kennel_id == -1)

	# Click the roof outside the dog's hit area to select the occupied house.
	await mouse(game.screen_cell(Vector2(13, 8)) + Vector2(0, -19))
	assert(game.group == 0 and game.selected.kind == "structure")
	var weed = Vector2i(16, 10)
	game.world.natural[weed] = "weed" # Explicit UI component fixture.
	await click("wall")
	var soil = game.world.materials
	await mouse(game.screen_cell(Vector2(weed)))
	assert(game.group == 2 and game.selected.kind == "resource" and game.world.materials == soil and game.world.natural.has(weed))
	await key(KEY_SPACE)
	await key(KEY_SPACE, false)
	await mouse(game.screen_cell(Vector2(weed)))
	assert(game.world.natural.has(weed))
	await key(KEY_TAB)
	await key(KEY_TAB, false)
	assert(game.tool == "collect")
	await key(KEY_SPACE)
	await key(KEY_SPACE, false)
	var gold = game.world.campaign.gold
	await mouse(game.screen_cell(Vector2(weed)))
	assert(not game.world.natural.has(weed) and game.world.campaign.gold == gold + 1)
	return {"direct_animal": true, "direct_facility": true, "direct_harvest_two_clicks": true,
		"pause_harvest_denied": true, "ctrl_toggle": true, "shift_drag": true,
		"tab_selects_without_execution": true, "shift_tab": true, "batch_rest_after_resume": true,
		"one_kennel_one_dog": true, "fixture": "Two owned Shibas and delayed invasion only for multi-selection UI; normal Stage1 still starts with one."}

func polish_trial() -> Dictionary:
	game.world = Farm.new({}, 17)
	game.reset_view()
	game.refresh()
	await mouse(game.screen_cell(Vector2(19, 8)))
	await click("group0")
	await click("wall")
	await mouse(game.screen_cell(Vector2(12, 8)))
	await mouse(game.screen_cell(Vector2(13, 8)))
	await step(4)
	game.world.structures[Vector2i(13, 8)].hp = 4 # Damaged facility UI fixture.
	await step(12) # Start announcement has finished; evaluate the real facility details.
	await mouse(game.screen_cell(Vector2(12, 8)))
	await mouse(game.screen_cell(Vector2(13, 8)), MOUSE_BUTTON_LEFT, true)
	assert(game.selected_structures.size() == 2)
	await move_pointer(Vector2(960, 560))
	await capture("harvest_or_build")
	await key(KEY_SPACE)
	await key(KEY_SPACE, false)
	var soil = game.world.materials
	await key(KEY_DELETE)
	await key(KEY_DELETE, false)
	assert(game.world.materials == soil and game.selected_structures.size() == 2)
	await key(KEY_SPACE)
	await key(KEY_SPACE, false)
	await key(KEY_DELETE)
	await key(KEY_DELETE, false)
	assert(game.world.materials == soil + 12 and game.selected_structures.is_empty())
	await key(KEY_DELETE)
	await key(KEY_DELETE, false)
	assert(game.world.materials == soil + 12)
	# Validate all generated clips, without playing through the user's speakers.
	var clips = {}
	for kind in game.audio.cache:
		var stream = game.audio.cache[kind]
		var peak = 0
		for i in range(0, stream.data.size(), 2): peak = maxi(peak, absi(stream.data.decode_s16(i)))
		assert(peak > 0 and peak < 32767)
		clips[kind] = {"duration": stream.get_length(), "peak": peak}
	assert(game.audio.ambient.playing)
	assert(game.audio.played.has("build") and game.audio.played.has("remove") and game.audio.played.has("collect") and game.audio.played.has("gate") and game.audio.played.has("attack"))
	var count = game.audio.played.get("object", 0)
	game.play_alert("object")
	game.play_alert("object")
	assert(game.audio.played.get("object", 0) <= count + 1)
	return {"batch_delete_refund": 12, "wall_hp": [8, 4], "refund_rate": Farm.Rules.DISMANTLE_REFUND,
		"pause_rejected": true, "no_double_refund": true, "clips": clips,
		"sound_triggers": game.audio.played.duplicate(), "sound_rate_limit": true,
		"audio_note": "Original synthesized clips; Dummy driver, no speaker audition. Two-wall damaged UI fixture."}
