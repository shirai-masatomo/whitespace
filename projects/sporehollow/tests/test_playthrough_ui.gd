extends "res://tests/test_controls.gd"
const Save=preload("res://game/morning_save.gd")

func fresh():
	game.world=Farm.new({},31).begin_day();game.world.day_seconds=600;game.world.spawn_schedule.clear()
	game.world.trees.clear();game.world.natural.clear();game.world.field_items.clear()
	game.world.keeper.pos=Vector2i(7,10);game.world.animals[0].pos=Vector2i(8,10)
	game.world.animals[0].home=Vector2i(8,10);game.world.animals[0].order=Vector2i(8,10)
	game.reset_view();game.story_modal="";game.arrival_started=-10;game.recenter();game.refresh()
	game._process(0)
	await process_frame

func ticks(count: int):
	for i in range(count):game.world.step();game._process(0)
	await process_frame

func click_id(id: String):
	await mouse(game.buttons[id].get_global_rect().get_center())

func run():
	output=OS.get_environment("FARM_REVIEW_OUTPUT")
	check(DisplayServer.get_name()=="headless" or ("--isolated-review" in OS.get_cmdline_user_args() and output!=""),"Experience review runs only on headless or private desktop")
	root.size=Vector2i(1280,800);game=load("res://game/main.tscn").instantiate();game.automated=true
	game.world=Farm.new({},31).begin_day()
	root.add_child(game);game.set_process(false);await process_frame
	# Controlled damage is the scenario setup; all player decisions use actual UI input.
	await fresh();var w=game.world;w.Life.hurt(w,{"id":-1,"attack_power":999})
	await click_id("walk")
	check(w.keeper.state=="unconscious" and game.buttons.keeper_rest.disabled,"Downed player sees unavailable rest rather than an escape from capture")
	await ticks(ceili(w.Life.CAPTURE_GRACE/w.DT))
	check(w.keeper.state=="hidden_rest" and game.buttons.keeper_rest.text=="起きる" and game.buttons.keeper_rest.disabled,"Hidden recovery starts; HP0 cannot be used to wake repeatedly")
	await ticks(ceili(w.Life.HIDDEN_HEAL_SECONDS/w.DT))
	check(w.keeper.hp==1 and not game.buttons.keeper_rest.disabled and "攻撃対象" in game.buttons.keeper_rest.tooltip_text,"After the first heal, the UI exposes waking and its risk")
	await capture("01_hidden_wake_choice")
	await key(KEY_SPACE);var tick=w.tick;await click_id("keeper_rest");await ticks(8)
	check(w.tick==tick and w.keeper.state=="hidden_rest" and w.keeper.get("pending_command",{}).get("kind")=="wake_hidden","Paused wake is an intent, not free healing or world time")
	await key(KEY_SPACE);await ticks(1)
	check(w.keeper.state=="free" and w.Life.targetable(w) and w.keeper.hp==1 and w.jobs_held,"Waking restores vulnerability and keeps work awaiting the player's decision")
	await click_id("resume_jobs");check(not w.jobs_held,"The visible resume-work button returns control")
	for blocked in ["unconscious","restrained","captured"]:
		w.keeper.state=blocked;w.keeper.carrier=12 if blocked=="captured" else -1
		check(not w.Life.command(w,"wake_hidden",Vector2i.ZERO),"Wake cannot escape "+blocked)
	await fresh();w=game.world;w.Life.hurt(w,{"id":-1,"attack_power":999});await ticks(250)
	check(w.keeper.state=="free" and w.keeper.hp>=w.Life.HIDDEN_RECOVER_HP,"Choosing to wait still reaches the existing automatic recovery")
	# A real build button -> board -> pause -> queue cancel sequence.
	await fresh();w=game.world;w.materials=100;await click_id("group0");await click_id("wall")
	await mouse(game.screen_cell(Vector2i(8,9)));await key(KEY_SPACE)
	check(w.jobs.size()==1 and w.materials==90,"Construction enters the paid queue through the visible tool")
	game.refresh_jobs();await process_frame
	var cancel=game.queue_controls.get_children().filter(func(n):return n is Button and n.tooltip_text=="この予定を取り消す")[0]
	await mouse(cancel.get_global_rect().get_center())
	check(w.jobs.is_empty() and w.materials==100,"Paused pending cancellation through × refunds exactly once")
	await key(KEY_SPACE);await ticks(12)
	check(w.jobs.is_empty() and not w.structures.has(Vector2i(8,9)),"A removed plan does not return after resume")
	# Work already begun uses the visible cancel-wait state and existing partial refund.
	await mouse(game.screen_cell(Vector2i(7,9)));await ticks(1);await key(KEY_SPACE)
	game.refresh_jobs();await process_frame
	cancel=game.queue_controls.get_children().filter(func(n):return n is Button and n.tooltip_text=="この予定を取り消す")[0]
	await mouse(cancel.get_global_rect().get_center())
	check(w.jobs[0].get("cancel_requested",false) and game.queue_controls.get_children().any(func(n):return n is Button and "取消待ち" in n.text),"Started work visibly acknowledges paused cancellation")
	await key(KEY_SPACE);await ticks(1)
	check(w.jobs.is_empty() and w.materials==95 and not w.structures.has(Vector2i(7,9)),"Started cancellation retains the existing half-refund, never creates free material")
	# A guide selected in the real species menu completes, then yields to autonomous behavior.
	await fresh();w=game.world;w.animals[0].loyalty=100
	await mouse(game.screen_cell(w.animals[0].pos));await click_id("guide");await mouse(game.screen_cell(Vector2i(15,10)))
	check(w.jobs.size()==1 and "遅い側" in game.buttons.guide.tooltip_text,"Guide UI explains pace and creates an actual order")
	for i in range(300):
		await ticks(1)
		if w.jobs.is_empty():break
	check(w.jobs.is_empty() and w.animals[0].mode=="auto" and w.job_log.any(func(e):return e.event=="guide_arrived"),"Arrival visibly returns the companion to autonomous behavior")
	await capture("02_guide_arrived")
	# The player can recover from a real idol-loss result with the visible retry action.
	await fresh();w=game.world;w.start_night();w.spawn_schedule.clear();w.story.idol.hp=1
	w.spawn_enemy({"role":"destroyer","entry":w.entries[0],"lv":1,"debug_single":true});var e=w.enemies.back()
	e.pos=Vector2i(w.story.idol.position[0]-1,w.story.idol.position[1]);e.ai_accuracy=100
	w.keeper.state="hidden_rest";w.keeper.hp=1;game.refresh();await ticks(12)
	check(w.phase=="result" and w.story.defeat_reason=="idol_destroyed","Visible idol pressure causes a bounded defeat, not a stalled game")
	game.clock=game.transition_at+10;game.refresh();await process_frame;await capture("03_idol_defeat")
	await click_id("retry")
	check(game.world.phase in ["day","defend"] and game.world.story.idol.hp>0,"The result's retry button restores a playable checkpoint")
	# Show owned corpses beside a recovering Shiba. Controlled deaths set the scene;
	# normal ticks and the real morning reconstruction determine persistence and return.
	await fresh();w=game.world
	for species in ["hen","cow","doberman"]:
		var id=w.campaign.next_animal_id;w.campaign.next_animal_id+=1
		var row={"id":id,"species":species,"category":w.SPECIES[species].category,"lv":1,"loyalty":w.SPECIES[species].loyalty,"name":"","unavailable_through_day":0}
		w.campaign.animals.append(row);w.add_resident(row);var a=w.animals.back()
		a.pos=Vector2i(7+(id-2)*3,12);w.Progression.animal_hurt(w,a,{"id":-1},999)
	w.Progression.animal_hurt(w,w.animals[0],{"id":-1},999)
	await ticks(80)
	check(w.animals[0].hp>0 and not w.available(w.animals[0]) and game.scene_actors().filter(func(a):return a.kind=="animal_corpse").size()==3,"Normal time keeps owned corpses visible and the living Shiba convalescent")
	await capture("04_corpse_and_recovery")
	w.persist_farm();var recovery_campaign=w.campaign.duplicate(true);recovery_campaign.night_ready=false
	recovery_campaign.day=w.animals[0].unavailable_through_day+1
	var returned=Farm.new(recovery_campaign,33)
	check(returned.animals.size()==1 and returned.available(returned.animals[0]) and returned.animals[0].hp>0,"The existing recovery morning returns one living Shiba and removes owned corpses")
	# Actual normal startup reads the morning slot; then the normal advance button continues it.
	var source=Farm.new({},73).campaign.duplicate(true);source.day=3;source.gold=123;source.world_story.intro_seen=true
	var morning=Farm.new(source,73)
	var path="user://experience/morning.sav";check(Save.write(Save.capture(morning),path).status=="ok","The fixture writes a structurally valid real morning")
	game.queue_free();await process_frame
	game=load("res://game/main.tscn").instantiate();game.save_path=path;root.add_child(game);game.set_process(false);await process_frame
	game.arrival_started=-10;game.clock=10;game.refresh();game._process(0)
	check(game.world.campaign.day==3 and game.world.campaign.gold==123 and "再開" in game.save_status,"Restarting the actual scene restores the saved morning and explains it")
	await click_id("advance")
	check(game.world.phase=="day" and game.world.campaign.day==3,"Restored morning continues via the ordinary button")
	if output!="":FileAccess.open(output+"/experience-review.json",FileAccess.WRITE).store_string(JSON.stringify(record,"  "))
	game.queue_free();await process_frame
	print("PLAYTHROUGH_UI: %d checks, failures=%d"%[checks,failures]);quit(1 if failures else 0)
