extends "res://tests/test_navigation.gd"
## One bounded two-case measurement. This is enemy AI/entry traffic, not renderer FPS.
const GAME_COMMIT="50f66c967a91fdfd26b1d0269c316ac452972841"
const MAX_TICKS=480 # 120 simulated seconds, less than the normal 180-second night.
const WALL_BUDGET_MS=60000
var rows=[]

func percentile(values: Array,fraction: float) -> float:
	var sorted=values.duplicate();sorted.sort()
	return sorted[clampi(ceili(sorted.size()*fraction)-1,0,sorted.size()-1)]/1000.0 if not sorted.is_empty() else 0.0

func timing(values: Array) -> Dictionary:
	var sum=0
	for value in values:sum+=value
	return {"samples":values.size(),"mean_ms":float(sum)/maxi(1,values.size())/1000.0,"p95_ms":percentile(values,0.95),"max_ms":percentile(values,1.0),"over_fixed_tick_budget":values.filter(func(value):return value>250000).size()}

func measure(label: String,roles: Array,debug: bool):
	var w=fresh();hidden(w);w.debug_enabled=true;w.keeper.pos=Vector2i(2,5)
	# Existing two-opening fixture, not the already-measured single-opening case.
	for y in range(1,w.H-1):
		if y not in [5,8]:w.trees[Vector2i(1,y)]="tree"
	var spawn_us=[]
	for role in roles:
		var before=Time.get_ticks_usec()
		if debug:check(w.debug_spawn_enemy(role),"A normal debug click admits one actor: "+role)
		else:w.spawn_enemy({"role":role,"entry":Vector2i(1,5),"lv":1,"debug_single":true})
		spawn_us.append(Time.get_ticks_usec()-before)
	check(w.enemies.size()==roles.size(),"Only the bounded requested actors were spawned: "+label)
	var actors=w.enemies;var crossed={};var still={};var longest={};var ai_us=[];var batch_us=[]
	var physical=true;var deadline=false;var started=Time.get_ticks_msec()
	for i in range(MAX_TICKS):
		w.tick+=1
		var batch_start=Time.get_ticks_usec()
		w.Content.tick(w)
		var per_tick_ai=0
		for e in actors:
			var before=e.pos;w.Combat.recover(e,w.DT)
			var ai_start=Time.get_ticks_usec();w.enemy_step(e);per_tick_ai+=Time.get_ticks_usec()-ai_start
			if not crossed.has(e.id):
				still[e.id]=still.get(e.id,0)+1 if before==e.pos else 0
				longest[e.id]=maxi(longest.get(e.id,0),still[e.id])
				if e.get("arrival_complete",false) and w.inside(e.pos):crossed[e.id]=w.tick*w.DT
		ai_us.append(per_tick_ai);batch_us.append(Time.get_ticks_usec()-batch_start)
		var occupied={}
		for e in actors:
			if e.done or e.hp<=0:continue
			physical=physical and not occupied.has(e.pos);occupied[e.pos]=true
		if crossed.size()==actors.size():break
		if Time.get_ticks_msec()-started>WALL_BUDGET_MS:deadline=true;break
		# Yield CPU between each simulated update; priority is also BelowNormal.
		await create_timer(0.02).timeout
	var remaining=actors.filter(func(e):return not crossed.has(e.id))
	var report={"case":label,"seed":31,"requested":roles.size(),"roles":roles,"debug_api":debug,"simulated_seconds":w.tick*w.DT,"wall_seconds":(Time.get_ticks_msec()-started)/1000.0,"wall_budget_stop":deadline,"crossed_seconds":crossed,"last_entry_seconds":crossed.values().max() if not crossed.is_empty() else 0.0,"longest_stationary_seconds":longest.values().max()*w.DT if not longest.is_empty() else 0.0,"physical":physical,"enemy_ai_per_tick":timing(ai_us),"content_recovery_ai_batch":timing(batch_us),"debug_spawn_call":timing(spawn_us),"queries":actors.map(func(e):return e.get("arrival_queries",0)),"entrance_changes":actors.map(func(e):return e.get("arrival_gate_changes",0)),"remaining":remaining.map(func(e):return {"id":e.id,"role":e.role,"pos":e.pos,"state":e.state,"goal":e.get("arrival_goal"),"route":e.get("arrival_route",[])}),"peak_static_bytes":int(Performance.get_monitor(Performance.MEMORY_STATIC))}
	rows.append(report)
	check(not deadline and remaining.is_empty(),"Every actor clears a real opening within the bounded measurement: "+label)
	check(physical,"The crowd uses unique physical cells: "+label)
	# Record timing without claiming a hardware-independent performance assertion.
	print("CROWD_CASE ",JSON.stringify(report))

func run():
	check(DisplayServer.get_name()=="headless","Measurement remains headless")
	var data=Farm.ProgressData;var basic=Farm.Progression.Encounters.TABLE_NIGHT.count
	var cap=data.SPECIAL.night_reinforcement_cap
	var normal_bound=basic+2+(basic-1)+cap # one salaryman, two runners/dogs, two reaction slots.
	check(basic==3 and cap==4 and normal_bound==11,"Current normal composition is bounded by eleven total actors")
	var normal=["runner","runner","salaryman","animal_tamer","thief","doberman","doberman"]
	for i in range(cap):normal.append("salaryman")
	# Conservative simultaneous cluster from a valid count/composition. Normal events are staggered.
	await measure("normal_bound_11_cluster",normal,false)
	var kinds=data.ENEMY_ROWS.keys()+["doberman"]
	check(kinds.size()==11,"Debug roster has eleven implemented kinds")
	await measure("debug_two_roster_rounds_22",kinds+kinds,true)
	var report={"game_commit":GAME_COMMIT,"normal_bound":normal_bound,"debug_test_bound":kinds.size()*2,"debug_limit_note":"No small fixed actor cap; 22 is this test's explicit two-roster-round bound, not a gameplay maximum. The finite outer placement pool is not exhausted.","fixed_tick_ms":Farm.DT*1000,"cases":rows,"checks":records,"failures":failures,"scope":"One run per case, original spawn positions and production enemy_step; open neutral farm with two left openings, no keeper/animal/idol combat. Artificial simultaneous normal composition, not a natural-play win, renderer/frame-rate test, indefinite stress test or general capacity guarantee."}
	FileAccess.open("user://crowd-budget.json",FileAccess.WRITE).store_string(JSON.stringify(report,"  "))
	print("CROWD_BUDGET: %d checks, failures=%d"%[checks,failures]);quit(1 if failures else 0)
