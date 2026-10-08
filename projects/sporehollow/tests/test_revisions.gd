extends SceneTree
const Farm=preload("res://game/world.gd")
var checks=0
var failures=0
var observations={}
func _initialize(): call_deferred("run")
func check(value: bool, why: String):
	checks+=1
	if not value: failures+=1; push_error(why)
func fresh():
	var config=Farm.StageData.STAGES[1].duplicate(true)
	config.day_seconds=9999.0; config.first_attack_seconds=99999.0
	var w=Farm.new({},17,config).begin_day()
	w.materials=500;w.wood=500;w.stone=500
	w.nature_config.spawn_chance_per_second=0
	return w
func steps(w,n):
	for i in range(n): w.step()
func drain(w,n=500):
	for i in range(n):
		if w.jobs.is_empty(): return
		w.step()
func site(w,kind,p):
	var d=w.BUILD[kind]
	w.Buildings.layer(w,kind)[p]={"id":w.next_structure_id,"kind":kind,"hp":d.hp,"max_hp":d.hp,"status":"ready","open":false,"armor":0,"cost":d.cost,"resource":d.get("resource","soil"),"lock_hp":d.get("lock_hp",0),"max_lock_hp":d.get("lock_hp",0)}
	w.next_structure_id+=1
func room(w,offset: Vector2i):
	for y in range(5):
		for x in range(5): site(w,"wall" if x in [0,4] or y in [0,4] else "soil_tile",offset+Vector2i(x,y))
	site(w,"locked_door",offset+Vector2i(0,2));w.refresh_indoor()
func run():
	var w=fresh(); var p=Vector2i(9,12)
	site(w,"wood_tile",p);w.floors[p].cost=20
	w.paused=true;var before=w.wood
	check(w.act("remove_floor",p),"Floor dismantle reserves during pause")
	check(w.jobs[0].target_layer=="floor" and w.jobs[0].target_id==w.floors[p].id,"Reservation records layer and identity")
	check(not w.act("remove_floor",p),"No duplicate demolition")
	steps(w,20);check(w.floors.has(p) and w.wood==before and w.tick==0,"Paused demolition has no world effect")
	w.act("cancel_job",Vector2i.ZERO,w.jobs[0].id);check(w.wood==before,"Cancellation has no salvage")
	w.act("remove_floor",p);w.paused=false
	w.field_items.append({"kind":"egg","pos":p,"born_day":1})
	drain(w);check(not w.floors.has(p) and w.wood==before+16,"Onsite floor-only salvage once")
	check(w.field_items.size()==1 and w.keeper.pos!=p,"Drops remain and worker stands adjacent")
	steps(w,2);check(w.wood==before+16,"No repeat salvage")
	w=fresh();site(w,"soil_tile",p);site(w,"wall",p)
	check(not w.act("remove_floor",p),"Structure above blocks floor removal")
	check(w.act("remove",p),"Can remove upper structure")
	drain(w);check(w.floors.has(p) and not w.live_structure(p),"Upper demolition leaves floor")
	w.act("remove_floor",p);var old_id=w.floors[p].id;site(w,"stone_tile",p)
	drain(w);check(w.floors[p].id!=old_id and w.floors[p].kind=="stone_tile","Replacement target not accidentally removed")
	w=fresh();site(w,"wood_tile",p);w.act("remove_floor",p);w.animals[0].pos=p;w.animals[0].mode="rest"
	steps(w,16);check(w.floors.has(p) and w.jobs[0].state=="blocked","Occupied floor job waits")
	w.animals[0].pos=Vector2i(14,12);drain(w);check(not w.floors.has(p),"Vacated floor resumes")
	w=fresh();site(w,"soil_tile",p);w.act("remove_floor",p);site(w,"wall",p);steps(w,4)
	check(w.jobs[0].state=="blocked" and w.floors.has(p),"Upper building added after reservation rechecked")
	w=fresh();site(w,"soil_tile",w.keeper.pos);p=w.keeper.pos;w.act("remove_floor",p);drain(w)
	check(w.keeper.pos!=p and not w.floors.has(p),"Worker leaves own floor before dismantling")
	w=fresh();p=Vector2i(9,12);w.debug_enabled=true;w.debug_infinite=true;w.act("stone_tile",p);drain(w)
	w.debug_infinite=false;before=w.stone;w.act("remove_floor",p);drain(w)
	check(w.stone==before,"Free debug construction has zero salvage")
	w=fresh();p=Vector2i(9,12);w.act("soil_tile",p);drain(w);w.act("wood_tile",p);drain(w);w.act("stone_tile",p);drain(w)
	before=w.stone;var old_wood=w.wood;w.act("remove_floor",p);drain(w)
	check(w.stone==before+1 and w.wood==old_wood,"Upgrade salvage only latest paid material")
	w=fresh();room(w,Vector2i(10,5));w.keeper.pos=Vector2i(12,7);w.keeper.sleepiness=70
	w.act("keeper_rest");steps(w,12);check(w.keeper.asleep,"Indoor onset three seconds")
	w.floors.erase(Vector2i(11,6));w.refresh_indoor();var fatigue=w.keeper.sleepiness;steps(w,4)
	check(w.keeper.asleep and w.keeper.sleepiness==fatigue-2,"Floor removal uses outdoor rate without resetting sleep")
	check(not w.is_indoor(w.keeper.pos),"Missing floor invalidates room")
	w=fresh();w.keeper.sleepiness=50;steps(w,ceili(w.Life.AUTO_REST_IDLE_SECONDS/w.DT)-1);check(not w.keeper.resting,"Idle wait uses the provisional eight-second interval")
	w.step();check(w.keeper.resting and w.keeper.rest_kind=="auto" and not w.keeper.asleep,"Idle then automatic settling")
	fatigue=w.keeper.sleepiness;steps(w,18);check(w.keeper.sleepiness==fatigue,"No fatigue recovery during onset wait")
	w.paused=true;var elapsed=w.keeper.rest_elapsed;w.act("wall",Vector2i(7,12));steps(w,20)
	check(w.keeper.resting and w.keeper.rest_elapsed==elapsed,"Paused new work only plans wake")
	w.paused=false;drain(w);check(w.structures[Vector2i(7,12)].status=="ready" and not w.keeper.resting,"New valid work wakes automatic rest")
	w=fresh();w.act("keeper_rest");w.act("wall",Vector2i(7,12));steps(w,24)
	check(w.keeper.resting and not w.jobs.is_empty(),"Manual rest is not auto-woken by new work")
	w=fresh();w.keeper.sleepiness=1;steps(w,160)
	check(w.keeper.resting and w.life_log.filter(func(e):return e.event=="rest_started").size()==1,"Auto rest at zero avoids sleep-wake loop")
	w=fresh();w.act("keeper_move",Vector2i(15,13));w.act("wall",Vector2i(7,12))
	for n in w.neighbors(w.keeper.pos): site(w,"wall",n)
	steps(w,4);check(w.manual_goal==null and not w.jobs_held,"Failed ordinary travel releases only travel hold")
	w=fresh();w.act("keeper_move",Vector2i(15,13));w.act("wall",Vector2i(7,12));w.keeper.sleepiness=100;w.step()
	check(w.manual_goal==null and w.job_hold_reason!="travel" and w.keeper.forced_rest,"Forced sleep invalidates transient travel hold")
	steps(w,70);drain(w);check(w.jobs.is_empty() and w.structures[Vector2i(7,12)].status=="ready","Building starts after forced recovery")
	w=fresh();w.act("wall",Vector2i(7,12));w.act("keeper_move",Vector2i(15,13));w.Jobs.hold(w,"explicit");w.keeper.sleepiness=100;steps(w,70)
	check(w.job_hold_reason=="explicit" and not w.jobs.is_empty(),"Explicit pause remains held after forced recovery")
	w=fresh();w.debug_enabled=true;var hp=w.keeper.hp
	check(not w.debug_action("lock",{"kind":"keeper"}) and w.keeper.hp==hp,"Lock action cannot heal keeper")
	check(not w.debug_action("lock",{"kind":"animal","id":1}),"Lock action rejects animal")
	site(w,"soil_tile",Vector2i(9,12));site(w,"locked_door",Vector2i(9,12));w.debug_action("hurt",{"kind":"floor","pos":Vector2i(9,12)})
	check(w.floors[Vector2i(9,12)].status=="destroyed" and w.structures[Vector2i(9,12)].hp==16,"Debug floor damage cannot damage structure")
	w=fresh();room(w,Vector2i(3,3));room(w,Vector2i(14,4));w.animals[0].pos=Vector2i(2,5)
	var goal=w.rescue_exit(w.animals[0],Vector2i(16,6))
	check(goal==Vector2i(13,6),"Rescue chooses target room, not closest unrelated door")
	observations.rescue_exit=[goal.x,goal.y]
	w=fresh();w.drop_blueprint(Vector2i(9,12));check(w.field_items.is_empty(),"Disabled hut plan no longer drops")
	w.field_items.append({"kind":"kennel_plan","pos":Vector2i(9,12),"born_day":1});w.act("collect",Vector2i(9,12));drain(w)
	check("kennel" in w.campaign.blueprint_records and "kennel" in w.campaign.unlocked_blueprints and w.item_count("kennel_plan")==0,"Legacy scroll consumed, history and knowledge preserved")
	w.grant_blueprint("kennel",Vector2i(9,12));check(not "覚えた" in w.milestones[-1].text,"Duplicate pickup does not relearn")
	w.persist_farm();var rebuilt=Farm.new(w.campaign,17,w.config)
	check(rebuilt.campaign.blueprint_records==["kennel"],"Blueprint record survives campaign reconstruction (not disk save)")
	check(not w.act("kennel",Vector2i(9,12)) and not w.act("coop",Vector2i(9,12)),"Both huts unavailable even if learned")
	w=fresh();w.animals[0].mode="rest";w.animals[0].hp=10;steps(w,40)
	check(w.animals[0].hp==12,"Normal dog rest heals without hut")
	w.debug_enabled=true;w.debug_action("hen");check(w.animals[1].placed and w.distance(w.animals[1].pos,w.entries[0])<=4,"Hen arrives near existing entrance")
	w.process_dawn()
	check(w.field_items.any(func(i):return i.kind=="egg"),"Hen lays without coop")
	w=fresh();w.keeper.pos=Vector2i(12,13);w.act("keeper_move",Vector2i(10,13));steps(w,12)
	check(w.keeper.get("facing",1)==-1,"Leftward move retains actor facing on stop")
	# Migrating old hut reservations cannot refund twice on repeated reconstruction.
	w=fresh();site(w,"kennel",Vector2i(20,12));w.persist_farm()
	w.campaign.work_jobs=[{"id":99,"kind":"coop","pos":[20,13],"resource":"wood","reserved":30,"started":false,"state":"pending","animal_id":-1}]
	before=w.campaign.resources.wood
	var migrated=Farm.new(w.campaign,17,w.config)
	var repeated=Farm.new(migrated.campaign,17,w.config)
	check(migrated.wood==before+30 and repeated.wood==migrated.wood,"Hut reservation refund migration is idempotent")
	check(migrated.structures[Vector2i(20,12)].status=="disabled" and migrated.campaign.retired_facilities.size()==1,"Old completed hut archived, disabled, not deleted")
	check(migrated.walkable(Vector2i(22,14)) and not migrated.find_path(Vector2i(22,13),Vector2i(22,14)).is_empty() and migrated.Buildings.reason(migrated,"wall",Vector2i(22,14))=="","Old shed-only exclusion removed")
	w=fresh()
	for y in range(1,w.H-1):
		for x in range(1,w.W-1): site(w,"soil_tile",Vector2i(x,y))
	p=Vector2i(10,8);w.act("remove_floor",p);drain(w)
	check(w.natural.is_empty(),"Demolition does not instantly generate grass")
	w.nature_config.spawn_chance_per_second=1.0;w.grow_nature()
	check(w.natural.has(p),"Next normal nature roll can use removed floor")
	w=fresh();w.debug_enabled=true
	for n in w.neighbors(w.entries[0]):
		if w.inside(n):site(w,"wall",n)
	room(w,Vector2i(14,4));w.debug_action("hen")
	check(not w.animals[1].placed,"Blocked entrance never admits to unrelated enclosed room")
	w=fresh();w.keeper.sleepiness=50;steps(w,ceili(w.Life.AUTO_REST_IDLE_SECONDS/w.DT));var start_tick=w.tick
	steps(w,19);check(not w.keeper.asleep,"Auto rest has a separate full five-second onset")
	w.step();check(w.keeper.asleep and w.tick-start_tick==20,"Auto onset exactly five game seconds after idle wait")
	observations.auto_rest=w.life_log.duplicate(true)
	w.spawn_enemy({"entry":w.keeper.pos+Vector2i(2,0),"role":"kidnapper"})
	check(not w.keeper.resting and w.job_hold_reason!="auto_rest","Enemy danger wakes automatic rest")
	w=fresh();w.keeper.sleepiness=60;steps(w,ceili(w.Life.AUTO_REST_IDLE_SECONDS/w.DT));w.act("guide",Vector2i(15,12),1)
	check(not w.keeper.resting,"Valid animal instruction also wakes automatic rest")
	w=fresh();w.keeper.sleepiness=60;steps(w,ceili(w.Life.AUTO_REST_IDLE_SECONDS/w.DT));check(not w.act("wall",w.keeper.pos) and w.keeper.resting,"Invalid simulation request does not wake automatically without UI activity")
	w.act("keeper_move",Vector2i(12,13));check(not w.keeper.resting,"Valid direct move wakes auto rest")
	w=fresh();w.keeper.sleepiness=50;w.Jobs.hold(w,"explicit");steps(w,24)
	check(not w.keeper.resting,"Explicit wait is not no-work idle")
	w=fresh();w.keeper.sleepiness=50;w.act("wall",Vector2i(10,10));site(w,"stone_wall",Vector2i(10,10));steps(w,24)
	check(not w.keeper.resting and w.jobs[0].state=="blocked","Blocked work is not no-work idle")
	w=fresh();w.debug_enabled=true;w.debug_action("shiba");room(w,Vector2i(14,4))
	w.animals[0].pos=Vector2i(13,6);w.animals[1].pos=Vector2i(12,6)
	check(w.rescue_exit(w.animals[1],Vector2i(16,6))!=w.animals[0].pos,"Rescue waiting never assigns another dog's occupied cell")
	w.structures[Vector2i(14,6)].status="destroyed";w.refresh_indoor()
	check(not w.is_indoor(Vector2i(16,6)),"Door body loss updates target room")
	w=fresh();w.animals[0].hp=10;w.animals[0].mode="rest";var days=[]
	for day in range(3):
		steps(w,80);days.append(w.animals[0].hp);w.finish(true);w=Farm.new(w.next_campaign(),17,w.config).begin_day();w.animals[0].mode="rest"
	check(days==[14,18,22],"Three days of normal dog rest retain 1HP per five seconds without hut bonus")
	observations.normal_rest_hp=days
	w=fresh();w.keeper.sleepiness=50;w.act("keeper_move",Vector2i(12,13));w.act("wall",Vector2i(7,12))
	w.keeper.sleepiness=100;steps(w,1);observations.forced_hold={"hold":w.job_hold_reason,"goal":w.manual_goal,"jobs":w.jobs.size()}
	observations.checks=checks;observations.failures=failures
	FileAccess.open("res://artifacts/revisions-observation.json",FileAccess.WRITE).store_string(JSON.stringify(observations,"  "))
	print("REVISIONS: ",checks," checks, failures=",failures)
	quit(1 if failures else 0)
