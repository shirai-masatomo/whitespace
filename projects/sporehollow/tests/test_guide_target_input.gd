extends "res://tests/test_controls.gd"
const Fixture=preload("res://tests/review_guide_fixture.gd")

func run():
	game=load("res://game/main.tscn").instantiate();game.automated=true;game.world=Fixture.create()
	root.size=Vector2i(1280,800);root.add_child(game);game.set_process(false);await process_frame
	game.reset_view();game.refresh();await process_frame
	for paused in [true,false]:
		game.world=Fixture.create();game.world.paused=paused;game.reset_view();game.refresh();await process_frame
		var w=game.world
		for point in [Vector2i(9,10),Vector2i(12,11),Vector2i(-1,-1),Vector2i(12,8)]:
			var target=w.animals[1].pos if point==Vector2i(-1,-1) else point
			game.choose_animal(1);game.select_tool("guide",false);await process_frame
			await mouse(game.screen_cell(target))
			check(game.group==1 and game.tool=="guide" and game.selected_animals==[1],"Destination retains the original animal and guide intent: "+str(target)+" paused="+str(paused))
			check(w.jobs.size()==1 and w.jobs[0].kind=="animal_order" and w.jobs[0].order=="guide" and w.jobs[0].targets[0].id==1 and w.jobs[0].command_pos==target,"Object click queues the intended guide, not selection/collection/demolition")
			if w.jobs.is_empty():continue
			var j=w.jobs[0];var dest=j.targets[0].dest
			check(w.animal_walkable(w.animals[0],dest) and not w.actor_occupied(dest,w.animals[0].pos),"Destination is an available physical cell near the clicked point")
			if paused:
				var tick=w.tick;w.step();check(w.tick==tick and not j.targets[0].issued,"Paused guide is a reservation only")
				w.paused=false
			for i in range(160):
				w.step()
				if w.jobs.is_empty():break
			check(w.jobs.is_empty() and w.animals[0].mode=="auto" and not w.animals[0].has("guide_job") and w.job_log.any(func(e):return e.event=="guide_arrived" and e.id==j.id),"Guide reaches its assigned point and returns the same animal to auto")
			w.paused=paused
	game.world=Fixture.create();var w=game.world;w.paused=true
	game.reset_view();game.choose_animal(1);game.select_tool("guide",false);game.refresh();await process_frame
	await mouse(game.screen_cell(Vector2i(12,11)))
	var queued=w.jobs[0].id
	await mouse(game.screen_cell(Vector2i(20,3)),MOUSE_BUTTON_RIGHT)
	check(game.tool=="" and w.jobs.size()==1 and w.jobs[0].id==queued,"Right click away from plans exits destination mode without deleting the queued order")
	await mouse(game.screen_cell(w.animals[1].pos))
	check(game.selected_animals==[2] and game.tool=="" and w.jobs[0].targets[0].id==1,"Normal animal selection cannot redirect an existing order to a different individual")
	await mouse(game.screen_cell(Vector2i(12,8)))
	check(game.selected.get("kind")=="idol" and w.jobs[0].id==queued,"Normal idol selection remains available after leaving guide mode")
	w.Jobs.cancel(w,queued);game.neutral();await mouse(game.screen_cell(Vector2i(12,11)))
	check(game.selected.get("kind")=="structure","Normal building selection remains available")
	game.choose_animal(1);game.select_tool("guide",false);w.indoor[Vector2i(10,10)]=true
	await mouse(game.screen_cell(Vector2i(10,10)))
	check(w.jobs.is_empty() and game.tool=="guide" and game.selected_animals==[1] and game.message.contains("屋内不可"),"Rejected destination explains why and retains guide intent")
	check(game.guide_nearby_target(Vector2i(12,11)) and game.guide_nearby_target(w.animals[1].pos) and game.guide_nearby_target(Vector2i(12,8)) and not game.guide_nearby_target(Vector2i(20,3)),"Object previews distinguish a nearby destination from exact empty ground")
	game.queue_free();await process_frame
	print("GUIDE_TARGET_INPUT: %d checks, failures=%d"%[checks,failures]);quit(1 if failures else 0)
