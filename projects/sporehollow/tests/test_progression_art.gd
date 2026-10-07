extends SceneTree
const Farm=preload("res://game/world.gd")
const Art=preload("res://game/delivered_art.gd")
const Motion=preload("res://game/progression_art.gd")
var game
var checks=0
var failures=0
var output=""
var shots=[]
func _initialize():call_deferred("run")
func check(ok: bool,message: String):
	checks+=1
	if not ok:failures+=1;push_error(message)
func capture(name: String):
	if output=="":return
	game.queue_redraw()
	await process_frame;await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(output+"/"+name+".png")
	shots.append({"file":name+".png","enemies":game.enemy_art.duplicate(true),"animals":game.actor_art.duplicate(true)})
func run():
	output=OS.get_environment("FARM_REVIEW_OUTPUT")
	if DisplayServer.get_name()!="headless" and (output=="" or not "--isolated-review" in OS.get_cmdline_user_args()):quit(2);return
	root.size=Vector2i(1280,800)
	game=load("res://game/main.tscn").instantiate();game.automated=true
	game.world=Farm.new({},17).begin_day();root.add_child(game);game.set_process(false)
	await process_frame
	var w=game.world
	w.trees.clear() # Clear only this render fixture so small bodies are not hidden by canopies.
	w.debug_enabled=true
	for species in ["doberman","bullfrog","hedgehog"]:w.debug_action(species,{})
	w.keeper.pos=Vector2i(16,8);w.animals[0].pos=Vector2i(16,10)
	for i in range(1,4):w.animals[i].pos=Vector2i(8+(i-1)*3,12)
	for i in range(6):
		w.spawn_enemy({"entry":w.entries[0],"role":Motion.SPECIES[i]})
		w.enemies.back().pos=Vector2i([8,11,15][i%3],8+(i/3)*2)
	game.reset_view();game.camera.zoom=Vector2(1.8,1.8);game.camera.position=game.center(Vector2i(12,10));game.group=-1
	game._process(0)
	for who in Motion.SPECIES:
		for facing in [-1,1]:check(Art.CLIPS.has(Motion.clip(who,"idle",facing)),"Formal idle: "+who)
	for key in Art.CLIPS:
		if key.get_slice("/",0) not in Motion.SPECIES:continue
		var c=Art.CLIPS[key]
		check(c.frames.size()==c.times.size() and Art.duration(key)>0,"Complete timings: "+key)
		for frame in c.frames:
			var body=frame.body if frame is Dictionary else frame
			check(body.get_image().get_used_rect().has_area(),"Nonempty delivered RGBA: "+key)
	await capture("01_formal_actors")
	var destroyer=w.enemies[0];var salary=w.enemies[2];var ninja=w.enemies[3]
	var frog=w.animals[2];var hedge=w.animals[3]
	destroyer.next_attack+=4;salary.phone_started=true;ninja.shuriken_at=20;frog.skill_ready.tongue=20;hedge.spines_until=20
	w.skill_log.append({"skill":"tongue","actor":frog.id,"target":w.enemies[4].id})
	game._process(0)
	check(game.enemy_art[destroyer.id].action=="iron_ball_hit","Attack selects layered iron ball")
	check(game.enemy_art[salary.id].action=="phone_take","Phone entrance uses existing state")
	check(game.enemy_art[ninja.id].action=="shuriken","Existing projectile event selects throw")
	check(game.actor_art["a"+str(frog.id)].action=="tongue_extend","Existing tongue event selects extension")
	check(game.actor_art["a"+str(hedge.id)].action=="defense_enter","Spines use formal transition")
	game.visual_time+=0.46;game._process(0)
	check(game.enemy_art[salary.id].action=="phone_call","Phone holds after entrance")
	await capture("02_formal_actions")
	var before=w.campaign.duplicate(true);var hp=destroyer.hp;var tick=w.tick
	w.paused=true
	var clock_before=game.visual_time
	game._process(2)
	check(game.visual_time==clock_before and w.tick==tick and w.campaign==before and destroyer.hp==hp,"Pause and drawing do not advance world or damage")
	w.paused=false;game.visual_time+=3
	salary.phone_started=false;hedge.spines_until=0
	game._process(0)
	check(game.enemy_art[salary.id].action=="phone_put","Phone exits once")
	check(game.actor_art["a"+str(hedge.id)].action=="defense_exit","Defense exits once")
	game.visual_time+=2;game._process(0)
	for multiplier in [0.5,1.0,2.0]:
		game.speed=multiplier
		var before_time=game.visual_time
		game._process(0.04)
		check(is_equal_approx(game.visual_time-before_time,0.04*multiplier),"Motion clock follows speed "+str(multiplier))
	for e in w.enemies:
		e.pos.x-=1;Motion.update(game,e,true)
		check(game.enemy_art[e.id].action==("run" if e.archetype=="runner" else "walk"),"Movement uses formal frames: "+e.archetype)
		game.view_positions["e"+str(e.id)]=Vector2(e.pos)
		Motion.update(game,e,true)
		check(game.enemy_art[e.id].facing==-1 and game.enemy_art[e.id].action=="idle","Left stop keeps facing: "+e.archetype)
	for a in w.animals:
		if a.species not in Motion.SPECIES:continue
		a.facing=-1;Motion.update(game,a,false)
		check(Motion.bounds(game,a).has_area(),"Selection follows visible animal: "+a.species)
	await capture("03_left_idle")
	if output!="":FileAccess.open(output+"/observations.json",FileAccess.WRITE).store_string(JSON.stringify({"implementation_commit":OS.get_environment("FARM_REVIEW_COMMIT"),"asset_delivery_commit":JSON.parse_string(FileAccess.get_file_as_string("res://game/art_provenance.json")).latest_delivery_commit,"method":"Current game rendering, controlled existing actor fixtures; headless event/clock checks. No user input or save.","checks":checks,"failures":failures,"shots":shots},"  "))
	print("PROGRESSION_ART: ",checks," checks failures=",failures)
	quit(0 if failures==0 else 1)
