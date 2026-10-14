extends SceneTree
const Farm=preload("res://game/world.gd")
var checks=[]
func check(ok,note):
	checks.append({"check":note,"passed":bool(ok)})
	if not ok:push_error(note)
func _initialize():call_deferred("run")
func run():
	var out=OS.get_environment("FARM_REVIEW_OUTPUT")
	if DisplayServer.get_name()!="headless" or out=="":quit(2);return
	var w=Farm.new(Farm.new_campaign(),31).begin_day();w.jobs.clear();w.enemies.clear();var a=w.keeper;w.Needs.begin(w)
	for row in [[100,100,1.0],[76,100,1.0],[75,90,1.0],[51,90,1.0],[50,80,0.75],[26,80,0.75],[25,60,0.5],[1,60,0.5],[0,40,0.25]]:
		check(w.Needs.band(row[0])[1]==row[1] and w.Needs.band(row[0])[2]==row[2],"Satiety band "+str(row[0]))
	a.satiety=100;a.stamina=50;a.needs_rest=false;a.resting=false;w.Needs.update(w,a,true);var after=a.stamina;w.Combat.recover(a,w.DT)
	check(a.stamina==after and is_equal_approx(after,50+2*w.DT),"Shared idle recovery exactly once")
	var before=a.stamina;w.Combat.pay(a,"move");check(a.stamina==before,"Movement has no duplicated combat cost")
	a.stamina=14;w.Needs.update(w,a,true);check(a.needs_rest,"Low stamina enters recovery")
	a.stamina=30;w.Needs.update(w,a,true);check(a.needs_rest,"Recovery hysteresis prevents short task switches")
	a.stamina=60;w.Needs.update(w,a,true);check(not a.needs_rest,"Recovered actor resumes")
	a.satiety=10;w.Needs.meal(w,a,"egg_meal");check(a.satiety==45 and a.food_regen_factor==1.2,"Egg meal gain and timed regen")
	w.Needs.meal(w,a,"egg_meal");check(a.food_regen_factor==1.2,"Repeated food buff cannot stack")
	w.tick=a.meal_effect.until;w.Needs.refresh_effect(w,a);check(not a.has("meal_effect") and a.food_regen_factor==1,"Effect expires by world time")
	w.Needs.meal(w,a,"roast_meat");a.stamina=100;w.Combat.pay(a,"attack");check(is_equal_approx(a.stamina,94.6),"Meat reduces existing combat cost once")
	w.Needs.meal(w,a,"stew");check(a.food_work_factor==1.1 and a.food_cost_factor==1,"New meal replaces previous effect")
	a.satiety=0;a.hp=10;a.starve_seconds=60;a.starve_damage=20;w.Needs.update(w,a,true);check(a.hp==9 and a.max_stamina==40,"Starvation damage and max stamina")
	a.hp=0;a.starve_damage=20;w.Needs.update(w,a,true);check(a.hp==0,"Starvation never revives an unconscious human")
	var dog=w.animals.filter(func(x):return x.species=="shiba")[0];dog.hp=1;dog.satiety=0;dog.starve_seconds=60;dog.starve_damage=20;w.Needs.update(w,dog,false);w.animal_step(dog)
	check(dog.hp==0 and not dog.get("dead",false),"Starving shiba is unconscious, not killed")
	for recipe in w.Craft.Data.RECIPES.values():check(not recipe.ingredients.is_empty() and recipe.count>0 and recipe.seconds>0,"Recipe has complete data: "+recipe.output)
	var fail=checks.filter(func(c):return not c.passed).size();FileAccess.open(out+"/living-needs.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":fail},"\t"));print("LIVING_NEEDS: ",checks.size()," checks, failures=",fail);quit(1 if fail else 0)
