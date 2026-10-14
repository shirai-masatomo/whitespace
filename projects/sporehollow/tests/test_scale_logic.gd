extends SceneTree
const Farm=preload("res://game/world.gd")
const Stroke=preload("res://game/wall_stroke.gd")
const Main=preload("res://game/main.gd")
const Metrics=preload("res://game/terrain_metrics.gd")
var rows=[]
func _initialize():call_deferred("run")
func fixture(n: int):
	var w=Farm.new({},731).begin_day()
	w.trees.clear();w.rocks.clear();w.mountains.clear();w.mountain_cells.clear();w.natural.clear();w.field_items.clear();w.structures.clear();w.floors.clear();w.enemies.clear();w.foods.clear();w.jobs.clear();w.work_claims.clear()
	w.keeper.pos=Vector2i(40,25);w.keeper.satiety=100;w.keeper.resting=false;w.jobs_held=false;w.job_hold_reason=""
	w.animals[0].pos=Vector2i(5,5)
	w.debug_enabled=true;w.debug_infinite=true;w.refresh_indoor()
	for i in range(1,n):
		var a=w.keeper.duplicate(true);a.pos=Vector2i(40+i,25);w.Work.register(w,"helper%d"%i,a)
	return w
func begin_measure():Metrics.enabled=true;Metrics.take();return Time.get_ticks_usec()
func record(label: String,n: int,h: int,start: int,repeat: int=1):
	rows.append({"stage":label,"jobs_or_cells":n,"humans":h,"repeat":repeat,"ms":(Time.get_ticks_usec()-start)/1000.0,"counts":Metrics.take()});Metrics.enabled=false
func run():
	var out=OS.get_environment("FARM_REVIEW_OUTPUT")
	if DisplayServer.get_name()!="headless" or out=="":quit(2);return
	for n in [10,50,100]:
		var w=fixture(1);var stroke=Stroke.new();stroke.kind="wall"
		for i in range(n):stroke.add(Vector2i(30+i%10,30+i/10))
		# Add() creates cardinal connections: use exactly the requested row-major cells.
		stroke.cells=[];stroke.seen={}
		for i in range(n):var p=Vector2i(30+i%10,30+i/10);stroke.cells.append(p);stroke.seen[p]=true
		var t=begin_measure();stroke.plan(w);record("preview_cold",n,1,t)
		t=begin_measure();for i in range(3):stroke.plan(w)
		record("preview_unchanged",n,1,t,3)
		t=begin_measure();var result=stroke.commit(w);record("commit",n,1,t)
		if result.accepted!=n:push_error("Fixture reservation mismatch");quit(1);return
		var g=Main.new();g.world=w;g.drag_start=Vector2.ZERO
		for i in range(1000):w.trees[Vector2i(i%100,i/100)]={}
		t=begin_measure();for i in range(10):g.selection_candidates()
		record("selection_candidates_1000_trees",n,1,t,10)
		t=begin_measure();for i in range(10):g.prepare_work_plan_data(false)
		record("hidden_route_data",n,1,t,10);g.free()
		for humans in [1,5,10]:
			w=fixture(humans)
			for i in range(n):w.act("wall",Vector2i(30+i%10,30+i/10))
			t=begin_measure()
			for key in w.workers:w.Work.choose(w,key)
			record("choose",n,humans,t)
			# Same-condition repeated route requests; no GPU, no World.step loop.
			t=begin_measure()
			for key in w.workers:
				for i in range(n):w.Jobs.path_to(w,w.workers[key].pos,w.neighbors(Vector2i(30+i%10,30+i/10)))
			record("path_requests",n,humans,t)
	FileAccess.open(out+"/scale-logic.json",FileAccess.WRITE).store_string(JSON.stringify({"map":[100,68],"seed":731,"rows":rows,"method":"Headless Dummy; synthetic clear terrain; production methods; no GPU or EXE update"},"\t"))
	print("Scale logic: ",rows.size()," samples");quit()
