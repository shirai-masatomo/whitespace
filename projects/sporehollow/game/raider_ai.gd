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
	if e.archetype=="kidnapper" and e.has("human_memory"):
		if w.tick<e.get("human_memory_until",0) and e.pos!=e.human_memory and reachable(e,w,e.human_memory):return e.human_memory
		e.erase("human_memory")
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
	e.search_route_active=false
	return w.RaidNavigation.objective(w,e)

static func forget_keeper(e: Dictionary,reason: String):
	e.last_known_keeper_position=null;e.search_goal=null
	e.erase("keeper_memory_progress_pos");e.erase("keeper_memory_progress_tick")
	e.keeper_memory_end=reason;e.search_state="周辺を探す"

static func reachable(e: Dictionary,w,p: Vector2i) -> bool:
	return not w.Story.terrain_block(w,p) and not route(e,w,p,w.Progression.Targets.can_damage_object(w,e),false).is_empty()

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
	return w.RaidNavigation.route(w,e,goal,break_objects,avoid_actors)

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
