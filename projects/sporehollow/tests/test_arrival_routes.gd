extends "res://tests/test_navigation.gd"
var results=[]

func gates(w,openings: Array):
	for y in range(1,w.H-1):
		if y not in openings:w.trees[Vector2i(1,y)]="tree"

func newcomer(w,p,role="kidnapper"):
	var e=enemy(w,p,role);e.entry=Vector2i(1,5);return e

func simulate(w,actors: Array,seconds: float) -> Dictionary:
	var crossed={};var still={};var longest={};var switches={};var goals={};var reverse=0;var physical=true
	for i in range(ceili(seconds/w.DT)):
		w.tick+=1
		for e in actors:
			var before=e.pos;var count=e.path.size();w.Combat.recover(e,w.DT);w.enemy_step(e)
			if not crossed.has(e.id):
				still[e.id]=still.get(e.id,0)+1 if before==e.pos else 0;longest[e.id]=maxi(longest.get(e.id,0),still[e.id])
				if e.get("arrival_complete",false) and w.inside(e.pos):crossed[e.id]=w.tick*w.DT
				var goal=e.get("arrival_goal")
				if goals.has(e.id) and goals[e.id]!=goal:switches[e.id]=switches.get(e.id,0)+1
				goals[e.id]=goal
				if e.path.size()>count and e.path.size()>=3 and e.path[-1]==e.path[-3]:reverse+=1
			physical=physical and w.enemies.filter(func(other):return not other.done and other.hp>0 and other.pos==e.pos).size()<=1
		if crossed.size()==actors.size():break
	return {"crossed_seconds":crossed,"longest_still_seconds":longest.values().max()*w.DT if not longest.is_empty() else 0,"goal_changes":switches,"entrance_changes":actors.map(func(e):return e.get("arrival_gate_changes",0)),"plans":actors.map(func(e):return e.get("arrival_plans",0)),"queries":actors.map(func(e):return e.get("arrival_queries",0)),"goals":goals,"reversals":reverse,"physical":physical}

func run():
	for openings in [[5,8],[5]]:
		var w=fresh();hidden(w);gates(w,openings)
		var actors=[newcomer(w,Vector2i(-1,6)),newcomer(w,Vector2i(-2,6)),newcomer(w,Vector2i(-1,7))]
		var report=simulate(w,actors,25);report.case="openings"+str(openings);results.append(report)
		check(report.crossed_seconds.size()==3 and report.physical,"Group clears available openings without overlap: "+str(openings))
		check(report.reversals<=(3 if openings.size()==1 else 0) and report.plans.all(func(n):return n<=4),"Routes stay bounded; inspecting closed alternatives permits a return: "+str(openings))
		if openings.size()==2:check(actors.any(func(e):return e.get("arrival_goal",Vector2i.ZERO).y==5) and actors.any(func(e):return e.get("arrival_goal",Vector2i.ZERO).y==8),"Comparable openings share nearby assignments")
	# Frozen front actor recreates the old single-file lock; alternate opening remains visible.
	var w=fresh();hidden(w);gates(w,[5,8]);var blocker=newcomer(w,Vector2i(0,5),"maid");blocker.arrival_complete=true;blocker.state="休む"
	var e=newcomer(w,Vector2i(-1,5));var before=e.pos
	for i in range(240):
		# Exact old outside movement rule; the frozen next cell prevents every step.
		var next=e.pos+(e.entry-w.exit_for(e.entry))
		if not w.actor_occupied(next,e.pos):e.pos=next
	check(e.pos==before,"Old fixed entry remains blocked for sixty seconds despite another opening")
	var report=simulate(w,[e],20);report.case="resting_front";report.baseline_stationary_seconds=60;results.append(report)
	check(report.crossed_seconds.size()==1 and e.arrival_goal.y==8 and report.physical,"Visible alternate entrance bypasses the resting front actor")
	# A short occupancy keeps the assigned route rather than causing target churn.
	w=fresh();hidden(w);gates(w,[5,8]);e=newcomer(w,Vector2i(-1,5));w.tick+=1;w.enemy_step(e)
	var goal=e.arrival_goal;var plans=e.arrival_plans;blocker=newcomer(w,e.arrival_route[1],"maid");blocker.arrival_complete=true
	for i in range(2):w.tick+=1;w.enemy_step(e)
	check(e.arrival_goal==goal and e.arrival_plans==plans,"Half-second temporary occupancy retains its route")
	blocker.done=true;report=simulate(w,[e],20);report.case="temporary_occupancy";results.append(report)
	check(report.crossed_seconds.size()==1,"Temporary occupancy resumes without a stale reservation")
	# Closing a selected lane triggers a bounded replan, not one choice per frame.
	for kind in ["tree","wall"]:
		w=fresh();hidden(w);gates(w,[5,8]);e=newcomer(w,Vector2i(-1,5));w.tick+=1;w.enemy_step(e)
		if kind=="tree":w.trees[Vector2i(1,5)]="tree"
		else:w.structures[Vector2i(1,5)]={"id":992,"kind":"wall","status":"ready","hp":100,"max_hp":100,"armor":0,"open":false}
		report=simulate(w,[e],20);report.case="midway_closure_"+kind;results.append(report)
		check(report.crossed_seconds.size()==1 and e.arrival_goal.y==8 and e.arrival_plans<=4,"New obstacle causes a bounded alternate-route choice: "+kind)
	# A distant unseen opening is not a global oracle; opening a visible lane resumes.
	w=fresh();hidden(w);gates(w,[14]);e=newcomer(w,Vector2i(-1,5));report=simulate(w,[e],6);report.case="unseen_only";results.append(report)
	check(report.crossed_seconds.is_empty() and (not e.has("arrival_goal") or w.distance(e.arrival_observation.from,e.arrival_goal)<=e.sight_range),"Unseen distant opening is not selected through hidden terrain")
	w.trees.erase(Vector2i(1,e.pos.y));report=simulate(w,[e],10);report.case="reopened";results.append(report)
	check(report.crossed_seconds.size()==1,"A locally reopened entrance restores progress")
	w=fresh();hidden(w);gates(w,[]);e=newcomer(w,Vector2i(-1,5));report=simulate(w,[e],10);report.case="fully_sealed";results.append(report)
	check(report.crossed_seconds.is_empty() and report.reversals<=1 and report.physical,"Complete terrain seal remains a real obstacle without repeated oscillation or teleport")
	# Reservation accounting is immediately visible, and excludes death/cancellation.
	w=fresh();hidden(w);gates(w,[5,8]);e=newcomer(w,Vector2i(-1,6));blocker=newcomer(w,Vector2i(-2,5));blocker.arrival_goal=Vector2i(0,5)
	var occupied=w.Arrival.choose(w,e);blocker.hp=0;var released=w.Arrival.choose(w,e)
	check(not occupied.is_empty() and not released.is_empty() and released.goal==Vector2i(0,5) and released.score<occupied.score,"Dead assignee releases its local soft cost immediately")
	blocker.hp=20;blocker.flee=true;w.Arrival.step(w,blocker)
	check(blocker.arrival_complete and not blocker.has("arrival_goal"),"Changed departure purpose releases arrival assignment")
	# Role capability and actual visible obstacle effort differ from arbitrary dispersal.
	for role in ["destroyer","maid"]:
		w=fresh();hidden(w);gates(w,[5,8]);e=newcomer(w,Vector2i(0,5),role)
		w.structures[Vector2i(1,5)]={"id":991,"kind":"wall","status":"ready","hp":4,"max_hp":80,"armor":0,"open":false}
		var weak=w.Arrival.choose(w,e)
		check(weak.goal==Vector2i(1,5) if role=="destroyer" else weak.goal!=Vector2i(1,5),"Weak obstacle choice respects the role's damage capability: "+role)
		w.structures[Vector2i(1,5)].hp=80;var strong=w.Arrival.choose(w,e)
		check(strong.goal!=Vector2i(1,5),"Expensive obstacle favors the reachable alternate: "+role)
	w=fresh();hidden(w);gates(w,[5,11]);e=newcomer(w,Vector2i(0,5));var direct=w.Arrival.choose(w,e)
	check(direct.goal==Vector2i(2,5),"An unoccupied close entrance wins over an unnecessary distant detour")
	# Actual captive exit crosses an incoming actor; incoming can use the side opening.
	w=fresh();gates(w,[5,8]);var carrier=newcomer(w,Vector2i(1,5));carrier.carry="keeper";w.keeper.state="captured";w.keeper.carrier=carrier.id;w.keeper.pos=carrier.pos
	e=newcomer(w,Vector2i(0,5));report=simulate(w,[carrier,e],20);report.case="opposing_capture_exit";results.append(report)
	check(carrier.done and w.story.defeat_reason=="keeper_abducted" and report.physical,"Captured keeper still exits across incoming traffic without overlap")
	FileAccess.open("user://arrival-routes.json",FileAccess.WRITE).store_string(JSON.stringify({"seed":31,"cases":results,"checks":records},"  "))
	for row in results:print("ARRIVAL_CASE ",JSON.stringify(row))
	print("ARRIVAL_ROUTES: %d checks, failures=%d"%[checks,failures]);quit(1 if failures else 0)
