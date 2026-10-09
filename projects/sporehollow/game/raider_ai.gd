extends RefCounted
## Perception alone may read the keeper's real position.
const MEMORY_STALL_SECONDS=8.0
static func perceive(e: Dictionary, w):
	e.search_route_active=false
	w.Progression.Targets.observe(w,e)
	var visible = w.Life.targetable(w,e.get("archetype","")=="kidnapper") and w.distance(e.pos, w.keeper.pos) <= e.sight_range and w.line_of_sight(e.pos, w.keeper.pos)
	if not w.Life.targetable(w,e.get("archetype","")=="kidnapper"):
		e.last_known_keeper_position=null
	if visible != e.can_see_keeper:
		if visible: w.Life.danger(w, "spotted")
		e.sight_reaction = "!" if visible else "?"
		e.sight_reaction_until = w.tick + 6
		w.sight_log.append({"tick": w.tick, "id": e.id, "visible": visible, "position": [e.pos.x, e.pos.y]})
		if w.sight_log.size() > 32: w.sight_log.pop_front()
	e.can_see_keeper = visible
	if visible:
		e.last_known_keeper_position = w.keeper.pos
		e.keeper_memory_progress_pos=e.pos
		e.keeper_memory_progress_tick=w.tick
		e.erase("keeper_memory_end")
		e.search_state = "追跡"
	elif e.last_known_keeper_position != null: e.search_state = "最後に見た場所へ"
	else: e.search_state = "探索中"

static func target(e: Dictionary, w) -> Vector2i:
	if e.flee or e.carry == "keeper": return w.Story.exit_goal(w,e)
	if e.can_see_keeper: return e.last_known_keeper_position
	if e.last_known_keeper_position != null:
		if e.pos==e.last_known_keeper_position:forget_keeper(e,"arrived")
		elif not reachable(e,w,e.last_known_keeper_position):forget_keeper(e,"unreachable")
		else:
			if not e.has("keeper_memory_progress_pos") or e.keeper_memory_progress_pos!=e.pos:
				e.keeper_memory_progress_pos=e.pos;e.keeper_memory_progress_tick=w.tick
			if w.tick-e.keeper_memory_progress_tick>=ceili(MEMORY_STALL_SECONDS/w.DT):forget_keeper(e,"no_progress")
			else:
				e.search_route_active=true
				return e.last_known_keeper_position
	e.search_route_active=true
	if e.search_goal!=null and e.pos==e.search_goal:
		e.search_visits[e.search_goal]=e.search_visits.get(e.search_goal,0)+1
		e.search_goal=null
	if e.search_goal!=null and reachable(e,w,e.search_goal):return e.search_goal
	var options = []
	for y in [3, 8, 13]:
		for x in [4, 10, 16, 22]:
			var p=Vector2i(x,y)
			if p!=e.pos and reachable(e,w,p):options.append(p)
	if options.is_empty():e.search_goal=null;e.search_state="行ける道を探す";return e.pos
	# Count arrivals, not selections. A reachable unfinished goal is not expired by a timer.
	options.sort_custom(func(a, b):
		var ca = e.search_visits.get(a, 0) * 100 + w.distance(e.pos, a)
		var cb = e.search_visits.get(b, 0) * 100 + w.distance(e.pos, b)
		return (a.y * w.W + a.x) < (b.y * w.W + b.x) if ca == cb else ca < cb)
	e.search_goal = options[0]
	e.search_goal_until = w.tick + 64 # Legacy observation field, no longer a retarget deadline.
	return e.search_goal

static func forget_keeper(e: Dictionary,reason: String):
	e.last_known_keeper_position=null;e.search_goal=null
	e.erase("keeper_memory_progress_pos");e.erase("keeper_memory_progress_tick")
	e.keeper_memory_end=reason;e.search_state="周辺を探す"

static func reachable(e: Dictionary,w,p: Vector2i) -> bool:
	return not w.Story.terrain_block(w,p) and not w.find_path(e.pos,p,w.Progression.Targets.can_damage_object(w,e),false,e.get("species","")=="doberman").is_empty()

# Provisional: 24 seconds, at most 48 cells, +0.75 per recent visit (cap 2.25).
# Only forgotten-target exploration uses this cost; paths stay legal and reversible.
static func costs(e,w) -> Dictionary:
	var result={}
	var history=e.get("search_route_history",{})
	for p in history.keys():
		if w.tick-history[p].tick>ceili(24.0/w.DT):history.erase(p)
		elif e.get("search_route_active",false):result[p]=minf(2.25,0.75*history[p].count)
	return result

static func route(e,w,goal: Vector2i,break_objects: bool,avoid_actors: bool) -> Array:
	return w.find_path(e.pos,goal,break_objects,avoid_actors,e.get("species","")=="doberman",costs(e,w))

static func remember_step(e,w,origin: Vector2i,destination: Vector2i):
	if not e.get("search_route_active",false) or e.flee or e.carry=="keeper":return
	if not e.has("search_route_history"):e.search_route_history={}
	costs(e,w)
	var history=e.search_route_history
	if not history.has(origin):history[origin]={"tick":w.tick,"count":1}
	var count=history.get(destination,{"count":0}).count+1
	# Reinsertion preserves chronological eviction order.
	history.erase(destination);history[destination]={"tick":w.tick,"count":mini(3,count)}
	while history.size()>48:history.erase(history.keys()[0])
