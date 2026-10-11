extends Node
var root: Window
var process_frame: Signal
const Farm=preload("res://game/world.gd")
const Clarity=preload("res://game/onsite_clarity.gd")
var game
var output=""
var failures=0
var record={"method":"Controlled fixtures, existing InputEvent/UI calls and lifecycle/AI steps; no strategy simulation or human play","groups":{},"captures":[],"prayer_schedule":[]}
func quit(code: int):get_tree().quit(code)
func verify(group: String,ok: bool,label: String):
	if not record.groups.has(group):record.groups[group]=[]
	record.groups[group].append({"passed":ok,"check":label})
	if not ok:failures+=1;push_error(label)
func fixture(day: int=2):
	var c=Farm.new_campaign();c.day=day
	var w=Farm.new(c,31).begin_day();w.story.intro_seen=true;w.spawn_schedule.clear();return w
func show(w):
	game.world=w;game.reset_view();game.refresh();game.queue_redraw();game.hud.queue_redraw()
func press(id: String):
	var p=game.buttons[id].get_global_rect().get_center()
	for down in [true,false]:
		var e=InputEventMouseButton.new();e.position=p;e.button_index=MOUSE_BUTTON_LEFT;e.pressed=down
		Input.parse_input_event(e);await process_frame
func capture(name: String):
	if DisplayServer.get_name()=="headless":return
	game.queue_redraw();game.hud.queue_redraw();await process_frame;await process_frame;await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(output+"/"+name+".png");record.captures.append(name+".png")
func fit(lines: Array,width: float) -> bool:
	return lines.all(func(line):return game.FONT.get_string_size(line,HORIZONTAL_ALIGNMENT_LEFT,-1,14).x<=width)
func run():
	root=get_tree().root;process_frame=get_tree().process_frame
	output=OS.get_environment("FARM_REVIEW_OUTPUT")
	if output=="" or (DisplayServer.get_name()!="headless" and not "--isolated-review" in OS.get_cmdline_user_args()):quit(2);return
	root.size=Vector2i(1280,800)
	game=load("res://game/main.tscn").instantiate();game.automated=true;game.world=fixture()
	root.add_child(game);await process_frame;await process_frame;game.set_process(false);game.audio.set_process(false)
	var w=fixture();var cell=Vector2i(10,9);w.field_items=[{"kind":"egg","pos":cell,"born_day":1}];show(w)
	game.select_resource(cell);var lines=game.selected_egg_lines()
	verify("1_eggs",game.job_reserved("collect",cell) and lines[1].contains("取消") and lines[3].contains("1回") and lines[4].contains("初産最短5日目") and fit(lines,418),"Selected egg uses existing collection reservation; cancellation and day2-to-day5 forecast fit")
	await capture("01_egg_reserved")
	await press("cancel_near")
	verify("1_eggs",not game.job_reserved("collect",cell) and not game.selected_egg_lines()[1].contains("取消"),"Existing Cancel leaves the egg and updates explanation")
	var timeline=[]
	for day in [2,3,4]:
		w.finish(true);w=Farm.new(w.next_campaign(),31).begin_day()
		timeline.append({"day":w.campaign.day,"items":w.field_items.duplicate(true),"hens":w.animals.filter(func(a):return a.species=="hen").map(func(a):return {"pos":a.pos,"placed":a.placed})})
	verify("1_eggs",timeline[0].items[0].kind=="chick" and timeline[1].hens.size()==1 and Farm.distance(timeline[1].hens[0].pos,w.logistics_entry)<=4 and timeline[2].items.any(func(i):return i.kind=="egg"),"Existing successful dawns produce chick day3, entry hen day4, first egg day5")
	record.groups["1_eggs"].append({"timeline":timeline})
	w=fixture();w.field_items=[{"kind":"egg","pos":cell,"born_day":2}]
	var fresh=Clarity.eggs(w,w.field_items,false);w.finish(true)
	verify("1_eggs",fresh[3].contains("2回") and w.field_items[0].kind=="egg","Same-day egg does not mature at its first dawn")
	w=fixture();w.field_items=[{"kind":"egg","pos":cell,"born_day":1}];w._execute_local("collect",cell)
	w.finish(true);w=Farm.new(w.next_campaign(),31).begin_day()
	verify("1_eggs",w.item_count("egg")==1 and w.field_items.is_empty() and w.animals.size()==1,"Collected egg remains inventory, with no hatching or return path")
	show(w);preload("res://game/inventory_view.gd").open(game)
	var labels=game.story_panel.find_children("*","Label",true,false)
	verify("1_eggs",labels.any(func(l):return l.text.contains("卵 ×1") and l.text.contains("食料・売却用")),"Inventory includes owned egg and collected-state description")
	game.StoryView.close(game)
	w=fixture();var a=w.animals[0];a.mode="stay";a.home=a.pos;a.order=a.pos;a.order_until=1000;w.animal_step(a);show(w);game.choose_animal(a.id)
	var state_before=a.duplicate(true);var desc=Clarity.dog(w,a)
	verify("2_dog",desc[0]=="指示位置で待つ" and desc[1].contains("おまかせ") and a==state_before and fit(desc,320),"Real stay state is explained without AI mutation and links to existing Auto")
	await capture("02_dog_stay")
	await press("auto")
	record.groups["2_dog"].append({"auto_button_tool":game.tool,"jobs":w.jobs.duplicate(true)})
	verify("2_dog",w.jobs.any(func(j):return j.kind=="animal_order" and j.order=="auto"),"Existing Auto button queues delivery through existing animal-order work")
	var dog_states=[]
	for kind in ["rest","auto","rescue","convalescent"]:
		w=fixture();a=w.animals[0]
		if kind=="rest":a.mode="rest";a.order_until=1000;a.hp=a.max_hp-2
		elif kind=="auto":a.mode="auto";a.hp=5
		elif kind=="rescue":
			w.spawn_enemy({"role":"kidnapper","entry":Vector2i(1,5),"lv":1});var e=w.enemies.back();e.pos=Vector2i(8,8);e.arrival_complete=true;e.carry="keeper";w.keeper.carrier=e.id;w.keeper.restrainer=e.id
		else:a.unavailable_through_day=w.campaign.day
		w.animal_step(a);desc=Clarity.dog(w,a);dog_states.append({"fixture":kind,"state":a.state,"rescuing":a.rescuing,"text":desc})
	verify("2_dog",dog_states[0].text[1].contains("無理するな") and dog_states[1].text[0].contains("自主休養") and dog_states[2].text[0].contains("救出") and dog_states[3].text[0].contains("療養") and dog_states.all(func(r):return fit(r.text,320)),"Actual rest, autonomous recovery, rescue, convalescence states and command hints fit")
	record.groups["2_dog"].append({"states":dog_states})
	w=fixture();show(w);game.persistence_enabled=true;game.save_path="user://clarity-check.sav";game.save_morning(w)
	var saved=FileAccess.get_file_as_bytes(game.save_path);w.tick=40;w.campaign.gold+=5;w.rename_animal(a.id,"日中の名前");game.save_morning(w)
	verify("3_merchant_save",saved==FileAccess.get_file_as_bytes(game.save_path) and game.MorningSave.restore(game.MorningSave.read(game.save_path).record).campaign.animals[0].name!="日中の名前","Midday changes do not overwrite day-start save; reload loses midday name")
	game.persistence_enabled=false;w.campaign.eggs=1;w.market_open=true;game.field_shop=true;game.morning_screen="market";game.shop_side="sell";game.shop_category="items";game.shop_level="detail";game.product_row={"id":"egg","count":1,"animal_id":-1};game.refresh()
	verify("3_merchant_save",game.MarketView.description("egg").contains("5G") and game.buttons.has("confirm_trade"),"Existing merchant egg sale detail retains transaction route and ownership explanation")
	await capture("03_merchant_egg")
	game.morning_screen="morning";game.refresh();await capture("03b_merchant_heading")
	game.field_shop=false;w.market_open=false;game.refresh();game.toggle_menu()
	verify("3_merchant_save",game.menu.get_node("SaveBoundaryNote").text==Clarity.SAVE_BOUNDARY and game.menu.get_node("SaveBoundaryNote").get_minimum_size().x<=900,"Pause/exit route explicitly explains day-start restoration")
	await capture("04_save_boundary")
	var guide=game.menu.get_node("ControlGuide");var note=game.menu.get_node("SaveBoundaryNote");var status=game.menu.get_node("MenuSaveStatus")
	verify("3_merchant_save",guide.get_rect().end.y<=note.position.y and note.get_rect().end.y<=status.position.y,"Menu control guide, save warning and status do not overlap")
	for day in [7,10]:
		var rows=[]
		for active in [false,true]:
			w=fixture(day);w.story.hidden.karma=12;w.story.hidden.recognition=2;w.story.hidden.security=2
			w.story.raid_slots=[{"event_id":"controlled-reaction","role":"animal_tamer","not_before_day":7}]
			# Same state/history on both branches; suppress only the reaction selector in this fixture.
			var snapshot=w.story.duplicate(true)
			if not active:w.story.raid_slots=[]
			w.start_night();var schedule=w.spawn_schedule.map(func(e):return {"seconds":e.tick*Farm.DT,"role":e.role,"lv":e.lv})
			w.story=snapshot
			rows.append({"active_reaction":active,"day":day,"seed":31,"karma":12,"recognition":2,"history":snapshot,"schedule":schedule})
		verify("prayer_schedule",rows[0].schedule==rows[1].schedule if day==10 else rows[1].schedule.size()==1 and rows[1].schedule[0].seconds==60,"Matched schedule replacement, day "+str(day))
		record.prayer_schedule.append(rows)
	record["failures"]=failures
	FileAccess.open(output+"/verification.json",FileAccess.WRITE).store_string(JSON.stringify(record,"  "))
	print("ONSITE_CLARITY failures=",failures);quit(1 if failures else 0)
