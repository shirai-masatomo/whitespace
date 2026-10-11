extends SceneTree
const Farm=preload("res://game/world.gd")
var checks=[]
var failed=0
func _initialize():call_deferred("run")
func check(ok,note):
	checks.append({"passed":bool(ok),"check":note})
	if not ok:failed+=1;push_error(note)
func run():
	var out=OS.get_environment("FARM_REVIEW_OUTPUT")
	if out=="" or "--isolated-review" not in OS.get_cmdline_user_args():quit(2);return
	var w=Farm.new({},31).begin_day();w.story.intro_seen=true;w.nature_config.spawn_chance_per_second=0
	check(w.field_items.all(func(row):return row.location=="ground" and w.distance(row.pos,w.keeper.pos)<=1 and w.walkable(row.pos)),"New initial materials are reachable physical ground objects beside the central keeper")
	var before=w.field_items.duplicate(true);var total=w.Stock.totals(w);var zone=w.Zones.create(w,"stockpile",Vector2i(28,20),Vector2i(30,20));w.Zones.set_allowed(w,zone,["soil","wood","food"])
	for i in range(8):w.step()
	check(w.field_items==before and w.Stock.totals(w)==total and not w.jobs.any(func(j):return j.kind=="haul"),"Creating and configuring storage does not move, claim, duplicate or automatically haul goods")
	w.Snapshot.save(w,out+"/zone.snapshot");w=w.Snapshot.restore(out+"/zone.snapshot");w.Zones.resize(w,zone,Vector2i(27,20),Vector2i(30,20));w.step()
	check(w.field_items==before and w.Stock.totals(w)==total and w.jobs.is_empty(),"Load and zone resize preserve existing positions and ownership without creating work")
	w.field_items.clear();w.Stock.sync(w);var source=w.keeper.pos+Vector2i.DOWN;w.Stock.add(w,"wood",8,source);w.Stock.add(w,"mushroom",2,source+Vector2i.LEFT)
	var result=w.Stock.designate(w,"haul",source,source)
	check(result.accepted==1 and w.Stock.designate(w,"haul",source,source).accepted==0,"Explicit single collection reserves one real job and duplicate request creates none")
	for i in range(20):
		w.step()
		if not w.Stock.cargo(w,"keeper").is_empty():break
	check(not w.Stock.cargo(w,"keeper").is_empty() and w.Stock.totals(w).wood==8,"Worker physically picks up the specified wood before delivery")
	w.Snapshot.save(w,out+"/carried.snapshot");w=w.Snapshot.restore(out+"/carried.snapshot")
	for i in range(150):
		w.step()
		if w.jobs.is_empty():break
	check(w.jobs.is_empty() and w.Stock.totals(w).wood==8 and w.field_items.any(func(row):return row.kind=="wood" and row.location=="ground" and w.Zones.accepts(w,row.pos,row.kind)),"Saved carrying resumes and drops exactly the original quantity at storage")
	check(w.field_items.any(func(row):return row.kind=="mushroom" and row.pos==source+Vector2i.LEFT),"Unselected goods remain at their original position")
	check(w.Stock.designate(w,"haul",source+Vector2i.LEFT,source).accepted==1,"Explicit rectangle collection uses the same real haul path")
	for j in w.jobs.duplicate():w.Jobs.cancel(w,j.id)
	w.keeper.pos=source;w.keeper.satiety=20
	for i in range(20):w.step()
	check(w.stock_used.get("mushroom",0)==1 and w.keeper.satiety>30,"Eating still fetches required ground food without a hauling designation")
	w.Stock.add(w,"wood",10,w.keeper.pos+Vector2i.RIGHT)
	check(w.act("wood_wall",Vector2i(25,21)),"Construction can still be explicitly designated")
	for i in range(200):
		w.step()
		if w.structures.get(Vector2i(25,21),{}).get("status")=="ready":break
	check(w.structures.get(Vector2i(25,21),{}).get("status")=="ready","Construction directly fetches needed physical materials without automatic storage hauling")
	FileAccess.open(out+"/explicit-storage.json",FileAccess.WRITE).store_string(JSON.stringify({"method":"One production World.step group; controlled food/build fixtures and carried-state snapshot","checks":checks,"failures":failed},"	"))
	print("ExplicitStorage: ",failed," failures");quit(1 if failed else 0)
