extends RefCounted
# Shared reverse routes know terrain and the raid rally point, never hidden residents.
const POLICIES={"kidnapper":["residential"],"salaryman":["residential","stockpile"],"ninja":["residential"],"runner":["residential"],"thief":["stockpile"],"destroyer":["residential","stockpile"],"animal_tamer":[],"doberman":[],"dancer":[],"maid":[]}
static func passable(w,p:Vector2i,breaker:bool)->bool:
	if not w.inside(p) or w.Story.terrain_block(w,p):return false
	return breaker or not w.blocks(p) or (w.structures[p].kind in w.Buildings.DOORS and w.structures[p].get("lock_hp",0)<=0)
static func field(w,breaker:bool,outdoor:bool=false)->Dictionary:
	var key=str([breaker,outdoor]);var cache=w.raid_navigation.get(key,{})
	if cache.get("revision",-1)==w.navigation_revision:return cache
	var next={};var distance={};var queue=[]
	for surface in w.Story.idol_cells(w):
		for q in w.neighbors(surface):
			if passable(w,q,breaker) and not (outdoor and w.is_indoor(q)) and not distance.has(q):distance[q]=0;queue.append(q)
	var at=0
	while at<queue.size():
		var p=queue[at];at+=1
		for q in w.neighbors(p):
			if distance.has(q) or not passable(w,q,breaker) or (outdoor and w.is_indoor(q)):continue
			distance[q]=distance[p]+1;next[q]=p;queue.append(q)
	cache={"revision":w.navigation_revision,"next":next,"distance":distance};w.raid_navigation[key]=cache;return cache
static func rally(w,e)->Vector2i:
	var nav=field(w,w.Progression.Targets.can_damage_object(w,e),e.get("species","")=="doberman")
	var p=e.pos
	if nav.distance.has(p):
		e.raid_reason="黄金像を目印に進軍";e.search_state=e.raid_reason
		# Use the terminal of a shared route; no A* at every target evaluation.
		while nav.next.has(p):p=nav.next[p]
		return p
	return e.pos
static func objective(w,e)->Vector2i:
	if e.get("raid_goal_zone",-1)>=0 and e.get("raid_goal")==e.pos:
		if not e.has("raid_zone_visits"):e.raid_zone_visits={}
		for id in e.raid_zone_visits.keys():
			if e.raid_zone_visits[id]<=w.tick:e.raid_zone_visits.erase(id)
		while e.raid_zone_visits.size()>=20:e.raid_zone_visits.erase(e.raid_zone_visits.keys()[0])
		e.raid_zone_visits[e.raid_goal_zone]=w.tick+ceili(30.0/w.DT)
		e.raid_goal_zone=-1;e.raid_goal_until=0
	if e.get("raid_goal_revision",-1)==w.navigation_revision and w.tick<e.get("raid_goal_until",0):return e.get("raid_goal",e.pos)
	var goals=[]
	for kind in POLICIES.get(e.archetype,[]):
		for z in w.zones:
			if z.kind!=kind or e.get("raid_zone_visits",{}).get(z.id,0)>w.tick:continue
			var visible=z.cells.filter(func(p):return w.distance(e.pos,p)<=e.sight_range and w.line_of_sight(e.pos,p) and w.walkable(p))
			visible.sort_custom(func(a,b):return w.distance(e.pos,a)<w.distance(e.pos,b))
			if not visible.is_empty():goals.append({"pos":visible[0],"zone":z.id,"reason":"備蓄を襲う" if kind=="stockpile" else "住居へ侵入"})
	var result=e.pos
	for goal in goals:
		if goal.pos==e.pos:continue
		if not w.find_path(e.pos,goal.pos,w.Progression.Targets.can_damage_object(w,e),false,e.get("species","")=="doberman",{},false,true).is_empty():result=goal.pos;e.raid_reason=goal.reason;e.raid_goal_zone=goal.zone;break
	if result==e.pos:result=rally(w,e)
	if result==e.pos:e.raid_reason="襲撃目標への経路なし：地形変更を待つ"
	e.search_state=e.raid_reason;e.raid_goal=result;e.raid_goal_revision=w.navigation_revision;e.raid_goal_until=w.tick+ceili(6.0/w.DT)
	return result
static func route(w,e,goal:Vector2i,breaker:bool,avoid:bool)->Array:
	var key=str([goal,breaker,avoid,w.navigation_revision]);var cache=e.get("raid_routes",{}).get(str(avoid),{})
	var path=cache.get("path",[])
	if cache.get("key")==key:
		var at=path.find(e.pos)
		if at>=0:
			path=path.slice(at)
			if path.size()<2 or not w.Story.terrain_block(w,path[1]) and (not avoid or not w.actor_occupied(path[1],e.pos)):return path
		elif path.is_empty() and w.tick<cache.get("retry",0):return []
	# Shared field is usable only for rally routes, not combat or retreat.
	var nav=field(w,breaker,e.get("species","")=="doberman") if w.inside(e.pos) and not e.flee and e.get("carry","")=="" else {}
	path=[]
	if not nav.is_empty() and nav.distance.get(goal,-1)==0 and nav.distance.has(e.pos):
		var p=e.pos;path=[p]
		while nav.next.has(p):p=nav.next[p];path.append(p)
		if path[-1]!=goal or avoid and path.size()>1 and w.actor_occupied(path[1],e.pos):path=[]
	if path.is_empty():path=w.find_path(e.pos,goal,breaker,avoid,e.get("species","")=="doberman",{},true,true)
	if not e.has("raid_routes"):e.raid_routes={}
	e.raid_routes[str(avoid)]={"key":key,"path":path,"retry":w.tick+ceili(4.0/w.DT)}
	e.raid_route_queries=e.get("raid_route_queries",0)+1
	if path.is_empty():e.raid_reason="目的地へ到達不能：再評価待ち"
	return path
