extends RefCounted
## Physical, per-designation claims. No stock is consumed until construction finishes.
static func token(j) -> String:return "plan:%d"%j.id
static func held(row,j) -> int:return int(row.get("claims",{}).get(token(j),0))
static func source(w,row,j) -> bool:
	if row.get("construction_transfer",false) and row.get("job_id",-1)!=j.id:return false
	return row.kind==j.resource and row.get("location")=="ground" and not row.get("forbidden",false) and not row.get("placed",false) and not row.get("craft_transfer",false) and (w.Stock.stored(w,row) or (row.get("construction_transfer",false) and row.get("job_id",-1)==j.id))
static func usable(w,row,j) -> int:
	return w.Stock.free_count(row)+held(row,j) if source(w,row,j) else 0
static func available(w,kind: String) -> int:
	var count=0
	for row in w.field_items:
		if row.kind==kind and w.Stock.stored(w,row) and not row.get("placed",false) and not row.get("construction_transfer",false) and not row.get("craft_transfer",false):count+=w.Stock.free_count(row)
	return count
static func shortage(w,kind: String,held_cost:int=0,budget:int=-1) -> String:
	var data=w.BUILD[kind];var resource=data.get("resource","soil")
	var required=int(data.cost)+held_cost;var count=available(w,resource) if budget<0 else budget
	if count>=required:return ""
	return "資材不足：%s不足（必要%d／利用可能%d）"%[{"soil":"土","wood":"木材","stone":"石材"}.get(resource,resource),required,count]
static func claim(w,j) -> bool:
	w.Stock.release_token(w,token(j))
	var left=int(j.required)
	for row in w.field_items:
		if not source(w,row,j) or not w.Stock.stored(w,row):continue
		var n=mini(left,w.Stock.free_count(row))
		if n<=0:continue
		row.claims[token(j)]=n;left-=n
		if left==0:break
	if left>0:w.Stock.release_token(w,token(j));return false
	w.Stock.sync(w);return true
static func transfer(w,row,j,delivery_token:String,n:int):
	var owned=mini(n,held(row,j))
	if owned>0:
		row.claims[token(j)]-=owned
		if row.claims[token(j)]==0:row.claims.erase(token(j))
	# Replacement stock must not leave an unreachable old claim reserved as well.
	var replacement=n-owned
	for old in w.field_items:
		if replacement<=0:break
		if old==row:continue
		var released=mini(replacement,held(old,j))
		if released<=0:continue
		old.claims[token(j)]-=released;replacement-=released
		if old.claims[token(j)]==0:old.claims.erase(token(j))
	row.claims[delivery_token]=row.claims.get(delivery_token,0)+n
static func return_claim(w,delivery_token:String,j):
	for row in w.field_items:
		var n=int(row.get("claims",{}).get(delivery_token,0))
		row.get("claims",{}).erase(delivery_token)
		if n>0 and not j.is_empty() and j.get("plan_claimed",false) and source(w,row,j):row.claims[token(j)]=held(row,j)+n
	w.Stock.sync(w)
static func reject(w,kind:String,why:String):
	var message=w.Buildings.NAMES.get(kind,kind)+"を建築できません："+why
	w.say(message);w.PlayerEvents.add(w,message)

static func place_available(w,kind:String) -> int:
	var count=0
	for row in w.field_items:
		if row.kind==kind and w.Stock.stored(w,row) and not row.get("placed",false):count+=w.Stock.free_count(row)
	for j in w.jobs:
		if j.kind=="place_"+kind and not j.get("plan_claimed",false):count-=1
	return maxi(0,count)
static func consume_place(w,j) -> bool:
	for row in w.field_items.duplicate():
		if held(row,j)>0 and source(w,row,j) and w.Access.can_take(w,row,w.workers.get(j.get("assigned_to","keeper"),w.keeper)):
			row.claims[token(j)]-=1;row.amount-=1
			if row.claims[token(j)]==0:row.claims.erase(token(j))
			if row.amount==0:w.field_items.erase(row)
			w.stock_used[row.kind]=w.stock_used.get(row.kind,0)+1;w.Stock.sync(w);return true
	return false

# Read-only display allocation: each physical unit covers at most one plan.
# Linear stock/job scan, shared by committed-site cards and draft previews.
static func presentation(w) -> Dictionary:
	var budget={};var site={};var owned={};var totals={}
	for row in w.field_items:
		var id=int(row.get("job_id",-1));var kind=row.kind
		if row.get("location")=="site":
			totals[id]=totals.get(id,0)+int(row.amount)
			if not row.get("forbidden",false):site[id]=site.get(id,0)+int(row.amount)
		elif row.get("construction_transfer",false):
			if not row.get("forbidden",false):owned[id]=owned.get(id,0)+int(row.amount)
		elif w.Stock.stored(w,row) and not row.get("placed",false) and not row.get("craft_transfer",false):
			budget[kind]=budget.get(kind,0)+w.Stock.free_count(row)
			if row.get("forbidden",false):continue
			for key in row.get("claims",{}):
				if key.begins_with("plan:") or key.begins_with("construction:"):
					var owner=int(key.get_slice(":",key.get_slice_count(":")-1))
					owned[owner]=owned.get(owner,0)+int(row.claims[key])
	var plans={}
	for j in w.jobs:
		if not w.BUILD.has(j.kind):continue
		var missing=maxi(0,int(j.get("required",w.BUILD[j.kind].cost))-int(site.get(j.id,0)))
		var needed=maxi(0,missing-int(owned.get(j.id,0)))
		var free=int(budget.get(j.resource,0));var covered=mini(needed,free)
		if j.get("cancel_requested",false):covered=needed
		else:budget[j.resource]=free-covered
		plans[j.id]={"waiting_material":covered<needed,"unfunded":needed-covered,"total":int(totals.get(j.id,0)),"usable":int(site.get(j.id,0)),"missing":missing}
	return {"plans":plans,"remaining":budget}
