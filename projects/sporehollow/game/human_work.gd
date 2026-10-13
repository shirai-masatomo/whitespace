extends RefCounted
## Selection/ownership only. Jobs executes onsite operations; Life owns emergencies/rest.
const Policy=preload("res://game/work_policy.gd")

static func register(w,key: String,actor: Dictionary):
	w.workers[key]=actor
	actor.work_key=key
	migrate_priorities(actor)
	actor.work_job=-1
	actor.work_status="仕事を探しています"
	actor.drafted=actor.get("drafted",false)

static func migrate_priorities(actor: Dictionary):
	if not actor.has("work_priorities"):actor.work_priorities=Policy.PRIORITIES.duplicate();actor.work_priority_version=Policy.PRIORITY_VERSION;return
	var legacy=int(actor.get("work_priority_version",1))<2
	# v3 adds animal work; v2 priorities must not be shifted a second time.
	if not actor.work_priorities.has("animal"):actor.work_priorities.animal=actor.work_priorities.get("other",3 if legacy else 4)
	for kind in Policy.ORDER:
		var value=int(actor.work_priorities.get(kind,Policy.PRIORITIES[kind] if not legacy else 3))
		actor.work_priorities[kind]=clampi(value+1 if legacy and value>0 else value,0,4)
	actor.work_priority_version=Policy.PRIORITY_VERSION

static func category(w,j) -> String:
	return Policy.category(w,j)

static func shared(w,j) -> bool:
	return w.BUILD.has(j.kind) or j.kind in ["collect","haul","slaughter","mine","train","clear_tree"]

static func target_key(w,j) -> String:
	if j.kind in ["slaughter","train"]:return "animal:%d"%j.animal_id
	if j.has("mountain_id"):return j.mountain_id
	if j.kind in ["mine","clear_tree"]:return "%s:%d:%d"%[j.kind,j.pos.x,j.pos.y]
	if j.kind=="haul":return "stock:%d"%j.stock_id
	var layer=w.BUILD[j.kind].get("layer","structure") if w.BUILD.has(j.kind) else j.get("target_layer","collect" if j.kind=="collect" else j.kind)
	return "%s:%d:%d"%[layer,j.pos.x,j.pos.y]

static func active(w,key: String="keeper") -> Dictionary:
	for j in w.jobs:
		if j.get("assigned_to","")==key:return j
	return {}

static func release(w,j):
	w.Stock.release_job(w,j)
	var owner=j.get("assigned_to","")
	for token in w.work_claims.keys():
		if w.work_claims[token]==j.id:w.work_claims.erase(token)
	if w.workers.has(owner) and w.workers[owner].get("work_job",-1)==j.id:w.workers[owner].work_job=-1
	j.assigned_to=""

static func interrupt(w,key: String,reason: String):
	w.Delivery.release(w,key)
	var j=active(w,key)
	if not j.is_empty():
		release(w,j)
		j.state="suspended";j.block_reason=reason;j.retry_at=w.tick
		w.job_log.append({"tick":w.tick,"event":"suspended","id":j.id,"worker":key,"reason":reason})
	if w.workers.has(key):w.workers[key].work_status=reason

static func set_priority(w,key: String,kind: String,value: int):
	if not w.workers.has(key) or not Policy.PRIORITIES.has(kind):return
	w.workers[key].work_priorities[kind]=clampi(value,0,4)
	interrupt(w,key,"優先設定を再評価")

static func set_drafted(w,key: String,value: bool):
	if not w.workers.has(key):return false
	var actor=w.workers[key]
	if value and (not actor.get("placed",false) or actor.get("hp",0)<=0 or actor.get("state","")!="free" or actor.get("forced_rest",false) or actor.get("nutrition_down",false) or actor.get("carrier",-1)>=0):return false
	if value:
		w.Food.interrupt(w,actor)
		if key=="keeper":w.Life.stop_rest_until(w,"drafted");w.Life.set_rest(w,false);actor.erase("pending_command")
		else:actor.resting=false
	actor.drafted=value
	if not value and key=="keeper":
		for j in w.jobs.duplicate():
			if j.get("direct_control",false):w.Jobs.cancel(w,j.id)
	interrupt(w,key,"徴兵中" if value else "仕事に復帰")
	return true

static func reason(w,key: String,a) -> String:
	if a.get("dead",false) or a.get("lost",false):return "離脱"
	if a.get("nutrition_down",false):return "栄養失調・行動不能"
	if a.get("carrier",-1)>=0 or a.get("state","") in ["captured","restrained"]:return "連れ去り・拘束中"
	if a.get("hp",0)<=0 or a.get("state","")!="free":return "負傷・療養中"
	if not a.get("placed",false):return "到着待ち"
	if a.get("resting",false):return "休息中"
	if a.get("drafted",false):return "徴兵中"
	if w.tick<a.get("hurt_until",0):return "被弾から回復中"
	if a.get("danger_near",false):return "近くの敵に対応中"
	if a.get("life_need","")=="food":return "空腹・食事を優先"
	if key=="keeper":
		if w.manual_goal!=null:return "移動指示中"
		if w.jobs_held:
			if w.job_hold_reason in ["danger","rescue","rest_end","travel","manual","auto_rest"]:w.Jobs.hold(w,"")
			else:return "作業停止" if w.job_hold_reason=="explicit" else "休息中"
	return ""

static func missing(w,j) -> bool:
	if j.kind in w.Tasks.KINDS:return w.Tasks.missing(w,j)
	if j.kind=="slaughter":return w.Livestock.missing(w,j)
	if j.kind=="haul":return j.get("haul_sources",[j.get("stock_id",-1)]).all(func(id):return w.Stock.find(w,id).is_empty()) and not w.field_items.any(func(r):return r.get("location")=="carry" and r.get("job_id",-1)==j.id)
	if j.kind=="collect":
		return w.items_at(j.pos).is_empty() and not w.natural.has(j.pos) and not(j.pos==w.nest and w.eggs>0)
	if w.BUILD.has(j.kind) and j.started:
		var site=w.Buildings.layer(w,j.kind).get(j.pos,{})
		return site.is_empty() or site.get("status") not in ["building","ready"] or (j.has("site_id") and site.get("id")!=j.site_id)
	return false

static func block(w,j,why: String):
	if j.get("notified_block","")!=why:
		w.PlayerEvents.add(w,preload("res://game/colony_ui_state.gd").work_name(w,j)+"："+why,"work_block:%d"%j.id);j.notified_block=why
	release(w,j)
	j.state="blocked";j.block_reason=why
	j.retry_at=w.tick+ceili(Policy.RETRY_SECONDS/w.DT)

static func allowed(w,key: String,j) -> bool:
	if j.get("explicit_actor",key)!=key:return false
	if j.get("purpose","")=="merchant":return w.merchant_actor_reason(key)==""
	var why=reason(w,key,w.workers[key])
	return why=="" or (j.kind in ["move","direct_attack"] and why in ["徴兵中","近くの敵に対応中"])

static func claim(w,key: String,j) -> bool:
	var actor=w.workers.get(key,w.merchant_actor(key) if j.get("purpose","")=="merchant" else {})
	if actor.is_empty() or j.get("assigned_to","")!="" or not allowed(w,key,j):return false
	var token=target_key(w,j)
	if w.work_claims.has(token):return false
	w.work_claims[token]=j.id;j.assigned_to=key
	if w.workers.has(key):w.workers[key].work_job=j.id
	return true

static func effort(w,a,j) -> float:
	if w.work_claims.has(target_key(w,j)):return INF
	if w.BUILD.has(j.kind) and w.Delivery.needed(w,j)>0:return INF
	var position=j.pos
	if j.kind in ["train","slaughter"]:
		var animal=w.Orders.animal(w,j.animal_id)
		if animal.is_empty():return INF
		position=animal.pos
	if j.kind=="haul":
		var row=w.Stock.find(w,j.stock_id)
		if row.is_empty():
			var remaining=j.get("haul_sources",[]).map(func(id):return w.Stock.find(w,id)).filter(func(r):return not r.is_empty() and r.location=="ground" and not r.get("forbidden",false))
			if not remaining.is_empty():row=remaining[0];j.stock_id=row.stock_id;j.pos=row.pos
		if row.is_empty() or row.get("forbidden",false):return INF
		var plan=w.Stock.storage_plan(w,a,mini(Policy.CARRY_CAPACITY,w.Stock.free_count(row)),row.kind,j.id)
		if not plan.has("pos"):
			block(w,j,plan.reason);return INF
		position=row.pos
	var goals=w.Mountains.job_goals(w,j) if j.has("mountain_id") else ([position] if j.kind=="move" else w.neighbors(position))
	var route=w.Jobs.path_to(w,a.pos,goals)
	if route.is_empty():
		block(w,j,"岩山へ通じる作業場所がありません" if j.has("mountain_id") else "対象へ通じる通路がありません")
		return INF
	return float(route.size()-1)+minf(20,j.get("remaining",0)*w.DT)

static func score(w,j,efficiency: float) -> float:
	# Waiting grows without a category-position bias, so feasible work cannot starve.
	return efficiency-maxi(0,w.tick-j.get("queued_tick",w.tick))*w.DT*0.08

static func choose(w,key: String) -> Dictionary:
	var a=w.workers[key];var candidates=[]
	for j in w.jobs.duplicate():
		if j.get("assigned_to","")!="" or j.get("cancel_requested",false) or w.tick<j.get("retry_at",0) or j.get("explicit_actor",key)!=key:continue
		if key!="keeper" and not shared(w,j) and j.get("explicit_actor","")!=key:continue
		var priority=0 if j.kind in ["move","direct_attack"] else a.work_priorities.get(category(w,j),0)
		if priority<=0 and j.kind not in ["move","direct_attack"]:continue
		if not allowed(w,key,j):continue
		if missing(w,j):w.Jobs.cancel(w,j.id,"target_missing");continue
		if w.BUILD.has(j.kind) and not j.started:
			var why=w.Buildings.reason(w,j.kind,j.pos,false)
			if why!="" and not (why=="ここに誰かいます" and a.pos==j.pos):block(w,j,why);continue
		var distance=effort(w,a,j)
		if is_inf(distance):continue
		candidates.append({"job":j,"priority":priority,"score":score(w,j,distance)})
	var delivery=w.Delivery.proposal(w,key)
	if not delivery.is_empty() and allowed(w,key,delivery):candidates.append({"job":delivery,"priority":delivery.priority,"score":score(w,delivery,delivery.effort)})
	candidates.sort_custom(func(x,y):return x.priority<y.priority if x.priority!=y.priority else (x.score<y.score if x.score!=y.score else x.job.id<y.job.id))
	for candidate in candidates:
		var j=candidate.job
		if j.kind=="build_delivery":return w.Delivery.start(w,key,j)
		if not claim(w,key,j):continue
		j.state="walking";j.block_reason="";j.phase="move"
		w.job_log.append({"tick":w.tick,"event":"assigned","id":j.id,"worker":key,"category":category(w,j)})
		return j
	return {}

static func step(w):
	w.Stock.step(w)
	w.Delivery.reconcile(w)
	var live_ids=w.jobs.map(func(j):return j.id)
	for token in w.work_claims.keys():
		if w.work_claims[token] not in live_ids:w.work_claims.erase(token)
	for a in w.workers.values():
		if a.get("work_job",-1) not in live_ids:a.work_job=-1
	# Recover orphan claims when an actor disappears without a normal completion callback.
	for j in w.jobs.duplicate():
		if not j.has("queued_tick"):j.queued_tick=w.tick
		j.work_category=category(w,j)
		var owner=j.get("assigned_to","")
		if owner!="" and not w.workers.has(owner) and not(j.get("purpose","")=="merchant" and owner==w.merchant_worker):release(w,j);j.state="pending"
		if j.get("cancel_requested",false):w.Jobs.cancel(w,j.id)
		elif missing(w,j):w.Jobs.cancel(w,j.id,"target_missing")
	for key in w.workers:
		var a=w.workers[key]
		if w.Food.step(w,a):continue
		var why=reason(w,key,a)
		if why!="":
			var current=active(w,key)
			if not current.is_empty() and not allowed(w,key,current):interrupt(w,key,why)
			if not w.jobs.any(func(row):return row.kind in ["move","direct_attack"] and allowed(w,key,row)):interrupt(w,key,why);continue
		if w.build_deliveries.has(key):w.Delivery.step(w,key);continue
		var j=active(w,key)
		if j.is_empty():j=choose(w,key)
		if j.get("kind","")=="build_delivery":w.Delivery.step(w,key);continue
		if j.is_empty():
			var blocked=w.jobs.filter(func(row):return row.state=="blocked")
			a.work_status="仕事の指定待ち" if w.jobs.is_empty() else (blocked[0].get("block_reason","実行できる仕事を待つ") if not blocked.is_empty() else "担当可能な仕事を待つ")
			continue
		w.Jobs.execute(w,j,a)
		if not w.jobs.has(j):a.work_job=-1;a.work_status="仕事を完了・次を探す";continue
		if j.state=="blocked":
			a.work_status=j.get("block_reason","作業待ち");block(w,j,a.work_status)
		else:
			if j.get("phase","") not in ["fetch","deliver"]:j.phase="work" if j.state=="working" else "move"
			a.work_status="%s · %s"%[Policy.LABELS[category(w,j)],{"work":"現場で作業中","fetch":"物資を取りに移動","deliver":"物資を運搬中"}.get(j.phase,"対象へ移動中")]

static func save(w):
	w.campaign.work_profiles={}
	for key in w.workers:
		var a=w.workers[key]
		w.campaign.work_profiles[key]={"priorities":a.work_priorities.duplicate(),"version":Policy.PRIORITY_VERSION,"drafted":a.drafted,"satiety":a.get("satiety",Policy.SATIETY_MAX),"malnutrition":a.get("malnutrition",0.0),"nutrition_down":a.get("nutrition_down",false),"dead":a.get("dead",false),"death_cause":a.get("death_cause","")}

static func restore(w):
	register(w,"keeper",w.keeper)
	var profile=w.campaign.get("work_profiles",{}).get("keeper",{})
	if profile.has("priorities"):
		w.keeper.work_priorities=profile.priorities.duplicate();w.keeper.work_priority_version=profile.get("version",1);migrate_priorities(w.keeper)
	w.keeper.drafted=profile.get("drafted",false)
	w.keeper.satiety=profile.get("satiety",Policy.SATIETY_MAX)
	w.keeper.malnutrition=profile.get("malnutrition",0.0);w.keeper.nutrition_down=profile.get("nutrition_down",false)
	w.keeper.dead=profile.get("dead",false);w.keeper.death_cause=profile.get("death_cause","")
	if w.keeper.dead:w.keeper.state="dead";w.keeper.hp=0
	for j in w.jobs:
		j.assigned_to="";j.delivery_owner="";j.retry_at=0;j.state="pending";j.erase("material_claims");j.erase("storage_target");j.erase("storage_amount")
