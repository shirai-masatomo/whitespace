extends "res://tests/test_controls.gd"

func empty_night():
	var w=Farm.new({},31).begin_day();w.start_night();w.spawn_schedule.clear();w.enemies.clear();w.trees.clear()
	# Real campaigns retain the Shiba record, including when no defenders are placed.
	for a in w.animals:a.placed=false
	w.keeper.pos=Vector2i(3,3);w.keeper.state="hidden_rest";w.keeper.hp=1
	return w

func run():
	root.size=Vector2i(1280,800);game=load("res://game/main.tscn").instantiate();game.automated=true
	game.world=empty_night();root.add_child(game);game.set_process(false);await process_frame
	for role in ["destroyer","salaryman","idol_breaker"]:
		var w=empty_night();game.world=w;game.reset_view();game.refresh();game.speed=4;game.seen_danger=w.danger_serial
		w.spawn_enemy({"entry":w.entries[0],"role":role,"lv":1});var e=w.enemies.back();e.pos=w.Story.goals(w)[0]
		var before=w.story.idol.hp;var serial=w.danger_serial
		game.seen_danger=serial # Exclude the independent spawn notification.
		if role=="idol_breaker":w.Story.idol_enemy(w,e)
		else:w.Progression.strike(w,e,{"kind":"idol","id":-1,"pos":w.Story.at(w)})
		check(w.story.idol.hp==before-e.object_attack_power,"Damage values stay unchanged: "+role)
		check(w.danger_serial>serial,"Every real idol hit signals danger: "+role)
		game.sync_danger();check(game.speed==1,"Every idol attack cancels UI fast speed: "+role)
		check(w.player_events.any(func(row):return "黄金像" in row.text),"Visible feed identifies the threatened object: "+role)
		var feed_count=w.player_events.size();var hp=w.story.idol.hp;serial=w.danger_serial
		w.Story.damage(w,0);w.Story.damage(w,-1)
		check(w.story.idol.hp==hp and w.danger_serial==serial,"Non-damaging calls do not heal or signal danger: "+role)
		w.Story.damage(w,1)
		check(w.player_events.size()==feed_count,"Repeated idol hits use the existing feed throttle: "+role)
	for role in ["idol_breaker","idol_extractor"]:
		var w=empty_night();var contacts=w.Story.goals(w)
		for p in contacts:
			w.structures[p]={"id":100+p.y*25+p.x,"kind":"wall","status":"ready","hp":8,"max_hp":8,"armor":0,"open":false}
		check(w.Story.goals(w).is_empty(),"Keeper jobs still cannot use intact wall cells: "+role)
		w.spawn_enemy({"entry":Vector2i(12,1),"role":role,"lv":1});var e=w.enemies.back();e.pos=Vector2i(12,4)
		var start=e.pos
		for i in range(240):
			w.tick+=1;w.Combat.recover(e,w.DT);w.Story.idol_enemy(w,e)
		check(e.pos!=start and w.structures.values().any(func(b):return b.hp<8),"A surrounded idol does not freeze the specialist: "+role)
		check(w.story.idol.hp<180 if role=="idol_breaker" else w.story.idol.state!="installed","Breaking an approach restores the intended objective: "+role)
		check(not w.blocks(e.pos) and e.pos not in w.Story.idol_cells(w),"Specialist never passes through intact walls or idol: "+role)
		for i in range(1400):
			if w.result!="":break
			w.step()
		check(w.result!="","A surrounded, undefended idol reaches a result in bounded real steps: "+role)
	game.queue_free();await process_frame
	print("IDOL_RESPONSE: %d checks, failures=%d"%[checks,failures]);quit(1 if failures else 0)
