extends "res://tests/test_controls.gd"
const Fixture=preload("res://tests/review_mixed_fixture.gd")

func run():
	game=load("res://game/main.tscn").instantiate();game.automated=true;game.world=Fixture.create(true)
	root.add_child(game);game.set_process(false);await process_frame
	var w=game.world;var hen=w.animals[1];var tamer=w.enemies[0];var dancer=w.enemies[1]
	check(hen.abductor==tamer.id and tamer.led_animal==hen.id,"The normal taming rule creates both sides of capture")
	check(game.animal_status_label(hen)=="連れ去り中","A captured healthy hen is labelled as needing rescue, not convalescent")
	w.finish(true);check(w.phase=="defend","Night cannot settle while a living enemy leads an animal")
	w.Progression.enemy_hurt(w,tamer,999)
	check(hen.get("abductor",-1)<0 and tamer.led_animal<0 and w.Orders.active(w,hen),"Defeating the captor releases the same living resident")
	check(game.animal_status_label(hen)=="","A rescued healthy animal has no recovery-day promise")
	w.Content.enemy_step(w,dancer)
	check(tamer.get("revived",false) and tamer.hp>0 and tamer.led_animal<0 and hen.get("abductor",-1)<0,"Revival cannot restore the old abduction link")
	w.Progression.enemy_hurt(w,tamer,999);dancer.ultimate_gauge=100;w.Content.enemy_step(w,dancer)
	check(tamer.hp==0 and not tamer.revivable,"A defeated revived captor cannot resurrect twice")
	w.Progression.enemy_hurt(w,dancer,999)
	for i in range(36):w.step()
	check(w.enemies.all(func(e):return e.done) and w.early_clear,"Corpse expiry resolves the encounter without an orphaned capture")
	w.finish(true);var morning=Farm.new(w.next_campaign(),32)
	check(morning.campaign.day==10 and morning.animals.any(func(a):return a.id==hen.id),"The rescued resident survives the next morning")
	game.world=Fixture.create();w=game.world;var dog=w.animals[0]
	w.Progression.animal_hurt(w,dog,{"id":-1},999)
	check(game.animal_status_label(dog)=="療養：11日目の朝に復帰","Actual Shiba convalescence retains its real return day")
	w.Progression.remove_animal(w,w.animals[1],"abducted")
	check(game.animal_status_label(w.animals[1])=="","A permanently lost animal is not promised recovery")
	game.queue_free();await process_frame
	print("MIXED_RESCUE: %d checks, failures=%d"%[checks,failures]);quit(1 if failures else 0)
