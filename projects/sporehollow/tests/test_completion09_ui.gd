extends SceneTree
const Farm=preload("res://game/world.gd")
var out=""
var checks=[]
var failures=0
func _initialize():call_deferred("run")
func check(ok,note):
	checks.append({"passed":bool(ok),"check":note})
	if not ok:failures+=1;push_error(note)
func mouse(point,down):
	var e=InputEventMouseButton.new();e.position=point;e.button_index=MOUSE_BUTTON_LEFT;e.pressed=down;Input.parse_input_event(e);await process_frame
func click(point):
	var e=InputEventMouseMotion.new();e.position=point;Input.parse_input_event(e);await process_frame;await mouse(point,true);await mouse(point,false)
func capture(g,name):
	g.queue_redraw();g.hud.queue_redraw();await process_frame;await RenderingServer.frame_post_draw;root.get_texture().get_image().save_png(out+"/"+name+".png")
func run():
	out=OS.get_environment("FARM_REVIEW_OUTPUT")
	if out=="" or "--isolated-review" not in OS.get_cmdline_user_args() or DisplayServer.get_name()=="headless":quit(2);return
	root.size=Vector2i(1280,800)
	var w=Farm.new({},31).begin_day();w.story.intro_seen=true;w.paused=true;w.trees.clear();w.natural.clear();w.keeper.pos=Vector2i(10,10);w.keeper.satiety=100
	w.rocks={Vector2i(12,10):{"amount":8,"forbidden":false}};w.Tasks.save(w);w.Stock.add(w,"wood_staff",1,Vector2i(11,9))
	var dog=w.animals[0];dog.pos=Vector2i(12,12);dog.mode="stay";dog.order_until=99999
	var g=load("res://game/main.tscn").instantiate();g.automated=true;g.world=w;root.add_child(g);await process_frame;await process_frame;g.set_process(false);g.audio.set_process(false);g.reset_view();g.neutral();g.camera.position=g.center(Vector2i(13,11));g.camera.force_update_scroll()
	await click(g.get_canvas_transform()*g.center(Vector2i(12,10)))
	check(g.buttons.has("mine"),"A visible rock can be selected by actual scene input")
	await click(g.buttons.mine.get_global_rect().get_center());check(not w.Tasks.job(w,"mine",Vector2i(12,10)).is_empty(),"UI mining designation creates the real job")
	await capture(g,"mining-morning")
	await click(g.buttons.mine.get_global_rect().get_center());check(w.Tasks.job(w,"mine",Vector2i(12,10)).is_empty(),"Mining UI cancel removes the job")
	await click(g.buttons.group1.get_global_rect().get_center());await click(g.palette.find_child("Animal_1",true,false).get_global_rect().get_center())
	check(g.buttons.has("train"),"Selecting an eligible dog shows training rather than invalid slaughter controls")
	await click(g.buttons.train.get_global_rect().get_center());check(not w.Tasks.job(w,"train",Vector2i.ZERO,1).is_empty(),"Training button designates only selected dog")
	w.calendar_ticks=400;await capture(g,"training-day")
	g.choose_walk();g.refresh();await process_frame
	check(g.buttons.has("keeper_equip") and not g.buttons.keeper_equip.disabled,"Keeper selection shows physical staff equipment action")
	await click(g.buttons.keeper_equip.get_global_rect().get_center());check(w.jobs.any(func(j):return j.kind=="keeper_equipment"),"Equipment button queues actual item pickup")
	for j in w.jobs.duplicate():w.Jobs.cancel(w,j.id)
	w.keeper.equipment={"item_id":"wood_staff","durability":-1};w.calendar_ticks=1100;g.refresh();await process_frame
	await click(g.buttons.keeper_draft.get_global_rect().get_center())
	w.spawn_enemy({"entry":Vector2i(1,5),"role":"kidnapper","archetype":"kidnapper"});var e=w.enemies.back();e.pos=Vector2i(14,10);g.reset_view();g.choose_walk();g.refresh();await process_frame
	await click(g.get_canvas_transform()*g.enemy_hit_rect(e).get_center())
	check(w.jobs.any(func(j):return j.kind=="direct_attack" and j.enemy_id==e.id),"Drafted keeper enemy click produces direct target attack instead of inspection")
	var previous_job=w.jobs.filter(func(j):return j.kind=="direct_attack")[0].id
	e.pos=Farm.MERCHANT_CELL;w.tick=20;g.reset_view();g.choose_walk();g.refresh();await process_frame
	await click(g.get_canvas_transform()*g.enemy_hit_rect(e).get_center())
	check(not g.merchant_requested and w.jobs.any(func(j):return j.kind=="direct_attack" and j.enemy_id==e.id and j.id>previous_job),"Drafted target click wins when an enemy overlaps the merchant interaction area")
	e.pos=Vector2i(14,10);g.reset_view();g.choose_walk();g.refresh();await process_frame
	await capture(g,"equipment-night")
	FileAccess.open(out+"/completion-ui.json",FileAccess.WRITE).store_string(JSON.stringify({"method":"Godot InputEvent clicks in private GPU desktop; controlled paused scene, not human play","checks":checks,"failures":failures},"	"))
	print("CompletionUI: ",failures," failures");g.queue_free();await process_frame;quit(1 if failures else 0)
