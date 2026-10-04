extends SceneTree
const Farm=preload("res://game/world.gd")
var game
var output=""
var observations={"captures":{},"motion":[],"checks":[],"failures":0}

func _initialize(): call_deferred("run")
func check(ok: bool, label: String):
	observations.checks.append({"check":label,"passed":ok})
	if not ok: observations.failures+=1; push_error(label)
func mouse(p: Vector2,button: int=MOUSE_BUTTON_LEFT):
	var motion=InputEventMouseMotion.new();motion.position=p;Input.parse_input_event(motion)
	await process_frame
	for pressed in [true,false]:
		var event=InputEventMouseButton.new();event.position=p;event.button_index=button;event.pressed=pressed
		Input.parse_input_event(event);await process_frame
func floor_at(p: Vector2i):
	game.world.floors[p]={"id":game.world.next_structure_id,"kind":"wood_tile","status":"ready","hp":16,"max_hp":16,"cost":2,"resource":"wood","open":false}
	game.world.next_structure_id+=1
func reset_case():
	game.world=Farm.new({},17).begin_day();game.world.natural.clear()
	game.world.keeper.pos=Vector2i(10,8);game.world.keeper.sleepiness=35
	game.world.animals[0].pos=Vector2i(12,8);game.world.animals[0].mode="stay";game.world.animals[0].order_until=9999
	game.world.animals[0].order=Vector2i(12,8);game.world.animals[0].home=Vector2i(12,8)
	for y in range(7,11):
		for x in range(8,15):floor_at(Vector2i(x,y))
	game.reset_view();game.refresh();game.world.paused=true;game.speed=1
	game.camera.position=Vector2(12,8.5)*game.TILE;game.camera.zoom=Vector2.ONE*1.5
	game._process(0);await process_frame
func frame():
	game._process(1.0/30.0)
	await RenderingServer.frame_post_draw
func capture(name: String):
	game.refresh()
	await frame()
	check(root.get_texture().get_image().save_png(output+"/"+name+".png")==OK,"save "+name)
	observations.captures[name]={"tick":game.world.tick,"speed":game.speed,"paused":game.world.paused,"keeper_pos":[game.world.keeper.pos.x,game.world.keeper.pos.y],"keeper_facing":game.world.keeper.get("facing",1),"dog_facing":game.world.animals[0].get("facing",1),"rest":game.world.Life.presentation(game.world),"zoom":game.camera.zoom.x,"selection":str(game.selected)}
func segment(prefix: String, count: int):
	for i in range(count):
		await frame()
		if i%3==0:
			root.get_texture().get_image().save_png(output+"/"+prefix+"_%03d.png"%i)
			observations.motion.append({"file":prefix+"_%03d.png"%i,"tick":game.world.tick,"speed":game.speed,"keeper_facing":game.world.keeper.get("facing",1),"keeper_visual":str(game.view_positions.get("keeper")),"dog_facing":game.world.animals[0].get("facing",1)})
func run():
	output=OS.get_environment("FARM_REVIEW_OUTPUT")
	if not "--isolated-review" in OS.get_cmdline_user_args() or output=="":quit(2);return
	observations.implementation_commit=OS.get_environment("FARM_REVIEW_COMMIT")
	observations.dirty=OS.get_environment("FARM_REVIEW_DIRTY")
	observations.asset_delivery_commit="f3e4ae82b68c342b928dfb5dfcebb451353f9b8d"
	observations.method="GPU rendering on private noninteractive Windows station; game-local InputEvent injection, no OS input"
	observations.renderer=RenderingServer.get_video_adapter_name()
	root.size=Vector2i(1280,800)
	game=load("res://game/main.tscn").instantiate();game.automated=true
	root.add_child(game);await process_frame;game.set_process(false);game.automated=false
	await reset_case()
	game.camera.zoom=Vector2.ONE
	await capture("native_scale")
	game.camera.zoom=Vector2.ONE*1.5
	await capture("characters")
	await mouse(game.get_canvas_transform()*(game.keeper_pixel()+Vector2(0,-10)))
	check(game.selected.get("kind")=="keeper","Keeper sprite click selects keeper")
	await capture("keeper_selected")
	await mouse(game.screen_cell(Vector2i(11,8)))
	check(game.world.manual_goal==Vector2i(11,8) and game.world.tick==0,"Paused floor movement plans without execution")
	await capture("floor_move")
	await mouse(game.screen_cell(Vector2i(8,7)),MOUSE_BUTTON_RIGHT)
	check(game.selected.is_empty() and game.world.manual_goal!=null,"Deselect preserves movement")
	await mouse(game.screen_cell(Vector2i(8,7)))
	check(game.selected.get("kind")=="floor","Neutral floor click selects floor")
	await capture("floor_selected")
	for rate in [0.5,1.0,2.0]:
		await reset_case();game.world.paused=false;game.speed=rate
		game.choose_walk();await mouse(game.screen_cell(Vector2i(11,8)))
		await segment("move_%s_right"%str(rate).replace(".","p"),66)
		check(game.world.manual_goal==null and game.world.keeper.get("facing")==1,"Right arrival at speed "+str(rate))
		await mouse(game.screen_cell(Vector2i(10,8)))
		await segment("move_%s_left"%str(rate).replace(".","p"),66)
		check(game.world.manual_goal==null and game.world.keeper.get("facing")==-1,"Left stop keeps facing at speed "+str(rate))
		if rate==1:await capture("left_stop")
	await reset_case()
	game.choose_animal(1);game.select_tool("guide",false)
	await mouse(game.screen_cell(Vector2i(13,9)))
	check(game.world.jobs.size()==1 and game.world.jobs[0].command_pos==Vector2i(13,9),"Paused floor guidance accepted")
	await capture("floor_guide")
	game.world.paused=false;game.speed=2
	await segment("guide",120)
	check(game.world.jobs.is_empty() and game.world.animals[0].pos==Vector2i(13,9),"Dog physically arrives on target floor")
	game.choose_animal(1);game.select_tool("guide",false)
	await mouse(game.screen_cell(Vector2i(11,9)))
	await segment("guide_left",120)
	check(game.world.jobs.is_empty() and game.world.animals[0].get("facing")==-1,"Dog left guidance and facing on stop")
	game.world.paused=true;game.reactions.clear();await capture("dog_left_stop")
	await reset_case();game.choose_walk();game.world.paused=false;game.keeper_action("keeper_rest")
	await capture("settling")
	for i in range(165): await frame()
	check(game.world.Life.presentation(game.world)=="sleeping","Rest reaches sleep")
	game.world.paused=true;await capture("sleeping")
	game.world.paused=false;game.keeper_action("keeper_rest");await frame()
	check(not game.world.keeper.resting,"Wake clears sleep state")
	game.world.paused=true;await capture("awake")
	check(game.material==null and game.hud.material==null,"No legacy white key material")
	FileAccess.open(output+"/observations.json",FileAccess.WRITE).store_string(JSON.stringify(observations,"  "))
	print("ISOLATED CHARACTER REVIEW: ",observations.checks.size()," checks failures=",observations.failures)
	quit(1 if observations.failures else 0)
