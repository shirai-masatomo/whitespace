extends "res://tests/test_market_reference_ui.gd"
const Speech=preload("res://game/merchant_speech.gd")
var baseline_image: Image
func frozen_capture(name: String,time: float):
	game.merchant_speech.elapsed=time;game.hud.queue_redraw();await capture(name)
	return root.get_texture().get_image()
func run():
	output=OS.get_environment("FARM_REVIEW_OUTPUT")
	if output=="" or not "--isolated-review" in OS.get_cmdline_user_args():quit(2);return
	root.size=Vector2i(1280,800)
	game=load("res://game/main.tscn").instantiate();game.automated=true;game.world=Farm.new({},31)
	game.world.story.intro_seen=true;root.add_child(game);await process_frame;await process_frame;game.set_process(false)
	game.world.tick=60;game.world.keeper.pos=game.world.merchant_talk_cells()[0]
	game.world.paused=true;game.open_market();game._process(0)
	check(game.field_shop and game.merchant_speech.frame(game)==0,"Conversation starts on original closed mouth")
	var tick=game.world.tick
	game._process(0.20)
	check(game.merchant_speech.frame(game)==1 and game.world.tick==tick,"Mouth advances while game time is paused")
	await frozen_capture("01_conversation_half",0.20)
	game.enter_market();game._process(0)
	baseline_image=await frozen_capture("02_shop_closed",0.0)
	var mouth=Speech.mouth_rect(game.MarketView.Art.CART,Rect2(160,300,498,300)).grow(2)
	for entry in [["03_shop_half",0.20,1],["04_shop_open",0.40,2]]:
		var pic: Image=await frozen_capture(entry[0],entry[1]);var changed=0;var outside=0
		for y in range(pic.get_height()):
			for x in range(pic.get_width()):
				if pic.get_pixel(x,y)!=baseline_image.get_pixel(x,y):
					changed+=1
					if not mouth.has_point(Vector2(x,y)):outside+=1
		check(game.merchant_speech.frame(game)==entry[2] and changed>0,"Visible mouth state "+str(entry[2]))
		check(outside==0,"All pixels outside mouth are identical: "+entry[0])
		record.events.append({"frame":entry[0],"changed_pixels":changed,"outside_mouth":outside})
	game.merchant_speech.elapsed=0
	var observed=[]
	for dt in [0.08,0.12,0.20,0.17,0.16]:
		game._process(dt);observed.append(game.merchant_speech.frame(game))
	check(observed==[0,1,2,1,0],"Closed half open half closed order")
	game._process(10);check(game.merchant_speech.frame(game)==0,"Utterance stops after bounded duration")
	game.refresh();game._process(10);check(game.merchant_speech.frame(game)==0,"Idle shop and refresh never restart speech")
	await press("shop_buy");game._process(0.2);check(game.merchant_speech.frame(game)==1,"New buy phrase starts")
	await press("category_animals");game._process(10);game.choose_category("materials");game._process(0.2)
	check(game.merchant_speech.frame(game)==0,"Category navigation does not repeat identical phrase")
	game.close_morning_screen();game._process(0.2);check(game.merchant_speech.frame(game)==1,"Returning greeting starts once")
	game.open_book();game._process(0);check(game.merchant_speech.frame(game)==0 and game.merchant_speech.key=="","Book hides and cancels speech")
	game.close_morning_screen();await settle();game._process(0.2);check(game.merchant_speech.key=="greeting","Book close resumes visible greeting")
	game.close_morning_screen();game._process(0);check(game.merchant_speech.key=="","Conversation close cancels speech")
	game.open_market();game._process(0.2);check(game.merchant_speech.frame(game)==1,"Reconversation starts a fresh utterance")
	game.world.market_open=false;game.world.merchant_leave_at=35;game.world.tick=200;game._process(0)
	check(game.merchant_speech.key=="" and game.merchant_speech.frame(game)==0,"Departure cancels mouth immediately")
	# Controlled still-world frames for a short reviewer preview; no OS input.
	game.world.tick=60;game.world.merchant_leave_at=35;game.open_market();game.enter_market();game._process(0)
	for i in range(19):await frozen_capture("preview_%02d"%i,i*0.1)
	FileAccess.open(output+"/merchant-mouth.json",FileAccess.WRITE).store_string(JSON.stringify(record,"  "))
	print("MERCHANT_MOUTH: %d checks, failures=%d"%[checks,failures]);quit(1 if failures else 0)
