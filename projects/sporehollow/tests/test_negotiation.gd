extends SceneTree
const Farm=preload("res://game/world.gd")
var checks=[]
var failed=0
func _initialize():call_deferred("run")
func check(ok,note):
	checks.append({"passed":bool(ok),"check":note})
	if not ok:failed+=1;push_error(note)
func fixture():
	var w=Farm.new({},31).begin_day();w.campaign.day=2;w.calendar_ticks=w.Cycle.Clock.TICKS_PER_DAY;w.last_daily_day=2;w.story.intro_seen=true;w.tick=24;w.paused=false
	w.enemies.clear();w.spawn_schedule.clear();w.trees.clear();w.rocks.clear();w.natural.clear();w.structures.clear();w.floors.clear();w.nature_config.spawn_chance_per_second=0
	w.keeper.pos=Vector2i(10,7);w.keeper.sleepiness=0;w.keeper.satiety=100
	for a in w.animals:a.pos=Vector2i(22,22);a.home=a.pos;a.order=a.pos;a.mode="stay"
	return w
func support(w):
	w.add_resident({"id":91,"species":"maid","category":"human","lv":1,"hp":45,"rarity":"common","xp":0,"loyalty":85,"traits":{},"name":"検証住人","affinity":null,"unavailable_through_day":0,"position":[10,9]})
	var a=w.animals.back();a.pos=Vector2i(10,9);a.placed=true;return a
func run():
	var out=OS.get_environment("FARM_REVIEW_OUTPUT")
	if out=="" or "--isolated-review" not in OS.get_cmdline_user_args():quit(2);return
	# 1. Explicit keeper instruction interrupts one real claim; UI close releases it for reevaluation.
	var w=fixture();w.Zones.create(w,"stockpile",w.keeper.pos,w.keeper.pos);w.Stock.add(w,"wood",12,w.keeper.pos).stocked=true;w.Jobs.enqueue(w,"wood_wall",Vector2i(15,7),-1);var original=w.jobs.back();w.Work.claim(w,"keeper",original);w.Jobs.execute(w,original,w.keeper)
	check(w.request_merchant("keeper") and original.state=="suspended" and original.assigned_to=="" and w.Stock.cargo(w,"keeper",original.id).is_empty(),"Keeper negotiation releases the real construction/material claim without deleting the old designation")
	var target=w.merchant_approach;var start=w.keeper.pos;var route=[]
	for i in range(80):
		w.step();route.append(w.keeper.pos)
		if w.keeper.pos==target:break
	check(w.keeper.pos==target and route[0]!=target and w.jobs.has(original),"Keeper walks through the existing movement job and reaches merchant without teleporting")
	w.market_open=true;var tick=w.tick;w.step();check(w.tick==tick,"Open shop freezes world time")
	w.cancel_merchant();w.market_open=false
	# Construction resumes through physical material delivery before assembly.
	for i in range(240):
		w.step()
		if w.Work.active(w).get("id",-1)==original.id:break
	check(w.Work.active(w).get("id",-1)==original.id and not w.jobs.any(func(j):return j.get("purpose")=="merchant"),"Closing conversation permits delivery then the suspended construction job to be reclaimed")
	# 2. Supporting resident ownership must not silently enlist it as an ordinary worker.
	w=fixture();var a=support(w);var keeper_start=w.keeper.pos
	check(w.request_merchant("a91") and not w.workers.has("a91"),"Selected support resident owns negotiation without joining the general worker registry")
	target=w.merchant_approach;w.merchant_leave_at=w.tick*w.DT+0.5
	for i in range(80):
		w.step()
		if a.pos==target:break
	check(a.pos==target and w.keeper.pos==keeper_start and w.merchant_present(),"Selected support resident walks, keeper stays put, and merchant waits beyond normal departure")
	w.cancel_merchant();w.step()
	check(not w.workers.has("a91") and a.get("action_id","")!="" and not w.jobs.any(func(j):return j.get("purpose")=="merchant"),"Support AI resumes after negotiation and is never assigned general work")
	# 3. Refusals and interruption release jobs/claims instead of stranding the actor.
	w=fixture();check(not w.request_merchant("") and w.jobs.is_empty(),"Missing selected person cannot create an order")
	w.keeper.drafted=true;check("徴兵" in w.merchant_reason("keeper") and not w.request_merchant("keeper"),"Drafted resident is rejected with a reason")
	w.keeper.drafted=false;w.keeper.forced_rest=true;check(not w.request_merchant("keeper"),"Incapacitated resident cannot negotiate")
	w.keeper.forced_rest=false
	for p in w.merchant_talk_cells():w.trees[p]=99
	check("通路" in w.merchant_reason("keeper") and not w.request_merchant("keeper"),"Unreachable merchant is rejected before creating a move job")
	w.trees.clear();w.request_merchant("keeper");w.keeper.hp-=1;w.step()
	check(w.merchant_worker=="" and w.jobs.is_empty() and w.work_claims.is_empty(),"Damage cancels negotiation and releases its movement reservation")
	w.request_merchant("keeper");w.merchant_arrive_tick=w.tick+100;w.step()
	check(w.merchant_approach==null and w.jobs.is_empty(),"Merchant disappearance cancels negotiation without a stale job")
	# 4. Saving while walking/conversing discards only the transient conversation on load.
	for in_shop in [false,true]:
		w=fixture();a=support(w);w.Jobs.enqueue(w,"move",Vector2i(16,7),-1);w.request_merchant("a91");w.market_open=in_shop
		w.Snapshot.save(w,out+"/negotiation.snapshot");var restored=w.Snapshot.restore(out+"/negotiation.snapshot")
		check(not restored.market_open and restored.merchant_approach==null and not restored.workers.has("a91") and restored.jobs.size()==1 and restored.work_claims.is_empty(),"Save/load clears transient negotiation and preserves unrelated job: shop="+str(in_shop))
	FileAccess.open(out+"/negotiation.json",FileAccess.WRITE).store_string(JSON.stringify({"method":"Four controlled production World.step groups; no physical OS input or human play","checks":checks,"failures":failed},"\t"))
	print("Negotiation: ",failed," failures");quit(1 if failed else 0)
