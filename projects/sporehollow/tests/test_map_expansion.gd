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
	var statistics=[]
	for seed_number in [31,73,109]:
		var w=Farm.new({},seed_number).begin_day()
		check(w.W==100 and w.H==68 and w.terrain.fields.size()==6800,"New map dimensions: "+str(seed_number))
		check(w.distance(w.keeper.pos,Vector2i(50,34))<=4 and w.distance(w.animals[0].pos,Vector2i(50,34))<=5 and w.Story.at(w)==Vector2i(49,33),"Central initial actors and idol: "+str(seed_number))
		var reached=w.Biome.reachable(w);var counts={};var largest={};var seen={}
		for y in range(w.H):
			for x in range(w.W):
				var p=Vector2i(x,y);var kind=w.Biome.kind(w,p);counts[kind]=counts.get(kind,0)+1
				if seen.has(p):continue
				var frontier=[p];seen[p]=true;var index=0
				while index<frontier.size():
					var v=frontier[index];index+=1
					for n in w.neighbors(v):
						if w.inside(n) and not seen.has(n) and w.Biome.kind(w,n)==kind:seen[n]=true;frontier.append(n)
				largest[kind]=maxi(largest.get(kind,0),frontier.size())
		check(counts.size()==5 and largest.get("rocky",0)>=100 and largest.get("woodland",0)>=100,"Five broad regions, forest/rock connected areas >=100 cells: "+str(seed_number))
		var edges=[Vector2i(0,0),Vector2i(99,0),Vector2i(0,67),Vector2i(99,67),Vector2i(50,0),Vector2i(50,67),Vector2i(0,34),Vector2i(99,34)]
		check(edges.all(func(p):return w.inside(p) and reached.has(p) and w.Land.is_exit(w.exit_for(p),w.W,w.H)),"All corners and edge midpoints connected and valid exits: "+str(seed_number))
		check(w.entries.all(func(p):return reached.has(p) and w.Land.is_exit(w.exit_for(p),w.W,w.H)) and reached.has(w.logistics_entry),"Enemy and merchant entries connected: "+str(seed_number))
		statistics.append({"seed":seed_number,"area":counts,"largest_connected":largest,"trees":w.trees.size(),"mountains":w.mountains.size()})
		if seed_number==31:
			w.Tasks.designate(w,"mine",w.mountains.values()[0].pos)
			var before=[w.trees.duplicate(true),w.rocks.duplicate(true),w.mountains.duplicate(true),w.jobs.duplicate(true),w.Stock.totals(w)]
			check(w.Snapshot.save(w,out+"/large.snapshot"),"New map saves")
			var loaded=w.Snapshot.restore(out+"/large.snapshot")
			check(loaded.W==100 and loaded.H==68 and [loaded.trees,loaded.rocks,loaded.mountains,loaded.jobs,loaded.Stock.totals(loaded)]==before,"100x68 snapshot restores exact terrain/resources/work")
	var legacy=Farm.Snapshot.restore(OS.get_environment("FARM_LEGACY_FIXTURE")+"/legacy.snapshot")
	check(legacy!=null and legacy.W==50 and legacy.H==34,"Actual old snapshot retains 50x34 bounds")
	FileAccess.open(out+"/map-expansion.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"regions":statistics},"  "))
	quit(0 if checks.all(func(c):return c.passed) else 1)
