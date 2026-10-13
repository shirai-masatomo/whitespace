extends SceneTree
const Farm=preload("res://game/world.gd")
var checks=[]
func _initialize():call_deferred("run")
func check(ok,note):
	checks.append({"passed":bool(ok),"check":note})
	if not ok:push_error(note)
func run():
	var out=OS.get_environment("FARM_REVIEW_OUTPUT")
	if out=="":quit(2);return
	var w=Farm.new({},31).begin_day();w.trees.clear();w.rocks.clear();w.mountains.clear();w.Mountains.reindex(w);w.natural.clear();w.field_items.clear();w.jobs.clear();w.zones.clear();w.Zones.sync_storage(w);w.keeper.pos=Vector2i(95,63);w.nature_config.spawn_chance_per_second=0
	for key in w.keeper.work_priorities:w.keeper.work_priorities[key]=1 if key in ["haul","build"] else 0
	var z=w.Zones.create(w,"stockpile",Vector2i(94,64),Vector2i(94,64));w.Stock.add(w,"wood",30,Vector2i(94,64))
	check(w.act("wood_wall",Vector2i(97,64)) and w.act("wood_wall",Vector2i(98,64)) and w.act("door",Vector2i(98,65)),"Plans accepted outside former 50x34 extent")
	for i in range(240):
		w.step()
		if w.metrics.built==3:break
	check(w.metrics.built==3 and w.Stock.totals(w).get("wood",0)==0 and w.stock_used.get("wood",0)==30,"Real hauling and assembly complete three structures at far corner")
	check(not w.walkable(Vector2i(98,64)) and w.find_path(w.keeper.pos,Vector2i(99,67)).size()>0,"New outer corner routes around completed walls")
	w.spawn_enemy({"role":"destroyer","entry":w.entries[0],"debug_single":true});var e=w.enemies.back();e.pos=Vector2i(99,64);e.object_attack_power=999
	w.move_enemy(e,Vector2i(98,64))
	check(w.structures[Vector2i(98,64)].status=="destroyed" and w.walkable(Vector2i(98,64)),"Actual enemy attack destroys wall and frees its logical cell")
	check(w.Zones.resize(w,z,Vector2i(93,64),Vector2i(94,65)) and w.storage_cells.size()==4,"Storage resize changes actual destination cells")
	check(w.Zones.remove(w,z) and w.storage_cells.is_empty(),"Zone removal removes destinations only")
	var exit=w.exit_for(Vector2i(99,34));check(exit==Vector2i(100,34) and not w.find_path(Vector2i(99,34),exit,false,false,false,{},true).is_empty(),"Retreat path permits exactly the adjacent new outer exit")
	FileAccess.open(out+"/map-actions.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks},"  "));quit(0 if checks.all(func(c):return c.passed) else 1)
