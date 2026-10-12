extends SceneTree
const Farm=preload("res://game/world.gd")
const Audio=preload("res://game/farm_audio.gd")
var checks=[]
var failures=0
func _initialize():call_deferred("run")
func check(ok: bool,note: String):
	checks.append({"passed":ok,"check":note})
	if not ok:failures+=1;push_error(note)
func farm():
	var w=Farm.new({},31).begin_day();w.story.intro_seen=true;w.trees.clear();w.rocks.clear();w.natural.clear();w.field_items.clear();w.zones.clear();w.storage_cells.clear();w.Zones.sync_storage(w);w.Stock.sync(w);w.nature_config.spawn_chance_per_second=0;w.campaign.last_supply_day=99999;w.keeper.pos=Vector2i(9,10);w.keeper.sleepiness=0;w.keeper.satiety=100;w.animals[0].pos=Vector2i(3,3)
	return w
func ticks(w,n):
	for i in range(n):w.step()
func tree(w,p):
	var id="fixture-tree-%d-%d"%[p.x,p.y];w.trees[p]=id;w.story.trees.append({"id":id,"position":[p.x,p.y]})
func run():
	var out=OS.get_environment("FARM_REVIEW_OUTPUT")
	if out=="" or "--isolated-review" not in OS.get_cmdline_user_args():quit(2);return
	var w=farm();var p=Vector2i(10,10);w.rocks[p]={"amount":8,"forbidden":false};w.rocks[p+Vector2i.RIGHT]={"amount":8,"forbidden":false}
	check(w.Tasks.designate(w,"mine",p),"Single-cell mining uses the existing designation")
	ticks(w,8);var progress=w.Harvest.progress(w,"mine",p);var count=w.harvest_events.size()
	check(progress>0 and progress<1 and not w.walkable(p),"Progress changes while the active rock still blocks movement")
	check(w.harvest_events.any(func(e):return e.event=="strike") and w.harvest_events.filter(func(e):return e.event=="strike").all(func(e):return absf(fposmod(e.progress*4,0.75))<0.01),"Strike events are emitted on actual work cadence")
	w.paused=true;ticks(w,12);check(w.Harvest.progress(w,"mine",p)==progress and w.harvest_events.size()==count,"PAUSE does not advance work or emit sound/particle events");w.paused=false
	w.Work.set_drafted(w,"keeper",true);ticks(w,4);check(w.Harvest.progress(w,"mine",p)==progress,"Interruption preserves rock damage")
	w.Work.set_drafted(w,"keeper",false);w.Snapshot.save(w,out+"/harvest.snapshot");var restored=w.Snapshot.restore(out+"/harvest.snapshot")
	check(restored.Harvest.progress(restored,"mine",p)==progress,"Snapshot retains mining progress and work identity")
	ticks(restored,30)
	check(not restored.rocks.has(p) and restored.rocks.has(p+Vector2i.RIGHT),"Only the mined cell disappears, neighbouring rock remains")
	check(restored.walkable(p) and not restored.find_path(Vector2i(9,10),p).is_empty() and restored.Buildings.reason(restored,"wood_tile",p,false)!="岩があります", "Collision/path/terrain re-evaluate the removed cell")
	check(restored.Stock.totals(restored).get("stone",0)==8 and restored.Stock.available(restored,"stone")==0 and restored.field_items.all(func(row):return row.pos==p and row.location=="ground"),"Mining creates eight real stones on site without supplying shared building stock")
	restored.Zones.create(restored,"stockpile",Vector2i(8,12),Vector2i(8,12));restored.Stock.designate(restored,"haul",p,p);ticks(restored,100)
	check(restored.Stock.available(restored,"stone")==8,"Explicit collection transports stone to a stockpile")
	w=farm();tree(w,p);tree(w,p+Vector2i.RIGHT)
	check(w.Stock.designate(w,"clear_tree",p,p+Vector2i.RIGHT).accepted==2,"Rectangle felling designates each tree once")
	check(w.jobs.all(func(j):return w.Work.category(w,j)=="gather"),"Felling uses the existing plant/gather work category")
	w.keeper.work_priorities.gather=0;w.keeper.work_priorities.other=1;ticks(w,5)
	check(w.Harvest.progress(w,"clear_tree",p)==0,"Other priority cannot run a disabled plant/gather job")
	w.keeper.work_priorities.gather=1;ticks(w,6);progress=w.Harvest.progress(w,"clear_tree",p)
	check(progress>0 and progress<1,"Plant/gather priority makes the resident approach and chop")
	w.Stock.designate(w,"forbid",p,p);ticks(w,4);check(w.Harvest.progress(w,"clear_tree",p)==progress,"Range forbid suspends felling, retains progress")
	var old_count=w.jobs.size();w.Stock.designate(w,"allow",p,p);w.Tasks.set_forbidden(w,"clear_tree",p+Vector2i.RIGHT,-1,true);check(w.jobs.size()==old_count, "Allow does not duplicate orders");ticks(w,5);check(w.Harvest.progress(w,"clear_tree",p)>progress,"Allow resumes the same work without creating an extra designation")
	var j=w.Tasks.job(w,"clear_tree",p);progress=w.Harvest.progress(w,"clear_tree",p);w.Jobs.cancel(w,j.id)
	check(w.trees.has(p) and w.Harvest.progress(w,"clear_tree",p)==progress,"Cancel removes the order and keeps the tree and damage")
	w.Tasks.set_forbidden(w,"clear_tree",p+Vector2i.RIGHT,-1,false);w.Tasks.designate(w,"clear_tree",p);w.persist_farm();restored=Farm.new(w.campaign,31)
	check(restored.Harvest.progress(restored,"clear_tree",p)==progress and restored.trees.get(p)==w.trees[p],"Campaign save preserves the same damaged tree without regeneration")
	w.Snapshot.save(w,out+"/tree.snapshot");restored=w.Snapshot.restore(out+"/tree.snapshot");ticks(restored,80)
	check(not restored.trees.has(p) and not restored.trees.has(p+Vector2i.RIGHT) and restored.Stock.totals(restored).get("wood",0)==16 and restored.Stock.available(restored,"wood")==0,"Both trees finish individually and leave exactly sixteen physical wood")
	check(restored.walkable(p) and restored.Buildings.reason(restored,"wall",p,false) =="物があるため建設できません","Felled cell loses tree collision; dropped wood remains a normal building obstacle")
	check(restored.harvest_events.size()<=64 and restored.harvest_events.filter(func(e):return e.event=="complete").size()==2,"Presentation events are bounded and completion is emitted once per tree")
	var a=Audio.new();root.add_child(a);a.set_process(false)
	check(a.cache.mine_hit.data!=a.cache.chop_hit.data and a.cache.mine_hit.data.count(0)<a.cache.mine_hit.data.size(),"Mining and chopping use distinct non-silent PCM sounds")
	check(a.harvest_cue("mine_hit",0) and not a.harvest_cue("chop_hit",0),"Simultaneous workers share a bounded sound rate")
	a.seconds+=0.2;check(not a.harvest_cue("mine_hit",15) and a.harvest_cue("chop_hit",3),"Offscreen/distant work is quiet while nearby work remains audible")
	a.cache.mine_hit.save_to_wav(out+"/mine_hit.wav");a.cache.chop_hit.save_to_wav(out+"/chop_hit.wav");a.queue_free()
	FileAccess.open(out+"/harvest.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"method":"Production World.step, real IDs and stock, interruption/forbid/cancel, campaign and full snapshot; PCM synthesis under Dummy audio"},"\t"))
	print("HARVEST: ",checks.size()," checks, failures=",failures);quit(1 if failures else 0)
