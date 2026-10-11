extends RefCounted
# One provisional weapon demonstrates physical equipment and a different attack reach.
const STAFF="wood_staff"
static func profile(a) -> Dictionary:
	return {"name":"木の長柄・突き","range":2,"damage":3,"interval":1.8} if a.get("equipment",{}).get("item_id","")==STAFF else {"name":"素手","range":1,"damage":2,"interval":1.5}
static func enemy(w,id: int) -> Dictionary:
	for e in w.enemies:
		if e.id==id:return e
	return {}
static func valid(e) -> bool:return not e.is_empty() and not e.done and not e.flee and e.hp>0
static func in_range(w,a,e) -> bool:
	var d=e.pos-a.pos
	return valid(e) and maxi(absi(d.x),absi(d.y))<=profile(a).range and w.line_of_sight(a.pos,e.pos)
static func attack(w,a,e) -> bool:
	if not in_range(w,a,e) or w.tick<a.next_attack or not w.Combat.pay(a,"attack"):return false
	var p=profile(a);a.next_attack=w.tick+ceili(p.interval/w.Jobs.factor(a)/w.DT)
	w.Progression.enemy_hurt(w,e,p.damage)
	w.combat_log.append({"tick":w.tick,"source":"keeper","id":-1,"target":e.id,"damage":p.damage,"method":p.name})
	if e.hp==0 and w.stage==1 and e.id==0:w.drop_blueprint(e.pos)
	return true
static func designate(w,id: int) -> bool:
	var e=enemy(w,id);var a=w.keeper
	if not w.working() or not a.get("drafted",false) or not w.Life.able(w) or not valid(e):return false
	for old in w.jobs.duplicate():
		if old.get("direct_control",false):w.Jobs.cancel(w,old.id)
	if w.jobs.size()>=w.Jobs.LIMIT:return false
	w.Work.interrupt(w,"keeper","指定した敵へ向かいます")
	w.jobs.append({"id":w.next_job_id,"kind":"direct_attack","enemy_id":id,"animal_id":-1,"pos":e.pos,"state":"pending","resource":"","reserved":0,"started":false,"direct_control":true,"work_category":"other"})
	w.next_job_id+=1;w.manual_goal=null;return true
static func equip(w,item: String) -> bool:
	var a=w.keeper
	if not w.working() or a.get("drafted",false) or not w.Life.able(w) or item not in [STAFF,"unequip"] or w.jobs.size()>=w.Jobs.LIMIT:return false
	if w.jobs.any(func(j):return j.kind=="keeper_equipment"):return false
	if item=="unequip" and a.get("equipment",{}).is_empty():return false
	if item!= "unequip" and w.Stock.available(w,item)<1:return false
	w.jobs.append({"id":w.next_job_id,"kind":"keeper_equipment","animal_id":-1,"item_id":item,"expected_equipment":a.get("equipment",{}).duplicate(true),"pos":a.pos,"state":"pending","resource":"","reserved":0,"started":false,"work_category":"other"})
	w.next_job_id+=1;w.Life.wake_auto(w);return true
static func execute(w,j,a):
	if j.kind=="keeper_equipment":equip_step(w,j,a);return
	var e=enemy(w,j.enemy_id)
	if not valid(e) or not a.get("drafted",false):w.Jobs.complete(w,j,true);return
	j.pos=e.pos
	if in_range(w,a,e):
		j.state="working";attack(w,a,e)
		if not valid(e):w.Jobs.complete(w,j,true)
		return
	var goals=[];var reach=profile(a).range
	for y in range(-reach,reach+1):
		for x in range(-reach,reach+1):
			var p=e.pos+Vector2i(x,y)
			if p!=e.pos and w.inside(p) and w.walkable(p) and w.line_of_sight(p,e.pos):goals.append(p)
	w.Jobs.walk(w,j,goals,a)
static func equip_step(w,j,a):
	if a.get("equipment",{})!=j.expected_equipment:w.Jobs.complete(w,j,false);return
	var cargo=w.Stock.cargo(w,a.work_key,j.id)
	if cargo.any(func(row):return row.get("forbidden",false)):w.Work.block(w,j,"装備は禁止中です");return
	if j.item_id!="unequip" and cargo.is_empty():
		var token="job:%d"%j.id
		if j.get("material_claims",[]).is_empty():j.material_claims=w.Stock.reserve(w,j.item_id,1,token,a)
		if j.material_claims.is_empty():j.state="blocked";j.block_reason="届く場所に装備がありません";return
		var row=w.Stock.find(w,j.material_claims[0].stock_id)
		if row.is_empty() or row.get("forbidden",false) or row.claims.get(token,0)<1:w.Stock.release_token(w,token);j.erase("material_claims");j.state="blocked";j.block_reason="予約した装備が使えません";return
		j.phase="fetch"
		if w.Jobs.walk(w,j,w.neighbors(row.pos),a):w.Stock.pickup(w,row,token,a,j.id);j.erase("material_claims")
		return
	if not a.get("equipment",{}).is_empty():w.Stock.add(w,a.equipment.item_id,1,a.pos)
	a.equipment={}
	if j.item_id!="unequip":
		var row=cargo[0];row.amount-=1
		if row.amount==0:w.field_items.erase(row)
		a.equipment={"item_id":j.item_id,"durability":-1}
	w.Stock.sync(w);w.Jobs.complete(w,j,true)
