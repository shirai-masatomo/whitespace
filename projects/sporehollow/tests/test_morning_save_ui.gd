extends "res://tests/test_controls.gd"
const Save=preload("res://game/morning_save.gd")
func run():
	output=OS.get_environment("FARM_REVIEW_OUTPUT")
	check(DisplayServer.get_name()=="headless" or ("--isolated-review" in OS.get_cmdline_user_args() and output!=""),"Only isolated rendering or headless verification")
	root.size=Vector2i(1280,800);game=load("res://game/main.tscn").instantiate();game.automated=true
	game.world=Farm.new({},31);root.add_child(game);game.set_process(false);await process_frame
	check(not game.persistence_enabled and not FileAccess.file_exists(Save.PATH),"Automated UI never reads or writes the normal campaign slot")
	game.persistence_enabled=true;game.save_path="user://ui-save/morning.sav";game.arrival_started=-10
	game.world.campaign.gold=300;game.world.campaign.exp_pool=100;game.save_morning(game.world)
	game.shop_side="buy";game.trade("berry");game.train(1)
	check(Save.read(game.save_path).record.campaign.gold==292 and Save.read(game.save_path).record.campaign.animals[0].lv==2,"Trade and training persist through the real UI callbacks")
	game.StoryView.open(game,"intro");game.StoryView.close(game)
	check(Save.read(game.save_path).record.campaign.world_story.intro_seen,"Closing the introduction persists its completed flag")
	game.morning_screen="morning";game.refresh();game._process(0)
	check(game.palette.get_node("MorningSaveStatus").text==game.save_status,"The morning displays the save and resume boundary")
	await capture("01_morning_saved")
	game.advance();game.world.start_night();game.world.spawn_schedule.clear();game.world.finish(true);game.refresh()
	var dawn=Save.read(game.save_path).record
	check(dawn.campaign.day==2 and dawn.seed==32 and not dawn.campaign.night_ready,"Dawn animation already protects the next real morning")
	game.clock=20;game.transition_at=0;game._process(0)
	check(game.world.phase=="shop" and Save.read(game.save_path).record.campaign.gold==dawn.campaign.gold,"Automatic dawn transition does not duplicate settlement")
	var before=game.world;game.restart_confirm=true
	DirAccess.make_dir_absolute(ProjectSettings.globalize_path(game.save_path+".tmp"))
	game.new_campaign()
	check(game.world==before and game.restart_confirm and "保存できません" in game.save_status,"New-campaign write failure preserves the existing farm and confirmation")
	game.arrival_started=-10;game.advance()
	check(game.world==before and game.world.phase=="shop","A failed final morning save keeps the player in preparation")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(game.save_path+".tmp"));game.new_campaign()
	check(game.world.campaign.day==1 and Save.read(game.save_path).record.campaign.day==1,"A confirmed new campaign replaces the slot only after successful persistence")
	var startup_path="user://ui-save/startup.sav";Save.write(dawn,startup_path)
	var reloaded=load("res://game/main.tscn").instantiate();reloaded.save_path=startup_path;root.add_child(reloaded);reloaded.set_process(false);await process_frame
	check(reloaded.persistence_enabled and reloaded.world.campaign.day==2 and reloaded.world.seed_value==32 and reloaded.world.shop_stock==dawn.stock,"Actual normal startup resumes the recorded morning and stock")
	reloaded.queue_free();await process_frame
	var future=FileAccess.open(startup_path,FileAccess.READ_WRITE);future.seek(4);future.store_32(99);future.close();var unchanged=FileAccess.get_file_as_bytes(startup_path)
	reloaded=load("res://game/main.tscn").instantiate();reloaded.save_path=startup_path;root.add_child(reloaded);reloaded.set_process(false);await process_frame
	check(reloaded.save_load_blocked and reloaded.buttons.advance.disabled and FileAccess.get_file_as_bytes(startup_path)==unchanged,"Unknown-version startup visibly blocks progress without overwriting the save")
	reloaded.queue_free();await process_frame
	var missing_path="user://ui-save/fresh.sav";reloaded=load("res://game/main.tscn").instantiate();reloaded.save_path=missing_path;root.add_child(reloaded);reloaded.set_process(false);await process_frame
	check(Save.read(missing_path).status=="ok" and Save.read(missing_path).record.campaign.day==1,"A genuinely empty slot creates and saves the first morning")
	reloaded.queue_free();await process_frame
	print("MORNING_SAVE_UI: %d checks, failures=%d"%[checks,failures]);quit(1 if failures else 0)
