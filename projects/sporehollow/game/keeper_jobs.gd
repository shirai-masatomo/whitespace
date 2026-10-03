extends RefCounted
## One keeper, FIFO work. Intent is separate from structures and from local effects.
const LIMIT = 8
const SPEED = 2.5 # Cells/second, provisional.

static func enqueue(w, kind: String, p: Vector2i, animal_id: int) -> bool:
	if not w.working() or w.jobs.size() >= LIMIT or not w.inside(p): return false
	if w.jobs.any(func(j): return (j.pos == p and j.kind == kind) or (kind == "place_animal" and j.kind == kind and j.animal_id == animal_id)): return false
	var resource = ""
	var cost = 0
	if w.BUILD.has(kind):
		if not w.can_build(kind, p) or w.jobs.any(func(j): return w.BUILD.has(j.kind) and j.pos == p): return false
		resource = w.BUILD[kind].get("resource", "soil")
		cost = w.BUILD[kind].cost
	elif kind == "move":
		if not w.walkable(p): return false
	elif kind == "place_animal":
		if not w.can_place_animal(animal_id, p) or w.jobs.any(func(j): return w.BUILD.has(j.kind) and j.pos == p): return false
	elif kind == "collect":
		if w.items_at(p).is_empty() and not w.natural.has(p) and not (p == w.nest and w.eggs > 0): return false
	elif kind == "repair":
		if w.repair_quote(p).hp <= 0: return false
	elif kind in ["remove", "gate"]:
		if not w.live_structure(p) or (kind == "gate" and w.structures[p].kind != "gate"): return false
	else: return false
	var j = {"id": w.next_job_id, "kind": kind, "pos": p, "animal_id": animal_id,
		"state": "pending", "resource": resource, "reserved": cost, "started": false}
	if cost > 0: w.add_resource(resource, -cost)
	w.next_job_id += 1
	if kind == "place_animal":
		j.transport = "to_shed"
		deployment(w, animal_id, "reserved")
	if w.job_hold_reason == "travel" and w.manual_goal == null and w.Life.able(w): hold(w, "")
	w.jobs.append(j)
	w.job_log.append({"tick": w.tick, "event": "queued", "id": j.id, "kind": kind, "pos": [p.x, p.y]})
	return true

static func cancel(w, id: int, reason: String = "cancelled") -> bool:
	for j in w.jobs:
		if j.id != id: continue
		if j.get("transport", "") == "drop_pending": return false
		if j.get("transport", "") in ["carrying", "returning"]:
			j.transport = "returning"
			j.state = "returning"
			w.job_log.append({"tick": w.tick, "event": "return_requested", "id": id})
			return true
		if w.paused and (j.started or j.get("resume", false)):
			j.cancel_requested = true
			return true
		if j.kind == "place_animal": deployment(w, j.animal_id, "unplaced")
		if j.reserved > 0: w.add_resource(j.resource, j.reserved)
		if (j.started or j.get("resume", false)) and w.structures.get(j.pos, {}).get("status") == "building": w.interrupt_site(j.pos)
		w.jobs.erase(j)
		w.job_log.append({"tick": w.tick, "event": reason, "id": id})
		return true
	return false

static func deployment(w, id: int, value: String):
	for a in w.animals:
		if a.id == id: a.deployment = value
	w.job_log.append({"tick": w.tick, "event": "deployment", "animal_id": id, "state": value})

static func reorder(w, id: int, destination: int) -> bool:
	if not w.working(): return false
	var index = -1
	for i in range(w.jobs.size()):
		if w.jobs[i].id == id: index = i
	var locked = not w.jobs.is_empty() and w.jobs[0].state != "pending"
	var minimum = 1 if locked else 0
	if index < minimum or index < 0: return false
	destination = clampi(destination, minimum, w.jobs.size() - 1)
	var job = w.jobs.pop_at(index)
	w.jobs.insert(destination, job)
	w.job_log.append({"tick": w.tick, "event": "reordered", "id": id, "order": w.jobs.map(func(j): return j.id)})
	return true

static func step(w):
	for pending in w.jobs.duplicate():
		if pending.get("transport", "") == "drop_pending": drop_companion(w, pending)
	for pending in w.jobs.duplicate():
		if pending.get("cancel_requested", false): cancel(w, pending.id)
	if not w.Life.able(w) or w.jobs_held or w.manual_goal != null or w.jobs.is_empty():
		if w.manual_goal == null: w.keeper.move_credit = 0.0
		return
	var j = w.jobs[0]
	if j.started:
		var status = w.structures.get(j.pos, {}).get("status", "missing")
		if status == "building":
			if w.distance(w.keeper.pos, j.pos) == 1:
				j.state = "working"
				return
			# A carrier can move the keeper away during an unfinished job.
			j.started = false
			j.resume = true
		else:
			complete(w, j, status == "ready")
			return
	var target: Vector2i = w.HOLDING_SHED if j.get("transport", "") in ["to_shed", "returning"] else j.pos
	var at_site = w.keeper.pos == target if j.kind == "move" else w.distance(w.keeper.pos, target) == 1
	if j.get("transport", "") in ["to_shed", "returning"] and w.keeper.pos == target: at_site = true
	if j.kind == "place_animal" and j.get("transport", "") == "carrying" and j.pos != w.keeper.pos and not w.valid_animal_site(j.animal_id, j.pos):
		j.state = "blocked"
		return
	if not at_site:
		j.state = "walking"
		w.keeper.move_credit = minf(1.9, w.keeper.move_credit + SPEED * w.Life.factor(w) * w.DT)
		if w.keeper.move_credit < 1: return
		# Choose a reachable adjacent work cell. A blocked near side must not hide an open far side.
		var goals = [target] if j.kind == "move" else w.neighbors(target)
		goals = goals.filter(func(p): return w.walkable(p))
		var solid_goals = goals.duplicate()
		goals = goals.filter(func(p): return not w.actor_occupied(p, w.keeper.pos))
		if goals.is_empty() and not solid_goals.is_empty(): return
		goals.sort_custom(func(a, b): return w.distance(w.keeper.pos, a) < w.distance(w.keeper.pos, b))
		var next: Vector2i = w.keeper.pos
		for goal in goals:
			next = w.next_step(w.keeper.pos, goal, false, true)
			if next != w.keeper.pos: break
		if next == w.keeper.pos:
			if goals.any(func(g): return w.next_step(w.keeper.pos, g) != w.keeper.pos): return
			if j.kind == "place_animal" and j.transport in ["carrying", "returning"]:
				j.state = "blocked"
				return
			cancel(w, j.id, "unreachable")
			w.say("道がふさがっている。予定を取り消したよ。")
			return
		if w.actor_occupied(next, w.keeper.pos): return
		w.keeper.move_credit -= 1.0
		w.keeper.pos = next
		w.keeper_path.append([next.x, next.y])
		return
	if j.kind == "place_animal":
		if j.transport == "to_shed":
			j.transport = "carrying"
			deployment(w, j.animal_id, "transporting")
			return
		if j.transport == "returning":
			deployment(w, j.animal_id, "unplaced")
			complete(w, j, true)
			return
	if j.kind == "move":
		complete(w, j, true)
		return
	if j.get("resume", false):
		j.started = true
		j.state = "working"
		return
	if not w.BUILD.has(j.kind):
		j["work_credit"] = j.get("work_credit", 0.0) + w.Life.factor(w)
		if j.work_credit < 1: return
	# Revalidate at arrival. Resources are held while walking, and consumed only for actual work.
	if j.reserved > 0:
		w.add_resource(j.resource, j.reserved)
		j.reserved = 0
	var ok: bool = w._execute_local(j.kind, j.pos, j.animal_id)
	if ok and w.BUILD.has(j.kind):
		j.started = true
		j.state = "working"
		w.job_log.append({"tick": w.tick, "event": "started", "id": j.id, "pos": [j.pos.x, j.pos.y]})
	else: complete(w, j, ok)

static func complete(w, j: Dictionary, ok: bool):
	w.jobs.erase(j)
	w.job_log.append({"tick": w.tick, "event": "completed" if ok else "invalid", "id": j.id, "kind": j.kind, "pos": [j.pos.x, j.pos.y], "animal_id": j.animal_id})
	if not ok: w.say("この仕事はできなくなったので、次へ進むよ。")


static func hold(w, reason: String):
	if w.job_hold_reason != reason:
		w.job_log.append({"tick":w.tick,"event":"hold_changed","reason":reason})
	w.job_hold_reason = reason
	w.jobs_held = reason != ""

static func status(w) -> String:
	if w.keeper.carrier >= 0: return "連れ去り中"
	if w.keeper.state != "free": return "気絶中"
	if w.keeper.resting: return "ひと休み"
	if w.manual_goal != null: return "歩いている"
	if w.jobs_held: return {"manual":"避難・再開待ち","rest":"起床待ち","rescue":"救出後・再開待ち","danger":"被弾・再開待ち","travel":"移動後・再開待ち"}.get(w.job_hold_reason,"再開待ち")
	if not w.jobs.is_empty() and w.jobs[0].state == "blocked": return "通り道・行き先がふさがっている"
	return ""

static func interrupt_transport(w):
	for j in w.jobs.duplicate():
		if j.get("transport", "") not in ["carrying","returning","drop_pending"]: continue
		j.transport = "drop_pending"
		j.state = "blocked"
		hold(w,"danger")
		drop_companion(w,j)

static func drop_companion(w,j):
	# Adjacent only: never teleport through walls, never overwrite another actor.
	var sites = w.neighbors(w.keeper.pos).filter(func(p):return w.valid_animal_site(j.animal_id,p))
	if sites.is_empty(): return
	var site=sites[0]
	if w._execute_local("place_animal",site,j.animal_id):
		w.job_log.append({"tick":w.tick,"event":"companion_lowered","animal_id":j.animal_id,"pos":[site.x,site.y]})
		complete(w,j,true)
		w.say("仲間を降ろした！")

static func path_to(w,start: Vector2i,goals: Array) -> Array:
	var frontier=[start]
	var previous={start:start}
	var index=0
	while index<frontier.size():
		var p=frontier[index]; index+=1
		if p in goals:
			var route=[p]
			while p!=start:
				p=previous[p]
				route.push_front(p)
			return route
		for n in w.neighbors(p):
			if w.walkable(n) and not previous.has(n):
				previous[n]=p
				frontier.append(n)
	return []

static func preview(w) -> Array:
	var legs=[]
	var origin=w.keeper.pos
	if w.manual_goal!=null:
		var path=path_to(w,origin,[w.manual_goal])
		if path.is_empty(): return legs
		legs.append({"number":0,"path":path})
		origin=path[-1]
	for i in range(w.jobs.size()):
		var j=w.jobs[i]
		var targets=[]
		if j.get("transport","") == "drop_pending": break
		if j.get("transport","") in ["to_shed","returning"]: targets.append(w.HOLDING_SHED)
		if j.get("transport","") != "returning": targets.append(j.pos)
		for target in targets:
			var goals=[target] if j.kind=="move" else w.neighbors(target)
			if target==w.HOLDING_SHED: goals.append(target)
			var path=path_to(w,origin,goals.filter(func(p):return w.walkable(p)))
			if path.is_empty(): return legs
			legs.append({"number":i+1,"path":path})
			origin=path[-1]
	return legs
