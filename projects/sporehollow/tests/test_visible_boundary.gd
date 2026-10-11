extends SceneTree
const Farm=preload("res://game/world.gd")
var checks=[]
var failed=0
func _initialize():call_deferred("run")
func check(ok,note):
	checks.append({"passed":bool(ok),"check":note})
	if not ok:failed+=1;push_error(note)
func fresh():
	var w=Farm.new({},31).begin_day();w.story.intro_seen=true;w.trees.clear();w.natural.clear();w.rocks.clear();w.structures.clear();w.nature_config.spawn_chance_per_second=0
	return w
func enemy(w,p,entry=Vector2i(1,8)):
	w.spawn_enemy({"entry":entry,"role":"kidnapper","lv":1})
	var e=w.enemies.back();e.pos=p;e.arrival_complete=true;e.stamina=100.0;e.move_credit=1.0;e.path=[p];return e
func run():
	var out=OS.get_environment("FARM_REVIEW_OUTPUT")
	if out=="" or "--isolated-review" not in OS.get_cmdline_user_args():quit(2);return
	# 1. All 1700 cells are inside; edge commands work, off-map ally paths do not.
	var w=fresh();var count=0
	for y in range(-1,35):
		for x in range(-1,51):
			if w.inside(Vector2i(x,y)):count+=1
	check(count==1700,"Exactly 50 x 34 cells are inside")
	for p in [Vector2i.ZERO,Vector2i(49,0),Vector2i(0,33),Vector2i(49,33)]:
		check(w.walkable(p) and not w.find_path(w.keeper.pos,p).is_empty() and w.Jobs.build_reason(w,"wood_wall",p)=="","Corner is reachable and accepts construction: "+str(p))
	w.keeper.pos=Vector2i(1,1);w.animals[0].pos=Vector2i(0,2)
	var guided=w.Orders.enqueue(w,"guide",[w.animals[0].id],Vector2i.ZERO)
	check(guided and w.jobs.back().targets[0].dest==Vector2i.ZERO and Vector2i(0,1) in w.Orders.command_goals(w,w.animals[0],1),"Animal guide preserves the exact corner destination and command contacts include edge cells")
	w.jobs.clear()
	check(not w.walkable(Vector2i(-1,8)) and w.find_path(Vector2i(0,8),Vector2i(-1,8)).is_empty(),"No ally walkable forest or off-map rescue path")
	for p in [Vector2i(1,8),Vector2i(48,8),Vector2i(12,1),Vector2i(12,32)]:w.spawn_enemy({"entry":p,"role":"kidnapper","lv":1})
	check(w.enemies.size()==4 and w.enemies.all(func(e):return e.pos in w.Land.border_cells()) and w.enemies.map(func(e):return e.pos).size()==4,"All four raid directions spawn on visible border cells")
	for e in w.enemies:
		for i in range(12):w.enemy_step(e);w.tick+=1
	check(w.enemies.all(func(e):return w.inside(e.pos) and e.get("arrival_complete",false)),"Visible-border enemies enter the field normally")
	w=fresh()
	for p in w.Land.border_cells():w.structures[p]={"id":1000+p.y*w.W+p.x,"kind":"wood_wall","status":"ready","open":false,"hp":30,"max_hp":30,"armor":0}
	var raid=enemy(w,Vector2i(-1,8));raid.arrival_complete=false
	check(w.enemies.size()==1 and w.Land.is_exit(raid.pos),"Fully walled perimeter retains a raid at its adjacent visible boundary")
	for i in range(16):w.enemy_step(raid);w.tick+=1
	check(w.structures.values().any(func(b):return b.hp<30),"Adjacent arriving enemy physically attacks the perimeter rather than disappearing")
	# 2. Human and animal remain rescuable on the edge, commit one step beyond it.
	for side in [[Vector2i(0,8),Vector2i(-1,8),Vector2i(1,8)],[Vector2i(49,8),Vector2i(50,8),Vector2i(48,8)],[Vector2i(12,0),Vector2i(12,-1),Vector2i(12,1)],[Vector2i(12,33),Vector2i(12,34),Vector2i(12,32)]]:
		w=fresh();var e=enemy(w,side[0],side[2]);e.carry="keeper";w.keeper.carrier=e.id;w.keeper.state="captured";w.keeper.pos=e.pos
		check(w.phase!="result" and not e.done,"Keeper on visible edge is not lost: "+str(side[0]))
		w.move_enemy(e,side[1],side[1])
		check(w.keeper.state=="abducted" and e.done and e.pos==side[1],"Keeper crossing commits on same movement: "+str(side[1]))
		w=fresh();e=enemy(w,side[1],side[2]);var a=w.animals[0];a.pos=side[0];a.abductor=e.id;e.led_animal=a.id;a.move_credit=0.0
		w.Departure.animal(w,e,a)
		check(not a.get("lost",false),"Animal on last visible cell retains rescue window: "+str(side[0]))
		a.move_credit=1.0;w.Departure.animal(w,e,a)
		check(a.get("lost",false) and e.done and a.pos==side[1],"Animal's own crossing commits: "+str(side[1]))
	# 3. Full 2x2 idol exits at the new bounds, no premature edge loss or hidden forest leg.
	for row in [[Vector2i(-1,8),Vector2i(-2,8),Vector2i(1,8),Vector2i(2,0)],[Vector2i(49,8),Vector2i(50,8),Vector2i(48,8),Vector2i(-1,0)],[Vector2i(12,-1),Vector2i(12,-2),Vector2i(12,1),Vector2i(0,2)],[Vector2i(12,33),Vector2i(12,34),Vector2i(12,32),Vector2i(0,-1)]]:
		w=fresh();var e=enemy(w,row[0]+row[3],row[2]);e.role="idol_extractor";w.story.idol.position=[row[0].x,row[0].y];w.story.idol.carrier=e.id;w.story.idol.state="transporting"
		check(not w.Story.cells(row[0]).all(func(p):return not w.inside(p)),"Partly visible idol is still present: "+str(row[0]))
		w.Story.idol_enemy(w,e)
		check(w.Story.at(w)==row[1] and w.story.idol.state=="lost","Full idol crossing commits at new edge: "+str(row[1]))
	# 4. Legacy off-map states migrate without changing interior positions, time or resources.
	w=fresh();var keeper_pos=w.keeper.pos;var totals=w.Stock.totals(w);var e=enemy(w,Vector2i(-20,8));w.boundary_version=0;w.campaign.erase("boundary_version");w.calendar_ticks=100
	w.animals[0].home=Vector2i(-5,8);w.animals[0].order=Vector2i(-5,8);w.animals[0].pending={"kind":"stay","pos":Vector2i(-5,8),"at":1}
	w.Snapshot.save(w,out+"/legacy.snapshot");w=w.Snapshot.restore(out+"/legacy.snapshot")
	check(w.keeper.pos==keeper_pos and w.calendar_ticks==100 and w.Stock.totals(w)==totals and w.inside(w.enemies[0].pos) and not w.enemies[0].done,"Legacy off-map enemy migrated; interior position, time and stock retained")
	check(w.animals[0].home==w.animals[0].pos and w.animals[0].order==w.animals[0].pos and w.animals[0].pending.pos==w.animals[0].pos,"Legacy off-map animal home, order and pending destination are remapped without losing the order")
	var first=w.enemies[0].pos;w.Snapshot.save(w,out+"/migrated.snapshot");w=w.Snapshot.restore(out+"/migrated.snapshot")
	check(w.enemies[0].pos==first and w.boundary_version==1,"Migrated snapshot reload is idempotent")
	# Camera margins expose corner cells below top HUD and above bottom panels at both zoom limits.
	var scene=load("res://game/main.tscn").instantiate();scene.automated=true;scene.world=w;w.paused=true;root.add_child(scene);await process_frame;scene.neutral()
	for zoom in [0.65,1.0,1.6]:
		scene.camera.zoom=Vector2.ONE*zoom
		for p in [Vector2i.ZERO,Vector2i(49,0),Vector2i(0,33),Vector2i(49,33)]:
			scene.camera.position=scene.center(p);scene.clamp_camera();var screen=scene.get_canvas_transform()*scene.center(p)
			check(Rect2(100,130,890,390).has_point(screen),"Panned corner remains in operable viewport at zoom "+str(zoom)+": "+str(p))
	check(scene.scene_actors().filter(func(a):return a.kind=="tree").all(func(a):return w.inside(a.data)),"No outer forest draw actors remain")
	if DisplayServer.get_name()!="headless":
		scene.world=Farm.new({},31).begin_day();scene.world.story.intro_seen=true;scene.world.paused=true;scene.refresh()
		scene.camera.zoom=Vector2.ONE*0.65;scene.camera.position=scene.center(Vector2i(49,33));scene.clamp_camera();scene.queue_redraw()
		await process_frame;await process_frame;await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(out+"/visible-boundary.png")
	scene.queue_free();await process_frame
	FileAccess.open(out+"/visible-boundary.json",FileAccess.WRITE).store_string(JSON.stringify({"method":"Four controlled production-rule groups plus headless camera transforms; no human play","checks":checks,"failures":failed},"\t"))
	print("VisibleBoundary: ",failed," failures");quit(1 if failed else 0)
