extends "res://tests/test_reference_ui.gd"
func run():
	if DisplayServer.get_name()!="headless" or OS.get_environment("FARM_REVIEW_OUTPUT")=="":quit(2);return
	var boot=load("res://game/loading.tscn").instantiate();boot.review_mode=true;root.add_child(boot)
	var deadline=Time.get_ticks_msec()+25000
	while not boot.finished and boot.failure=="" and Time.get_ticks_msec()<deadline:await process_frame
	check(boot.finished,"Loading real game UI")
	if boot.finished:
		var g=boot.game;g.set_process(false);g.world=fixture();w=g.world;w.paused=true;g.story_modal="";g.field_book=false;g.field_shop=false
		for dimensions in [Vector2i(1280,800),Vector2i(1600,1000)]:
			root.size=dimensions;g.select_group(0);g.ColonyPanels.architecture_category(g,"設置");g.select_tool("mushroom_bed");await process_frame
			check(g.ReviewUI.icon("mushroom_bed")==g.ReviewUI.icon("mushroom_bed"),"Prototype mushroom icon reuses cached texture")
			check(g.buttons.has("mushroom_bed") and g.buttons.mushroom_bed.has_node("BuildIcon"),"Existing architect exposes bed with adopted icon")
			check(g.colony_panel.get_node("BuildDescription").text.contains("木材8・土4"),"UI shows both construction materials")
			var rect=g.buttons.mushroom_bed.get_global_rect();check(rect.size.x>=102 and rect.size.x<=108 and rect.size.y==96,"Full building button clickable rectangle")
			layout(g,"cultivation-architect",dimensions)
			var q=Vector2i(35,25);ready("mushroom_bed",q);w.Craft.enqueue(w,q,"grow_mushroom","count",3)
			var j=w.jobs.back();w.structures[q].culture={"seeded_tick":w.tick,"ready_tick":w.tick+3456,"harvest_progress":0.0};j.batch_active=true
			g.neutral();g.crafting_panel.show(g,q);await process_frame
			check(g.colony_panel.position==Vector2(16,110) and g.colony_panel.size==Vector2(520,440),"Reused compact production panel")
			check(w.Craft.summary(w,j).contains("48.0時間"),"Live crop time visible in production bill")
			check(g.colony_panel.find_child("Recipe",true,false)!=null,"Original recipe control reused")
			layout(g,"cultivation-growing",dimensions)
			g.crafting_panel.close(g);w.jobs.clear();w.structures.clear()
		boot.queue_free();await process_frame
	var fail=checks.filter(func(c):return not c.passed).size()
	FileAccess.open(OS.get_environment("FARM_REVIEW_OUTPUT")+"/phase2-ui.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":fail,"layouts":layouts},"  "))
	print("PHASE2_UI ",checks.size()," failures=",fail);quit(1 if fail else 0)
