extends RefCounted
## Reachable escape goals avoid one-step distance oscillation in corners and U-shaped cover.
static func safety(w,p: Vector2i,threats: Array) -> int:
	var nearest=10000
	for threat in threats:nearest=mini(nearest,w.distance(p,threat))
	return nearest

static func route(w,a,threats: Array) -> Array:
	var frontier=[a.pos];var previous={a.pos:a.pos};var best=a.pos
	var best_safety=safety(w,a.pos,threats);var safe_distance=a.detection_range+1
	while not frontier.is_empty():
		var p=frontier.pop_front();var value=safety(w,p,threats)
		if value>best_safety:best=p;best_safety=value
		if value>safe_distance:best=p;break # Nearest reachable safety, not a random distant corner.
		for n in w.neighbors(p):
			if previous.has(n) or not w.animal_walkable(a,n) or w.actor_occupied(n,a.pos):continue
			previous[n]=p;frontier.append(n)
	var path=[]
	while best!=a.pos:path.push_front(best);best=previous[best]
	return path

static func step(w,a,visible: Array):
	if not visible.is_empty():a.escape_threats=visible.map(func(e):return e.pos)
	var threats=a.get("escape_threats",[])
	if threats.is_empty() or a.move_credit<1:return
	var path=a.get("escape_route",[])
	var goal=a.get("escape_goal",a.pos)
	if path.is_empty() or w.distance(a.pos,path[0])!=1 or not w.animal_walkable(a,path[0]) or w.actor_occupied(path[0],a.pos) or safety(w,goal,threats)<=a.detection_range:
		path=route(w,a,threats);a.escape_route=path
		a.escape_goal=path[-1] if not path.is_empty() else a.pos
	if path.is_empty():return # At the safest reachable place; do not step back into danger.
	a.move_credit-=1;a.pos=path.pop_front()

static func clear(a):
	for field in ["escape_goal","escape_route","escape_threats"]:a.erase(field)
