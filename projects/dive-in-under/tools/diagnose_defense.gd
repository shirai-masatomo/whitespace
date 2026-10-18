extends SceneTree
## Diagnostic only: paired inputs call the production core; no balance mutation.
const C = preload("res://core/combat.gd")
const E = preload("res://core/expedition.gd")
const Catalog = preload("res://core/catalog.gd")
const Policy = preload("res://tools/campaign_policy.gd")
const Stats = preload("res://tools/simulation.gd")

func compact(result: Dictionary) -> Dictionary:
	return {"outcome":result.outcome,"rounds":result.round,"hp":result.hero.hp,"sp":result.hero.sp,"enemy_hp":result.enemy.hp,"casts":result.log.filter(func(x):return x.type=="skill").size(),"hero_attacks":result.log.filter(func(x):return x.type=="attack" and x.actor=="hero").size(),"enemy_attacks":result.log.filter(func(x):return x.type=="attack" and x.actor=="enemy").size(),"log":result.log}

func paired(h: Dictionary, e: Dictionary, rules: Dictionary, seed_value: int) -> Dictionary:
	var off:=h.duplicate(true); off.skills=[]
	var on:=h.duplicate(true); on.skills=["S105"]
	return {"seed":seed_value,"hero":h,"enemy":e,"without":compact(C.simulate(off,e,rules,seed_value)),"with":compact(C.simulate(on,e,rules,seed_value))}

func windows(result: Dictionary) -> Array:
	var values: Array=[]
	var incoming: int=-1
	for event in result.log:
		if event.type=="skill" and event.actor=="hero": incoming=0
		elif event.type=="attack" and event.actor=="enemy" and incoming>=0: incoming+=1
		elif event.type=="status_removed" and event.actor=="hero" and incoming>=0:
			values.append({"attacks":incoming,"reason":event.reason}); incoming=-1
	return values

func _initialize() -> void:
	var data:=Catalog.load_data()
	var cfg: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/v1/expedition-no-defense.json"))
	var policy: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/scenarios/campaign.json"))
	var examples: Array=[]
	var candidates: Array=[]
	var natural: Array=[]
	# Obtain effective hero inputs from actual baseline progression, with no fabricated growth.
	for campaign_seed in range(10000,10020):
		var s:=E.fresh(cfg,campaign_seed)
		for step in range(30000):
			if s.phase=="battle" and s.battle.rounds==0 and s.sp>=3:
				var pair:=paired(s.battle.hero,C.enemy(data,s.battle.enemy_id,int(s.battle.enemy_level)),data.rules,int(s.battle.seed))
				pair.campaign_seed=campaign_seed; pair.trip=E.normal_trips(s); pair.floor=s.floor
				if pair.with.casts>0:
					var row:=pair.duplicate(true); row.with.erase("log"); row.without.erase("log")
					natural.append(row)
					if candidates.is_empty(): candidates.append(pair)
					if pair.without.outcome=="victory" and pair.with.outcome=="defeat" and examples.size()<5: examples.append(pair)
			var choice:=Policy.choose(s,cfg,policy)
			s=E.act(s,choice.action,int(s.revision),choice.args,data,cfg)
			if s.phase=="result" and (s.result.kind=="clear" or E.normal_trips(s)>=30): break
	if candidates.is_empty(): printerr("No natural defense sample"); quit(1); return
	var selected: Dictionary=examples[0] if not examples.is_empty() else candidates[0]
	var random_pairs: Array=[]
	var totals: Dictionary={"without_wins":0,"with_wins":0,"without_deaths":0,"with_deaths":0,"casts":0,"lost_wins":0,"gained_wins":0}
	var off_rounds: Array=[]; var on_rounds: Array=[]; var off_hp: Array=[]; var on_hp: Array=[]
	for seed_value in range(10000,11000):
		var pair:=paired(selected.hero,selected.enemy,data.rules,seed_value)
		for side in ["without","with"]:
			totals[side+"_wins"]+=int(pair[side].outcome=="victory")
			totals[side+"_deaths"]+=int(pair[side].outcome=="defeat")
		totals.casts+=pair.with.casts
		totals.lost_wins+=int(pair.without.outcome=="victory" and pair.with.outcome=="defeat")
		totals.gained_wins+=int(pair.without.outcome=="defeat" and pair.with.outcome=="victory")
		off_rounds.append(pair.without.rounds); on_rounds.append(pair.with.rounds)
		off_hp.append(pair.without.hp); on_hp.append(pair.with.hp)
		pair.with.erase("log"); pair.without.erase("log"); pair.erase("hero"); pair.erase("enemy")
		random_pairs.append(pair)
	var deterministic: Dictionary=data.rules.duplicate(true)
	deterministic.hit_chance=1.0; deterministic.critical_chance=0.0; deterministic.variance_min=1.0; deterministic.variance_max=1.0
	var controlled:=paired(selected.hero,selected.enemy,deterministic,int(selected.seed))
	# Explicitly isolate own-action duration from death, damage variance and cooldown.
	var speed_cases: Dictionary={}
	for enemy_speed in [1,5,9]:
		var h: Dictionary={"max_hp":1000,"hp":600,"max_sp":3,"sp":3,"atk":1,"def":10,"spd":5,"skills":["S105"]}
		var e: Dictionary={"max_hp":1000,"hp":1000,"max_sp":0,"sp":0,"atk":10,"def":10,"spd":enemy_speed}
		var counts: Dictionary={"0":0,"1":0,"2":0}; var traces: Dictionary={}
		for seed_value in range(10000,11000):
			var result:=C.advance(C.advance(C.start(h,e,deterministic,seed_value)))
			var guarded:=windows(result)
			if guarded.size()!=1 or guarded[0].reason!="expired": printerr("Invalid duration window"); quit(1); return
			var key:=str(guarded[0].attacks); counts[key]+=1
			if not traces.has(key): traces[key]={"seed":seed_value,"log":result.log}
		speed_cases[str(enemy_speed)]={"hero_spd":5,"enemy_spd":enemy_speed,"incoming_attacks_per_defense":counts,"representative_traces":traces}
	var rounding: Array=[]
	for defense in [0,1,2,3,5,10,20]:
		var unit: Dictionary={"def":defense,"defense_until":1}
		var effective:=C.effective_def(unit,data.rules)
		for attack in [5,10,15,20]: rounding.append({"atk":attack,"def":defense,"effective_def":effective,"normal_damage":C.damage(attack,defense),"defended_damage":C.damage(attack,effective)})
	var report: Dictionary={"source":"working tree; initial SP remains 0; no production balance changes","natural_campaign_seeds":[10000,10019],"natural_casting_battles":natural,"representative_lost_wins":examples,"selected_input":selected,"fixed_1000":{"seeds":[10000,10999],"totals":totals,"without_rounds":Stats.distribution(off_rounds),"with_rounds":Stats.distribution(on_rounds),"without_hp":Stats.distribution(off_hp),"with_hp":Stats.distribution(on_hp),"pairs":random_pairs},"no_variance_counterfactual":controlled,"speed_duration":speed_cases,"rounding":rounding,"source_hashes":{"combat":FileAccess.get_sha256("res://core/combat.gd"),"balance":FileAccess.get_sha256(Catalog.PATH),"diagnostic":FileAccess.get_sha256("res://tools/diagnose_defense.gd")}}
	var file:=FileAccess.open("res://artifacts/defense-diagnosis.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(report,"\t")); file.close()
	print("DEFENSE_DIAGNOSIS: "+JSON.stringify(totals)+"; natural casting battles="+str(natural.size()))
	quit()
