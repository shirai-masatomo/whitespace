extends SceneTree
const Farm=preload("res://game/world.gd")
const Live=preload("res://game/livestock.gd")
var failures=0
var report={"method":"Controlled fixtures using production World.step and snapshot/campaign serialization. Simulation, not human play.","groups":[]}
var current={}
func _initialize():call_deferred("run")
func begin(name):current={"name":name,"checks":[]};report.groups.append(current)
func check(ok: bool,note: String):
	current.checks.append({"passed":ok,"check":note})
	if not ok:failures+=1;push_error(note)
func farm():
	var w=Farm.new({},31).begin_day();w.trees.clear();w.natural.clear();w.field_items.clear();w.jobs.clear();w.zones=[];w.storage_cells=[];w.stock_used={};w.nature_config.spawn_chance_per_second=0
	w.keeper.pos=Vector2i(6,8);w.keeper.satiety=100;w.keeper.sleepiness=0;w.story.intro_seen=true;w.animals[0].pos=Vector2i(20,20);w.animals[0].mode="stay";w.animals[0].home=w.animals[0].pos
	return w
func animal(w,species="hen",id=2):
	var row={"id":id,"category":w.SPECIES[species].category,"species":species,"lv":1,"xp":0,"loyalty":w.SPECIES[species].loyalty,"unavailable_through_day":0,"position":[8,8]}
	w.campaign.animals.append(row);w.campaign.next_animal_id=maxi(w.campaign.next_animal_id,id+1);w.add_resident(row);var a=w.Orders.animal(w,id);a.pos=Vector2i(8,8);a.home=a.pos;return a
func progress(w,until_started=false):
	for i in range(140):
		w.step()
		if until_started and w.jobs.any(func(j):return j.kind=="slaughter" and j.get("work_elapsed",0)>0):break
		if not until_started and not w.jobs.any(func(j):return j.kind=="slaughter"):break
func meat(w):return w.Stock.totals(w).get("meat",0)+w.stock_used.get("meat",0)
func run():
	var out=OS.get_environment("FARM_REVIEW_OUTPUT")
	if out=="" or not "--isolated-review" in OS.get_cmdline_user_args():quit(2);return
	begin("1 Explicit eligibility, cancellable work and one physical meat output")
	var w=farm();var hen=animal(w);var cat=animal(w,"cat",3)
	check(Live.classification(hen)=="livestock" and Live.classification(cat)=="pet" and Live.classification(w.animals[0])=="pet","Existing hen is livestock; cat and dog are protected pets")
	var before=[hen.loyalty,hen.mode,hen.attack_power];Live.set_class(w,hen.id,"pet")
	check(not Live.designate(w,hen.id) and not Live.set_class(w,cat.id,"livestock") and not Live.designate(w,cat.id),"Pet status blocks slaughter and non-livestock species cannot be reclassified into eligible livestock")
	Live.set_class(w,hen.id,"livestock");check(before==[hen.loyalty,hen.mode,hen.attack_power],"Classification changes no loyalty, AI mode or combat values")
	for i in range(18):w.step()
	check(meat(w)==0 and not hen.get("dead",false),"Livestock never self-designates slaughter")
	check(Live.designate(w,hen.id) and not Live.designate(w,hen.id),"One explicit individual designation creates only one job")
	progress(w,true);var j=Live.job(w,hen.id)
	check(not j.is_empty() and j.started and w.distance(w.keeper.pos,hen.pos)<=1 and meat(w)==0,"Worker reaches the living animal and starts onsite work without early meat")
	w.paused=true;w.Jobs.cancel(w,j.id);w.paused=false;w.step()
	check(Live.job(w,hen.id).is_empty() and not hen.get("dead",false) and meat(w)==0,"Cancelling a started job while paused leaves the animal alive and creates no meat")
	Live.designate(w,hen.id);progress(w,true);j=Live.job(w,hen.id);var elapsed=j.work_elapsed
	Live.set_forbidden(w,hen.id,true)
	for i in range(20):w.step()
	check(not hen.get("dead",false) and meat(w)==0 and j.state=="blocked" and j.work_elapsed==elapsed,"Forbid interrupts work, keeps progress and produces no meat")
	w.persist_farm();var saved=Farm.new(w.campaign,31);var saved_hen=saved.Orders.animal(saved,hen.id)
	check(saved_hen.forbidden and Live.classification(saved_hen)=="livestock" and saved.jobs.any(func(row):return row.kind=="slaughter" and row.explicit_designation),"Campaign retains classification, forbid and explicit unfinished work")
	Live.set_forbidden(w,hen.id,false);check(w.Snapshot.save(w,out+"/slaughter-mid.snapshot"),"Started work snapshot saved")
	w=w.Snapshot.restore(out+"/slaughter-mid.snapshot");hen=w.Orders.animal(w,2);progress(w)
	check(hen.get("slaughtered",false) and not w.campaign.animals.any(func(row):return row.id==2) and meat(w)==Live.MEAT.hen,"Allowed saved work finishes exactly once and removes the owned animal")
	var output=w.field_items.filter(func(row):return row.kind=="meat")
	check(output.size()==1 and output[0].location=="ground" and output[0].pos==hen.pos and output[0].slaughter_animal_id==2,"Meat is a single real ground stack at the actual slaughter location")
	w.Snapshot.save(w,out+"/slaughter-done.snapshot");w=w.Snapshot.restore(out+"/slaughter-done.snapshot")
	check(not Live.designate(w,2),"Completed slaughter cannot be designated again after restore")
	var zone=w.Zones.create(w,"stockpile",Vector2i(12,10),Vector2i(12,10));w.Zones.set_allowed(w,zone,["food"]);w.Stock.designate(w,"haul",hen.pos,hen.pos)
	for i in range(140):w.step()
	check(meat(w)==4 and w.field_items.any(func(row):return row.kind=="meat" and row.pos==Vector2i(12,10)),"Existing hauling transports meat to food-enabled stockpile without duplication")
	w.keeper.satiety=20
	for i in range(120):
		w.step()
		if w.stock_used.get("meat",0)>0:break
	check(w.stock_used.get("meat",0)>0 and meat(w)==4,"Existing human eating consumes physical meat while total output remains four")
	begin("2 Target loss, captivity, foreign ownership and conflicting reservation")
	for cause in ["dead","lost","missing"]:
		w=farm();hen=animal(w);Live.designate(w,hen.id);progress(w,true)
		if cause=="missing":w.animals.erase(hen)
		else:w.Progression.remove_animal(w,hen,"death" if cause=="dead" else "lost")
		w.step();check(meat(w)==0 and Live.job(w,2).is_empty(),"Target "+cause+" cancels remaining work without meat")
	w=farm();hen=animal(w);hen.abductor=7
	check(not Live.designate(w,hen.id),"Captured animal cannot be designated")
	hen.erase("abductor");hen.faction="enemy";check(not Live.designate(w,hen.id),"Foreign animal cannot be designated")
	hen.faction="owned";w.jobs.append({"id":99,"kind":"milk","animal_id":hen.id,"pos":hen.pos,"state":"pending"})
	check(not Live.designate(w,hen.id),"A conflicting animal reservation blocks a new slaughter job")
	w.jobs.clear();Live.designate(w,hen.id);progress(w,true);hen.abductor=7;w.step()
	check(meat(w)==0 and Live.job(w,hen.id).state=="blocked","Capture during onsite work blocks before the final irreversible effect")
	hen.erase("abductor");Live.set_class(w,hen.id,"pet");w.step()
	check(meat(w)==0 and not hen.get("dead",false) and Live.job(w,hen.id).state=="blocked","Changing an active target to pet protects it immediately")
	report.passed=failures==0;report.failures=failures
	FileAccess.open(out+"/livestock09.json",FileAccess.WRITE).store_string(JSON.stringify(report,"\t"));print("Livestock09: 2 groups, ",failures," failures");quit(0 if failures==0 else 1)
