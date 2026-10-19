extends SceneTree
const Farm=preload("res://game/world.gd")
const Metrics=preload("res://game/terrain_metrics.gd")
var checks=[]
var rows=[]
func check(ok,note):checks.append({"passed":bool(ok),"check":note})
func _initialize():call_deferred("run")
func count_stock(w):return w.Stock.totals(w).duplicate()
func run():
	if DisplayServer.get_name()!="headless" or OS.get_environment("FARM_REVIEW_OUTPUT")=="":quit(2);return
	var seed_value=int(OS.get_environment("FARM_PHASE_SEED")) if OS.get_environment("FARM_PHASE_SEED")!="" else 31
	var nights=int(OS.get_environment("FARM_PHASE_NIGHTS")) if OS.get_environment("FARM_PHASE_NIGHTS")!="" else 1
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--seed="):seed_value=int(arg.trim_prefix("--seed="))
		if arg.begins_with("--nights="):nights=int(arg.trim_prefix("--nights="))
	var profile="--profile" in OS.get_cmdline_user_args();var slow=[];Metrics.enabled=profile
	var w=Farm.new({},seed_value).begin_day();var started=Time.get_ticks_msec();var times=[];var initial=count_stock(w);var peak=0;var same_job_ticks=0;var seen={"meal":false,"sleep":false,"night":false,"built":false,"harvest":false};var positions={};var sampled=[]
	check(w.W==100 and w.H==68,"Production 100x68 generated map")
	# Only normal player designations: no free resources, forced wins or stat healing.
	var candidates=w.natural.keys();candidates.sort_custom(func(a,b):return w.distance(w.keeper.pos,a)<w.distance(w.keeper.pos,b))
	for q in candidates.slice(0,3):w.act("collect",q)
	for kind in ["clear_tree","mine"]:
		var cells=(w.trees if kind=="clear_tree" else w.rocks).keys();cells.sort_custom(func(a,b):return w.distance(w.keeper.pos,a)<w.distance(w.keeper.pos,b))
		for q in cells:
			if w.act(kind,q):break
	var target=w.keeper.pos+Vector2i(5,3)
	for q in [target,target+Vector2i(1,0),target+Vector2i(2,0)]:w.act("wall",q)
	var last={};var previous_calendar=w.calendar_ticks;var daily={};var invalid="";var last_active=-1
	for i in range(1728*nights):
		var t=Time.get_ticks_usec();w.step();var ms=(Time.get_ticks_usec()-t)/1000.0;times.append(ms)
		if profile:
			var details=Metrics.take()
			if ms>50 and slow.size()<30:slow.append({"tick":w.tick,"total_ms":ms,"cpu_sections":details,"active":w.Work.active(w).get("kind",""),"personal":w.keeper.get("personal_haul",{}).duplicate(true),"life_need":w.keeper.get("life_need",""),"work_status":w.keeper.work_status,"jobs":w.jobs.size()})
		if w.tick%64==0:
			peak=maxi(peak,int(Performance.get_monitor(Performance.MEMORY_STATIC)))
			var ids={};var stockids={}
			for j in w.jobs:
				if ids.has(j.id):invalid="duplicate_job"
				ids[j.id]=true
			for r in w.field_items:
				if stockids.has(r.stock_id) or r.amount<=0:invalid="invalid_stock"
				stockids[r.stock_id]=true
				var claimed=0
				for amount in r.claims.values():claimed+=amount
				if claimed>r.amount:invalid="overclaimed"
			for a in w.workers.values():
				var cargo=0
				for r in w.Stock.cargo(w,a.work_key):cargo+=r.amount
				if cargo>20:invalid="cargo_overflow"
			for q in w.storage_cells:
				if w.Stock.storage_used(w,q)>40:invalid="storage_overflow"
			for token in w.work_claims:
				var id=w.work_claims[token]
				if not ids.has(id):invalid="orphan_job_claim"
			var active=w.Work.active(w);same_job_ticks=same_job_ticks+64 if active.get("id",-1)==last_active else 0;last_active=active.get("id",-1)
			if w.tick%256==0:sampled.append({"tick":w.tick,"day":w.campaign.day,"satiety":w.keeper.satiety,"hp":w.keeper.hp,"status":w.keeper.work_status,"jobs":w.jobs.size(),"stock":count_stock(w),"claims":w.work_claims.size(),"enemies":w.enemies.size()})
		seen.meal=seen.meal or w.keeper.has("meal_remaining");seen.sleep=seen.sleep or w.keeper.get("asleep",false);seen.night=seen.night or w.phase=="defend";seen.built=w.metrics.built>0;seen.harvest=w.metrics.weed_collected+w.metrics.mushroom_collected+w.metrics.stump_collected>0
		if w.last_daily_day>1:daily[w.last_daily_day]=true
		if not w.working():break
		if i%64==0:
			await process_frame
			if Time.get_ticks_msec()-started>85000:invalid="wall_time_budget";break
	check(invalid=="","IDs/claims/carry/storage invariants: "+invalid)
	check(w.result=="loss" or w.tick==1728*nights,"Simulation advances or explains a normal defeat")
	check(w.result!="loss" or w.story.defeat_reason!="","A loss has its real defeat reason")
	check(seen.night,"Night reached naturally")
	check(w.last_daily_day>=nights+1 or w.result=="loss","Dawn reached or normal loss recorded, never forced")
	times.sort();var sum=0.0
	for ms in times:sum+=ms
	var report={"seed":seed_value,"nights":nights,"ticks":w.tick,"calendar_ticks":w.calendar_ticks,"daily_day":w.last_daily_day,"result":w.result,"reason":w.story.get("defeat_reason",""),"initial_stock":initial,"final_stock":count_stock(w),"used":w.stock_used,"seen":seen,"jobs":w.jobs.size(),"worker_reason":w.Work.reason(w,"keeper",w.keeper),"worker_status":w.keeper.work_status,"hp":w.keeper.hp,"satiety":w.keeper.satiety,"metrics":w.metrics,"gold":w.campaign.gold,"idol_hp":w.story.idol.hp,"enemies":{"total":w.enemies.size(),"done":w.enemies.filter(func(e):return e.done).size()},"history":{"actions":w.actions.size(),"jobs":w.job_log.size(),"combat":w.combat_log.size(),"life":w.life_log.size(),"samples":w.traces.size()},"cpu_step_ms":{"mean":sum/maxi(1,times.size()),"p95":times[int((times.size()-1)*.95)],"p99":times[int((times.size()-1)*.99)],"max":times[-1]},"peak_static_bytes":peak,"wall_seconds":(Time.get_ticks_msec()-started)/1000.0,"samples":sampled,"checks":checks,"failures":checks.filter(func(c):return not c.passed).size(),"profile":profile,"slow_steps":slow,"keeper_state":w.keeper.state,"keeper_carrier":w.keeper.carrier,"scope":"Production World.step, normal player designations on generated terrain, no injected wins/resources, headless; not GPU/frame pacing or human play"}
	FileAccess.open(OS.get_environment("FARM_REVIEW_OUTPUT")+"/phase1-day-%d-%d%s.json"%[seed_value,nights,"-profile" if profile else ""],FileAccess.WRITE).store_string(JSON.stringify(report,"  "))
	print("PHASE1_DAY seed=",seed_value," nights=",nights," ticks=",w.tick," dawn=",w.last_daily_day," loss=",w.result," invalid=",invalid," seen=",seen)
	Metrics.enabled=false;quit(1 if report.failures else 0)
