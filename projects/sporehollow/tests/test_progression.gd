extends SceneTree
const Farm=preload("res://game/world.gd")
const P=Farm.Progression
const D=Farm.ProgressData
var checks=0
var failures=0
var records=[]
func _initialize(): call_deferred("run")
func check(ok: bool,message: String):
	checks+=1; records.append({"check":message,"passed":ok})
	if not ok: failures+=1; push_error(message)
func fresh(day: int=1):
	var c=Farm.new_campaign();c.day=day
	var w=Farm.new(c,31).begin_day();w.day_seconds=9999;w.nature_config.spawn_chance_per_second=0
	w.animals[0].mode="rest";w.animals[0].order_until=999999
	return w
func add(w,species: String,pos: Vector2i):
	var id=w.campaign.next_animal_id;w.campaign.next_animal_id+=1
	var a={"id":id,"species":species,"category":w.SPECIES[species].category,"lv":1,"loyalty":w.SPECIES[species].loyalty,"name":"","unavailable_through_day":0}
	w.campaign.animals.append(a);w.add_resident(a)
	var actor=w.animals.back();actor.pos=pos;actor.home=pos;actor.order=pos
	return actor
func enemy(w,id: String,pos: Vector2i):
	w.spawn_enemy({"role":id,"entry":w.entries[0],"lv":1});var e=w.enemies.back();e.pos=pos;return e
func step(w,n: int):
	for i in range(n):w.step()
func run():
	check(D.rarity("Rare")==D.Rarity.RARE and D.rarity(null)==D.Rarity.COMMON,"Rarity safely migrates missing/legacy values")
	check(not Farm.AnimalData.skill("rescue").rollable and Farm.AnimalData.skill("rescue").source=="species","Rescue is fixed, not rollable")
	var plan=P.Encounters.plan(1,31,0)
	check(plan.encounter_mode=="Fixed" and plan.chosen==["kidnapper"],"Day1 fixed kidnapper only")
	check(P.Encounters.plan(4,31,0)==P.Encounters.plan(4,31,0),"Table deterministic")
	check(P.Encounters.plan(5,31,0).chosen[0]=="martial_artist" and P.Encounters.plan(5,31,0).chosen.size()==2,"Hybrid contains fixed and drawn slots")
	for type in ["Infected","Mutation","Cult","Military","Alien"]:
		var row=D.enemy("kidnapper");row.type_tag=type
		check(not P.Encounters.eligible(row,{"day":20,"karma":0}),"Low karma excludes "+type)
	var w=fresh(4);var reset=Farm.new(w.morning_checkpoint,31)
	check(w.spawn_schedule==reset.spawn_schedule,"Morning reset keeps encounter plan and entry directions")
	check(w.story.hidden.karma==0 and not w.act("pray_wealth",w.Story.at(w)),"Low karma route does not accept obsolete fixed-gold prayer")
	var stock=w.shop_stock.duplicate(true)
	check(stock==Farm.Shop.generate(w.stage,w.seed_value,w.campaign.unlocked_blueprints,w.campaign.day),"Morning individual stock reproducible")
	for source in ["shop","idol"]:
		check(D.individual("hen",17,source)==D.individual("hen",17,source),"Individual seed stable "+source)
	var shop_rare=0;var idol_rare=0;var bonuses=0
	for i in range(1000):
		if D.individual("hen",i,"shop").rarity>0:shop_rare+=1
		if D.individual("hen",i,"idol").rarity>0:idol_rare+=1
		if not D.individual("hen",i,"shop").bonus_skills.is_empty():bonuses+=1
	check(idol_rare>shop_rare and bonuses>0 and bonuses<120,"Separate rarity weights and low shop bonus rate")
	var idol_safe=true
	for i in range(500):
		if D.idol_reward("animal",0,i,2).species=="shiba":idol_safe=false
	check(idol_safe,"Idol animal reward pool always excludes Shiba")
	w=fresh();var e=enemy(w,"destroyer",Vector2i(8,8))
	var cell=Vector2i(9,8)
	w.structures[cell]={"id":98,"kind":"wall","hp":8,"max_hp":8,"armor":0,"status":"ready","open":false}
	var target={"kind":"structure","id":98,"pos":cell}
	P.strike(w,e,target);check(w.structures[cell].hp==4,"Destroyer first adjacent hit 4")
	P.strike(w,e,target);check(w.structures[cell].status=="destroyed","Destroyer second hit breaks soil wall")
	var counts={"keeper":0,"animal":0,"structure":0,"idol":0}
	var options=[]
	for kind in counts: options.append({"kind":kind,"id":0,"pos":Vector2i(9,8)})
	for i in range(2000):counts[P.select_target(w,e,options).kind]+=1
	check(counts.structure>1200 and counts.structure<1600,"Destroyer structural priority statistically follows category weight")
	w=fresh();e=enemy(w,"martial_artist",w.keeper.pos+Vector2i.RIGHT)
	w.keeper.hp=3;w.RaiderAI.perceive(e,w);P.enemy_step(w,e)
	check(e.action_id=="bow" and e.hp>0,"Martial artist bows before combat without invulnerability")
	P.enemy_hurt(w,e,2);check(e.hp==58,"Bowing enemy can be damaged")
	P.strike(w,e,{"kind":"keeper","id":-1,"pos":w.keeper.pos})
	check(w.keeper.hp==1 and w.keeper.state=="free" and e.action_id=="bow","Nonlethal keeper hit stops at 1 and bows after")
	var hen=add(w,"hen",Vector2i(8,9));hen.hp=2
	P.strike(w,e,{"kind":"animal","id":hen.id,"pos":hen.pos})
	check(hen.hp==1 and not hen.get("dead",false),"Nonlethal mortal animal remains alive")
	w=fresh();e=enemy(w,"salaryman",Vector2i(8,8))
	for i in range(100):
		if e.get("phone_started",false):break
		P.enemy_hurt(w,e,1);e.hp=e.max_hp
	check(e.get("phone_started",false),"Salaryman can start delayed call from damage")
	w.tick=e.phone_until;P.enemy_step(w,e)
	var calls=w.spawn_schedule.filter(func(x):return x.wave==999)
	check(calls.size()==1 and e.phone_success,"One successful call schedules one reinforcement")
	for i in range(20):P.enemy_hurt(w,e,1);e.hp=e.max_hp
	check(w.spawn_schedule.filter(func(x):return x.wave==999).size()==1,"Successful caller never calls twice")
	P.enemy_hurt(w,e,999);check(w.spawn_schedule.has(calls[0]),"Completed call survives caller defeat")
	w.spawn_enemy(calls[0]);check(not w.inside(w.enemies.back().pos),"Reinforcement starts outside forest boundary")
	var coins=w.metrics.coins;P.loot(w,e);check(coins>=2 and coins<=5 and w.metrics.coins==coins,"Salaryman drops 2-5 gold exactly once")
	w=fresh();e=enemy(w,"ninja",Vector2i(8,10));w.keeper.pos=Vector2i(11,10);w.animals[0].pos=Vector2i(2,2);e.target_weights={"keeper":1,"animal":0,"structure":0,"idol":0}
	w.structures[Vector2i(9,10)]={"id":4,"kind":"wall","hp":8,"max_hp":8,"armor":0,"status":"ready","open":false}
	w.RaiderAI.perceive(e,w);P.enemy_step(w,e)
	check(w.keeper.hp==30 and not e.has("shuriken_at"),"Ninja cannot throw through wall")
	w.structures.clear();w.RaiderAI.perceive(e,w);e.choose_at=0;P.enemy_step(w,e)
	check(w.keeper.hp==23 and e.action_id=="shuriken","Visible ranged ninja throw deals 7")
	P.enemy_hurt(w,e,999);P.loot(w,e)
	check(w.field_items.filter(func(item):return item.kind=="skill_scroll").size()==1,"Ninja always drops exactly one usable scroll")
	w=fresh();e=enemy(w,"animal_tamer",Vector2i(8,10));var shiba=w.animals[0];shiba.pos=Vector2i(9,10)
	P.tame(w,e,shiba);check(shiba.loyalty==75 and shiba.loyalty_loss==15,"Shiba resistance halves temporary tame loss, base unchanged")
	var loss=shiba.loyalty_loss;P.tick(w);check(shiba.loyalty_loss<loss,"Temporary loyalty recovers with simulation time")
	hen=add(w,"hen",Vector2i(8,11));P.tame(w,e,hen)
	check(hen.get("abductor",-1)==e.id and e.led_animal==hen.id,"Tamer leads low-loyalty animal without turning it into cargo")
	var position=hen.pos;P.enemy_hurt(w,e,999)
	check(not hen.has("abductor") and hen.placed and hen.pos==position,"Defeating tamer releases same animal in place")
	w=fresh();e=enemy(w,"runner",Vector2i(8,10));e.run_seconds=8.0;P.walk(w,e,Vector2i(16,10))
	check(e.get("tired_until",0)==w.tick+16 and e.move_speed==D.FAST_SPEED,"Runner gets four-second fatigue without permanent speed rewrite")
	check(w.SPECIES.doberman.move_speed==D.FAST_SPEED,"Runner and Doberman share base speed")
	var companions=false
	for i in range(30):
		enemy(w,"runner",Vector2i(8,10))
		if w.spawn_schedule.any(func(x):return x.role=="doberman"):companions=true;break
	check(companions,"Runner has seeded chance to schedule companion")
	if companions:
		w.spawn_enemy(w.spawn_schedule.filter(func(x):return x.role=="doberman")[0]);var dog=w.enemies.back()
		check(dog.type_tag=="Animal" and dog.faction=="enemy" and dog.max_hp==w.SPECIES.doberman.hp and not w.inside(dog.pos),"Enemy dog uses shared species stats and enters from exterior")
	w=fresh();e=enemy(w,"kidnapper",Vector2i(8,10));shiba=w.animals[0];P.animal_hurt(w,shiba,e,999)
	check(shiba.hp==0 and shiba.placed and not shiba.get("dead",false),"Shiba HP0 remains unconscious")
	for species in ["hen","cat","doberman","bullfrog","hedgehog"]:
		var a=add(w,species,Vector2i(10,10));P.animal_hurt(w,a,e,999)
		check(a.get("dead",false) and not a.placed and not w.campaign.animals.any(func(o):return o.id==a.id),species+" dies and leaves active roster")
	w.persist_farm();var data=w.next_campaign();data.day+=2;var next=Farm.new(data,31)
	check(next.campaign.animals.size()==1 and next.animals[0].hp>0,"Only Shiba recovers later; mortal animals never revive")
	w=fresh();e=enemy(w,"salaryman",Vector2i(10,10));var frog=add(w,"bullfrog",Vector2i(9,10));var hedgehog=add(w,"hedgehog",Vector2i(10,11));var cat=add(w,"cat",Vector2i(11,11))
	check(w.animal_targets(hedgehog).is_empty(),"Reactive hedgehog does not acquire on sight alone")
	P.animal_hurt(w,frog,e,1)
	check(not w.animal_targets(hedgehog).is_empty() and w.animal_targets(cat).is_empty(),"Frog warning activates reactive but never noncombatant")
	w.animal_step(frog);check(e.move_stopped_until>w.tick,"Frog tongue stops visible enemy movement")
	P.animal_hurt(w,hedgehog,e,1);var hp=e.hp;P.tick(w);var reflected=e.hp;P.tick(w)
	check(reflected==hp-4 and e.hp==reflected,"Spines reflect once per enemy per tick")
	w=fresh();e=enemy(w,"salaryman",Vector2i(8,10));shiba=w.animals[0];hen=add(w,"hen",Vector2i(9,10));w.add_item("collar",1);w.add_item("berry",2)
	check(not P.equip_job(w,hen.id,"collar"),"Collar rejected for non-dog")
	w.paused=true;check(P.equip_job(w,shiba.id,"collar"),"Equip can be planned paused")
	var tick=w.tick;step(w,8);check(w.tick==tick and shiba.equipment.is_empty() and w.item_count("collar")==1,"Paused equip does not move or consume")
	check(not P.equip_job(w,shiba.id,"collar"),"Duplicate equip job rejected")
	w.paused=false;w.keeper.pos=shiba.pos+Vector2i.LEFT;w.Jobs.step(w)
	check(shiba.equipment.item_id=="collar" and w.item_count("collar")==0 and P.loyalty(shiba)==100 and shiba.loyalty==75,"Local collar applies modifiers without rewriting base")
	P.equip_job(w,shiba.id,"unequip");w.Jobs.step(w)
	check(shiba.equipment.is_empty() and w.item_count("collar")==1 and P.loyalty(shiba)==75,"Unequip returns exactly one collar and removes only modifiers")
	shiba.equipment={"item_id":"berry"};shiba.hp=24;P.animal_hurt(w,shiba,e,5)
	check(shiba.hp==29 and shiba.equipment.is_empty(),"Berry consumes once after surviving half-HP hit and heals quarter max")
	shiba.equipment={"item_id":"berry"};P.animal_hurt(w,shiba,e,999)
	check(shiba.hp==0 and shiba.equipment.item_id=="berry","Berry never prevents lethal hit or revives unconscious Shiba")
	w=fresh();e=enemy(w,"ninja",Vector2i(22,1));P.tick(w)
	check(w.campaign.enemy_knowledge.get("ninja",0)==0,"Unseen spawned enemy stays unknown")
	e.pos=w.keeper.pos+Vector2i(3,0);P.tick(w)
	check(w.campaign.enemy_knowledge.ninja==1,"Sight reveals name only")
	e.observed_action=true;P.tick(w);check(w.campaign.enemy_knowledge.ninja==2,"Observed action reveals behavior")
	P.enemy_hurt(w,e,999);check(w.campaign.enemy_knowledge.ninja==3,"Defeat unlocks drop information")
	w=fresh();e=enemy(w,"ninja",Vector2i(8,10));w.keeper.pos=Vector2i(11,10);w.animals[0].pos=Vector2i(2,2);e.target_weights={"keeper":1,"animal":0,"structure":0,"idol":0}
	w.structures[Vector2i(9,10)]={"id":4,"kind":"door","hp":18,"max_hp":18,"armor":0,"status":"ready","open":false}
	w.RaiderAI.perceive(e,w);P.enemy_step(w,e)
	check(w.keeper.hp==30 and not e.has("shuriken_at"),"Closed door blocks shuriken exactly like wall")
	w.structures.clear();P.enemy_hurt(w,e,999);w.keeper.pos=e.pos
	w.act("collect",e.pos)
	for i in range(10):w.Jobs.step(w)
	check(w.field_items.filter(func(item):return item.kind=="skill_scroll").is_empty() and w.campaign.skill_scrolls.size()==1 and "hardy" in w.animals[0].bonus_skills,"Ninja scroll collects once and applies real eligible skill")
	var max_hp=w.animals[0].max_hp;w._execute_local("collect",e.pos)
	check(w.animals[0].max_hp==max_hp and w.campaign.skill_scrolls.size()==1,"Repeated collection never grants scroll twice")
	w=fresh();w.campaign.animals.clear();w.animals.clear();w.start_night();w.finish(true)
	check(w.result=="win","Farm without surviving animals still finishes safely")
	var file=FileAccess.open("user://progression-observation.json",FileAccess.WRITE);file.store_string(JSON.stringify({"checks":records,"target_distribution":counts,"shop_rare":shop_rare,"idol_rare":idol_rare,"shop_bonus":bonuses},"\t"))
	print("PROGRESSION: %d checks, failures=%d"%[checks,failures]);quit(1 if failures else 0)
