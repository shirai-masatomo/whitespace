extends SceneTree
const Farm=preload("res://game/world.gd")
var checks=[]
var beds=[]
var bench=Vector2i(-1,-1)
var bills=[]
var seed_value=31
var humans=1
var policy="gather"
var economy=false
var chunk=1
var meals={}
var work_ticks={}
var hunger_ticks={}
func _initialize():call_deferred("run")
func check(ok,note):checks.append({"passed":bool(ok),"check":note})
func food_energy(w):
	var n=0.0
	for r in w.field_items:
		if r.kind in w.Work.Policy.HUMAN_FOOD:n+=r.amount*w.Needs.Data.FOOD[r.kind].satiety
	return n
func take(w):
	var people={};var starvation=0
	for key in w.workers:
		var a=w.workers[key]
		people[key]={"hp":a.hp,"satiety":a.satiety,"malnutrition":a.get("malnutrition",0),"state":a.state,"dead":a.get("dead",false),"status":a.work_status,"hunger_ticks":hunger_ticks.get(key,0),"meals":meals.get(key,0)}
		if a.get("dead",false) or a.get("nutrition_down",false):starvation+=1
	var grown=0;var cooked=0
	for j in bills:
		if j.recipe=="grow_mushroom":grown+=j.made
		else:cooked+=j.made
	return {"tick":w.tick,"day":w.campaign.day,"stock":w.Stock.totals(w),"stored_food":w.Work.Policy.HUMAN_FOOD.map(func(kind):return {"kind":kind,"stored":w.Stock.summary(w,kind).stored}),"food_energy":food_energy(w),"used":w.stock_used.duplicate(),"people":people,"nutrition_down_or_dead":starvation,"grown":grown,"cooked":cooked,"built":w.metrics.built,"work_ticks":work_ticks.duplicate(),"gathered":w.metrics.mushroom_collected,"cultivation_policy":"two beds per person, count12 per bed; cooking target10 portions/person", "pending_jobs":w.jobs.map(func(j):return {"kind":j.kind,"recipe":j.get("recipe",""),"state":j.state,"reason":j.get("block_reason","")}),"beds_ready":beds.filter(func(q):return w.structures.get(q,{}).get("status")=="ready").size(),"loss":w.result,"reason":w.story.get("defeat_reason",""),"idol_hp":w.story.idol.hp,"living_enemies":w.enemies.filter(func(e):return not e.done and e.hp>0).size()}
func manage(w):
	if policy=="none":return
	for q in w.natural:
		if w.natural[q]=="mushroom" and not w.natural_forbidden.get(q,false) and not w.jobs.any(func(j):return j.kind=="collect" and j.pos==q):w.act("collect",q)
	for q in beds+([bench] if bench.x>=0 else []):
		var b=w.structures.get(q,{})
		if b.get("status")!="ready" or bills.any(func(j):return j.get("bench_id",-1)==b.id):continue
		var recipe="grow_mushroom" if b.kind=="mushroom_bed" else "roast_mushroom"
		if w.Craft.enqueue(w,q,recipe,"count" if recipe=="grow_mushroom" else "stock",12 if recipe=="grow_mushroom" else humans*10):bills.append(w.jobs.back())
func run():
	if DisplayServer.get_name()!="headless" or OS.get_environment("FARM_REVIEW_OUTPUT")=="":quit(2);return
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--seed="):seed_value=int(arg.trim_prefix("--seed="))
		if arg.begins_with("--humans="):humans=int(arg.trim_prefix("--humans="))
		if arg.begins_with("--policy="):policy=arg.trim_prefix("--policy=")
		economy=economy or arg=="--economy"
		if arg.begins_with("--chunk="):chunk=int(arg.trim_prefix("--chunk="))
	var stem=OS.get_environment("FARM_REVIEW_OUTPUT")+"/phase2-day-%d-%d-%s%s"%[seed_value,humans,policy,"-economy" if economy else ""]
	var started=Time.get_ticks_msec();var initial={};var invalid="";var samples=[];var seen3={};var cpu=[];var elapsed=0.0;var w
	if chunk==1:
		w=Farm.new({},seed_value).begin_day();initial=take(w)
		# Extra people are explicit fixtures. No added supplies, tools, HP healing or prayer.
		for n in range(1,humans):
			var a=w.keeper.duplicate(true);a.id=-10-n;a.name="検証住民%d"%n;a.pos=w.keeper.pos+Vector2i(n,2);a.appetite="normal";a.auto_collect=true;w.Work.register(w,"resident%d"%n,a)
		if policy in ["grow","cook"]:
			var kinds=[]
			for n in range(humans*2 if policy=="grow" else 1):kinds.append("mushroom_bed" if policy=="grow" else "cooking_bench")
			var choices=[]
			for x in range(41,61):
				for y in range(26,43):choices.append(Vector2i(x,y))
			choices.sort_custom(func(a,b):return w.distance(a,w.keeper.pos)<w.distance(b,w.keeper.pos) if w.distance(a,w.keeper.pos)!=w.distance(b,w.keeper.pos) else a.y*100+a.x<b.y*100+b.x)
			for kind in kinds:
				for q in choices:
					if w.act(kind,q):
						if kind=="mushroom_bed":beds.append(q)
						else:bench=q
						break
			var trees=w.trees.keys();trees.sort_custom(func(a,b):return w.distance(a,w.keeper.pos)<w.distance(b,w.keeper.pos))
			var wood_jobs=0
			for q in trees:
				if w.act("clear_tree",q):wood_jobs+=1
				if wood_jobs>=(3 if policy=="grow" and humans>1 else 1):break
	else:
		w=Farm.Snapshot.restore(stem+".snapshot")
		if w==null:push_error("Chunk snapshot missing");quit(1);return
		var file=FileAccess.open(stem+".state",FileAccess.READ);var state=file.get_var(false)
		beds=state.beds;bench=state.bench;meals=state.meals;work_ticks=state.work_ticks;hunger_ticks=state.hunger_ticks
		initial=state.initial;samples=state.samples;seen3=state.seen3;cpu=state.cpu;elapsed=state.elapsed
		for old in state.bills:
			var live=w.jobs.filter(func(j):return j.id==old.id);bills.append(live[0] if not live.is_empty() else old)
	var start_tick=w.tick
	var wall_limit=45000
	for i in range(1728):
		if economy:w.spawn_schedule=[] # Declared supply-only comparison, not survival victory.
		if i%64==0:manage(w)
		var previous={}
		for key in w.workers:previous[key]=w.workers[key].get("meal_remaining",0)
		var timer=Time.get_ticks_usec();w.step();cpu.append((Time.get_ticks_usec()-timer)/1000.0)
		for key in w.workers:
			var a=w.workers[key];var label=a.get("life_need","") if a.get("life_need","")!="" else a.get("work_status","待機")
			if a.get("asleep",false):label="sleep"
			elif w.build_deliveries.has(key):label="construction_delivery"
			elif not w.Work.active(w,key).is_empty():label=w.Work.active(w,key).kind
			work_ticks[label]=work_ticks.get(label,0)+1
			if previous[key]==1:meals[key]=meals.get(key,0)+1
			if a.satiety<=0:hunger_ticks[key]=hunger_ticks.get(key,0)+1
		if i%128==0:
			var ids={};var stockids={}
			for j in w.jobs:
				if ids.has(j.id):invalid="duplicate job"
				ids[j.id]=true
			for r in w.field_items:
				if stockids.has(r.stock_id) or r.amount<=0:invalid="invalid physical item"
				stockids[r.stock_id]=true;var claimed=0
				for n in r.claims.values():claimed+=n
				if claimed>r.amount:invalid="overclaimed"
			for key in w.workers:
				var cargo=0
				for r in w.Stock.cargo(w,key):cargo+=r.amount
				if cargo>20:invalid="cargo>20"
			for q in w.storage_cells:
				if w.Stock.storage_used(w,q)>40:invalid="storage>40"
			if w.jobs.size()>100:invalid="jobs>100"
			await process_frame
			if Time.get_ticks_msec()-started>wall_limit:invalid="bounded CPU scenario timeout";break
		if w.tick==5184:seen3=take(w)
		if w.tick%1728==0:samples.append(take(w))
		if not w.working():break
	check(invalid=="","Physical IDs/claims/capacity/time budget: "+invalid)
	check(w.tick==start_tick+1728 or w.result=="loss","One-day chunk advanced or normal defeat explained")
	check(w.story.get("prayed_day",-1)<=0,"No prayer/debug supplies used")
	var final=take(w);cpu.sort();var sum=0.0
	for ms in cpu:sum+=ms
	var record={"seed":seed_value,"policy":policy,"humans":humans,"economy_fixture":economy,"scope":"Production generated map and World.step; extra residents are explicit fixtures, no free materials or prayer. Economy fixture suppresses scheduled raids only." ,"initial":initial,"night3":seen3,"night5":final,"samples":samples,"checks":checks,"failures":checks.filter(func(c):return not c.passed).size(),"wall_seconds":elapsed+(Time.get_ticks_msec()-started)/1000.0,"chunk":chunk,"chunk_seconds":(Time.get_ticks_msec()-started)/1000.0,"cpu_step_ms":{"mean":sum/maxi(1,cpu.size()),"p99":cpu[int((cpu.size()-1)*.99)],"max":cpu[-1]}}
	FileAccess.open(stem+".json",FileAccess.WRITE).store_string(JSON.stringify(record,"  "))
	if invalid=="":
		if not w.Snapshot.save(w,stem+".snapshot"):push_error("Cannot save bounded-test snapshot");quit(1);return
		var metadata={"beds":beds,"bench":bench,"bills":bills,"meals":meals,"work_ticks":work_ticks,"hunger_ticks":hunger_ticks,"initial":initial,"samples":samples,"seen3":seen3,"cpu":cpu,"elapsed":record.wall_seconds}
		FileAccess.open(stem+".state",FileAccess.WRITE).store_var(metadata,false)
	print("PHASE2_DAY ",seed_value," ",humans," ",policy," tick=",w.tick," hp=",w.keeper.hp," satiety=",w.keeper.satiety," grown=",final.grown," cooked=",final.cooked," invalid=",invalid)
	quit(1 if record.failures else 0)
