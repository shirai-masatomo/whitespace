extends "res://tests/audit_balance_failures.gd"
## One bounded continuation of a real saved campaign. No injected wins or resources.
const SLOT="user://continuity-review/morning.sav"
const LAST_NIGHT=30 # 15-night first route plus 15 continuation nights, starting from existing day 13.
var game

func boot(expected: Dictionary):
	if is_instance_valid(game):game.queue_free();await process_frame
	game=load("res://game/main.tscn").instantiate();game.save_path=SLOT
	root.add_child(game);game.set_process(false);await process_frame
	check(game.persistence_enabled and game.world.campaign.day==expected.campaign.day,"Real scene startup restores the current saved morning")
	check(Save.capture(game.world)==expected,"Repeated scene startup preserves the entire morning record")
	game.automated=true;game.story_modal="";game.clock=10;game.arrival_started=-10;game.refresh()

func run():
	check(DisplayServer.get_name()=="headless","Continuity review is headless only")
	var loaded=Save.read("res://artifacts/balance-fixtures/failure-31-none.sav")
	check(loaded.status=="ok" and loaded.record.campaign.day==13,"Reuse the real day13 morning; do not rerun its twelve-day prefix")
	if loaded.status!="ok":quit(1);return
	var morning=Save.restore(loaded.record);var observations=[];var total_ticks=0;var started=Time.get_ticks_msec()
	var peak_memory=0;var reached=false;var retry_checked=false
	for day in range(13,LAST_NIGHT+1):
		if day>13:morning=prepare_day(morning)
		var saved=Save.capture(morning)
		check(Save.write(saved,SLOT).status=="ok","Morning rotates safely into the same disk slot: day"+str(day))
		await boot(saved)
		if day>13:check(Save.read_one(SLOT+".bak").status=="ok","Repeated morning writes retain a readable prior generation")
		if day>=16:
			check(game.buttons.advance.text=="牧場を続ける","Post-milestone mornings still offer continuation")
			game.advance();check(game.world.phase=="day" and game.world.campaign.day==day,"Continue remains usable beyond the first milestone")
		var result=run_day(Save.restore(saved),"none",false,"repair_guard");var w=result.world
		total_ticks+=w.tick;peak_memory=maxi(peak_memory,int(Performance.get_monitor(Performance.MEMORY_STATIC)))
		check(w.result in ["win","loss"],"Natural fixed-tick play reaches a result within 1700 ticks: day"+str(day))
		check(w.wood>=0 and w.campaign.gold>=0,"Preparation and recovery use only available resources")
		observations.append({"day":day,"seed":w.seed_value,"result":w.result,"reason":w.story.defeat_reason,"ticks":w.tick,"idol_hp":w.story.idol.hp,"gold":w.campaign.gold,"wood":w.wood,"keeper":w.keeper.duplicate(true),"max_blocked_seconds":result.report.max_blocked_seconds,"animals":w.campaign.animals.map(func(a):return {"id":a.id,"species":a.species,"hp":a.get("hp",0),"lv":a.lv}),"logs":{"events":w.events.size(),"jobs":w.job_log.size(),"life":w.life_log.size(),"combat":w.combat_log.size()},"memory_bytes":int(Performance.get_monitor(Performance.MEMORY_STATIC))})
		print("CONTINUITY_DAY ",day," ",w.result," idol=",w.story.idol.hp," gold=",w.campaign.gold," ticks=",w.tick)
		game.world=w;game.last_phase="defend";game.clock+=100;game.refresh()
		if w.result!="win":
			check(w.result=="loss" and w.story.defeat_reason!="","A natural loss remains explained rather than counted as a balance failure")
			check(Save.read(SLOT).record==saved,"Defeat leaves the previously saved morning intact")
			game.clock+=10;game.retry_stage()
			check(game.world.working() and game.world.result=="" and game.world.campaign.gold==saved.campaign.gold and game.world.wood==saved.campaign.resources.wood,"Real retry restores the same day's earned resources, with no free grant")
			check(game.world.act("keeper_rest") or game.world.keeper.state in ["unconscious","hidden_rest"],"A restored retry exposes a valid rest or recovery state")
			var tick=game.world.tick
			for i in range(12):game.world.step()
			check(game.world.tick==tick+12,"Retry resumes fixed-tick play instead of remaining stuck at the result")
			retry_checked=true;break
		var next=Save.read(SLOT)
		check(next.status=="ok" and next.record.campaign.day==day+1,"Dawn saves the next morning before the transition animation")
		var settled=next.record.duplicate(true)
		game.clock+=10;game.advance();morning=game.world
		check(morning.phase=="shop" and Save.capture(morning)==settled,"Dawn animation and morning entry do not duplicate rewards or progress")
		if day>=15:
			reached=true
			check(morning.campaign.route_progress.completed_through_day>=15 and morning.campaign.route_progress.milestones.size()==1,"The first route milestone remains a single record during continuation")
		await process_frame
	var report={"base_game_commit":"f96467a","start_fixture":"failure-31-none.sav","range":[13,LAST_NIGHT],"policy":"existing repair_guard, none; normal purchases/training; stop at first loss and exercise one retry","days":observations,"total_ticks":total_ticks,"simulated_seconds":total_ticks*Farm.DT,"wall_seconds":(Time.get_ticks_msec()-started)/1000.0,"peak_static_bytes":peak_memory,"milestone_reached":reached,"retry_checked":retry_checked,"checks":records,"failures":failures,"scope":"Accelerated headless simulation and repeated actual scene/save restoration, not a wall-clock soak or human fun evaluation"}
	FileAccess.open("user://continuity-review/results.json",FileAccess.WRITE).store_string(JSON.stringify(report,"  "))
	if is_instance_valid(game):game.queue_free();await process_frame
	print("CONTINUITY_REVIEW: %d checks, failures=%d, ticks=%d"%[checks,failures,total_ticks]);quit(1 if failures else 0)
