extends "res://tests/test_controls.gd"
func run():
	output=OS.get_environment("FARM_REVIEW_OUTPUT")
	if DisplayServer.get_name()!="headless" and (output=="" or not "--isolated-review" in OS.get_cmdline_user_args()):quit(2);return
	root.size=Vector2i(1280,800)
	game=load("res://game/main.tscn").instantiate();game.automated=true
	game.world=Farm.new({},17).begin_day();root.add_child(game);game.set_process(false)
	await process_frame
	game.story_modal="";game.reset_view();game.refresh()
	var w=game.world
	var idol=w.story.idol.duplicate(true)
	check(game.StoryView.IDOL.get_size()==Vector2(144,160),"Adopted A native dimensions")
	check(ResourceLoader.exists("res://art_delivery/ui_world_direction_v1/candidates/world/goldB.png"),"B retained as alternative")
	check(not w.debug_action("spawn_enemy",{"enemy_kind":"ninja"}) and w.enemies.is_empty(),"Normal mode cannot spawn")
	w.paused=true
	await key(KEY_F3)
	check(game.debug_view and w.debug_enabled,"F3 enables existing debug mode")
	var schedule=w.spawn_schedule.duplicate(true);var next_wave=w.schedule_index
	var original_tick=w.tick;var original_gold=w.campaign.gold
	for kind in Farm.ProgressData.ENEMY_ROWS.keys()+["doberman"]:
		var before=w.enemies.size()
		await mouse(game.buttons["debug_enemy_"+kind].get_global_rect().get_center())
		check(game.debug_enemy_kind==kind and w.enemies.size()==before,"Choosing only selects: "+kind)
		await mouse(game.buttons.debug_spawn_enemy.get_global_rect().get_center())
		check(w.enemies.size()==before+1,"One spawn per click: "+kind)
		var e=w.enemies.back()
		check(e.archetype==kind and e.hp==e.max_hp and e.lv==1,"Existing enemy data: "+kind)
		check(not w.inside(e.pos) and w.distance(e.pos,e.entry)>10,"Valid spawn site: "+kind)
		check(not w.enemies.any(func(other):return other.id!=e.id and other.pos==e.pos),"Distinct spawn: "+kind)
	check(w.tick==original_tick and w.paused and w.campaign.gold==original_gold and w.jobs.is_empty(),"Debug UI does not leak board input or advance paused world")
	check(w.spawn_schedule==schedule and w.schedule_index==next_wave,"Debug spawn leaves normal waves intact, runner adds no surprise companion")
	check(w.story.idol==idol and w.Story.idol_cells(w).size()==4,"Image replacement preserves idol state and footprint")
	game.camera.zoom=Vector2(1.4,1.4);game.camera.position=game.center(w.Story.at(w))+game.TILE*0.5
	game._process(0)
	await capture("01_idol_A_debug_list")
	var count=w.enemies.size()
	check(not w.debug_action("spawn_enemy",{"enemy_kind":"unimplemented"}) and w.enemies.size()==count,"Unknown enemy rejected")
	var trees=w.trees.duplicate()
	for gate in w.entries:w.trees[gate]="debug-block"
	check(not w.debug_action("spawn_enemy",{"enemy_kind":"ninja"}) and w.enemies.size()==count,"Blocked entrances reject without overlap")
	w.trees=trees
	game.camera.position=game.center(w.enemies[0].pos);game.camera.zoom=Vector2(1.2,1.2)
	game.reset_view();game._process(0)
	await capture("02_debug_enemies")
	await key(KEY_F3)
	check(not w.debug_enabled and not game.buttons.has("debug_spawn_enemy"),"F3 closes debug UI")
	check(not w.debug_action("spawn_enemy",{"enemy_kind":"ninja"}),"Disabled debug remains guarded")
	var positions=w.enemies.map(func(e):return e.pos)
	w.step()
	check(w.tick==original_tick and w.enemies.map(func(e):return e.pos)==positions,"Paused spawn stays still")
	w.paused=false
	for i in range(12):w.step()
	check(w.tick>original_tick and w.enemies.map(func(e):return e.pos)!=positions,"Spawned enemies use normal AI after resume")
	if output!="":
		record.implementation_commit=OS.get_environment("FARM_REVIEW_COMMIT")
		record.asset_delivery_commit=JSON.parse_string(FileAccess.get_file_as_string("res://game/golden_idol_receipt.json")).source_commit
		record.method="Real F3 and mouse events in current game. Paused debug fixture, no user save."
		FileAccess.open(output+"/observations.json",FileAccess.WRITE).store_string(JSON.stringify(record,"  "))
	print("IDOL_DEBUG: %d checks, failures=%d"%[checks,failures]);quit(1 if failures else 0)
