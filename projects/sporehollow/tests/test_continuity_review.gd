extends "res://tests/audit_balance_failures.gd"
## One bounded continuation of a real saved campaign. No injected wins or resources.
const SLOT="user://continuity-review/morning.sav"
const LAST_NIGHT=30 # 15-night first route plus 15 continuation nights, starting from existing day 13.
const GAME_COMMIT="50f66c967a91fdfd26b1d0269c316ac452972841"
const ARRIVAL_KEYS=["arrival_goal","arrival_gate","arrival_route","arrival_closed","arrival_retry_tick","arrival_plans","arrival_queries","arrival_last_gate","arrival_complete","arrival_barriers","arrival_blocked_ticks","arrival_observation"]
var game
var entry_observations={}

func arrival_key_count(value) -> int:
	var count=0
	if value is Dictionary:
		for key in value:
			if key in ARRIVAL_KEYS:count+=1
			count+=arrival_key_count(value[key])
	elif value is Array:
		for row in value:count+=arrival_key_count(row)
	return count

func observe_entries(w):
	# Read-only observation of the existing policy's normal ticks, never a routing call.
	var active=0;var inactive=0
	for e in w.enemies:
		if not entry_observations.actors.has(e.id):
			entry_observations.actors[e.id]={"role":e.role,"last_pos":e.pos,"still_ticks":0,"longest_still_ticks":0,"queries":0,"plans":0,"entrance_changes":0,"ever_complete":false}
		var row=entry_observations.actors[e.id]
		var incoming=not e.done and e.hp>0 and not e.get("arrival_complete",false)
		row.still_ticks=row.still_ticks+1 if incoming and row.last_pos==e.pos else 0
		row.longest_still_ticks=maxi(row.longest_still_ticks,row.still_ticks);row.last_pos=e.pos
		row.queries=maxi(row.queries,e.get("arrival_queries",0));row.plans=maxi(row.plans,e.get("arrival_plans",0))
		row.entrance_changes=maxi(row.entrance_changes,e.get("arrival_gate_changes",0))
		row.ever_complete=row.ever_complete or e.get("arrival_complete",false)
		if e.has("arrival_goal"):
			if incoming:active+=1
			else:inactive+=1
	entry_observations.max_active_assignments=maxi(entry_observations.max_active_assignments,active)
	# Completed/dead/done actors may retain diagnostic keys; choose() excludes them.
	entry_observations.end_active_assignments=active;entry_observations.end_inactive_goal_keys=inactive

func boot(expected: Dictionary):
	if is_instance_valid(game):game.queue_free();await process_frame
	game=load("res://game/main.tscn").instantiate();game.save_path=SLOT
	root.add_child(game);game.set_process(false);await process_frame
	check(game.persistence_enabled and game.world.campaign.day==expected.campaign.day,"Real scene startup restores the current saved morning")
	check(Save.capture(game.world)==expected,"Repeated scene startup preserves the entire morning record")
	check(game.world.enemies.is_empty() and arrival_key_count(expected)==0,"Scene restart carries no previous-night enemy or entrance assignment")
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
		entry_observations={"actors":{},"max_active_assignments":0,"end_active_assignments":0,"end_inactive_goal_keys":0}
		var result=run_day(Save.restore(saved),"none",false,"repair_guard",observe_entries);var w=result.world
		total_ticks+=w.tick;peak_memory=maxi(peak_memory,int(Performance.get_monitor(Performance.MEMORY_STATIC)))
		check(w.result in ["win","loss"],"Natural fixed-tick play reaches a result within 1700 ticks: day"+str(day))
		check(w.wood>=0 and w.campaign.gold>=0,"Preparation and recovery use only available resources")
		observations.append({"day":day,"seed":w.seed_value,"result":w.result,"reason":w.story.defeat_reason,"ticks":w.tick,"idol_hp":w.story.idol.hp,"gold":w.campaign.gold,"wood":w.wood,"keeper":w.keeper.duplicate(true),"max_blocked_seconds":result.report.max_blocked_seconds,"animals":w.campaign.animals.map(func(a):return {"id":a.id,"species":a.species,"hp":a.get("hp",0),"lv":a.lv}),"logs":{"events":w.events.size(),"jobs":w.job_log.size(),"life":w.life_log.size(),"combat":w.combat_log.size()},"memory_bytes":int(Performance.get_monitor(Performance.MEMORY_STATIC))})
		observations[-1].arrival=entry_observations.duplicate(true)
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
		check(morning.enemies.is_empty() and arrival_key_count(settled)==0,"Dawn clears old enemies and entrance assignments from the next saved morning")
		if day>=15:
			reached=true
			check(morning.campaign.route_progress.completed_through_day>=15 and morning.campaign.route_progress.milestones.size()==1,"The first route milestone remains a single record during continuation")
		await process_frame
	check(observations.any(func(day):return day.arrival.actors.values().any(func(actor):return actor.plans>0)),"Continuation actually exercises the new local entrance routing")
	var report={"base_game_commit":GAME_COMMIT,"start_fixture":"failure-31-none.sav","range":[13,LAST_NIGHT],"policy":"existing repair_guard, none; normal purchases/training; stop at first loss and exercise one retry","days":observations,"total_ticks":total_ticks,"simulated_seconds":total_ticks*Farm.DT,"wall_seconds":(Time.get_ticks_msec()-started)/1000.0,"peak_static_bytes":peak_memory,"milestone_reached":reached,"retry_checked":retry_checked,"checks":records,"failures":failures,"scope":"One accelerated continuation of the new routing with read-only per-tick observations and morning assignment checks; not a wall-clock soak or human fun evaluation"}
	FileAccess.open("user://continuity-review/results.json",FileAccess.WRITE).store_string(JSON.stringify(report,"  "))
	if is_instance_valid(game):game.queue_free();await process_frame
	print("CONTINUITY_REVIEW: %d checks, failures=%d, ticks=%d"%[checks,failures,total_ticks]);quit(1 if failures else 0)
