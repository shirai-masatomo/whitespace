extends "res://tests/test_progression.gd"
const Corpse=preload("res://game/animal_corpse.gd")
const Save=preload("res://game/morning_save.gd")

func recovery_lane():
	var w=fresh();w.trees.clear();w.story.trees=[];w.story.idol={}
	w.keeper.pos=Vector2i(5,8)
	var dog=w.animals[0];dog.pos=Vector2i(10,8);dog.home=dog.pos;dog.order=dog.pos
	dog.hp=1;dog.unavailable_through_day=w.campaign.day+1
	for x in range(2,20):
		for y in [7,9]:w.structures[Vector2i(x,y)]={"id":100+y*25+x,"kind":"wall","status":"ready","hp":8,"max_hp":8,"armor":0,"open":false}
	for x in [2,19]:w.structures[Vector2i(x,8)]={"id":300+x,"kind":"wall","status":"ready","hp":8,"max_hp":8,"armor":0,"open":false}
	return w

func run():
	var w=fresh();var a=add(w,"hen",Vector2i(8,12));var id=a.id;var p=a.pos
	var e=enemy(w,"kidnapper",Vector2i(9,12))
	P.animal_hurt(w,a,e,999)
	check(Corpse.visible(a) and a.pos==p and a.corpse_disappear_at==Corpse.DISAPPEAR_AT,"Dead animal retains its death cell until the morning boundary")
	check(not a.placed and not w.Orders.active(w,a) and not w.campaign.animals.any(func(row):return row.id==id),"A corpse is neither roster, command target nor worker")
	check(not P.target_candidates(w,e).any(func(t):return t.kind=="animal" and t.id==id),"Enemy AI excludes the corpse")
	var count=w.campaign.animal_history.size();P.animal_hurt(w,a,e,999);P.remove_animal(w,a,"death")
	check(w.campaign.animal_history.size()==count,"Repeated death does not duplicate history")
	for i in range(80):w.tick+=1;w.animal_step(a)
	check(Corpse.visible(a) and a.pos==p and a.hp==0,"Owned corpse persists beyond enemy eight-second lifetime without AI or recovery")
	w.start_night();w.spawn_schedule.clear();w.enemies.clear();w.finish(true)
	var morning=Farm.new(w.next_campaign(),32);var record=Save.capture(morning);var loaded=Save.restore(record)
	check(not morning.animals.any(func(row):return row.id==id) and not loaded.animals.any(func(row):return row.id==id),"Next morning and its save restore contain no corpse or duplicate individual")
	check(loaded.campaign.animal_history.size()==count,"Morning restoration preserves the one death record")
	w=fresh();var dog=w.animals[0];e=enemy(w,"kidnapper",dog.pos+Vector2i.RIGHT)
	P.animal_hurt(w,dog,e,999)
	check(not Corpse.visible(dog) and not dog.get("dead",false),"Unconscious Shiba is never classified as a corpse")
	var through=dog.unavailable_through_day
	for i in range(10):w.tick+=1;w.animal_step(dog)
	w.persist_farm();var c=w.campaign.duplicate(true);c.night_ready=false
	var restored=Save.restore(Save.capture(Farm.new(c,31)));var resumed=restored.begin_day();dog=resumed.animals[0]
	var credit=dog.get("convalescent_ticks",0);var hp=dog.hp
	resumed.paused=true
	for i in range(25):resumed.step()
	check(dog.hp==hp and dog.convalescent_ticks==credit,"Pause does not advance convalescent healing")
	resumed.paused=false
	for i in range(10):resumed.tick+=1;resumed.animal_step(dog);resumed.animal_step(dog)
	check(dog.hp==1 and dog.unavailable_through_day==through and not resumed.available(dog),"Saved healing fraction resumes once per tick without early deployment")
	var attacker=enemy(resumed,"ninja",dog.pos+Vector2i.RIGHT)
	P.strike(resumed,attacker,{"kind":"animal","id":dog.id,"pos":dog.pos},999)
	P.animal_hurt(resumed,dog,attacker,999)
	check(dog.hp==1 and dog.unavailable_through_day==through,"Ranged and direct damage cannot re-down or extend convalescence")
	check(not P.target_candidates(resumed,attacker).any(func(t):return t.kind=="animal" and t.id==dog.id),"Recovering positive-HP Shiba stays out of enemy targets")
	attacker.attacker=dog.id;attacker.threat_until=resumed.tick+20
	attacker.chosen_target={"kind":"animal","id":dog.id,"pos":dog.pos};attacker.choose_at=resumed.tick+20
	P.enemy_step(resumed,attacker)
	check(not (attacker.chosen_target.get("kind")=="animal" and attacker.chosen_target.get("id")==dog.id),"An old retaliation target cannot restore a convalescent Shiba as an enemy target")
	var tamer=enemy(resumed,"animal_tamer",dog.pos+Vector2i.LEFT);var loyalty=dog.get("loyalty_loss",0.0)
	check(not P.tame(resumed,tamer,dog) and dog.get("loyalty_loss",0.0)==loyalty,"Convalescence cannot acquire a tame penalty or abductor")
	var pos=dog.pos;resumed.keeper.state="unconscious";resumed.keeper.hp=0
	resumed.tick+=1;resumed.animal_step(dog)
	check(dog.pos==pos and not dog.rescuing and not resumed.Orders.active(resumed,dog),"A recovering Shiba cannot restart rescue work early")
	resumed.keeper.state="free";resumed.keeper.hp=30
	for i in range(600):resumed.tick+=1;resumed.animal_step(dog)
	check(dog.hp==Farm.AnimalData.stats("shiba",dog.lv).hp/2 and not resumed.available(dog),"Gradual recovery respects the existing half-health/full-day boundary")
	resumed.campaign.day=through+1;resumed.tick+=1;resumed.animal_step(dog)
	check(resumed.available(dog),"After the existing recovery day the Shiba can act again")
	check(P.target_candidates(resumed,attacker).any(func(t):return t.kind=="animal" and t.id==dog.id),"After the recovery boundary normal targeting resumes")
	w=recovery_lane();dog=w.animals[0];pos=dog.pos;through=dog.unavailable_through_day
	check(w.occupied(pos) and w.Buildings.reason(w,"wall",pos)=="ここに誰かいます" and w.Buildings.reason(w,"soil_tile",pos)=="ここに誰かいます","Convalescent Shiba retains building and floor occupancy")
	check(not w.actor_occupied(pos,w.keeper.pos) and not w.find_path(w.keeper.pos,Vector2i(16,8),false,true).is_empty(),"A protected prone Shiba does not seal an otherwise closed one-cell lane")
	var accepted=w.Jobs.enqueue(w,"move",Vector2i(16,8),-1)
	var crossed=false
	for i in range(80):
		w.step();crossed=crossed or w.keeper.pos==pos
		if w.jobs.is_empty():break
	check(accepted and crossed and w.keeper.pos==Vector2i(16,8) and w.jobs.is_empty() and dog.pos==pos,"Keeper movement crosses a prone Shiba and completes without moving the dog")
	e=enemy(w,"martial_artist",Vector2i(5,8));crossed=false;hp=dog.hp
	for i in range(100):
		w.tick+=1;P.walk(w,e,Vector2i(15,8));crossed=crossed or e.pos==pos
		if e.pos==Vector2i(15,8):break
	check(crossed and e.pos==Vector2i(15,8) and dog.hp==hp and dog.pos==pos and dog.unavailable_through_day==through,"Enemy movement crosses the prone Shiba without damage, displacement or extending recovery")
	var returned_campaign=Farm.new_campaign();returned_campaign.day=through+1
	returned_campaign.keeper_position=[6,13]
	returned_campaign.animals[0].position=[6,13]
	returned_campaign.animals[0].hp=hp;returned_campaign.animals[0].unavailable_through_day=through
	morning=Farm.new(returned_campaign,31);dog=morning.animals[0]
	check(dog.placed and dog.pos!=morning.keeper.pos and morning.Orders.active(morning,dog) and morning.actor_occupied(dog.pos,morning.keeper.pos),"Recovery morning admits the returning Shiba into a free cell and restores movement occupancy")
	loaded=Save.restore(Save.capture(morning))
	check(loaded!=null and loaded.animals.size()==1 and loaded.animals[0].pos==dog.pos and loaded.Orders.active(loaded,loaded.animals[0]),"Morning save restoration preserves one active returning Shiba at its admitted cell")
	print("ANIMAL_CORPSE: %d checks, failures=%d"%[checks,failures]);quit(1 if failures else 0)
