extends "res://tests/test_controls.gd"
func run():
	root.size=Vector2i(1280,800)
	game=load("res://game/main.tscn").instantiate();game.automated=true;game.world=Farm.new({},17)
	root.add_child(game);await process_frame
	var original=game.world.story.duplicate(true)
	game.StoryView.open(game,"intro");await process_frame
	await mouse(Vector2(720,390));await key(KEY_TAB)
	check(game.world.tick==0 and game.world.jobs.is_empty() and game.group==-1,"Intro blocks world input without advancing time")
	await mouse(game.buttons.story_close.get_global_rect().get_center())
	original.intro_seen=true
	check(game.story_modal=="" and game.world.story==original,"Intro skip changes only the seen marker")
	game.StoryView.open(game,"diary");await process_frame;await key(KEY_ESCAPE)
	check(game.story_modal=="" and game.world.tick==0,"Diary closes safely with world frozen")
	game.world=Farm.new({},17).begin_day();game.world.paused=true;game.reset_view();game.refresh()
	var tree=game.world.trees.keys()[0]
	await mouse(game.screen_cell(tree))
	check(game.selected.get("kind")=="tree" and game.buttons.has("clear_tree"),"Tree click opens local clearing control")
	await mouse(game.buttons.clear_tree.get_global_rect().get_center())
	check(game.world.jobs.is_empty() and game.buttons.clear_tree.disabled and game.world.trees.has(tree),"Tool-required control is disabled without affecting tree")
	game.choose_walk();await mouse(game.screen_cell(Vector2i(12,8)))
	check(game.selected.get("kind")=="idol" and game.world.manual_goal==null,"Idol selection takes priority over ground movement")
	await mouse(game.buttons.inspect_idol.get_global_rect().get_center())
	check(game.world.jobs.size()==1 and game.world.jobs[0].kind=="inspect_idol","Idol inspection uses ordinary queued onsite work")
	await mouse(Vector2(700,430),MOUSE_BUTTON_RIGHT)
	check(game.group==-1 and game.world.jobs.size()==1,"Right click deselects without cancelling story job")
	game.world=Farm.new({},17).begin_day();game.world.paused=true;game.reset_view();game.refresh()
	game.selected_trees.clear()
	for cell in game.world.trees:game.toggle_selection(game.selected_trees,cell)
	game.selected={"kind":"tree","pos":game.selected_trees[0]};game.refresh()
	check(game.selected_trees.size()==8,"Trees share the eight-target selection cap")
	game.story_action("clear_tree")
	check(game.world.jobs.is_empty(),"Bulk bare-hand clearing also rejected")
	game.world=Farm.new({},17).begin_day();game.world.paused=true;game.reset_view();game.select_group(0);game.tool="wall";game.refresh()
	await mouse(game.screen_cell(tree))
	check(game.tool=="wall" and game.world.jobs.is_empty(),"Construction over tree keeps tool and does not silently clear")
	var c=Farm.new_campaign();c.day=3;game.world=Farm.new(c,17);game.reset_view();game.refresh()
	var snapshot=JSON.stringify(game.world.story);var gold=game.world.campaign.gold
	for i in range(2):
		await mouse(game.buttons.radio.get_global_rect().get_center());await key(KEY_TAB)
		await mouse(game.buttons.story_close.get_global_rect().get_center())
	check(JSON.stringify(game.world.story)==snapshot and game.world.campaign.gold==gold and game.world.tick==0,"Repeated radio input is readonly and time-free")
	print("STORY UI: ",checks," checks, failures=",failures)
	quit(1 if failures else 0)
