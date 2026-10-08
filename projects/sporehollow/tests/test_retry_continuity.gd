extends "res://tests/audit_balance_failures.gd"
func run():
	check(DisplayServer.get_name()=="headless","Retry review is headless with private persistence")
	var saved=Save.read("res://artifacts/balance-fixtures/failure-31-gold_once.sav").record
	var slot="user://retry-review/morning.sav";check(Save.write(saved,slot).status=="ok","Reuse the earned day5 morning without replaying four days")
	var game=load("res://game/main.tscn").instantiate();game.save_path=slot;root.add_child(game);game.set_process(false);await process_frame
	check(Save.capture(game.world)==saved,"Real startup restores the exact earned preparation")
	game.automated=true;game.story_modal="";game.arrival_started=-10;game.clock=10
	var outcome=run_day(Save.restore(saved),"gold_once",false,"baseline");var w=outcome.world
	check(w.result=="loss" and w.story.defeat_reason=="idol_destroyed","Existing baseline naturally reaches the known idol-loss boundary")
	game.world=w;game.last_phase="defend";game.refresh();game.clock+=10;game.refresh()
	check(not game.buttons.retry.disabled and Save.read(slot).record==saved,"Natural defeat exposes retry without changing the saved morning")
	game.buttons.retry.emit_signal("pressed");w=game.world
	check(w.working() and w.result=="" and w.campaign.gold==saved.campaign.gold and w.wood==saved.campaign.resources.wood,"Actual retry button restores earned resources with no grant")
	var hp=w.story.idol.hp;var wood=w.wood
	check(w.act("repair_idol",w.Story.at(w)),"Normal retry can reserve a paid repair")
	for i in range(200):
		w.step()
		if w.jobs.is_empty():break
	check(w.jobs.is_empty() and w.story.idol.hp==hp+30 and w.wood==wood-5,"Retry repair completes using five existing wood for thirty HP")
	check(Save.read(slot).record==saved,"Daytime repair retains the morning save boundary")
	FileAccess.open("user://retry-review/result.json",FileAccess.WRITE).store_string(JSON.stringify({"loss_tick":outcome.world.tick,"loss_reason":outcome.world.story.defeat_reason,"retry_idol_hp":w.story.idol.hp,"retry_wood":w.wood,"checks":records},"  "))
	game.queue_free();await process_frame
	print("RETRY_CONTINUITY: %d checks, failures=%d"%[checks,failures]);quit(1 if failures else 0)
