extends SceneTree
const Farm=preload("res://game/world.gd")
var checks=0
var failures=0
var observations={}
func _initialize(): call_deferred("run")
func check(value: bool,reason: String):
	checks+=1
	if not value: failures+=1; push_error(reason)
func fresh():
	var config=Farm.StageData.STAGES[1].duplicate(true)
	config.day_seconds=600.0; config.first_attack_seconds=9999.0
	var w=Farm.new({},17,config).begin_day()
	w.materials=500; w.wood=500; w.stone=500
	w.nature_config.spawn_chance_per_second=0
	return w
func steps(w,n):
	for i in range(n): w.step()
func drain(w,n=700):
	for i in range(n):
		if w.jobs.is_empty(): return
		w.step()
func site(w,kind,p):
	var d=w.BUILD[kind]
	w.Buildings.layer(w,kind)[p]={"id":w.next_structure_id,"kind":kind,"hp":d.hp,"max_hp":d.hp,"status":"ready","open":false,"armor":0,"cost":d.cost,"resource":d.get("resource","soil"),"lock_hp":d.get("lock_hp",0),"max_lock_hp":d.get("lock_hp",0)}
	w.next_structure_id+=1
func room(w):
	for y in range(5,10):
		for x in range(10,15):
			var p=Vector2i(x,y)
			if x in [10,14] or y in [5,9]: site(w,"wall",p)
			else: site(w,"soil_tile",p)
	site(w,"locked_door",Vector2i(10,7))
	w.refresh_indoor()
func run():
	var w=fresh()
	w.act("wall",Vector2i(12,10));w.act("wall",Vector2i(11,10));drain(w)
	check(w.jobs.is_empty() and w.metrics.built==2,"Keeper leaves next construction target before occupancy validation")
	w=fresh()
	check(w.animals[0].placed and w.animals[0].pos!=w.keeper.pos,"Initial dog is a resident, distinct from keeper")
	check(not w.act("place_animal",Vector2i(2,2),1),"Removed deployment cannot teleport a resident")
	var saved=w.animals[0].pos
	w.persist_farm(); var next=Farm.new(w.campaign,17,w.config)
	check(next.animals[0].pos==saved,"Resident position persists through reconstruction")
	w.paused=true
	check(w.act("rest",Vector2i.ZERO,1),"Animal order takes a queue slot during pause")
	steps(w,10)
	check(w.animals[0].mode=="auto" and w.tick==0,"Paused order never executes")
	w.paused=false; drain(w); steps(w,6)
	check(w.animals[0].mode=="rest","Adjacent instruction reaches the actual individual")
	check(w.job_log.any(func(e):return e.event=="order_issued" and e.distance<=1),"No-whistle issuance requires adjacency")
	w.debug_enabled=true; w.debug_action("cat"); w.debug_action("hen")
	check(not w.act("guide",Vector2i(9,12),2),"Cat cannot receive guidance")
	check(not w.act("rest",Vector2i.ZERO,3),"Hen cannot receive dog rest order")
	check(w.act("guide",Vector2i(16,12),3),"Hen accepts movement guidance")
	drain(w)
	check(w.jobs.is_empty() and w.animals[2].placed,"Hen physically completes guidance")
	w=fresh(); w.debug_enabled=true; w.debug_action("hen"); w.debug_action("whistle")
	check(w.queue_order("guide",[1,2],Vector2i(15,12)),"Whistle groups two residents into one job")
	check(w.jobs.size()==1 and w.jobs[0].targets[0].dest!=w.jobs[0].targets[1].dest,"Group destinations are unique")
	var destinations=w.jobs[0].targets.duplicate(true)
	drain(w)
	check(w.jobs.is_empty(),"Dispersed targets are issued sequentially and finish")
	check(w.animals[0].pos!=w.animals[1].pos and w.animals.all(func(a):return a.placed),"Group never duplicates or overlaps individuals")
	check(w.job_log.filter(func(e):return e.event=="order_issued").all(func(e):return e.distance<=6),"Whistle obeys six-cell range")
	observations.orders=w.job_log
	w=fresh(); w.debug_enabled=true; w.debug_action("whistle")
	w.animals[0].loyalty=100
	for i in range(7): w.debug_action("hen")
	steps(w,12) # Entrance arrivals wait for their occupied neighbors to move, then join.
	check(w.queue_order("guide",w.animals.map(func(a):return a.id),Vector2i(15,12)),"Eight residents reserve one group")
	drain(w,1600)
	var arrivals=w.job_log.filter(func(e):return e.event=="guide_arrived")
	if arrivals.size()!=8: print("GROUPDEBUG ",w.jobs," animals ",w.animals.map(func(a):return [a.id,a.pos,a.state])," keeper ",w.keeper.pos)
	check(arrivals.size()==8 and w.jobs.is_empty(),"All eight physically arrive; no cancellation masquerades as success")
	var unique={}
	for a in w.animals: unique[a.pos]=true
	check(unique.size()==8 and not unique.has(w.keeper.pos),"Eight animals and keeper have distinct endpoint cells")
	observations.group_eight={"arrivals":arrivals,"log":w.job_log}
	w=fresh(); w.act("guide",Vector2i(16,12),1); steps(w,4)
	var count=w.animals.size(); w.act("cancel_job",Vector2i.ZERO,w.jobs[0].id)
	check(w.animals.size()==count and w.animals[0].placed and not w.animals[0].has("guide_job"),"Guide cancellation keeps physical individual")
	w.act("guide",Vector2i(16,12),1); steps(w,4); w.Life.hurt(w,{"id":0,"attack_power":1})
	check(not w.animals[0].has("guide_job") and w.animals[0].placed,"Actual keeper hit interrupts guidance without cargo")
	w=fresh(); room(w)
	check(w.is_indoor(Vector2i(12,7)) and not w.is_indoor(Vector2i(5,5)),"Completed tiled enclosure is indoor, pasture is not")
	w.structures[Vector2i(10,7)].open=true; w.refresh_indoor()
	check(w.is_indoor(Vector2i(12,7)),"Open door preserves enclosure")
	w.structures[Vector2i(10,7)].lock_hp=0; w.refresh_indoor()
	check(w.is_indoor(Vector2i(12,7)),"Lock destruction preserves enclosure")
	check(not w.animal_walkable(w.animals[0],Vector2i(12,7)),"Shiba cannot enter indoor")
	check(w.animal_path(w.animals[0],w.animals[0].pos,Vector2i(12,7)).is_empty(),"Shiba pathfinding rejects indoor destination")
	w.structures[Vector2i(12,5)].status="destroyed"; w.refresh_indoor()
	check(not w.is_indoor(Vector2i(12,7)),"Wall breach makes entire room outdoor")
	w=fresh(); room(w); w.floors.erase(Vector2i(12,7)); w.refresh_indoor()
	check(w.indoor.is_empty(),"One missing floor prevents indoor designation")
	w.animals[0].pos=Vector2i(11,7); w.animals[0].mode="rest"
	check(not w.act("soil_tile",Vector2i(12,7)) and w.Buildings.reason(w,"soil_tile",Vector2i(12,7))=="先に犬を外へ誘導","Last floor rejects enclosure of outdoor dog")
	w.animals[0].pos=Vector2i(6,11)
	check(w.act("soil_tile",Vector2i(12,7)),"Moving dog outside allows final floor")
	w.animals[0].pos=Vector2i(11,7)
	steps(w,120)
	check(not w.jobs.is_empty() and w.jobs[0].state=="blocked" and w.indoor.is_empty(),"Arrival validation preserves blocked work and resources")
	w.animals[0].pos=Vector2i(6,11); drain(w)
	check(w.is_indoor(Vector2i(12,7)),"Blocked construction completes after dog leaves")
	observations.enclosure={"indoor":w.indoor.keys().map(func(c):return [c.x,c.y]),"jobs":w.job_log}
	w=fresh(); var p=Vector2i(7,12)
	check(w.act("wall",p),"Soil wall reservation")
	drain(w); check(w.structures[p].status=="ready","Onsite wall completes")
	w.structures[p].hp=4; var wood=w.wood
	check(w.act("wood_wall",p) and w.wood==wood-10,"Upgrade reserves new material once")
	check(w.structures[p].kind=="wall" and w.blocks(p),"Old wall functions throughout reservation")
	drain(w); check(w.structures[p].kind=="wood_wall" and w.structures[p].hp==8,"Upgrade preserves half durability")
	check(not w.act("wall",p) and not w.act("wood_wall",p),"No downgrade or same tier")
	check(w.act("stone_wall",p),"Stone upgrade")
	var id=w.jobs[0].id; w.act("cancel_job",Vector2i.ZERO,id)
	check(w.stone==500 and w.structures[p].kind=="wood_wall","Unstarted upgrade cancellation refunds once and retains wall")
	check(not w.act("cancel_job",Vector2i.ZERO,id) and w.stone==500,"Repeated cancellation cannot mint resources")
	w=fresh(); var floor_cell=Vector2i(7,12)
	check(w.act("soil_tile",floor_cell),"Separate floor construction")
	drain(w); check(w.floors.has(floor_cell) and not w.structures.has(floor_cell),"Floor is separate layer")
	check(w.act("wall",floor_cell),"Structure can be built on floor")
	drain(w); check(w.floors.has(floor_cell) and w.structures.has(floor_cell),"Both layers survive")
	w.field_items.append({"kind":"egg","pos":Vector2i(8,12),"born_day":1})
	check(not w.act("soil_tile",Vector2i(8,12)) and w.field_items.size()==1,"Floor cannot delete an existing item")
	w.field_items.append({"kind":"kennel_plan","pos":floor_cell,"born_day":1})
	check(w.items_at(floor_cell).size()==1,"Legacy blueprint remains collectible on a floor")
	w=fresh(); var tile=Vector2i(7,12)
	w.act("soil_tile",tile); drain(w); w.floors[tile].hp=4
	for kind in ["wood_tile","stone_tile"]:
		check(w.act(kind,tile),"Floor upgrade accepted: "+kind); drain(w)
	check(w.floors[tile].kind=="stone_tile" and w.floors[tile].hp==14,"Floor upgrade preserves durability ratio through both tiers")
	w=fresh(); room(w); w.structures.erase(Vector2i(12,5)); w.refresh_indoor()
	w.animals[0].pos=Vector2i(6,11); w.animals[0].mode="rest"
	w.keeper.pos=Vector2i(12,4)
	check(w.act("stone_wall",Vector2i(12,5)),"Final wall reserved outside empty room")
	w.step(); check(w.jobs[0].started,"Final wall starts onsite")
	var progress=w.jobs[0].remaining
	w.animals[0].pos=Vector2i(11,7); steps(w,8)
	check(w.jobs[0].remaining==progress and w.jobs[0].state=="blocked" and w.indoor.is_empty(),"Completion revalidation preserves progress when dog enters after start")
	w.debug_enabled=true; w.debug_action("whistle")
	check(w.act("guide",Vector2i(8,7),1),"Guide can be queued behind blocked construction")
	check(w.Jobs.reorder(w,w.jobs[1].id,0),"Blocked job can yield to guidance without cancelling material or progress")
	drain(w,900)
	if not w.jobs.is_empty(): print("ENCDEBUG ",w.jobs," animals ",w.animals.map(func(a):return [a.id,a.pos,a.state])," keeper ",w.keeper.pos)
	check(w.jobs.is_empty() and w.is_indoor(Vector2i(11,7)) and not w.is_indoor(w.animals[0].pos),"Guide outside then complete saved construction")
	w=fresh(); room(w); w.structures[Vector2i(10,7)].status="destroyed";w.refresh_indoor()
	check(w.indoor.is_empty(),"Door body destruction breaches room")
	w=fresh(); site(w,"door",Vector2i(8,12));w.structures[Vector2i(8,12)].kind="gate"; w.structures[Vector2i(8,12)].hp=7
	w.persist_farm();var migrated=Farm.new(w.campaign,17,w.config)
	check(migrated.structures[Vector2i(8,12)].kind=="door" and migrated.structures[Vector2i(8,12)].hp==7,"Legacy gate migration preserves body durability")
	# Sleep comparison uses identical fixed ticks, including topology changes while asleep.
	var outdoor=fresh(); var indoor=fresh(); room(indoor)
	indoor.keeper.pos=Vector2i(12,7)
	for sample in [outdoor,indoor]: sample.keeper.sleepiness=70; sample.keeper.hp=20; sample.act("keeper_rest")
	steps(outdoor,12); steps(indoor,12)
	check(not outdoor.keeper.get("asleep",false) and indoor.keeper.asleep,"Outdoor onset5s and indoor onset3s")
	steps(outdoor,12); steps(indoor,12)
	check(outdoor.keeper.sleepiness==68 and indoor.keeper.sleepiness==58,"Outside2/s inside4/s after respective waits")
	check(outdoor.keeper.hp==indoor.keeper.hp,"Indoor bonus does not change HP healing")
	indoor.structures[Vector2i(12,5)].status="destroyed"; indoor.refresh_indoor(); steps(indoor,4)
	check(indoor.keeper.asleep and indoor.keeper.sleepiness==56,"Breach switches recovery rate without resetting sleep")
	indoor.paused=true; var elapsed=indoor.keeper.rest_elapsed; steps(indoor,10)
	check(indoor.keeper.rest_elapsed==elapsed and indoor.keeper.sleepiness==56,"Paused sleep has no elapsed time or recovery")
	observations.sleep={"outdoor":outdoor.life_log,"indoor":indoor.life_log,"outdoor_sleepiness":outdoor.keeper.sleepiness,"breached_sleepiness":indoor.keeper.sleepiness}
	w=fresh(); room(w); site(w,"door",Vector2i(14,7)); w.refresh_indoor()
	w.keeper.pos=Vector2i(8,8);w.keeper_path=[];w.animals[0].pos=Vector2i(8,7);w.animals[0].mode="rest";w.animals[0].loyalty=100
	w.act("guide",Vector2i(18,7),1);drain(w)
	check(w.job_log.any(func(e):return e.event=="guide_arrived"),"Outdoor dog reaches destination past room")
	check(w.keeper_path.all(func(p):return not w.is_indoor(Vector2i(p[0],p[1]))),"Keeper routes outdoor group around indoor shortcut")
	w=fresh(); w.keeper.hp=1;w.animals[0].loyalty=100;w.act("guide",Vector2i(20,8),1);steps(w,4);w.Life.hurt(w,{"id":0,"attack_power":5})
	check(w.keeper.state=="unconscious" and w.animals[0].placed and not w.animals[0].has("guide_job"),"Knockout also releases living guide animal")
	w=fresh();w.debug_enabled=true
	for y in range(1,w.H-1):
		for x in range(1,w.W-1): site(w,"wall",Vector2i(x,y))
	w.debug_action("hen");check(not w.animals[1].placed and w.animals[1].state=="受入待ち","Full ranch keeps single pending individual")
	w.structures.erase(w.entries[0]);w.structures.erase(w.entries[0]+Vector2i.RIGHT);w.admit(w.animals[1],w.entries[0])
	check(w.animals.size()==2 and w.animals[1].placed and w.animals[1].pos==w.entries[0]+Vector2i.RIGHT,"Admission retry uses a valid vacancy without duplication")
	# Door lock can break independently and cannot be restored by toggling.
	w=fresh(); var door=Vector2i(8,12); site(w,"locked_door",door)
	w.spawn_enemy({"entry":Vector2i(9,12),"role":"kidnapper"}); var e=w.enemies[0]
	for i in range(4): w.move_enemy(e,door)
	check(w.structures[door].lock_hp==0 and w.structures[door].hp==16,"Object attacks break lock without breaking body")
	w.move_enemy(e,door)
	check(w.structures[door].open,"Raider opens broken lock door")
	w.structures[door].open=false
	check(w.structures[door].lock_hp==0,"Closing never repairs lock")
	w=fresh(); room(w); w.keeper.pos=Vector2i(12,7); w.keeper.hp=0; w.keeper.state="captured"
	w.spawn_enemy({"entry":Vector2i(12,7),"role":"kidnapper"}); e=w.enemies[0]; e.pos=Vector2i(12,7); e.carry="keeper"; w.keeper.carrier=e.id
	w.animals[0].pos=Vector2i(8,7); w.animal_step(w.animals[0])
	check(w.animals[0].state=="外で待つ" and not w.is_indoor(w.animals[0].pos),"Rescue instinct waits outdoors for indoor carrier")
	e.pos=Vector2i(9,7); w.keeper.pos=e.pos; w.animals[0].pos=Vector2i(8,7); e.hp=1; w.animal_step(w.animals[0])
	check(w.metrics.rescues==1 and w.keeper.carrier<0,"Outdoor interception rescues keeper")
	w=fresh(); var stock=w.materials
	check(not w.debug_action("infinite"),"Debug disabled by default")
	w.debug_enabled=true; w.debug_action("infinite"); w.act("wall",Vector2i(7,12)); w.act("cancel_job",Vector2i.ZERO,w.jobs[0].id); w.debug_action("infinite")
	check(w.materials==stock,"Infinite material toggle cannot create refunded resources")
	FileAccess.open("res://artifacts/residents-observation.json",FileAccess.WRITE).store_string(JSON.stringify(observations,"  "))
	print("RESIDENTS: ",checks," checks, failures=",failures)
	quit(1 if failures else 0)
