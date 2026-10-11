extends SceneTree
const Farm=preload("res://game/world.gd")
const Tasks=preload("res://game/colony_tasks.gd")
var failed=0
var report={"method":"Controlled fixtures through production World.step and snapshot/campaign persistence. Simulation, not human play.","groups":[]}
var group={}
func _initialize():call_deferred("run")
func begin(name):group={"name":name,"checks":[]};report.groups.append(group)
func check(ok: bool,note: String):
	group.checks.append({"passed":ok,"check":note})
	if not ok:failed+=1;push_error(note)
func farm():
	var w=Farm.new({},31).begin_day();w.trees.clear();w.natural.clear();w.field_items.clear();w.jobs.clear();w.zones=[];w.storage_cells=[];w.stock_used={};w.nature_config.spawn_chance_per_second=0
	w.rocks={Vector2i(8,8):{"amount":8,"forbidden":false}};Tasks.save(w)
	w.keeper.pos=Vector2i(6,8);w.keeper.satiety=100;w.keeper.sleepiness=0;w.story.intro_seen=true
	var dog=w.animals[0];dog.pos=Vector2i(8,10);dog.home=dog.pos;dog.mode="stay";dog.order_until=99999;return w
func progress(w,kind: String,started=false):
	for i in range(160):
		w.step()
		if started and w.jobs.any(func(j):return j.kind==kind and j.get("work_elapsed",0)>0):return
		if not started and not w.jobs.any(func(j):return j.kind==kind):return
func run():
	var out=OS.get_environment("FARM_REVIEW_OUTPUT")
	if out=="" or not "--isolated-review" in OS.get_cmdline_user_args():quit(2);return
	begin("1 Deterministic rocks, physical mining, interruption and persistence")
	var original=Farm.new({},31).begin_day();var another=Farm.new({},31).begin_day()
	check(original.rocks==another.rocks and not original.rocks.is_empty() and original.rocks.keys().all(func(p):return original.Biome.kind(original,p)=="rocky"),"New farms place deterministic deposits on rocky terrain")
	check(original.rocks.keys().all(func(p):return not original.trees.has(p) and not original.natural.has(p) and not original.live_structure(p) and p not in original.entries),"Generated rocks avoid trees, natural resources, buildings and entrances")
	var w=farm();var p=Vector2i(8,8)
	check(Tasks.designate(w,"mine",p) and not Tasks.designate(w,"mine",p),"Explicit mining creates one real job and rejects duplicate designation")
	progress(w,"mine",true);var j=Tasks.job(w,"mine",p)
	check(j.started and w.distance(w.keeper.pos,p)<=1 and w.Stock.totals(w).get("stone",0)==0,"Worker reaches the rock before mining; no early stone appears")
	w.paused=true;w.Jobs.cancel(w,j.id);w.paused=false;w.step()
	check(w.rocks[p].amount==8 and Tasks.job(w,"mine",p).is_empty(),"Cancelling started mining preserves the unmined deposit")
	Tasks.designate(w,"mine",p);progress(w,"mine",true);j=Tasks.job(w,"mine",p);var elapsed=j.work_elapsed
	Tasks.set_forbidden(w,"mine",p,-1,true)
	for i in range(12):w.step()
	check(j.work_elapsed==elapsed and j.state=="blocked" and w.rocks[p].amount==8,"Forbidding a reserved rock stops progress and preserves its quantity")
	Tasks.set_forbidden(w,"mine",p,-1,false);w.Snapshot.save(w,out+"/mining.snapshot");w=w.Snapshot.restore(out+"/mining.snapshot");progress(w,"mine")
	check(not w.rocks.has(p) and w.field_items.any(func(row):return row.kind=="stone" and row.amount==8 and row.pos==p and row.location=="ground"),"Saved mining resumes and produces exactly eight physical stone at the rock")
	var zone=w.Zones.create(w,"stockpile",Vector2i(12,10),Vector2i(12,10));w.Zones.set_allowed(w,zone,["stone"]);w.Stock.designate(w,"haul",p,p)
	for i in range(100):w.step()
	check(w.Stock.totals(w).stone==8 and w.field_items.any(func(row):return row.kind=="stone" and row.pos==Vector2i(12,10)),"Existing haul jobs move mined stone into permitted storage")
	w.persist_farm();var restored=Farm.new(w.campaign,31)
	check(restored.rocks.is_empty() and restored.Stock.totals(restored).stone==8,"Campaign reload never regenerates a depleted rock or duplicates stone")
	w=farm();Tasks.designate(w,"mine",p);progress(w,"mine",true);w.rocks.erase(p);w.step()
	check(Tasks.job(w,"mine",p).is_empty() and w.Stock.totals(w).get("stone",0)==0,"Disappeared mining target cancels without producing stone")
	begin("2 Player training: real loyalty, eligibility, ownership, cancellation and saved completion")
	w=farm();var dog=w.animals[0];var loyalty=dog.loyalty
	check(Tasks.designate(w,"train",Vector2i.ZERO,dog.id) and not Tasks.designate(w,"train",Vector2i.ZERO,dog.id),"Only one explicit training job is registered for the selected dog")
	progress(w,"train",true);j=Tasks.job(w,"train",Vector2i.ZERO,dog.id)
	check(j.started and dog.loyalty==loyalty,"Training starts at the animal and does not grant loyalty early")
	w.paused=true;w.Jobs.cancel(w,j.id);w.paused=false;w.step()
	check(dog.loyalty==loyalty and dog.get("last_training_day",-1)<w.last_daily_day,"Cancelling started training grants no loyalty or daily completion")
	Tasks.designate(w,"train",Vector2i.ZERO,dog.id);progress(w,"train",true);j=Tasks.job(w,"train",Vector2i.ZERO,dog.id);elapsed=j.work_elapsed
	Tasks.set_forbidden(w,"train",Vector2i.ZERO,dog.id,true)
	for i in range(12):w.step()
	check(j.state=="blocked" and j.work_elapsed==elapsed and dog.loyalty==loyalty,"Forbidden animal pauses training without granting loyalty")
	Tasks.set_forbidden(w,"train",Vector2i.ZERO,dog.id,false);w.Snapshot.save(w,out+"/training.snapshot");w=w.Snapshot.restore(out+"/training.snapshot");dog=w.animals[0];progress(w,"train")
	check(dog.loyalty==loyalty+Tasks.TRAIN_GAIN and w.Progression.loyalty(dog)==loyalty+Tasks.TRAIN_GAIN and not Tasks.designate(w,"train",Vector2i.ZERO,dog.id),"Saved training changes the existing loyalty value once and enforces the disclosed daily limit")
	w.persist_farm();restored=Farm.new(w.campaign,31);check(restored.animals[0].loyalty==dog.loyalty and restored.animals[0].last_training_day==dog.last_training_day,"Campaign preserves training result and daily guard")
	w.last_daily_day+=1;check(Tasks.reason(w,"train",Vector2i.ZERO,dog.id)=="","The next morning permits another explicit training session")
	for species in ["hen","cat","maid"]:
		var record={"id":9,"species":species,"category":w.SPECIES[species].category,"lv":1,"loyalty":w.SPECIES[species].loyalty,"hp":20,"placed":true,"pos":Vector2i(9,9)}
		w.campaign.animals.append(record);check(Tasks.training_reason(w,record)!="",species+" receives no invented training effect");w.campaign.animals.pop_back()
	w=farm();dog=w.animals[0];dog.abductor=5;check(not Tasks.designate(w,"train",Vector2i.ZERO,dog.id),"A captive cannot be designated")
	dog.erase("abductor");dog.faction="enemy";check(not Tasks.designate(w,"train",Vector2i.ZERO,dog.id),"Foreign animals cannot be trained");dog.faction="owned"
	w.jobs.append({"id":999,"kind":"equip","pos":dog.pos,"animal_id":dog.id});check(not Tasks.designate(w,"train",Vector2i.ZERO,dog.id),"Existing animal work prevents conflicting training");w.jobs.clear()
	Tasks.designate(w,"train",Vector2i.ZERO,dog.id);progress(w,"train",true);dog.abductor=5;w.step()
	check(Tasks.job(w,"train",Vector2i.ZERO,dog.id).state=="blocked" and dog.loyalty==75,"Capture during work blocks the loyalty effect")
	dog.erase("abductor");dog.dead=true;w.step();check(Tasks.job(w,"train",Vector2i.ZERO,dog.id).is_empty() and dog.loyalty==75,"Death cancels training with no reward")
	check(w.Work.target_key(w,{"kind":"train","animal_id":1})==w.Work.target_key(w,{"kind":"slaughter","animal_id":1}),"Training and slaughter share the animal reservation namespace")
	report.passed=failed==0;report.failures=failed;FileAccess.open(out+"/colony-tasks09.json",FileAccess.WRITE).store_string(JSON.stringify(report,"\t"));print("ColonyTasks09: 2 groups, ",failed," failures");quit(0 if failed==0 else 1)
