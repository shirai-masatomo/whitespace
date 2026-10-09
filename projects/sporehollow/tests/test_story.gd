extends SceneTree
const Farm=preload("res://game/world.gd")
var checks=0
var failures=0
var records=[]
func _initialize():call_deferred("run")
func check(ok: bool,text: String):
	checks+=1
	records.append({"check":text,"passed":ok})
	if not ok: failures+=1;push_error(text)
func quiet(day: int=1):
	var c=Farm.new_campaign();c.day=day
	var w=Farm.new(c,17).begin_day();w.config.legacy_prayer=true;w.day_seconds=10000;w.nature_config.spawn_chance_per_second=0
	w.animals[0].mode="rest";w.animals[0].order_until=999999
	return w
func drain(w,n: int=800):
	for i in range(n):
		if w.jobs.is_empty():return
		w.step()
func local(w,kind: String):
	w.keeper.pos=w.Story.goals(w)[0];w.Life.set_rest(w,false);w.Jobs.hold(w,"")
	return w.act(kind,w.Story.at(w))
func run():
	var w=quiet()
	check(not w.trees.is_empty() and w.Story.idol_cells(w).size()==4,"Real trees and 2x2 idol exist")
	check(w.story.prayers.is_empty() and w.spawn_schedule.all(func(e):return e.role not in ["idol_breaker","idol_extractor"]),"First night unrelated to prayer")
	check(w.keeper.pos not in w.Story.idol_cells(w) and w.animals.all(func(a):return a.pos not in w.Story.idol_cells(w) and not w.trees.has(a.pos)),"Initial occupants are safe")
	var p=w.trees.keys()[0];var id=w.trees[p]
	check(not w.walkable(p) and w.blocks_sight(p) and not w.is_indoor(p),"Trees block walking/sight but do not enclose rooms")
	check(w.Buildings.reason(w,"wall",p)=="先に開拓が必要","Construction preserves tool and explains tree obstacle")
	check(not w.act("remove",w.Story.at(w)) and not w.act("soil_tile",w.Story.at(w)),"Cannot dismantle or build over idol")
	w.paused=true
	check(not w.act("clear_tree",p) and w.jobs.is_empty(),"Bare-hand clearing cannot be queued")
	var tick=w.tick;var wood=w.wood
	for i in range(20):w.step()
	check(w.tick==tick and w.wood==wood and w.trees.has(p),"Pause preserves tree and resources")
	w.paused=false
	# Migration fixture: historic cleared IDs are retained, no new clearing ability.
	w.story.cleared.append(id);w.trees.erase(p)
	w.persist_farm();var restored=Farm.new(w.campaign,17)
	check(not restored.trees.has(p) and restored.wood==wood,"Historical cleared IDs persist without rewards")
	var rollback=Farm.new(w.morning_checkpoint,17)
	check(rollback.trees.has(p) and rollback.wood==0,"Morning retry restores trees AND resources")
	check(not local(w,"pray_wealth"),"Prayer locked before first night")
	local(w,"inspect_idol");drain(w)
	check(not w.story.investigated,"Investigating day one does not unlock prayer")
	var seen={}
	for seed in range(1,41):
		var world=Farm.new({},seed)
		for event in world.spawn_schedule:
			var exit=world.exit_for(event.entry);seen["left" if exit.x==0 else ("right" if exit.x==24 else ("top" if exit.y==0 else "bottom"))]=true
	check(seen.size()==4,"Seeded invasion plans cover all four sides")
	check(Farm.new({},17).spawn_schedule==Farm.new({},17).spawn_schedule,"Same seed/day yields identical raid plan")
	w=quiet(2);local(w,"inspect_idol");drain(w)
	check(w.story.investigated and w.story.radio,"After first night inspection unlocks prayer and radio is owned")
	var gold=w.campaign.gold
	w.start_night();w.spawn_schedule.clear()
	w.paused=true;check(local(w,"pray_wealth"),"Prayer can be planned while paused")
	w.step();check(w.story.prayers.is_empty() and w.campaign.gold==gold,"Prayer is not an immediate reward")
	w.paused=false;w.step();w.Life.hurt(w,{"id":99,"attack_power":1})
	check(w.story.prayers.is_empty() and w.jobs.is_empty(),"Hit interrupts prayer before commit")
	local(w,"pray_wealth");drain(w)
	check(w.story.prayers.size()==1 and w.campaign.gold==gold,"Three-second onsite prayer creates one pending miracle")
	check(not local(w,"pray_wealth"),"Daily prayer limit revalidated")
	w.Story.morning(w,3)
	check(w.campaign.gold==gold+60 and w.story.prayers[0].rewarded,"Dawn settles exactly +60G")
	var snapshot=JSON.stringify(w.story);w.Story.morning(w,3)
	check(w.campaign.gold==gold+60 and JSON.stringify(w.story)==snapshot,"Repeated dawn/radio reads cannot duplicate events or gold")
	w.Story.morning(w,5);w.make_schedule()
	check(w.spawn_schedule.any(func(e):return e.role=="idol_breaker"),"Delayed security event materially adds idol attackers")
	var histories=[]
	for prayers in [0,1,3]:
		var c=quiet(2);c.story.investigated=true
		for day in range(2,7):
			c.campaign.day=day
			if day-2<prayers:c.Story.pray(c)
			c.Story.morning(c,day+1)
		c.make_schedule();histories.append({"prayers":prayers,"gold":c.campaign.gold,"news":c.story.news.size(),"roles":c.spawn_schedule.map(func(e):return e.role),"hidden":c.story.hidden.duplicate(true)})
	check(histories[0].roles.size()<histories[1].roles.size() and histories[1].roles.size()<histories[2].roles.size(),"Same seed no/one/repeated wishes change actual raids")
	check("idol_extractor" in histories[2].roles and histories[0].hidden.karma==0,"Repeated wishes unlock actual extraction, no-prayer remains independent")
	w=quiet(2);w.start_night();w.spawn_schedule.clear()
	w.spawn_enemy({"entry":Vector2i(1,5),"role":"idol_breaker"});var e=w.enemies[-1]
	check(e.pos==Vector2i(-24,5),"Invader begins outside, not inside the farm")
	e.pos=w.Story.goals(w)[0];e.next_attack=0
	var hp=w.story.idol.hp;w.enemy_step(e)
	check(w.story.idol.hp<hp,"Idol attacker inflicts object damage")
	w.tick=w.night_started_tick+ceili(w.config.duration_seconds/w.DT) if w.config.has("duration_seconds") else 10000
	w.step();check(w.phase=="defend","Dawn cannot erase an active idol threat")
	w.Story.damage(w,999);check(w.result=="loss" and w.story.defeat_reason=="idol_destroyed","Idol HP0 is a specific defeat")
	w=quiet(2);w.start_night();w.spawn_schedule.clear();w.keeper.pos=Vector2i(6,10)
	w.spawn_enemy({"entry":Vector2i(12,1),"role":"idol_extractor"});e=w.enemies[-1]
	e.pos=Vector2i(12,7);w.Story.idol_enemy(w,e)
	check(w.story.idol.state=="preparing","Extractor begins separate unfastening state")
	for i in range(32):w.Story.idol_enemy(w,e)
	check(w.story.idol.state=="transporting","Eight-second preparation precedes towing")
	var before=w.Story.at(w)
	for i in range(16):w.tick+=1;w.Story.idol_enemy(w,e)
	check(w.Story.at(w)!=before and w.Story.idol_cells(w).size()==4 and e.carry=="","Towing preserves footprint; no keeper carry sprite/state")
	e.flee=true;w.Story.tick(w)
	check(w.story.idol.state=="interrupted" and w.Story.at(w)!=before,"Defeated hauler leaves idol where interrupted")
	var stopped=w.Story.at(w);local(w,"recover_idol");drain(w)
	check(w.story.idol.state=="recovered" and w.Story.at(w)==stopped,"Onsite recovery anchors idol without teleport")
	w=quiet(2);w.start_night();w.spawn_schedule.clear();w.keeper.pos=Vector2i(6,10)
	w.spawn_enemy({"entry":Vector2i(12,1),"role":"idol_extractor"});e=w.enemies[-1];e.pos=Vector2i(12,7)
	for i in range(200):
		w.tick+=1;w.Story.idol_enemy(w,e)
		if w.result!="":break
	check(w.result=="loss" and w.story.defeat_reason=="idol_stolen","Full footprint crossing fixed boundary loses idol")
	w=quiet();w.start_night();w.spawn_enemy({"entry":Vector2i(23,8),"role":"kidnapper"});e=w.enemies[-1]
	e.carry="keeper";w.keeper.carrier=e.id;w.keeper.state="captured";e.pos=Vector2i(22,8);w.keeper.pos=e.pos
	check(w.result=="" and w.inside(e.pos),"Carrying inside forest is not boundary defeat")
	w.release_keeper(e);check(w.keeper.carrier<0 and w.result=="","Existing rescue works inside forest")
	e.carry="keeper";w.keeper.carrier=e.id;e.pos=Vector2i(23,8);w.keeper.pos=e.pos
	w.move_enemy(e,Vector2i(24,8));check(w.result=="loss" and w.story.defeat_reason=="keeper_abducted","Keeper loss is fixed boundary crossing")
	# Reconstruct a real next morning, then retry that same checkpoint after another wish.
	w=quiet(2);w.story.investigated=true;w.start_night();w.spawn_schedule.clear();local(w,"pray_wealth");drain(w)
	w.start_night();w.spawn_schedule.clear();w.finish(true)
	var next=Farm.new(w.next_campaign(),17)
	var morning_gold=next.campaign.gold;var morning_story=next.story.duplicate(true)
	w=next.begin_day();w.start_night();w.spawn_schedule.clear();local(w,"pray_wealth");drain(w)
	var retry=Farm.new(w.morning_checkpoint,17)
	check(retry.campaign.gold==morning_gold and retry.story==morning_story,"Morning retry restores miracle, prayer IDs, reactions and money atomically")
	# Current clearing is disabled; old TreeIDs remain data, not a free reward.
	w=quiet();p=w.trees.keys()[0]
	check(not w.act("clear_tree",p) and w.trees.has(p),"No new clearing across phase boundaries")
	# Seal every edge with constructed walls; spawn still occurs outside and attacks an obstacle.
	w=quiet();w.start_night();w.spawn_schedule.clear()
	for y in range(1,w.H-1):
		for x in range(1,w.W-1):
			if x in [1,w.W-2] or y in [1,w.H-2]:site(w,"wall",Vector2i(x,y))
	for entry in [Vector2i(1,5),Vector2i(23,8),Vector2i(12,1),Vector2i(19,15)]:
		w.spawn_enemy({"entry":entry,"role":"kidnapper"});e=w.enemies[-1]
		check(not w.inside(e.pos) and w.distance(e.pos,w.exit_for(entry))==24,"Sealed edge still spawns outside: "+str(entry))
		for i in range(200):
			if e.pos==w.exit_for(entry):break
			w.enemy_step(e)
		var wallhp=w.structures[entry].hp;w.move_enemy(e,entry)
		check(e.pos==w.exit_for(entry) and w.structures[entry].hp<wallhp,"Invader damages barrier before entering: "+str(entry))
	# A 2x2 idol cannot squeeze through a one-cell forest corridor.
	w=quiet();w.trees.clear()
	for y in range(1,w.H-1):
		if y!=8:w.trees[Vector2i(10,y)]="fixture-tree-%d"%y
	check(w.Story.tow_path(w,Vector2i(12,8),Vector2i(-1,8),Vector2i(0,-1)).is_empty(),"Whole idol and hauler reject one-cell bottleneck")
	w.spawn_enemy({"entry":Vector2i(1,8),"role":"idol_extractor"});e=w.enemies[-1]
	check(not w.Story.tow_route(w,e,Vector2i(12,8),Vector2i(0,-1)).is_empty(),"Blocked preferred edge can choose another reachable extraction edge")
	# No destructive migration when the central safe candidates have been used.
	w=quiet();w.story.clear();w.campaign.erase("world_story")
	for at in [Vector2i(12,8),Vector2i(10,8),Vector2i(14,8),Vector2i(12,6)]:site(w,"soil_tile",at)
	w.persist_farm();w.campaign.erase("world_story");w.campaign.night_ready=false
	var migrated=Farm.new(w.campaign,17)
	check(migrated.story.has("migration_error") and migrated.floors.size()==4 and migrated.begin_day()==null,"Unsafe legacy migration preserves land and blocks play with explicit reason")
	w=quiet();w.start_night();w.spawn_schedule.clear();w.spawn_enemy({"entry":Vector2i(1,5),"role":"kidnapper"});e=w.enemies[-1];e.capture_progress=1
	w.finish(true);check(w.phase=="defend" and w.result=="","Dawn cannot erase kidnapping preparation")
	var file=FileAccess.open("user://story-observation.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"checks":records,"same_seed_comparison":histories},"  "))
	print("STORY: ",checks," checks, failures=",failures)
	quit(1 if failures else 0)

func site(w,kind: String,p: Vector2i):
	var d=w.BUILD[kind]
	w.Buildings.layer(w,kind)[p]={"id":w.next_structure_id,"kind":kind,"hp":d.hp,"max_hp":d.hp,"status":"ready","open":false,"armor":0,"cost":d.cost,"resource":d.get("resource","soil"),"lock_hp":d.get("lock_hp",0),"max_lock_hp":d.get("lock_hp",0)}
	w.next_structure_id+=1
