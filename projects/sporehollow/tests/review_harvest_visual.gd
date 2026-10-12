extends SceneTree
const Farm=preload("res://game/world.gd")
var game
var out=""
var shots=[]
var stages=[]
var samples=[]
func _initialize():call_deferred("run")
func mark(note):
	stages.append({"stage":note,"ms":Time.get_ticks_msec()})
	FileAccess.open(out+"/harvest-stages.json",FileAccess.WRITE).store_string(JSON.stringify(stages))
func image(name):
	game.queue_redraw();game.hud.queue_redraw()
	await process_frame;await RenderingServer.frame_post_draw
	var picture=root.get_texture().get_image();var error=picture.save_png(out+"/"+name+".png")
	if error!=OK:push_error("Could not save "+name);quit(2)
func scene(kind: String):
	var w=Farm.new({},31).begin_day();w.story.intro_seen=true;w.trees.clear();w.rocks.clear();w.natural.clear();w.field_items.clear();w.zones.clear();w.storage_cells.clear();w.Zones.sync_storage(w);w.nature_config.spawn_chance_per_second=0;w.campaign.last_supply_day=99999;w.keeper.pos=Vector2i(16,12);w.keeper.satiety=100;w.keeper.sleepiness=0;w.animals[0].pos=Vector2i(6,6);w.jobs.clear();w.Stock.sync(w)
	var p=Vector2i(19,12)
	if kind=="mine":
		for point in [p,p+Vector2i.RIGHT,p+Vector2i.UP,p+Vector2i.RIGHT+Vector2i.UP,p+Vector2i.RIGHT*2]:w.rocks[point]={"amount":8,"forbidden":false}
	else:
		for point in [p,p+Vector2i(2,-1)]:w.trees[point]="review-tree-%d-%d"%[point.x,point.y]
	w.Tasks.designate(w,kind,p);game.world=w;game.reset_view();game.neutral();game.camera.zoom=Vector2.ONE*2;game.camera.position=game.center(p)+Vector2(0,-35);game.clamp_camera();game.visual_time=0;game.harvest_view.setup(w)
	return p
func run():
	out=OS.get_environment("FARM_REVIEW_OUTPUT")
	if out=="" or "--isolated-review" not in OS.get_cmdline_user_args():quit(2);return
	mark("start");root.size=Vector2i(1280,800);root.content_scale_size=Vector2i(1280,800)
	game=load("res://game/main.tscn").instantiate();game.automated=true;root.add_child(game)
	await process_frame;game.set_process(false);game.audio.set_process(false)
	for kind in ["mine","clear_tree"]:
		var p=scene(kind);var named={};var accumulated=0.0
		for frame in range(64):
			if frame>0:
				accumulated+=0.125
				while accumulated>=Farm.DT:game.world.step();accumulated-=Farm.DT
			game.accumulated=accumulated;game.visual_time=frame*0.125;game.audio.seconds+=0.125
			game.smooth_actor("keeper",game.world.keeper.pos,0.125)
			game.update_facility_effects(0.125);game.refresh_jobs();game.harvest_view.sync(game)
			await image("frame_%s_%03d"%[kind,frame])
			var j=game.world.Tasks.job(game.world,kind,p);var phase=""
			if not j.is_empty() and j.state=="working" and not named.has("start"):phase="start"
			elif game.world.harvest_events.any(func(e):return e.kind==kind and e.event=="strike") and not named.has("strike"):phase="strike"
			elif not j.is_empty() and j.get("work_elapsed",0.0)>=3.75 and not named.has("near_complete"):phase="near_complete"
			elif not game.world.Harvest.exists(game.world,kind,p) and not named.has("after") and game.world.harvest_events.any(func(e):return e.kind==kind and e.event=="complete" and (game.world.tick-e.tick)*Farm.DT+accumulated>=game.HarvestView.EFFECT_SECONDS):phase="after"
			if phase!="":
				var filename="%s_%s"%[kind,phase];await image(filename);named[phase]=true
				shots.append({"file":filename+".png","frame":frame,"seconds":frame*0.125,"tick":game.world.tick,"phase":phase,"progress":j.get("work_elapsed",0.0),"target_exists":game.world.Harvest.exists(game.world,kind,p),"physical_stock":game.world.Stock.totals(game.world),"usable_stock":game.world.Stock.available(game.world,"stone" if kind=="mine" else "wood")})
			if frame%8==0:mark("%s:%d"%[kind,frame])
		if named.size()!=4:push_error("Missing harvest phases: "+kind);quit(3);return
		samples.append({"kind":kind,"events":game.world.harvest_events.duplicate(true),"audio_played":game.audio.played.duplicate(true),"remaining_rocks":game.world.rocks.size(),"remaining_trees":game.world.trees.size()})
	for kind in ["mine_hit","chop_hit","rock_crumble","tree_fall"]:game.audio.cache[kind].save_to_wav(out+"/"+kind+".wav")
	FileAccess.open(out+"/harvest-visual.json",FileAccess.WRITE).store_string(JSON.stringify({"implementation":OS.get_environment("FARM_REVIEW_COMMIT"),"method":"Actual GPU viewport frames of normal World.step at fixed simulation sampling, 64 frames per job at 8 fps; seed31 with explicitly controlled approach/adjacent deposits/trees, no real user save","screens":shots,"samples":samples,"audio":"Dummy driver; emitted work cues and generated PCM exported, hardware listening not claimed"},"\t"))
	mark("complete");game.queue_free();await process_frame;quit(0)
