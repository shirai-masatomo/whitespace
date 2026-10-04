extends SceneTree
const Farm=preload("res://game/world.gd")
var game
var output=""
var frames=[]
func _initialize():call_deferred("run")
func frame():
	game._process(1.0/30.0)
	await RenderingServer.frame_post_draw
func capture(name):
	await frame();await frame()
	root.get_texture().get_image().save_png(output+"/"+name+".png")
	frames.append({"file":name+".png","clock":game.clock,"phase":game.world.phase,"tick":game.world.tick,"jobs":game.world.jobs.duplicate(true)})
func segment(prefix,count):
	for i in range(count):
		await frame()
		if i%3==0:await capture(prefix+"_%03d"%i)
func button(p,pressed):
	var e=InputEventMouseButton.new();e.position=p;e.button_index=MOUSE_BUTTON_LEFT;e.pressed=pressed;Input.parse_input_event(e);await process_frame
func motion(p):
	var e=InputEventMouseMotion.new();e.position=p;Input.parse_input_event(e);await process_frame
func click(p):
	await motion(p);await button(p,true);await button(p,false)
func run():
	output=OS.get_environment("FARM_REVIEW_OUTPUT")
	if output=="" or not "--isolated-review" in OS.get_cmdline_user_args():quit(2);return
	root.size=Vector2i(1280,800)
	game=load("res://game/main.tscn").instantiate();game.automated=true;root.add_child(game);await process_frame
	game.set_process(false);game.automated=false;game.arrival_started=game.clock;game.refresh()
	await segment("arrival",66)
	await capture("waiting_cart")
	await click(game.buttons.advance.get_global_rect().get_center())
	await segment("departure",24)
	game.world.paused=true;game.world.natural.clear();game.select_group(0);game.select_tool("wall",false)
	for p in [Vector2i(8,4),Vector2i(16,4),Vector2i(8,6)]:await click(game.screen_cell(p))
	game.choose_walk();game.refresh();await capture("queue_before")
	await motion(Vector2(1100,179));await button(Vector2(1100,179),true)
	for i in range(10):
		await motion(Vector2(1100,179-i*8));await capture("queue_drag_%02d"%i)
	await button(Vector2(1100,107),false);await capture("queue_after")
	game.select_group(1);await click(game.screen_cell(game.world.animals[0].pos))
	await motion(game.buttons.rest.get_global_rect().get_center());await button(game.buttons.rest.get_global_rect().get_center(),true)
	for i in range(10):
		await motion(Vector2(578-i*48,726));await capture("operation_drag_%02d"%i)
	await button(Vector2(90,726),false);await capture("operation_after")
	FileAccess.open(output+"/observations.json",FileAccess.WRITE).store_string(JSON.stringify({"implementation_commit":OS.get_environment("FARM_REVIEW_COMMIT"),"frames":frames,"method":"isolated viewport; game-local mouse events; controlled 1/30 second process steps"},"  "))
	quit()
