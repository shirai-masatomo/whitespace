extends "res://tests/test_housing_sleep.gd"
var results=[]
func verify(ok,note):results.append({"passed":bool(ok),"check":note})
func pointer(at,down):
	var motion=InputEventMouseMotion.new();motion.position=root.get_final_transform()*at;motion.button_mask=0 if down else MOUSE_BUTTON_MASK_LEFT;root.push_input(motion,false)
	var e=InputEventMouseButton.new();e.position=root.get_final_transform()*at;e.button_index=MOUSE_BUTTON_LEFT;e.pressed=down;root.push_input(e,false)
func run():
	if DisplayServer.get_name()!="headless" or OS.get_environment("FARM_REVIEW_OUTPUT")=="":quit(2);return
	var boot=load("res://game/loading.tscn").instantiate();boot.review_mode=true;root.add_child(boot)
	var deadline=Time.get_ticks_msec()+25000
	while not boot.finished and boot.failure=="" and Time.get_ticks_msec()<deadline:await process_frame
	if not boot.finished:quit(2);return
	var g=boot.game;g.set_process(false);g.world=fixture();w=g.world;w.paused=true;g.story_modal="";g.field_book=false;g.field_shop=false
	var categories=g.ColonyModel.ARCHITECT.keys();var trial=0
	for dimensions in [Vector2i(1280,800),Vector2i(1600,1000)]:
		root.size=dimensions
		for index in range(4):
			for change in ["none","stock","job"]:
				for relative in [Vector2(.04,.08),Vector2(.5,.08),Vector2(.96,.08),Vector2(.04,.5),Vector2(.5,.5),Vector2(.96,.5),Vector2(.04,.92),Vector2(.5,.92),Vector2(.96,.92)]:
					g.select_group(0);g.ColonyPanels.architecture_category(g,categories[(index+1)%4]);g._process_measured(0);await process_frame
					var id="architect_category_%d"%index;var before=g.buttons[id].get_instance_id();var r=g.buttons[id].get_global_rect();var at=r.position+r.size*relative
					var motion=InputEventMouseMotion.new();motion.position=root.get_final_transform()*at;root.push_input(motion,false);pointer(at,true)
					if change=="stock":w.Stock.add(w,"wood",1,Vector2i(29,23))
					elif change=="job":w.act("wall",Vector2i(60+trial%20,30+trial/20));trial+=1
					g._process_measured(0);await process_frame
					var same=before==g.buttons[id].get_instance_id();pointer(at,false)
					results.append({"window":str(dimensions),"target":categories[index],"point":str(relative),"change_while_held":change,"same_button":same,"passed":g.architect_category==categories[index]})
		# Retention must not accumulate nodes/signals, hide live data, or keep
		# invisible buttons active after leaving architect mode.
		g.select_group(0);g.ColonyPanels.architecture_category(g,"壁と扉");await process_frame
		var ids=[];var rectangles=[]
		for i in range(4):ids.append(g.buttons["architect_category_%d"%i].get_instance_id());rectangles.append(g.buttons["architect_category_%d"%i].get_global_rect())
		for i in range(12):g.refresh()
		verify(g.palette.get_children().filter(func(n):return n.has_meta("architect_category")).size()==4,"Exactly four category controls after repeated refresh")
		for i in range(4):
			var b=g.buttons["architect_category_%d"%i]
			verify(b.get_instance_id()==ids[i] and b.get_global_rect()==rectangles[i],"Refresh preserves instance and geometry: "+categories[i])
			verify(b.pressed.get_connections().size()==1,"No duplicate category callback: "+categories[i])
		g.select_tool("wood_wall",false);await process_frame
		var old_details=g.colony_panel.get_node("BuildDescription").get_instance_id();w.Stock.add(w,"wood",1,Vector2i(29,23));g._process_measured(0)
		verify(old_details!=g.colony_panel.get_node("BuildDescription").get_instance_id() and g.colony_signature==g.ColonyPanels.signature(g),"Stock/details still refresh while category controls are retained")
		await process_frame;var b=g.buttons.architect_category_1;var r=b.get_global_rect();pointer(r.get_center(),true);g.refresh();pointer(r.end+Vector2(4,0),false)
		verify(g.architect_category=="壁と扉","Releasing outside the category cancels selection")
		g.buttons.architect_category_1.disabled=true;pointer(r.get_center(),true);pointer(r.get_center(),false)
		verify(g.architect_category=="壁と扉","Disabled category does not activate")
		g.buttons.architect_category_1.disabled=false;pointer(r.get_center(),true)
		var cancel=InputEventMouseButton.new();cancel.position=root.get_final_transform()*r.get_center();cancel.button_index=MOUSE_BUTTON_RIGHT;cancel.pressed=true;root.push_input(cancel,false);cancel=cancel.duplicate();cancel.pressed=false;root.push_input(cancel,false);pointer(r.get_center(),false)
		verify(g.group==-1 and not g.buttons.has("architect_category_1"),"Right click removes category controls and cancels held press")
		g.select_group(0);await process_frame
		verify(g.buttons.architect_category_1.get_instance_id()!=ids[1],"Re-entering architect creates fresh controls once")
		g.select_group(3);await process_frame
		verify(g.palette.get_children().all(func(n):return not n.has_meta("architect_category")),"No invisible category controls after mode change")
	var failed=results.filter(func(c):return not c.passed).size()
	FileAccess.open(OS.get_environment("FARM_REVIEW_OUTPUT")+"/category-click.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":results,"count":results.size(),"failed":failed},"  "))
	print("Category clicks: ",results.size()," failed=",failed)
	boot.queue_free();await process_frame;quit(1 if failed else 0)
