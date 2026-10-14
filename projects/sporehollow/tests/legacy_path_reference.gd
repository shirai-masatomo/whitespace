extends RefCounted
# Frozen pre-geology path implementation for exact-route regression only.
static func find_path(w,start: Vector2i, goal: Vector2i, raider: bool = false, avoid_actors: bool = false, outdoor_only: bool = false, route_costs: Dictionary = {}, allow_exit: bool = false) -> Array:
	preload("res://game/terrain_metrics.gd").count("world.find_path")
	if start == goal: return [start]
	# Reject impossible endpoints before scanning the whole 100x68 map.
	if w.Story.terrain_block(w,goal) or (outdoor_only and w.is_indoor(goal)):return []
	if w.inside(goal):
		if not raider and not w.walkable(goal):return []
	elif not ((raider or allow_exit) and w.Land.is_exit(goal,w.W,w.H)):return []
	var frontier = [start]
	var cost = {start: 0.0}
	var previous = {start: start}
	while not frontier.is_empty():
		preload("res://game/terrain_metrics.gd").count("path_expanded")
		var best = 0
		for i in range(1, frontier.size()):
			if cost[frontier[i]] + w.distance(frontier[i], goal) < cost[frontier[best]] + w.distance(frontier[best], goal): best = i
		var p: Vector2i = frontier.pop_at(best)
		if p == goal:
			var path=[p]
			while p != start:
				p=previous[p]
				path.push_front(p)
			return path
		for n in w.neighbors(p):
			var exit_cell = (raider or allow_exit) and n == goal and w.Land.is_exit(n,w.W,w.H)
			if not w.inside(n) and not exit_cell: continue
			if w.Story.terrain_block(w,n): continue
			if outdoor_only and w.is_indoor(n): continue
			if avoid_actors and n != goal and w.actor_occupied(n, start): continue
			var blocked = w.blocks(n)
			if blocked and not raider and w.structures.get(n,{}).get("kind") not in w.Buildings.DOORS: continue
			# Compare walking actions with the actual number of object attacks needed.
			var value: float = cost[p] + 1.0 + maxf(0.0,route_costs.get(n,0.0)) + (ceilf(float(w.structures[n].hp) / w.Rules.KIDNAPPER.object_attack_power) if blocked else 0)
			if not cost.has(n) or value < cost[n]:
				cost[n] = value
				previous[n] = p
				if n not in frontier: frontier.append(n)
	return []
