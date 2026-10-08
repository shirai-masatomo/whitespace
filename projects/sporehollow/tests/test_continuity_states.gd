extends "res://tests/test_playthrough_ui.gd"
## Controlled state boundaries, not a balance or natural-win fixture.
func run():
	check(DisplayServer.get_name()=="headless","State review is headless and uses private saves")
	root.size=Vector2i(1280,800);game=load("res://game/main.tscn").instantiate();game.automated=true
	game.world=Farm.new({},31).begin_day();root.add_child(game);game.set_process(false);await process_frame
	for state in ["unconscious","hidden_rest","forced"]:
		await fresh();var w=game.world;w.start_night();w.spawn_schedule.clear()
		w.keeper.hp=0 if state=="unconscious" else (3 if state=="hidden_rest" else 12)
		w.keeper.state=state if state!="forced" else "free";w.keeper.recover_ticks=24;w.keeper.heal_credit=5.75
		if state=="forced":w.keeper.sleepiness=100;w.keeper.forced_rest=true;w.Life.set_rest(w,true,"forced")
		w.finish(true) # Only settlement boundary is under test; no claim of natural victory.
		game.persistence_enabled=true;game.save_path="user://state-review/"+state+".sav";game.last_phase="defend";game.refresh()
		var slot=game.save_path;var saved=Save.read(slot)
		check(saved.status=="ok" and saved.record.campaign.day==2,"Dawn saves recovery before animation: "+state)
		for repeat in range(3):
			game.queue_free();await process_frame
			game=load("res://game/main.tscn").instantiate();game.save_path=slot;root.add_child(game);game.set_process(false);await process_frame
			check(Save.capture(game.world)==saved.record,"Real startup preserves the whole recovery morning: "+state+str(repeat))
		game.automated=true;game.story_modal="";game.clock=10;game.arrival_started=-10;game.advance();w=game.world
		w.day_seconds=600;w.spawn_schedule.clear()
		if state=="unconscious":
			check(w.keeper.hp==0 and w.keeper.recover_ticks==24,"Morning cannot grant downed keeper free HP or reset grace")
			await ticks(23);check(w.keeper.state=="unconscious","Remaining grace is still active")
			await ticks(1);check(w.keeper.state=="hidden_rest","Remaining six seconds enter hidden recovery")
		elif state=="hidden_rest":
			check(w.keeper.hp==3 and w.keeper.heal_credit==5.75,"Fractional hidden healing survives restart")
			await ticks(1);check(w.keeper.hp==4,"Only the remaining quarter-second grants the next HP")
		else:
			check(w.keeper.forced_rest and w.keeper.resting,"Exhaustion restores forced rest")
			await ticks(70);check(not w.keeper.forced_rest and not w.keeper.resting,"Forced rest recovers and releases control")
		if state!="forced":
			await ticks(200);check(w.keeper.state=="free" and w.keeper.hp>=8,"Recovery eventually restores a living keeper: "+state)
		check(w.act("resume_jobs") and w.act("keeper_move",Vector2i(9,10)),"Recovered morning accepts work and movement: "+state)
		await ticks(16);check(w.keeper.pos!=Vector2i(7,10),"Movement actually proceeds after recovery: "+state)
	for reason in ["death","abduction"]:
		await fresh();var w=game.world
		var row={"id":2,"species":"doberman","category":"dog","lv":1,"loyalty":100,"name":"","unavailable_through_day":0}
		w.campaign.animals.append(row);w.add_resident(row);var a=w.animals.back();a.pos=Vector2i(8,10);a.home=a.pos;a.order=a.pos
		check(w.queue_order("guide",[a.id],Vector2i(15,10)),"Guide target accepted before "+reason)
		await ticks(2);check(not w.jobs.is_empty(),"Guide is active before target disappears")
		if reason=="death":w.Progression.animal_hurt(w,a,{"id":-1},999)
		else:w.Progression.remove_animal(w,a,reason)
		await ticks(2)
		check(w.jobs.is_empty() and not a.has("guide_job"),"Lost target cannot permanently occupy the work queue: "+reason)
		w.Progression.remove_animal(w,a,reason)
		check(w.campaign.animal_history.filter(func(h):return h.id==2).size()==1,"Repeated cleanup cannot duplicate loss history: "+reason)
		check(w.queue_order("guide",[1],Vector2i(14,10)),"Another living companion accepts a new order: "+reason)
		w.act("cancel_job",Vector2i.ZERO,w.jobs[0].id);await ticks(2)
		check(w.jobs.is_empty(),"Replacement order still cancels normally: "+reason)
	game.queue_free();await process_frame
	print("CONTINUITY_STATES: %d checks, failures=%d"%[checks,failures]);quit(1 if failures else 0)
