extends RefCounted
## Read-only site presentation, shared by world markers and the existing selection card.
const Art=preload("res://game/delivered_art.gd")
const UI=preload("res://game/ui_style.gd")
var signature=[]
var rows={}
var rebuilds=0
func update(w):
	var key=[w.get_instance_id(),w.tick,w.stock_revision,w.next_job_id,w.jobs.size(),w.paused,w.jobs_held]
	if key==signature:return
	signature=key;rows.clear();rebuilds+=1
	var budget=w.Jobs.Reservations.presentation(w).plans
	for j in w.jobs:
		if not w.BUILD.has(j.kind):continue
		var amounts=budget.get(j.id,{"total":0,"usable":0,"waiting_material":false,"unfunded":0})
		rows[j.id]=describe(w,j,amounts.total,amounts.usable,amounts.unfunded)
		rows[j.id].waiting_material=amounts.waiting_material
		rows[j.id].unfunded=amounts.unfunded
		if amounts.waiting_material:rows[j.id].lines.insert(2,"資材待ち：備蓄の未確保分 %d"%amounts.unfunded)

static func describe(w,j,total: int,usable: int,unfunded:int=-1) -> Dictionary:
	var required=int(j.get("required",w.BUILD[j.kind].cost))
	var missing=maxi(0,required-usable)
	var stage="empty"
	if j.get("started",false):stage="working"
	elif missing==0:stage="ready"
	elif total>0 or j.get("delivery_owner","")!="":stage="partial"
	var name=w.Buildings.NAMES.get(j.kind,"建築")
	var material={"soil":"土","wood":"木材","stone":"石材"}.get(j.resource,j.resource)
	var phase={"empty":"搬入待ち","partial":"資材搬入中","ready":"搬入完了・施工待ち","working":"施工中"}[stage]
	var progress=clampf(1.0-float(j.get("remaining",0))/maxf(1,ceil(w.BUILD[j.kind].seconds/w.DT)),0,1) if stage=="working" else 0.0
	var materials=[]
	var lines=[name,"状態："+phase]
	for kind in w.Buildings.Cost.materials(w,j.kind,j):
		var amount=w.Buildings.Cost.materials(w,j.kind,j)[kind];var arrived=w.Buildings.Cost.onsite(w,j,kind,true);var usable_amount=w.Buildings.Cost.onsite(w,j,kind)
		if arrived>0:materials.append(kind)
		lines.append("%s：搬入%d / 必要%d　不足%d"%[preload("res://game/item_catalog.gd").title(kind),arrived,amount,maxi(0,amount-usable_amount)])
	lines.append("搬入済み：%d / %d　不足：%d"%[total,required,missing])
	if total>usable:lines.append("搬入済みのうち禁止中：%d"%(total-usable))
	if stage=="working":lines.append("施工進捗：%d%%"%roundi(progress*100))
	var reason=j.get("block_reason","")
	if unfunded==0 and reason=="資材待ち：備蓄に使える資材がありません":reason=""
	if stage=="ready" and not w.Delivery.can_build(j):reason=w.Delivery.GROUP_WAIT
	if reason=="" and j.get("assigned_to","")=="" and j.get("delivery_owner","")=="":
		var category="haul" if missing>0 else "build"
		if not w.workers.values().any(func(a):return a.get("work_priorities",{}).get(category,0)>0 and not a.get("dead",false)):
			reason="資材搬入の担当設定がありません" if category=="haul" else "建築の担当設定がありません"
		elif stage=="ready":reason="施工担当の割当待ち"
	if j.get("cancel_requested",false):reason="取消待ち"
	elif w.jobs_held:reason="作業保留中"+("／"+reason if reason!="" else "")
	if reason!="":
		var text="待機理由："+reason
		while text.length()>24:lines.append(text.substr(0,24));text=text.substr(24)
		lines.append(text)
	return {"materials":materials,"name":name,"stage":stage,"phase":phase,"required":required,"delivered":total,"usable":usable,"missing":missing,"progress":progress,"resource":j.resource,"lines":lines}

static func panel_rect(lines: Array) -> Rect2:
	return Rect2(16,mini(595,690-28-lines.size()*24),422,28+lines.size()*24)

static func draw(c,q: Vector2,row: Dictionary):
	var stage=row.stage
	if stage!="working":
		for x in [-18,18]:c.draw_line(q+Vector2(x,11),q+Vector2(x,-12),Color("bdac7a"),3)
	if row.delivered>0:
		# Reuse adopted square resource art; no generated or stretched material sprites.
		var materials=row.get("materials",[row.resource])
		for i in range(materials.size()):
			var size=24 if materials.size()==1 else 20
			c.draw_texture_rect(Art.RESOURCES[materials[i]][24],Rect2(q+Vector2(-size/2.0+(i-(materials.size()-1)*0.5)*20,-5),Vector2(size,size)),false)
	if stage=="ready":
		c.draw_rect(Rect2(q-Vector2(20,15),Vector2(40,30)),Color("d9bb70"),false,2)
		c.draw_texture_rect(UI.icon("check"),Rect2(q+Vector2(7,-15),Vector2(12,12)),false)
	elif stage=="working":
		for x in [-20,20]:c.draw_line(q+Vector2(x,12),q+Vector2(x,-20),Color("bdac7a"),2)
		c.draw_line(q+Vector2(-20,-14),q+Vector2(20,-14),Color("bdac7a"),2)
		c.draw_rect(Rect2(q+Vector2(-18,16),Vector2(36,4)),Color("384738"))
		c.draw_rect(Rect2(q+Vector2(-18,16),Vector2(36*row.progress,4)),Color("b2ebcf"))
