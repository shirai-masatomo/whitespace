extends RefCounted
## One keeper, FIFO work. Intent is separate from structures and from local effects.
const LIMIT = 8
const SPEED = 2.5 # Cells/second, provisional.

static func enqueue(w, kind: String, p: Vector2i, animal_id: int) -> bool:
	if not w.working() or w.paused or w.jobs.size() >= LIMIT or not w.inside(p): return false
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
	w.jobs.append(j)
	w.job_log.append({"tick": w.tick, "event": "queued", "id": j.id, "kind": kind, "pos": [p.x, p.y]})
	return true

static func cancel(w, id: int, reason: String = "cancelled") -> bool:
	for j in w.jobs:
		if j.id != id: continue
		if j.reserved > 0: w.add_resource(j.resource, j.reserved)
		if (j.started or j.get("resume", false)) and w.structures.get(j.pos, {}).get("status") == "building": w.interrupt_site(j.pos)
		w.jobs.erase(j)
		w.job_log.append({"tick": w.tick, "event": reason, "id": id})
		return true
	return false

static func step(w):
	if w.keeper.state != "free" or w.jobs.is_empty():
		w.keeper.move_credit = 0.0
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
	var at_site = w.keeper.pos == j.pos if j.kind == "move" else w.distance(w.keeper.pos, j.pos) == 1
	if not at_site:
		j.state = "walking"
		w.keeper.move_credit = minf(1.9, w.keeper.move_credit + SPEED * w.DT)
		if w.keeper.move_credit < 1: return
		# Choose a reachable adjacent work cell. A blocked near side must not hide an open far side.
		var goals = [j.pos] if j.kind == "move" else w.neighbors(j.pos)
		goals = goals.filter(func(p): return w.walkable(p))
		goals.sort_custom(func(a, b): return w.distance(w.keeper.pos, a) < w.distance(w.keeper.pos, b))
		var next: Vector2i = w.keeper.pos
		for goal in goals:
			next = w.next_step(w.keeper.pos, goal)
			if next != w.keeper.pos: break
		if next == w.keeper.pos:
			cancel(w, j.id, "unreachable")
			w.say("道がふさがっている。予定を取り消したよ。")
			return
		w.keeper.move_credit -= 1.0
		w.keeper.pos = next
		w.keeper_path.append([next.x, next.y])
		return
	if j.kind == "move":
		complete(w, j, true)
		return
	if j.get("resume", false):
		j.started = true
		j.state = "working"
		return
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
