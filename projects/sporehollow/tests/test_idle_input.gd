extends "res://tests/test_playthrough_ui.gd"
func run():
	check(DisplayServer.get_name()=="headless","Input checks remain headless")
	root.size=Vector2i(1280,800);game=load("res://game/main.tscn").instantiate();game.automated=true
	game.world=Farm.new({},31).begin_day();root.add_child(game);game.set_process(false);await process_frame
	await fresh();var w=game.world;w.keeper.sleepiness=20
	await ticks(20);check(not w.keeper.resting,"Five inactive seconds no longer start automatic rest")
	await ticks(11);check(not w.keeper.resting,"Automatic rest does not start before eight seconds")
	await key(KEY_TAB);check(w.keeper.idle_elapsed==0,"Mode selection resets inactivity without issuing a job")
	await ticks(31);check(not w.keeper.resting,"Input postpones the full eight-second interval")
	await ticks(1);check(w.keeper.resting and w.keeper.rest_kind=="auto","Eight inactive seconds start automatic rest")
	await ticks(19);check(not w.keeper.asleep,"Outdoor sleep onset remains five more seconds")
	await ticks(1);check(w.keeper.asleep,"Outdoor sleep follows thirteen inactive seconds overall")
	var motion=InputEventMouseMotion.new();motion.position=Vector2(650,400);motion.relative=Vector2(2,0);Input.parse_input_event(motion);await process_frame
	check(not w.keeper.resting and w.keeper.idle_elapsed==0,"Real pointer motion wakes automatic rest")
	for context in ["menu","book","queue_drag","camera"]:
		await fresh();w=game.world;w.keeper.sleepiness=20;await ticks(28)
		if context=="menu":game.toggle_menu()
		elif context=="book":game.open_book()
		elif context=="queue_drag":game.queue_drag_id=777
		else:game.keys_down[KEY_D]=true
		await ticks(48)
		check(not w.keeper.resting and w.keeper.idle_elapsed==0,"Sustained UI activity is not inactivity: "+context)
		if context=="menu":game.toggle_menu()
		elif context=="book":game.field_book=false
		elif context=="queue_drag":game.queue_drag_id=-1
		else:game.keys_down.clear()
	for state in ["manual","forced","unconscious","hidden_rest"]:
		await fresh();w=game.world
		if state in ["manual","forced"]:
			w.Life.set_rest(w,true,state);w.keeper.forced_rest=state=="forced"
		else:w.keeper.hp=0;w.keeper.state=state
		await key(KEY_TAB)
		check(w.keeper.resting if state in ["manual","forced"] else w.keeper.state==state,"UI activity cannot bypass "+state)
	await fresh();w=game.world;w.keeper.sleepiness=20
	check(w.act("keeper_move",Vector2i(15,10)),"Queued movement accepted")
	await ticks(12);check(not w.keeper.resting and w.keeper.idle_elapsed==0,"Executing a queued job is not inactivity")
	game.queue_free();await process_frame
	print("IDLE_INPUT: %d checks, failures=%d"%[checks,failures]);quit(1 if failures else 0)
