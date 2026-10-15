extends RefCounted
# Provisional husbandry policy for existing playable species. No loyalty/AI mutation.
# Hen has lay, cow has milk, bull shares bovine husbandry; other companions are pets.
const MEAT={"hen":4,"cow":12,"bull":14}
const WORK_SECONDS=3.0

static func classification(a: Dictionary) -> String:
	if a.get("category","")=="human" or a.get("species","")=="maid":return "person"
	if not MEAT.has(a.get("species","")):return "pet"
	return "pet" if a.get("husbandry_class","livestock")=="pet" else "livestock"

static func owned(w,a: Dictionary) -> bool:
	return not a.is_empty() and a.get("faction","owned")=="owned" and w.campaign.animals.any(func(row):return row.id==a.id and row.species==a.species)

static func job(w,id: int) -> Dictionary:
	for j in w.jobs:
		if j.kind=="slaughter" and j.animal_id==id:return j
	return {}

static func persist_flags(w,a):
	for row in w.campaign.animals:
		if row.id==a.id:row.husbandry_class=classification(a);row.forbidden=a.get("forbidden",false)

static func set_class(w,id: int,value: String) -> bool:
	var a=w.Orders.animal(w,id)
	if not owned(w,a) or value not in ["livestock","pet"] or not MEAT.has(a.species):return false
	a.husbandry_class=value;persist_flags(w,a)
	var j=job(w,id)
	if not j.is_empty() and value=="pet":w.Work.block(w,j,"ペットとして保護されています")
	elif not j.is_empty():j.retry_at=w.tick
	return true

static func set_forbidden(w,id: int,value: bool) -> bool:
	var a=w.Orders.animal(w,id)
	if not owned(w,a) or classification(a)=="person":return false
	a.forbidden=value;persist_flags(w,a)
	var training=w.Tasks.job(w,"train",a.pos,id)
	if not training.is_empty():
		if value:w.Work.block(w,training,"この動物の作業は禁止中です")
		else:training.retry_at=w.tick
	var j=job(w,id)
	if not j.is_empty() and value:w.Work.block(w,j,"対象のと殺は禁止中です")
	elif not j.is_empty():j.retry_at=w.tick
	return true

static func missing(w,j) -> bool:
	var a=w.Orders.animal(w,j.animal_id)
	return not owned(w,a) or a.get("dead",false) or a.get("lost",false) or a.get("slaughtered",false) or a.get("hp",0)<=0

static func reason(w,a: Dictionary,own_job: int=-1) -> String:
	if not owned(w,a):return "所有している家畜を選んでください"
	if classification(a)!="livestock" or not MEAT.has(a.species):return "ペット・人はと殺の対象外です"
	if a.get("forbidden",false):return "対象のと殺は禁止中です"
	if a.get("dead",false) or a.get("lost",false) or a.get("slaughtered",false) or a.get("hp",0)<=0:return "生きている家畜が対象です"
	if not a.get("placed",false):return "家畜の入場を待っています"
	if a.get("abductor",-1)>=0 or a.get("carrier",-1)>=0 or a.get("restrainer",-1)>=0 or a.get("state","") in ["captured","restrained","unconscious"]:return "拘束・運搬・気絶中の家畜は処理できません"
	if not w.available(a):return "家畜の回復を待っています"
	for other in w.jobs:
		if other.id==own_job or other.get("cancel_requested",false):continue
		if other.get("animal_id",-1)==a.id or other.get("targets",[]).any(func(t):return t.get("id",-1)==a.id and not t.get("done",false)):return "対象には別の動物作業が予約されています"
	return ""

static func designate(w,id: int) -> bool:
	var a=w.Orders.animal(w,id)
	if not w.working() or w.jobs.size()>=w.Jobs.LIMIT or reason(w,a)!="":return false
	var j={"id":w.next_job_id,"kind":"slaughter","pos":a.pos,"animal_id":id,"state":"pending","resource":"","reserved":0,"started":false,"work_category":"animal","work_elapsed":0.0,"explicit_designation":true}
	w.next_job_id+=1;w.jobs.append(j);w.Life.wake_auto(w)
	w.job_log.append({"tick":w.tick,"event":"queued","id":j.id,"kind":"slaughter","animal_id":id})
	w.PlayerEvents.add(w,w.animal_name(a)+"のと殺を予約。現地作業後に肉%d個"%MEAT[a.species],"slaughter_plan:%d"%j.id)
	return true

static func held(w,a) -> bool:
	var j=job(w,a.id)
	if j.is_empty() or not j.get("started",false) or j.get("cancel_requested",false):return false
	var actor=w.workers.get(j.get("assigned_to",""),{})
	return not actor.is_empty() and actor.get("hp",0)>0 and actor.get("state","")=="free" and not actor.get("resting",false) and w.distance(actor.pos,a.pos)<=1 and reason(w,a,j.id)==""

static func execute(w,j,actor):
	if not j.get("explicit_designation",false) or j.get("cancel_requested",false):w.Jobs.cancel(w,j.id);return
	var a=w.Orders.animal(w,j.animal_id)
	if missing(w,j):w.Jobs.complete(w,j,false);return
	var why=reason(w,a,j.id)
	if why!="":j.state="blocked";j.block_reason=why;return
	j.pos=a.pos
	if not w.Jobs.walk(w,j,w.neighbors(a.pos),actor):return
	j.started=true;j.state="working";j.phase="work"
	j.work_elapsed=j.get("work_elapsed",0.0)+w.DT*w.Jobs.factor(actor)
	if j.work_elapsed<WORK_SECONDS:return
	# Final eligibility check and completion run atomically in the same fixed tick.
	if reason(w,a,j.id)!="":j.state="blocked";j.block_reason=reason(w,a,j.id);return
	var at=a.pos;var amount=MEAT[a.species]
	a.slaughtered=true;a.dead=true;a.hp=0;a.placed=false;a.state="と殺済み";a.pending={};a.rescuing=false;a.erase("guide_job")
	# Worn equipment remains a real good at the same site rather than disappearing.
	if not a.get("equipment",{}).is_empty():w.Stock.add(w,a.equipment.item_id,1,at);a.equipment={}
	w.campaign.animal_history.append({"id":a.id,"species":a.species,"name":a.get("name",""),"day":w.campaign.day,"reason":"slaughter","job_id":j.id,"meat":amount})
	w.campaign.animals=w.campaign.animals.filter(func(row):return row.id!=a.id)
	var output=w.Stock.add(w,"meat",amount,at);output.slaughter_animal_id=a.id;output.slaughter_job_id=j.id
	w.PlayerEvents.add(w,w.animal_name(a)+"のと殺が完了。現地に肉%d個"%amount,"slaughter_done:%d"%j.id)
	w.Jobs.complete(w,j,true)
