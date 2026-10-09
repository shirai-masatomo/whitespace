extends "res://tests/test_progression.gd"
const Guide=preload("res://game/animal_guide.gd")

func command_world():
	var w=fresh();w.trees.clear();w.story.trees=[];w.story.idol={}
	w.keeper.pos=Vector2i(5,8);w.keeper.hp=30
	var dog=w.animals[0];dog.pos=Vector2i(6,8);dog.home=dog.pos;dog.order=dog.pos;dog.loyalty=100
	return w

func wall(w,p):
	w.structures[p]={"id":100+p.y*25+p.x,"kind":"wall","status":"ready","hp":8,"max_hp":8,"open":false}

func guide_trial(w,a,destination: Vector2i,limit: int=500) -> Dictionary:
	var accepted=w.queue_order("guide",[a.id],destination)
	var adjacent=true;var legal=true;var moved=0;var k=w.keeper.pos;var p=a.pos
	for i in range(limit):
		w.step()
		legal=legal and w.distance(k,w.keeper.pos)<=1 and w.distance(p,a.pos)<=1 and a.pos!=w.keeper.pos and w.animal_walkable(a,a.pos)
		if a.has("guide_job"):adjacent=adjacent and w.distance(a.pos,w.keeper.pos)==1
		if p!=a.pos:moved+=1
		k=w.keeper.pos;p=a.pos
		if w.jobs.is_empty():break
	return {"accepted":accepted,"adjacent":adjacent,"legal":legal,"moves":moved,"arrived":w.job_log.any(func(e):return e.event=="guide_arrived" and e.animal_id==a.id)}

func run():
	for species in Farm.SPECIES:
		check("auto" in Farm.SPECIES[species].orders and "guide" in Farm.SPECIES[species].orders,"Every species supports auto and guide: "+species)
		check(Farm.SPECIES[species].object_attack>0,"Every animal has a positive object capability: "+species)
	for species in ["hen","cat","cow"]:
		check(Farm.SPECIES[species].attack==0 and Farm.SPECIES[species].combat_response==D.CombatResponse.NONE,"Object capability adds no combat AI: "+species)
	var w=command_world();var dog=w.animals[0]
	var r=guide_trial(w,dog,Vector2i(15,8))
	check(r.accepted and r.arrived and r.adjacent and r.legal and dog.mode=="auto","Single guide remains adjacent, physical and returns to auto")
	w=command_world();dog=w.animals[0]
	for x in range(2,20):wall(w,Vector2i(x,7));wall(w,Vector2i(x,9))
	r=guide_trial(w,dog,Vector2i(17,8))
	check(r.arrived and r.adjacent and r.legal,"One-cell lane guides without swapping or passing through walls")
	w=command_world();dog=w.animals[0];dog.pos=Vector2i(2,2)
	var hen=add(w,"hen",Vector2i(6,8));hen.move_speed=0.5
	check(w.queue_order("guide",[hen.id],Vector2i(15,8)),"Slow companion accepts a guide")
	var last=w.keeper.pos;var keeper_moves=0
	for i in range(40):
		w.step()
		if w.keeper.pos!=last:keeper_moves+=1;last=w.keeper.pos
	check(keeper_moves<=5 and hen.has("guide_job") and w.distance(hen.pos,w.keeper.pos)==1,"Keeper pace is capped by the slower companion")
	var id=w.jobs[0].id;var before=hen.pos
	w.Jobs.cancel(w,id)
	check(not hen.has("guide_job") and hen.pos==before and hen.mode=="auto","Cancellation releases the same resident without teleporting")
	w=command_world();dog=w.animals[0];dog.mode="stay"
	w.queue_order("guide",[dog.id],Vector2i(15,8));step(w,5)
	w.Life.hurt(w,{"id":999,"attack_power":100})
	check(not dog.has("guide_job") and dog.mode=="stay" and w.keeper.hp==0,"Keeper knockout interrupts guidance and restores prior intent")
	w=command_world();dog=w.animals[0]
	wall(w,Vector2i(8,8));wall(w,Vector2i(8,7));wall(w,Vector2i(8,9))
	var other=add(w,"hedgehog",Vector2i(7,8));other.mode="stay";other.order_until=99999
	r=guide_trial(w,dog,Vector2i(12,8))
	check(r.arrived and r.adjacent and r.legal and other.pos==Vector2i(7,8),"Guide routes around a stationary animal and wall")
	w=command_world();dog=w.animals[0];dog.pos=Vector2i(2,2)
	var cat=add(w,"cat",Vector2i(6,8))
	r=guide_trial(w,cat,Vector2i(12,8))
	check(r.arrived and cat.mode=="auto","Cat accepts guidance and resumes its normal behavior")
	check(w.issue_order("auto",cat.pos,cat.id),"Zero-loyalty cat still accepts the common automatic order")
	w=command_world();dog=w.animals[0];dog.mode="stay";dog.order=dog.pos;dog.home=dog.pos
	var e=enemy(w,"kidnapper",Vector2i(8,8));var start=dog.pos
	for i in range(40):w.tick+=1;w.animal_step(dog)
	check(dog.pos==start,"Stay never chases a distant target")
	dog.mode="wander";dog.known_enemies.clear();e.done=true
	for i in range(60):w.tick+=1;w.animal_step(dog)
	check(dog.pos!=start and dog.has("patrol_goal"),"Patrol traverses a circuit instead of holding position")
	w=command_world();dog=w.animals[0];dog.mode="rest";dog.hp=20
	var hp=dog.hp
	for i in range(20):w.tick+=1;w.animal_step(dog)
	check(dog.hp==hp+1,"Cautious mode heals at the existing rest cadence when safe")
	e=enemy(w,"kidnapper",dog.pos+Vector2i.RIGHT);hp=e.hp
	w.tick+=1;dog.move_credit=1;w.animal_step(dog)
	check(e.hp<hp and not dog.rescuing and w.distance(dog.pos,e.pos)>1,"Cautious mode counters close danger while retreating")
	w=command_world();dog=w.animals[0]
	check(not w.queue_order("attack_target",[dog.id],Vector2i(9,9)) and w.events[-1].text=="敵を選んでください","Empty attack selection gives the requested prompt")
	e=enemy(w,"kidnapper",Vector2i(11,8));w.keeper.pos=Vector2i(10,8)
	check(w.Orders.target_reason(w,dog,e.id)=="柴犬から敵が遠すぎます。仲間を近づけてください","A visible out-of-range enemy identifies the animal that must approach")
	e.pos=Vector2i(20,12);w.keeper.pos=Vector2i(5,8);dog.known_enemies.clear()
	check(w.Orders.target_reason(w,dog,e.id)=="敵を選んでください","Hidden enemies do not disclose their distance")
	e.pos=dog.pos+Vector2i.RIGHT
	check(w.queue_order("attack_target",[dog.id],e.pos),"Detected reachable enemy is accepted")
	e.done=true;step(w,15)
	check(w.jobs.is_empty() and dog.mode!="attack_target","Target lost before issuance never creates a stale attack order")
	print("ANIMAL_COMMANDS: %d checks, failures=%d"%[checks,failures]);quit(1 if failures else 0)
