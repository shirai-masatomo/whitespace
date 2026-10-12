extends RefCounted
# Small provisional extensions of the existing designation/work/physical-stock loop.
const ROCK_COUNT=4
const STONE_PER_ROCK=8
const MINE_SECONDS=4.0
const TRAIN_SECONDS=4.0
const TRAIN_GAIN=5
const TRAIN_SPECIES=["shiba","doberman"]
const KINDS=["mine","train","clear_tree"]

static func init(w):
	w.rocks={}
	w.mined_rock_cells=w.campaign.get("mined_rock_cells",[]).map(func(p):return Vector2i(p[0],p[1]))
	if w.campaign.has("mining_rocks"):
		for saved in w.campaign.mining_rocks:
			var row=saved.duplicate(true);var p=Vector2i(row.pos[0],row.pos[1]);row.erase("pos")
			if w.inside(p) and row.get("amount",0)>0:w.rocks[p]=row
		return
	if w.campaign.get("biome_new_map",false):return
	var sites=[]
	for y in range(2,w.H-2):
		for x in range(2,w.W-2):
			var p=Vector2i(x,y);var d=w.distance(w.keeper.pos,p)
			if d<4 or d>12 or not w.walkable(p) or w.occupied(p) or w.live_structure(p) or w.natural.has(p) or w.floors.has(p) or p in w.entries or p==w.logistics_entry or p in w.Story.idol_cells(w):continue
			if w.field_items.any(func(row):return row.pos==p) or w.jobs.any(func(j):return j.pos==p) or p in w.storage_cells:continue
			sites.append(p)
	var rng=RandomNumberGenerator.new();rng.seed=w.seed_value*619+409
	for i in range(mini(ROCK_COUNT*4,sites.size())):
		if w.rocks.size()>=ROCK_COUNT:break
		var index=rng.randi_range(0,sites.size()-1);var p=sites[index];sites.remove_at(index)
		if w.Jobs.path_to(w,w.keeper.pos,w.neighbors(p).filter(func(c):return w.walkable(c))).is_empty():continue
		w.rocks[p]={"amount":STONE_PER_ROCK,"forbidden":false}
	# An empty/depleted list is a real saved result, never a signal to respawn rocks.
	save(w)

static func save(w):
	w.Mountains.save(w)
	w.campaign.mined_rock_cells=w.mined_rock_cells.map(func(p):return [p.x,p.y])
	w.campaign.mining_rocks=[]
	for p in w.rocks:
		var row=w.rocks[p].duplicate(true);row.pos=[p.x,p.y];w.campaign.mining_rocks.append(row)

static func job(w,kind: String,p: Vector2i=Vector2i.ZERO,id: int=-1) -> Dictionary:
	if kind=="mine":p=w.Mountains.canonical(w,p)
	for j in w.jobs:
		if j.kind==kind and (j.animal_id==id if kind=="train" else j.pos==p):return j
	return {}

static func training_reason(w,a: Dictionary,own_job: int=-1) -> String:
	if not w.Livestock.owned(w,a):return "所有している犬を選んでください"
	if a.species not in TRAIN_SPECIES or a.get("category","")=="human":return "調教は柴犬・ドーベルマンが対象です"
	if a.get("dead",false) or a.get("lost",false) or a.get("hp",0)<=0:return "生きている犬が対象です"
	if a.get("forbidden",false):return "この動物の作業は禁止中です"
	if not a.get("placed",false):return "動物の入場を待っています"
	if a.get("abductor",-1)>=0 or a.get("carrier",-1)>=0 or a.get("restrainer",-1)>=0 or a.get("state","") in ["captured","restrained","unconscious"]:return "拘束・運搬・気絶中は調教できません"
	if not w.available(a):return "動物の回復を待っています"
	if a.get("loyalty",0)>=100:return "基礎忠誠は上限の100です"
	if a.get("last_training_day",-1)>=w.last_daily_day:return "今日は調教済みです（1日1回・仮）"
	for other in w.jobs:
		if other.id==own_job or other.get("cancel_requested",false):continue
		if other.get("animal_id",-1)==a.id or other.get("targets",[]).any(func(t):return t.get("id",-1)==a.id and not t.get("done",false)):return "対象には別の動物作業が予約されています"
	return ""

static func reason(w,kind: String,p: Vector2i=Vector2i.ZERO,id: int=-1,own_job: int=-1) -> String:
	if kind=="clear_tree":return w.Harvest.tree_reason(w,p,own_job)
	if kind=="train":return training_reason(w,w.Orders.animal(w,id),own_job)
	if kind!="mine":return "対応する作業ではありません"
	var mountain=w.Mountains.resource(w,p)
	if not mountain.is_empty():
		if mountain.remaining<=0:return "採掘済みです"
		if mountain.forbidden:return "この岩山の採掘は禁止中です"
		if w.jobs.any(func(j):return j.id!=own_job and j.get("mountain_id","")==mountain.id):return "採掘は予約済みです"
		return ""
	if not w.inside(p) or not w.rocks.has(p) or w.rocks[p].get("amount",0)<=0:return "採掘する岩がありません"
	if w.rocks[p].get("forbidden",false):return "この岩の採掘は禁止中です"
	if w.live_structure(p):return "先に岩の上の建物を片づけてください"
	if w.jobs.any(func(j):return j.id!=own_job and j.kind=="mine" and j.pos==p):return "採掘は予約済みです"
	return ""

static func designate(w,kind: String,p: Vector2i=Vector2i.ZERO,id: int=-1) -> bool:
	if not w.working() or w.jobs.size()>=w.Jobs.LIMIT or reason(w,kind,p,id)!="":return false
	if kind=="mine":p=w.Mountains.canonical(w,p)
	if kind=="train":p=w.Orders.animal(w,id).pos
	var j={"id":w.next_job_id,"kind":kind,"pos":p,"animal_id":id,"state":"pending","resource":"","reserved":0,"started":false,"work_category":"gather" if kind in ["mine","clear_tree"] else "animal","work_elapsed":0.0,"explicit_designation":true}
	if kind=="mine" and not w.Mountains.resource(w,p).is_empty():j.mountain_id=w.Mountains.resource(w,p).id
	if kind=="clear_tree":j.world_target=w.trees[p]
	j.queued_tick=w.tick
	w.next_job_id+=1;w.jobs.append(j);w.Life.wake_auto(w)
	w.job_log.append({"tick":w.tick,"event":"queued","id":j.id,"kind":kind,"pos":[p.x,p.y],"animal_id":id})
	return true

static func set_forbidden(w,kind: String,p: Vector2i,id: int,value: bool) -> bool:
	if kind=="clear_tree":
		if not w.trees.has(p):return false
		w.Harvest.target(w,kind,p).forbidden=value;w.Harvest.save(w)
	elif kind=="mine":
		var r=w.Mountains.resource(w,p)
		if not r.is_empty():r.forbidden=value;p=r.pos
		elif w.rocks.has(p):w.rocks[p].forbidden=value
		else:return false
		save(w)
	elif kind=="train":
		var a=w.Orders.animal(w,id)
		if not w.Livestock.owned(w,a):return false
		a.forbidden=value;w.Livestock.persist_flags(w,a)
	else:return false
	var j=job(w,kind,p,id)
	if not j.is_empty():
		if value:w.Work.block(w,j,"対象の作業は禁止中です")
		else:j.retry_at=w.tick
	return true

static func missing(w,j) -> bool:
	if j.has("mountain_id"):return w.mountains.get(j.mountain_id,{}).get("remaining",0)<=0
	if j.kind=="clear_tree":return not w.trees.has(j.pos) or w.trees[j.pos]!=j.get("world_target",w.trees[j.pos])
	if j.kind=="mine":return not w.rocks.has(j.pos) or w.rocks[j.pos].get("amount",0)<=0
	var a=w.Orders.animal(w,j.animal_id)
	return not w.Livestock.owned(w,a) or a.get("dead",false) or a.get("lost",false) or a.get("hp",0)<=0

static func held(w,a) -> bool:
	var j=job(w,"train",Vector2i.ZERO,a.id)
	if j.is_empty() or not j.get("started",false) or j.get("cancel_requested",false):return false
	var actor=w.workers.get(j.get("assigned_to",""),{})
	return not actor.is_empty() and actor.get("hp",0)>0 and actor.get("state","")=="free" and not actor.get("resting",false) and w.distance(actor.pos,a.pos)<=1 and training_reason(w,a,j.id)==""

static func execute(w,j,actor):
	if j.kind in w.Harvest.KINDS:
		if j.get("cancel_requested",false):w.Jobs.cancel(w,j.id);return
		w.Harvest.execute(w,j,actor);return
	if j.kind not in KINDS or not j.get("explicit_designation",false) or j.get("cancel_requested",false):w.Jobs.cancel(w,j.id);return
	if missing(w,j):w.Jobs.complete(w,j,false);return
	var why=reason(w,j.kind,j.pos,j.animal_id,j.id)
	if why!="":j.state="blocked";j.block_reason=why;return
	if j.kind=="train":j.pos=w.Orders.animal(w,j.animal_id).pos
	if not w.Jobs.walk(w,j,w.neighbors(j.pos),actor):return
	j.started=true;j.state="working";j.phase="work";j.work_elapsed+=w.DT*w.Jobs.factor(actor)
	if j.work_elapsed<TRAIN_SECONDS:return
	if reason(w,j.kind,j.pos,j.animal_id,j.id)!="":j.state="blocked";j.block_reason=reason(w,j.kind,j.pos,j.animal_id,j.id);return
	var a=w.Orders.animal(w,j.animal_id);var before=a.loyalty
	a.loyalty=mini(100,a.loyalty+TRAIN_GAIN);a.last_training_day=w.last_daily_day
	for owned in w.campaign.animals:
		if owned.id==a.id:owned.loyalty=a.loyalty;owned.last_training_day=a.last_training_day
	w.PlayerEvents.add(w,w.animal_name(a)+"の調教完了：基礎忠誠 %d → %d"%[before,a.loyalty],"train_done:%d"%j.id)
	w.Jobs.complete(w,j,true)
