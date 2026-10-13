extends "res://tests/review_ui_survey.gd"
const Metrics=preload("res://game/terrain_metrics.gd")
var runs=[]
func stats(values):
	var s=values.duplicate();s.sort();var total=0.0
	for value in s:total+=value
	return {"mean":total/s.size(),"p95":s[mini(s.size()-1,ceili(s.size()*0.95)-1)],"p99":s[mini(s.size()-1,ceili(s.size()*0.99)-1)],"max":s[-1],"over25ms":s.filter(func(v):return v>25).size(),"over50ms":s.filter(func(v):return v>50).size()}
func measure(label,repeat):
	var samples=[];var elapsed=0.0;var last=Time.get_ticks_usec();var sign=1
	if label=="fast":g.camera.zoom=Vector2.ONE*0.5
	elif label=="boundaries":g.camera.zoom=Vector2.ONE*0.8;g.camera.position=g.center(Vector2i(8,12))
	else:g.camera.zoom=Vector2.ONE
	Metrics.take()
	while elapsed<5.0:
		if label!="startup":
			var half=640.0/g.camera.zoom.x
			if g.camera.position.x>=g.world.W*48-half-10:sign=-1
			if g.camera.position.x<=half+10:sign=1
			g.keys_down={KEY_D:sign>0,KEY_A:sign<0,KEY_S:label=="boundaries"}
		await process_frame;await RenderingServer.frame_post_draw
		var now=Time.get_ticks_usec();var ms=(now-last)/1000.0;last=now;elapsed+=ms/1000
		var row=Metrics.take();row.frame_ms=ms;row.camera=[g.camera.position.x,g.camera.position.y];samples.append(row)
	g.keys_down.clear()
	var cpu={}
	for key in ["main","scene_draw","ground_sync","chunk_draw"]:cpu[key]=stats(samples.map(func(v):return v.get(key,0.0)))
	runs.append({"repeat":repeat,"phase":label,"frames":stats(samples.map(func(v):return v.frame_ms)),"cpu_inclusive_ms":cpu,"samples":samples,"cap_fps":60,"speed_screen_px_s":g.CAMERA_SPEED,"zoom":g.camera.zoom.x,"world_tick":g.world.tick})
func shot_at(seed_number,p,z,name):
	g.camera.position=g.center(p);g.camera.zoom=Vector2.ONE*z;g.clamp_camera();g.camera.force_update_scroll();g.queue_redraw()
	await process_frame;await process_frame
	await shot(name,name,"seed%d; ground and objects from normal generation; camera/paused fixture"%seed_number)
func run():
	out=OS.get_environment("FARM_REVIEW_OUTPUT")
	if out=="" or "--isolated-review" not in OS.get_cmdline_user_args():quit(2);return
	root.size=Vector2i(1280,800);root.content_scale_size=Vector2i(1280,800);Metrics.enabled=true
	var initial=[]
	for repeat in range(3):
		seed(31);var start=Time.get_ticks_usec();var scene=load("res://game/main.tscn");var loaded=Time.get_ticks_usec()
		g=scene.instantiate();g.automated=true;root.add_child(g);g.automated=false;g.persistence_enabled=false;g.world.paused=false
		initial.append({"repeat":repeat,"seed":g.world.seed_value,"load_ms":(loaded-start)/1000.0,"initialize_ms":(Time.get_ticks_usec()-loaded)/1000.0,"total_ms":(Time.get_ticks_usec()-start)/1000.0,"cold_resource_cache":repeat==0})
		for phase in ["startup","normal","fast","boundaries"]:await measure(phase,repeat)
		g.queue_free();await process_frame
	Metrics.enabled=false
	for seed_number in [31,73,109]:
		var w=Farm.new({},seed_number).begin_day();w.story.intro_seen=true;w.paused=true
		g=load("res://game/main.tscn").instantiate();g.automated=true;g.world=w;root.add_child(g);g.neutral();await process_frame
		await shot_at(seed_number,Vector2i(50,34),0.224,"seed_%d_overview"%seed_number)
		var target=Vector2i(0,0);var high=-1.0
		for y in range(w.H):
			for x in range(w.W):
				var p=Vector2i(x,y);var f=w.Biome.field(w,p)
				if f[2]>high:high=f[2];target=p
		await shot_at(seed_number,target,1.0,"seed_%d_rock_edge"%seed_number)
		if seed_number==31:
			await shot_at(seed_number,Vector2i(50,34),1.0,"center_soil_grass")
			if OS.get_environment("FARM_TERRAIN_BEFORE")!="1":
				g.keys_down={KEY_D:true}
				for frame in range(4):
					for wait_frame in range(6):await process_frame
					await shot("scroll_%02d"%frame,"スクロール連続確認","1050px/s; paused world; position="+str(g.camera.position))
				g.keys_down.clear()
			for key in ["sand","clay"]:
				high=-1.0
				for y in range(10,w.H-10):
					for x in range(14,w.W-14):
						var p=Vector2i(x,y);var f=w.Biome.field(w,p);var value=f[5 if key=="sand" else 6]
						if value>high:high=value;target=p
				await shot_at(seed_number,target,1.0,key+"_transition")
		g.queue_free();await process_frame
	FileAccess.open(out+"/scroll-performance.json",FileAccess.WRITE).store_string(JSON.stringify({"implementation_commit":OS.get_environment("FARM_REVIEW_COMMIT"),"initialization":initial,"runs":runs,"method":"3 sequential repetitions,60fps cap; normal world simulation and production camera1050. fast means zoom0.5, boundaries zoom0.8; CPU scopes inclusive, renderer/driver/OS unattributed remainder. No OS input; no screenshots during measurements."},""))
	quit(0)
