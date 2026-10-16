extends SceneTree
var records=[]
var failed=false
func _initialize():call_deferred("capture")
func shot(g,name,setup):
	g.camera.force_update_scroll();g.queue_redraw();g.hud.queue_redraw()
	for frame in range(3):await process_frame;await RenderingServer.frame_post_draw
	var img=root.get_texture().get_image()
	var error=img.save_png(OS.get_environment("FARM_REVIEW_OUTPUT")+"/"+name)
	failed=failed or error!=OK
	records.append({"file":name,"width":img.get_width(),"height":img.get_height(),"seed":g.world.seed_value,"tick":g.world.tick,"setup":setup,"png_error":error})
func ready_build(w,kind,q):
	var d=w.BUILD[kind]
	var b={"id":w.next_structure_id,"kind":kind,"status":"ready","hp":d.hp,"max_hp":d.hp,"cost":d.cost,"resource":d.get("resource","soil"),"armor":0,"open":false,"lock_hp":0}
	w.next_structure_id+=1;w.Buildings.layer(w,kind)[q]=b
func capture():
	Engine.max_fps=30
	var boot=load("res://game/loading.tscn").instantiate();root.add_child(boot)
	var deadline=Time.get_ticks_msec()+45000
	while not boot.finished and boot.failure=="" and Time.get_ticks_msec()<deadline:await process_frame
	if not boot.finished:push_error("Capture loading failed: "+boot.failure);quit(1);return
	var g=boot.game;var w=g.world
	w.paused=true;g.set_process(false);g.set_process_input(false);g.set_process_unhandled_input(false)
	g.story_modal="";g.field_book=false;g.field_shop=false;g.controls.visible=true
	g.recenter();g.camera.force_update_scroll()
	g.select_group(0);g.select_tool("wall")
	var candidate=w.keeper.pos+Vector2i(5,-2)
	for dx in range(4,9):
		var q=w.keeper.pos+Vector2i(dx,-2)
		if w.Jobs.build_reason(w,"wall",q)=="":candidate=q;break
	g.pointer=g.get_canvas_transform()*g.center(candidate)
	await shot(g,"02-current-architect.png","Fresh map; architect walls/doors; soil wall pointer preview; no reservation committed")
	g.pointer=Vector2(-100,-100)
	var stock=w.zones.filter(func(z):return z.kind=="stockpile")
	if stock.is_empty():push_error("Initial stockpile missing");quit(1);return
	g.zone_controls.open(g,stock[0].id);g.zone_controls.access_tab=false;g.refresh()
	await shot(g,"03-current-stockpile-filters.png","Initial stockpile, default filter tree, storage items tab")
	g.zone_controls.access_tab=true;g.refresh()
	await shot(g,"04-current-stockpile-access.png","Same initial stockpile, resident withdrawal permission tab")
	g.zone_controls.close(g);g.neutral()
	# A staged completed house is necessary because a fresh map has no house.
	# Locate an empty 5x5 site; preserve generated terrain and the initial stockpile.
	var origin=Vector2i(-1,-1)
	for x in range(54,75):
		for y in range(25,40):
			var clear=true
			for dx in range(5):
				for dy in range(5):
					var q=Vector2i(x+dx,y+dy)
					if w.Jobs.build_reason(w,"wall",q)!="" or w.zones.any(func(z):return q in z.cells):clear=false
			if clear:origin=Vector2i(x,y);break
		if origin.x>=0:break
	if origin.x<0:push_error("No empty house fixture site");quit(1);return
	for x in range(5):
		for y in range(5):ready_build(w,"wood_wall" if x==0 or x==4 or y==0 or y==4 else "wood_tile",origin+Vector2i(x,y))
	ready_build(w,"door",origin+Vector2i(2,0));ready_build(w,"bed",origin+Vector2i(2,2))
	w.refresh_indoor();w.Zones.create(w,"residential",origin+Vector2i.ONE,origin+Vector2i(3,3));w.Homes.assign_pending(w)
	if w.homes.is_empty():push_error("Fixture house not recognized");quit(1);return
	g.selected={"kind":"house","id":w.homes.keys()[0]};g.refresh()
	g.camera.position=g.center(origin+Vector2i(2,2))
	await shot(g,"05-current-house.png","Staged fixture only: completed 5x5 wood wall/floor enclosure, door, one bed, 3x3 residential zone; keeper assigned by existing home rules. Not player progress.")
	var record={"source_commit":OS.get_environment("FARM_REVIEW_COMMIT"),"method":"Actual Godot viewport on private noninteractive desktop; current game source, not packaged EXE window; uncropped","fps_limit":Engine.max_fps,"rendering_driver":RenderingServer.get_video_adapter_name(),"elapsed_ms":Time.get_ticks_msec(),"screens":records,"failed":failed}
	var f=FileAccess.open(OS.get_environment("FARM_REVIEW_OUTPUT")+"/ui-capture.json",FileAccess.WRITE);f.store_string(JSON.stringify(record,"  "));f.close()
	boot.queue_free();await process_frame
	print("UI capture complete: ",records.size());quit(1 if failed else 0)
