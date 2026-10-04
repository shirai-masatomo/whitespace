extends SceneTree
const Farm = preload("res://game/world.gd")
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

func capture(name: String, delay: float=0.4):
	if name in ["context_collection","context_facility"]: return
	await create_timer(delay).timeout
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
	captures[name] = {"tick": game.world.tick, "camera": [game.camera.position.x, game.camera.position.y], "alert": game.alert_text if game.alert_visible() else "", "keeper_state": game.world.keeper.state, "keeper_hp": game.world.keeper.hp, "sleepiness": game.world.keeper.sleepiness, "speed": game.speed, "held": game.world.jobs_held, "phase": game.world.phase, "shop_side": game.shop_side, "shop_level": game.shop_level, "gold": game.world.campaign.gold, "paused":game.world.paused, "resting":game.world.keeper.resting, "rest_elapsed":game.world.keeper.get("rest_elapsed",0), "display_order":game.world.jobs.map(func(j):return {"number":game.world.jobs.find(j)+1,"job_id":j.id,"kind":j.kind,"pos":[j.pos.x,j.pos.y]})}
	print("Captured ", name)

func step(count: int = 1):
	for i in range(count):
		game.world.step()
		await process_frame

func motion_frames(prefix: String, count: int):
	for i in range(count):
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://artifacts/%s-%02d.png" % [prefix,i])
		await create_timer(0.055).timeout

func drag(from: Vector2, to: Vector2, shot: String = ""):
	await move_pointer(from)
	var event = InputEventMouseButton.new()
	event.position = from
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = true
	Input.parse_input_event(event)
	await process_frame
	for i in range(1,9):
		await move_pointer(from.lerp(to,float(i)/8))
		if shot!="":
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("res://artifacts/queue-move-%02d.png" % i)
	if shot != "":
		await capture(shot)
		await motion_frames("queue-lift",4)
	event = event.duplicate()
	event.position = to
	event.pressed = false
	Input.parse_input_event(event)
	await process_frame

func run():
	game=load("res://game/main.tscn").instantiate()
	game.world=Farm.new({},17);game.automated=true
	root.add_child(game)
	await create_timer(3.2).timeout
	assert(game.morning_screen == "morning" and not game.buttons.has("shop_buy"))
	await capture("morning")
	await click("open_market")
	await capture("shop")
	await click("shop_buy")
	await click("category_animals")
	await capture("shop_products")
	await click("trade_hen_-1")
	await capture("shop_detail")
	await click("confirm_trade")
	assert(game.world.campaign.animals.size()==2)
	await click("shop_back")
	assert(game.shop_level=="list")
	await click("shop_back")
	await click("category_materials")
	await click("shop_back")
	await click("shop_back")
	await click("shop_sell")
	await click("category_items")
	await click("close_market")
	assert(game.morning_screen=="morning" and game.world.phase=="shop")
	await click("open_book")
	assert(game.book_motion=="open")
	await motion_frames("book-open",9)
	assert(game.training_id==1)
	await click("book_next")
	await mouse(Vector2(1085,699)) # Repeat during turn is ignored.
	await capture("book_turn",0.07)
	await motion_frames("book-turn",7)
	assert(game.training_id==2)
	await click("book_prev")
	await create_timer(0.35).timeout
	await click("rename")
	await process_frame
	assert(game.name_edit.has_focus())
	game.name_edit.text="こむぎ"
	await key(KEY_SPACE)
	await key(KEY_SPACE,false)
	assert(not game.world.paused)
	await click("save_name")
	assert(game.world.campaign.animals[0].name=="こむぎ")
	await capture("animal")
	await click("close_market")
	assert(game.book_motion=="close")
	await motion_frames("book-close",9)
	assert(game.morning_screen=="morning")
	await click("advance")
	await create_timer(1.0).timeout
	assert(game.world.phase=="day" and game.group==-1 and game.tool=="")
	game.world.nature_config.spawn_chance_per_second=0
	game.world.animals[0].loyalty=100
	await key(KEY_SPACE);await key(KEY_SPACE,false)
	await click("group0")
	await click("wall")
	for cell in [Vector2i(10,10),Vector2i(11,10),Vector2i(12,10)]:await mouse(game.screen_cell(cell))
	assert(game.world.jobs.size()==3 and game.world.tick==0)
	await drag(Vector2(1120,180),Vector2(1120,100),"queue_motion")
	await capture("paused_queue")
	var ids=game.world.jobs.map(func(j):return j.id)
	await mouse(game.screen_cell(game.world.jobs[1].pos));await click("cancel_near")
	assert(game.world.jobs.size()==2 and game.world.manual_goal==null)
	await mouse(game.screen_cell(Vector2i(4,4)),MOUSE_BUTTON_RIGHT)
	assert(game.group==-1)
	await mouse(game.screen_cell(game.world.animals[0].pos))
	assert(game.group==1 and game.buttons.has("guide"))
	await click("guide");await mouse(game.screen_cell(Vector2i(20,8)))
	assert(game.world.jobs.back().kind=="animal_order")
	await capture("instructions")
	await key(KEY_SPACE);await key(KEY_SPACE,false)
	for i in range(400):
		if game.world.jobs.size()==1 and game.world.animals[0].has("guide_job"):break
		await step()
	assert(game.world.animals[0].has("guide_job"))
	await mouse(game.screen_cell(Vector2i(4,4)),MOUSE_BUTTON_RIGHT)
	await step(4)
	await move_pointer(Vector2(1120,110))
	await capture("guidance")
	for frame in range(8):
		await step(2)
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://artifacts/guidance-%02d.png" % frame)
	var guide_id=game.world.jobs[0].id
	await mouse(game.screen_cell(game.world.jobs[0].pos));await click("cancel_near")
	assert(not game.world.animals[0].has("guide_job") and game.world.animals[0].placed)
	# Real F3/debug buttons create only valid residents and grant the owned tool.
	await key(KEY_F3);await key(KEY_F3,false)
	await click("debug_whistle");await click("debug_infinite")
	assert(game.world.item_count("whistle")==1 and game.world.debug_infinite)
	await click("debug_cat")
	assert(game.world.animals.size()==3)
	# Topology fixture is explicitly debug setup; all following operations use actual UI inputs.
	var w=game.world
	for y in range(5,10):
		for x in range(10,15):
			var cell=Vector2i(x,y)
			if x in [10,14] or y in [5,9]:debug_site("wood_wall",cell)
			else:debug_site("wood_tile",cell)
	debug_site("locked_door",Vector2i(10,7))
	w.refresh_indoor()
	game.reset_view();game.refresh();await process_frame
	await capture("indoors")
	await mouse(game.screen_cell(w.keeper.pos))
	await mouse(game.screen_cell(Vector2i(12,7)))
	for i in range(200):
		if w.manual_goal==null:break
		await step()
	assert(w.keeper.pos==Vector2i(12,7))
	w.keeper.sleepiness=70
	await click("keeper_rest");await step(12)
	assert(w.keeper.asleep)
	await capture("indoor_sleep")
	await click("keeper_rest")
	assert(not w.keeper.resting and w.Life.presentation(w)!="sleeping")
	await mouse(game.screen_cell(Vector2i(10,7)))
	await click("debug_lock");await click("debug_lock")
	assert(w.structures[Vector2i(10,7)].lock_hp==0 and w.structures[Vector2i(10,7)].hp==16)
	await capture("broken_lock")
	await click("repair")
	assert(w.jobs.any(func(j):return j.kind=="repair"))
	for i in range(200):
		if w.jobs.is_empty():break
		await step()
	assert(w.structures[Vector2i(10,7)].lock_hp==8)
	await key(KEY_F3);await key(KEY_F3,false)
	assert(not w.debug_enabled)
	# Normal clocks and existing defense continue; no instant phase assignment.
	await mouse(game.screen_cell(w.keeper.pos));await click("advance")
	for i in range(1200):
		if not w.working():break
		w.step()
		if i%8==0:await process_frame
		if w.early_clear and w.rest_skip.is_empty():w.act("end_night")
	assert(w.result=="win")
	await capture("dawn",2.4)
	for i in range(220):
		if game.world.phase=="shop" and not game.cinematic(): break
		await create_timer(0.035).timeout
	assert(game.world.phase=="shop")
	await capture("next_morning")
	var record={"source_commit":OS.get_environment("REVIEW_COMMIT"),"captures":captures,"normal_inputs":{"market_book":true,"pause_queue_reorder_cancel":true,"resident_guidance":true,"right_click_deselect":true},"debug_inputs":{"grant_whistle":true,"add_cat":true,"room_fixture":true,"keeper_left_click_indoor_move":true,"indoor_sleep":true,"lock_damage_and_onsite_repair":true},"final_world":w.observation(),"requirements":JSON.parse_string(FileAccess.get_file_as_string("res://artifacts/residents-observation.json"))}
	FileAccess.open("res://review/current/stage1-observation.json",FileAccess.WRITE).store_string(JSON.stringify(record,"  "))
	print("PASS: actual-input resident instruction, build, market, book, debug, indoor sleep, doors and day flow")
	quit()

func debug_site(kind: String,cell: Vector2i):
	var w=game.world;var d=w.BUILD[kind]
	w.Buildings.layer(w,kind)[cell]={"id":w.next_structure_id,"kind":kind,"hp":d.hp,"max_hp":d.hp,"status":"ready","open":false,"armor":0,"cost":d.cost,"resource":d.get("resource","soil"),"lock_hp":d.get("lock_hp",0),"max_lock_hp":d.get("lock_hp",0)}
	w.next_structure_id+=1
