extends "res://tests/test_controls.gd"
var baseline=false
var viewport_mouse_notified=false

func mouse(p: Vector2,button: int=MOUSE_BUTTON_LEFT,ctrl: bool=false):
	# Coordinates are in the content viewport, including at non-1x window scales.
	if not viewport_mouse_notified:root.notify_mouse_entered();viewport_mouse_notified=true
	var motion=InputEventMouseMotion.new();motion.position=p;root.push_input(motion,true);await process_frame
	for pressed in [true,false]:
		var event=InputEventMouseButton.new();event.position=p;event.button_index=button;event.pressed=pressed;event.ctrl_pressed=ctrl
		root.push_input(event,true);await process_frame

func settle():
	game._process(0.6);game._process(0)
	await process_frame;await process_frame

func press(id: String):
	check(game.buttons.has(id),"Morning action exists: "+id)
	if game.buttons.has(id):await mouse(game.buttons[id].get_global_rect().get_center())
	await settle()

func morning_bounds(label: String):
	var paper=Rect2(330,112,656,510) if baseline else game.StoryView.morning_layout(game).paper
	var outside=[];var visible=[]
	for child in game.palette.get_children():
		if child is Control and child.visible and not child.is_queued_for_deletion():visible.append(child)
	if game.buttons.advance.visible:visible.append(game.buttons.advance)
	for child in visible:
		if not paper.encloses(child.get_global_rect()):outside.append(child.name)
		if not baseline:check(paper.encloses(child.get_global_rect()),"Morning control stays inside the paper: "+label+" / "+child.name)
	if not baseline:
		for i in range(visible.size()):
			for j in range(i+1,visible.size()):check(not visible[i].get_global_rect().intersects(visible[j].get_global_rect()),"Morning controls do not overlap: %s / %s"%[visible[i].name,visible[j].name])
	var frame={"case":label,"paper":str(paper),"viewport":str(root.get_visible_rect()),"window":str(root.size),"outside":outside,"controls":visible.map(func(c):return {"name":c.name,"rect":str(c.get_global_rect())})}
	record.events.append(frame)
	if baseline:check(outside.size()==2,"Reproduce the two story buttons outside the old morning paper")
	else:check(root.get_visible_rect().encloses(paper),"Morning paper fits the logical viewport: "+label)

func run():
	output=OS.get_environment("FARM_REVIEW_OUTPUT");baseline=OS.get_environment("FARM_LAYOUT_BASELINE")=="1"
	if DisplayServer.get_name()!="headless" and (output=="" or not "--isolated-review" in OS.get_cmdline_user_args()):quit(2);return
	root.size=Vector2i(1280,800)
	game=load("res://game/main.tscn").instantiate();game.automated=true;game.world=Farm.new({},31)
	root.add_child(game);game.set_process(false);await process_frame
	game.story_modal="";game.arrival_started=-10;game.save_status="";game.refresh();await settle()
	if baseline:
		morning_bounds("reference_day1");await capture("00_before_day1")
	else:
		for window_size in [Vector2i(1280,800),Vector2i(1024,640),Vector2i(1600,1000)]:
			root.size=window_size;await process_frame;await process_frame
			var c=Farm.new_campaign();game.world=Farm.new(c,31);game.reset_view();game.save_status="";game.story_modal="";game.arrival_started=-10;game.refresh();await settle()
			morning_bounds("day1_"+str(window_size));await capture("01_day1_%dx%d"%[window_size.x,window_size.y])
			var tick=game.world.tick;var gold=game.world.campaign.gold
			await press("diary");check(game.story_modal=="diary","Diary opens from the repaired footer");await press("story_close")
			await press("intro_again");check(game.story_modal=="intro","Recall opens from the repaired footer");await press("story_close")
			await press("open_market");check(game.morning_screen=="market" and not game.buttons.has("diary"),"Market replaces the morning footer");await press("close_market")
			await press("open_book");check(game.morning_screen=="book" and not game.buttons.has("diary"),"Book replaces the morning footer");await press("close_market")
			check(game.morning_screen=="morning" and game.world.tick==tick and game.world.campaign.gold==gold,"Menu/book/modal round trips preserve morning time and money")
			game.world.story.radio=true
			game.world.story.news=[{"day":1,"title":"遠い町から届いた長い放送見出しを表示しても紙面を飛び出さず全文を確認できる","text":"テスト用の放送本文"}]
			game.world.story.miracles=[{"day":1,"text":"とても長い願いの贈り物の説明でもボタンや放送と重ならず全文を確認できる"}]
			game.save_status="テスト用の保存状態です。長い状態説明でも紙面の下部に収まり、操作ボタンを覆わないことを確認します。"
			game.refresh();await settle();morning_bounds("all_notes_"+str(window_size))
			for name in ["MorningNews","MorningGift","MorningSaveStatus"]:
				var node=game.palette.get_node_or_null(NodePath(name));check(node!=null and node.tooltip_text==node.text and node.clip_text,"Long footer text keeps an accessible full tooltip: "+name)
			await capture("02_notes_%dx%d"%[window_size.x,window_size.y])
			await press("radio");check(game.story_modal=="radio","Radio still opens with long footer text");await press("story_close")
			game.world.campaign.route_progress.milestones[Farm.Progression.Encounters.ROUTE_ID]={"achieved_night":15};game.world.campaign.day=16
			game.save_status="";game.refresh();await settle();morning_bounds("milestone_"+str(window_size))
			await press("route_restart");morning_bounds("restart_confirm_"+str(window_size));await capture("03_milestone_%dx%d"%[window_size.x,window_size.y])
			await press("route_restart_cancel");check(not game.restart_confirm,"Restart cancellation restores the morning without starting a new farm")
		root.size=Vector2i(1280,800)
	record.baseline=baseline;record.method="Actual UI layout and local Input events, isolated or headless; new day1 plus explicit long-news/gift/save-status and milestone fixtures. No normal saves or OS inputs."
	var destination=output+"/morning-layout.json" if output!="" else "user://morning-layout.json"
	FileAccess.open(destination,FileAccess.WRITE).store_string(JSON.stringify(record,"  "))
	print("MORNING_LAYOUT_UI: %d checks, failures=%d, baseline=%s"%[checks,failures,baseline]);quit(1 if failures else 0)
