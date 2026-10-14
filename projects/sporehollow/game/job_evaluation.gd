extends RefCounted
## One synchronous worker evaluation only. No cache survives movement or world mutation.
var origin: Vector2i
var frontier: Array=[]
var head=0
var distances={}
var routes={}
var uniform=false
func _init(w,start: Vector2i):
	origin=start;frontier=[start];distances[start]=0
	# Legacy A* weights closed doors. Keep that exact algorithm whenever those exist.
	uniform=w.jobs.size()>=24 and not w.structures.keys().any(func(p):return w.blocks(p) and w.structures[p].kind in w.Buildings.DOORS)
func distance_to(w,goals: Array) -> float:
	goals=goals.duplicate()
	goals.sort_custom(func(a,b):
		var da=w.distance(origin,a);var db=w.distance(origin,b)
		return da<db if da!=db else (a.y<b.y if a.y!=b.y else a.x<b.x))
	for goal in goals:
		if not uniform:
			if not routes.has(goal):
				var route=w.find_path(origin,goal)
				routes[goal]=INF if route.is_empty() else float(route.size()-1)
			if not is_inf(routes[goal]):return routes[goal]
			continue
		if goal!=origin and not w.walkable(goal):continue
		while not distances.has(goal) and head<frontier.size():
			var cell=frontier[head];head+=1
			preload("res://game/terrain_metrics.gd").count("evaluation_expanded")
			for n in w.neighbors(cell):
				if distances.has(n) or not w.walkable(n):continue
				distances[n]=distances[cell]+1;frontier.append(n)
		if distances.has(goal):return float(distances[goal])
	return INF
