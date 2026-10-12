extends SceneTree
const Farm=preload("res://game/world.gd")
const Present=preload("res://game/colony_ui_state.gd")
const Model=preload("res://game/colony_view_model.gd")
var checks=[]
var failures=0
var observations=[]
func _initialize():call_deferred("run")
func check(ok,note):
	checks.append({"passed":bool(ok),"check":note})
	if not ok:failures+=1;push_error(note)
func farm():
	var c=Farm.new_campaign();c.animals.append({"id":2,"species":"hen","category":"bird","lv":1,"xp":0,"loyalty":0,"position":[16,14]})
	var w=Farm.new(c,31).begin_day();w.story.intro_seen=true;w.paused=false;w.enemies.clear();w.spawn_schedule.clear();w.natural.clear();w.trees.clear();w.rocks.clear();w.structures.clear();w.floors.clear();w.field_items.clear();w.jobs.clear();w.zones=[];w.storage_cells=[];w.nature_config.spawn_chance_per_second=0
	w.keeper.pos=Vector2i(10,10);w.keeper.satiety=100;w.keeper.sleepiness=0
	for a in w.animals:a.pos=Vector2i(16,14) if a.species=="hen" else Vector2i(12,10);a.home=a.pos;a.mode="stay";a.order_until=99999
	return w
func advance(w,n):
	for i in range(n):w.step()
func enemy(w):
	w.spawn_enemy({"entry":Vector2i(0,10),"archetype":"kidnapper","role":"kidnapper"});return w.enemies.back()
func run():
	var out=OS.get_environment("FARM_REVIEW_OUTPUT")
	if out=="" or "--isolated-review" not in OS.get_cmdline_user_args():quit(2);return
	for kind in ["train","slaughter"]:
		for animal_on in [false,true]:
			var w=farm();var dog=w.Orders.animal(w,1);var hen=w.Orders.animal(w,2);var loyalty=dog.loyalty
			for category in w.Work.Policy.ORDER:w.Work.set_priority(w,"keeper",category,0)
			w.Work.set_priority(w,"keeper","animal",1 if animal_on else 0);w.Work.set_priority(w,"keeper","other",0 if animal_on else 1)
			var accepted=w.Tasks.designate(w,kind,Vector2i.ZERO,1) if kind=="train" else w.Livestock.designate(w,2)
			check(accepted and w.Work.category(w,w.jobs[0])=="animal" and Model.job_category(w,w.jobs[0])=="動物",kind+" uses one canonical animal category")
			advance(w,140)
			check((dog.loyalty>loyalty if kind=="train" else hen.get("slaughtered",false))==animal_on,kind+" runs only for animal1/other0; not animal0/other1")
			if not animal_on:
				check(w.jobs.size()==1 and w.jobs[0].get("work_elapsed",0)==0 and "停止" in Present.category_hint(w,kind),kind+" remains queued with the disclosed disabled category")
				w.Work.set_priority(w,"keeper","animal",1);w.Work.set_priority(w,"keeper","other",0);advance(w,140)
				check(dog.loyalty>loyalty if kind=="train" else hen.get("slaughtered",false),kind+" resumes when the correct category is enabled")
	var w=farm();w.Zones.create(w,"stockpile",Vector2i(10,9),Vector2i(10,9));w.Stock.add(w,"soil",40,Vector2i(10,9));w.act("wall",Vector2i(8,10))
	check(w.Work.set_drafted(w,"keeper",true),"Healthy keeper can be drafted")
	for paused in [false,true]:
		w.paused=paused;var jobs=w.jobs.duplicate(true)
		check(not w.act("keeper_rest") and not w.act("resume_jobs") and not w.keeper.has("pending_command") and w.jobs==jobs,"Drafted keeper rejects rest/resume without changing jobs: paused="+str(paused))
		check(not w.HumanCombat.equip(w,"wood_staff") and not w.act("rest_until_night"),"Drafted keeper rejects equipment and bulk rest")
	w.paused=false;advance(w,20);check(w.metrics.built==0,"Normal work does not execute while drafted")
	check(w.act("keeper_move",Vector2i(11,10)),"Drafted direct movement remains available")
	advance(w,12);check(w.keeper.pos==Vector2i(11,10),"Drafted direct movement executes physically")
	w.Work.set_drafted(w,"keeper",false);advance(w,120);check(w.metrics.built==1,"Undrafting permits the existing wall designation to finish")
	w=farm();w.Life.set_rest(w,true);w.keeper.pending_command={"kind":"keeper_rest","pos":Vector2i.ZERO}
	w.Work.set_drafted(w,"keeper",true);check(not w.keeper.resting and not w.keeper.has("pending_command"),"Drafting ends voluntary sleep and removes old queued rest")
	w=farm();w.keeper.forced_rest=true;check(not w.Work.set_drafted(w,"keeper",true) and not w.keeper.drafted,"Forced sleeper cannot be drafted")
	w=farm();w.calendar_ticks=1100;w.phase="day"
	check(Present.rest_target(w)=="dawn" and not w.act("rest_until_night"),"20:16 selects dawn and rejects daytime skip even if legacy phase says day")
	w.spawn_schedule=[{"tick":w.tick+100,"role":"kidnapper","entry":Vector2i(0,10)}];w.schedule_index=0
	check(not w.act("end_night") and "予定" in w.Life.rest_until_reason(w,"dawn"),"Pending raids block overnight rest")
	w.spawn_schedule.clear();var e=enemy(w)
	check(not w.act("end_night") and "敵" in w.Life.rest_until_reason(w,"dawn"),"Living threat blocks overnight rest")
	e.hp=0;e.dead=true;e.done=false;e.revivable=true
	check(w.act("end_night"),"Only a corpse remains: normal fixed-tick dawn rest can be planned")
	w=farm();w.paused=true;w.keeper.sleepiness=50
	check(w.act("rest_until_night") and w.rest_skip.pending,"Pause permits a rest plan")
	var tick=w.tick;w.step();check(w.tick==tick and not w.keeper.resting,"Paused rest plan does not advance or begin sleep")
	w.paused=false;advance(w,22);check(w.keeper.resting and w.keeper.get("asleep",false),"Rest plan enters the existing delayed sleep calculation")
	w.Life.danger(w,"review02");w.step();check(w.rest_skip.is_empty(),"Danger stops time forwarding")
	w=farm();w.calendar_ticks=1727;w.phase="defend";w.keeper.sleepiness=100;w.keeper.forced_rest=true;w.Life.set_rest(w,true,"forced");w.act("end_night");w.step()
	check(w.Cycle.period(w)=="morning" and w.keeper.forced_rest and w.keeper.resting,"Dawn does not wake a forced sleeper before its recovery condition")
	w=farm();var row=w.Stock.add(w,"soil",40,Vector2i(11,10));var actor=w.keeper
	w.Stock.reserve(w,"soil",8,"job:7",actor,row.stock_id,false);var cargo=w.Stock.pickup(w,row,"job:7",actor,7)
	var s=w.Stock.summary(w,"soil");observations.append({"stage":"carry8","summary":s.duplicate(true)})
	check(s.owned==40 and s.available==0 and s.carried==8 and s.stored==0,"40 owned with 8 carried; remaining off-stock 32 are not yet usable")
	w.Zones.create(w,"stockpile",Vector2i(11,10),Vector2i(11,10));s=w.Stock.summary(w,"soil");observations.append({"stage":"remaining_ground_in_stockpile","summary":s.duplicate(true)})
	check(s.owned==40 and s.available==0 and s.stored==0 and s.carried==8,"Painting storage over uncollected goods does not mark a physical receipt")
	# The ledger fixture now represents delivery back into that cell; real hauling is covered separately.
	row.stocked=true;w.Stock.sync(w);s=w.Stock.summary(w,"soil")
	check(s.available==32 and s.stored==32,"A completed receipt makes the remaining physical stack shared stock")
	var helper=actor.duplicate(true);helper.pos=Vector2i(12,10);w.Work.register(w,"helper",helper)
	w.Stock.reserve(w,"soil",4,"job:8",helper,row.stock_id);w.Stock.pickup(w,row,"job:8",helper,8);s=w.Stock.summary(w,"soil")
	check(s.owned==40 and s.available==28 and s.carried==12 and s.stored==28,"Two workers use the same shared stock without duplicating the total")
	w.Stock.consume(w,"soil",10);s=w.Stock.summary(w,"soil");observations.append({"stage":"consumed10","summary":s.duplicate(true)})
	check(s.owned==30 and s.available==18 and s.carried==12 and s.stored==18,"Consumption reduces total, while moving material does not")
	w=farm();e=enemy(w);e.flee=true
	check(Present.threats(w).is_empty(),"Harmless retreat is not a residual combat threat")
	e.carry="animal";check(Present.threats(w).size()==1,"An abducting retreat remains a threat")
	e.hp=0;e.dead=true;check(Present.threats(w).is_empty(),"Dead enemy is not reported as a living residual threat")
	FileAccess.open(out+"/review02.json",FileAccess.WRITE).store_string(JSON.stringify({"method":"Controlled production World.step, Work, Life and physical shared stock; no human play","checks":checks,"failures":failures,"stock_observations":observations},"\t"))
	print("Review02: ",checks.size()," checks, ",failures," failures");quit(1 if failures else 0)
