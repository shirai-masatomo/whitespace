extends SceneTree
const Farm=preload("res://game/world.gd")
var game
var out=""
var prefix="after"
var shots=[]
var stages=[]
func mark(stage: String):
	stages.append({"stage":stage,"milliseconds":Time.get_ticks_msec()})
	var file=FileAccess.open(OS.get_environment("FARM_REVIEW_OUTPUT")+"/"+OS.get_environment("FARM_REVIEW_CASE")+"-stages.json",FileAccess.WRITE)
	if file!=null:file.store_string(JSON.stringify(stages,"\t"));file.flush();file.close()
func _initialize():mark("initialize");call_deferred("run")
func capture(name: String):
	mark("refresh:"+name)
	game.refresh();game.refresh_jobs();game.queue_redraw();game.hud.queue_redraw()
	mark("frames:"+name)
	await process_frame;await process_frame
	mark("render_wait:"+name)
	await RenderingServer.frame_post_draw
	mark("read_image:"+name)
	var image=root.get_texture().get_image();var file=prefix+"_"+name+".png";var error=image.save_png(out+"/"+file)
	if error!=OK:push_error("PNG save failed: "+str(error));quit(3);return
	mark("saved:"+name)
	shots.append({"file":file,"width":image.get_width(),"height":image.get_height(),"seed":game.world.seed_value,"tick":game.world.tick,"group":game.group,"tool":game.tool,"materials":game.world.Stock.totals(game.world)})
func run():
	mark("run")
	out=OS.get_environment("FARM_REVIEW_OUTPUT")
	if out=="" or "--isolated-review" not in OS.get_cmdline_user_args():quit(2);return
	if "--baseline" in OS.get_cmdline_user_args():prefix="before"
	root.size=Vector2i(1280,800);root.content_scale_size=Vector2i(1280,800)
	mark("load_main")
	game=load("res://game/main.tscn").instantiate();game.automated=true;game.world=Farm.new({},31).begin_day();game.world.story.intro_seen=true;game.world.paused=true;root.add_child(game)
	mark("main_added")
	await process_frame;await process_frame;game.set_process(false);game.audio.set_process(false);game.reset_view();game.neutral()
	await capture("01_initial_stock")
	var w=game.world;var helper=w.keeper.duplicate(true);helper.name="検証用作業者";helper.pos=w.keeper.pos+Vector2i.LEFT+Vector2i.UP;w.Work.register(w,"helper",helper)
	game.colony_page="roles";game.refresh();await capture("02_roles")
	game.neutral();game.select_group(0);game.architect_category="壁と扉";await capture("03_architect")
	game.neutral();game.group=4;game.item_commands.select(game,"haul");await capture("04_commands")
	var c=Farm.new_campaign();c.animals.append({"id":2,"name":"こっこ","species":"hen","category":"bird","lv":1,"xp":0,"loyalty":0,"position":[21,21]});c.animals.append({"id":3,"name":"みけ","species":"cat","category":"cat","lv":1,"xp":0,"loyalty":0,"position":[24,21]})
	game.world=Farm.new(c,31).begin_day();game.world.story.intro_seen=true;game.world.paused=true;game.neutral();game.select_group(1);await capture("05_animals")
	game.neutral()
	var rw=game.world;var rp=rw.rocks.keys()[0]
	game.camera.zoom=Vector2.ONE*1.6;game.camera.position=game.center(rp);game.clamp_camera()
	await capture("06_natural_rocks")
	var rock=rw.rocks[rp].duplicate(true);rw.rocks.clear();rw.trees.clear();rw.natural.clear()
	var base=Vector2i(18,12)
	for offset in [Vector2i(0,0),Vector2i(1,0),Vector2i(2,0),Vector2i(0,1),Vector2i(1,1),Vector2i(1,2)]:rw.rocks[base+offset]=rock.duplicate(true)
	if prefix=="after":rw.mined_rock_cells=[base+Vector2i(2,2)]
	game.camera.position=game.center(base+Vector2i(1,1));game.clamp_camera()
	await capture("07_connected_rock_fixture")
	root.size=Vector2i(1920,1080);game.reset_view();game.neutral();game.select_group(0);game.architect_category="壁と扉";await capture("08_architect_1080")
	FileAccess.open(out+"/"+prefix+"-visual.json",FileAccess.WRITE).store_string(JSON.stringify({"method":"Actual game viewport on noninteractive GPU desktop, frozen seed31; helper, hen/cat and connected rocks/mined scar are explicitly controlled review fixtures; natural rocks retain the unchanged seed distribution","implementation":OS.get_environment("FARM_REVIEW_COMMIT"),"side":prefix,"shots":shots},"\t"))
	mark("complete");game.queue_free();await process_frame;quit(0)
