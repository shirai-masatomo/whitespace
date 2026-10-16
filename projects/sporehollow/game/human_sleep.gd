extends RefCounted
## Seconds here are simulation seconds (432 seconds/day), independent of render FPS.
const TYPES={"early":[22,4],"normal":[0,6],"late":[3,9]}
const TRAITS={"short":1.5,"normal":1.0,"long":0.75}
const LABELS={"sleep":"睡眠","work":"仕事","free":"自由"}
const BED_FACTOR=1.25
const OFF_HOURS_FACTOR=0.75
static func people(w)->Dictionary:
	var result=w.workers.duplicate()
	for a in w.animals:
		if a.get("category","")=="human" and not result.has("a%d"%a.id):
			a.sleep_key="a%d"%a.id;initialize(a);result[a.sleep_key]=a
	return result
static func actor_key(a)->String:return a.get("work_key",a.get("sleep_key","keeper"))
static func defaults(kind:String)->Array:
	var result=[];var span=TYPES.get(kind,TYPES.normal)
	for hour in range(24):result.append("sleep" if fposmod(hour-span[0],24)<6 else ("work" if hour>=6 and hour<18 else "free"))
	return result
static func initialize(a):
	preload("res://game/resident_life.gd").initialize(a)
	if not a.has("life_type"):a.life_type="normal" if actor_key(a)=="keeper" else TYPES.keys()[absi(hash(actor_key(a)))%3]
	if not a.has("sleep_trait"):a.sleep_trait="normal" if actor_key(a)=="keeper" else TRAITS.keys()[absi(hash(actor_key(a)+"recovery"))%3]
	if not a.has("sleepiness"):a.sleepiness=0.0
	for flag in ["resting","asleep","forced_rest"]:
		if not a.has(flag):a[flag]=false
	if not a.has("sleep_rate"):a.sleep_rate=1.0 if actor_key(a)=="keeper" else [0.9,1.0,1.1][absi(hash(actor_key(a)+"fatigue"))%3]
	if not a.has("timetable"):a.timetable=defaults(a.life_type)
static func hour(w)->int:return w.Cycle.clock(w).minute_of_day()/60
static func activity(w,a)->String:
	initialize(a)
	var stamp=int(w.calendar_ticks/72) # 18 seconds/hour at 0.25 seconds/tick.
	if a.get("schedule_stamp",-1)!=stamp:
		a.schedule_stamp=stamp
		if a.has("pending_timetable"):a.timetable=a.pending_timetable;a.erase("pending_timetable")
	return a.timetable[hour(w)]
static func edit(w,a,h:int,kind:String):
	activity(w,a)
	if not a.has("pending_timetable"):a.pending_timetable=a.timetable.duplicate()
	a.pending_timetable[clampi(h,0,23)]=kind
static func wake(w,a,manual:bool=false):
	a.resting=false;a.asleep=false;a.forced_rest=false;a.rest_kind="";a.erase("rest_target");a.erase("rest_reason");a.erase("sleep_travel")
	if manual:a.wake_until=w.tick+ceili(15.0/w.DT)
	if not a.has("work_key") and a.get("state","")=="休む":a.state="待機"
	if actor_key(a)=="keeper" and w.job_hold_reason in ["rest","auto_rest"]:w.Jobs.hold(w,"")
static func begin(w,a,forced:bool):
	if w.workers.has(actor_key(a)):w.Work.interrupt(w,actor_key(a),"睡眠のため仕事を中断")
	a.resting=true;a.asleep=false;a.forced_rest=forced;a.rest_kind="forced" if forced else "scheduled";a.rest_elapsed=0.0
	a.erase("rest_target");a.erase("rest_reason");a.erase("sleep_travel")
static func arrive(w,a)->bool:
	var b=w.Homes.bed(w,a)
	if a.get("sleep_bed_id",-1)!=b.get("id",-1):a.erase("rest_target");a.erase("sleep_travel");a.erase("sleep_bed_id")
	if w.tick<a.get("bed_retry",0):a.rest_reason="寝床に到達できず、その場でうたた寝";return true
	if b.is_empty():
		if a.get("forced_rest",false):a.rest_reason="その場でうたた寝";return true
		return w.Zones.rest_step(w,a)
	if not a.has("rest_target"):
		var goals=w.Buildings.perimeter("bed",b.pos).filter(func(q):return w.home_cells.get(q,-1)==a.get("home_id",-2))
		var path=w.Jobs.path_to(w,a.pos,goals)
		if path.is_empty():a.bed_retry=w.tick+ceili(8.0/w.DT);a.rest_reason="寝床へ到達できないため、その場でうたた寝";return true
		a.rest_target=path[-1];a.sleep_bed_id=b.id
	if a.pos==a.rest_target:a.rest_reason="自分のベッドで睡眠";return true
	if not a.has("sleep_travel"):a.sleep_travel={"kind":"rest_travel","state":"walking"}
	a.rest_reason="自分のベッドへ移動中"
	w.Jobs.walk(w,a.sleep_travel,[a.rest_target],a)
	if a.sleep_travel.state=="blocked":a.bed_retry=w.tick+ceili(8.0/w.DT);a.erase("rest_target");a.erase("sleep_bed_id");a.rest_reason="寝床へ到達できないため、その場でうたた寝";return true
	return false
static func recovery(w,a)->float:
	var preferred=defaults(a.life_type)[hour(w)]=="sleep"
	var bed_bonus=not w.Homes.bed(w,a).is_empty() and a.has("rest_target") and a.pos==a.rest_target
	return 100.0/108.0*TRAITS.get(a.sleep_trait,1.0)*(1.0 if preferred else OFF_HOURS_FACTOR)*(BED_FACTOR if bed_bonus else 1.0)
static func step(w,a):
	initialize(a);var planned=activity(w,a)
	if not a.get("placed",false) or a.get("dead",false) or a.get("hp",0)<=0 or (a.has("work_key") and a.get("state","")!="free") or a.get("carrier",-1)>=0 or a.get("nutrition_down",false):return
	var near=w.enemies.any(func(e):return not e.done and e.hp>0 and not e.flee and w.distance(e.pos,a.pos)<=3 and w.line_of_sight(a.pos,e.pos))
	var danger=a.get("danger_state","relaxed")!="relaxed" or near
	a.danger_near=near or a.get("danger_state","relaxed") in ["alert","extreme"]
	if a.get("resting",false) and a.get("satiety",100)<=0:
		a.sleep_food_wait=true;wake(w,a)
	if a.get("resting",false) and (danger or a.get("drafted",false)):wake(w,a,true)
	if a.get("resting",false) and a.get("rest_kind","")=="scheduled" and planned!="sleep" and not a.get("forced_rest",false):wake(w,a)
	if not a.get("resting",false) and not danger and not a.get("sleep_food_wait",false) and a.get("satiety",100)>0 and not a.get("drafted",false) and a.get("life_need","")!="food" and w.tick>=a.get("wake_until",0):
		if a.sleepiness>=100:begin(w,a,true)
		elif planned=="sleep" and a.sleepiness>=50 and a.get("satiety",100)>w.Work.Policy.EAT_THRESHOLD:begin(w,a,false)
	if a.get("resting",false):
		if a.get("life_need","")=="food" or not arrive(w,a):return
		a.rest_elapsed=a.get("rest_elapsed",0.0)+w.DT
		a.asleep=a.rest_elapsed>= (3.0 if w.is_indoor(a.pos) else 5.0)
		if a.asleep:a.sleepiness=maxf(0,a.sleepiness-recovery(w,a)*w.DT)
		a.heal_credit=a.get("heal_credit",0.0)+w.DT
		if a.heal_credit>=5:a.hp=mini(a.max_hp,a.hp+1);a.heal_credit-=5
		a.work_status=a.get("rest_reason","睡眠中")
		if not a.has("work_key"):a.state="休む"
		if a.sleepiness<=0 and a.get("rest_kind","") in ["scheduled","forced"]:w.Resident.remember(w,a,"rested");wake(w,a)
	else:a.sleepiness=minf(100,a.sleepiness+100.0/432.0*a.sleep_rate*w.DT)
