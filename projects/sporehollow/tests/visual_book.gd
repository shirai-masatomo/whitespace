extends "res://tests/visual_shop.gd"
# Capture-only fixture. Uses current UI and isolated APPDATA, never normal saves.
var fixture = "normal_new_campaign"
func capture(label: String):
	await super.capture(label)
	var shot=shots[-1]
	shot["fixture"]=fixture
	shot["book_motion"]=game.book_motion
	shot["animal_id"]=game.training_id
	shot["next_animal_id"]=game.book_next_id
	shot["animals"]=game.world.campaign.animals.duplicate(true)
	shot["exp_pool"]=game.world.campaign.exp_pool
	shot["rename_open"]=game.rename_open
	shot["buttons"]={}
	for id in game.buttons:
		shot.buttons[id]={"disabled":game.buttons[id].disabled,"visible":game.buttons[id].is_visible_in_tree()}
func motion_frames(label: String):
	var count=0
	while game.book_motion!="" and count<12:
		await capture(label+"_frame_"+str(count))
		count+=1
	await create_timer(0.12).timeout
func run():
	output=OS.get_environment("FARM_REVIEW_OUTPUT")
	if output=="" or not "--isolated-review" in OS.get_cmdline_user_args():quit(2);return
	root.size=Vector2i(1280,800)
	game=load("res://game/main.tscn").instantiate();root.add_child(game)
	await create_timer(3.0).timeout
	await capture("morning_closed_cover")
	await click("open_book");await motion_frames("opening")
	await capture("shiba_initial_single_animal")
	await click("rename");await capture("name_input")
	game.name_edit.select_all();game.name_edit.insert_text_at_caret("こむぎ")
	await capture("name_edited")
	await click("save_name");await capture("name_saved")
	await click("close_market");await motion_frames("closing")
	await capture("closed_back_to_morning")
	# Only resources are provisioned; owned animals enter through normal purchase.
	fixture="review_resources_gold_150_exp_100"
	game.world.campaign.gold=150;game.world.campaign.exp_pool=100;game.refresh()
	await click("open_market");await click("shop_buy");await click("category_animals")
	await click("trade_hen_-1");await click("confirm_trade");await click("shop_back")
	await click("trade_cat_-1");await click("confirm_trade");await click("close_market")
	await click("open_book");await create_timer(0.65).timeout
	await capture("shiba_training_available")
	await click("train_"+str(game.training_id));await capture("shiba_after_training")
	await click("book_next");await motion_frames("turn_next_hen")
	await capture("hen_page")
	await click("book_next");await motion_frames("turn_next_cat")
	await capture("cat_page")
	await click("book_prev");await motion_frames("turn_previous_hen")
	await capture("hen_page_returned")
	# Right-click must close the book, not turn a page or reach the farm.
	var p=Vector2(600,500)
	for pressed in [true,false]:
		var e=InputEventMouseButton.new();e.position=p;e.button_index=MOUSE_BUTTON_RIGHT;e.pressed=pressed
		Input.parse_input_event(e);await process_frame
	await motion_frames("right_click_closing")
	await capture("final_morning")
	if game.morning_screen!="morning" or game.world.tick!=0:
		push_error("Book capture changed world time or did not close");quit(4);return
	FileAccess.open(output+"/observations.json",FileAccess.WRITE).store_string(JSON.stringify({"implementation_commit":OS.get_environment("FARM_REVIEW_COMMIT"),"runtime_commit":"e65f7d1","method":"Current main.tscn on isolated GPU desktop. Game-local mouse press/release, LineEdit text input. Normal new campaign first; then explicitly provisioned 150 G / 100 EXP, hen and cat purchased through UI. Animation frames are viewport snapshots, not authored artwork.","shots":shots,"events":events},"  "))
	print("BOOK_CAPTURE_OK ",shots.size()," screenshots; world tick ",game.world.tick)
	quit()
