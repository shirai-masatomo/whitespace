extends RefCounted
const SPEED=0.8 # cells/second; slower than ordinary workers
const GREETINGS=["いらっしゃい、何か見ていくかい？","今日はいいものがあるよ","少し休ませてもらうよ"]
static func schedule(w):
	var day=int(w.campaign.day);var roll=w.Biome.unit(w.seed_value,day,0,857)
	var minute=600+int(roll*150) # 10:00--12:29; generous time before 19:00.
	var now=w.Cycle.clock(w).minute_of_day()
	w.merchant_arrive_tick=w.tick+ceili(maxi(0,minute-now)*w.Cycle.Clock.DAY_SECONDS/1440.0/w.DT)
	w.merchant_leave_at=INF
	w.merchant_visit={"state":"scheduled" if day>=2 and now<=minute else "gone","day":day,"route":[],"credit":0.0,"steps":0,"pause_until":0,"retry":0}
static func safe(w,p)->bool:
	return not w.enemies.any(func(e):return not e.done and e.hp>0 and w.distance(e.pos,p)<7)
static func exclusion(w)->Dictionary:
	var cells={};var blocked={}
	for p in w.structures:
		for q in w.Buildings.cells(w.structures[p].kind,p):cells[q]=true
	for p in w.floors:cells[p]=true
	for z in w.zones:
		for p in z.cells:cells[p]=true
	for j in w.jobs:
		if w.BUILD.has(j.kind):
			for p in w.Buildings.cells(j.kind,j.pos):cells[p]=true
	for p in cells:
		blocked[p]=true
		for q in w.neighbors(p):blocked[q]=true
	return blocked
static func clearance(w,p)->bool:
	for q in [p]+w.neighbors(p):
		if w.live_structure(q) or w.floors.get(q,{}).get("status")=="ready":return false
		if w.zones.any(func(z):return q in z.cells):return false
		if w.jobs.any(func(j):return w.BUILD.has(j.kind) and q in w.Buildings.cells(j.kind,j.pos)):return false
	return true
static func goals(w)->Array:
	var blocked=exclusion(w)
	var result=[]
	for a in w.workers.values():
		if a.hp<=0 or not a.get("placed",false) or a.get("state")!="free" or not safe(w,a.pos):continue
		for dy in range(-3,4):
			for dx in range(-3,4):
				var q=a.pos+Vector2i(dx,dy)
				if absi(dx)+absi(dy) in [3,4] and w.walkable(q) and not w.actor_occupied(q,q+Vector2i(999,999)) and q not in result and not blocked.has(q):result.append(q)
	if result.is_empty():
		for q in w.neighbors(w.keeper.pos):
			if w.walkable(q) and safe(w,q) and not blocked.has(q):result.append(q)
	return result
static func route_to(w,start:Vector2i,targets:Array,avoid_sites:bool=true)->Array:
	# One multi-goal BFS, not a full A* per candidate. Only on arrival/replan.
	var blocked=exclusion(w) if avoid_sites else {}
	var wanted={};var previous={start:start};var queue=[start];var i=0
	for q in targets:
		if w.walkable(q):wanted[q]=true
	while i<queue.size():
		var p=queue[i];i+=1
		if wanted.has(p):
			var path=[p]
			while p!=start:p=previous[p];path.push_front(p)
			return path
		for q in w.neighbors(p):
			if avoid_sites and not wanted.has(q) and blocked.has(q):continue
			if not previous.has(q) and w.walkable(q) and not w.actor_occupied(q,start):previous[q]=p;queue.append(q)
	return route_to(w,start,targets,false) if avoid_sites else []
static func arrive(w):
	var visit=w.merchant_visit;var destinations=goals(w);var best=[]
	# Multi-source reverse BFS: all safe stopping cells share one border search.
	var previous={};var queue=[];var border={};var cursor=0
	for q in w.Land.border_cells(w.W,w.H):border[q]=true
	for q in destinations:
		if not previous.has(q):previous[q]=q;queue.append(q)
	while cursor<queue.size():
		var cell=queue[cursor];cursor+=1
		if border.has(cell) and not w.actor_occupied(cell,cell+Vector2i(999,999)):
			best=[cell]
			while previous[cell]!=cell:cell=previous[cell];best.append(cell)
			best.reverse();break
		for q in w.neighbors(cell):
			if w.walkable(q) and not w.actor_occupied(q,q+Vector2i(999,999)) and not previous.has(q):previous[q]=cell;queue.append(q)
	if best.is_empty():visit.state="gone";w.PlayerEvents.add(w,"商人は安全な入口を見つけられず、来訪を見合わせました");return
	# Reserve the travel, occasional pauses and thirty seconds on site before night.
	var travel=(best.size()-1)/SPEED+floori((best.size()-1)/9.0)*1.25
	if travel+30.0>w.Cycle.until(w,1140):visit.state="gone";w.PlayerEvents.add(w,"商人は日暮れまでに到着できないため、来訪を見合わせました");return
	best.reverse();w.MERCHANT_CELL=best[0];visit.previous=best[0];visit.route=best;visit.state="approach";visit.arrived=w.tick;visit.move_tick=w.tick
	visit.exit=best[0];visit.goal=best[-1];visit.leave_after=w.tick+ceili(30.0/w.DT);visit.hard_end=w.tick+ceili((w.Cycle.until(w,1140)+40.0)/w.DT)
	w.PlayerEvents.add(w,"行商人が牧場にやってきました")
static func leave(w):
	var v=w.merchant_visit
	if v.state=="return":return
	w.cancel_merchant("商人が帰路に就きます" if w.merchant_approach!=null else "")
	v.state="return";v.route=[];v.retry=0;v.return_started=w.tick
static func step(w):
	var v=w.merchant_visit
	if v.is_empty():schedule(w);v=w.merchant_visit
	if v.state=="gone":return
	if v.state=="scheduled":
		if w.tick>=w.merchant_arrive_tick:arrive(w)
		return
	if w.Cycle.period(w)=="night":leave(w)
	elif w.tick>=v.get("leave_after",w.tick+1) and v.state=="waiting" and not w.merchant_waiting():leave(w)
	if v.state=="waiting":
		var signature=[w.navigation_revision,w.jobs.map(func(j):return j.id),hash(w.zones)]
		if v.get("site_signature",[])!=signature:
			v.site_signature=signature
			if not clearance(w,w.MERCHANT_CELL):
				var destinations=goals(w);destinations.erase(w.MERCHANT_CELL)
				var escape=route_to(w,w.MERCHANT_CELL,destinations)
				if escape.size()>1:v.state="approach";v.goal=escape[-1];v.route=escape
				else:leave(w)
		if v.state=="waiting":return
	if v.state=="return" and w.tick>=v.hard_end:
		v.state="gone";w.PlayerEvents.add(w,"商人は帰路を確保できず、退場しました");return
	if w.tick<v.pause_until or w.tick<v.retry:return
	var route=v.route
	if route.is_empty() or route[0]!=w.MERCHANT_CELL or route.size()>1 and not w.walkable(route[1]):
		var targets=w.Land.border_cells(w.W,w.H) if v.state=="return" else ([v.goal] if w.walkable(v.goal) and safe(w,v.goal) and clearance(w,v.goal) and not w.actor_occupied(v.goal,w.MERCHANT_CELL) else goals(w))
		route=route_to(w,w.MERCHANT_CELL,targets);v.route=route
		if route.is_empty():v.retry=w.tick+ceili(3.0/w.DT);return
	if route.size()==1:
		if v.state=="return":
			# The cart reaches a legal map edge, then leaves through that edge.
			v.previous=w.MERCHANT_CELL;w.MERCHANT_CELL=w.exit_for(w.MERCHANT_CELL);v.state="gone";return
		v.state="waiting";v.leave_after=maxi(v.leave_after,w.tick+ceili(30.0/w.DT));w.merchant_leave_at=v.leave_after*w.DT
		v.speech=GREETINGS[posmod(w.seed_value+v.day,GREETINGS.size())];v.speech_until=w.tick+ceili(6.0/w.DT);return
	v.credit=minf(1.0,v.credit+SPEED*w.DT)
	if v.credit<1:return
	if w.actor_occupied(route[1],w.MERCHANT_CELL):
		v.retry=w.tick+4
		if not v.has("blocked_at"):v.blocked_at=w.tick
		if w.tick-v.blocked_at>16:v.route=[]
		return
	w.open_for_ally(route[1]);v.erase("blocked_at");v.credit-=1;v.previous=w.MERCHANT_CELL;w.MERCHANT_CELL=route[1];v.move_tick=w.tick;route.pop_front();v.steps+=1
	if v.previous.x!=w.MERCHANT_CELL.x:v.facing=signi(w.MERCHANT_CELL.x-v.previous.x)
	if v.steps%9==0:v.pause_until=w.tick+ceili(1.25/w.DT)
static func visible(w)->bool:return w.merchant_visit.get("state","") in ["approach","waiting","return"]
static func available(w)->bool:return w.merchant_visit.get("state","")=="waiting" and w.Cycle.period(w)!="night"
static func pixel_cell(w,accumulated:float)->Vector2:
	var v=w.merchant_visit;var t=clampf(((w.tick-v.get("move_tick",w.tick))*w.DT+accumulated)*SPEED,0,1)
	return Vector2(v.get("previous",w.MERCHANT_CELL)).lerp(Vector2(w.MERCHANT_CELL),t)
