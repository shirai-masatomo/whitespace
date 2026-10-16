extends "res://tests/test_construction_recovery.gd"
func run():
	var boot=load("res://game/loading.tscn").instantiate();boot.review_mode=true;root.add_child(boot)
	var deadline=Time.get_ticks_msec()+25000
	while not boot.finished and boot.failure=="" and Time.get_ticks_msec()<deadline:await process_frame
	check(boot.finished,"Production headless loading completes")
	if not boot.finished:quit(1);return
	var scene=boot.game;scene.set_process(false);var j=partial();scene.world=w;scene.story_modal="";scene.field_book=false;scene.field_shop=false;scene.neutral();w.paused=true
	scene.selected={"kind":"job","id":j.id,"pos":j.pos};scene.refresh()
	var info=scene.construction_info() if scene.has_method("construction_info") else scene.construction_view.rows.get(j.id,{})
	scene.construction_view.update(w);info=scene.construction_view.rows[j.id]
	check(info.delivered==3 and info.missing==2 and info.waiting_material,"Production selected card reads actual3/5 shortage")
	var key=InputEventKey.new();key.pressed=true;key.physical_keycode=KEY_X;scene._route_input(key)
	check(w.jobs.is_empty() and w.Stock.totals(w).get("wood",0)==3,"X-key cancels paused partial site and releases3")
	check(w.field_items.all(func(r):return r.location=="ground" and r.job_id==-1),"X leaves ordinary unowned physical goods")
	w.paused=false;check(w.Stock.designate(w,"haul",j.pos,j.pos).accepted==1,"Returned materials remain collectible after UI cancel");tick_work(100)
	check(w.Stock.available(w,"wood")==3,"UI-cancelled goods reach stockpile")
	setup();scene.world=w;w.act("cooking_bench",Vector2i(35,25));scene.neutral();scene.camera.zoom=Vector2.ONE
	var mouse=InputEventMouseButton.new();mouse.button_index=MOUSE_BUTTON_LEFT;mouse.position=scene.get_canvas_transform()*scene.center(Vector2i(36,26));scene.board_click(mouse)
	check(scene.selected.get("kind")=="job" and scene.selected.id==w.jobs[0].id,"Click on2x2 far cell selects same construction job")
	boot.queue_free();await process_frame
	var failed=checks.filter(func(c):return not c.passed).size()
	FileAccess.open(OS.get_environment("FARM_REVIEW_OUTPUT")+"/construction-input.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failed":failed},"  "))
	print("Construction input: ",checks.size()," checks, ",failed," failures");quit(1 if failed else 0)
