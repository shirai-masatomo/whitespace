extends RefCounted
const Reservations=preload("res://game/build_reservations.gd")
const Policy=preload("res://game/work_policy.gd")
const LIMIT = Policy.DESIGNATION_LIMIT
const SPEED = 2.5

# Index lives only for a synchronous preview/commit transaction, never across ticks.
static func index(w) -> Dictionary:
	var result={"kinds":{},"layers":{},"materials":{},"bench_cells":{}}
	for kind in w.Rules.RESOURCE_TYPES:result.materials[kind]=Reservations.available(w,kind)
	for j in w.jobs:index_add(w,result,j)
	preload("res://game/terrain_metrics.gd").count("job_index_rows",w.jobs.size())
	return result

static func index_add(w,lookup: Dictionary,j):
	if not lookup.kinds.has(j.pos):lookup.kinds[j.pos]={}
	lookup.kinds[j.pos][j.kind]=true
	var target=w.BUILD[j.kind].layer if w.BUILD.has(j.kind) else ("structure" if j.kind.begins_with("place_") else j.get("target_layer",""))
	if target!="":
		for cell in w.Buildings.cells(j.kind,j.pos):
			if not lookup.layers.has(cell):lookup.layers[cell]={}
			lookup.layers[cell][target]=true
			if j.kind in w.Buildings.BENCHES:lookup.bench_cells[cell]=true

static func build_reason(w, kind: String, p: Vector2i, extra_jobs: int=0, held_cost: int=0,lookup: Dictionary={}) -> String:
	preload("res://game/terrain_metrics.gd").count("keeper_jobs.build_reason")
	# Used both by the drag preview and the actual reservation; no world mutation.
	if not w.working(): return "牧場作業中に予約してください"
	if w.jobs.size()+extra_jobs>=LIMIT: return "指定は%d件まで"%LIMIT
	if not w.BUILD.has(kind) or not w.inside(p): return "ここには建てられません"
	if lookup.is_empty():lookup=index(w)
	if lookup.kinds.get(p,{}).has(kind): return "予約済みです"
	for cell in w.Buildings.cells(kind,p):
		if (kind in w.Buildings.BENCHES and not lookup.layers.get(cell,{}).is_empty()) or lookup.bench_cells.get(cell,false) or lookup.layers.get(cell,{}).has(w.BUILD[kind].layer):return "同じ場所に別の予定があります"
	var why=w.Buildings.reason(w,kind,p,false)
	if why!="": return why
	return "" # Designation is independent of current stock; delivery reserves physical goods.

static func enqueue(w, kind: String, p: Vector2i, animal_id: int,lookup: Dictionary={}) -> bool:
	w.Stock.normalize(w)
	if kind in ["remove","repair","gate"]:p=w.Buildings.anchor(w,p)
	if not w.working() or w.jobs.size()>=LIMIT or not w.inside(p):
		if w.BUILD.has(kind) and not lookup.get("quiet",false):Reservations.reject(w,kind,build_reason(w,kind,p,0,0,lookup))
		return false
	if lookup.is_empty():lookup=index(w)
	if lookup.kinds.get(p,{}).has(kind):
		if w.BUILD.has(kind) and not lookup.get("quiet",false):Reservations.reject(w,kind,"予約済みです")
		return false
	var resource=""
	var cost=0
	if w.BUILD.has(kind):
		var why=build_reason(w,kind,p,0,0,lookup)
		if why!="":
			if not lookup.get("quiet",false):Reservations.reject(w,kind,why)
			return false
		resource=w.BUILD[kind].get("resource","soil")
		cost=w.BUILD[kind].cost
	elif kind=="move":
		if not w.walkable(p): return false
	elif kind=="collect":
		var locked=w.Stock.collection_reason(w,p)
		if locked!="":w.say(locked);w.PlayerEvents.add(w,locked);return false
		if w.natural_forbidden.get(p,false):return false
		if w.items_at(p).is_empty() and not w.natural.has(p) and not(p==w.nest and w.eggs>0): return false
	elif kind in ["repair", "repair_floor"]:
		if w.repair_quote(p, "floor" if kind=="repair_floor" else "structure").hp<=0: return false
	elif kind in ["remove","remove_floor","gate"]:
		var store=w.floors if kind=="remove_floor" else w.structures
		if store.get(p,{}).get("status")!="ready" or (kind=="gate" and store[p].kind not in w.Buildings.DOORS): return false
		if kind=="remove_floor" and w.live_structure(p): w.say("先に上の建物を解体してください"); return false
	else: return false
	var j={"id":w.next_job_id,"kind":kind,"pos":p,"animal_id":animal_id,"state":"pending","resource":resource,"reserved":0,"required":cost,"started":false,"queued_tick":w.tick}
	if kind in ["remove","remove_floor","repair","repair_floor","gate"]:
		j.target_layer="floor" if kind.ends_with("_floor") else "structure"
		var b=w.building_store(j.target_layer).get(p,{})
		j.target_id=b.id; j.target_kind=b.kind
		if lookup.layers.get(p,{}).has(j.target_layer): return false
	if kind=="collect" and not w.items_at(p).is_empty():
		var candidates=w.items_at(p).filter(func(r):return not w.Stock.construction_locked(r) and not r.get("craft_transfer",false))
		if candidates.is_empty():return false
		var row=candidates[0]
		if row.kind!="skill_scroll" and not row.kind.ends_with("_plan"):
			if w.jobs.any(func(other):return other.get("stock_id",-1)==row.stock_id):return false
			j.kind="haul";j.stock_id=row.stock_id;j.explicit_designation=true
	j.physical=w.BUILD.has(kind)
	if j.physical:
		j.plan_claimed=false # Partial delivery owns claims, not the designation.
		lookup.materials[resource]=maxi(0,int(lookup.materials.get(resource,0))-cost)
		j.construction_group=lookup.get("construction_group",j.id)
		j.construction_ready=not lookup.has("construction_group")
	j.work_category=w.Work.category(w,j)
	w.next_job_id+=1
	if w.jobs.is_empty() and w.manual_goal==null and w.Life.able(w) and w.job_hold_reason in ["travel","manual","rescue","danger","rest_end"]: hold(w,"")
	w.jobs.append(j)
	index_add(w,lookup,j)
	w.Life.wake_auto(w)
	w.job_log.append({"tick":w.tick,"event":"queued","id":j.id,"kind":kind,"pos":[p.x,p.y]})
	return true

static func cancel(w,id: int,reason: String="cancelled") -> bool:
	for j in w.jobs:
		if j.id!=id: continue
		if w.paused and (j.started or j.get("targets",[]).any(func(t):return t.issued)):
			j.cancel_requested=true; return true
		if j.kind=="craft":w.Craft.cancel(w,j)
		w.Delivery.cancel_job(w,j)
		w.Stock.release_token(w,Reservations.token(j))
		w.Work.release(w,j)
		if j.kind=="animal_order": w.Orders.stop(w,j)
		if w.BUILD.has(j.kind):
			if j.get("physical",false):w.Stock.finish_build(w,j,false)
			w.Buildings.cancel(w,j)
		if j.reserved>0: w.add_resource(j.resource,j.reserved)
		w.jobs.erase(j)
		w.job_log.append({"tick":w.tick,"event":reason,"id":id})
		return true
	return false

static func reorder(_w,_id: int,_destination: int) -> bool:
	# Designation display order is not an execution priority.
	return false

static func walk(w,j,goals: Array,actor: Dictionary={}) -> bool:
	if actor.is_empty():actor=w.keeper
	goals=goals.filter(func(p):return w.walkable(p) and not w.actor_occupied(p,actor.pos))
	if actor.pos in goals: return true
	j.state="walking"
	actor.move_credit=minf(1.9,actor.move_credit+SPEED*movement_factor(actor)*(w.Content.speed(w,actor) if actor.get("work_key","")=="keeper" else 1.0)*w.DT)
	if actor.move_credit<1: return false
	var outdoor=j.kind=="animal_order" and j.order=="guide" and j.targets.any(func(t):return t.issued and not w.SPECIES[w.Orders.animal(w,t.id).get("species","hen")].can_enter_indoor) and not w.is_indoor(actor.pos)
	# Keep actor avoidance for the whole route, not just one bypass step; otherwise
	# the next tick returns into the same blocked corridor and oscillates.
	var route=path_to(w,actor.pos,goals,outdoor,not(j.kind=="animal_order" and j.order=="guide"))
	if route.size()<2:
		j.state="blocked"; j.block_reason="通路がふさがっています"
		return false
	var next=route[1]
	if w.actor_occupied(next,actor.pos):
		for goal in ([] if j.kind=="animal_order" and j.order=="guide" else goals):
			var bypass=w.find_path(actor.pos,goal,false,true,outdoor)
			if bypass.size()>1 and not w.actor_occupied(bypass[1],actor.pos): next=bypass[1]; break
		if w.actor_occupied(next,actor.pos):
			if j.kind=="animal_order" and j.order=="guide": w.Orders.clear_guide_path(w,j,next)
			actor.yield_cell=next; j.state="blocked"; j.block_reason="通行待ち"; return false
	j.state="walking"
	actor.erase("yield_cell")
	if not w.Combat.pay(actor,"move"):
		j.state="blocked";j.block_reason="息を整えています";return false
	actor.move_credit-=1
	w.open_for_ally(next)
	actor.pos=next
	if actor.get("work_key","")=="keeper":w.keeper_path.append([next.x,next.y])
	return false

static func factor(actor: Dictionary) -> float:
	return movement_factor(actor)*actor.get("food_work_factor",1.0)*actor.get("focus_work",1.0)*actor.get("mood_work",1.0)

static func movement_factor(actor: Dictionary) -> float:
	return (0.6 if actor.get("sleepiness",0)>=80 else 1.0)*preload("res://game/human_nutrition.gd").factor(actor)

static func step(w):
	w.Work.step(w)

static func execute(w,j,actor: Dictionary):
	if j.kind=="collect" and (w.natural_forbidden.get(j.pos,false) or not w.items_at(j.pos,true).is_empty() and w.items_at(j.pos).is_empty()):j.state="blocked";j.block_reason="採集対象は禁止中です";return
	if j.kind=="craft":w.Craft.step(w,j,actor);return
	if j.kind in ["direct_attack","keeper_equipment"]:w.HumanCombat.execute(w,j,actor);return
	if j.kind in w.Tasks.KINDS:w.Tasks.execute(w,j,actor);return
	if j.kind=="slaughter":w.Livestock.execute(w,j,actor);return
	if j.kind=="haul":w.Stock.haul_step(w,j,actor);return
	if w.BUILD.has(j.kind) and not w.Stock.prepare_build(w,j,actor):return
	if j.kind in ["milk","place_kokeshi","place_fossil","place_wood_crate","place_wood_shelf"]:w.Content.job(w,j);return
	if j.kind=="equip": w.Progression.equip_step(w,j); return
	if j.kind in w.Story.ACTIONS: w.Story.step_job(w,j); return
	if j.has("target_id"):
		var b=w.building_store(j.target_layer).get(j.pos,{})
		if b.get("id")!=j.target_id or b.get("kind")!=j.target_kind or b.get("status")!="ready": complete(w,j,false); return
		if j.kind=="remove_floor" and w.live_structure(j.pos): j.state="blocked"; j.block_reason="先に上の建物を解体してください"; return
		if j.kind in ["remove","remove_floor"] and w.occupied(j.pos) and actor.pos!=j.pos: j.state="blocked"; j.block_reason="誰かがいます"; return
	if j.kind=="animal_order": w.Orders.step(w,j); return
	if w.BUILD.has(j.kind) and not j.started:
		var why=w.Buildings.reason(w,j.kind,j.pos,false,j.id)
		if why!="" and not (why=="ここに誰かいます" and actor.pos==j.pos): j.state="blocked"; j.block_reason=why; return
	var goals=[j.pos] if j.kind=="move" else w.Buildings.job_goals(w,j)
	if w.BUILD.has(j.kind):goals=preload("res://game/construction_safety.gd").work_goals(w,j,actor,goals)
	if goals.is_empty():w.Work.block(w,j,"退避経路を確保できません");return
	if actor.pos not in goals:
		walk(w,j,goals,actor); return
	if j.kind=="move":
		if j.get("purpose","")=="merchant":j.state="working";return
		complete(w,j,true); return
	if w.BUILD.has(j.kind):
		if not j.started:
			var why=w.Buildings.reason(w,j.kind,j.pos,false,j.id)
			if why!="": j.state="blocked"; j.block_reason=why; return
			if not preload("res://game/construction_safety.gd").can_finish(w,j,actor):
				w.Work.block(w,j,"退避経路を確保できません");return
			w.Buildings.begin(w,j)
		j.phase="work"
		w.Buildings.advance(w,j,factor(actor))
		return
	if j.kind in ["remove","remove_floor"] and w.occupied(j.pos): j.state="blocked"; j.block_reason="誰かがいます"; return
	j.state="working"
	j.work_credit=j.get("work_credit",0.0)+factor(actor)
	if j.work_credit<1: return
	complete(w,j,w._execute_local(j.kind,j.pos,j.animal_id))

static func complete(w,j: Dictionary,ok: bool):
	if j.get("personal",false):w.Work.release(w,j);j.personal_finished=true;return
	if j.kind.begins_with("place_"):w.Stock.release_token(w,Reservations.token(j))
	if w.BUILD.has(j.kind) and j.get("physical",false):
		w.Stock.finish_build(w,j,ok)
		if ok:w.PlayerEvents.add(w,w.Buildings.NAMES.get(j.kind,"建物")+"が完成しました","build_done:%d"%j.id)
	w.Work.release(w,j)
	w.jobs.erase(j)
	w.job_log.append({"tick":w.tick,"event":"completed" if ok else "invalid","id":j.id,"kind":j.kind,"pos":[j.pos.x,j.pos.y],"animal_id":j.animal_id})
	if not ok: w.say("この仕事はできなくなりました")

static func hold(w, reason: String):
	if w.job_hold_reason != reason:
		w.job_log.append({"tick":w.tick,"event":"hold_changed","reason":reason})
	w.job_hold_reason = reason
	w.jobs_held = reason != ""

static func status(w) -> String:
	return w.keeper.get("work_status","")

static func path_to(w,start: Vector2i,goals: Array,outdoor: bool=false,avoid_actors: bool=false) -> Array:
	preload("res://game/terrain_metrics.gd").count("keeper_jobs.path_to")
	goals=goals.filter(func(p):return not outdoor or not w.is_indoor(p))
	goals.sort_custom(func(a,b):
		var da=w.distance(start,a); var db=w.distance(start,b)
		return da<db if da!=db else (a.y<b.y if a.y!=b.y else a.x<b.x))
	for goal in goals:
		var route=w.find_path(start,goal,false,avoid_actors,outdoor)
		if not route.is_empty(): return route
	return []

static func preview(w) -> Array:
	var legs=[]
	var origin=w.keeper.pos
	var plans=[]
	if w.manual_goal!=null: plans.append({"number":0,"goals":[w.manual_goal]})
	var delivery=w.build_deliveries.get("keeper",{})
	if not delivery.is_empty():
		var targets=[]
		for allocation in delivery.allocations:
			for claim in allocation.claims:
				var row=w.Stock.find(w,claim.stock_id)
				if not row.is_empty():plans.append({"number":allocation.job_id,"goals":w.neighbors(row.pos)})
			var target=w.Delivery.job(w,allocation.job_id)
			if not target.is_empty() and (not allocation.claims.is_empty() or not w.Stock.cargo(w,"keeper",target.id).is_empty()):targets.append(target)
		targets.sort_custom(func(a,b):return w.distance(w.keeper.pos,a.pos)<w.distance(w.keeper.pos,b.pos))
		for target in targets:plans.append({"number":target.id,"goals":w.neighbors(target.pos)})
	for i in range(w.jobs.size()):
		var j=w.jobs[i]
		if j.get("assigned_to","")!="keeper":continue
		if j.kind in ["equip","milk","slaughter","train"]:
			var a=w.Orders.animal(w,j.animal_id)
			if not a.is_empty(): plans.append({"number":j.id,"goals":w.neighbors(a.pos)})
		elif j.kind=="animal_order":
			for t in j.targets:
				if not t.issued and not t.done:
					var a=w.Orders.animal(w,t.id)
					if not a.is_empty(): plans.append({"number":j.id,"goals":w.Orders.command_goals(w,a,j.range)})
			if j.order=="guide": plans.append({"number":j.id,"goals":[j.leader_goal],"outdoor":j.targets.any(func(t):return not w.SPECIES[w.Orders.animal(w,t.id).get("species","hen")].can_enter_indoor)})
		else: plans.append({"number":j.id,"goals":w.Story.goals(w) if j.kind in w.Story.ACTIONS and j.kind!="clear_tree" else (w.Mountains.job_goals(w,j) if j.has("mountain_id") else ([j.pos] if j.kind=="move" else w.neighbors(j.pos)))})
	for plan in plans:
		var route=path_to(w,origin,plan.goals.filter(func(p):return w.walkable(p)),plan.get("outdoor",false) and not w.is_indoor(origin))
		legs.append({"number":plan.number,"path":route if not route.is_empty() else [origin],"blocked":route.is_empty()})
		if route.is_empty(): break
		origin=route[-1]
	return legs
