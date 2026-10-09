extends SceneTree
## Observed walkthrough: private-desktop only, normal UI inputs and a recorded review clock.
const Farm=preload("res://game/world.gd")
var game
var output=""
var serial=0
var last_request=-1
var events=[]
var scenario="fresh_seed31"

func _initialize():call_deferred("run")

func mouse(p: Vector2,button: int=MOUSE_BUTTON_LEFT):
	var motion=InputEventMouseMotion.new();motion.position=p;root.push_input(motion,true);await process_frame
	for pressed in [true,false]:
		var e=InputEventMouseButton.new();e.position=p;e.button_index=button;e.pressed=pressed
		root.push_input(e,true);await process_frame

func key(code: int):
	for pressed in [true,false]:
		var e=InputEventKey.new();e.keycode=code;e.physical_keycode=code;e.pressed=pressed
		root.push_input(e,true);await process_frame

func snapshot(label: String):
	game._process(0);await process_frame;await process_frame;await RenderingServer.frame_post_draw
	serial+=1
	var file="%s_%03d_%s.png"%[Time.get_date_string_from_system().replace("-",""),serial,label.validate_filename()]
	root.get_texture().get_image().save_png(output+"/"+file)
	var controls={}
	for id in game.buttons:
		var b=game.buttons[id]
		if is_instance_valid(b) and b.is_visible_in_tree() and not b.is_queued_for_deletion():controls[id]={"text":b.text,"disabled":b.disabled,"rect":str(b.get_global_rect()),"tooltip":b.tooltip_text}
	var w=game.world
	var state={"request":last_request,"screenshot":file,"label":label,"phase":w.phase,"day":w.campaign.day,"tick":w.tick,"game_seconds":w.tick*w.DT,"clock":game.clock,"paused":w.paused,"speed":game.speed,"modal":game.story_modal,"screen":game.morning_screen,"controls":controls,"notice":game.message,"alert":game.alert_text,"keeper":{"pos":str(w.keeper.pos),"hp":w.keeper.hp,"state":w.keeper.state,"resting":w.keeper.resting},"jobs":w.jobs,"job_hold":w.job_hold_reason,"animals":w.animals.map(func(a):return {"id":a.id,"species":a.species,"pos":str(a.pos),"hp":a.hp,"state":a.state,"mode":a.mode}),"enemies":w.enemies.map(func(e):return {"id":e.id,"role":e.role,"pos":str(e.pos),"hp":e.hp,"done":e.done}),"defeat_reason":w.story.get("defeat_reason","")}
	state.scenario=scenario;state.idol=w.story.idol;state.life_log=w.life_log;state.job_log=w.job_log
	state.combat_log=w.combat_log;state.skill_log=w.skill_log
	state.player_events=w.player_events
	for i in range(w.animals.size()):
		var a=w.animals[i]
		state.animals[i].merge({"abductor":a.get("abductor",-1),"dead":a.get("dead",false),"lost":a.get("lost",false),"target_id":a.get("target_id",-1)})
	for i in range(w.enemies.size()):
		var e=w.enemies[i]
		state.enemies[i].merge({"state":e.state,"led_animal":e.get("led_animal",-1),"dead":e.get("dead",false),"revived":e.get("revived",false),"gauge":e.get("ultimate_gauge",0),"chosen_target":e.get("chosen_target",{})})
	FileAccess.open(output+"/state.json",FileAccess.WRITE).store_string(JSON.stringify(state,"  "))
	FileAccess.open(output+"/"+file.trim_suffix(".png")+".json",FileAccess.WRITE).store_string(JSON.stringify(state,"  "))
	FileAccess.open(output+"/events.json",FileAccess.WRITE).store_string(JSON.stringify(events,"  "))
	var index=FileAccess.open(output+"/SCREENSHOTS.tsv",FileAccess.READ_WRITE)
	if not index:index=FileAccess.open(output+"/SCREENSHOTS.tsv",FileAccess.WRITE)
	index.seek_end();index.store_line("%s\t%s\tday%d\t%s\ttick%d"%[file,label,w.campaign.day,w.phase,w.tick])

func fixture(name: String):
	# Explicitly separate branch setup from a continuous new-game review. Private save only.
	if name not in ["recovery","kidnapping","animal_loss","idol_breaker","idol_extraction","target_range","tamer_dancer","tamer_dancer_rescue","tamer_dancer_intercept"]:return
	scenario="fixture_"+name
	if is_instance_valid(game.story_panel):game.story_panel.queue_free();game.story_panel=null
	var campaign=Farm.new({},31).campaign.duplicate(true)
	campaign.day=5 if name.begins_with("idol_") else 1
	campaign.world_story.intro_seen=true
	game.world=Farm.new(campaign,31).begin_day()
	if name.begins_with("tamer_dancer"):game.world=preload("res://tests/review_mixed_fixture.gd").create(name!="tamer_dancer",name=="tamer_dancer_intercept")
	var w=game.world
	w.trees.clear();w.natural.clear();w.field_items.clear();w.spawn_schedule.clear();w.day_seconds=600
	if not name.begins_with("tamer_dancer"):
		w.keeper.pos=Vector2i(7,10);w.animals[0].pos=Vector2i(8,10)
		w.animals[0].home=w.animals[0].pos;w.animals[0].order=w.animals[0].pos
	if name=="recovery":w.Life.hurt(w,{"id":-1,"attack_power":999})
	elif name=="animal_loss":
		var row={"id":w.campaign.next_animal_id,"species":"hen","category":w.SPECIES.hen.category,"lv":1,"loyalty":w.SPECIES.hen.loyalty,"name":"","unavailable_through_day":0}
		w.campaign.next_animal_id+=1;w.campaign.animals.append(row);w.add_resident(row)
		w.animals.back().pos=Vector2i(9,10);w.Progression.animal_hurt(w,w.animals.back(),{"id":-1},999)
		w.start_night();w.spawn_schedule.clear()
	elif name=="kidnapping":
		w.start_night();w.spawn_schedule.clear();w.keeper.pos=Vector2i(20,8)
		w.animals[0].pos=Vector2i(3,12);w.animals[0].home=w.animals[0].pos;w.animals[0].order=w.animals[0].pos
		w.Life.hurt(w,{"id":-1,"attack_power":999})
		w.spawn_enemy({"role":"kidnapper","entry":Vector2i(23,8),"lv":1,"debug_single":true})
		w.enemies.back().pos=Vector2i(21,8);w.enemies.back().ai_accuracy=100
	elif name.begins_with("idol_"):
		w.start_night();w.spawn_schedule.clear();w.keeper.state="hidden_rest";w.keeper.hp=1
		w.animals[0].pos=Vector2i(3,12);w.animals[0].home=w.animals[0].pos;w.animals[0].order=w.animals[0].pos
		w.spawn_enemy({"role":"destroyer" if name=="idol_breaker" else "idol_extractor","entry":Vector2i(12,1),"lv":1,"debug_single":true})
		var e=w.enemies.back();e.ai_accuracy=100
		e.pos=Vector2i(w.story.idol.position[0]-1,w.story.idol.position[1]) if name=="idol_breaker" else Vector2i(12,7)
		if name=="idol_breaker":w.story.idol.hp=1
	elif name=="target_range":
		w.spawn_enemy({"role":"kidnapper","entry":Vector2i(1,8),"lv":1,"debug_single":true})
		w.enemies.back().pos=Vector2i(8,15);w.keeper.pos=Vector2i(7,14)
	game.reset_view();game.story_modal="";game.arrival_started=-10;game.recenter();game.refresh()
	game._process(0);await process_frame

func apply(request: Dictionary):
	events.append({"request":request.duplicate(true),"before_tick":game.world.tick,"before_phase":game.world.phase})
	for action in request.get("actions",[]):
		match action.kind:
			"fixture":
				await fixture(action.name)
				if action.get("idol_warning_layout",false):
					# Layout-only overlap stress; not evidence of a played extraction encounter.
					game.world.story.idol.state="preparing";scenario+="_idol_warning_layout"
			"click":
				var b=game.buttons.get(action.id)
				if not is_instance_valid(b) or not b.is_visible_in_tree() or b.disabled:
					events.append({"rejected":"unavailable button","id":action.id});continue
				await mouse(b.get_global_rect().get_center())
			"cell":await mouse(game.screen_cell(Vector2i(action.x,action.y)),action.get("button",MOUSE_BUTTON_LEFT))
			"mouse":await mouse(Vector2(action.x,action.y),action.get("button",MOUSE_BUTTON_LEFT))
			"key":await key(OS.find_keycode_from_string(action.key))
			"advance":
				# Normal main._process, including overlays, danger and transitions. Fast review playback.
				for i in range(ceili(clampf(action.seconds,0,300)*10)):
					game._process(0.1);await process_frame
			"observe":
				# Actual frame delta, no accelerated manual steps. Normal game speed still applies.
				var started=Time.get_ticks_msec();var before=game.world.tick
				var deadline=started+roundi(clampf(action.seconds,0,30)*1000)
				game.set_process(true)
				var next_capture=started+3000
				while Time.get_ticks_msec()<deadline:
					await process_frame
					if Time.get_ticks_msec()>=next_capture:
						await snapshot(request.get("label","observe")+"_%02ds"%roundi((Time.get_ticks_msec()-started)/1000.0))
						next_capture+=3000
				game.set_process(false)
				events.append({"observation":"real_frame_delta","wall_ms":Time.get_ticks_msec()-started,"before_tick":before,"after_tick":game.world.tick,"speed":game.speed})
			"quit":quit();return
		game._process(0);await process_frame
	await snapshot(request.get("label","observed"))

func run():
	output=OS.get_environment("FARM_REVIEW_OUTPUT")
	if DisplayServer.get_name()=="headless" or output=="" or not "--isolated-review" in OS.get_cmdline_user_args():quit(2);return
	root.size=Vector2i(1280,800);root.notify_mouse_entered()
	game=load("res://game/main.tscn").instantiate();game.world=Farm.new({},31)
	game.save_path="user://player-walkthrough/morning.sav"
	root.add_child(game);game.set_process(false);await process_frame
	await snapshot("newgame_intro_before")
	while true:
		await create_timer(0.1).timeout
		if not FileAccess.file_exists(output+"/request.json"):continue
		var request=JSON.parse_string(FileAccess.get_file_as_string(output+"/request.json"))
		if request is Dictionary and request.get("id",-1)>last_request:
			last_request=request.id;await apply(request)
