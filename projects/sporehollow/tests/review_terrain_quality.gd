extends "res://tests/review_ui_survey.gd"
var timings=[]
func view(p,zoom):
	g.camera.position=g.center(p);g.camera.zoom=Vector2.ONE*zoom;g.clamp_camera();g.queue_redraw();g.hud.queue_redraw();await process_frame
func production_startup():
	seed(31)
	var started=Time.get_ticks_usec();var resource=load("res://game/main.tscn");var loaded=Time.get_ticks_usec()
	g=resource.instantiate();var instantiated=Time.get_ticks_usec();g.automated=true;root.add_child(g);var attached=Time.get_ticks_usec()
	var frames=[];var last=started
	for i in range(90):
		await process_frame
		var now=Time.get_ticks_usec();frames.append((now-last)/1000.0);last=now
		if i==4:g.keys_down={KEY_D:true}
		if i==34:g.keys_down.clear()
	var sorted=frames.duplicate();sorted.sort();var total=0.0
	for f in frames:total+=f
	timings.append({"production_new_game":true,"seed":g.world.seed_value,"scene_load_ms":(loaded-started)/1000.0,"instantiate_ms":(instantiated-loaded)/1000.0,"attach_ms":(attached-instantiated)/1000.0,"frames_ms":frames,"mean_ms":total/frames.size(),"max_ms":sorted[-1],"p95_ms":sorted[int(sorted.size()*0.95)],"method":"Actual scene owns new world, no injected fixture; automated disables persistence and world ticks; rendering and WASD are active; first frame includes cold scene load and setup; 30FPS cap; WASD from frame4."})
	g.queue_free();await process_frame
func startup(seed_number):
	if is_instance_valid(g):g.queue_free();await process_frame
	var started=Time.get_ticks_usec();var scene_resource=load("res://game/main.tscn");var loaded=Time.get_ticks_usec()
	var w=Farm.new({},seed_number).begin_day();w.story.intro_seen=true;var generated=Time.get_ticks_usec()
	g=scene_resource.instantiate();var instantiated=Time.get_ticks_usec();g.automated=true;g.world=w;root.add_child(g);var attached=Time.get_ticks_usec()
	var frames=[];var last=started
	for i in range(90):
		await process_frame
		var now=Time.get_ticks_usec();frames.append((now-last)/1000.0);last=now
		if i==4:g.keys_down={KEY_D:true}
		if i==34:g.keys_down.clear()
	var sorted=frames.duplicate();sorted.sort();var total=0.0
	for f in frames:total+=f
	timings.append({"seed":seed_number,"scene_load_ms":(loaded-started)/1000.0,"world_generation_ms":(generated-loaded)/1000.0,"instantiate_ms":(instantiated-generated)/1000.0,"attach_ms":(attached-instantiated)/1000.0,"frames_ms":frames,"mean_ms":total/frames.size(),"max_ms":sorted[-1],"p95_ms":sorted[int(sorted.size()*0.95)],"method":"Cold scene resource load + new world + production scene; 90 startup frames, WASD begins at frame4. GPU cap30. First frame includes synchronous setup; OS process bootstrap is separately audited."})
	g.set_process(false);g.audio.set_process(false);w.paused=true;g.neutral();g.reset_view()
	return w
func live_probe():
	g.automated=false;g.persistence_enabled=false;g.world.paused=false;g.set_process(true)
	var frames=[];var last=Time.get_ticks_usec();var tick_start=g.world.tick
	for i in range(120):
		g.keys_down={KEY_D:true,KEY_S:true} if i<60 else {KEY_A:true}
		await process_frame
		var now=Time.get_ticks_usec();frames.append((now-last)/1000.0);last=now
		if i>=8 and i<12:
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png(out+"/scroll_%02d.png"%(i-8))
			last=Time.get_ticks_usec() # Exclude PNG encoding overhead from frame timing.
	g.keys_down.clear();var sorted=frames.duplicate();sorted.sort();var total=0.0
	for f in frames:total+=f
	check(g.world.tick>tick_start,"Normal simulation runs during GPU camera measurement")
	timings.append({"live_simulation":true,"seed":g.world.seed_value,"frames_ms":frames,"mean_ms":total/frames.size(),"max_ms":sorted[-1],"p95_ms":sorted[int(sorted.size()*0.95)],"ticks":g.world.tick-tick_start,"method":"120 real GPU frames with world ticks enabled; diagonal and horizontal WASD,30FPS cap. PNG encoding excluded. Four successive rendered frames saved. No OS input."})
	g.automated=true;g.world.paused=true;g.set_process(false)
func run():
	out=OS.get_environment("FARM_REVIEW_OUTPUT")
	if out=="" or "--isolated-review" not in OS.get_cmdline_user_args():quit(2);return
	root.size=Vector2i(1280,800);root.content_scale_size=Vector2i(1280,800)
	await production_startup()
	var before=OS.get_environment("FARM_TERRAIN_BEFORE")=="1"
	for seed_number in ([31] if before else [31,73,109]):
		var w=await startup(seed_number)
		await view(Vector2i(50,34),0.224);await shot("seed_%d_overview"%seed_number,"全景 seed"+str(seed_number))
		var sites=[]
		for y in range(w.H):
			for x in range(w.W):
				var p=Vector2i(x,y)
				if w.Biome.kind(w,p)=="rocky":sites.append(p)
		sites.sort_custom(func(a,b):return w.Biome.field(w,a)[2]>w.Biome.field(w,b)[2])
		await view(sites[0],1.0);await shot("seed_%d_rocks"%seed_number,"岩場・通常倍率 seed"+str(seed_number))
		if not before and seed_number==31:
			await view(Vector2i(50,34),1.0);await shot("center","建築余地・拠点の地表")
			for kind in ["soil","sand","clay"]:
				var candidate=null;var strongest=-1.0;var channel={"soil":7,"sand":5,"clay":6}[kind]
				for y in range(10,w.H-10):
					for x in range(14,w.W-14):
						var p=Vector2i(x,y);var intensity=w.Biome.field(w,p)[channel]
						if w.Biome.material(w,p)==kind and intensity>strongest:candidate=p;strongest=intensity
				check(candidate!=null,"Surface exists: "+kind)
				if candidate!=null:
					await view(candidate,1.0);await shot("surface_"+kind,"地表 "+kind,"新規seed31・分布の濃い地点・仮配色。資源や移動効果は追加しない")
			await view(Vector2i(50,34),1.0);await live_probe()
	FileAccess.open(out+"/terrain-performance.json",FileAccess.WRITE).store_string(JSON.stringify({"source_commit":OS.get_environment("FARM_REVIEW_COMMIT"),"before":before,"startup":timings,"job_limit":Farm.Jobs.LIMIT},"  "))
	g.queue_free();await process_frame;quit(0 if checks.all(func(c):return c.passed) else 1)
