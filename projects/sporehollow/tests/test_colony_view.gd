extends SceneTree
const Farm=preload("res://game/world.gd")
const HumanVisual=preload("res://game/human_visual.gd")
var game
var output=""
var failed=0
var record={"method":"Paused rendering fixtures and injected Godot key events; controlled frame deltas; no human play or strategy simulation","groups":{}}
func _initialize():call_deferred("run")
func check(group: String,ok: bool,note: String):
	if not record.groups.has(group):record.groups[group]=[]
	record.groups[group].append({"passed":ok,"check":note})
	if not ok:failed+=1;push_error(note)
func set_key(code: int,down: bool):
	var event=InputEventKey.new();event.keycode=code;event.physical_keycode=code;event.pressed=down
	Input.parse_input_event(event);await process_frame
func camera_trial(fps: int,diagonal: bool) -> Vector2:
	game.recenter();var start=game.camera.position
	await set_key(KEY_D,true)
	if diagonal:await set_key(KEY_S,true)
	for i in range(fps/2):game._process(1.0/fps)
	await set_key(KEY_D,false)
	if diagonal:await set_key(KEY_S,false)
	return game.camera.position-start
func capture(name: String):
	game.queue_redraw();game.hud.queue_redraw();await process_frame;await process_frame;await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(output+"/"+name+".png")
func run():
	output=OS.get_environment("FARM_REVIEW_OUTPUT")
	if output=="" or not "--isolated-review" in OS.get_cmdline_user_args():quit(2);return
	root.size=Vector2i(1280,800)
	game=load("res://game/main.tscn").instantiate();game.automated=true
	game.world=Farm.new({},31).begin_day();game.world.story.intro_seen=true;game.world.paused=true
	root.add_child(game);await process_frame;await process_frame;game.set_process(false);game.audio.set_process(false)
	game.reset_view();game.neutral();game.refresh()
	var w=game.world;var original_tick=w.tick;var original_pos=w.keeper.pos
	var at60=await camera_trial(60,false);var at120=await camera_trial(120,false);var diagonal=await camera_trial(60,true)
	record.camera={"half_second_60fps":at60,"half_second_120fps":at120,"half_second_diagonal":diagonal,"expected_distance":315}
	check("1_camera",absf(at60.length()-315)<0.01 and at60.distance_to(at120)<0.01,"630 pixels/second at both 60 and 120 FPS")
	check("1_camera",absf(diagonal.length()-at60.length())<0.01 and absf(diagonal.x-diagonal.y)<0.01,"Diagonal key motion has the same speed")
	check("1_camera",w.tick==original_tick and w.keeper.pos==original_pos,"Camera keys do not move the keeper or step the paused world")
	game.speed=1;w.paused=false;game.view_positions["keeper"]=Vector2(4,5);game.actor_tracks["keeper"]=[]
	game.record_actor("keeper",Vector2i(5,5));game.record_actor("keeper",Vector2i(5,6))
	game.smooth_actor("keeper",Vector2i(5,6),0.3);var before_turn=game.view_positions.keeper
	game.smooth_actor("keeper",Vector2i(5,6),0.2);var after_turn=game.view_positions.keeper
	game.smooth_actor("keeper",Vector2i(5,6),0.5);var arrived=game.view_positions.keeper
	record.path={"before_turn":before_turn,"after_turn":after_turn,"arrival":arrived}
	check("2_path",is_equal_approx(before_turn.y,5) and before_turn.x<5 and is_equal_approx(after_turn.x,5) and after_turn.y>5 and arrived==Vector2(5,6),"Existing human interpolation follows queued cardinal corners and reaches its destination")
	w.paused=true;w.debug_enabled=true;w.keeper.pos=Vector2i(5,5)
	for species in ["hen","cat","cow","bullfrog","maid"]:w.debug_action(species,{})
	for i in range(w.animals.size()):w.animals[i].pos=Vector2i(4+i*3,10);w.animals[i].placed=true
	w.spawn_enemy({"role":"kidnapper","entry":Vector2i(1,5),"lv":1});var enemy=w.enemies.back();enemy.pos=Vector2i(9,5);enemy.arrival_complete=true
	game.view_positions.clear();game.actor_tracks.clear();game.reset_view();game.recenter();game.refresh()
	var foot=game.keeper_pixel()+Vector2(0,14);var base=game.keeper_hit_rect_base();var enlarged=game.keeper_hit_rect()
	check("3_display",(HumanVisual.transform(foot)*foot).distance_to(foot)<0.001 and enlarged.size.is_equal_approx(base.size*1.25),"Human scaling keeps the foot anchor and enlarges selection coverage")
	var animal=w.animals[0];var animal_base=game.animal_hit_rect_base(animal)
	check("3_display",game.animal_hit_rect(animal).size.is_equal_approx(animal_base.size*1.25) and is_equal_approx(HumanVisual.SCALE/1.3,1.25),"Animal and delivered-human displays are 1.25 times the prior scale")
	check("3_display",Farm.W==25 and Farm.H==17 and w.Jobs.SPEED==2.5 and w.keeper.pos==Vector2i(5,5),"Logical map and movement speed stay at the existing values")
	record.fixture={"keeper":w.keeper.pos,"animals":w.animals.map(func(a):return {"species":a.species,"pos":a.pos}),"enemy":enemy.pos,"human_scale":HumanVisual.SCALE,"keeper_scale":1.15*game.ACTOR_SCALE,"animal_scale":game.ACTOR_SCALE}
	await capture("01_actor_scale_fixture")
	enemy.carry="keeper";w.keeper.carrier=enemy.id;w.keeper.restrainer=enemy.id;w.keeper.pos=enemy.pos;game.view_positions.clear();game.refresh()
	await capture("02_carried_keeper_fixture")
	FileAccess.open(output+"/colony-view.json",FileAccess.WRITE).store_string(JSON.stringify(record,"\t"))
	print("Colony view: 3 groups, ",failed," failures; isolated fixtures, not human play")
	quit(1 if failed else 0)
