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

func drag(from: Vector2, to: Vector2):
	await move_pointer(from)
	var event = InputEventMouseButton.new()
	event.position = from
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = true
	Input.parse_input_event(event)
	await process_frame
	for i in range(1,9): await move_pointer(from.lerp(to,float(i)/8))
	event = event.duplicate()
	event.position = to
	event.pressed = false
	Input.parse_input_event(event)
	await process_frame

func run():
	game = load("res://game/main.tscn").instantiate()
	game.world = Farm.new({},17)
	game.automated = true
	root.add_child(game)
	await create_timer(3.2).timeout
	if "--selection-only" in OS.get_cmdline_user_args():
		await focused_selection_checks()
		print("PASS: focused selection/context/fatigue input")
		quit()
		return
	assert(game.morning_screen == "morning" and not game.buttons.has("shop_buy"))
	await click("open_market")
	await capture("shop")
	await click("shop_buy")
	await click("category_animals")
	await click("trade_hen_-1")
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
	assert(game.world.phase=="day")
	# Pause, reserve from real board input, reorder using UI drag, cancel on board.
	await key(KEY_SPACE)
	await key(KEY_SPACE,false)
	var frozen_pos=game.world.keeper.pos
	await click("group0")
	await click("wall")
	for p in [Vector2(10,8),Vector2(11,8),Vector2(12,8)]: await mouse(game.screen_cell(p))
	game.world.natural[Vector2i(9,8)]="stump"
	await mouse(game.screen_cell(Vector2(9,8)))
	await click("group1")
	await click("animal1")
	await mouse(game.screen_cell(Vector2(16,9)))
	assert(game.world.jobs.size()==5 and game.world.tick==0)
	await capture("paused_queue")
	var last=game.world.jobs[4].id
	await drag(Vector2(1120,250),Vector2(1120,100))
	assert(game.world.jobs[0].id==last)
	await mouse(game.screen_cell(Vector2(11,8)),MOUSE_BUTTON_RIGHT)
	assert(game.world.jobs.size()==4 and game.world.manual_goal==null)
	await capture("reordered")
	await click("walk")
	await mouse(game.screen_cell(Vector2(8,12)),MOUSE_BUTTON_RIGHT)
	await capture("destinations")
	await step(12)
	assert(game.world.tick==0 and game.world.keeper.pos==frozen_pos and game.world.wood==0)
	await key(KEY_SPACE)
	await key(KEY_SPACE,false)
	while game.world.manual_goal!=null: await step()
	await click("resume_jobs")
	while game.world.animals[0].deployment!="transporting": await step()
	await step(6)
	await capture("transport")
	while not game.world.jobs.is_empty() and game.world.tick<350: await step()
	assert(game.world.animals[0].placed and game.world.metrics.built==2 and game.world.wood==20)
	var planning=game.world.observation()
	# A mixed rectangle locks to first animal; no click creates an incidental collection.
	game.world.animals[0].pos=Vector2i(10,12)
	game.view_positions.clear()
	game.world.natural[Vector2i(12,12)]="weed"
	await process_frame
	await drag(game.screen_cell(Vector2(10,12)),game.screen_cell(Vector2(13,13)))
	assert(game.selected_animals==[1] and game.selected_resources.is_empty() and game.world.jobs.is_empty())
	await drag(game.screen_cell(Vector2(12,12)),game.screen_cell(Vector2(9,13)))
	assert(not game.selected_resources.is_empty() and game.selected_animals.is_empty() and game.world.jobs.is_empty())
	await click("collect_selection")
	assert(game.world.jobs.size()>=1)
	# Controlled six-item selection with five existing jobs: bounded batch remains visible.
	while not game.world.jobs.is_empty(): await step()
	game.world.natural.clear()
	for x in range(12,18): game.world.natural[Vector2i(x,12)]="weed"
	for x in range(18,23): assert(game.world.act("wall",Vector2i(x,5)))
	await drag(game.screen_cell(Vector2(12,12)),game.screen_cell(Vector2(17.5,13)))
	assert(game.selected_resources.size()==6)
	await click("collect_selection")
	assert(game.world.jobs.size()==8 and game.selected_resources.size()==3)
	for job in game.world.jobs.duplicate(): game.world.act("cancel_job",Vector2i.ZERO,job.id)
	await click("walk")
	game.world.keeper.sleepiness=90 # Controlled fatigue fixture; real rest/move commands follow.
	await capture("tired")
	await click("keeper_rest")
	await step(20)
	assert(game.world.keeper.sleepiness==90)
	await step(4)
	await capture("rest")
	await mouse(game.screen_cell(Vector2(15,12)),MOUSE_BUTTON_RIGHT)
	assert(not game.world.keeper.resting and game.world.keeper.rest_elapsed==0)
	while game.world.manual_goal!=null: await step()
	var rest=game.world.observation()
	# Restore a rested keeper only for the full-night regression; defend/AI remain production.
	game.world.keeper.sleepiness=0
	await click("resume_jobs")
	game.world.act("stay",Vector2i(10,12),1)
	while game.world.phase=="day": await step()
	assert(game.world.phase=="defend")
	while game.world.working() and not game.world.early_clear and game.world.tick<1085: await step()
	if game.world.early_clear: game.world.act("end_night")
	assert(game.world.phase=="dawn")
	await create_timer(5.5).timeout
	assert(game.world.phase=="shop" and game.morning_screen=="morning")
	while game.cinematic(): await process_frame
	await click("open_book")
	await create_timer(0.45).timeout
	await click("train_1")
	assert(game.world.campaign.animals[0].lv==2)
	await click("close_market")
	await create_timer(0.45).timeout
	var next_morning = game.world.observation()
	await focused_selection_checks()
	var record={"source_commit":OS.get_environment("REVIEW_COMMIT"),"captures":captures,"planning":planning,"rest":rest,"next_morning":next_morning,"selection_context_checks":{"drag_cap_all_classes":8,"ctrl_cap_all_classes":8,"batch_reserved":3,"batch_unregistered":5,"ui_priority_disabled_and_release":true,"context_camera_clamp":true,"paused_world_unchanged":true,"right_click_selected_facility":true},"input_checks":{"market_back_close":true,"book_open_turn_close":true,"name_shortcut_guard":true,"paused_planning":true,"queue_drag":true,"board_cancel_no_move":true,"mixed_class_drag":true,"shed_transport":true,"five_second_rest":true,"awake_no_sleep_effect":true,"morning_training":true}}
	var file=FileAccess.open("res://review/current/stage1-observation.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(record,"  "))
	print("PASS: real-input market/book/planning/transport/rest/day-night flow")
	quit()


func selection_fixture(kind: String):
	game.world = Farm.new({},17).begin_day()
	game.world.paused = true
	game.world.natural.clear()
	game.world.field_items.clear()
	game.world.structures.clear()
	var base = game.world.animals[0].duplicate(true)
	game.world.animals.clear()
	for i in range(10):
		var cell = Vector2i(10+i%5,8+i/5)
		if kind == "animal":
			var a=base.duplicate(true)
			a.id=i+1
			a.placed=true
			a.deployment="deployed"
			a.pos=cell
			game.world.animals.append(a)
		elif kind == "resource": game.world.natural[cell]="weed"
		else: game.world.structures[cell]={"id":i+1,"kind":"wall","hp":8,"max_hp":8,"status":"ready","cost":10,"resource":"soil","open":false}
	if kind != "animal": game.world.animals.append(base)
	game.reset_view()
	game.refresh()
	await process_frame

func selection_count(kind: String):
	return game.selected_animals.size() if kind=="animal" else (game.selected_resources.size() if kind=="resource" else game.selected_structures.size())

func focused_selection_checks():
	for kind in ["animal","resource","structure"]:
		await selection_fixture(kind)
		await drag(game.screen_cell(Vector2(9.5,7.5)),game.screen_cell(Vector2(14.5,9.5)))
		assert(selection_count(kind)==8,"Drag cap " + kind)
		var first = game.selected_animals.duplicate() if kind=="animal" else (game.selected_resources.duplicate() if kind=="resource" else game.selected_structures.duplicate())
		await selection_fixture(kind)
		# Reverse storage order must not change geometric encounter selection.
		if kind=="animal": game.world.animals.reverse()
		else:
			var source=game.world.natural if kind=="resource" else game.world.structures
			var keys=source.keys(); keys.reverse()
			var reordered={}
			for cell in keys: reordered[cell]=source[cell]
			if kind=="resource": game.world.natural=reordered
			else: game.world.structures=reordered
		await drag(game.screen_cell(Vector2(9.5,7.5)),game.screen_cell(Vector2(14.5,9.5)))
		var second=game.selected_animals if kind=="animal" else (game.selected_resources if kind=="resource" else game.selected_structures)
		assert(first==second,"Order independent from storage " + kind)
		await selection_fixture(kind)
		for i in range(10): await mouse(game.screen_cell(Vector2(10+i%5,8+i/5)),MOUSE_BUTTON_LEFT,true)
		assert(selection_count(kind)==8,"Ctrl cap " + kind)
		assert(game.world.jobs.is_empty(),"Selection does not create work")
	# Eight selected objects are distinct from the three free work slots.
	await selection_fixture("resource")
	for x in range(18,23): assert(game.world.act("wall",Vector2i(x,5)))
	await drag(game.screen_cell(Vector2(9.5,7.5)),game.screen_cell(Vector2(14.5,9.5)))
	await click("collect_selection")
	assert(game.world.jobs.size()==8 and game.selected_resources.size()==5)
	assert(game.message.contains("3件予約") and game.message.contains("5件未登録"))
	await capture("context_collection")
	await click("collect_selection")
	assert(game.world.jobs.size()==8 and game.selected_resources.size()==5)
	# Local facility buttons, shortcuts and selected-object right click share reservations.
	await selection_fixture("structure")
	var cell=Vector2i(10,8)
	game.world.structures[cell].hp=4
	await mouse(game.screen_cell(cell))
	assert(game.buttons.has("repair") and not game.buttons.repair.disabled)
	var anchor=game.screen_cell(cell)
	assert(game.context_panel.position.distance_to(anchor)<180)
	await capture("context_facility")
	await click("repair")
	await key(KEY_E)
	assert(game.world.jobs.size()==1 and game.world.structures[cell].hp==4)
	assert(game.buttons.repair.disabled)
	var button_point=game.buttons.repair.get_global_rect().get_center()
	# Place a live selectable creature and a cancellable plan behind disabled UI.
	var behind=Vector2i(game.get_canvas_transform().affine_inverse()*button_point/game.TILE)
	game.world.natural[behind]="mushroom"
	assert(game.world.act("collect",behind))
	await process_frame
	await mouse(button_point)
	await mouse(button_point,MOUSE_BUTTON_RIGHT)
	assert(game.world.jobs.size()==2 and game.selected.get("kind")=="structure")
	# UI press dragged/released over the board must never become board selection.
	await drag(button_point,game.screen_cell(Vector2(15,12)))
	assert(game.world.jobs.size()==2 and game.selected.get("kind")=="structure")
	var removal_point=game.buttons.remove.get_global_rect().get_center()
	game.world.animals[0].placed=true
	game.world.animals[0].pos=Vector2i(game.get_canvas_transform().affine_inverse()*removal_point/game.TILE)
	game.view_positions.clear()
	await process_frame
	await click("remove")
	assert(game.selected.get("kind")=="structure","Enabled button wins over animal underneath")
	await key(KEY_DELETE)
	assert(game.world.jobs.size()==3 and game.world.live_structure(cell))
	await step(12)
	assert(game.world.tick==0 and game.world.structures[cell].hp==4)
	# Camera/zoom move the anchored panel; clamping keeps every button inside view.
	game.camera.position += Vector2(400,240)
	game.camera.zoom=Vector2.ONE*1.6
	await process_frame
	await process_frame
	var bounds=game.context_panel.get_global_rect()
	assert(Rect2(0,49,1280,650).encloses(bounds))
	game.world.structures.erase(cell)
	await process_frame
	assert(not is_instance_valid(game.context_panel))
	await selection_fixture("structure")
	await mouse(game.screen_cell(Vector2(10,8)),MOUSE_BUTTON_RIGHT)
	assert(game.world.jobs.is_empty(),"Unselected wall cannot be dismantled by right click")
	await mouse(game.screen_cell(Vector2(10,8)))
	assert(not game.buttons.has("repair"),"No repair button for full health")
	await mouse(game.screen_cell(Vector2(10,8)),MOUSE_BUTTON_RIGHT)
	assert(game.world.jobs.size()==1 and game.world.jobs[0].kind=="remove" and game.world.manual_goal==null)
	await mouse(game.screen_cell(Vector2(10,8)),MOUSE_BUTTON_RIGHT)
	assert(game.world.jobs.is_empty(),"Reserved work cancellation precedes dismantling")
	# Unselected keeper, matching composition: awake fatigue vs rest onset vs sleep.
	await selection_fixture("resource")
	game.world.paused=false
	game.refresh()
	game.world.keeper.pos=Vector2i(13,10)
	game.view_positions.clear()
	game.world.keeper.sleepiness=65
	await capture("drowsy")
	game.world.keeper.sleepiness=85
	await capture("tired")
	game.world.act("keeper_rest")
	await capture("settling")
	await step(21)
	await capture("rest")
	game.world.act("keeper_rest")
	# Explicit direct movement also wakes rest; no historical sleep overlay.
	game.world.act("keeper_move",Vector2i(15,10))
	assert(Farm.Life.presentation(game.world) not in ["settling","sleeping"])
	game.world.keeper.sleepiness=50
	assert(Farm.Life.presentation(game.world)=="awake")
