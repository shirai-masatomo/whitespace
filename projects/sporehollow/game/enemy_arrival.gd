extends RefCounted
## Local, visible border alternatives. No RNG, hidden target or global entrance oracle.
const OCCUPIED_COST=12.0
const ASSIGNED_COST=3.0
const BLOCKED_REPLAN_SECONDS=0.75

static func side(w,e) -> Vector2i:
	return e.entry-w.exit_for(e.entry)

static func depth(w,p: Vector2i,inward: Vector2i) -> int:
	if inward.x==1:return p.x
	if inward.x==-1:return w.W-1-p.x
	if inward.y==1:return p.y
	return w.H-1-p.y

static func known(w,e,p: Vector2i) -> bool:
	return w.distance(e.pos,p)<=e.sight_range and w.line_of_sight(e.pos,p,true)

static func choose(w,e) -> Dictionary:
	var inward=side(w,e);var open=[e.pos];var cost={e.pos:0.0};var previous={};var goals=[];var scouting={}
	var fronts=w.entries.filter(func(gate):return gate-w.exit_for(gate)==inward).map(func(gate):return w.exit_for(gate))
	var closed=e.get("arrival_closed",{})
	for front in fronts:
		if known(w,e,front+inward):closed[front]=w.Story.terrain_block(w,front+inward)
	e.arrival_closed=closed
	var can_break=w.Progression.Targets.can_damage_object(w,e)
	var nearby=w.enemies.filter(func(other):return other.id!=e.id and not other.done and other.hp>0 and known(w,e,other.pos))
	while not open.is_empty():
		open.sort_custom(func(p,q):return cost[p]<cost[q] if cost[p]!=cost[q] else (p.y*w.W+p.x)<(q.y*w.W+q.x))
		var p=open.pop_front()
		if w.inside(p) and (depth(w,p,inward)>=2 or w.blocks(p)):goals.append(p);continue
		# The known entrance marker can be approached before its inside is visible.
		# Inspect it from the forest side; never infer the hidden passage is open.
		if p in fronts and p!=e.pos and not closed.get(p,false):
			goals.append(p);scouting[p]=true
		for n in w.neighbors(p):
			if depth(w,n,inward)>2 or not known(w,e,n) or w.Story.terrain_block(w,n):continue
			if inward.x!=0 and (n.y<1 or n.y>=w.H-1):continue
			if inward.y!=0 and (n.x<1 or n.x>=w.W-1):continue
			var obstacle=w.structures.get(n,{})
			if w.blocks(n) and not can_break and (obstacle.kind not in w.Buildings.DOORS or obstacle.get("lock_hp",0)>0):continue
			var effort=1.0
			if w.blocks(n):effort+=ceilf(float(obstacle.get("lock_hp",0) if obstacle.kind in w.Buildings.DOORS else obstacle.hp)/maxf(1,e.object_attack_power))
			if w.actor_occupied(n,e.pos):effort+=OCCUPIED_COST
			for other in nearby:
				if not other.get("arrival_complete",false) and other.get("arrival_goal") == n:effort+=ASSIGNED_COST
			var value=cost[p]+effort
			if not cost.has(n) or value<cost[n]:
				cost[n]=value;previous[n]=p
				if n not in open:open.append(n)
	if goals.is_empty():return {}
	# An already perceived goal only breaks close cost ties; unseen objectives stay unknown.
	var objective=e.get("chosen_target",{}).get("pos",e.get("last_known_keeper_position"))
	var scores={}
	for goal in goals:
		var free=w.neighbors(goal).filter(func(n):return w.inside(n) and known(w,e,n) and w.walkable(n) and not w.actor_occupied(n,e.pos)).size()
		var onward=2.0 if scouting.has(goal) else (0.0 if w.blocks(goal) else maxi(0,2-free)*2.0)
		if scouting.has(goal) and known(w,e,goal+inward) and w.actor_occupied(goal+inward,e.pos):onward+=OCCUPIED_COST
		scores[goal]=cost[goal]+onward+(w.distance(goal,objective)*0.05 if objective is Vector2i else 0.0)
	goals.sort_custom(func(p,q):return scores[p]<scores[q] if scores[p]!=scores[q] else (p.y*w.W+p.x)<(q.y*w.W+q.x))
	var goal=goals[0];var route=[goal];var p=goal
	while p!=e.pos:p=previous[p];route.push_front(p)
	var gate=goal+inward*(1-depth(w,goal,inward))
	return {"goal":goal,"gate":gate,"route":route,"score":scores[goal],"candidates":goals.size(),"scouting":scouting.has(goal)}

static func step(w,e) -> bool:
	if e.get("arrival_complete",false):return false
	if e.flee or e.carry!="" or e.get("led_animal",-1)>=0 or w.story.idol.get("carrier",-1)==e.id:
		e.arrival_complete=true;e.erase("arrival_goal");e.erase("arrival_gate");e.erase("arrival_route");return false
	var inward=side(w,e)
	if w.inside(e.pos) and depth(w,e.pos,inward)>=2:
		e.arrival_complete=true;e.erase("arrival_route");return false
	# Far from the border, its alternatives are not visible yet. Keep the existing approach.
	if 2-depth(w,e.pos,inward)>e.sight_range:
		e.state="森から接近";e.move_credit=minf(1.9,e.move_credit+e.move_speed*w.Content.speed(w,e)*w.DT)
		if e.move_credit>=1:
			var next=e.pos+inward
			if not w.actor_occupied(next,e.pos):
				var before=e.pos;w.move_enemy(e,next)
				if e.pos!=before:e.move_credit-=1
		return true
	var route=e.get("arrival_route",[])
	if not route.is_empty() and route[0]!=e.pos:route=[]
	if w.tick<e.get("arrival_retry_tick",0):e.state="入口を探す";return true
	var blocked=route.size()>1 and (w.actor_occupied(route[1],e.pos) or w.Story.terrain_block(w,route[1]))
	if route.size()>1 and w.blocks(route[1]):
		var obstacle=w.structures[route[1]]
		var cannot_break=not w.Progression.Targets.can_damage_object(w,e) and (obstacle.kind not in w.Buildings.DOORS or obstacle.get("lock_hp",0)>0)
		blocked=blocked or cannot_break or e.get("arrival_barriers",{}).get(route[1],-1)!=obstacle.id
	e.arrival_blocked_ticks=e.get("arrival_blocked_ticks",0)+1 if blocked else 0
	if route.size()<2 or e.arrival_blocked_ticks>=ceili(BLOCKED_REPLAN_SECONDS/w.DT):
		e.arrival_queries=e.get("arrival_queries",0)+1
		var plan=choose(w,e)
		if not plan.is_empty():
			route=plan.route;e.arrival_goal=plan.goal;e.arrival_route=route
			if e.has("arrival_last_gate") and e.arrival_last_gate!=plan.gate:e.arrival_gate_changes=e.get("arrival_gate_changes",0)+1
			e.arrival_gate=plan.gate;e.arrival_last_gate=plan.gate
			e.arrival_barriers={}
			for cell in route:
				if w.blocks(cell):e.arrival_barriers[cell]=w.structures[cell].id
			e.arrival_plans=e.get("arrival_plans",0)+1;e.arrival_blocked_ticks=0
			e.arrival_observation={"tick":w.tick,"goal":plan.goal,"score":plan.score,"candidates":plan.candidates,"scouting":plan.scouting,"from":e.pos,"sight":e.sight_range}
		else:
			e.arrival_route=[];e.erase("arrival_goal");e.erase("arrival_gate");e.arrival_retry_tick=w.tick+ceili(BLOCKED_REPLAN_SECONDS/w.DT)
			e.state="入口を探す"
			# Approach a visible obstacle to discover side openings; never enter unseen terrain.
			var next=e.pos+inward
			if not w.inside(next) and not w.Story.terrain_block(w,next) and not w.actor_occupied(next,e.pos):
				e.move_credit=minf(1.9,e.move_credit+e.move_speed*w.Content.speed(w,e)*w.DT)
				if e.move_credit>=1:w.move_enemy(e,next);e.move_credit-=1
			return true
	e.state="入口を空ける" if w.inside(e.pos) else ("別の入口へ" if e.arrival_gate!=e.entry else "森から接近")
	e.move_credit=minf(1.9,e.move_credit+e.move_speed*w.Content.speed(w,e)*w.DT)
	if e.move_credit<1 or route.size()<2:return true
	var next=route[1]
	if w.actor_occupied(next,e.pos):return true
	e.move_credit-=1
	var before=e.pos;w.move_enemy(e,next) # Physical walls/collision/stamina stay authoritative.
	if e.pos!=before:route.pop_front();e.arrival_route=route;e.arrival_blocked_ticks=0
	return true
