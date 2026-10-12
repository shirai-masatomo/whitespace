extends RefCounted
const Policy=preload("res://game/work_policy.gd")

static func resume_rest(w,a):
	if not a.has("meal_rest_kind"):return
	var kind=a.meal_rest_kind;a.erase("meal_rest_kind")
	if a.get("dead",false) or a.hp<=0 or a.state!="free" or a.get("nutrition_down",false):return
	if a.work_key=="keeper":w.Life.set_rest(w,true,kind)
	else:a.resting=true;a.rest_kind=kind

static func interrupt(w,a):
	w.Stock.release_token(w,"food:"+a.work_key)
	for row in w.Stock.cargo(w,a.work_key,-2):row.location="ground";row.owner="";row.pos=a.pos;row.job_id=-1
	a.erase("food_target");a.erase("meal_remaining");a.erase("life_need");resume_rest(w,a)
	w.Stock.sync(w)

static func step(w,a) -> bool:
	var down=a.get("nutrition_down",false)
	if (a.get("drafted",false) and not down) or a.get("carrier",-1)>=0 or a.hp<=0 or a.state!="free" or (a.get("danger_near",false) and not down) or w.tick<a.get("hurt_until",0) or a.get("dead",false) or a.get("lost",false) or not a.get("placed",false):interrupt(w,a);return false
	if a.satiety>Policy.EAT_THRESHOLD and not a.has("meal_remaining") and not a.has("food_target"):return false
	if w.tick<a.get("food_retry_at",0):return false
	# No food available: do not repeatedly interrupt the very haul that will supply it.
	if not down and not a.has("food_target") and w.Stock.cargo(w,a.work_key,-2).is_empty() and not w.field_items.any(func(row):return row.kind in Policy.HUMAN_FOOD and w.Stock.eligible(w,row) and not w.Jobs.path_to(w,a.pos,w.neighbors(row.pos)).is_empty()):
		a.erase("life_need");a.food_retry_at=w.tick+ceili(Policy.RETRY_SECONDS/w.DT)
		if not a.get("food_shortage",false):w.PlayerEvents.add(w,"備蓄へ食料を回収してください","food_shortage:"+a.work_key)
		a.food_shortage=true;return false
	if a.get("resting",false) and not down:
		if a.get("rest_kind","")!="auto" and a.get("malnutrition",0.0)<=0:interrupt(w,a);return false
		if a.get("rest_kind","")!="auto":
			a.meal_rest_kind=a.get("rest_kind","manual")
			if a.work_key=="keeper":w.Life.set_rest(w,false)
			else:a.resting=false
		elif a.work_key=="keeper":w.Life.wake_auto(w)
		else:a.resting=false
	if a.get("life_need","")!="food":
		w.Work.interrupt(w,a.work_key,"空腹・食事を優先")
		a.life_need="food"
	var carried=w.Stock.cargo(w,a.work_key,-2)
	if carried.any(func(row):return row.get("forbidden",false)):
		interrupt(w,a);carried=[]
	if not carried.is_empty():
		if not a.has("meal_remaining"):
			a.meal_remaining=ceili(Policy.EAT_SECONDS/w.DT)
			w.PlayerEvents.add(w,w.PlayerEvents.name_of(w,a)+"：食事中。終わったら仕事に戻ります","meal:"+a.work_key)
		a.work_status="食事中"
		a.meal_remaining-=1
		if a.meal_remaining<=0:
			var row=carried[0];row.amount-=1;w.stock_used[row.kind]=w.stock_used.get(row.kind,0)+1
			if row.amount==0:w.field_items.erase(row)
			a.satiety=minf(Policy.SATIETY_MAX,a.satiety+Policy.MEAL_GAIN)
			a.erase("meal_remaining");a.erase("food_target");a.erase("life_need");resume_rest(w,a)
			a.work_status="食事を終え、仕事を選び直す"
			w.PlayerEvents.add(w,w.PlayerEvents.name_of(w,a)+"：食事を終えて仕事に復帰","meal_done:"+a.work_key);w.Stock.sync(w)
		return true
	var token="food:"+a.work_key
	var target=w.Stock.find(w,a.get("food_target",-1))
	if target.is_empty() or not w.Stock.stored(w,target) or target.get("forbidden",false) or target.get("kind","") not in Policy.HUMAN_FOOD or target.get("claims",{}).get(token,0)<1:
		w.Stock.release_token(w,token);a.erase("food_target");target={}
		for kind in Policy.HUMAN_FOOD:
			var claim=w.Stock.reserve(w,kind,1,token,a)
			if not claim.is_empty():a.food_target=claim[0].stock_id;target=w.Stock.find(w,a.food_target);break
	if down:
		# No walking or new rescue system: use carried food or unreserved food within reach.
		if not target.is_empty() and w.distance(a.pos,target.pos)>1:w.Stock.release_token(w,token);a.erase("food_target");target={}
		if target.is_empty():
			for row in w.field_items:
				if row.kind in Policy.HUMAN_FOOD and w.Stock.eligible(w,row) and w.distance(a.pos,row.pos)<=1 and w.line_of_sight(a.pos,row.pos):
					row.claims[token]=1;a.food_target=row.stock_id;target=row;break
		if not target.is_empty():w.Stock.pickup(w,target,token,a,-2);return true
		a.work_status="栄養失調・行動不能 · 手元/隣の食料を待つ";return true
	if target.is_empty():
		a.food_retry_at=w.tick+ceili(Policy.RETRY_SECONDS/w.DT);a.erase("life_need");resume_rest(w,a)
		if not a.get("food_shortage",false):w.PlayerEvents.add(w,"備蓄に使える食料がありません。採集後に回収して備蓄へ運んでください","food_shortage:"+a.work_key)
		a.food_shortage=true;a.work_status="食料不足 · 仕事を続けながら再確認";return false
	a.food_shortage=false;a.work_status="空腹 · 食べ物へ移動中"
	var task={"kind":"collect","pos":target.pos,"state":"walking"}
	if w.Jobs.walk(w,task,w.neighbors(target.pos),a):w.Stock.pickup(w,target,token,a,-2)
	elif task.state=="blocked":
		interrupt(w,a);a.food_retry_at=w.tick+ceili(Policy.RETRY_SECONDS/w.DT);a.work_status="食料への通路が閉塞"
	return true
