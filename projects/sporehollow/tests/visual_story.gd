extends "res://tests/visual_shop.gd"
const Farm=preload("res://game/world.gd")
var evidence=[]
func capture(label: String):
	# Controlled bulk simulation may leave sprite interpolation behind; wait for actual render to settle.
	for i in range(100):
		await create_timer(0.08).timeout
		var pending=false
		for id in game.actor_tracks:
			if not game.actor_tracks[id].is_empty():pending=true
		if not pending:break
	await super.capture(label)
	evidence.append({"frame":label,"fixture":game.get_meta("fixture","normal new campaign"),"world":game.world.observation(),"modal":game.story_modal,"intro_page":game.story_page})
func board(cell: Vector2i):
	var p=game.screen_cell(cell)
	var move=InputEventMouseMotion.new();move.position=p;Input.parse_input_event(move);await process_frame
	for pressed in [true,false]:
		var e=InputEventMouseButton.new();e.position=p;e.pressed=pressed;e.button_index=MOUSE_BUTTON_LEFT
		Input.parse_input_event(e);await process_frame
func ticks(n: int):
	for i in range(n):game.world.step()
	game.refresh();await process_frame;await process_frame
func quiet(day: int):
	var c=Farm.new_campaign();c.day=day;c.world_story=game.world.story.duplicate(true)
	game.world=Farm.new(c,17).begin_day();game.world.day_seconds=90;game.world.nature_config.spawn_chance_per_second=0
	game.world.animals[0].mode="rest";game.world.animals[0].order_until=999999
	game.reset_view();game.refresh();game.set_meta("fixture","Controlled day %d; ordinary local jobs and combat simulation"%day)
func run():
	output=OS.get_environment("FARM_REVIEW_OUTPUT")
	if output=="" or not "--isolated-review" in OS.get_cmdline_user_args():quit(2);return
	root.size=Vector2i(1280,800)
	game=load("res://game/main.tscn").instantiate();game.automated=true;game.world=Farm.new({},17);root.add_child(game)
	await process_frame
	game.StoryView.open(game,"intro")
	for i in range(4):await capture("intro_%d"%i);await click("story_next")
	await capture("morning_forest")
	await click("advance");game.sky_started=-10;game.departure_started=-10
	await capture("ranch_idol_and_forest")
	var tree=game.world.trees.keys()[0]
	await board(tree);await capture("tree_selected")
	await click("clear_tree");await capture("clearing_reserved")
	await ticks(2);game.choose_walk();await capture("clearing_route")
	for i in range(200):
		if game.world.jobs.is_empty():break
		game.world.step()
	game.refresh();await capture("cleared_ground")
	await board(game.world.Story.at(game.world));await click("inspect_idol");await ticks(130);await capture("first_diary")
	# Four explicit entry fixtures, using the normal spawn and path system.
	for entry in [Vector2i(1,5),Vector2i(23,8),Vector2i(12,1),Vector2i(19,15)]:
		quiet(1);game.world.start_night();game.world.spawn_schedule.clear();game.world.spawn_enemy({"entry":entry,"role":"kidnapper"})
		await ticks(5);await capture("invasion_%d_%d"%[entry.x,entry.y])
	quiet(2)
	await board(game.world.Story.at(game.world));await click("inspect_idol");await ticks(130)
	await board(game.world.Story.at(game.world));await capture("prayer_unlocked")
	await click("pray_wealth");await ticks(5);await capture("praying")
	await ticks(30);await capture("prayer_pending")
	game.world.start_night();game.world.spawn_schedule.clear();game.world.finish(true);game.refresh();game.sky_started=-10
	await capture("miracle_dawn")
	game.world=Farm.new(game.world.next_campaign(),17);game.reset_view();game.refresh();game.arrival_started=-10
	await capture("morning_with_radio");await click("radio");await capture("radio_history");await click("story_close")
	quiet(5);game.world.start_night();game.world.spawn_schedule.clear();game.world.keeper.pos=Vector2i(6,10)
	game.world.spawn_enemy({"entry":Vector2i(12,1),"role":"idol_breaker"})
	var e=game.world.enemies[-1];e.pos=Vector2i(12,7);await ticks(8);await capture("idol_under_attack")
	e.done=true;game.world.Story.tick(game.world)
	game.world.spawn_enemy({"entry":Vector2i(12,1),"role":"idol_extractor"});e=game.world.enemies[-1];e.pos=Vector2i(12,7)
	await ticks(8);await capture("idol_unfastening")
	await ticks(32);await capture("idol_towing")
	await ticks(24);await capture("idol_towing_moved")
	e.flee=true;await ticks(1);await capture("idol_extraction_interrupted")
	await board(game.world.Story.at(game.world));await capture("idol_recover_action")
	quiet(2);game.world.start_night();game.world.spawn_schedule.clear();game.world.spawn_enemy({"entry":Vector2i(23,8),"role":"kidnapper"});e=game.world.enemies[-1]
	e.pos=Vector2i(22,8);e.carry="keeper";game.world.keeper.pos=e.pos;game.world.keeper.carrier=e.id;game.world.keeper.state="captured";game.world.keeper.hp=0
	game.world.animals[0].pos=Vector2i(21,8);game.world.animals[0].mode="auto";game.world.animals[0].order_until=0;e.hp=1
	await capture("forest_keeper_carried");await ticks(12);await capture("forest_dog_rescue")
	FileAccess.open(output+"/story-observation.json",FileAccess.WRITE).store_string(JSON.stringify({"implementation_commit":OS.get_environment("FARM_REVIEW_COMMIT"),"shots":shots,"evidence":evidence,"input_events":events,"new_art":"Explicit code-art placeholders for forest/idol; adopted characters/cart/book unchanged"},"  "))
	print("STORY_CAPTURE_OK ",shots.size());quit()
