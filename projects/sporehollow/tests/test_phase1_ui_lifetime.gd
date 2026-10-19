extends SceneTree
var checks=[]
var rows=[]
func check(ok,note):checks.append({"passed":bool(ok),"check":note})
func _initialize():call_deferred("run")
func run():
	if DisplayServer.get_name()!="headless" or OS.get_environment("FARM_REVIEW_OUTPUT")=="":quit(2);return
	for cycle in range(3):
		var boot=load("res://game/loading.tscn").instantiate();boot.review_mode=true;root.add_child(boot)
		var deadline=Time.get_ticks_msec()+25000
		while not boot.finished and boot.failure=="" and Time.get_ticks_msec()<deadline:await process_frame
		check(boot.finished,"Production boot cycle %d"%cycle)
		if not boot.finished:boot.queue_free();break
		var g=boot.game;g.set_process(false);g.world.paused=true;g.story_modal="";g.field_book=false;g.field_shop=false
		for category in g.ColonyModel.ARCHITECT:
			g.select_group(0);g.ColonyPanels.architecture_category(g,category)
		g.choose_walk();g.resident_tab="ステータス";g.refresh()
		var weak_game=weakref(g);var weak_world=weakref(g.world);var weak_boot=weakref(boot)
		g=null;boot.queue_free();boot=null;await process_frame;await process_frame
		check(weak_game.get_ref()==null and weak_boot.get_ref()==null,"Game scene and loading node released cycle %d"%cycle)
		check(weak_world.get_ref()==null,"World reference released after UI closes cycle %d"%cycle)
		rows.append({"cycle":cycle,"objects":int(Performance.get_monitor(Performance.OBJECT_COUNT)),"resources":int(Performance.get_monitor(Performance.OBJECT_RESOURCE_COUNT)),"static_bytes":int(Performance.get_monitor(Performance.MEMORY_STATIC)),"nodes":int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT))})
	var failures=checks.filter(func(c):return not c.passed).size()
	FileAccess.open(OS.get_environment("FARM_REVIEW_OUTPUT")+"/phase1-ui-lifetime.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"rows":rows,"failures":failures,"scope":"Three finite headless boot/UI/close cycles; not a long-duration memory-leak guarantee"},"  "))
	print("PHASE1_UI_LIFETIME failures=",failures," rows=",rows);quit(1 if failures else 0)
