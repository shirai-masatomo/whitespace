extends "res://tests/test_progression.gd"
const Save=preload("res://game/morning_save.gd")
## Repeatable simple policy, not an optimal player and never a forced victory. Outcomes are measurements.
func wish(mode: String,day: int) -> String:
	if day<2 or mode=="none":return ""
	if mode=="gold_once":return "gold" if day==2 else ""
	return ["animal","gold","item"][posmod(day-2,3)]
func run():
	var reports=[];var target=P.Encounters.route_definition().completion_night
	for seed_value in [17,31,73]:
		for mode in ["none","gold_once","mixed"]:
			var morning=Farm.new({},seed_value);var days=[]
			for day in range(1,target+1):
				while morning.train_animal(1):pass
				if morning.story.idol.hp<120:morning.buy("wood")
				for product in ["collar","doberman","bullfrog","hedgehog","berry"]:
					if product=="collar" and morning.animals[0].equipment.get("item_id","")=="collar":continue
					if product in Farm.SPECIES and morning.animals.any(func(a):return a.species==product):continue
					morning.buy(product)
				# Exercise the persisted boundary each morning without mutating normal user data.
				var saved=Save.capture(morning);morning=Save.restore(saved)
				if morning==null:check(false,"Natural scenario formed a valid morning save");quit(1);return
				var w=morning.begin_day();var category=wish(mode,day);var requested=false
				if w.item_count("collar")>0:P.equip_job(w,1,"collar")
				for a in w.animals:
					if a.species!="shiba" and w.item_count("berry")>0:P.equip_job(w,a.id,"berry")
				if w.story.idol.hp<120 and w.wood>=5:w.act("repair_idol",w.Story.at(w))
				if category!="" and not w.story.investigated:w.act("inspect_idol",w.Story.at(w))
				var steps=0
				for i in range(1700):
					if w.phase=="day" and w.jobs.is_empty():
						if category!="" and not requested and w.story.investigated and w.Life.able(w):
							requested=w.act("pray_"+category,w.Story.at(w))
						elif not w.keeper.resting:w.act("keeper_rest")
					if w.phase=="defend" and w.tick%12==0:
						var threats=w.enemies.filter(func(e):return not e.done and not e.flee and e.hp>0 and w.distance(e.pos,w.keeper.pos)<=6)
						if not threats.is_empty() and w.keeper.resting and not w.keeper.forced_rest:w.act("keeper_rest")
						if not threats.is_empty() and w.Life.able(w) and w.distance(threats[0].pos,w.keeper.pos)<=2:
							var cells=w.neighbors(w.keeper.pos).filter(func(p):return w.walkable(p) and not w.actor_occupied(p,w.keeper.pos))
							cells.sort_custom(func(a,b):return w.distance(a,threats[0].pos)>w.distance(b,threats[0].pos))
							if not cells.is_empty():w.act("keeper_move",cells[0])
					w.step();steps=i+1
					if w.result!="":break
				days.append({"day":day,"seed":w.seed_value,"result":w.result,"defeat_reason":w.story.defeat_reason,"steps":steps,"gold":w.campaign.gold,"exp_pool":w.campaign.exp_pool,"idol_hp":w.story.idol.hp,"karma":w.story.hidden.karma,"prayer_requested":category if requested else "","prayer_completed":w.story.prayed_day==day,"enemies":w.enemies.map(func(e):return {"role":e.role,"lv":e.lv}),"animals":w.campaign.animals.map(func(a):return {"species":a.species,"lv":a.lv,"hp":a.get("hp",0)}),"lost":w.campaign.animal_history.duplicate(true)})
				check(w.result in ["win","loss"],"Natural day terminates: %d/%s/%d"%[seed_value,mode,day])
				if w.result!="win":
					check(w.story.defeat_reason!="" and Save.restore(saved).campaign.day==day,"Loss is explained and the saved morning remains resumable: %d/%s"%[seed_value,mode])
					break
				morning=Farm.new(w.next_campaign(),w.seed_value+1)
			var report={"initial_seed":seed_value,"policy":mode,"days":days,"target_night":target,"reached_night":days[-1].day,"last_result":days[-1].result,"survival_target_met":days[-1].day==target and days[-1].result=="win"}
			reports.append(report)
			print("CAMPAIGN_OBSERVATION: ",JSON.stringify({"seed":seed_value,"policy":mode,"day":days[-1].day,"result":days[-1].result,"reason":days[-1].defeat_reason}))
	FileAccess.open("user://campaign-play.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":records,"reports":reports,"scope":"real fixed ticks and normal economy; seed increments like UI; technical termination is separate from survival and fun"},"  "))
	print("CAMPAIGN_PLAY: %d checks, failures=%d"%[checks,failures]);quit(1 if failures else 0)
