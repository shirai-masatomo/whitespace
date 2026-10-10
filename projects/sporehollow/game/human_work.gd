extends RefCounted
## Selection/ownership only. Jobs executes onsite operations; Life owns emergencies/rest.
const Policy=preload("res://game/work_policy.gd")

static func register(w,key: String,actor: Dictionary):
	w.workers[key]=actor
	actor.work_key=key
	actor.work_priorities=actor.get("work_priorities",Policy.PRIORITIES.duplicate())
	actor.work_job=-1
	actor.work_status="仕事を探しています"
	actor.drafted=actor.get("drafted",false)

static func category(w,j) -> String:
	if j.has("work_category"):return j.work_category
	if w.BUILD.has(j.kind) or j.kind in ["repair","repair_floor","remove","remove_floor","gate"]:return "build"
	if j.kind=="collect":return "gather" if w.natural.has(j.pos) else "collect"
	return "other"

static func shared(w,j) -> bool:
	return w.BUILD.has(j.kind) or j.kind=="collect"

static func target_key(w,j) -> String:
	var layer=w.BUILD[j.kind].get("layer","structure") if w.BUILD.has(j.kind) else j.get("target_layer","collect" if j.kind=="collect" else j.kind)
	return "%s:%d:%d"%[layer,j.pos.x,j.pos.y]

static func active(w,key: String="keeper") -> Dictionary:
	for j in w.jobs:
		if j.get("assigned_to","")==key:return j
	return {}

static func release(w,j):
	var owner=j.get("assigned_to","")
	for token in w.work_claims.keys():
		if w.work_claims[token]==j.id:w.work_claims.erase(token)
	if w.workers.has(owner) and w.workers[owner].get("work_job",-1)==j.id:w.workers[owner].work_job=-1
	j.assigned_to=""

static func interrupt(w,key: String,reason: String):
	var j=active(w,key)
	if not j.is_empty():
		release(w,j)
		j.state="suspended";j.block_reason=reason;j.retry_at=w.tick
		w.job_log.append({"tick":w.tick,"event":"suspended","id":j.id,"worker":key,"reason":reason})
	if w.workers.has(key):w.workers[key].work_status=reason

static func set_priority(w,key: String,kind: String,value: int):
	if not w.workers.has(key) or not Policy.PRIORITIES.has(kind):return
	w.workers[key].work_priorities[kind]=clampi(value,0,3)
	interrupt(w,key,"優先設定を再評価")

static func set_drafted(w,key: String,value: bool):
	if not w.workers.has(key):return
	w.workers[key].drafted=value
	interrupt(w,key,"徴兵中" if value else "仕事に復帰")

static func reason(w,key: String,a) -> String:
	if a.get("dead",false) or a.get("lost",false):return "離脱"
	if a.get("carrier",-1)>=0 or a.get("state","") in ["captured","restrained"]:return "連れ去り・拘束中"
	if a.get("hp",0)<=0 or a.get("state","")!="free":return "負傷・療養中"
	if not a.get("placed",false):return "到着待ち"
	if a.get("drafted",false):return "徴兵中"
	if w.tick<a.get("hurt_until",0):return "被弾から回復中"
	if a.get("danger_near",false):return "近くの敵に対応中"
	if a.get("life_need","")=="food":return "空腹・食事を優先"
	if a.get("resting",false):return "休息中"
	if key=="keeper":
		if w.manual_goal!=null:return "移動指示中"
		if w.jobs_held:
			if w.job_hold_reason in ["danger","rescue","rest_end","travel","manual","auto_rest"]:w.Jobs.hold(w,"")
			else:return "作業停止" if w.job_hold_reason=="explicit" else "休息中"
	return ""

static func missing(w,j) -> bool:
	if j.kind=="collect":
		return w.items_at(j.pos).is_empty() and not w.natural.has(j.pos) and not(j.pos==w.nest and w.eggs>0)
	if w.BUILD.has(j.kind) and j.started:
		var site=w.Buildings.layer(w,j.kind).get(j.pos,{})
		return site.is_empty() or site.get("status") not in ["building","ready"] or (j.has("site_id") and site.get("id")!=j.site_id)
	return false

static func block(w,j,why: String):
	release(w,j)
	j.state="blocked";j.block_reason=why
	j.retry_at=w.tick+ceili(Policy.RETRY_SECONDS/w.DT)

static func allowed(w,key: String,j) -> bool:
	var why=reason(w,key,w.workers[key])
	return why=="" or (j.kind=="move" and why in ["徴兵中","近くの敵に対応中"])

static func claim(w,key: String,j) -> bool:
	if not w.workers.has(key) or j.get("assigned_to","")!="" or not allowed(w,key,j):return false
	var token=target_key(w,j)
	if w.work_claims.has(token):return false
	w.work_claims[token]=j.id;j.assigned_to=key;w.workers[key].work_job=j.id
	return true

static func choose(w,key: String) -> Dictionary:
	var a=w.workers[key]
	var candidates=w.jobs.filter(func(j):return j.get("assigned_to","")=="" and not j.get("cancel_requested",false) and w.tick>=j.get("retry_at",0) and (key=="keeper" or shared(w,j)) and (j.kind=="move" or a.work_priorities.get(category(w,j),3)>0))
	candidates.sort_custom(func(x,y):
		var px=0 if x.kind=="move" else a.work_priorities.get(category(w,x),3)
		var py=0 if y.kind=="move" else a.work_priorities.get(category(w,y),3)
		if px!=py:return px<py
		var dx=w.distance(a.pos,x.pos);var dy=w.distance(a.pos,y.pos)
		return dx<dy if dx!=dy else x.id<y.id)
	for j in candidates:
		if not allowed(w,key,j):continue
		if missing(w,j):w.Jobs.cancel(w,j.id,"target_missing");continue
		if w.BUILD.has(j.kind) and not j.started:
			var why=w.Buildings.reason(w,j.kind,j.pos,false)
			if why!="":block(w,j,why);continue
			var required=j.get("required",j.reserved)
			if j.reserved<required and w.resource_amount(j.resource)<required-j.reserved:block(w,j,"資材不足・採集や入手を待つ");continue
		if not claim(w,key,j):continue
		# Unit 1 retains the existing scalar budget escrow, acquired once, not on registration.
		if w.BUILD.has(j.kind):
			var due=maxi(0,j.get("required",j.reserved)-j.reserved)
			if due>0:w.add_resource(j.resource,-due);j.reserved+=due
		j.state="walking";j.block_reason="";j.phase="move"
		w.job_log.append({"tick":w.tick,"event":"assigned","id":j.id,"worker":key,"category":category(w,j)})
		return j
	return {}

static func step(w):
	var live_ids=w.jobs.map(func(j):return j.id)
	for token in w.work_claims.keys():
		if w.work_claims[token] not in live_ids:w.work_claims.erase(token)
	for a in w.workers.values():
		if a.get("work_job",-1) not in live_ids:a.work_job=-1
	# Recover orphan claims when an actor disappears without a normal completion callback.
	for j in w.jobs.duplicate():
		var owner=j.get("assigned_to","")
		if owner!="" and not w.workers.has(owner):release(w,j);j.state="pending"
		if j.get("cancel_requested",false):w.Jobs.cancel(w,j.id)
		elif missing(w,j):w.Jobs.cancel(w,j.id,"target_missing")
	for key in w.workers:
		var a=w.workers[key];var why=reason(w,key,a)
		if why!="":
			var current=active(w,key)
			if not current.is_empty() and not allowed(w,key,current):interrupt(w,key,why)
			if not w.jobs.any(func(row):return row.kind=="move" and allowed(w,key,row)):interrupt(w,key,why);continue
		var j=active(w,key)
		if j.is_empty():j=choose(w,key)
		if j.is_empty():
			var blocked=w.jobs.filter(func(row):return row.state=="blocked")
			a.work_status="仕事の指定待ち" if w.jobs.is_empty() else (blocked[0].get("block_reason","実行できる仕事を待つ") if not blocked.is_empty() else "担当可能な仕事を待つ")
			continue
		w.Jobs.execute(w,j,a)
		if not w.jobs.has(j):a.work_job=-1;a.work_status="仕事を完了・次を探す";continue
		if j.state=="blocked":
			a.work_status=j.get("block_reason","作業待ち");block(w,j,a.work_status)
		else:
			j.phase="work" if j.state=="working" else "move"
			a.work_status="%s #%d · %s"%[Policy.LABELS[category(w,j)],j.id,"現場で作業中" if j.phase=="work" else "対象へ移動中"]

static func save(w):
	w.campaign.work_profiles={}
	for key in w.workers:
		var a=w.workers[key]
		w.campaign.work_profiles[key]={"priorities":a.work_priorities.duplicate(),"drafted":a.drafted}

static func restore(w):
	register(w,"keeper",w.keeper)
	var profile=w.campaign.get("work_profiles",{}).get("keeper",{})
	for kind in Policy.PRIORITIES:w.keeper.work_priorities[kind]=clampi(int(profile.get("priorities",{}).get(kind,Policy.PRIORITIES[kind])),0,3)
	w.keeper.drafted=profile.get("drafted",false)
	for j in w.jobs:
		j.assigned_to="";j.retry_at=0;j.state="pending"
