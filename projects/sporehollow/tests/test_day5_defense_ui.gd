extends "res://tests/test_playthrough_ui.gd"
var morning_record={}

func fifth_day():
	game.world=Save.restore(morning_record)
	game.reset_view();game.story_modal="";game.arrival_started=-10;game.clock=10;game.refresh();game._process(0)
	await process_frame;await click_id("advance")
	game.arrival_started=-10;game.story_modal="";game.recenter();game.refresh();game._process(0)
	await process_frame
	check(game.world.campaign.day==5 and game.world.phase=="day","Preserved fifth morning starts through the ordinary advance button")

func guide(a,destination: Vector2i):
	game.choose_animal(a.id);game.refresh();await process_frame
	await click_id("guide");await mouse(game.screen_cell(destination))

func run():
	output=OS.get_environment("FARM_REVIEW_OUTPUT")
	check(DisplayServer.get_name()=="headless" or ("--isolated-review" in OS.get_cmdline_user_args() and output!=""),"Only headless or private desktop; no user input desktop")
	var loaded=Save.read("res://artifacts/balance-fixtures/failure-31-gold_once.sav")
	check(loaded.status=="ok","Read the preserved day-five morning, without normal saves")
	if loaded.status!="ok":quit(1);return
	morning_record=loaded.record
	root.size=Vector2i(1280,800);game=load("res://game/main.tscn").instantiate();game.automated=true
	game.world=Save.restore(morning_record);root.add_child(game);game.set_process(false);await process_frame
	# Real saved resources and idol damage; no injected money, damage, or victory.
	await fifth_day();var w=game.world;var initial_hp=w.story.idol.hp;var initial_wood=w.wood;var gold=w.campaign.gold
	for repair in range(2):
		await mouse(game.screen_cell(w.Story.at(w)))
		check(game.buttons.has("repair_idol") and not game.buttons.repair_idol.disabled,"A damaged idol exposes repair again after completed work")
		await click_id("repair_idol")
		check(w.jobs.any(func(j):return j.kind=="repair_idol"),"The repair button creates a normal job")
		for i in range(160):
			await ticks(1)
			if w.jobs.is_empty():break
		check(w.jobs.is_empty() and w.story.idol.hp==initial_hp+30*(repair+1) and w.wood==initial_wood-5*(repair+1),"Repeated repair uses five wood and restores thirty HP each time")
	check(w.campaign.gold==gold,"Repeated repairs do not inject or charge gold")
	await capture("01_day5_repeat_repair")
	# Interrupt an issued instruction while paused, then issue it again through the UI.
	await fifth_day();w=game.world
	var dog=w.animals.filter(func(a):return a.species=="doberman")[0];var destination=w.Story.goals(w)[0]
	await guide(dog,destination)
	for i in range(80):
		if not w.jobs.is_empty() and w.jobs[0].targets[0].issued:break
		await ticks(1)
	check(not w.jobs.is_empty() and w.jobs[0].targets[0].issued,"The keeper physically reaches the companion before cancellation")
	await key(KEY_SPACE);game.refresh_jobs();await process_frame
	var cancelled_id=w.jobs[0].id
	var cancel=game.queue_controls.get_children().filter(func(n):return n is Button and n.tooltip_text=="この予定を取り消す")[0]
	await mouse(cancel.get_global_rect().get_center())
	check(w.jobs[0].get("cancel_requested",false) and game.queue_controls.get_children().any(func(n):return n is Button and "取消待ち" in n.text),"Paused issued guidance acknowledges cancellation visibly")
	await capture("02_day5_cancel_wait")
	await key(KEY_SPACE);await ticks(1)
	check(w.jobs.is_empty() and not dog.has("guide_job"),"Resume releases both the cancelled job and companion")
	await guide(dog,destination)
	check(w.jobs.size()==1 and w.jobs[0].id!=cancelled_id,"The same companion accepts a fresh instruction")
	for i in range(180):
		await ticks(1)
		if w.jobs.is_empty():break
	check(w.jobs.is_empty() and dog.mode=="auto" and w.job_log.any(func(e):return e.event=="guide_arrived"),"Reissued guidance arrives and returns to autonomous behavior")
	await capture("03_day5_reissued_arrival")
	# Reproduce the existing guard-fork preparation through visible command buttons.
	await fifth_day();w=game.world
	if w.item_count("collar")>0:w.Progression.equip_job(w,1,"collar")
	for a in w.animals:
		if a.species!="shiba" and w.item_count("berry")>0:w.Progression.equip_job(w,a.id,"berry")
	if w.story.idol.hp<120 and w.wood>=5:w.act("repair_idol",w.Story.at(w))
	for i in range(160):
		if w.jobs.is_empty():break
		await ticks(1)
	var defenders=w.animals.filter(func(a):return w.Orders.active(w,a) and a.species in ["doberman","shiba","hedgehog","bullfrog","bull"])
	defenders.sort_custom(func(a,b):return (0 if a.species=="doberman" else a.id)<(0 if b.species=="doberman" else b.id))
	var saw_blocked=false;var timeout_animal={};var preparations=[]
	for index in range(defenders.size()):
		var a=defenders[index];var sites=w.Story.goals(w);var dest=sites[index%sites.size()]
		await guide(a,dest)
		var notices=w.milestones.size();var blocked=0
		for i in range(220):
			if w.jobs.is_empty():break
			await ticks(1)
			if not w.jobs.is_empty() and w.jobs[0].state=="blocked":
				blocked+=1
				if not saw_blocked:
					saw_blocked=true;game.refresh_jobs();await process_frame
					check(game.queue_controls.get_children().any(func(n):return n is Button and "取消可" in n.tooltip_text),"Blocked guidance exposes a reason and cancellation")
					await capture("04_day5_congestion")
		var ended=w.milestones.slice(notices).any(func(e):return "道が開かない" in e.get("text",""))
		preparations.append({"species":a.species,"blocked_ticks":blocked,"timeout":ended,"remaining_jobs":w.jobs.size(),"tick":w.tick})
		check(w.jobs.is_empty(),"Each preparation instruction ends within its bounded simulation window")
		if ended:timeout_animal=a
	check(saw_blocked and not timeout_animal.is_empty(),"The saved preparation reproduces congestion and its existing twenty-second stop")
	if not timeout_animal.is_empty():
		check(not timeout_animal.has("guide_job") and w.events.any(func(e):return "道が開かない" in e.text),"Timeout releases the companion and explains why guidance ended")
		await capture("05_day5_timeout_notice")
		await guide(timeout_animal,w.Story.goals(w)[-1])
		check(w.jobs.size()==1,"A companion from the timed-out order can be instructed again")
		game.refresh_jobs();await process_frame
		cancel=game.queue_controls.get_children().filter(func(n):return n is Button and n.tooltip_text=="この予定を取り消す")[0]
		await mouse(cancel.get_global_rect().get_center())
		check(w.jobs.is_empty() and not timeout_animal.has("guide_job"),"Cancelling the retry leaves no stranded guide state")
	record.preparations=preparations
	record.scope="Saved morning31/gold_once/day5; short UI contracts, not a full night or human fun rating. Gear/first repair in congestion branch matches the existing audit setup."
	if output!="":FileAccess.open(output+"/day5-defense-review.json",FileAccess.WRITE).store_string(JSON.stringify(record,"  "))
	game.queue_free();await process_frame
	print("DAY5_DEFENSE_UI: %d checks, failures=%d"%[checks,failures]);quit(1 if failures else 0)
