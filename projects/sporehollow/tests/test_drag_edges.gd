extends "res://tests/test_selection_controls.gd"
func run():
	var out=OS.get_environment("FARM_REVIEW_OUTPUT")
	if out=="" or "--isolated-review" not in OS.get_cmdline_user_args():quit(2);return
	root.size=Vector2i(1280,800);root.content_scale_size=Vector2i(1280,800)
	game=load("res://game/main.tscn").instantiate();game.automated=true;game.world=Farm.new({},31).begin_day();game.world.story.intro_seen=true;game.world.paused=true
	root.add_child(game);await process_frame;await process_frame;game.set_process(false)
	var w=game.world;w.trees.clear();w.rocks.clear();w.natural.clear();w.mountains.clear();w.field_items.clear();w.jobs.clear()
	var anchor=Vector2i(30,25);w.Stock.add(w,"wood",8,anchor)
	var points=[Vector2(640,450),Vector2(640,0),Vector2(640,799),Vector2(0,400),Vector2(1279,400),Vector2(0,0),Vector2(1279,0),Vector2(0,799),Vector2(1279,799),Vector2(330,780),Vector2(640,-40),Vector2(1300,400)]
	for zoom in [0.65,1.0,1.5]:
		for offset in [Vector2.ZERO,Vector2(70,40)]:
			game.camera.zoom=Vector2.ONE*zoom;game.camera.position=game.center(anchor)+offset;game.camera.force_update_scroll();await process_frame
			for end in points:
				game.neutral();await held_drag(at(anchor),end);await release(end)
				check(anchor in game.selected_resources and not game.press_pending and not game.dragging,"World drag ends on UI/edge; zoom="+str(zoom)+" offset="+str(offset)+" end="+str(end))
	game.neutral();var origin=at(anchor);await held_drag(origin,origin+Vector2(60,60));game.notification(Node.NOTIFICATION_WM_MOUSE_EXIT);await release(origin+Vector2(70,70))
	check(not game.dragging and not game.press_pending and game.selected_resources.is_empty(),"Leaving window cancels capture before an OS release can be lost")
	await held_drag(origin,origin+Vector2(60,60));game.notification(Node.NOTIFICATION_WM_WINDOW_FOCUS_OUT)
	check(not game.dragging and not game.press_pending,"Focus loss clears capture")
	game.neutral();var p=game.buttons.pause.get_global_rect().get_center();await held_drag(p,origin);await release(origin)
	check(game.selected_resources.is_empty(),"UI-started gesture does not become world selection")
	check(w.jobs.is_empty(),"Edge releases never fire underlying buttons or jobs")
	FileAccess.open(out+"/drag-edges.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failed,"limitation":"Window exit/focus loss notifications synthesized in Godot; real Windows taskbar/OS input not automated."},"  "))
	game.queue_free();await process_frame;quit(1 if failed else 0)
