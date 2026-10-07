extends RefCounted
const LIMIT = 8
const SPEED = 2.5

static func enqueue(w, kind: String, p: Vector2i, animal_id: int) -> bool:
	if not w.working() or w.jobs.size()>=LIMIT or not w.inside(p): return false
	if w.jobs.any(func(j):return j.pos==p and j.kind==kind): return false
	var resource=""
	var cost=0
	if w.BUILD.has(kind):
		var why=w.Buildings.reason(w,kind,p)
		if why!="": w.say(why); return false
		if w.jobs.any(func(j):return j.pos==p and ((w.BUILD.has(j.kind) and w.BUILD[j.kind].layer==w.BUILD[kind].layer) or j.get("target_layer")==w.BUILD[kind].layer)): return false
		resource=w.BUILD[kind].get("resource","soil")
		cost=0 if w.debug_enabled and w.debug_infinite else w.BUILD[kind].cost
	elif kind=="move":
		if not w.walkable(p): return false
	elif kind=="collect":
		if w.items_at(p).is_empty() and not w.natural.has(p) and not(p==w.nest and w.eggs>0): return false
	elif kind in ["repair", "repair_floor"]:
		if w.repair_quote(p, "floor" if kind=="repair_floor" else "structure").hp<=0: return false
	elif kind in ["remove","remove_floor","gate"]:
		var store=w.floors if kind=="remove_floor" else w.structures
		if store.get(p,{}).get("status")!="ready" or (kind=="gate" and store[p].kind not in w.Buildings.DOORS): return false
		if kind=="remove_floor" and w.live_structure(p): w.say("先に上の建物を解体してください"); return false
	else: return false
	var j={"id":w.next_job_id,"kind":kind,"pos":p,"animal_id":animal_id,"state":"pending","resource":resource,"reserved":cost,"started":false}
	if kind in ["remove","remove_floor","repair","repair_floor","gate"]:
		j.target_layer="floor" if kind.ends_with("_floor") else "structure"
		var b=w.building_store(j.target_layer).get(p,{})
		j.target_id=b.id; j.target_kind=b.kind
		if w.jobs.any(func(other):return other.pos==p and ((w.BUILD.has(other.kind) and w.BUILD[other.kind].layer==j.target_layer) or other.get("target_layer")==j.target_layer)): return false
	if cost>0: w.add_resource(resource,-cost)
	w.next_job_id+=1
	if w.jobs.is_empty() and w.manual_goal==null and w.Life.able(w) and w.job_hold_reason in ["travel","manual","rescue","danger","rest_end"]: hold(w,"")
	w.jobs.append(j)
	w.Life.wake_auto(w)
	w.job_log.append({"tick":w.tick,"event":"queued","id":j.id,"kind":kind,"pos":[p.x,p.y]})
	return true

static func cancel(w,id: int,reason: String="cancelled") -> bool:
	for j in w.jobs:
		if j.id!=id: continue
		if w.paused and (j.started or j.get("targets",[]).any(func(t):return t.issued)):
			j.cancel_requested=true; return true
		if j.kind=="animal_order": w.Orders.stop(w,j)
		if w.BUILD.has(j.kind): w.Buildings.cancel(w,j)
		if j.reserved>0: w.add_resource(j.resource,j.reserved)
		w.jobs.erase(j)
		w.job_log.append({"tick":w.tick,"event":reason,"id":id})
		return true
	return false

static func reorder(w,id: int,destination: int) -> bool:
	if not w.working(): return false
	var index=-1
	for i in range(w.jobs.size()):
		if w.jobs[i].id==id: index=i
	var minimum=1 if not w.jobs.is_empty() and w.jobs[0].state not in ["pending","blocked"] else 0
	if index<minimum: return false
	var job=w.jobs.pop_at(index)
	w.jobs.insert(clampi(destination,minimum,w.jobs.size()),job)
	w.job_log.append({"tick":w.tick,"event":"reordered","id":id,"order":w.jobs.map(func(j):return j.id)})
	return true

static func walk(w,j,goals: Array) -> bool:
	goals=goals.filter(func(p):return w.walkable(p) and not w.actor_occupied(p,w.keeper.pos))
	if w.keeper.pos in goals: return true
	j.state="walking"
	w.keeper.move_credit=minf(1.9,w.keeper.move_credit+SPEED*w.Life.factor(w)*w.Content.speed(w,w.keeper)*w.DT)
	if w.keeper.move_credit<1: return false
	var outdoor=j.kind=="animal_order" and j.order=="guide" and j.targets.any(func(t):return t.issued and not w.SPECIES[w.Orders.animal(w,t.id).get("species","hen")].can_enter_indoor) and not w.is_indoor(w.keeper.pos)
	var route=path_to(w,w.keeper.pos,goals,outdoor)
	if route.size()<2:
		j.state="blocked"; j.block_reason="通路がふさがっています"
		if j.kind in ["move","collect","repair","repair_floor","remove","remove_floor","gate"]: cancel(w,j.id,"unreachable")
		return false
	var next=route[1]
	if w.actor_occupied(next,w.keeper.pos):
		for goal in ([] if j.kind=="animal_order" and j.order=="guide" else goals):
			var bypass=w.find_path(w.keeper.pos,goal,false,true,outdoor)
			if bypass.size()>1 and not w.actor_occupied(bypass[1],w.keeper.pos): next=bypass[1]; break
		if w.actor_occupied(next,w.keeper.pos):
			if j.kind=="animal_order" and j.order=="guide": w.Orders.clear_guide_path(w,j,next)
			w.keeper.yield_cell=next; j.state="blocked"; j.block_reason="通行待ち"; return false
	j.state="walking"
	w.keeper.erase("yield_cell")
	if not w.Combat.pay(w.keeper,"move"):
		j.state="blocked";j.block_reason="息を整えています";return false
	w.keeper.move_credit-=1
	w.open_for_ally(next)
	w.keeper.pos=next
	w.keeper_path.append([next.x,next.y])
	return false

static func step(w):
	for pending in w.jobs.duplicate():
		if pending.get("cancel_requested",false): cancel(w,pending.id)
	if not w.Life.able(w) or w.jobs_held or w.manual_goal!=null or w.jobs.is_empty(): return
	var j=w.jobs[0]
	if j.kind in ["milk","place_kokeshi","place_fossil"]:w.Content.job(w,j);return
	if j.kind=="equip": w.Progression.equip_step(w,j); return
	if j.kind in w.Story.ACTIONS: w.Story.step_job(w,j); return
	if j.has("target_id"):
		var b=w.building_store(j.target_layer).get(j.pos,{})
		if b.get("id")!=j.target_id or b.get("kind")!=j.target_kind or b.get("status")!="ready": complete(w,j,false); return
		if j.kind=="remove_floor" and w.live_structure(j.pos): j.state="blocked"; j.block_reason="先に上の建物を解体してください"; return
		if j.kind in ["remove","remove_floor"] and w.occupied(j.pos) and w.keeper.pos!=j.pos: j.state="blocked"; j.block_reason="誰かがいます"; return
	if j.kind=="animal_order": w.Orders.step(w,j); return
	if w.BUILD.has(j.kind) and not j.started:
		var why=w.Buildings.reason(w,j.kind,j.pos,false)
		if why!="" and not (why=="ここに誰かいます" and w.keeper.pos==j.pos): j.state="blocked"; j.block_reason=why; return
	var goals=[j.pos] if j.kind=="move" else w.neighbors(j.pos)
	if w.keeper.pos not in goals:
		walk(w,j,goals); return
	if j.kind=="move": complete(w,j,true); return
	if w.BUILD.has(j.kind):
		if not j.started:
			var why=w.Buildings.reason(w,j.kind,j.pos,false)
			if why!="": j.state="blocked"; j.block_reason=why; return
			w.Buildings.begin(w,j)
		w.Buildings.advance(w,j)
		return
	if j.kind in ["remove","remove_floor"] and w.occupied(j.pos): j.state="blocked"; j.block_reason="誰かがいます"; return
	j.work_credit=j.get("work_credit",0.0)+w.Life.factor(w)
	if j.work_credit<1: return
	complete(w,j,w._execute_local(j.kind,j.pos,j.animal_id))

static func complete(w,j: Dictionary,ok: bool):
	w.jobs.erase(j)
	w.job_log.append({"tick":w.tick,"event":"completed" if ok else "invalid","id":j.id,"kind":j.kind,"pos":[j.pos.x,j.pos.y],"animal_id":j.animal_id})
	if not ok: w.say("この仕事はできなくなりました")

static func hold(w, reason: String):
	if w.job_hold_reason != reason:
		w.job_log.append({"tick":w.tick,"event":"hold_changed","reason":reason})
	w.job_hold_reason = reason
	w.jobs_held = reason != ""

static func status(w) -> String:
	if w.keeper.carrier >= 0: return "連れ去り中"
	if w.keeper.state != "free": return "気絶中"
	if w.keeper.resting: return "休息"
	if w.manual_goal != null: return "歩いている"
	if w.jobs_held: return {"manual":"移動で中断","rest":"休息","auto_rest":"自動休息","rescue":"救出後・再開待ち","danger":"被弾・再開待ち","travel":"移動後・再開待ち","rest_end":"休息終了・再開待ち","explicit":"作業停止"}.get(w.job_hold_reason,"再開待ち")
	if not w.jobs.is_empty() and w.jobs[0].state == "blocked": return w.jobs[0].get("block_reason","通路がふさがっています")
	return ""

static func path_to(w,start: Vector2i,goals: Array,outdoor: bool=false) -> Array:
	goals=goals.filter(func(p):return not outdoor or not w.is_indoor(p))
	goals.sort_custom(func(a,b):
		var da=w.distance(start,a); var db=w.distance(start,b)
		return da<db if da!=db else (a.y<b.y if a.y!=b.y else a.x<b.x))
	for goal in goals:
		var route=w.find_path(start,goal,false,false,outdoor)
		if not route.is_empty(): return route
	return []

static func preview(w) -> Array:
	var legs=[]
	var origin=w.keeper.pos
	var plans=[]
	if w.manual_goal!=null: plans.append({"number":0,"goals":[w.manual_goal]})
	for i in range(w.jobs.size()):
		var j=w.jobs[i]
		if j.kind in ["equip","milk"]:
			var a=w.Orders.animal(w,j.animal_id)
			if not a.is_empty(): plans.append({"number":i+1,"goals":w.neighbors(a.pos)})
		elif j.kind=="animal_order":
			for t in j.targets:
				if not t.issued and not t.done:
					var a=w.Orders.animal(w,t.id)
					if not a.is_empty(): plans.append({"number":i+1,"goals":w.Orders.command_goals(w,a,j.range)})
			if j.order=="guide": plans.append({"number":i+1,"goals":[j.leader_goal],"outdoor":j.targets.any(func(t):return not w.SPECIES[w.Orders.animal(w,t.id).get("species","hen")].can_enter_indoor)})
		else: plans.append({"number":i+1,"goals":w.Story.goals(w) if j.kind in w.Story.ACTIONS and j.kind!="clear_tree" else ([j.pos] if j.kind=="move" else w.neighbors(j.pos))})
	for plan in plans:
		var route=path_to(w,origin,plan.goals.filter(func(p):return w.walkable(p)),plan.get("outdoor",false) and not w.is_indoor(origin))
		legs.append({"number":plan.number,"path":route if not route.is_empty() else [origin],"blocked":route.is_empty()})
		if route.is_empty(): break
		origin=route[-1]
	return legs
