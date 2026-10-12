extends SceneTree
const Farm=preload("res://game/world.gd")
var game
var out=""
var shots=[]
var observations=[]
func _initialize():call_deferred("run")
func mark(stage):
	FileAccess.open(out+"/rock-stages.json",FileAccess.WRITE).store_string(JSON.stringify({"stage":stage,"milliseconds":Time.get_ticks_msec()}))
func image(name):
	game.refresh_jobs();game.queue_redraw();game.hud.queue_redraw()
	await process_frame;await RenderingServer.frame_post_draw
	var error=root.get_texture().get_image().save_png(out+"/"+name+".png")
	if error!=OK:push_error("PNG save failed: "+name);quit(2)
func farm():
	var w=Farm.new({},31).begin_day();w.story.intro_seen=true;w.trees.clear();w.rocks.clear();w.natural.clear();w.mined_rock_cells.clear();w.jobs.clear();w.field_items.clear();w.zones.clear();w.storage_cells.clear();w.Zones.sync_storage(w);w.Stock.sync(w);w.keeper.satiety=100;w.keeper.sleepiness=0;w.animals[0].pos=Vector2i(4,4);w.nature_config.spawn_chance_per_second=0;w.campaign.last_supply_day=99999
	return w
func masks(w):
	var result={}
	for p in w.rocks:result["%d,%d"%[p.x,p.y]]=game.RockView.mask(w,p)
	return result
func capture(name,p,seconds):
	await image(name)
	shots.append({"file":name+".png","seconds":seconds,"tick":game.world.tick,"target":[p.x,p.y],"target_exists":game.world.rocks.has(p),"progress":game.world.Harvest.progress(game.world,"mine",p),"rock_count":game.world.rocks.size(),"masks":masks(game.world),"stone_owned":game.world.Stock.totals(game.world).get("stone",0),"stone_usable":game.world.Stock.available(game.world,"stone"),"walkable":game.world.walkable(p)})
func run():
	out=OS.get_environment("FARM_REVIEW_OUTPUT")
	if out=="" or "--isolated-review" not in OS.get_cmdline_user_args():quit(2);return
	mark("start");root.size=Vector2i(1280,800);root.content_scale_size=Vector2i(1280,800)
	game=load("res://game/main.tscn").instantiate();game.automated=true;root.add_child(game);await process_frame;game.set_process(false);game.audio.set_process(false)
	var reference=farm();var candidates=[]
	for y in range(3,reference.H-5):
		for x in range(3,reference.W-5):
			var base=Vector2i(x,y)
			if reference.Story.idol_cells(reference).any(func(p):return p.x>=x-2 and p.x<=x+4 and p.y>=y-2 and p.y<=y+4):continue
			var all_rock=true
			for dy in range(3):
				for dx in range(3):
					if not game.RockView.geology(reference,base+Vector2i(dx,dy)):all_rock=false
			if all_rock:candidates.append(base)
	if candidates.is_empty():push_error("No genuine rocky-field 3x3 fixture");quit(3);return
	candidates.sort_custom(func(a,b):return reference.distance(a,Vector2i(25,17))<reference.distance(b,Vector2i(25,17)))
	var base=candidates[0]
	for which in ["center","edge","corner"]:
		mark(which);var w=farm()
		for y in range(3):
			for x in range(3):w.rocks[base+Vector2i(x,y)]={"amount":8,"forbidden":false}
		var target=base+Vector2i(1,1) if which=="center" else base+Vector2i(1,2) if which=="edge" else base+Vector2i(0,2)
		w.keeper.pos=base+Vector2i(1,3) if which!="corner" else base+Vector2i(-1,2)
		game.world=w;game.reset_view();game.neutral();game.camera.zoom=Vector2.ONE*2.0;game.camera.position=game.center(base+Vector2i(1,1))+Vector2(0,-25);game.clamp_camera();game.harvest_view.setup(w)
		await capture(which+"_before",target,0)
		w.Tasks.designate(w,"mine",target)
		if which=="center":w.Tasks.designate(w,"mine",base+Vector2i(1,2))
		var named={};var accumulated=0.0
		for frame in range(104):
			if frame>0:
				accumulated+=0.125
				while accumulated>=Farm.DT:w.step();accumulated-=Farm.DT
			game.accumulated=accumulated;game.visual_time=frame*0.125;game.audio.seconds+=0.125;game.smooth_actor("keeper",w.keeper.pos,0.125);game.update_facility_effects(0.125)
			await image("frame_%s_%03d"%[which,frame])
			if which=="center" and not w.rocks.has(base+Vector2i(1,2)) and not named.has("corridor"):
				await capture("center_corridor",target,frame*0.125);named.corridor=true
			if w.rocks.has(target) and w.Harvest.progress(w,"mine",target)>=0.55 and not named.has("damage"):
				await capture(which+"_damage",target,frame*0.125);named.damage=true
			if not w.rocks.has(target) and not named.has("after") and w.harvest_events.any(func(e):return e.pos==target and e.event=="complete" and (w.tick-e.tick)*Farm.DT+accumulated>0.65):
				await capture(which+"_after",target,frame*0.125);named.after=true
			if frame%16==0:mark(which+":"+str(frame))
		if not named.has("damage") or not named.has("after"):push_error("Missing mine case: "+which);quit(4);return
		var retreat=base+Vector2i(-1,3)
		if not w.act("move",retreat):push_error("Could not issue ordinary move-away job");quit(5);return
		for i in range(100):
			w.step();game.smooth_actor("keeper",w.keeper.pos,Farm.DT)
			if w.keeper.pos==retreat:break
		if w.keeper.pos!=retreat:push_error("Could not walk aside after mining");quit(5);return
		game.smooth_actor("keeper",w.keeper.pos,1.0);game.accumulated=0
		await capture(which+"_drops_clear",target,w.tick*Farm.DT)
		w.Snapshot.save(w,out+"/"+which+".snapshot");var restored=w.Snapshot.restore(out+"/"+which+".snapshot")
		observations.append({"case":which,"method":"All removal through ordinary World.step; centre first opens a real edge corridor","rock_count":w.rocks.size(),"stone_owned":w.Stock.totals(w).get("stone",0),"restore_identical":restored.rocks==w.rocks and restored.field_items==w.field_items and restored.mined_rock_cells==w.mined_rock_cells})
	FileAccess.open(out+"/rock-observations.json",FileAccess.WRITE).store_string(JSON.stringify({"source_commit":OS.get_environment("FARM_REVIEW_COMMIT"),"material_commit":"7b6e81320009710b861fca04d6b86470de3835d7","fixture_base":[base.x,base.y],"method":"Seed31 actual rocky biome distribution, controlled 3x3 cells; ordinary fixed-tick tasks and pathfinding, no completion calls or teleport into the centre; 104 frames per case at 8 fps","screens":shots,"cases":observations},"  "))
	mark("complete");game.queue_free();await process_frame;quit(0)
