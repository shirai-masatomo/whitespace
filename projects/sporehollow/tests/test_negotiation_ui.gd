extends SceneTree
const Farm=preload("res://game/world.gd")
var checks=[]
var failed=0
func _initialize():call_deferred("run")
func check(ok,note):
	checks.append({"passed":bool(ok),"check":note})
	if not ok:failed+=1;push_error(note)
func mouse(point,button,down):
	var e=InputEventMouseButton.new();e.position=point;e.button_index=button;e.pressed=down;Input.parse_input_event(e);await process_frame
func click(point,button=MOUSE_BUTTON_LEFT):
	var e=InputEventMouseMotion.new();e.position=point;Input.parse_input_event(e);await process_frame
	await mouse(point,button,true);await mouse(point,button,false)
func run():
	var out=OS.get_environment("FARM_REVIEW_OUTPUT")
	if out=="" or "--isolated-review" not in OS.get_cmdline_user_args() or DisplayServer.get_name()=="headless":quit(2);return
	root.size=Vector2i(1280,800)
	var w=Farm.new({},31).begin_day();w.story.intro_seen=true;w.tick=24;w.paused=true
	w.enemies.clear();w.spawn_schedule.clear();w.trees.clear();w.rocks.clear();w.natural.clear();w.structures.clear();w.floors.clear();w.field_items.clear();w.nature_config.spawn_chance_per_second=0
	w.keeper.pos=Vector2i(8,7);w.keeper.sleepiness=0
	for a in w.animals:a.pos=Vector2i(20,20);a.home=a.pos;a.mode="stay"
	var g=load("res://game/main.tscn").instantiate();g.automated=true;g.world=w;root.add_child(g);await process_frame;await process_frame;g.set_process(false);g.neutral()
	g.camera.position=g.center(Vector2i(8,8));g.camera.zoom=Vector2.ONE;g.camera.force_update_scroll();await process_frame
	var merchant=g.screen_cell(Farm.MERCHANT_CELL)
	await click(merchant);check(not g.field_shop and w.jobs.is_empty(),"Merchant left click alone neither opens shop nor selects a default negotiator")
	await click(merchant,MOUSE_BUTTON_RIGHT);check(not g.merchant_context and w.jobs.is_empty(),"Unselected right click gives guidance without creating an instruction")
	await click(g.get_canvas_transform()*g.keeper_pixel())
	check(g.selected.get("kind")=="keeper" and g.group==-1 and g.tool=="","Actual keeper click selects person while remaining neutral")
	await click(merchant,MOUSE_BUTTON_RIGHT)
	check(g.merchant_context and g.buttons.has("negotiate") and not g.buttons.negotiate.disabled and g.buttons.negotiate.text=="交渉","Right click opens enabled contextual negotiation action for the selected resident")
	g.queue_redraw();g.hud.queue_redraw();await process_frame;await RenderingServer.frame_post_draw;root.get_texture().get_image().save_png(out+"/negotiation-menu.png")
	await click(g.buttons.negotiate.get_global_rect().get_center())
	check(g.merchant_requested and w.merchant_worker=="keeper" and not g.field_shop,"Choosing negotiation creates an owned move order while shop remains closed")
	w.paused=false
	for i in range(80):
		w.step();g.view_positions["keeper"]=Vector2(w.keeper.pos);g._process(0)
		if g.field_shop:break
	check(g.field_shop and w.market_open and w.keeper.pos in w.merchant_talk_cells(),"The same person reaches merchant before the existing shop opens")
	var stopped=w.tick;g._process(0.5);check(w.tick==stopped,"Conversation stops world time")
	await click(merchant,MOUSE_BUTTON_RIGHT);check(not g.field_shop and not w.market_open,"Right click closes conversation and releases the pause")
	w.paused=true;g.neutral();g.select_group(0);g.tool="wood_wall";g.refresh();await click(merchant,MOUSE_BUTTON_RIGHT)
	check(g.group==-1 and g.tool=="" and not g.merchant_context,"Architect mode right click is cancellation, not negotiation")
	g.select_group(4);g.item_commands.select(g,"haul");await click(merchant,MOUSE_BUTTON_RIGHT)
	check(g.group==-1 and not g.merchant_context,"Command mode right click is cancellation, not negotiation")
	g.select_group(0);g.architect_category="ゾーン";g.tool="zone_stockpile";g.refresh();await click(merchant,MOUSE_BUTTON_RIGHT)
	check(g.group==-1 and not g.merchant_context,"Zone mode right click is cancellation, not negotiation")
	# Existing support human is selected by the same actual board input, never by assigning selected in the fixture.
	w.add_resident({"id":91,"species":"maid","category":"human","lv":1,"hp":45,"rarity":"common","xp":0,"loyalty":85,"traits":{},"name":"検証住人","affinity":null,"unavailable_through_day":0,"position":[9,9]})
	var a=w.animals.back();a.pos=Vector2i(9,9);a.placed=true;g.view_positions["a91"]=Vector2(a.pos);g.refresh();g.queue_redraw();await process_frame
	await click(g.get_canvas_transform()*g.actor_pixel("a91",a.pos))
	check(g.selected.get("id",-1)==91 and g.group==-1,"Actual support-human click also retains a neutral individual selection")
	await click(merchant,MOUSE_BUTTON_RIGHT);await click(g.buttons.negotiate.get_global_rect().get_center())
	check(w.merchant_worker=="a91" and not w.workers.has("a91"),"Support-human menu instructs that person without registering general autonomous work")
	w.cancel_merchant();g.merchant_requested=false;g.queue_free();await process_frame
	FileAccess.open(out+"/negotiation-ui.json",FileAccess.WRITE).store_string(JSON.stringify({"method":"Private GPU Godot InputEvent actual board selection, contextual button and shop close; controlled movement steps; no physical OS input","checks":checks,"failures":failed},"\t"))
	print("NegotiationUI: ",failed," failures");quit(1 if failed else 0)
