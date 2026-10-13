extends SceneTree
const Metrics=preload("res://game/terrain_metrics.gd")
var rows=[]
var out=""
func _initialize():call_deferred("run")
func stats(values):
	var s=values.duplicate();s.sort();var total=0.0
	for v in s:total+=v
	return {"mean":total/s.size(),"p95":s[mini(s.size()-1,ceili(s.size()*0.95)-1)],"p99":s[mini(s.size()-1,ceili(s.size()*0.99)-1)],"max":s[-1],"over50":s.filter(func(v):return v>50).size()}
func run():
	out=OS.get_environment("FARM_REVIEW_OUTPUT")
	if out=="" or "--isolated-review" not in OS.get_cmdline_user_args():quit(2);return
	root.size=Vector2i(1280,800);root.content_scale_size=Vector2i(1280,800)
	Metrics.enabled=true
	var baseline=OS.get_environment("FARM_STARTUP_BASELINE")=="1"
	for repeat in range(2):
		seed(31);Metrics.take();var start=Time.get_ticks_usec();var loaded=start;var g;var boot
		if baseline:
			var scene=load("res://game/main.tscn");loaded=Time.get_ticks_usec()
			g=scene.instantiate();g.automated=true;root.add_child(g)
		else:
			boot=load("res://game/loading.tscn").instantiate();boot.review_mode=true;root.add_child(boot)
			while not boot.finished and boot.failure=="":await process_frame
			if boot.failure!="":push_error(boot.failure);quit(1);return
			g=boot.game
		var ready=Time.get_ticks_usec();var init=Metrics.take()
		g.automated=false;g.persistence_enabled=false
		if g.story_modal!="":g.StoryView.close(g)
		var frames=[];var last=ready;var elapsed=0.0
		while elapsed<5.0:
			await process_frame;await RenderingServer.frame_post_draw
			var now=Time.get_ticks_usec();var ms=(now-last)/1000.0;last=now;elapsed+=ms/1000.0
			var row=Metrics.take();row.frame_ms=ms;frames.append(row)
		var record={"repeat":repeat,"resource_load_ms":(loaded-start)/1000.0,"before_control_ms":(ready-start)/1000.0,"init_scopes_ms":init,"frames_ms":stats(frames.map(func(f):return f.frame_ms)),"frames":frames,"world_tick":g.world.tick}
		if not baseline:record.loading=boot.timings;record.world_frozen_during_loading=boot.frozen_ok
		rows.append(record)
		if repeat==0:
			root.get_texture().get_image().save_png(out+"/"+("before" if baseline else "after")+"-ready.png")
			g.world.Snapshot.save(g.world,out+"/large.snapshot")
		g.queue_free()
		if boot!=null:boot.queue_free()
		await process_frame
	FileAccess.open(out+"/startup.json",FileAccess.WRITE).store_string(JSON.stringify({"baseline":baseline,"runs":rows,"method":"Two sequential fresh worlds; first resource load cold in process, OS/GPU cache not reset; normal simulation after initial preparation; 60fps cap; no OS input.","source_commit":OS.get_environment("FARM_REVIEW_COMMIT")},""))
	quit(0)
