extends RefCounted
const Data=preload("res://game/crafting_data.gd")
const Cultivation=preload("res://game/cultivation.gd")
const Catalog=preload("res://game/item_catalog.gd")
static func valid(w,j)->bool:
	var b=w.structures.get(j.pos,{})
	return b.get("id")==j.bench_id and b.get("status")=="ready" and b.get("kind")==Data.RECIPES[j.recipe].bench
static func enqueue(w,p:Vector2i,recipe:String,mode:String,amount:int)->bool:
	if not w.working() or not Data.RECIPES.has(recipe) or mode not in ["count","stock"] or amount<1 or amount>100 or w.jobs.size()>=w.Jobs.LIMIT:return false
	p=w.Buildings.anchor(w,p)
	var b=w.structures.get(p,{})
	if b.get("status")!="ready" or b.get("kind")!=Data.RECIPES[recipe].bench:return false
	if recipe=="grow_mushroom" and w.jobs.any(func(other):return other.kind=="craft" and other.get("bench_id",-1)==b.id):return false
	var j={"id":w.next_job_id,"kind":"craft","pos":p,"bench_id":b.id,"recipe":recipe,"bill_mode":mode,"bill_amount":amount,"made":0,"craft_progress":0.0,"animal_id":-1,"state":"pending","resource":"","reserved":0,"started":false,"work_category":"other"}
	w.jobs.append(j);w.next_job_id+=1;w.Life.wake_auto(w);return true
static func token(j)->String:return "craft:%d"%j.id
static func holding(w,j,kind:String)->int:
	var n=0
	for r in w.field_items:
		if r.kind!=kind or r.get("forbidden",false):continue
		if r.get("job_id",-1)==j.id and (r.location=="site" or r.get("craft_transfer",false)):n+=r.amount
		else:n+=r.claims.get(token(j),0)
	return n
static func remaining_stock(w,j)->int:
	var key=[w.tick,w.stock_revision,w.craft_revision,w.jobs.size()]
	if w.craft_stock_cache.get("key",[])!=key:
		var counts={}
		for r in w.field_items:
			if not r.get("forbidden",false) and not r.get("placed",false):counts[r.kind]=counts.get(r.kind,0)+r.amount
		for other in w.jobs:
			if other.kind=="craft" and other.get("batch_active",false):
				var rec=Data.RECIPES[other.recipe];counts[rec.output]=counts.get(rec.output,0)+rec.count
		w.craft_stock_cache={"key":key,"counts":counts}
	var recipe=Data.RECIPES[j.recipe]
	return maxi(0,j.bill_amount-w.craft_stock_cache.counts.get(recipe.output,0)+(recipe.count if j.get("batch_active",false) else 0))
static func ready(w,j)->bool:
	if j.recipe=="grow_mushroom" and valid(w,j) and not w.structures[j.pos].get("culture",{}).is_empty():return w.tick>=int(w.structures[j.pos].culture.ready_tick)
	return j.get("batch_active",false) or j.bill_mode=="count" or remaining_stock(w,j)>0
static func prepare(w,j,a)->bool:
	var rec=Data.RECIPES[j.recipe];var changed=false
	for r in w.field_items:
		if r.get("craft_transfer",false) and r.job_id==j.id and not w.Access.can_take(w,r,a):
			j.state="blocked";j.block_reason="中断した材料の持出し権限がありません";return false
	for row in w.field_items:
		if row.claims.get(token(j),0)>0 and not w.Access.can_take(w,row,a):row.claims.erase(token(j));changed=true
	for kind in rec.ingredients:
		var need=rec.ingredients[kind]-holding(w,j,kind)
		if need<=0:continue
		var requested=need
		var rows=w.field_items.filter(func(r):return r.kind==kind and w.Stock.stored(w,r) and w.Stock.eligible(w,r) and w.Access.can_take(w,r,a))
		rows.sort_custom(func(x,y):return w.distance(a.pos,x.pos)<w.distance(a.pos,y.pos))
		for r in rows:
			if w.Jobs.path_to(w,a.pos,w.neighbors(r.pos)+[r.pos]).is_empty():continue
			changed=true
			var n=mini(need,w.Stock.free_count(r));r.claims[token(j)]=r.claims.get(token(j),0)+n;need-=n
			if need<=0:break
		if need>0:
			w.Stock.release_token(w,token(j));j.state="blocked";j.block_reason=material_reason(w,kind,a,requested);return false
	if not j.get("batch_active",false):w.craft_revision+=1
	j.batch_active=true
	if changed:w.Stock.sync(w)
	return true
static func cancel(w,j):
	w.craft_revision+=1
	w.Stock.release_token(w,token(j))
	for r in w.field_items:
		if r.get("job_id",-1)!=j.id:continue
		if r.location=="carry" and w.workers.has(r.owner):r.pos=w.workers[r.owner].pos
		r.location="ground";r.owner="";r.job_id=-1;r.stocked=false;r.erase("craft_transfer")
	w.Stock.sync(w)
static func step(w,j,a):
	if not valid(w,j):cancel(w,j);w.Jobs.complete(w,j,false);return
	if Cultivation.harvest(w,j,a):return
	if not ready(w,j):w.Work.release(w,j);j.state="pending";j.block_reason="目標在庫を満たしています";return
	if not prepare(w,j,a):return
	var carried=w.Stock.cargo(w,a.work_key,j.id)
	if not carried.is_empty():
		j.phase="deliver"
		if not w.Jobs.walk(w,j,w.Buildings.job_goals(w,j),a):return
		for r in carried:r.location="site";r.pos=j.pos;r.owner="";r.erase("craft_transfer")
		w.Stock.sync(w);return
	# Recover interrupted cargo at its real location before claiming replacement ingredients.
	var sources=w.field_items.filter(func(r):return not r.get("forbidden",false) and r.location=="ground" and (r.claims.get(token(j),0)>0 or (r.get("craft_transfer",false) and r.job_id==j.id)))
	if not sources.is_empty():
		var r=sources[0];j.phase="fetch"
		if not w.Jobs.walk(w,j,w.neighbors(r.pos)+([r.pos] if a.pos==r.pos else []),a):return
		var reserved=r.claims.get(token(j),r.amount if r.get("craft_transfer",false) else 0)
		var n=mini(reserved,w.Stock.carry_free(w,a.work_key))
		if n<=0:j.state="blocked";j.block_reason="携行品を下ろす必要があります";return
		r.claims[token(j)]=n
		var cargo=w.Stock.pickup(w,r,token(j),a,j.id)
		if cargo.is_empty():return
		cargo.craft_transfer=true
		if r.amount>0 and reserved>n:r.claims[token(j)]=reserved-n
		return
	var rec=Data.RECIPES[j.recipe]
	for kind in rec.ingredients:
		var onsite=0
		for r in w.field_items:
			if r.location=="site" and r.job_id==j.id and r.kind==kind and not r.get("forbidden",false):onsite+=r.amount
		if onsite<rec.ingredients[kind]:j.state="blocked";j.block_reason="搬入した材料を確認しています";return
	if not w.Jobs.walk(w,j,w.Buildings.job_goals(w,j),a):return
	j.phase="work";j.state="working";j.started=true;j.block_reason="";j.craft_progress+=w.DT*w.Jobs.factor(a)
	if j.craft_progress<rec.seconds:return
	var drop=a.pos if rec.has("grow_seconds") else output_cell(w,j,a,rec.count)
	if drop==null:j.state="blocked";j.block_reason="完成品の置き場が満杯です。周囲の物資を回収してください";return
	for kind in rec.ingredients:
		var left=rec.ingredients[kind]
		for r in w.field_items.duplicate():
			if r.location!="site" or r.job_id!=j.id or r.kind!=kind or r.get("forbidden",false):continue
			var used=mini(left,r.amount);r.amount-=used;left-=used;w.stock_used[kind]=w.stock_used.get(kind,0)+used
			if r.amount==0:w.field_items.erase(r)
			if left==0:break
	if Cultivation.seed(w,j):return
	w.Stock.add(w,rec.output,rec.count,drop).stocked=false
	j.made+=rec.count;j.craft_progress=0.0;j.started=false;j.batch_active=false;w.craft_revision+=1
	w.PlayerEvents.add(w,Catalog.title(rec.output)+"を製作しました","craft:%d"%j.id)
	if j.bill_mode=="count" and j.made>=j.bill_amount:cancel(w,j);w.Jobs.complete(w,j,true)
	else:w.Work.release(w,j);j.state="pending"
static func summary(w,j)->String:
	if j.recipe=="grow_mushroom" and valid(w,j) and not w.structures[j.pos].get("culture",{}).is_empty():return Cultivation.summary(w,j)
	var rec=Data.RECIPES[j.recipe];var parts=[]
	for kind in rec.ingredients:
		var onsite=0
		for r in w.field_items:
			if r.location=="site" and r.job_id==j.id and r.kind==kind and not r.get("forbidden",false):onsite+=r.amount
		parts.append("%s 搬入%d/%d・確保%d"%[Catalog.title(kind),onsite,rec.ingredients[kind],holding(w,j,kind)])
	var state=j.get("block_reason","")
	if state=="":
		state="目標在庫を満たしています" if not ready(w,j) else (("植菌中" if j.recipe=="grow_mushroom" else "製作中") if j.get("phase")=="work" else "材料搬入" if j.get("phase") in ["fetch","deliver"] else "担当者待ち")
	return "%s · %s%d・完成%d · %d%%\n%s\n%s"%[Catalog.title(rec.output),"指定" if j.bill_mode=="count" else "在庫目標",j.bill_amount,j.made,mini(100,int(j.craft_progress/rec.seconds*100))," / ".join(parts),state]

static func material_reason(w,kind:String,a,requested:int=1) -> String:
	var physical=w.field_items.filter(func(r):return r.kind==kind and r.pos in w.storage_cells and r.get("stocked",false) and r.get("location")=="ground")
	var title=Catalog.title(kind)
	if physical.is_empty():return "資材待ち：備蓄に"+title+"がありません"
	if physical.all(func(r):return r.get("forbidden",false)):return "資材待ち："+title+"は禁止中です"
	var allowed=physical.filter(func(r):return not r.get("forbidden",false) and w.Access.can_take(w,r,a))
	if allowed.is_empty():return "資材待ち："+title+"の持出し権限がありません"
	if allowed.all(func(r):return w.Stock.free_count(r)<=0):return "資材待ち："+title+"は他の仕事が確保しています"
	var usable=allowed.filter(func(r):return w.Stock.stored(w,r) and not r.get("placed",false) and not r.get("craft_transfer",false))
	if usable.is_empty():return "資材待ち：備蓄の受入設定では"+title+"を利用できません"
	var free=0
	for r in usable:free+=w.Stock.free_count(r)
	if free<requested:return "資材待ち：%s不足（必要%d／利用可能%d）"%[title,requested,free]
	return "資材待ち："+title+"の備蓄へ通じる通路がありません"

static func output_cell(w,j,a,amount:int):
	# Completion only: bounded adjacent search, not a global stock scan every frame.
	for p in [a.pos]+w.Buildings.job_goals(w,j)+[j.pos]:
		if not w.inside(p):continue
		if p in w.storage_cells and w.Stock.storage_free(w,p)<amount:continue
		return p
	return null
