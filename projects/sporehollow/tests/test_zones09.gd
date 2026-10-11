extends SceneTree
const Farm=preload("res://game/world.gd")
var failures=0
var report={"method":"Controlled component simulation using production Work/Life movement and save/restore; not human play.","groups":[]}
var current={}
func _initialize():call_deferred("run")
func begin(title):current={"name":title,"checks":[]};report.groups.append(current)
func check(ok: bool,note: String):
	current.checks.append({"passed":ok,"check":note})
	if not ok:failures+=1;push_error(note)
func farm():
	var w=Farm.new({},31).begin_day();w.trees.clear();w.natural.clear();w.field_items.clear();w.jobs.clear();w.zones=[];w.storage_cells=[]
	w.keeper.pos=Vector2i(4,6);w.keeper.satiety=100;w.keeper.sleepiness=0;w.keeper.drafted=false;w.stock_used={};w.story.intro_seen=true
	return w
func work_ticks(w,n):
	for i in range(n):w.tick+=1;w.Work.step(w)
func run():
	var out=OS.get_environment("FARM_REVIEW_OUTPUT")
	if out=="" or not "--isolated-review" in OS.get_cmdline_user_args():quit(2);return
	begin("1 Multiple filtered stockpiles: physical hauling, edits in transit and save")
	var w=farm();var wood=w.Stock.add(w,"wood",6,Vector2i(6,6));var stone=w.Stock.add(w,"stone",3,Vector2i(7,6))
	var z1=w.Zones.create(w,"stockpile",Vector2i(10,8),Vector2i(11,8));w.Zones.set_allowed(w,z1,["wood"])
	var z2=w.Zones.create(w,"stockpile",Vector2i(12,9),Vector2i(12,9));w.Zones.set_allowed(w,z2,["stone"])
	check(w.zones.size()==2 and w.storage_cells.size()==3 and wood.pos==Vector2i(6,6),"Two zones are separate and designation does not teleport goods")
	w.Stock.designate(w,"haul",Vector2i(6,6),Vector2i(7,6))
	for i in range(80):
		work_ticks(w,1)
		if not w.Stock.cargo(w,"keeper").is_empty():break
	check(not w.Stock.cargo(w,"keeper").is_empty(),"Worker physically picks up goods before zone edit")
	var before=w.Stock.totals(w);w.Zones.resize(w,z1,Vector2i(14,8),Vector2i(14,8));work_ticks(w,150)
	check(w.field_items.any(func(r):return r.kind=="wood" and r.location=="ground" and r.pos==Vector2i(14,8)),"Carried wood reselects the resized permitted destination")
	check(w.field_items.any(func(r):return r.kind=="stone" and r.location=="ground" and r.pos==Vector2i(12,9)),"Stone reaches only the stone-enabled stockpile")
	check(w.Stock.totals(w)==before,"Resize and actual hauling preserve all quantities")
	var held=w.Stock.add(w,"wood",2,Vector2i(6,7));w.Stock.designate(w,"haul",Vector2i(6,7),Vector2i(6,7))
	for i in range(120):
		work_ticks(w,1)
		if not w.Stock.cargo(w,"keeper").is_empty():break
	var actual=w.keeper.pos;before=w.Stock.totals(w);w.Zones.remove(w,z1);work_ticks(w,1)
	check(w.Stock.cargo(w,"keeper").is_empty() and w.field_items.any(func(r):return r.kind=="wood" and r.location=="ground" and r.pos==actual),"Deleting the only allowed destination releases carried goods at the actual worker location")
	check(w.Stock.totals(w)==before and w.jobs.any(func(j):return j.state=="blocked" and "備蓄" in j.get("block_reason","")),"No destination blocks with a visible reason and no quantity loss")
	w.Zones.set_allowed(w,z2,["wood","stone"]);work_ticks(w,170)
	check(w.field_items.any(func(r):return r.kind=="wood" and r.amount==2 and r.location=="ground" and r.pos==Vector2i(12,9)) and w.field_items.any(func(r):return r.kind=="wood" and r.amount==6 and r.pos==Vector2i(14,8)),"Changing allowed types resumes the explicit blocked haul; undesignated stored wood stays put")
	w.Zones.remove(w,z2);check(w.Stock.available(w,"wood")==8,"Goods remain available for use outside deleted zones")
	var saved_zone=w.Zones.create(w,"stockpile",Vector2i(15,9),Vector2i(16,9));w.Zones.set_allowed(w,saved_zone,["food"])
	w.Zones.create(w,"residential",Vector2i(7,10),Vector2i(8,10));w.persist_farm();var restored=Farm.new(w.campaign,31)
	check(restored.zones==w.zones and restored.Stock.totals(restored)==w.Stock.totals(w),"Campaign save restores zones, filters and unchanged physical goods")
	check(w.Snapshot.save(w,out+"/zones.snapshot"),"Snapshot writes zones with current work state")
	restored=w.Snapshot.restore(out+"/zones.snapshot")
	check(restored.zones==w.zones and restored.storage_cells==w.storage_cells and restored.jobs==w.jobs,"Snapshot restores zone cells and job state consistently")
	var legacy=w.campaign.duplicate(true);legacy.erase("zones");legacy.storage_cells=[[9,9],[10,9]];restored=Farm.new(legacy,31)
	check(restored.zones.size()==1 and restored.zones[0].cells==[Vector2i(9,9),Vector2i(10,9)],"Legacy single storage cells migrate into one permissive zone")
	begin("2 Residential rest: travel, changed/deleted area and unreachable fallback")
	w=farm();var home=w.Zones.create(w,"residential",Vector2i(8,8),Vector2i(8,8));w.keeper.sleepiness=50;w.Life.set_rest(w,true)
	var start=w.keeper.pos
	for i in range(100):
		w.tick+=1;w.Life.step(w)
		if w.keeper.get("asleep",false):break
	check(w.keeper.pos==Vector2i(8,8) and w.keeper.pos!=start and w.keeper.asleep,"Keeper walks into residential zone before sleeping")
	w.Zones.resize(w,home,Vector2i(10,8),Vector2i(10,8))
	for i in range(70):w.tick+=1;w.Life.step(w)
	check(w.keeper.pos==Vector2i(10,8),"Resting keeper follows the changed residential destination")
	w.Zones.remove(w,home);var current_pos=w.keeper.pos;w.tick+=1;w.Life.step(w)
	check(w.keeper.pos==current_pos and "未指定" in w.keeper.rest_reason,"Deleting residential area preserves the sleeper and states the current-location fallback")
	# Existing solid tree cells are unwalkable and therefore a valid unreachable designation.
	w.trees[Vector2i(12,8)]={"hp":10};w.Zones.create(w,"residential",Vector2i(12,8),Vector2i(12,8));w.tick+=1;w.Life.step(w)
	check(w.keeper.pos==current_pos and "到達できない" in w.keeper.rest_reason,"An unreachable residential area falls back with an explicit reason")
	report.passed=failures==0;report.failures=failures
	FileAccess.open(out+"/zones09.json",FileAccess.WRITE).store_string(JSON.stringify(report,"\t"))
	print("Zones09: 2 groups, ",failures," failures");quit(0 if failures==0 else 1)
