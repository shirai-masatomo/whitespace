extends "res://tests/test_controls.gd"
func run():
	output=OS.get_environment("FARM_REVIEW_OUTPUT")
	if DisplayServer.get_name()=="headless" or output=="" or not "--isolated-review" in OS.get_cmdline_user_args():quit(2);return
	root.size=Vector2i(1280,800)
	game=load("res://game/main.tscn").instantiate();game.automated=true;game.world=Farm.new({},31).begin_day();root.add_child(game);game.set_process(false);await process_frame
	var w=game.world;game.story_modal="";w.paused=true;w.enemies.clear();w.keeper.pos=Vector2i(9,12)
	for p in w.trees.keys():
		if p.x>=9 and p.x<=17 and p.y>=8 and p.y<=13:w.trees.erase(p)
	for i in range(4):
		w.spawn_enemy({"role":["dancer","thief","dancer","kidnapper"][i],"entry":w.entries[0],"debug_single":true})
		w.enemies.back().pos=[Vector2i(12,10),Vector2i(13,10),Vector2i(12,12),Vector2i(15,12)][i]
	game.neutral();game.reset_view();game.camera.zoom=Vector2(1.65,1.65);game.camera.position=game.center(Vector2i(12,10));game.refresh();game._process(0)
	for e in w.enemies.slice(1):w.Progression.enemy_hurt(w,e,999)
	game._process(0);await process_frame;await RenderingServer.frame_post_draw
	check(w.enemies[1].dead and not w.enemies[1].done,"Dead thief renders before revival")
	w.tick+=4;w.enemies[0].hp=17;w.enemies[0].ultimate_gauge=100;w.Progression.Content.enemy_step(w,w.enemies[0])
	game._process(0);game._process(0.25)
	check(w.enemies[1].hp==17 and not w.enemies[1].dead,"Thief revived through actual skill")
	check(w.enemies[2].dead and w.enemies[3].dead,"Dancer corpse and temporary kidnapper corpse remain")
	await capture("corpse_revival")
	record.implementation_commit=OS.get_environment("FARM_REVIEW_COMMIT")
	record.asset_commit=JSON.parse_string(FileAccess.get_file_as_string("res://game/art_provenance.json")).latest_delivery_commit
	record.states=w.enemies.duplicate(true)
	record.method="Isolated GPU; controlled positions, normal lethal damage and revival skill; one representative screenshot after rendering both states."
	FileAccess.open(output+"/observations.json",FileAccess.WRITE).store_string(JSON.stringify(record,"  "))
	print("CORPSES_UI: %d checks, failures=%d"%[checks,failures]);quit(1 if failures else 0)
