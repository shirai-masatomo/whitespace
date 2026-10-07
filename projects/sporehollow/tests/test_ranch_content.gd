extends "res://tests/test_progression.gd"
const C=Farm.Content
func open_world():
	var w=fresh(6);w.trees.clear();w.natural.clear();w.structures.clear();w.field_items.clear();w.floors.clear();w.refresh_indoor();w.keeper.pos=Vector2i(6,10)
	w.animals[0].pos=Vector2i(3,10);w.animals[0].home=w.animals[0].pos
	return w
func run():
	var w=open_world();var cow=add(w,"cow",Vector2i(8,10))
	w.paused=true
	check(w.act("milk",cow.pos,cow.id),"Paused milk reserves a physical job")
	check(not w.act("milk",cow.pos,cow.id),"Milk cannot be queued twice")
	step(w,20);check(w.item_count("milk")==0 and w.tick==0,"Pause does not produce milk")
	w.paused=false
	for i in range(160):
		w.step()
		if w.jobs.is_empty():break
	check(w.item_count("milk")==1 and w.distance(w.keeper.pos,cow.pos)<=1,"Keeper actually approaches the moving cow and milks")
	check(not w.act("milk",cow.pos,cow.id),"Cow may be milked once per day")
	check(w.campaign.animals.back().milked_day==w.campaign.day,"Milk day persists on owned individual")
	w.add_item("kokeshi",1);var p=Vector2i(10,10)
	check(w.act("place_kokeshi",p),"Placeable uses existing FIFO")
	check(not w.act("place_kokeshi",p+Vector2i.RIGHT),"Reserved inventory cannot be duplicated")
	w.Jobs.cancel(w,w.jobs[0].id)
	check(w.item_count("kokeshi")==1,"Cancelling unconsumed placeable does not duplicate inventory")
	w.act("place_kokeshi",p)
	for i in range(160):
		w.step()
		if w.jobs.is_empty():break
	check(w.item_count("kokeshi")==0 and w.field_items.size()==1,"Local placement consumes once")
	var e=enemy(w,"thief",p+Vector2i.RIGHT)
	check(is_equal_approx(C.speed(w,e),0.8) and is_equal_approx(C.speed(w,w.keeper),0.8),"Kokeshi slows both sides")
	w.field_items.append({"kind":"kokeshi","pos":p+Vector2i.UP,"placed":true})
	check(is_equal_approx(C.speed(w,e),0.8),"Kokeshi does not stack multiplicatively")
	w.enemies.clear();w.field_items.pop_back();w.act("collect",p)
	for i in range(80):
		w.step()
		if w.jobs.is_empty():break
	check(w.item_count("kokeshi")==1 and w.field_items.is_empty(),"Local recovery returns the same item")
	w=open_world();var bull=add(w,"bull",Vector2i(8,10));bull.mode="charge";bull.order=Vector2i(12,10)
	e=enemy(w,"destroyer",Vector2i(11,10));var hp=e.hp
	for i in range(12):w.tick+=1;C.animal_step(w,bull)
	check(e.hp==hp-20 and bull.pos==Vector2i(10,10) and bull.mode=="auto","Bull hits first enemy without overlap")
	bull.hp=bull.max_hp/2
	check(is_equal_approx(C.speed(w,bull),1.5) and is_equal_approx(C.attack_speed(w,bull),1.5),"Grit changes effective rates at half HP")
	bull.hp=bull.max_hp;check(is_equal_approx(C.speed(w,bull),1.0),"Recovery removes grit immediately")
	bull.pos=Vector2i(8,10);bull.mode="charge";bull.order=Vector2i(12,10);bull.charge_at=0
	w.trees[Vector2i(9,10)]="tree_a";C.animal_step(w,bull)
	check(bull.pos==Vector2i(8,10) and bull.mode=="auto","Charge stops before obstacle, never detours")
	w=open_world();var maid=add(w,"maid",Vector2i(7,10));w.keeper.hp=20;w.keeper.stamina=60
	C.animal_step(w,maid)
	check(w.keeper.hp==23 and w.keeper.stamina==72 and maid.coffee_wait==4,"Coffee restores HP/stamina then pauses one second")
	C.animal_step(w,maid);check(w.keeper.hp==23,"Coffee cannot repeat within delivery pause")
	maid.coffee_served=[-1,w.animals[0].id];w.tick=4;maid.coffee_wait=0;maid.hp=20
	C.animal_step(w,maid);check(maid.hp==23 and maid.coffee_rest_until==44,"After the circuit maid drinks then rests")
	e=enemy(w,"destroyer",Vector2i(8,10));maid.ultimate_gauge=100
	C.animal_step(w,maid)
	check(maid.rage_until==28 and maid.ultimate_gauge==5 and e.hp==e.max_hp-12,"Maid READY triggers actual rage against enemies")
	cow=add(w,"cow",Vector2i(7,11));var chp=cow.hp;C.animal_step(w,maid)
	check(cow.hp==chp,"Rage never targets friendly cow")
	maid.mode="rest";maid.ultimate_gauge=100;C.animal_step(w,maid)
	check(maid.state=="休む" and maid.ultimate_gauge==100,"Explicit rest suppresses rage activation")
	w=open_world();var dancer=enemy(w,"dancer",Vector2i(10,10));var martial=enemy(w,"martial_artist",Vector2i(11,10));var other=enemy(w,"salaryman",Vector2i(10,11))
	P.enemy_hurt(w,martial,999);P.enemy_hurt(w,other,999)
	check(martial.get("downed",false) and not martial.flee and not martial.get("loot_granted",false),"Downed ally remains revivable without rewards")
	dancer.hp=17;dancer.ultimate_gauge=100;C.enemy_step(w,dancer)
	check(martial.hp==17 and martial.revived and not martial.downed and other.hp==0,"Dancer revives martial first with capped HP")
	check(dancer.ultimate_gauge==0,"Resurrection spends gauge once")
	P.enemy_hurt(w,martial,999);check(not martial.revivable and martial.flee,"Each target is revivable at most once")
	var coins=w.metrics.coins;w.tick+=44;C.enemy_step(w,other);P.tick(w);P.tick(w)
	check(other.flee and other.loot_granted and w.metrics.coins<=coins+5,"Expiry finalizes once, repeated ticks do not duplicate loot")
	w=open_world();dancer=enemy(w,"dancer",Vector2i(12,10));other=enemy(w,"destroyer",Vector2i(13,10));C.enemy_step(w,dancer)
	check(is_equal_approx(C.speed(w,other),1.15),"Dance affects nearby same army")
	w.tick+=3;check(is_equal_approx(C.speed(w,other),1.0),"Dance fades when no longer refreshed")
	w=open_world();e=enemy(w,"thief",Vector2i(12,10));e.poison_at=9999
	w.field_items=[{"id":"fossil1","kind":"fossil","pos":Vector2i(13,10),"placed":true}]
	C.enemy_step(w,e);check(w.field_items.is_empty() and e.stolen.id=="fossil1","Thief approaches and takes existing object")
	P.enemy_hurt(w,e,999);check(w.field_items.size()==1 and e.stolen.is_empty() and w.field_items[0].pos==e.pos,"Defeat returns original stolen item once")
	P.enemy_hurt(w,e,999);check(w.field_items.size()==1,"Repeated defeat cannot duplicate stolen item")
	w=open_world();e=enemy(w,"thief",w.exit_for(w.entries[0]));e.stolen={"id":"fossil2","kind":"fossil","pos":e.pos}
	C.enemy_step(w,e);check(e.done and e.stolen.is_empty() and w.milestones.back().kind=="theft_committed","Theft commits only at existing map exit boundary")
	w=open_world();e=enemy(w,"thief",w.keeper.pos+Vector2i(3,0));e.can_see_keeper=true;C.enemy_step(w,e)
	check(w.keeper.get("poison_until",0)==20 and is_equal_approx(C.speed(w,w.keeper),0.8),"Poison applies bounded movement debuff")
	var initial=w.keeper.hp;w.tick=4;C.tick(w)
	check(w.keeper.hp==initial-1,"Poison uses actual damage pipeline once per second")
	w.tick=20;C.tick(w);check(is_equal_approx(C.speed(w,w.keeper),1.0),"Poison expires without permanent attribute changes")
	check(P.Encounters.plan(9,31,0).chosen[0]=="dancer" and P.Encounters.plan(10,31,0).chosen[0]=="thief","New enemies enter progression after original learning nights")
	w=open_world();maid=add(w,"maid",Vector2i(12,10));w.keeper.hp=12;w.keeper.sleepiness=0
	for i in range(80):
		w.step()
		if w.skill_log.any(func(event):return event.get("skill")=="coffee_support" and event.get("target")==-1):break
	check(w.skill_log.any(func(event):return event.get("skill")=="coffee_support" and event.get("target")==-1) and maid.path.size()>1,"Normal fixed tick moves maid physically before coffee")
	e=enemy(w,"animal_tamer",maid.pos+Vector2i.RIGHT)
	check(not P.tame(w,e,maid) and not maid.has("abductor"),"Animal-only taming cannot abduct Human companion")
	w=open_world();bull=add(w,"bull",Vector2i(8,10));bull.mode="stay"
	check(w.queue_order("charge",[bull.id],Vector2i(12,10)),"Bull charge is an ordinary local order job")
	for i in range(60):w.step()
	check(w.jobs.is_empty() and bull.path.any(func(p):return p==Vector2i(12,10)),"Local order executes physical charge in world.step")
	w=open_world();e=enemy(w,"thief",Vector2i(12,10));e.stolen={"id":"pending","kind":"fossil","pos":e.pos}
	w.start_night();w.finish(true)
	check(w.result=="" and e.stolen.id=="pending","Night cannot erase stolen object before recovery or boundary")
	var receipt=JSON.parse_string(FileAccess.get_file_as_string("res://art_delivery/direction_index.json"))
	var visuals=preload("res://game/direction_art.gd")
	for id in receipt:
		check(visuals.ASSETS[id].anchor==Vector2(receipt[id][2][0],receipt[id][2][1]),"Exact delivered anchor "+id)
	print("RANCH_CONTENT: %d checks, failures=%d"%[checks,failures]);quit(1 if failures else 0)

