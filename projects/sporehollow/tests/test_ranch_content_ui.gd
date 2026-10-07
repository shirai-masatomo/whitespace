extends "res://tests/test_controls.gd"
func press(id: String):
	check(game.buttons.has(id),"Button exists: "+id)
	if game.buttons.has(id):await mouse(game.buttons[id].get_global_rect().get_center())
func run():
	output=OS.get_environment("FARM_REVIEW_OUTPUT")
	if DisplayServer.get_name()!="headless" and (output=="" or not "--isolated-review" in OS.get_cmdline_user_args()):quit(2);return
	root.size=Vector2i(1280,800)
	game=load("res://game/main.tscn").instantiate();game.automated=true
	var campaign=Farm.new_campaign();campaign.day=6;campaign.gold=500
	game.world=Farm.new(campaign,17);root.add_child(game);game.set_process(false);await process_frame
	game.story_modal="";game.arrival_started=-10;game.refresh()
	var w=game.world
	for id in ["maid","cow","bull"]:check(w.buy(id),"New character purchased through existing transaction: "+id)
	check(w.animals.size()==4 and w.animals.all(func(a):return a.placed),"All new companions are real residents")
	check(not w.sell("maid",w.animals[1].id),"Friendly human is not sale inventory")
	w.add_item("kokeshi",1);w.add_item("fossil",1)
	game.world=w.begin_day();w=game.world;w.paused=true
	# Controlled open stage for UI and image checks; original forest outside remains.
	for y in range(6,13):
		for x in range(5,18):w.trees.erase(Vector2i(x,y));w.natural.erase(Vector2i(x,y))
	w.keeper.pos=Vector2i(7,11)
	for i in range(w.animals.size()):w.animals[i].pos=Vector2i(8+i*2,10);w.animals[i].home=w.animals[i].pos
	game.reset_view();game.camera.position=game.center(Vector2i(11,9));game.camera.zoom=Vector2(1.4,1.4);game.refresh();game._process(0)
	var cow=w.animals.filter(func(a):return a.species=="cow")[0]
	await mouse(game.screen_cell(cow.pos))
	check(game.selected_animal==cow.id,"Click selects cow using its visible body")
	game.select_tool("milk",false);check(w.jobs.is_empty(),"Choosing milk without activation does not queue")
	await press("milk");check(w.jobs.size()==1 and w.jobs[0].kind=="milk" and w.item_count("milk")==0,"Explicit milk button reserves only, paused")
	w.Jobs.cancel(w,w.jobs[0].id)
	game.select_group(0);await press("place_kokeshi")
	await mouse(game.screen_cell(Vector2i(10,8)))
	check(w.jobs.size()==1 and w.jobs[0].kind=="place_kokeshi" and w.item_count("kokeshi")==1,"Placeable click is a reservation, not remote execution")
	w.Jobs.cancel(w,w.jobs[0].id)
	var bull=w.animals.filter(func(a):return a.species=="bull")[0]
	game.neutral();await mouse(game.screen_cell(bull.pos));await press("charge")
	await mouse(game.screen_cell(Vector2i(17,10)))
	check(w.jobs.size()==1 and w.jobs[0].order=="charge" and bull.pos==Vector2i(14,10),"Bull destination queues a local command while paused")
	w.Jobs.cancel(w,w.jobs[0].id);game.neutral()
	w.field_items=[{"kind":"kokeshi","pos":Vector2i(10,8),"placed":true},{"kind":"fossil","pos":Vector2i(16,8),"placed":true}]
	game.refresh();game._process(0);await capture("01_residents_forest_placeables")
	# Adopted portrait and rarity/skill UI are used by the actual book.
	w.phase="shop";game.morning_screen="morning";game.open_book();game.book_motion="";game.training_id=1;game.refresh();game._process(0)
	check(game.Assets.texture("shiba","portrait").get_size()==Vector2(192,192),"Book uses supplied Portrait, not enlarged world sprite")
	check(game.Assets.skill_texture("bark").get_size()==Vector2(64,64),"Formal skill icon is connected")
	await capture("02_portrait_rarity_skill")
	w.phase="day";game.morning_screen="morning";game.shop_side="buy";game.book_motion="";game.training_id=-1
	for id in ["dancer","thief","destroyer","martial_artist","ninja"]:
		w.spawn_enemy({"role":id,"entry":w.entries[0],"debug_single":true});var e=w.enemies.back();e.pos=Vector2i(6+w.enemies.size()*2,12);e.facing=-1
	var dancer=w.enemies[0];dancer.action_id="fan_spread"
	var thief=w.enemies[1];thief.action_id="poison_windup";thief.poison_fired=w.tick;thief.poison_visual_until=w.tick+3;thief.poison_target=w.keeper.pos
	var maid=w.animals[1];maid.action_id="rage";maid.ultimate_gauge=100
	game.reset_view();game.camera.position=game.center(Vector2i(11,10));game.camera.zoom=Vector2(1.4,1.4);game.refresh();game._process(0)
	var destroyer=w.enemies[2];destroyer.action_id="iron_ball_hit";destroyer.next_attack=w.tick+1
	game.enemy_art[destroyer.id].attack=destroyer.next_attack
	game.ProgressArt.update(game,destroyer,true)
	check(game.enemy_art[destroyer.id].action=="iron_ball_windup","Destroyer cooldown anticipates formal windup")
	var martial=w.enemies[3];martial.action_id="attack";game.ProgressArt.update(game,martial,true)
	check(game.enemy_art[martial.id].action=="stance","Martial holds formal stance between strikes")
	for i in range(2):martial.next_attack+=4;game.ProgressArt.update(game,martial,true)
	check(game.enemy_art[martial.id].action=="kick","Martial second real strike uses kick, no additional hit")
	var ninja=w.enemies[4];ninja.chosen_target={"pos":w.keeper.pos};ninja.shuriken_at=4;game.enemy_art[ninja.id].shuriken=0;game.ProgressArt.update(game,ninja,true)
	check(game.enemy_art[ninja.id].has("shot_to"),"Ninja flight records actual target at throw")
	game.visual_time+=0.22;game.queue_redraw();await capture("03_battle_keyposes_formal_motion")
	check(w.tick==0 and w.paused,"UI test did not advance paused world")
	if output!="":
		record.implementation_commit=OS.get_environment("FARM_REVIEW_COMMIT");record.dirty=OS.get_environment("FARM_REVIEW_DIRTY")
		record.asset_delivery_commit=JSON.parse_string(FileAccess.get_file_as_string("res://game/direction_receipt.json")).source_commit
		record.method="Current game with controlled day6/500G fixture, actual mouse inputs; battle keyposes explicitly staged. No live user data."
		FileAccess.open(output+"/observations.json",FileAccess.WRITE).store_string(JSON.stringify(record,"  "))
	print("RANCH_CONTENT_UI: %d checks, failures=%d"%[checks,failures]);quit(1 if failures else 0)
