extends RefCounted
const Data=preload("res://game/needs_data.gd")
static func init(a):
	a.needs_managed=true;a.satiety=a.get("satiety",100.0);a.stamina=a.get("stamina",100.0);a.max_stamina=a.get("max_stamina",100.0)
static func band(satiety:float)->Array:
	for row in Data.BANDS:
		if ceili(satiety)>=row[0]:return row
	return Data.BANDS[-1]
static func meal(w,a,kind:String):
	var food=Data.FOOD.get(kind,{"satiety":45});init(a);a.satiety=minf(100,a.satiety+food.satiety)
	if food.has("effect"):
		# One meal effect slot: a new cooked buff replaces/refreshes it, never multiplies it.
		a.meal_effect={"name":food.effect,"until":w.tick+ceili(food.duration/w.DT),"regen":food.get("regen",1.0),"cost":food.get("cost",1.0),"work":food.get("work",1.0)}
	refresh_effect(w,a)
	if a.get("work_key","")!="" or a.get("category","")=="human":
		w.Resident.remember(w,a,"meal")
		var tier=preload("res://game/item_catalog.gd").item(kind).tier
		if tier>0:w.Resident.remember(w,a,"quality",tier)
static func refresh_effect(w,a):
	if a.has("meal_effect") and a.meal_effect.until<=w.tick:a.erase("meal_effect")
	var effect=a.get("meal_effect",{})
	a.food_regen_factor=effect.get("regen",1.0);a.food_cost_factor=effect.get("cost",1.0);a.food_work_factor=effect.get("work",1.0)
static func describe(w,a)->String:
	var effect=a.get("meal_effect",{})
	return ("%s · 残り%d秒"%[effect.name,maxi(0,ceili((effect.until-w.tick)*w.DT))] if not effect.is_empty() else "食事効果なし")+(" · スタミナ回復中" if a.get("needs_rest",false) else "")+(" · 飢餓" if a.get("satiety",100)<=0 else "")
static func begin(w):
	for a in w.workers.values():init(a)
	for a in w.animals:init(a)
static func update(w,a,human:bool):
	if a.get("dead",false) or a.get("lost",false) or not a.get("placed",false):return
	init(a);refresh_effect(w,a)
	if not human:a.satiety=maxf(0,a.satiety-Data.ANIMAL_HUNGER*w.DT*(w.Resident.appetite(a) if a.get("category","")=="human" else 1.0))
	var limits=band(a.satiety);a.max_stamina=limits[1];a.stamina=minf(a.stamina,a.max_stamina)
	var moving=a.get("needs_last_pos",a.pos)!=a.pos;a.needs_last_pos=a.pos
	var task=w.Work.active(w,a.work_key) if human else {}
	var working=not task.is_empty() and task.get("state")=="working"
	var hauling=not w.Stock.cargo(w,a.get("work_key","")).is_empty() if human else false
	var rest=a.get("resting",false) or a.get("asleep",false) or a.get("needs_rest",false) or a.get("mode","")=="rest" or a.get("state","") in ["休む","自主休養","ひと休み","hidden_rest"]
	var activity="rest" if rest else ("haul" if hauling else ("work" if working else ("wander" if not human and a.get("mode","")=="auto" and not a.get("rescuing",false) and a.get("state","") not in ["追跡","救出本能"] else "move") if moving else "idle"))
	if w.enemies.any(func(e):return not e.done and e.hp>0 and w.distance(e.pos,a.pos)<=2) and not rest:activity="combat" if not moving else "move"
	var rate=Data.RATES[activity]
	a.stamina=clampf(a.stamina+rate*w.DT*(limits[2]*a.food_regen_factor if rate>0 else a.food_cost_factor*(a.get("focus_cost",1.0) if activity=="work" else 1.0)),0,a.max_stamina)
	if a.stamina<=Data.REST_AT:a.needs_rest=true
	elif a.stamina>=minf(Data.RESUME_AT,a.max_stamina*0.8):a.needs_rest=false
	if a.satiety>0:a.starve_seconds=0.0;a.starve_damage=0.0;return
	a.starve_seconds=a.get("starve_seconds",0.0)+w.DT
	if a.starve_seconds<Data.STARVE_GRACE:return
	a.starve_damage=a.get("starve_damage",0.0)+w.DT
	if a.starve_damage>=Data.STARVE_DAMAGE_INTERVAL:
		a.starve_damage-=Data.STARVE_DAMAGE_INTERVAL
		# Human mortality remains owned by the existing malnutrition lifecycle.
		if a.hp>0:a.hp=maxi(1 if human else 0,a.hp-1)
static func finish(w):
	var handled={}
	for a in w.workers.values():update(w,a,true);handled[a.get("id",-999)]=true
	for a in w.animals:
		if not handled.has(a.id):update(w,a,false)
static func animal_action(w,a)->bool:
	if a.has("work_key") and w.workers.has(a.work_key):return false
	if w.enemies.any(func(e):return not e.done and not e.flee and e.hp>0 and w.distance(e.pos,a.pos)<=a.detection_range):return false
	if a.get("needs_rest",false):a.state="ひと休み";return true
	if a.get("category","")=="human" or a.get("satiety",100)>30:return false
	var diet=Data.DIETS.get(a.species,w.Work.Policy.HUMAN_FOOD)
	var row=w.Stock.find(w,a.get("needs_food_id",-1))
	if not row.is_empty() and (row.kind not in diet or not w.Stock.eligible(w,row,false)):row={}
	if row.is_empty() and w.tick>=a.get("needs_food_retry",0):
		a.needs_food_retry=w.tick+ceili(2.0/w.DT)
		var candidates=w.field_items.filter(func(r):return r.kind in diet and w.Stock.eligible(w,r,false))
		candidates.sort_custom(func(x,y):return w.distance(a.pos,x.pos)<w.distance(a.pos,y.pos))
		for candidate in candidates:
			if not w.Jobs.path_to(w,a.pos,w.neighbors(candidate.pos)+[candidate.pos],not w.SPECIES[a.species].can_enter_indoor).is_empty():row=candidate;a.needs_food_id=row.stock_id;break
	if row.is_empty():
		if "weed" in diet:
			for cell in [a.pos]+w.neighbors(a.pos):
				if w.natural.get(cell)=="weed" and not w.natural_forbidden.get(cell,false) and w.line_of_sight(a.pos,cell):w.natural.erase(cell);meal(w,a,"hen_food");a.state="食事中";return true
		return false
	if w.distance(a.pos,row.pos)<=1 and w.line_of_sight(a.pos,row.pos):
		row.amount-=1;w.stock_used[row.kind]=w.stock_used.get(row.kind,0)+1;meal(w,a,row.kind)
		if row.amount<=0:w.field_items.erase(row)
		w.Stock.sync(w);a.erase("needs_food_id");a.state="食事中";return true
	a.state="食べ物へ移動";a.move_credit=minf(1.9,a.move_credit+a.move_speed*w.Content.speed(w,a)*w.DT)
	if a.move_credit>=1:
		var next=w.animal_next(a,row.pos)
		if next!=a.pos and not w.actor_occupied(next,a.pos):a.move_credit-=1;w.open_for_ally(next);a.pos=next
	return true
