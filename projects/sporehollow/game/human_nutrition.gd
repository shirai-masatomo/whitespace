extends RefCounted
## Provisional survival values for a 432-second day. Only registered human workers.
const EMPTY_TO_DEATH_SECONDS=864.0
const RECOVERY_SECONDS=432.0
const WEAK=25.0
const SEVERE=50.0
const DOWN=75.0
const DEATH=100.0
const RESUME=50.0

static func factor(a: Dictionary) -> float:
	if a.get("dead",false) or a.get("nutrition_down",false):return 0.0
	return 0.5 if a.get("malnutrition",0.0)>=SEVERE else (0.8 if a.get("malnutrition",0.0)>=WEAK else 1.0)

static func status(a: Dictionary) -> String:
	if a.get("death_cause","")=="malnutrition":return "栄養失調で死亡"
	if a.get("nutrition_down",false):return "行動不能 · 手元の食料で療養"
	var level=a.get("malnutrition",0.0)
	if level>=SEVERE:return "栄養失調・重度 · 作業/移動50%"
	if level>=WEAK:return "栄養失調 · 作業/移動80%"
	return "栄養回復中" if level>0 and a.get("satiety",0)>0 else ("食料不足" if level>0 else "栄養良好")

static func step(w,a: Dictionary):
	if a.get("dead",false) or a.get("lost",false) or not a.get("placed",false):return
	a.satiety=maxf(0,a.get("satiety",w.Work.Policy.SATIETY_MAX)-w.Work.Policy.HUNGER_PER_SECOND*w.DT)
	var old=a.get("malnutrition",0.0)
	a.malnutrition=clampf(old+(100.0/EMPTY_TO_DEATH_SECONDS if a.satiety<=0 else -100.0/RECOVERY_SECONDS)*w.DT,0,DEATH)
	if a.malnutrition>=DOWN and not a.get("nutrition_down",false):
		a.nutrition_down=true
		w.Work.interrupt(w,a.work_key,"栄養失調・行動不能")
		if a.work_key=="keeper":w.manual_goal=null;w.Life.stop_rest_until(w,"malnutrition")
		w.PlayerEvents.add(w,w.PlayerEvents.name_of(w,a)+"：栄養失調で行動不能。手元/隣の食料は食べられます","nutrition_down:"+a.work_key)
	elif a.get("nutrition_down",false) and a.malnutrition<RESUME and a.satiety>0:
		a.nutrition_down=false
		w.PlayerEvents.add(w,w.PlayerEvents.name_of(w,a)+"：栄養が回復し、行動を再開できます","nutrition_up:"+a.work_key)
	for threshold in [WEAK,SEVERE]:
		if old<threshold and a.malnutrition>=threshold:w.PlayerEvents.add(w,w.PlayerEvents.name_of(w,a)+"："+status(a),"nutrition_warn:%s:%d"%[a.work_key,threshold])
	if a.malnutrition<DEATH:return
	# Inability precedes death by 216 seconds with no food, never the same threshold.
	w.Work.interrupt(w,a.work_key,"栄養失調で死亡");w.Food.interrupt(w,a)
	a.dead=true;a.death_cause="malnutrition";a.hp=0;a.state="dead";a.resting=false
	w.PlayerEvents.add(w,w.PlayerEvents.name_of(w,a)+"：栄養失調で死亡しました","nutrition_death:"+a.work_key)
	if a.work_key=="keeper":w.story.defeat_reason="malnutrition";w.finish(false)
