extends SceneTree
const Farm=preload("res://game/world.gd")
const View=preload("res://game/rock_view.gd")
var checks=[]
var failures=0
func _initialize():call_deferred("run")
func check(ok: bool,note: String):
	checks.append({"passed":ok,"check":note})
	if not ok:failures+=1;push_error(note)
func farm():
	var w=Farm.new({},31).begin_day();w.story.intro_seen=true;w.trees.clear();w.natural.clear();w.rocks.clear();w.mined_rock_cells.clear();w.field_items.clear();w.jobs.clear();w.zones.clear();w.storage_cells.clear();w.Zones.sync_storage(w);w.Stock.sync(w);w.keeper.satiety=100;w.keeper.sleepiness=0;w.animals[0].pos=Vector2i(3,3);w.nature_config.spawn_chance_per_second=0;w.campaign.last_supply_day=99999
	return w
func fill(w):
	for y in range(3):
		for x in range(3):w.rocks[Vector2i(14+x,10+y)]={"amount":8,"forbidden":false}
func finish(w,p):
	for i in range(140):
		w.step()
		if not w.rocks.has(p):return
func masks(w):
	var result={}
	for p in w.rocks:result[p]=View.mask(w,p)
	return result
func run():
	var out=OS.get_environment("FARM_REVIEW_OUTPUT")
	if out=="" or "--isolated-review" not in OS.get_cmdline_user_args():quit(2);return
	for which in ["center","edge","corner"]:
		var w=farm();fill(w);var p=Vector2i(15,11) if which=="center" else Vector2i(15,12) if which=="edge" else Vector2i(14,12);var approach=Vector2i(15,12)
		w.keeper.pos=Vector2i(15,13) if which!="corner" else Vector2i(13,12)
		var before=masks(w);var transitions={}
		for cell in w.rocks:transitions[cell]=View.transition(w,cell)
		check(w.rocks.size()==9 and View.mask(w,Vector2i(15,11))==15,"3x3 cluster starts with nine real cells and full centre mask: "+which)
		if which=="center":
			w.Tasks.designate(w,"mine",p);w.step();check(w.Harvest.progress(w,"mine",p)==0,"An enclosed centre cannot be worked by teleporting through stone")
			w.Tasks.designate(w,"mine",approach);finish(w,approach)
			check(w.walkable(approach) and w.Stock.totals(w).get("stone",0)==8,"Real edge mining opens the corridor to the centre")
		else:w.Tasks.designate(w,"mine",p)
		for i in range(50):
			w.step()
			if w.Harvest.progress(w,"mine",p)>0.25:break
		check(w.rocks.has(p) and w.Harvest.progress(w,"mine",p)>0,"Damage appears before removal: "+which)
		w.Snapshot.save(w,out+"/"+which+".snapshot");var restored=w.Snapshot.restore(out+"/"+which+".snapshot")
		check(restored.Harvest.progress(restored,"mine",p)==w.Harvest.progress(w,"mine",p) and masks(restored)==masks(w),"Save preserves cell progress and connection masks: "+which)
		finish(restored,p)
		var removed=2 if which=="center" else 1
		check(restored.rocks.size()==9-removed and not restored.rocks.has(p),"Only the requested cells are removed: "+which)
		check(restored.walkable(p) and not restored.find_path(restored.keeper.pos,p).is_empty(),"Actual collision/path updates after extraction: "+which)
		check(restored.Stock.totals(restored).get("stone",0)==removed*8 and restored.Stock.available(restored,"stone")==0,"Exact physical stone stays on site, not free construction stock: "+which)
		check(restored.rocks.keys().all(func(cell):return before.has(cell)),"No neighbour disappears or new deposit appears: "+which)
		check(restored.rocks.keys().all(func(cell):return View.transition(restored,cell)==transitions[cell]),"Biome boundary selection does not change with mining masks: "+which)
		if which=="center":
			check(View.inner(restored,Vector2i(14,10)).has("se") and View.inner(restored,Vector2i(16,10)).has("sw"),"New diagonal concave seams appear when the centre is missing")
		var snapshot=out+"/"+which+"_after.snapshot";restored.Snapshot.save(restored,snapshot);var again=restored.Snapshot.restore(snapshot)
		check(again.rocks==restored.rocks and again.mined_rock_cells==restored.mined_rock_cells and again.Stock.totals(again)==restored.Stock.totals(restored),"Post-mining restart does not respawn cells or duplicate drops: "+which)
	var boundary_world=farm();var duplicate_outer=0;var inside_textures=0
	for y in range(boundary_world.H):
		for x in range(boundary_world.W):
			var cell=Vector2i(x,y);var key=View.transition(boundary_world,cell)
			if not View.geology(boundary_world,cell) and key!="":duplicate_outer+=1
			if View.geology(boundary_world,cell) and key!="":inside_textures+=1
	check(duplicate_outer==0 and inside_textures>0,"Biome transition finishes inside rock biome without restarting on grass neighbour")
	var w=farm();var p=Vector2i(15,11);w.rocks[p]={"amount":8,"forbidden":false};var size=View.node_size(w,p)
	for amount in [0.0,1.1,2.4,3.6]:
		w.rocks[p].elapsed=amount;var key=View.normal_key(w,p)
		check(key.begins_with("biome_environment_v2/rock_node/"+size+"/") and View.Art.ASSETS[key].anchor==Vector2(24,46),"Single-node state preserves its size and foot anchor: "+str(amount))
	for m in range(16):
		for level in range(1,4):
			var damage=View.clipped_damage(m,level).get_image();var normal=View.Art.texture(View.WALL+"normal/mask_%02d.png"%m).get_image();var escaped=false
			for y in range(54):
				for x in range(48):
					if normal.get_pixel(x,y).a==0 and damage.get_pixel(x,y).a>0:escaped=true
			check(not escaped,"Damage never leaves mask alpha: %d/%d"%[m,level])
	FileAccess.open(out+"/rock-connections.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"method":"Production World.step, enclosed-centre access, snapshot restore, exact drops and dynamic masks; all 48 damage mask clips"},"  "))
	print("ROCK_CONNECTIONS: ",checks.size()," checks, failures=",failures);quit(1 if failures else 0)
