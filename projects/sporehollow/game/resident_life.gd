extends RefCounted
## Independent resident traits, danger awareness, bounded mood memories and focus.
const APPETITES={"small":0.7,"normal":1.0,"large":1.4}
const APPETITE_NAMES={"small":"小食","normal":"通常","large":"大食漢"}
const WORK_NAMES={"normal":"普通","builder":"建築職人","distracted":"注意力散漫"}
const REACTIONS={"relaxed":"リラックス","alert":"警戒","extreme":"極度の緊張","tense":"緊張"}
const SAFE_SECONDS=20.0
const EXTREME_SECONDS=8.0
const FOCUS_INTERVAL=6.0
const FOCUS_DURATION=18.0
const FOCUS_COOLDOWN=30.0
const FOCUS_SPEED=1.12
const FOCUS_COST=0.85
const MOOD_EVENTS={"meal":["食事を取れた",3,120],"quality":["良い食事",4,120],"rested":["十分に眠れた",4,150],"lost_home":["住居を失った",-8,180],"attacked":["襲われた",-6,120]}
static func initialize(a):
	var key=a.get("work_key",a.get("sleep_key","keeper"))
	if not a.has("appetite"):a.appetite="normal" if key=="keeper" else APPETITES.keys()[absi(hash(key+"appetite"))%3]
	if not a.has("work_trait"):a.work_trait="normal" if key=="keeper" else WORK_NAMES.keys()[absi(hash(key+"worktrait"))%3]
	if not a.has("mood_events"):a.mood_events={}
	if not a.has("satisfaction"):a.satisfaction=50.0
	if not a.has("danger_state"):a.danger_state="relaxed"
static func appetite(a)->float:
	initialize(a);return APPETITES.get(a.appetite,1.0)
static func detection(a)->int:return 2 if a.get("work_trait","")=="distracted" else 0
static func remember(w,a,id:String,multiplier:float=1.0):
	initialize(a);var row=MOOD_EVENTS[id]
	a.mood_events[id]={"label":row[0],"value":row[1]*multiplier,"until":w.tick+ceili(row[2]/w.DT)}
static func attacked(w,a):
	initialize(a);a.danger_seen=true;a.extreme_until=w.tick+ceili(EXTREME_SECONDS/w.DT);a.safe_since=w.tick;a.danger_state="extreme";a.danger_near=true
	remember(w,a,"attacked");clear_focus(a)
	if a.get("resting",false):w.Sleep.wake(w,a,true)
static func clear_focus(a):
	a.focus_until=0;a.focus_work=1.0;a.focus_cost=1.0;a.focus_job=-1;a.focus_elapsed=0.0
static func chance(a,building:bool)->float:
	return 0.04 if a.get("work_trait")=="distracted" else 0.35 if building and a.get("work_trait")=="builder" else 0.12
static func focus(w,a):
	var j=w.Work.active(w,w.Sleep.actor_key(a))
	var valid=not j.is_empty() and j.get("state")=="working" and (w.BUILD.has(j.kind) or j.kind in ["mine","clear_tree","collect","craft"]) and not a.get("resting",false) and not a.get("needs_rest",false) and a.get("life_need","")!="food" and a.get("danger_state","relaxed")=="relaxed"
	if not valid:clear_focus(a);return
	if a.get("focus_job",-1)!=j.id:clear_focus(a);a.focus_job=j.id
	if w.tick<a.get("focus_until",0):a.focus_work=FOCUS_SPEED;a.focus_cost=FOCUS_COST;return
	a.focus_work=1.0;a.focus_cost=1.0;a.focus_elapsed=a.get("focus_elapsed",0.0)+w.DT
	if a.focus_elapsed<FOCUS_INTERVAL or w.tick<a.get("focus_retry",0):return
	a.focus_elapsed=0.0;a.focus_retry=w.tick+ceili(FOCUS_INTERVAL/w.DT)
	if w.rng.randf()<chance(a,w.BUILD.has(j.kind)):
		a.focus_until=w.tick+ceili(FOCUS_DURATION/w.DT);a.focus_retry=a.focus_until+ceili(FOCUS_COOLDOWN/w.DT);a.focus_work=FOCUS_SPEED;a.focus_cost=FOCUS_COST
static func step(w,a):
	initialize(a)
	if a.get("dead",false) or not a.get("placed",false):clear_focus(a);return
	var live=w.enemies.filter(func(e):return not e.done and e.hp>0 and not e.flee)
	var radius=int(a.get("detection_range",6))+detection(a)
	var seen=live.any(func(e):return w.distance(e.pos,a.pos)<=radius and w.line_of_sight(a.pos,e.pos))
	if seen:a.danger_seen=true;a.safe_since=w.tick
	if w.tick<a.get("extreme_until",0):a.danger_state="extreme"
	elif seen:a.danger_state="alert"
	elif a.get("danger_seen",false):
		# Only a resident who already perceived danger keeps the colony raid alarm.
		if not live.is_empty():a.safe_since=w.tick
		if w.tick-a.get("safe_since",w.tick)<ceili(SAFE_SECONDS/w.DT):a.danger_state="tense"
		else:a.danger_state="relaxed";a.danger_seen=false
	else:a.danger_state="relaxed"
	a.danger_near=a.danger_state in ["alert","extreme"]
	if a.get("resting",false) and a.danger_state!="relaxed":w.Sleep.wake(w,a,true)
	focus(w,a)
	if w.tick<a.get("mood_next",0):return
	a.mood_next=w.tick+ceili(2.0/w.DT)
	var home=not w.Homes.bed(w,a).is_empty()
	if a.get("had_home",false) and not home:remember(w,a,"lost_home")
	a.had_home=home
	for id in a.mood_events.keys():
		if a.mood_events[id].until<=w.tick:a.mood_events.erase(id)
	var reasons=[];var target=50.0
	for event in a.mood_events.values():reasons.append(event.label);target+=event.value
	if home:target+=5;reasons.append("自分の寝床")
	if a.satiety<=0:target-=12;reasons.append("空腹が続いている")
	if a.sleepiness>=80:target-=8;reasons.append("睡眠不足")
	if a.danger_state!="relaxed":target-=6;reasons.append("危険が続いている")
	else:target+=2;reasons.append("安全な環境")
	a.satisfaction=move_toward(a.satisfaction,clampf(target,0,100),0.5);a.mood_reasons=reasons
	a.mood_work=1.0+(a.satisfaction-50.0)*0.001
static func describe(a)->String:
	initialize(a)
	return "%s · %s · %s%s\n満足度 %d/100：%s"%[APPETITE_NAMES[a.appetite],WORK_NAMES[a.work_trait],REACTIONS[a.danger_state]," · 集中" if a.get("focus_work",1.0)>1 else "",a.satisfaction,"・".join(a.get("mood_reasons",["普段の生活"]))]
