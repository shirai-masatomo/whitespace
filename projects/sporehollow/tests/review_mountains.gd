extends SceneTree
const Farm=preload("res://game/world.gd")
const Fixture=preload("res://tests/test_mountains.gd")
var game
var out=""
var screens=[]
var checks=[]
var frames=0
func _initialize():call_deferred("run")
func check(ok,note):
	checks.append({"passed":ok,"check":note})
	if not ok:push_error(note)
func render():
	game.queue_redraw();game.hud.queue_redraw();await process_frame;await RenderingServer.frame_post_draw
func image(name,note=""):
	await render();check(root.get_texture().get_image().save_png(out+"/"+name+".png")==OK,"Save "+name)
	var w=game.world;screens.append({"file":name+".png","tick":w.tick,"note":note,"objects":w.mountains.values().map(func(r):return {"id":r.id,"stage":r.stage,"remaining":r.remaining,"cells":w.Mountains.footprint(r).size()})})
func advance():
	game.world.step();game.record_actor_tracks();game._process(Farm.DT);game.accumulated=0;game.audio.seconds+=Farm.DT
func click(cell):
	var e=InputEventMouseButton.new();e.button_index=MOUSE_BUTTON_LEFT;e.pressed=true;e.position=game.get_canvas_transform()*game.center(cell)
	game.pointer=e.position;game.board_click(e)
func run():
	out=OS.get_environment("FARM_REVIEW_OUTPUT")
	if out=="" or "--isolated-review" not in OS.get_cmdline_user_args():quit(2);return
	root.size=Vector2i(1280,800);root.content_scale_size=Vector2i(1280,800)
	game=load("res://game/main.tscn").instantiate();game.automated=true;root.add_child(game);await process_frame;game.set_process(false);game.audio.set_process(false)
	# Controlled initial map; all subsequent progress/drop/stage changes use World.step.
	var fixture=Fixture.new();var w=fixture.farm();fixture.free()
	var r=w.Mountains.add(w,"large",Vector2i(10,10));var small=w.Mountains.add(w,"small",Vector2i(16,13))
	game.world=w;game.reset_view();game.neutral();game.harvest_view.setup(w);game.refresh();game.camera.zoom=Vector2.ONE*1.6;game.camera.position=game.center(Vector2i(12,12))+Vector2(40,10);game.camera.force_update_scroll();await render()
	w.paused=true;click(Vector2i(13,13));check(game.selected.get("id")==r.id and w.jobs.is_empty(),"Paused ordinary click selects same object without issuing work")
	await image("01_large_stage1","4x4 and 1x1 with keeper and shiba; paused real selection")
	game.buttons.mine.pressed.emit();check(w.jobs.size()==1 and w.jobs[0].mountain_id==r.id,"Explicit mine button queues one job while paused")
	var initial=r.elapsed;advance();check(r.elapsed==initial,"Paused input does not advance work");w.paused=false
	var stage=0;var guard=0;var hit=false
	while r.remaining>0 and guard<260:
		advance();guard+=1
		if not hit and w.harvest_events.any(func(e):return e.event=="strike"):
			await image("02_mining_hit","Normal strike event, actual worker/contact, shared sound cue");hit=true
		if r.stage!=stage:
			stage=r.stage
			var labels=game.palette.find_children("*","Label",true,false).map(func(n):return n.text)
			check(labels.any(func(t):return t.contains("残り石材 %d / 64"%r.remaining)),"Selected information follows stage "+str(stage))
			await image("large_stage%d"%(stage+1) if stage<4 else "06_large_depleted","Ordinary mining transition; updated physical drops and collision")
		if guard%2==0:
			await render();check(root.get_texture().get_image().save_png(out+"/frame_mountains_%03d.png"%frames)==OK,"Save frame");frames+=1
	check(r.remaining==0 and w.Stock.totals(w).get("stone",0)==64,"Four normal batches complete large mountain")
	game.neutral();click(small.pos);check(game.selected.get("id")==small.id,"Small object selects normally");game.buttons.mine.pressed.emit();await image("07_small_before")
	guard=0
	while small.remaining>0 and guard<100:advance();guard+=1
	check(small.remaining==0,"Small mountain completes through ordinary work");await image("08_small_after")
	var generated=Farm.new({},31).begin_day();generated.story.intro_seen=true;game.world=generated;game.reset_view();game.neutral();game.refresh();game.camera.zoom=Vector2.ONE*0.48;game.camera.position=Vector2(1200,714);game.camera.force_update_scroll();game.hud.get_parent().hide();await image("09_generated_map","Seed31 actual new map, overview scale, HUD hidden")
	var big=generated.mountains.values().filter(func(a):return a.kind=="large")
	if not big.is_empty():game.camera.zoom=Vector2.ONE*1.3;game.camera.position=game.center(big[0].pos+Vector2i(2,2));game.camera.force_update_scroll();await image("10_generated_rocky","Naturally generated large mountain and connected walls")
	FileAccess.open(out+"/mountains-observations.json",FileAccess.WRITE).store_string(JSON.stringify({"source_commit":OS.get_environment("FARM_REVIEW_COMMIT"),"material_commit":"3229d2655e35e82d178577cdd8acbbe66e9be4f8","method":"Controlled initial objects; actual board click and UI button; ordinary World.step through complete mining; seed31 natural new map. Private GPU, no OS input.","screens":screens,"checks":checks,"frames":frames,"failures":checks.filter(func(c):return not c.passed).size()},"  "))
	game.queue_free();await process_frame;quit(0 if checks.all(func(c):return c.passed) else 4)
