extends "res://tests/test_progression.gd"
const Save=preload("res://game/morning_save.gd")
func prayers(categories: Array,seed_value: int=31):
	var c=Farm.new_campaign();c.day=2;var w=Farm.new(c,seed_value).begin_day();w.story.investigated=true
	for i in range(categories.size()):
		w.campaign.day=2+i;w.Story.pray(w,categories[i])
	return w
func morning(w,day: int):
	w.persist_farm();var c=w.campaign.duplicate(true);c.day=day;c.night_ready=false;c.erase("morning_checkpoint")
	return Farm.new(c,w.seed_value)
func raids(w) -> Array:
	return w.spawn_schedule.filter(func(e):return e.wave>=100).map(func(e):return e.role)
func run():
	var samples=[]
	for seed_value in [17,31,73]:
		for day in [1,4,11,12,15,16,30]:
			var plan=P.Encounters.plan(day,seed_value,0)
			check(plan.waves.all(func(wave):return wave.lv==1) if day<=11 else plan.waves[0].lv==2 and plan.waves.slice(1).all(func(wave):return wave.lv==1),"One later lead role grows; introductions stay unchanged: %d/%d"%[seed_value,day])
	for id in Farm.ProgressData.ENEMY_ROWS:
		var one=Farm.ProgressData.enemy(id,1);var two=Farm.ProgressData.enemy(id,2)
		check(two.max_hp>one.max_hp and two.move_speed==one.move_speed and two.human_attack==one.human_attack and two.object_attack_power==one.object_attack_power and two.skills==one.skills,"Lv2 is a bounded HP tier, retaining the role: "+id)
	for species in ["cow","bull","maid"]:
		var c=Farm.new_campaign();c.exp_pool=100;c.animals.append({"id":2,"species":species,"category":Farm.SPECIES[species].category,"lv":1,"xp":0,"loyalty":85})
		var w=Farm.new(c,31);check(w.train_animal(2),"New resident can use shared EXP: "+species)
		var restored=Save.restore(Save.capture(w));var day=restored.begin_day();var a=day.Orders.animal(day,2)
		check(a.lv==2 and a.max_hp==Farm.SPECIES[species].hp+4 and a.hp==Farm.SPECIES[species].hp,"Growth survives saving without free healing: "+species)
	var w=fresh();w.debug_enabled=true;w.debug_action("cow",{});var cow=w.animals.back();cow.pos=Vector2i(9,9);cow.placed=true;w.trees.clear()
	w.spawn_enemy({"role":"maid","entry":w.entries[0],"lv":2});var e=w.enemies.back();e.pos=Vector2i(10,9);e.debug_recruit_chance=1.0;e.threat_until=0
	check(w.Content.recruit_maid(w,e) and w.animals.back().lv==2 and w.animals.back().hp==49 and w.animals.back().max_hp==49,"Lv2 maid keeps the same health on joining")
	for seed_value in [17,31,73]:
		for category in ["animal","item","gold"]:
			w=prayers([category],seed_value)
			var first=7 if category=="animal" else (10 if category=="item" else 5)
			var before=morning(w,first-1);var after=morning(w,first)
			check(raids(before).is_empty(),"Reaction never precedes its event and role introduction: %d/%s"%[seed_value,category])
			var expected={"animal":"animal_tamer","item":"thief","gold":"idol_breaker"}[category]
			check(raids(after)==[expected] and after.spawn_schedule.filter(func(row):return row.wave>=100).all(func(row):return row.lv==1),"Category reaction uses one real Lv1 role: %d/%s"%[seed_value,category])
			var saved=Save.capture(after);var replay=Save.restore(saved);var repeated=Save.restore(Save.capture(replay))
			check(raids(repeated)==raids(after) and repeated.story.raid_slots==after.story.raid_slots and repeated.story.news==after.story.news and repeated.campaign.gold==after.campaign.gold,"Save and repeated morning cannot reroll, add slots or pay twice: %d/%s"%[seed_value,category])
			samples.append({"seed":seed_value,"category":category,"first_raid_day":first,"raids":raids(after),"news":after.story.news})
	w=prayers(["animal","item","gold"]);var mixed=morning(w,7)
	check(mixed.story.raid_slots.size()==2 and raids(mixed)==["idol_extractor"],"Latest two reactions replace the oldest; a waiting item slot is not filled by a legacy raid")
	mixed=morning(mixed,10);check(raids(mixed)==["thief","idol_extractor"] and mixed.story.hidden.security==2,"Mixed reactions remain capped at two actual arrivals")
	var stock=mixed.shop_stock.duplicate(true);var money=mixed.campaign.gold;mixed.Story.morning(mixed,10);mixed.make_schedule()
	check(raids(mixed)==["thief","idol_extractor"] and mixed.shop_stock==stock and mixed.campaign.gold==money,"Repeated event application does not add raids, stock or money")
	for category in ["wealth","animal","item"]:
		w=prayers([category])
		for event in w.story.events:
			for key in ["reaction_version","reaction_role","raid_not_before_day"]:event.erase(key)
		var old=morning(w,5)
		check(raids(old)==["idol_breaker"] and not old.story.has("raid_slots"),"Historical category contracts retain their idol reaction: "+category)
	w=prayers([]);w.story.hidden.security=2;w.story.hidden.recognition=1;w=morning(w,5)
	check(raids(w)==["idol_breaker","idol_extractor"],"Legacy security without event records keeps both old roles")
	w=prayers([]);w=morning(w,16)
	check(raids(w).is_empty() and w.story.hidden.karma==0,"No-prayer progression reaches the endpoint without mandatory karma raids")
	FileAccess.open("user://campaign-tiers.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":records,"samples":samples,"tuning":"provisional HP-only growth, latest-two category reactions; not survival acceptance"},"  "))
	print("CAMPAIGN_TIERS: %d checks, failures=%d"%[checks,failures]);quit(1 if failures else 0)
