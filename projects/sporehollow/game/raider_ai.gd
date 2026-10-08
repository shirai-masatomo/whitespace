extends RefCounted
## Perception alone may read the keeper's real position.
static func perceive(e: Dictionary, w):
	w.Progression.Targets.observe(w,e)
	var visible = w.Life.targetable(w,e.get("archetype","")=="kidnapper") and w.distance(e.pos, w.keeper.pos) <= e.sight_range and w.line_of_sight(e.pos, w.keeper.pos)
	if not w.Life.targetable(w,e.get("archetype","")=="kidnapper"):
		e.last_known_keeper_position=null;e.search_goal=null
	if visible != e.can_see_keeper:
		if visible: w.Life.danger(w, "spotted")
		e.sight_reaction = "!" if visible else "?"
		e.sight_reaction_until = w.tick + 6
		w.sight_log.append({"tick": w.tick, "id": e.id, "visible": visible, "position": [e.pos.x, e.pos.y]})
		if w.sight_log.size() > 32: w.sight_log.pop_front()
	e.can_see_keeper = visible
	if visible:
		e.last_known_keeper_position = w.keeper.pos
		e.search_state = "追跡"
	elif e.last_known_keeper_position != null: e.search_state = "最後に見た場所へ"
	else: e.search_state = "探索中"

static func target(e: Dictionary, w) -> Vector2i:
	if e.flee or e.carry == "keeper": return w.Story.exit_goal(w,e)
	if e.can_see_keeper: return e.last_known_keeper_position
	if e.last_known_keeper_position != null:
		if e.pos != e.last_known_keeper_position: return e.last_known_keeper_position
		e.last_known_keeper_position = null
		e.search_goal = null
		e.search_state = "周辺を探す"
	if e.search_goal == null or e.pos == e.search_goal or w.tick >= e.search_goal_until:
		var options = []
		for y in [3, 8, 13]:
			for x in [4, 10, 16, 22]: options.append(Vector2i(x, y))
		# Least visited coverage first; never uses the unseen keeper.
		options.sort_custom(func(a, b):
			var ca = e.search_visits.get(a, 0) * 100 + w.distance(e.pos, a)
			var cb = e.search_visits.get(b, 0) * 100 + w.distance(e.pos, b)
			return (a.y * w.W + a.x) < (b.y * w.W + b.x) if ca == cb else ca < cb)
		e.search_goal = options[0]
		e.search_visits[e.search_goal] = e.search_visits.get(e.search_goal, 0) + 1
		e.search_goal_until = w.tick + 64
	return e.search_goal
