extends SceneTree
const Farm=preload("res://game/world.gd")
const Model=preload("res://game/colony_view_model.gd")
var checks=[]
var failed=0
func _initialize():call_deferred("run")
func check(ok,note):
	checks.append({"passed":bool(ok),"check":note})
	if not ok:failed+=1;push_error(note)
func farm():
	var w=Farm.new({},31).begin_day();w.enemies.clear();w.spawn_schedule.clear();w.natural.clear();w.trees.clear();w.rocks.clear();w.structures.clear();w.floors.clear();w.field_items.clear();w.jobs.clear();w.zones=[];w.storage_cells=[]
	w.keeper.pos=Vector2i(8,8);w.keeper.satiety=100;w.keeper.sleepiness=0;w.story.intro_seen=true;w.nature_config.spawn_chance_per_second=0
	for a in w.animals:a.pos=Vector2i(22,22);a.home=a.pos;a.mode="stay";a.order_until=99999
	return w
func run():
	var out=OS.get_environment("FARM_REVIEW_OUTPUT")
	if out=="" or "--isolated-review" not in OS.get_cmdline_user_args():quit(2);return
	var w=farm()
	var v2={"work_priority_version":2,"work_priorities":{"build":1,"gather":0,"collect":2,"other":3,"haul":4}}
	w.Work.migrate_priorities(v2)
	check(v2.work_priorities=={"build":1,"gather":0,"collect":2,"other":3,"haul":4,"animal":3},"v2 migration preserves existing choices and initializes animal work from other")
	w.Work.migrate_priorities(v2);check(v2.work_priorities.build==1 and v2.work_priorities.animal==3,"v3 migration is idempotent")
	var v1={"work_priority_version":1,"work_priorities":{"build":1,"gather":0,"collect":2,"other":2,"haul":3}}
	w.Work.migrate_priorities(v1);check(v1.work_priorities.build==2 and v1.work_priorities.gather==0 and v1.work_priorities.animal==3,"Only v1 values receive the historical offset; disabled stays disabled")
	for kind in ["train","slaughter","milk","animal_order","equip"]:
		var j={"kind":kind,"work_category":"other","pos":Vector2i(9,9)}
		check(w.Work.category(w,j)=="animal" and Model.job_category(w,j)=="動物","Canonical animal category overrides legacy field: "+kind)
	check(Model.job_category(w,{"kind":"mine","pos":Vector2i(9,9)})=="採集" and "登録順" not in Model.CATEGORIES,"Mining agrees with work priorities and list offers no misleading execution order")
	w.Stock.add(w,"soil",100,Vector2i(9,8));w.act("wall",Vector2i(16,8));w.act("wall",Vector2i(10,8))
	var picked=w.Work.choose(w,"keeper")
	check(picked.pos==Vector2i(10,8) and picked.id>w.jobs[0].id,"Same category chooses nearer valid job, not first registered")
	w=farm();w.Stock.add(w,"soil",100,Vector2i(9,8));w.act("wall",Vector2i(10,8));w.paused=true
	var at=w.keeper.pos;var tick=w.tick;w.step();check(w.tick==tick and w.keeper.pos==at and w.jobs.size()==1,"Pause accepts plans without work or clock progression")
	w=farm();var zone=w.Zones.create(w,"stockpile",Vector2i(10,8),Vector2i(10,8))
	w.Stock.add(w,"wood",10,Vector2i(10,8));var reserved=w.Stock.add(w,"wood",6,Vector2i(11,8));reserved.claims={"test":2}
	var forbidden=w.Stock.add(w,"wood",5,Vector2i(12,8));forbidden.forbidden=true
	w.Stock.add(w,"wood",3,Vector2i(8,8),"carry",91);w.field_items.back().owner="keeper"
	w.Stock.add(w,"wood",4,Vector2i(14,8),"site",92)
	var s=w.Stock.summary(w,"wood")
	check(s=={"owned":28,"available":14,"stored":10,"carried":3,"site":4,"forbidden":5,"reserved":2},"Ownership, available, stored, cargo, site, forbidden and reserved counts stay distinct")
	check(w.jobs.is_empty(),"Stockpile designation and summary create no hidden jobs")
	w=farm();w.keeper.work_priorities.other=2;w.keeper.work_priorities.animal=0
	w.Tasks.designate(w,"train",Vector2i.ZERO,w.animals[0].id)
	check(w.Work.choose(w,"keeper").is_empty(),"Disabled animal priority excludes training even with enabled other")
	w.Work.set_priority(w,"keeper","animal",1)
	check(w.Work.choose(w,"keeper").get("kind")=="train","Animal priority enables the real training job")
	w.Snapshot.save(w,out+"/review01.snapshot");var restored=w.Snapshot.restore(out+"/review01.snapshot")
	check(restored.keeper.work_priorities==w.keeper.work_priorities and restored.Work.category(restored,restored.jobs[0])=="animal","Snapshot retains independent animal priorities and existing job identity")
	FileAccess.open(out+"/review01.json",FileAccess.WRITE).store_string(JSON.stringify({"method":"Controlled World/Work/Stock fixtures; no human play","checks":checks,"failures":failed},"\t"))
	print("Review01: ",checks.size()," checks, ",failed," failures");quit(1 if failed else 0)
