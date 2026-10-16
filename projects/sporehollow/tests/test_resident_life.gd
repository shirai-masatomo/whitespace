extends "res://tests/test_housing_sleep.gd"
func helper():
	var a=w.keeper.duplicate(true);a.name="田中";a.pos=Vector2i(29,25);a.erase("home_id");a.erase("bed_id");w.Work.register(w,"helper",a);return a
func food_tick(count:int):
	for i in range(count):w.tick+=1;w.Sleep.step(w,w.keeper);w.Food.step(w,w.keeper)
func food():
	w=fixture();var a=w.keeper;w.Sleep.initialize(a)
	for appetite_kind in w.Resident.APPETITES:
		a.appetite=appetite_kind;a.satiety=100
		for i in range(20):w.Nutrition.step(w,a)
		check(is_equal_approx(a.satiety,100-20*w.DT*w.Work.Policy.HUNGER_PER_SECOND*w.Resident.APPETITES[appetite_kind]),"Appetite independent hunger rate "+appetite_kind)
	check(w.Zones.Catalog.FOOD_TIERS.size()==4 and w.Work.Policy.HUMAN_FOOD.all(func(id):return w.Zones.Catalog.item(id).tier==0),"Four tiers, all current human foods simple")
	w.FoodPrefs.initialize(a);check(w.FoodPrefs.order(a)[0] in ["stew","egg_meal","roast_meat","roast_mushroom"],"Default cooked before raw")
	w.FoodPrefs.change(a,"raw:0",1)
	check(a.food_order[0]=="raw:0" and a.food_order.size()==8 and a.food_order.all(func(value):return a.food_order.count(value)==1),"Priority editing swaps unique ranks")
	var z=w.Zones.find(w,w.Zones.create(w,"stockpile",Vector2i(31,25),Vector2i(32,25)))
	w.Stock.add(w,"mushroom",4,Vector2i(31,25));w.Stock.add(w,"stew",2,Vector2i(32,25));a.satiety=20;a.appetite="normal";a.timetable.fill("work")
	w.Food.step(w,a);check(w.Stock.find(w,a.get("food_target",-1)).get("kind")=="mushroom","Actual food choice uses resident raw priority")
	w.Food.interrupt(w,a);w.Access.set_permission(w,z,"keeper",false);a.food_retry_at=0
	check(not w.Food.step(w,a) and not a.has("food_target") and w.Stock.totals(w).mushroom==4,"Denied food not claimed or consumed")
	w.Access.set_permission(w,z,"keeper",true);w.FoodPrefs.change(a,"cooked:0",1);a.food_retry_at=0
	w.Food.step(w,a);check(w.Stock.find(w,a.get("food_target",-1)).get("kind")=="stew","Cooked setting selects cooked physical stock")
	w.Food.interrupt(w,a);a.pos=Vector2i(30,25);a.timetable.fill("sleep");a.sleepiness=80
	for satiety in [30,1]:
		a.satiety=satiety;w.Sleep.begin(w,a,false);w.Food.step(w,a);w.Sleep.step(w,a);check(a.resting,"Sleeping stays asleep at satiety "+str(satiety))
	a.satiety=0;a.food_retry_at=0;w.Sleep.step(w,a);check(not a.resting and a.get("sleep_food_wait",false),"Zero satiety wakes sleeper")
	food_tick(80);check(a.satiety>0 and a.resting and not a.get("sleep_food_wait",false),"Two-second physical meal returns to scheduled sleep")
	w.field_items.clear();w.Stock.sync(w);a.satiety=0;a.sleepiness=100;w.Sleep.begin(w,a,true);food_tick(80)
	check(not a.resting and a.get("sleep_food_wait",false) and a.get("food_shortage",false),"No food retries without forced-sleep oscillation")
	w.Stock.add(w,"mushroom",2,Vector2i(31,25));a.pos=Vector2i(30,25);food_tick(80)
	check(a.satiety>0 and a.resting,"Restocking releases hungry wake latch and resumes sleep")
func permissions():
	w=fixture();var a=w.keeper;var b=helper()
	for x in range(9):
		for y in range(5):ready("wood_wall" if x in [0,4,8] or y in [0,4] else "wood_tile",Vector2i(10+x,10+y))
	ready("door",Vector2i(12,10));ready("door",Vector2i(14,12));ready("bed",Vector2i(12,12));ready("bed",Vector2i(16,12));w.refresh_indoor()
	var left=w.home_cells[Vector2i(11,11)];var right=w.home_cells[Vector2i(15,11)]
	check(left!=right,"Interior door gives independent homes")
	w.structures[Vector2i(14,12)].open=true;w.refresh_indoor();check(w.homes.size()==2,"Open interior door still separates rooms")
	check(w.Homes.assign(w,left,"keeper") and w.Homes.assign(w,right,"helper"),"Each resident gets own room and bed")
	var z=w.Zones.find(w,w.Zones.create(w,"stockpile",Vector2i(11,11),Vector2i(17,11)))
	var row=w.Stock.add(w,"wood",10,Vector2i(15,11))
	check(not w.Access.can_take(w,row,a) and w.Access.can_take(w,row,b),"Cross-room single zone isolates occupied room goods")
	check(w.Access.allowed_at(w,Vector2i(11,11),a) and not w.Access.allowed_at(w,Vector2i(11,11),b),"Other room keeps own access")
	check(w.Zones.accepts(w,Vector2i(15,11),"wood") and w.walkable(Vector2i(15,11)),"Withdrawal ban does not block delivery or walking")
	check(w.Stock.reserve(w,"wood",2,"private",a).is_empty(),"Public job cannot reserve another resident private materials")
	check(not w.Stock.consume(w,"wood",1,a) and row.amount==10,"Direct consumption uses same permission")
	var token="test";check(not w.Stock.reserve(w,"wood",2,token,b).is_empty(),"Authorized resident reserves goods")
	w.Access.set_permission(w,z,"helper",false)
	check(w.Stock.pickup(w,row,token,b,999).is_empty() and row.amount==10 and not row.claims.has(token),"Permission revocation safely releases uncollected claim")
	ready("bed",Vector2i(16,13));w.refresh_indoor();check(w.Homes.assign(w,right,"keeper"),"New roommate can be assigned")
	check(w.Access.can_take(w,row,a) and not w.Access.can_take(w,row,b),"New resident auto access, manual denial retained")
	check(w.Homes.title(w,w.homes[right])=="田中達の家","Earliest assigned resident names shared home")
	w.Access.set_permission(w,z,"helper",true);check(w.Access.can_take(w,row,b),"Manual permission restores withdrawal")
	var totals=w.Stock.totals(w);w.Zones.filter_change(w,z.id,"all","",false)
	check(w.Stock.totals(w)==totals and w.Access.can_take(w,row,b),"Filter and access remain separate; no item loss")
	# Build and craft cannot bypass the shared source authorization.
	w.Zones.filter_change(w,z.id,"all","",true);w.Access.set_permission(w,z,"keeper",false)
	w.act("wood_wall",Vector2i(35,25));var j=w.jobs.back();check(w.Delivery.sources(w,j,a).is_empty(),"Construction source scan respects actor permission")
	ready("carpentry_bench",Vector2i(34,25))
	var recipe=w.Craft.Data.RECIPES.keys().filter(func(k):return w.Craft.Data.RECIPES[k].output=="wood_crate")[0]
	w.Craft.enqueue(w,Vector2i(34,25),recipe,"count",1);j=w.jobs.back()
	check(not w.Craft.prepare(w,j,a) and row.amount==10,"Crafting cannot reserve unauthorized wood")
	var equipment=w.Stock.add(w,"fiber_clothes",1,Vector2i(15,11));check(w.Stock.reserve(w,"fiber_clothes",1,"equip",a).is_empty() and equipment.amount==1,"Equipment uses same withdrawal check")
func transactions():
	w=fixture();var a=w.keeper;var z=w.Zones.find(w,w.Zones.create(w,"stockpile",Vector2i(31,25),Vector2i(32,25)))
	w.Stock.add(w,"wood",10,Vector2i(31,25));w.Stock.add(w,"fiber_clothes",1,Vector2i(32,25));w.Access.set_permission(w,z,"keeper",false)
	a.timetable.fill("work");w.act("wood_wall",Vector2i(35,25));tick_work(24)
	check(not w.structures.has(Vector2i(35,25)) and w.Stock.totals(w).wood==10,"Denied construction does not consume stock")
	w.Access.set_permission(w,z,"keeper",true);tick_work(140)
	check(w.structures.get(Vector2i(35,25),{}).get("status")=="ready" and w.Stock.totals(w).wood==5,"Restored access resumes delivery and construction exactly once")
	check(w.HumanCombat.equip(w,"fiber_clothes"),"Clothing designation accepted");tick_work(120)
	check(a.get("clothing",{}).get("item_id")=="fiber_clothes" and w.Stock.totals(w).get("fiber_clothes",0)==1 and not w.field_items.any(func(r):return r.kind=="fiber_clothes"),"Authorized equipment uses one physical item")
	w.Stock.add(w,"mushroom",2,Vector2i(32,25));w.Access.set_permission(w,z,"keeper",false)
	var creature={"id":88,"placed":true,"hp":1,"max_hp":20};w.animals.append(creature)
	w.heal_with_mushrooms();check(creature.hp==1 and w.Stock.totals(w).mushroom==2,"Denied automatic mushroom healing exits without infinite loop or free heal")
	w.animals.clear()
func companion_food():
	w=fixture();var a=w.keeper.duplicate(true);a.erase("work_key");a.sleep_key="a99";a.id=99;a.category="human";a.state="待機";a.satiety=20;a.sleepiness=0;a.timetable.fill("work");a.appetite="large";w.animals.append(a)
	w.Zones.create(w,"stockpile",Vector2i(31,25),Vector2i(31,25));w.Stock.add(w,"mushroom",2,Vector2i(31,25))
	for i in range(20):w.tick+=1;w.Food.step(w,a)
	check(a.satiety>20 and w.Stock.totals(w).mushroom==1,"Human companion shares two-second meal system without worker registration")
	check(not w.workers.has("a99") and w.Sleep.people(w).has("a99"),"Human support AI retained while life settings include companion")
func danger_focus_mood():
	w=fixture();var a=w.keeper;w.Sleep.initialize(a);a.timetable.fill("sleep");a.sleepiness=100
	w.spawn_enemy({"role":"kidnapper","entry":Vector2i(0,30),"lv":1,"wave":999});var e=w.enemies.back();e.pos=Vector2i(90,60)
	w.Resident.step(w,a);check(a.danger_state=="relaxed","Unseen enemy does not reveal coordinates or trigger personal detection")
	a.work_trait="distracted";e.pos=a.pos+Vector2i(2,0);ready("wood_wall",a.pos+Vector2i.RIGHT);w.refresh_indoor();w.Resident.step(w,a)
	check(a.danger_state=="relaxed","Distracted detection cannot see through a wall")
	w.structures.erase(a.pos+Vector2i.RIGHT);w.refresh_indoor()
	e.pos=a.pos+Vector2i(2,0);w.Sleep.begin(w,a,false);w.Resident.step(w,a);w.Sleep.step(w,a)
	check(a.danger_state=="alert" and not a.resting,"Seen danger wakes and prevents sleep at fatigue100")
	w.Sleep.begin(w,a,false);w.Life.hurt(w,e);check(a.danger_state=="extreme" and not a.resting,"Attack wakes immediately and records extreme tension")
	e.pos=Vector2i(90,60);w.tick+=40;w.Resident.step(w,a);w.Sleep.step(w,a);check(a.danger_state=="tense" and not a.resting,"Remaining enemy holds tension after attacker leaves sight")
	e.done=true;w.tick+=ceili(w.Resident.SAFE_SECONDS/w.DT)+1;w.Resident.step(w,a);w.Sleep.step(w,a);check(a.danger_state=="relaxed" and a.resting,"Safe interval releases tension and reevaluates forced sleep")
	w.Sleep.wake(w,a);a.timetable.fill("work");a.sleepiness=0;a.satiety=100;a.danger_state="relaxed"
	var normal=w.Resident.chance({"work_trait":"normal"},true);var builder=w.Resident.chance({"work_trait":"builder"},true);var distracted=w.Resident.chance({"work_trait":"distracted"},true)
	check(0<distracted and distracted<normal and normal<builder and builder<1,"Focus probabilities independent, builder highest, never guaranteed")
	w.act("wood_wall",Vector2i(35,25));var j=w.jobs.back();j.assigned_to="keeper";j.state="working";a.work_job=j.id;a.work_trait="builder"
	w.rng.seed=17;var occurred=false
	for i in range(400):
		w.tick+=1;w.Resident.focus(w,a)
		if a.get("focus_work",1.0)>1:occurred=true;break
	check(occurred,"Sustained work can probabilistically enter focus")
	var until=a.get("focus_until",0);var factor=w.Jobs.factor(a);w.Resident.focus(w,a)
	a.stamina=100;a.needs_last_pos=a.pos;w.Needs.update(w,a,true)
	check(is_equal_approx(a.stamina,100+w.Needs.Data.RATES.work*w.DT*w.Resident.FOCUS_COST),"Focus stamina reduction applied exactly once")
	check(a.focus_until==until and is_equal_approx(w.Jobs.factor(a),factor),"Focus does not stack or extend on every tick")
	w.Work.interrupt(w,"keeper","test");check(a.focus_work==1 and a.focus_cost==1,"Interruption clears both focus corrections")
	for i in range(100):w.Resident.remember(w,a,"meal")
	check(a.mood_events.size()<=w.Resident.MOOD_EVENTS.size(),"Repeated events bounded by event type")
	w.Needs.meal(w,a,"mushroom");check(a.mood_events.has("meal") and not a.mood_events.has("quality"),"Simple food gives meal satisfaction without quality penalty")
	w.tick+=800;a.mood_next=0;w.Resident.step(w,a);check(a.mood_events.is_empty() and a.satisfaction>=0 and a.satisfaction<=100,"Mood memories expire and satisfaction stays bounded")
	check(w.Resident.detection({"work_trait":"distracted"})==2,"Distracted appetite_kind has bounded detection bonus")
func run():
	food();permissions();transactions();companion_food();danger_focus_mood()
	var failed=checks.filter(func(c):return not c.passed).size()
	var f=FileAccess.open(OS.get_environment("FARM_REVIEW_OUTPUT")+"/resident-life.json",FileAccess.WRITE);f.store_string(JSON.stringify({"checks":checks,"count":checks.size(),"failed":failed},"  "));f.close()
	print("Resident life: %d checks, %d failures"%[checks.size(),failed]);quit(1 if failed else 0)


