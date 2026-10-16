extends "res://tests/test_housing_sleep.gd"
class GhostSpy:
	extends "res://game/building_ghost.gd"
	var draws=[]
	func draw(_g,kind:String,cell:Vector2i,valid:bool=true,waiting_material:bool=false):
		draws.append({"kind":kind,"pos":cell,"valid":valid,"waiting":waiting_material})
class PreviewScene:
	extends "res://game/main.gd"
	var labels=[]
	func _ready():pass
	func pointer_over_ui() -> bool:return false
	func label_on(_target:CanvasItem,_p:Vector2,text_value:String,_size:int=17,_color:Color=Color("f3ead1")):
		labels.append(text_value)
var scene
func hover(kind:String,q:Vector2i):
	scene.tool=kind;scene.pointer=scene.get_canvas_transform()*scene.center(q)
	scene.labels.clear();scene.building_ghost.draws.clear();scene.draw_pointer_preview()
func run():
	scene=PreviewScene.new();root.add_child(scene);scene.set_process(false);scene.set_physics_process(false)
	scene.building_ghost=GhostSpy.new();w=fixture();scene.world=w
	var q=Vector2i(35,25)
	for kind in ["wall","wood_wall","stone_wall","soil_tile","wood_tile","stone_tile","door","locked_door","cooking_bench","carpentry_bench","sewing_bench","bed"]:
		w=fixture();scene.world=w
		check(w.act(kind,q),"Designation accepted: "+kind)
		for cell in w.Buildings.cells(kind,q):
			hover(kind,cell)
			check(scene.building_ghost.draws.is_empty() and scene.labels.is_empty(),"No duplicate hover ghost/text: "+kind+str(cell))
		check(not w.act(kind,q) and w.jobs.size()==1,"Actual duplicate still rejected: "+kind)
		var view=preload("res://game/construction_view.gd").new();view.update(w)
		check(view.rows[w.jobs[0].id].waiting_material,"Committed material-wait display retained: "+kind)
		var rebuilds=scene.planned_ghost.rebuilds;hover(kind,q);hover(kind,q)
		check(scene.planned_ghost.rebuilds==rebuilds,"Repeated hover reuses footprint cache: "+kind)
		w.Jobs.cancel(w,w.jobs[0].id);hover(kind,q)
		check(scene.building_ghost.draws.size()==1 and scene.building_ghost.draws[0].waiting,"Cancel restores reservable shortage preview: "+kind)
	w=fixture();scene.world=w;w.act("wood_wall",q)
	scene.wall_stroke.begin("wood_wall",q);hover("wood_wall",q)
	check(scene.building_ghost.draws.is_empty() and scene.labels.is_empty(),"All-reserved drag has no overlay")
	scene.wall_stroke.add(q+Vector2i.RIGHT);hover("wood_wall",q+Vector2i.RIGHT)
	check(scene.building_ghost.draws.size()==1 and scene.building_ghost.draws[0].pos==q+Vector2i.RIGHT and scene.building_ghost.draws[0].waiting,"Mixed drag retains empty-cell shortage ghost only")
	check(scene.labels.all(func(t):return not "予約済み" in t),"Mixed drag does not leak reserved hover reason")
	var result=scene.wall_stroke.commit(w)
	check(result.accepted==1 and result.skipped==1 and w.jobs.size()==2,"Mixed commit rejects duplicate and accepts unfunded new cell")
	var empty=q+Vector2i(4,0);hover("wood_wall",empty)
	check(scene.building_ghost.draws.size()==1 and scene.building_ghost.draws[0].valid and scene.building_ghost.draws[0].waiting,"Empty cell retains shortage preview")
	w.trees[empty]="test";hover("wood_wall",empty)
	check(scene.building_ghost.draws.size()==1 and not scene.building_ghost.draws[0].valid and not scene.labels.is_empty(),"Other obstruction retains invalid ghost and reason")
	w.trees.erase(empty);w.Zones.create(w,"stockpile",Vector2i(25,23),Vector2i(26,23));w.Stock.add(w,"wood",40,Vector2i(25,23));hover("wood_wall",empty)
	check(scene.building_ghost.draws.size()==1 and scene.building_ghost.draws[0].valid and not scene.building_ghost.draws[0].waiting,"Funded empty cell retains normal ghost")
	# A non-building designation must not hide normal obstruction feedback.
	w.jobs.clear();w.trees[empty]="test";w.jobs.append({"id":900,"kind":"chop","pos":empty});hover("wood_wall",empty)
	check(scene.building_ghost.draws.size()==1 and not scene.building_ghost.draws[0].valid,"Non-building job does not suppress invalid preview")
	w.jobs.clear();w.jobs.append({"id":901,"kind":"place_wood_crate","pos":q});hover("place_wood_crate",q)
	check(scene.building_ghost.draws.is_empty() and scene.labels.is_empty(),"Furniture reservation suppresses duplicate placement preview")
	hover("wood_wall",q)
	check(scene.building_ghost.draws.is_empty() and scene.labels.is_empty(),"Existing furniture reservation suppresses other new building overlays")
	w.jobs.clear();w.jobs.append({"id":902,"kind":"cooking_bench","pos":q});hover("wood_wall",q+Vector2i.ONE)
	check(scene.building_ghost.draws.is_empty() and scene.labels.is_empty(),"Different tool also respects full bench footprint")
	scene.free()
	var failed=checks.filter(func(c):return not c.passed).size()
	var f=FileAccess.open(OS.get_environment("FARM_REVIEW_OUTPUT")+"/reserved-preview.json",FileAccess.WRITE)
	f.store_string(JSON.stringify({"checks":checks,"count":checks.size(),"failed":failed},"  "));f.close()
	print("Reserved preview: %d checks, %d failures"%[checks.size(),failed]);quit(1 if failed else 0)
