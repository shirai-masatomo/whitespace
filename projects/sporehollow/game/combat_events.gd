extends RefCounted
## Individual meters; called by successful combat outcomes, never by draw/input.
const GAINS={"AttackHit":5.0,"SkillHit":7.0,"DamageTaken":2.0,"Kill":10.0,"Finisher":15.0}
const COSTS={"move":1.0,"attack":6.0,"skill":12.0}
const ULTIMATE_FIELDS=["UltimateID","Name","Rarity","UnlockLevel","GaugeCost","ConditionID","Duration","AIHints","LevelScaling"]

static func init_actor(a: Dictionary,human: bool=false):
	a.ultimate_gauge_max=a.get("ultimate_gauge_max",100.0)
	a.ultimate_gauge=clampf(a.get("ultimate_gauge",0.0),0,a.ultimate_gauge_max)
	a.ultimate_state="ULTIMATE_READY" if ready(a) else "CHARGING"
	a.has_stamina=human
	if human:
		a.max_stamina=a.get("max_stamina",100.0)
		a.stamina=a.get("stamina",a.max_stamina)
		a.stamina_regen=a.get("stamina_regen",2.0)

static func ready(a: Dictionary) -> bool:
	return a.get("ultimate_gauge",0.0)>=a.get("ultimate_gauge_max",100.0)

static func grant(w,a: Dictionary,event: String,action: String,target: String) -> bool:
	if a.is_empty() or not GAINS.has(event):return false
	if not a.has("ultimate_gauge"):init_actor(a,a.get("has_stamina",false))
	var limits=a.get("gauge_limits",{})
	# One award per actor/action/target/event per second, including multi-hit and DoT.
	var key=event+":"+action+":"+target
	if w.tick<limits.get(key,-1):return false
	for old in limits.keys():
		if limits[old]<=w.tick:limits.erase(old)
	limits[key]=w.tick+ceili(1.0/w.DT);a.gauge_limits=limits
	a.ultimate_gauge=minf(a.ultimate_gauge_max,a.ultimate_gauge+GAINS[event])
	a.ultimate_state="ULTIMATE_READY" if ready(a) else "CHARGING"
	w.combat_log.append({"tick":w.tick,"source":"gauge","id":a.get("id",-1),"damage":0,"event":event,"action":action,"target":target,"gauge":a.ultimate_gauge,"actor_id":a.get("id",-1),"faction":a.get("faction","keeper")})
	return true

static func hit(w,source: Dictionary,target: Dictionary,action: String,damage: float,skill: bool=false):
	if damage<=0:return
	var tid=str(target.get("faction","keeper"))+str(target.get("id",-1))
	grant(w,source,"SkillHit" if skill else "AttackHit",action,tid)
	grant(w,target,"DamageTaken",action,str(source.get("faction","keeper"))+str(source.get("id",-1)))
	if target.hp<=0 and not target.get("kill_gauge_awarded",false):
		target.kill_gauge_awarded=true
		grant(w,source,"Kill",action,tid)
		grant(w,source,"Finisher",action,tid)

static func pay(a: Dictionary,action: String) -> bool:
	if not a.get("has_stamina",false):return true
	var cost=COSTS.get(action,0.0)
	if a.stamina<cost:return false
	a.stamina=maxf(0,a.stamina-cost)
	return true

static func recover(a: Dictionary,dt: float,rest: bool=false):
	if a.get("has_stamina",false) and a.get("hp",0)>0:
		a.stamina=minf(a.max_stamina,a.stamina+a.stamina_regen*dt*(3.0 if rest else 1.0))

static func tongue(w,source: Dictionary,target: Dictionary):
	target.move_stopped_until=maxi(target.get("move_stopped_until",0),w.tick+ceili(w.ProgressData.SPECIAL.tongue_stop/w.DT))
	if target.get("has_stamina",false):target.stamina=maxf(0,target.stamina-20.0)
	grant(w,source,"SkillHit","tongue",str(target.get("faction","enemy"))+str(target.get("id",-1)))

static func can_use(a: Dictionary,definition: Dictionary,context: Dictionary) -> bool:
	for field in ULTIMATE_FIELDS:
		if not definition.has(field):return false
	if not ready(a) or a.get("lv",1)<definition.UnlockLevel or a.ultimate_gauge<definition.GaugeCost:return false
	if not context.get("conditions",{}).get(definition.ConditionID,false):return false
	# Low accuracy uses early; high accuracy waits for a useful tactical opportunity.
	var hints=definition.AIHints
	var score=context.get("tactical_score",0.0)+context.get("targets",0)*hints.get("per_target",0.0)
	score+=hints.get("priority",0.0) if context.get("priority_target",false) else 0.0
	score+=(1.0-float(a.get("hp",1))/maxf(1,a.get("max_hp",1)))*hints.get("low_hp",0.0)
	score-=context.get("distance",0.0)*hints.get("distance_penalty",0.0)
	return score>=hints.get("threshold",0.5)*clampf(a.get("ai_accuracy",50)/100.0,0,1)

static func ai_use(w,a: Dictionary,definition: Dictionary,context: Dictionary,execute: Callable) -> bool:
	definition=w.ProgressData.Levels.resolve(definition,a.get("lv",1),{},definition.get("LevelScaling",{}))
	if not can_use(a,definition,context) or not execute.is_valid():return false
	if not execute.call():return false
	a.ultimate_gauge=maxf(0,a.ultimate_gauge-definition.GaugeCost)
	a.ultimate_state="ULTIMATE_READY" if ready(a) else "CHARGING"
	w.skill_log.append({"tick":w.tick,"actor":a.get("id",-1),"ultimate":definition.UltimateID,"skill":definition.UltimateID,"faction":a.get("faction","owned")})
	return true
