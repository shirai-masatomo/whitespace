extends "res://tests/test_controls.gd"
const Motion=preload("res://game/six_motion.gd")
func run():
	output=OS.get_environment("FARM_REVIEW_OUTPUT")
	if DisplayServer.get_name()!="headless" and (output=="" or not "--isolated-review" in OS.get_cmdline_user_args()):quit(2);return
	root.size=Vector2i(1280,800)
	game=load("res://game/main.tscn").instantiate();game.automated=true;game.world=Farm.new({},31).begin_day();root.add_child(game);game.set_process(false);await process_frame
	var w=game.world;w.paused=true;game.story_modal="";game.reset_view();game.refresh();game._process(0)
	var frames=0
	for id in Motion.Data.CLIPS:
		var parts=id.split("/");var c=Motion.Data.CLIPS[id]
		for f in c.frames:
			check(f.texture.get_image().get_used_rect().has_area() and f.anchor.y<=f.texture.get_height(),"Delivered frame: "+f.texture.resource_path);frames+=1
		if not c.loop:check(Motion.frame(parts[0],parts[1],-1 if parts[2]=="left" else 1,99).texture==c.frames.back().texture,"Non-loop holds final: "+id)
	check(frames==320,"All six deliveries connected: 320 PNG")
	for who in ["maid","dancer","thief"]:w.spawn_enemy({"role":who,"entry":w.entries[0],"debug_single":true})
	for i in range(w.enemies.size()):w.enemies[i].pos=Vector2i(8+i*3,10)
	var maid=w.enemies[0];var id="e"+str(maid.id)
	Motion.update(game,maid,true);maid.pos.x+=1;game.view_positions[id]=Vector2(maid.pos)-Vector2(0.5,0);Motion.update(game,maid,true)
	check(game.six_art[id].action=="walk" and game.six_art[id].facing==1,"Right walking uses delivered sequence")
	maid.pos.x-=1;game.view_positions[id]=Vector2(maid.pos)+Vector2(0.5,0);Motion.update(game,maid,true)
	game.view_positions[id]=Vector2(maid.pos);Motion.update(game,maid,true)
	check(game.six_art[id].action=="idle" and game.six_art[id].facing==-1,"Left stop retains direction")
	var t=game.visual_time;game._process(0.3);check(game.visual_time==t,"Pause freezes motion clock")
	Motion.skill(game,{"skill":"coffee_support","actor":maid.id,"faction":"enemy"});Motion.update(game,maid,true)
	check(game.six_art[id].action=="coffee_serve","Coffee event selects serve, not attack")
	game.visual_time+=1.5;Motion.update(game,maid,true);check(game.six_art[id].action=="twirl","Serve exits into short twirl")
	game.visual_time+=1;Motion.update(game,maid,true);check(game.six_art[id].action=="idle","Support visual does not loop forever")
	maid.rage_until=w.tick+24;Motion.update(game,maid,true);check(game.six_art[id].action=="rage_start","Rage begins once")
	game.visual_time+=0.5;maid.next_attack+=4;Motion.update(game,maid,true);check(game.six_art[id].action=="rage_attack","Rage attack uses knife motion")
	maid.rage_until=0;game.visual_time+=0.5;Motion.update(game,maid,true);check(game.six_art[id].action=="rage_end","Rage ends into normal equipment")
	var hp=maid.hp;maid.hp=0;Motion.update(game,maid,true);check(game.six_art[id].action=="death","Down uses delivered collapse")
	maid.hp=hp;game.visual_time+=1;Motion.update(game,maid,true);check(game.six_art[id].action=="get_up","Revived actor uses get-up")
	for who in ["cow","bull"]:
		var owned={"id":w.campaign.next_animal_id,"species":who,"lv":1,"loyalty":85,"name":"","unavailable_through_day":0};w.campaign.next_animal_id+=1;w.campaign.animals.append(owned);w.add_resident(owned)
	var cow=w.animals.filter(func(a):return a.species=="cow")[0];var bull=w.animals.filter(func(a):return a.species=="bull")[0]
	cow.pos=Vector2i(10,13);bull.pos=Vector2i(15,13)
	Motion.update(game,cow,false);w.jobs=[{"id":99,"kind":"milk","animal_id":cow.id,"state":"working","pos":cow.pos}];Motion.update(game,cow,false)
	check(game.six_art["a"+str(cow.id)].action=="milking_start","Local milk job starts animation")
	game.visual_time+=0.5;Motion.update(game,cow,false);check(game.six_art["a"+str(cow.id)].action=="milking_hold","Milk holds while job works")
	w.jobs.clear();Motion.update(game,cow,false);check(game.six_art["a"+str(cow.id)].action=="milking_end","Cancel/completion exits milk pose")
	Motion.update(game,bull,false);bull.mode="charge";Motion.update(game,bull,false);check(game.six_art["a"+str(bull.id)].action=="charge_start","Charge starts")
	game.visual_time+=0.6;Motion.update(game,bull,false);check(game.six_art["a"+str(bull.id)].action=="charge","Charge loop follows start")
	bull.mode="auto";Motion.update(game,bull,false);check(game.six_art["a"+str(bull.id)].action=="charge_end","Blocked or completed charge ends")
	# Two representative game-render fixtures; no world rules are altered for the art.
	for e in w.enemies:game.view_positions["e"+str(e.id)]=Vector2(e.pos)
	for a in w.animals:game.view_positions["a"+str(a.id)]=Vector2(a.pos)
	for y in range(8,15):
		for x in range(5,20):w.trees.erase(Vector2i(x,y));w.natural.erase(Vector2i(x,y))
	game.neutral();game.camera.zoom=Vector2(1.6,1.6);game.camera.position=game.center(Vector2i(12,11));game._process(0)
	for e in w.enemies:game.six_art["e"+str(e.id)]={"action":"run" if e.archetype=="thief" else "walk","at":game.visual_time-0.2,"facing":-1}
	game.six_art["a"+str(cow.id)]={"action":"walk","at":game.visual_time-0.2,"facing":-1}
	game.six_art["a"+str(bull.id)]={"action":"run","at":game.visual_time-0.2,"facing":-1}
	game.queue_redraw();await capture("01_left_motion")
	game.six_art["e"+str(maid.id)]={"action":"coffee_serve","at":game.visual_time-0.2,"facing":1}
	game.six_art["e"+str(w.enemies[1].id)]={"action":"ultimate","at":game.visual_time-0.4,"facing":1}
	w.enemies[2].stolen={"kind":"fossil"};game.six_art["e"+str(w.enemies[2].id)]={"action":"steal","at":game.visual_time-0.2,"facing":1}
	game.six_art["a"+str(cow.id)]={"action":"milking_hold","at":game.visual_time,"facing":1}
	bull.hp=1;game.six_art["a"+str(bull.id)]={"action":"guts","at":game.visual_time-0.2,"facing":1}
	game.queue_redraw();await capture("02_actions")
	game.departure_started=game.clock-0.05;game.camera.position=game.center(Vector2i(3,5));game.camera.zoom=Vector2(2,2)
	game.queue_redraw();await capture("03_departing_cart")
	if output!="":FileAccess.open(output+"/observations.json",FileAccess.WRITE).store_string(JSON.stringify(record,"  "))
	print("SIX MOTION: %d checks, failures=%d"%[checks,failures]);quit(1 if failures else 0)
