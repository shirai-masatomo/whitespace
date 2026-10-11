extends RefCounted
## A one-animal guide searches the two occupied cells together; neither actor is cargo.
static func speed(w,j) -> float:
	var result=w.Jobs.SPEED*w.Life.factor(w)*w.Content.speed(w,w.keeper)
	for t in j.targets:
		var a=w.Orders.animal(w,t.id)
		if w.Orders.active(w,a):result=minf(result,a.move_speed*w.Content.speed(w,a))
	return result

static func key(keeper: Vector2i,animal: Vector2i) -> Vector4i:
	return Vector4i(keeper.x,keeper.y,animal.x,animal.y)

static func keeper_cell(state: Vector4i) -> Vector2i:
	return Vector2i(state.x,state.y)

static func animal_cell(state: Vector4i) -> Vector2i:
	return Vector2i(state.z,state.w)

static func cell_free(w,p: Vector2i,keeper: Vector2i,animal: Vector2i) -> bool:
	return p in [keeper,animal] or not w.actor_occupied(p,keeper)

static func route(w,a,destination: Vector2i) -> Array:
	var start=key(w.keeper.pos,a.pos)
	var open=[start];var previous={start:start};var index=0
	while index<open.size():
		var state=open[index];index+=1
		var k=keeper_cell(state);var p=animal_cell(state)
		if p==destination and w.distance(k,p)==1:
			var result=[]
			while state!=start:result.push_front(state);state=previous[state]
			return result
		for next_k in [k]+w.neighbors(k):
			if not w.walkable(next_k) or not cell_free(w,next_k,w.keeper.pos,a.pos):continue
			# Keep the keeper outdoors with an outdoor-only companion.
			if not w.SPECIES[a.species].can_enter_indoor and w.is_indoor(next_k):continue
			for next_a in [p]+w.neighbors(p):
				if w.distance(next_k,next_a)!=1 or not w.animal_walkable(a,next_a) or not cell_free(w,next_a,w.keeper.pos,a.pos):continue
				if next_k==p and next_a==k:continue # Never swap through one another in a narrow lane.
				var next=key(next_k,next_a)
				if previous.has(next):continue
				previous[next]=state;open.append(next)
	return []

static func step(w,j,a,t):
	if not w.Life.able(w) or w.jobs_held:return
	j.state="guiding";j.leading=true
	if a.pos==t.dest and w.distance(w.keeper.pos,a.pos)==1:
		t.done=true
		w.job_log.append({"tick":w.tick,"event":"guide_arrived","id":j.id,"animal_id":a.id,"destination":[a.pos.x,a.pos.y]})
		w.Orders.stop(w,j,true);w.Jobs.complete(w,j,true);return
	j.guide_credit=minf(1.0,j.get("guide_credit",0.0)+speed(w,j)*w.DT)
	if j.guide_credit<1:return
	var path=j.get("pair_route",[])
	if not path.is_empty():
		var k=keeper_cell(path[0]);var p=animal_cell(path[0])
		if w.distance(k,w.keeper.pos)>1 or w.distance(p,a.pos)>1 or not w.walkable(k) or not w.animal_walkable(a,p) or not cell_free(w,k,w.keeper.pos,a.pos) or not cell_free(w,p,w.keeper.pos,a.pos):path=[]
	if path.is_empty():path=route(w,a,t.dest)
	j.pair_route=path
	if path.is_empty():j.state="blocked";j.block_reason="一緒に通れる道を空けてください";return
	var next=path[0];var k=keeper_cell(next);var p=animal_cell(next)
	if k!=w.keeper.pos and not w.Combat.pay(w.keeper,"move"):
		j.state="blocked";j.block_reason="息を整えています";return
	j.guide_credit-=1;path.pop_front()
	if k!=w.keeper.pos:w.keeper_path.append([k.x,k.y])
	w.open_for_ally(k);w.open_for_ally(p)
	w.keeper.pos=k;a.pos=p;a.state="ついていく"
	j.blocked_ticks=0

static func walk_leader(w,j,goals: Array):
	# Existing group collection/arrival policy, with the same pace on both sides.
	var base=w.Jobs.SPEED*w.Life.factor(w)*w.Content.speed(w,w.keeper)*w.DT
	w.keeper.move_credit-=base-speed(w,j)*w.DT
	w.Jobs.walk(w,j,goals)
