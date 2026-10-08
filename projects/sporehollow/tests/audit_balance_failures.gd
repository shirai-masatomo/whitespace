extends "res://tests/test_campaign_play.gd"
## Replays only the four previously failed policies. Captures real morning slots for bounded forks.
const CASES=[[17,"mixed",9],[31,"none",13],[31,"gold_once",5],[31,"mixed",7]]

func prepare_day(morning):
	while morning.train_animal(1):pass
	if morning.story.idol.hp<120:morning.buy("wood")
	for product in ["collar","doberman","bullfrog","hedgehog","berry"]:
		if product=="collar" and morning.animals[0].equipment.get("item_id","")=="collar":continue
		if product in Farm.SPECIES and morning.animals.any(func(a):return a.species==product):continue
		morning.buy(product)
	return Save.restore(Save.capture(morning))

func run_day(morning,mode: String,trace: bool=false,variant: String="baseline",observer: Callable=Callable()) -> Dictionary:
	var start={"day":morning.campaign.day,"gold":morning.campaign.gold,"wood":morning.wood,"idol_hp":morning.story.idol.hp,"news":morning.story.news.duplicate(true),"raids":morning.Story.reaction_raids(morning),"animals":morning.animals.duplicate(true)}
	var w=morning.begin_day();var category=wish(mode,w.campaign.day);var requested=false
	if w.item_count("collar")>0:P.equip_job(w,1,"collar")
	for a in w.animals:
		if a.species!="shiba" and w.item_count("berry")>0:P.equip_job(w,a.id,"berry")
	if w.story.idol.hp<120 and w.wood>=5:w.act("repair_idol",w.Story.at(w))
	if category!="" and not w.story.investigated:w.act("inspect_idol",w.Story.at(w))
	var hits=[];var night_start={};var max_blocked_ticks=0;var blocked_ticks=0
	var guided=[];var guide_attempts=[]
	var defenders=w.animals.filter(func(a):return w.Orders.active(w,a) and a.species in ["doberman","shiba","hedgehog","bullfrog","bull"])
	defenders.sort_custom(func(a,b):return (0 if a.species=="doberman" else a.id)<(0 if b.species=="doberman" else b.id))
	for i in range(1700):
		if w.phase=="day" and w.jobs.is_empty():
			if variant=="repair_guard" and guided.size()<defenders.size() and w.Life.able(w):
				var a=defenders[guided.size()];var sites=w.Story.goals(w);var dest=sites[guided.size()%sites.size()]
				var accepted=w.queue_order("guide",[a.id],dest);guided.append(a.id)
				guide_attempts.append({"tick":w.tick,"id":a.id,"species":a.species,"destination":dest,"accepted":accepted})
			elif variant in ["repair_full","repair_guard"] and w.story.idol.hp<w.story.idol.max_hp and w.wood>=5 and w.Life.able(w):
				w.act("repair_idol",w.Story.at(w))
			elif category!="" and not requested and w.story.investigated and w.Life.able(w):
				requested=w.act("pray_"+category,w.Story.at(w))
			elif not w.keeper.resting:w.act("keeper_rest")
		if w.phase=="defend" and w.tick%12==0:
			var threats=w.enemies.filter(func(e):return not e.done and not e.flee and e.hp>0 and w.distance(e.pos,w.keeper.pos)<=6)
			if not threats.is_empty() and w.keeper.resting and not w.keeper.forced_rest:w.act("keeper_rest")
			if not threats.is_empty() and w.Life.able(w) and w.distance(threats[0].pos,w.keeper.pos)<=2:
				var cells=w.neighbors(w.keeper.pos).filter(func(p):return w.walkable(p) and not w.actor_occupied(p,w.keeper.pos))
				cells.sort_custom(func(a,b):return w.distance(a,threats[0].pos)>w.distance(b,threats[0].pos))
				if not cells.is_empty():w.act("keeper_move",cells[0])
		var hp=w.story.idol.hp;var danger=w.danger_serial;var before={}
		if trace:
			for e in w.enemies:before[e.id]=e.next_attack
		w.step()
		if observer.is_valid():observer.call(w)
		if w.phase=="defend" and night_start.is_empty():night_start={"tick":w.tick,"idol_hp":w.story.idol.hp,"gold":w.campaign.gold,"wood":w.wood,"keeper":w.keeper.duplicate(true),"jobs":w.jobs.duplicate(true),"held":w.job_hold_reason}
		if w.story.idol.hp!=hp and trace:
			var attackers=w.enemies.filter(func(e):return e.next_attack>before.get(e.id,-1) and (e.role=="idol_breaker" or e.get("chosen_target",{}).get("kind")=="idol"))
			hits.append({"tick":w.tick,"phase":w.phase,"night_seconds":(w.tick-w.night_started_tick)*w.DT,"change":w.story.idol.hp-hp,"hp":w.story.idol.hp,"danger_changed":w.danger_serial>danger,"keeper_state":w.keeper.state,"keeper_pos":w.keeper.pos,"keeper_hp":w.keeper.hp,"held":w.job_hold_reason,"jobs":w.jobs.duplicate(true),"attackers":attackers.map(func(e):return {"id":e.id,"role":e.role,"archetype":e.archetype,"hp":e.hp,"pos":e.pos}),"active_animals":w.animals.filter(func(a):return w.Orders.active(w,a)).map(func(a):return {"id":a.id,"species":a.species,"pos":a.pos,"state":a.state,"mode":a.mode}),"feed":w.player_events.duplicate(true)})
		blocked_ticks=blocked_ticks+1 if not w.jobs.is_empty() and w.jobs[0].state=="blocked" else 0
		max_blocked_ticks=maxi(max_blocked_ticks,blocked_ticks)
		if w.result!="":break
	return {"world":w,"report":{"variant":variant,"start":start,"night_start":night_start,"result":w.result,"reason":w.story.defeat_reason,"steps":w.tick,"idol_hp":w.story.idol.hp,"end_gold":w.campaign.gold,"end_wood":w.wood,"max_blocked_seconds":max_blocked_ticks*w.DT,"guide_attempts":guide_attempts,"hits":hits,"jobs":w.job_log,"life":w.life_log,"enemies":w.enemies.duplicate(true)}}

func run():
	var reports=[]
	for entry in CASES:
		var morning=Farm.new({},entry[0]);var prior=[]
		for day in range(1,entry[2]+1):
			morning=prepare_day(morning)
			var snapshot=Save.capture(morning)
			var final_day=day==entry[2]
			if final_day:check(Save.write(snapshot,"user://failure-%d-%s.sav"%[entry[0],entry[1]]).status=="ok","Capture exact failure morning")
			var result=run_day(morning,entry[1],final_day)
			var w=result.world
			prior.append({"day":day,"result":w.result,"idol_hp":w.story.idol.hp,"gold":w.campaign.gold,"steps":w.tick})
			if final_day:
				check(w.result=="loss" and w.story.defeat_reason=="idol_destroyed","Reproduce recorded failure %d/%s/%d"%[entry[0],entry[1],day])
				reports.append({"seed":entry[0],"policy":entry[1],"prior_days":prior,"baseline":result.report})
				var repaired=run_day(Save.restore(snapshot),entry[1],true,"repair_full")
				reports[-1].repair_full=repaired.report
				check(repaired.world.result in ["win","loss"],"Repair fork remains bounded")
				print("AUDIT_CASE ",entry," baseline=",w.result," repair_full=",repaired.world.result," remaining=",repaired.world.story.idol.hp)
				break
			check(w.result=="win","Prefix matches existing successful days")
			morning=Farm.new(w.next_campaign(),w.seed_value+1)
	FileAccess.open("user://balance-failure-audit.json",FileAccess.WRITE).store_string(JSON.stringify({"base_commit":"3bc0644","reports":reports,"checks":checks,"failures":failures,"method":"Four existing failures only; same morning forks; repair policy only, no balance constants changed"},"  "))
	print("BALANCE_AUDIT: %d checks, failures=%d"%[checks,failures]);quit(1 if failures else 0)
