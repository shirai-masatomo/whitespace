extends SceneTree
const Farm=preload("res://game/world.gd")
var out=""
var failures=0
var group={}
var report={"method":"Controlled fixture at starvation thresholds; production World.step, physical food and full snapshot. Not a natural multi-day playthrough.","groups":[]}
func _initialize():call_deferred("run")
func begin(name):group={"name":name,"checks":[]};report.groups.append(group)
func check(ok,note):
	group.checks.append({"passed":bool(ok),"check":note})
	if not ok:failures+=1;push_error(note)
func farm():
	var w=Farm.new({},31).begin_day();w.trees.clear();w.natural.clear();w.field_items.clear();w.stock_used={};w.nature_config.spawn_chance_per_second=0;w.story.intro_seen=true
	w.keeper.pos=Vector2i(6,8);w.keeper_path=[[6,8]];w.keeper.satiety=0;w.keeper.sleepiness=0;w.animals[0].mode="stay";w.animals[0].pos=Vector2i(10,8);w.animals[0].home=w.animals[0].pos;w.Stock.sync(w);return w
func summary(w):return {"keeper":w.keeper,"items":w.field_items,"used":w.stock_used,"jobs":w.jobs,"tick":w.tick,"clock":w.calendar_ticks}
func run():
	out=OS.get_environment("FARM_REVIEW_OUTPUT")
	if out=="" or "--isolated-review" not in OS.get_cmdline_user_args():quit(2);return
	if "--resume-nutrition" in OS.get_cmdline_user_args():
		begin("Separate process in-flight meal continuation")
		var saved=Farm.Snapshot.restore(out+"/nutrition.snapshot");var expected=FileAccess.open(out+"/expected.bin",FileAccess.READ).get_var(false)
		check(summary(saved)==expected.before,"Nutrition, meal progress and physical food restore exactly")
		for i in range(8):saved.step()
		check(summary(saved)==expected.after,"Meal consumes once and continuation matches uninterrupted run")
		write("restart.json");return
	begin("1 Slow deterioration, work/movement effects, inability and later death")
	var w=farm();var p=w.Work.Policy;var n=w.Nutrition
	check((p.SATIETY_MAX-p.EAT_THRESHOLD)/p.HUNGER_PER_SECOND==350.0 and n.EMPTY_TO_DEATH_SECONDS==2*w.Cycle.Clock.DAY_SECONDS,"Full satiety reaches meal seeking at 350s; starvation then has two days before death")
	w.keeper.malnutrition=24.99;w.step();check(is_equal_approx(w.Jobs.factor(w.keeper),0.8),"First deterioration reduces real movement and work factor to 80 percent")
	w.keeper.malnutrition=49.99;w.step();check(is_equal_approx(w.Jobs.factor(w.keeper),0.5),"Severe deterioration reduces real movement and work factor to 50 percent")
	w.Work.set_drafted(w,"keeper",true);w.Life.command(w,"keeper_move",Vector2i(15,8));w.keeper.malnutrition=74.99;var position=w.keeper.pos
	w.step();check(w.keeper.nutrition_down and w.keeper.hp>0 and not w.keeper.get("dead",false) and w.keeper.pos==position,"Inability interrupts a drafted move while still alive")
	check(not w.Life.able(w) and not w.Life.plan_rest_until(w,"night"),"Inability cannot move, attack or accelerate time via rest")
	check(is_equal_approx((n.DEATH-n.DOWN)*n.EMPTY_TO_DEATH_SECONDS/100.0,216.0),"The separate death threshold leaves 216 seconds after inability without food")
	check(not w.animals[0].has("satiety") and not w.animals[0].has("malnutrition"),"Animal hunger is not introduced")
	w.keeper.malnutrition=99.99;w.step();check(w.keeper.dead and w.keeper.hp==0 and w.result=="loss" and w.story.defeat_reason=="malnutrition","Later starvation has an explicit terminal death result")
	w.incidents.append({"id":"defeat-proof","day":1,"settled":false});w.enemies.append({"incident":"defeat-proof","done":true});var gold=w.campaign.gold;w.Cycle.settle_incidents(w)
	check(w.campaign.gold==gold and not w.incidents[-1].settled,"Defeat cannot trigger the provisional raid completion reward")
	begin("2 Hand-reach recovery, prohibition, gradual return and save during a meal")
	w=farm();w.keeper.nutrition_down=true;w.keeper.malnutrition=75;w.keeper.drafted=true
	for cell in w.neighbors(w.keeper.pos):w.trees[cell]={"hp":99,"kind":"tree"}
	var food=w.Stock.add(w,"meat",2,w.keeper.pos);food.forbidden=true
	for i in range(4):w.step()
	check(w.keeper.nutrition_down and w.Stock.cargo(w,"keeper",-2).is_empty() and food.amount==2,"Forbidden nearby food is neither eaten nor duplicated")
	food.forbidden=false
	for i in range(4):w.step()
	check(w.keeper.has("meal_remaining") and not w.Stock.cargo(w,"keeper",-2).is_empty(),"Incapacitated drafted worker eats food at own feet even with every exit blocked")
	Farm.Snapshot.save(w,out+"/nutrition.snapshot");var before=summary(w).duplicate(true)
	for i in range(8):w.step()
	var after=summary(w).duplicate(true);FileAccess.open(out+"/expected.bin",FileAccess.WRITE).store_var({"before":before,"after":after},false)
	check(w.stock_used.get("meat",0)==1 and w.keeper.satiety>0 and w.keeper.nutrition_down,"One meal consumes exactly one physical meat and does not instantly remove inability")
	var restored=Farm.Snapshot.restore(out+"/nutrition.snapshot")
	for i in range(8):restored.step()
	check(summary(restored)==after,"Saved in-flight meal resumes without duplicate consumption")
	var recovery_start=w.tick;var recovery_level=w.keeper.malnutrition
	for i in range(500):
		w.step()
		if not w.keeper.nutrition_down:break
	check(not w.keeper.nutrition_down and w.keeper.malnutrition<50 and w.tick-recovery_start>400 and w.keeper.pos==Vector2i(6,8),"Fed worker gradually recovers for more than 100 seconds before becoming able")
	group.observation={"recovery_seconds":(w.tick-recovery_start)*w.DT,"before":recovery_level,"after":w.keeper.malnutrition,"meat_consumed":w.stock_used.get("meat",0)}
	w=farm();w.keeper.malnutrition=60;w.Zones.create(w,"residential",Vector2i(20,8),Vector2i(20,8));w.Life.set_rest(w,true,"forced");w.keeper.forced_rest=true;w.Stock.add(w,"milk",1,Vector2i(6,9))
	for i in range(3):w.step()
	check(w.keeper.get("life_need","")=="food" and not w.keeper.resting and w.keeper.get("meal_rest_kind","")=="forced","Malnourished forced sleeper pauses residential travel while food owns movement")
	for i in range(15):w.step()
	check(w.stock_used.get("milk",0)==1 and w.keeper.resting and w.keeper.rest_kind=="forced","After the meal the original forced rest resumes without competing movement")
	w=farm();w.keeper.malnutrition=60;w.Life.set_rest(w,true,"manual");w.step()
	check(w.keeper.resting and w.keeper.rest_kind=="manual" and not w.keeper.has("meal_rest_kind"),"No reachable food restores the original manual rest instead of dropping it")
	write("nutrition.json")
func write(name):
	report.passed=failures==0;report.failures=failures;FileAccess.open(out+"/"+name,FileAccess.WRITE).store_string(JSON.stringify(report,"\t"));print("Nutrition09: ",report.groups.size()," groups, ",failures," failures");quit(0 if failures==0 else 1)
