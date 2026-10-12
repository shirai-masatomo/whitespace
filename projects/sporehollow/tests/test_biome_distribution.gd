extends SceneTree
const Farm=preload("res://game/world.gd")
var checks=[]
var failures=0
var observations=[]
func _initialize():call_deferred("run")
func check(ok,note):
	checks.append({"passed":bool(ok),"check":note})
	if not ok:failures+=1;push_error(note)
func reachable(w) -> Dictionary:
	var seen={w.keeper.pos:true};var queue=[w.keeper.pos];var index=0
	while index<queue.size():
		var p=queue[index];index+=1
		for n in w.neighbors(p):
			if w.walkable(n) and not seen.has(n):seen[n]=true;queue.append(n)
	return seen
func excavatable(w,reached: Dictionary) -> bool:
	# Flood through rock only after reaching its edge: enclosed centres require excavation.
	var accessible=reached.duplicate();var queue=reached.keys();var index=0
	while index<queue.size():
		var p=queue[index];index+=1
		for n in w.neighbors(p):
			if not accessible.has(n) and w.rocks.has(n):accessible[n]=true;queue.append(n)
	return w.rocks.keys().all(func(p):return accessible.has(p))
func run():
	var out=OS.get_environment("FARM_REVIEW_OUTPUT")
	if out=="" or "--isolated-review" not in OS.get_cmdline_user_args():quit(2);return
	var chosen={"weed":0.0,"mushroom":0.0,"stump":0.0};var baseline={"weed":0.0,"mushroom":0.0,"stump":0.0};var counts={"weed":0,"mushroom":0,"stump":0}
	for seed_number in range(16):
		var w=Farm.new({},seed_number).begin_day();var reached=reachable(w);var walkable=0;var kinds={};var total_weight={"weed":0.0,"mushroom":0.0,"stump":0.0}
		for y in range(w.H):
			for x in range(w.W):
				var p=Vector2i(x,y);var label=w.Biome.kind(w,p);kinds[label]=kinds.get(label,0)+1
				if w.walkable(p):walkable+=1
				for resource in total_weight:total_weight[resource]+=w.Biome.resource_weight(w,p,resource)
		for p in w.natural:
			var resource=w.natural[p];chosen[resource]+=w.Biome.resource_weight(w,p,resource);baseline[resource]+=total_weight[resource]/1700.0;counts[resource]+=1
		check(kinds.size()==5,"All five landscape characters: seed "+str(seed_number))
		check(reached.size()==walkable and w.Land.border_cells().all(func(p):return reached.has(p)),"Generated natural cover leaves all walkable cells and perimeter connected: seed "+str(seed_number))
		check(excavatable(w,reached),"Every rock component can be excavated from a reachable edge: seed "+str(seed_number))
		for corner in [Vector2i.ZERO,Vector2i(49,0),Vector2i(0,33),Vector2i(49,33)]:
			if w.natural.has(corner):
				check(w.Jobs.build_reason(w,"wall",corner)!="","Existing harvest blocks corner construction until collected")
				w.nature_config.spawn_chance_per_second=0;w.story.intro_seen=true
				w.keeper.pos=w.neighbors(corner).filter(func(p):return w.walkable(p) and not w.occupied(p))[0]
				w.act("collect",corner)
				for i in range(160):
					w.step()
					if not w.natural.has(corner):break
				check(not w.natural.has(corner),"Existing gather job completes on the corner")
			check(w.Jobs.build_reason(w,"wall",corner)==("" if w.items_at(corner).is_empty() else "物があるため建設できません"),"Unchanged physical-item building eligibility at corner "+str(corner)+" seed "+str(seed_number)+" reason="+w.Jobs.build_reason(w,"wall",corner)+" natural="+str(w.natural.get(corner))+" rock="+str(w.rocks.has(corner)))
		observations.append({"seed":seed_number,"kinds":kinds,"trees":w.trees.size(),"rocks":w.rocks.size()})
	for resource in chosen:check(chosen[resource]>baseline[resource]*1.35,"Harvest locations favor their habitat over uniform placement: "+resource)
	# Retain generated terrain and targets while exercising actual visitors/raids.
	var w=Farm.new({},31).begin_day();w.story.intro_seen=true;w.nature_config.spawn_chance_per_second=0
	for i in range(22):w.step()
	check(w.request_merchant("keeper"),"Generated map accepts a real merchant approach")
	for i in range(180):
		w.step()
		if w.keeper.pos==w.merchant_approach:break
	check(w.keeper.pos==w.merchant_approach and w.merchant_waiting() and w.keeper.pos in w.merchant_talk_cells(),"Resident physically reaches merchant on generated map: "+str({"pos":w.keeper.pos,"market":w.market_open,"state":w.keeper.state,"reason":w.merchant_actor_reason("keeper"),"tick":w.tick,"worker":w.merchant_worker,"approach":w.merchant_approach}))
	w=Farm.new({},31).begin_day();w.story.intro_seen=true;w.nature_config.spawn_chance_per_second=0
	for p in [Vector2i(1,8),Vector2i(48,8),Vector2i(12,1),Vector2i(12,32)]:w.spawn_enemy({"entry":p,"role":"kidnapper","lv":1})
	for e in w.enemies:
		for i in range(30):w.enemy_step(e);w.tick+=1
	check(w.enemies.all(func(e):return w.inside(e.pos) and e.get("arrival_complete",false)),"Enemies from four sides enter the generated landscape")
	# Actual gathering uses the existing job and physical-stock path.
	w=Farm.new({},31).begin_day();w.story.intro_seen=true;w.nature_config.spawn_chance_per_second=0;w.enemies.clear();w.spawn_schedule.clear()
	var stump=w.natural.keys().filter(func(p):return w.natural[p]=="stump")[0];var wood_before=w.Stock.totals(w).get("wood",0)
	w.keeper.pos=w.neighbors(stump).filter(func(p):return w.walkable(p) and not w.occupied(p))[0]
	w.keeper.satiety=100;w.keeper.sleepiness=0
	check(w.act("collect",stump),"Generated stump accepts existing gathering designation")
	for i in range(160):
		w.step()
		if not w.natural.has(stump):break
	check(not w.natural.has(stump) and w.field_items.any(func(item):return item.kind=="wood" and item.pos==stump),"Gathered stump produces physical wood at its location")
	for i in range(3):
		w.persist_farm();w=Farm.new(w.campaign,31)
		check(not w.natural.has(stump) and w.Stock.totals(w).get("wood",0)==wood_before+w.Rules.NATURE.stump_wood,"Repeated reload does not respawn collected stump or duplicate wood: "+str(i))
	# Snapshot resume also preserves the next terrain-weighted growth decision.
	w=Farm.new({},31).begin_day();w.natural.clear();w.metrics.weed_spawned=0;w.metrics.mushroom_spawned=0;w.metrics.stump_spawned=0;w.nature_config.spawn_chance_per_second=1.0
	w.Snapshot.save(w,out+"/growth.snapshot");var restored=w.Snapshot.restore(out+"/growth.snapshot")
	w.grow_nature();restored.grow_nature()
	check(w.natural==restored.natural and w.nature_rng.state==restored.nature_rng.state,"Snapshot resumes identical weighted growth and RNG state")
	var f=FileAccess.open(out+"/biome-distribution.json",FileAccess.WRITE)
	f.store_string(JSON.stringify({"checks":checks,"failures":failures,"seeds":observations,"harvest_weight_observations":{"chosen":chosen,"uniform":baseline,"count":counts}},"\t"));f.close()
	print("Biome distribution: ",checks.size()," checks, ",failures," failures")
	quit(0 if failures==0 else 1)
