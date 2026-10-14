extends SceneTree
const Farm=preload("res://game/world.gd")
var checks=[]
func _initialize():call_deferred("run")
func check(ok,note):
	checks.append({"passed":bool(ok),"check":note})
	if not ok:push_error(note)
func run():
	var out=OS.get_environment("FARM_REVIEW_OUTPUT")
	if DisplayServer.get_name()!="headless" or out=="":quit(2);return
	root.size=Vector2i(1280,800);root.content_scale_size=Vector2i(1280,800)
	var g=load("res://game/main.tscn").instantiate();g.automated=true;g.world=Farm.new({},31).begin_day();g.world.paused=true;g.world.story.intro_seen=true;root.add_child(g)
	await process_frame;g.set_process(false);g.audio.set_process(false);g.neutral();g.select_group(0);g.architect_category="壁と扉";g.select_tool("wall",false);g.refresh()
	var jobs=g.world.jobs.size()
	for id in ["wall","wood_wall","stone_wall"]:
		g.select_tool(id,false);g.refresh();await process_frame
		var button=g.buttons[id];var selected=button.get_theme_stylebox("normal").modulate_color
		var motion=InputEventMouseMotion.new();motion.position=button.get_global_rect().get_center();root.push_input(motion,true);await process_frame
		check(button.get_draw_mode()==BaseButton.DRAW_HOVER,"Actual Control uses hovered draw mode: "+id)
		check(selected==button.get_theme_stylebox("hover").modulate_color and selected.g>selected.r,"Selected button remains green while hovered: "+id)
		var other="wood_wall" if id=="wall" else "wall"
		check(g.buttons[other].get_theme_stylebox("hover").modulate_color!=selected,"Unselected hover is distinct: "+id)
		check(g.world.jobs.size()==jobs,"Selection and hover do not reserve construction: "+id)
		check(Farm.BUILD[id].cost==5,"Current wall cost is five: "+id)
		g.refresh();check(g.buttons[id].get_theme_stylebox("hover").modulate_color==selected,"Refresh keeps selection: "+id)
	var failed=checks.filter(func(c):return not c.passed).size()
	FileAccess.open(out+"/architect-selected.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failed,"method":"Headless main Control tree with Viewport.push_input; no OS input, no native window, no GPU"},"\t"))
	g.queue_free();await process_frame;print("ARCHITECT_SELECTED: ",checks.size()," failures=",failed);quit(1 if failed else 0)
