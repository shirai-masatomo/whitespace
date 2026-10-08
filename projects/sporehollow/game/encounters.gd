extends RefCounted
const Data = preload("res://game/progression_data.gd")
## Learning nights are data, not day-number branches in the simulation.
const NIGHTS = {
	11:{"mode":"Hybrid","fixed":["maid"],"count":1},
	1:{"mode":"Fixed","fixed":["kidnapper"],"count":0},
	2:{"mode":"Fixed","fixed":["salaryman","salaryman"],"count":0},
	3:{"mode":"Fixed","fixed":["destroyer"],"count":0},
	4:{"mode":"Table","fixed":[],"count":2},
	5:{"mode":"Hybrid","fixed":["martial_artist"],"count":1},
	6:{"mode":"Hybrid","fixed":["ninja"],"count":1},
	7:{"mode":"Hybrid","fixed":["animal_tamer"],"count":1},
	9:{"mode":"Hybrid","fixed":["dancer"],"count":1},
	10:{"mode":"Hybrid","fixed":["thief"],"count":1},
	8:{"mode":"Hybrid","fixed":["runner"],"count":1}}
const FIRST_DAY = {"kidnapper":1,"salaryman":2,"destroyer":3,"martial_artist":5,"ninja":6,"animal_tamer":7,"runner":8,"dancer":9,"thief":10,"maid":11}
const TABLE_NIGHT = {"mode":"Table","fixed":[],"count":3}
const MILESTONE = {"interval":5,"from_day":10,"mode":"Hybrid","fixed":["runner"],"count":2}
const ROUTE_ID="first-cycle-v1"

static func route_definition() -> Dictionary:
	var last_intro=int(FIRST_DAY.values().max())
	var night=maxi(last_intro+1,MILESTONE.from_day)
	while night%MILESTONE.interval!=0 or NIGHTS.has(night):night+=1
	return {"version":1,"last_intro":last_intro,"completion_night":night}

static func route_phase(day: int) -> String:
	var route=route_definition()
	if day<=route.last_intro:return "introduction"
	if day<route.completion_night:return "mixed"
	if day==route.completion_night:return "milestone"
	return "continuation"

static func record_win(campaign: Dictionary,seed_value: int):
	var progress=campaign.route_progress
	progress.completed_through_day=maxi(progress.completed_through_day,campaign.day)
	var route=route_definition()
	if campaign.day>=route.completion_night and not progress.milestones.has(ROUTE_ID):
		progress.milestones[ROUTE_ID]={"rule_version":route.version,"target_night":route.completion_night,"achieved_night":campaign.day,"morning_day":campaign.day+1,"seed":seed_value}

static func reached(campaign: Dictionary) -> bool:
	return campaign.get("route_progress",{}).get("milestones",{}).has(ROUTE_ID)

static func route_text(campaign: Dictionary) -> String:
	if reached(campaign):return "ひと区切り達成 · この先も牧場を続けられます"
	var route=route_definition()
	match route_phase(campaign.day):
		"introduction":return "新しい相手との出会い · %d / %d日目"%[campaign.day,route.last_intro]
		"mixed":return "混成の襲撃に備える · 次の節目は%d日目"%route.completion_night
		"milestone":return "今夜は節目の防衛 · 仲間と黄金像を守ろう"
	return "牧場の日々は続きます"

static func eligible(row: Dictionary, context: Dictionary) -> bool:
	var karma=context.get("karma",0)
	if karma<row.get("karma_min",0) or (row.get("karma_max",-1)>=0 and karma>row.karma_max): return false
	if karma==0 and row.get("type_tag","Human") not in ["Human","Animal"]: return false
	if context.day<row.get("day_min",1) or context.get("stage",1)<row.get("stage_min",1): return false
	if row.get("story_flag","")!="" and row.story_flag not in context.get("story_flags",[]): return false
	if context.get("counts",{}).get(row.archetype,0)<row.get("encounter_min",0): return false
	if row.has("rarity_max") and row.rarity>row.rarity_max: return false
	return row.get("spawn_weight",1.0)>0

static func plan(day: int, seed_value: int, karma: int, stage: int=1, flags: Array=[], counts: Dictionary={}, override: Dictionary={}) -> Dictionary:
	var rule=override if not override.is_empty() else NIGHTS.get(day,MILESTONE if day>=MILESTONE.from_day and day%MILESTONE.interval==0 else TABLE_NIGHT)
	var context={"day":day,"karma":karma,"stage":stage,"story_flags":flags,"counts":counts}
	var candidates=[]
	for id in Data.ENEMY_ROWS:
		var row=Data.enemy(id); row.day_min=FIRST_DAY[id]
		if eligible(row,context): candidates.append(row)
	var rng=RandomNumberGenerator.new(); rng.seed=seed_value*8191+day*131
	var chosen=[]
	if rule.mode in ["Fixed","Hybrid"]:
		for id in rule.get("fixed",[]):
			var row=Data.enemy(id)
			if Data.ENEMY_ROWS.has(id) and eligible(row,context): chosen.append(id)
	if rule.mode in ["Table","Hybrid"] and not candidates.is_empty():
		for i in range(rule.get("count",1)): chosen.append(candidates[Data.weighted(rng,candidates.map(func(c):return c.spawn_weight))].archetype)
	var waves=[]
	# First-cycle provisional growth: introductions remain Lv1; only the first known role advances.
	for i in range(chosen.size()): waves.append({"start_seconds":i*18.0,"interval_seconds":1.0,"jitter_seconds":0.0,"count":1,"role":chosen[i],"entries":[[1,5]],"lv":2 if day>route_definition().last_intro and i==0 else 1})
	return {"encounter_mode":rule.mode,"chosen":chosen,"first_attack_seconds":10.0,"repeat_waves":false,"repeat_interval_seconds":60.0,"time_limit_seconds":180.0,"waves":waves}
