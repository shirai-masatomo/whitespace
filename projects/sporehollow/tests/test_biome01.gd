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
func run():
	var out=OS.get_environment("FARM_REVIEW_OUTPUT")
	if out=="" or "--isolated-review" not in OS.get_cmdline_user_args():quit(2);return
	check(load("res://game/board_art.gd")!=null,"Ground drawing compiles without a renderer")
	for seed_number in [1,17,31,97,2026]:
		var start=Time.get_ticks_usec()
		var w=Farm.new({},seed_number).begin_day();var twin=Farm.new({},seed_number).begin_day()
		check(w.terrain==twin.terrain and w.trees==twin.trees and w.rocks==twin.rocks and w.natural==twin.natural,"Same seed reproduces terrain and all natural targets: "+str(seed_number))
		var kinds={};var seen=reachable(w);var free_count=0;var center_trees=0
		for y in range(w.H):
			for x in range(w.W):
				var p=Vector2i(x,y);var label=w.Biome.kind(w,p);kinds[label]=kinds.get(label,0)+1
				if w.walkable(p):free_count+=1
				if w.trees.has(p) and w.Biome.clearing(Vector2(p),seed_number)<0.8:center_trees+=1
		check(kinds.size()==5,"Five terrain characters present: "+str(seed_number)+" "+str(kinds))
		check(center_trees==0 and w.keeper.pos.distance_to(Vector2i(25,17))<5,"Organic central opening and initial resident near idol: "+str(seed_number))
		check(seen.size()==free_count,"Every walkable cell connects to center: "+str(seed_number))
		check(w.Land.border_cells().all(func(p):return seen.has(p) or (w.rocks.has(p) and w.neighbors(p).any(func(n):return seen.has(n)))),"All four edges reachable or occupied by an adjacent-mineable rock: "+str(seed_number))
		check(w.entries.all(func(p):return seen.has(p)) and seen.has(w.logistics_entry) and w.Story.goals(w).any(func(p):return seen.has(p)),"Merchant, raid entries and idol approaches stay connected: "+str(seed_number))
		check(not w.trees.is_empty() and w.trees.keys().all(func(p):return w.Biome.field(w,p)[1]>0.4),"Trees belong to woodland: "+str(seed_number))
		check(not w.rocks.is_empty() and w.rocks.keys().all(func(p):return w.Biome.field(w,p)[2]>0.43),"Existing mine targets belong to rocky ground: "+str(seed_number))
		check(w.natural.values().all(func(k):return k in ["weed","mushroom","stump"]) and w.natural.size()<=w.nature_config.limit,"Only existing capped harvest kinds: "+str(seed_number))
		check(w.resource_amount("wood")==8 and w.resource_amount("stone")==0 and w.resource_amount("mushroom")==7 and w.campaign.last_supply_day==1,"Only the existing first-day supplies enter shared stock; natural deposits do not: "+str(seed_number))
		observations.append({"seed":seed_number,"terrain":kinds,"trees":w.trees.size(),"rocks":w.rocks.size(),"natural":w.natural.size(),"two_worlds_and_checks_ms":(Time.get_ticks_usec()-start)/1000.0})
	var w=Farm.new({},31).begin_day();w.story.intro_seen=true;w.enemies.clear();w.spawn_schedule.clear();w.nature_config.spawn_chance_per_second=0
	var rock=w.rocks.keys()[0];var amount=w.rocks[rock].amount
	var approach=w.neighbors(rock).filter(func(p):return w.walkable(p) and not w.occupied(p))
	w.keeper.pos=approach[0];w.keeper.satiety=100;w.keeper.sleepiness=0
	check(w.Tasks.designate(w,"mine",rock),"New deposit accepts existing mining designation")
	for i in range(200):
		w.step()
		if not w.rocks.has(rock):break
	check(not w.rocks.has(rock) and w.field_items.any(func(item):return item.kind=="stone" and item.pos==rock and item.get("mining_job_id",-1)>0),"Production mining creates physical stone at deposit")
	check(w.Stock.totals(w).get("stone",0)==amount,"Mining conserves the existing per-rock yield")
	var harvest=w.natural.keys()[0];w.natural.erase(harvest)
	w.persist_farm();var restored=Farm.new(w.campaign,31)
	check(restored.terrain==w.terrain and restored.natural==w.natural and restored.rocks==w.rocks and restored.trees==w.trees,"Campaign reload retains terrain, depleted mine and removed harvest")
	check(w.Snapshot.save(w,out+"/biome.snapshot"),"Full snapshot writes")
	var snapshot=w.Snapshot.restore(out+"/biome.snapshot")
	check(snapshot!=null and snapshot.terrain==w.terrain and snapshot.natural==w.natural and snapshot.rocks==w.rocks and snapshot.field_items==w.field_items,"Full snapshot preserves scenery and physical mine output")
	var legacy=w.campaign.duplicate(true);legacy.erase("biome_map");legacy.erase("biome_natural")
	var old=Farm.new(legacy,31)
	check(old.trees==w.trees and old.rocks==w.rocks and old.structures==w.structures and old.keeper.pos==w.keeper.pos and old.Stock.totals(old)==w.Stock.totals(w),"Legacy campaign receives scenery without regenerating saved objects or stock")
	check(not old.campaign.has("biome_new_map"),"Legacy load never becomes a fresh-map population request")
	var other=Farm.new({},97)
	check(other.terrain!=w.terrain,"Different seeds vary the landscape")
	var f=FileAccess.open(out+"/biome01.json",FileAccess.WRITE)
	f.store_string(JSON.stringify({"checks":checks,"failures":failures,"observations":observations,"visual_review":"not performed; delegated"},"\t"));f.close()
	print("Biome01: ",checks.size()," checks, ",failures," failures")
	quit(0 if failures==0 else 1)
