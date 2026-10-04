extends SceneTree
const Farm=preload("res://game/world.gd")
var checks=0
var failures=0
func _initialize():call_deferred("run")
func check(ok: bool,why: String):
	checks+=1
	if not ok: failures+=1;push_error(why)
func steps(w,n):
	for i in range(n):w.step()
func drain(w):
	for i in range(600):
		if w.jobs.is_empty():return
		w.step()
func quiet():
	var w=Farm.new({},17).begin_day();w.day_seconds=9999;w.nature_config.spawn_chance_per_second=0
	return w
func run():
	var shop=Farm.new({},17)
	check(shop.phase=="shop" and shop.campaign.gold==40 and shop.animals[0].placed,"Funded morning with resident dog")
	check(not shop.buy("shiba") and not shop.buy("dog_food"),"No dog or food sale")
	check(shop.buy("hen") and shop.campaign.gold==10 and not shop.buy("wood"),"Animal budget tradeoff")
	check(shop.animals[1].placed,"Purchase naturally admits hen")
	for product in Farm.Shop.table().values():check(product.BuyPrice>product.SellPrice,"No resale profit: "+product.ProductID)
	shop.campaign.exp_pool=1000;shop.rename_animal(1,"こむぎ")
	for i in range(8):shop.train_animal(1)
	check(shop.campaign.animals[0].lv==5 and not shop.train_animal(1),"Lv5 cap")
	var w=shop.begin_day()
	check(w.animals[0].name=="こむぎ" and not w.train_animal(1),"Name and level persist; training morning only")
	w=quiet();w.spawn_enemy(w.spawn_schedule[0]);var a=w.animals[0];var e=w.enemies[0];e.pos=a.pos-Vector2i(4,0)
	w.try_bark(a);check(w.metrics.bark_casts==1 and e.hp==50,"Bark no damage")
	var origin=e.pos;w.move_enemy(e,origin+Vector2i.RIGHT);check(e.pos==origin,"Bark stops movement")
	w.tick=3;w.move_enemy(e,origin+Vector2i.RIGHT);check(e.pos==origin,"Stop through .75s")
	w.tick=4;w.move_enemy(e,origin+Vector2i.RIGHT);check(e.pos!=origin,"Movement resumes at1s")
	w.tick=23;w.try_bark(a);check(w.metrics.bark_casts==1,"CT before6s")
	w.tick=24;w.try_bark(a);check(w.metrics.bark_casts==2,"CT at6s")
	e.pos=a.pos-Vector2i.RIGHT;e.attacker=a.id;e.threat_until=100;e.counter_target=a.id;e.counter_until=100;e.ai_context="under_attack";e.intent="counter";e.next_decision=100
	w.enemy_step(e);check(a.hp==35,"Movement stop does not stop attacks")
	w=quiet();w.keeper.pos=Vector2i(19,8);w.spawn_enemy(w.spawn_schedule[0]);e=w.enemies[0];e.pos=Vector2i(5,8)
	w.RaiderAI.perceive(e,w);check(not e.can_see_keeper and e.last_known_keeper_position==null,"No omniscient tracking")
	var goal=w.RaiderAI.target(e,w);w.keeper.pos=Vector2i(23,14);check(w.RaiderAI.target(e,w)==goal,"Unseen move preserves search goal")
	w.keeper.pos=Vector2i(9,8);w.RaiderAI.perceive(e,w);check(e.can_see_keeper,"Clear sight detects")
	w.structures[Vector2i(7,8)]={"kind":"wall","status":"ready","open":false,"hp":8,"max_hp":8,"id":1,"cost":10,"armor":0}
	w.RaiderAI.perceive(e,w);check(not e.can_see_keeper and e.last_known_keeper_position==Vector2i(9,8),"Wall hides but retains last known position")
	w.structures[Vector2i(7,8)].kind="door";w.structures[Vector2i(7,8)].open=true;w.RaiderAI.perceive(e,w);check(e.can_see_keeper,"Open door admits sight")
	w=quiet();w.debug_enabled=true;w.debug_action("cat");var cat=w.animals[1];cat.lv=2;w.spawn_enemy(w.spawn_schedule[0]);e=w.enemies[0];e.pos=cat.pos+Vector2i.LEFT
	w.try_meow(cat);check(e.weakened_until>w.tick and cat.attack_power==0,"Cat weakens without normal attacks")
	w=quiet();w.natural[Vector2i(6,12)]="weed";var gold=w.campaign.gold;w.paused=true
	check(w.act("collect",Vector2i(6,12)),"Pause accepts harvest plan");steps(w,8);check(w.campaign.gold==gold,"Pause never harvests")
	w.paused=false;drain(w);check(w.campaign.gold==gold+1 and not w.act("collect",Vector2i(6,12)),"Harvest once on arrival")
	w.natural[Vector2i(6,12)]="mushroom";w.act("collect",Vector2i(6,12));drain(w);w.animals[0].hp=32;w.finish(true)
	check(w.animals[0].hp==37 and w.campaign.mushrooms==0,"Dawn mushroom heals5")
	check(w.campaign.animals[0].lv==1 and w.campaign.exp_pool==w.score.xp,"EXP shared without automatic level")
	var next=Farm.new(w.next_campaign());check(next.campaign.day==2 and next.stage==1 and next.phase=="shop","Next morning same Stage1")
	w=quiet();w.animals[0].hp=0;w.finish(true);next=Farm.new(w.next_campaign()).begin_day()
	check(next.animals[0].placed and not next.available(next.animals[0]),"Convalescence remains in ranch")
	next.finish(true);next=Farm.new(next.next_campaign()).begin_day();check(next.animals[0].hp==20 and next.available(next.animals[0]),"Recovery after one full day")
	w=quiet();w.field_items=[{"kind":"egg","pos":Vector2i(8,8),"born_day":0}];w.finish(true);check(w.field_items[0].kind=="chick","Egg ages to chick")
	next=Farm.new(w.next_campaign()).begin_day();next.finish(true);check(next.campaign.animals.size()==2 and next.field_items.is_empty(),"Chick ages to owned hen")
	shop=Farm.new();shop.buy("hen");w=shop.begin_day();w.finish(true);check(w.dawn_summary.eggs==1,"Resident hen daily egg")
	var eggs=w.field_items.size();w.finish(true);check(w.field_items.size()==eggs,"No repeated dawn production")
	w=quiet();w.field_items.append({"kind":"kennel_plan","pos":Vector2i(6,12),"born_day":1});check("kennel" not in w.campaign.unlocked_blueprints,"Drop not auto-unlock")
	w.act("collect",Vector2i(6,12));drain(w);check("kennel" in w.campaign.unlocked_blueprints,"Onsite pickup unlocks")
	w.wood=100;w.act("kennel",Vector2i(7,13));drain(w);w.animals[0].pos=Vector2i(7,13);w.animals[0].hp=20;w.animals[0].mode="rest";steps(w,20)
	check(w.animals[0].hp==21 and not w.structures.has(Vector2i(7,13)),"Normal rest heals without disabled kennel")
	w=quiet();w.nature_config.spawn_chance_per_second=1.0
	for y in range(1,w.H-1):
		for x in range(1,w.W-1):w.floors[Vector2i(x,y)]={"kind":"soil_tile","status":"ready"}
	steps(w,80);check(w.natural.is_empty(),"No forced natural spawn on tiled map")
	w.floors.clear();steps(w,300);check(w.natural.size()<=w.nature_config.limit,"Natural population cap")
	for kind in w.nature_config.caps:check(w.metrics[kind+"_spawned"]<=w.nature_config.caps[kind],"Natural per-kind cap")
	var left=quiet();var right=quiet()
	for sample in [left,right]:sample.act("wall",Vector2i(10,10));sample.act("guide",Vector2i(15,12),1);steps(sample,140)
	check(JSON.stringify(left.observation())==JSON.stringify(right.observation()),"Deterministic replay")
	print("WORLD: ",checks," checks, failures=",failures)
	quit(1 if failures else 0)
