extends RefCounted
## Existing living individuals, addressed by ID; never inventory or cargo.
static func animal(w,id: int) -> Dictionary:
	for a in w.animals:
		if a.id==id: return a
	return {}

static func active(w,a) -> bool:
	return not a.is_empty() and a.placed and a.hp>0 and w.campaign.day>a.unavailable_through_day

static func enqueue(w,kind: String,ids: Array,p: Vector2i) -> bool:
	if not w.working() or w.jobs.size()>=8: w.say("予定は8件までです"); return false
	var whistle = w.item_count("whistle")>0
	var targets=[]
	var rejected=[]
	var assigned=[]
	var leader_goal=p
	if kind=="guide":
		var leader_sites=w.neighbors(p).filter(func(c):return w.walkable(c) and not w.actor_occupied(c,w.keeper.pos) and not w.find_path(w.keeper.pos,c).is_empty())
		if leader_sites.is_empty(): w.say("牧場主が案内先へ近づけません"); return false
		leader_goal=leader_sites[0]
	for id in ids.slice(0,8):
		if targets.size()>=(8 if whistle else 1): rejected.append({"id":id,"reason":"ホイッスルなしでは1匹ずつ"}); continue
		var a=animal(w,id)
		if not active(w,a) or kind not in w.SPECIES[a.species].orders:
			rejected.append({"id":id,"reason":"非対応、または療養中"}); continue
		if w.jobs.any(func(j):return id in j.get("targets",[]).map(func(t):return t.id)): rejected.append({"id":id,"reason":"予約済み"}); continue
		var dest=a.pos
		if kind=="guide":
			var sites=[]
			for y in range(maxi(1,p.y-3),mini(w.H-1,p.y+4)):
				for x in range(maxi(1,p.x-3),mini(w.W-1,p.x+4)):
					var cell=Vector2i(x,y)
					if cell!=leader_goal and cell not in assigned and w.animal_walkable(a,cell) and not w.actor_occupied(cell,a.pos): sites.append(cell)
			sites.sort_custom(func(a1,b1):
				var da=w.distance(a1,p); var db=w.distance(b1,p)
				return da<db if da!=db else (a1.y<b1.y if a1.y!=b1.y else a1.x<b1.x))
			var found=false
			for cell in sites:
				if not w.find_path(a.pos,cell,false,false,not w.SPECIES[a.species].can_enter_indoor).is_empty(): dest=cell; found=true; break
			if not w.SPECIES[a.species].can_enter_indoor and w.is_indoor(p): found=false
			if not found: rejected.append({"id":id,"reason":"届く空き場所がない、または屋内不可"}); continue
		assigned.append(dest)
		targets.append({"id":id,"dest":dest,"issued":false,"done":false,"previous":a.mode,"previous_duration":maxi(0,a.order_until-w.tick)})
	if targets.is_empty():
		w.say(rejected[0].reason if not rejected.is_empty() else "仲間を選んでください"); return false
	if w.jobs.is_empty() and w.manual_goal==null and w.Life.able(w) and w.job_hold_reason in ["travel","manual","rescue","danger","rest_end"]: w.Jobs.hold(w,"")
	w.jobs.append({"id":w.next_job_id,"kind":"animal_order","order":kind,"leader_goal":leader_goal,"command_pos":p,"targets":targets,"pos":p if kind=="guide" else animal(w,targets[0].id).pos,"animal_id":targets[0].id,"state":"pending","started":false,"reserved":0,"resource":"","range":w.Rules.WHISTLE.range if whistle else 1})
	w.Life.wake_auto(w)
	w.say("指示 %d匹" % targets.size() + ("・未割当 %d匹（%s）" % [rejected.size(),rejected[0].reason] if not rejected.is_empty() else ""))
	w.next_job_id+=1
	w.job_log.append({"tick":w.tick,"event":"order_reserved","id":w.next_job_id-1,"unassigned":rejected,"targets":targets.map(func(t):return t.id),"order":kind})
	return true

static func stop(w,j):
	for t in j.targets:
		var a=animal(w,t.id)
		if a.is_empty() or a.get("guide_job",-1)!=j.id: continue
		a.erase("guide_job")
		a.mode=t.previous
		a.order_until=w.tick+t.previous_duration
		a.order=a.pos; a.home=a.pos
		a.state="見張り" if a.species=="shiba" else "散歩"

static func interrupt(w):
	for j in w.jobs.duplicate():
		if j.kind=="animal_order" and j.order=="guide" and j.targets.any(func(t):return t.issued):
			stop(w,j); w.Jobs.complete(w,j,false)

static func step(w,j):
	if j.state=="blocked":
		j.blocked_ticks=j.get("blocked_ticks",0)+1
		if j.blocked_ticks>=80:
			report(w,"道が開かないため誘導を終了しました"); stop(w,j); w.Jobs.complete(w,j,false); return
	for t in j.targets:
		if t.done: continue
		var a=animal(w,t.id)
		if not active(w,a): t.done=true; a.erase("guide_job"); continue
		if not t.issued:
			j.state="walking"
			if w.distance(w.keeper.pos,a.pos)>j.range or (not w.Rules.WHISTLE.through_walls and not w.line_of_sight(w.keeper.pos,a.pos)):
				var goals=command_goals(w,a,j.range)
				w.Jobs.walk(w,j,goals)
				return
			t.issued=true
			if j.range>1:
				w.keeper.whistle_until=w.tick+4
				w.milestones.append({"tick":w.tick,"kind":"whistle"})
			w.job_log.append({"tick":w.tick,"event":"order_issued","animal_id":a.id,"distance":w.distance(w.keeper.pos,a.pos),"destination":[t.dest.x,t.dest.y]})
			# One bounded response, with loyalty influencing refusal; hens accept guidance provisionally.
			if a.species=="shiba" and w.daily_rng.randf()>0.90+a.loyalty*0.001:
				t.done=true; report(w,"今は気が乗らないようです"); continue
			if j.order!="guide":
				w.issue_order(j.order,j.command_pos if j.order=="attack_target" else a.pos,a.id); t.done=true
			else:
				a.guide_job=j.id
				w.release_kennel(a)
				a.pending={}
			return
	if j.order!="guide": w.Jobs.complete(w,j,true); return
	var pending=j.targets.filter(func(t):return not t.done)
	if pending.is_empty(): stop(w,j); w.Jobs.complete(w,j,true); return
	var goals=[j.leader_goal].filter(func(c):return w.walkable(c) and not w.actor_occupied(c,w.keeper.pos))
	var at_end=w.keeper.pos in goals
	j.leading=not at_end
	if not at_end:
		if not w.is_indoor(w.keeper.pos) and pending.any(func(t):return w.distance(animal(w,t.id).pos,w.keeper.pos)>3):
			j.state="guiding"; return
		w.Jobs.walk(w,j,goals)
	else: j.state="guiding"
	for t in pending:
		var a=animal(w,t.id)
		if a.pos==t.dest and at_end:
			t.done=true
			w.job_log.append({"tick":w.tick,"event":"guide_arrived","id":j.id,"animal_id":a.id,"destination":[a.pos.x,a.pos.y]})

static func follow(w,a) -> bool:
	if not a.has("guide_job"): return false
	var found=w.jobs.filter(func(j):return j.id==a.guide_job)
	if found.is_empty(): a.erase("guide_job"); return false
	var j=found[0]
	if w.jobs[0].id!=j.id: a.state="誘導待ち"; return true
	var t=j.targets.filter(func(t):return t.id==a.id)[0]
	if w.keeper.get("yield_cell",Vector2i(-1,-1))==a.pos and not w.jobs_held:
		var spaces=w.neighbors(a.pos).filter(func(c):return w.animal_walkable(a,c) and not w.actor_occupied(c,a.pos))
		if not spaces.is_empty():
			a.move_credit=minf(1.9,a.move_credit+a.move_speed*w.DT)
			if a.move_credit>=1: a.move_credit-=1; a.pos=spaces[0]; w.open_for_ally(a.pos)
			a.state="道を空ける"; return true
	if t.done: a.state="誘導先で待つ"; return true
	var goal=t.dest
	if j.get("leading",true) or not j.targets.all(func(t):return t.issued or t.done):
		if w.distance(a.pos,w.keeper.pos)<=2: a.state="ついていく"; return true
		var cells=[]
		for y in range(w.keeper.pos.y-2,w.keeper.pos.y+3):
			for x in range(w.keeper.pos.x-2,w.keeper.pos.x+3):
				var c=Vector2i(x,y)
				if w.distance(c,w.keeper.pos)<=2 and w.animal_walkable(a,c) and not w.actor_occupied(c,a.pos) and not w.animal_path(a,a.pos,c).is_empty(): cells.append(c)
		cells.sort_custom(func(c,d):return w.distance(a.pos,c)<w.distance(a.pos,d))
		if cells.is_empty(): return true
		goal=cells[0]
	a.state="ついていく"
	a.move_credit=minf(1.9,a.move_credit+a.move_speed*w.DT)
	if a.move_credit>=1:
		var next=w.animal_next(a,goal)
		if next!=a.pos:
			a.move_credit-=1; w.open_for_ally(next); a.pos=next
		elif a.pos!=goal:
			j.state="blocked"; j.block_reason="誘導先への通路を空けてください"
	return true

static func command_goals(w,a,reach: int) -> Array:
	var goals=[]
	for y in range(1,w.H-1):
		for x in range(1,w.W-1):
			var cell=Vector2i(x,y)
			if w.distance(cell,a.pos)<=reach and (w.Rules.WHISTLE.through_walls or w.line_of_sight(cell,a.pos)) and w.walkable(cell) and not w.actor_occupied(cell,w.keeper.pos): goals.append(cell)
	return goals

static func report(w,text: String):
	w.say(text)
	w.milestones.append({"tick":w.tick,"kind":"order_notice","text":text})
