extends RefCounted
const E = preload("res://core/expedition.gd")
const Policy = preload("res://tools/campaign_policy.gd")
const Stats = preload("res://tools/simulation.gd")

static func normalized(v: Variant) -> Variant:
	return JSON.parse_string(JSON.stringify(v))

static func state_hash(s: Dictionary) -> String:
	return JSON.stringify(normalized(s)).sha256_text()

static func play(data: Dictionary, cfg: Dictionary, policy: Dictionary, seed_value: int, trace: bool=false) -> Dictionary:
	var s:=E.fresh(cfg,seed_value)
	var records: Array=[]
	var actions: Array=[]
	var floors: Dictionary={}
	for floor_number in range(1,11): floors[str(floor_number)]={"entries":0,"deaths":0,"returns":0,"clears":0,"battles":0,"chests":0,"events":0,"enemies":{},"levels":{},"items":{}}
	var trip: Dictionary={}
	var error:=""
	var step_count:=0
	var digest:=""
	var story_count:=0
	var reached10:=false
	var highest_level:=1
	var owned:=0
	while step_count<30000:
		var choice:=Policy.choose(s,cfg,policy)
		var before:=s
		s=E.act(s,choice.action,int(s.revision),choice.args,data,cfg)
		step_count+=1
		if s.revision==before.revision: error="policy made no progress"; break
		error=E.validate(s,data,cfg)
		if error!="": break
		# Full state chain covers combat checkpoints, rewards, RNG counters and inventory.
		digest=(digest+state_hash(s)).sha256_text()
		if trace: actions.append({"action":choice.action,"args":choice.args,"revision":s.revision,"phase":s.phase,"floor":s.floor,"state_sha256":state_hash(s)})
		if choice.action=="depart":
			trip={"trip":E.normal_trips(s),"start_level":E.hero(s,cfg).level,"exp_start":s.exp,"gold_start":s.gold,"exp_earned":0,"gold_earned":0,"loot":{},"rounds":0,"hp_lost_in_combat":0,"floor_max":0}
		if before.first_done and choice.action=="descend":
			var f: Dictionary=floors[str(s.floor)]
			f.entries+=1; trip.floor_max=s.floor
			if s.floor==10: reached10=true
			if s.phase=="battle":
				f.battles+=1
				f.enemies[s.battle.enemy_id]=int(f.enemies.get(s.battle.enemy_id,0))+1
				f.levels[str(s.battle.enemy_level)]=int(f.levels.get(str(s.battle.enemy_level),0))+1
			elif s.phase=="event": f.events+=1
			else: f.chests+=1
		if before.first_done and not trip.is_empty():
			trip.exp_earned+=maxi(0,int(s.exp)-int(before.exp))
			trip.gold_earned+=maxi(0,int(s.gold)-int(before.gold))
			if choice.action=="round":
				trip.rounds+=1
				# Measure before level-up recovery; query the shared combat core.
				var combat:=E.Combat.advance(E.battle_state(before,data))
				trip.hp_lost_in_combat+=maxi(0,int(before.hp)-int(combat.hero.hp))
			for uid in s.items:
				if not before.items.has(uid):
					var id: String=s.items[uid]
					trip.loot[id]=int(trip.loot.get(id,0))+1
					var f: Dictionary=floors[str(s.floor)]
					f.items[id]=int(f.items.get(id,0))+1
		if s.phase=="result" and before.phase!="result":
			if s.result.kind=="story_death": story_count+=1
			else:
				trip.outcome=s.result.kind; trip.end_level=E.hero(s,cfg).level; trip.remaining_hp=s.hp
				trip.exp_end=s.exp; trip.gold_end=s.gold; trip.loss=s.result.loss.duplicate(true)
				records.append(trip)
				var f: Dictionary=floors[str(s.floor)]
				if s.result.kind=="death": f.deaths+=1
				elif s.result.kind=="return": f.returns+=1
				elif s.result.kind=="clear": f.clears+=1
				if s.result.kind=="clear" or records.size()>=int(policy.max_trips): break
		if s.phase=="town":
			var level: int=E.hero(s,cfg).level
			if level<highest_level: error="achieved level regressed"; break
			if not cfg.death_penalty.lose_inventory and s.items.size()<owned: error="permanent item loss"; break
			highest_level=level; owned=s.items.size()
	if step_count>=30000: error="action budget exhausted"
	if story_count!=1 or s.story_deaths!=1: error="tutorial must occur exactly once"
	return {"seed":seed_value,"cleared":s.phase=="result" and s.result.kind=="clear","reached_10F":reached10,"normal_trips":records.size(),"normal_deaths":E.normal_deaths(s),"story_deaths":story_count,"level":E.hero(s,cfg).level,"exp":s.exp,"gold":s.gold,"items":s.items.size(),"highest_floor":s.highest_floor,"error":error,"state_sha256":state_hash(s),"trace_sha256":digest,"trips":records,"floors":floors,"actions":actions if trace else [],"final_state":s if trace else {}}

static func run(data: Dictionary, cfg: Dictionary, policy: Dictionary, seeds: Array) -> Dictionary:
	var records: Array=[]
	var clear_trips: Array=[]
	var levels: Array=[]
	var exp_values: Array=[]
	var gold_values: Array=[]
	var loot_values: Array=[]
	var rounds: Array=[]
	var remaining: Array=[]
	var anomalies: Array=[]
	var nonclear: Array=[]
	var totals: Dictionary={"trials":seeds.size(),"normal_trips":0,"normal_deaths":0,"returns":0,"draws":0,"clears":0,"reached_10F":0,"story_deaths_excluded":0,"exp_earned":0,"gold_earned":0,"loot_earned":0}
	var floors: Dictionary={}
	for seed_value in seeds:
		var record:=play(data,cfg,policy,int(seed_value))
		records.append(record)
		totals.normal_trips+=record.normal_trips; totals.normal_deaths+=record.normal_deaths
		totals.story_deaths_excluded+=record.story_deaths; totals.reached_10F+=int(record.reached_10F)
		if record.cleared: totals.clears+=1; clear_trips.append(record.normal_trips)
		else: nonclear.append(seed_value)
		if record.error!="": anomalies.append({"seed":seed_value,"error":record.error})
		levels.append(record.level); exp_values.append(record.exp); gold_values.append(record.gold); loot_values.append(record.items)
		for trip in record.trips:
			totals.returns+=int(trip.outcome=="return"); totals.draws+=int(trip.outcome=="draw")
			totals.exp_earned+=trip.exp_earned; totals.gold_earned+=trip.gold_earned
			for count in trip.loot.values(): totals.loot_earned+=count
			rounds.append(trip.rounds); remaining.append(trip.remaining_hp)
		for key in record.floors:
			if not floors.has(key): floors[key]={"entries":0,"deaths":0,"returns":0,"clears":0,"battles":0,"chests":0,"events":0,"seed_reached":0,"enemies":{},"levels":{},"items":{}}
			var f: Dictionary=floors[key]; var rf: Dictionary=record.floors[key]
			f.seed_reached+=int(rf.entries>0)
			for field in ["entries","deaths","returns","clears","battles","chests","events"]: f[field]+=rf[field]
			for field in ["enemies","levels","items"]:
				for id in rf[field]: f[field][id]=int(f[field].get(id,0))+int(rf[field][id])
	for f in floors.values():
		f.seed_reach_rate=float(f.seed_reached)/seeds.size()
		f.death_rate_per_entry=float(f.deaths)/maxi(1,f.entries)
		f.return_rate_per_entry=float(f.returns)/maxi(1,f.entries)
	totals.clear_rate=float(totals.clears)/seeds.size(); totals.reach_10F_rate=float(totals.reached_10F)/seeds.size()
	totals.death_rate_per_normal_trip=float(totals.normal_deaths)/maxi(1,totals.normal_trips)
	totals.mean_exp_earned_per_trip=float(totals.exp_earned)/maxi(1,totals.normal_trips)
	totals.mean_gold_earned_per_trip=float(totals.gold_earned)/maxi(1,totals.normal_trips)
	totals.mean_loot_earned_per_trip=float(totals.loot_earned)/maxi(1,totals.normal_trips)
	totals.trips_to_clear=Stats.distribution(clear_trips); totals.final_level=Stats.distribution(levels)
	totals.final_exp=Stats.distribution(exp_values); totals.final_gold=Stats.distribution(gold_values); totals.final_items=Stats.distribution(loot_values)
	totals.rounds_per_trip=Stats.distribution(rounds); totals.remaining_hp_per_trip=Stats.distribution(remaining)
	totals.invalid_results=anomalies.size()
	return {"schema_version":1,"policy":policy,"seeds":seeds,"metrics":totals,"floors":floors,"anomalies":anomalies,"nonclear_seeds":nonclear,"records":records}

static func compare(before: Dictionary, after: Dictionary, strict: bool) -> Dictionary:
	before=normalized(before); after=normalized(after)
	for key in ["schema_version","policy","seeds"]:
		if before.get(key)!=after.get(key): return {"error":"Comparison conditions differ: "+key}
	for key in ["engine","runner_contract"]:
		if before.get("metadata",{}).get(key)!=after.metadata.get(key): return {"error":"Comparison environment differs: "+key}
	if not before.get("metrics") is Dictionary or not before.get("records") is Array or not before.get("floors") is Dictionary: return {"error":"Malformed baseline"}
	if strict:
		for key in ["config_sha256","data_sha256","policy_sha256","combat_sha256","expedition_sha256","policy_code_sha256"]:
			if before.metadata.get(key)!=after.metadata.get(key): return {"error":"Strict source differs: "+key}
	var equal: bool=before.metrics==after.metrics and before.records==after.records and before.floors==after.floors and before.anomalies==after.anomalies and before.nonclear_seeds==after.nonclear_seeds
	var delta: Dictionary={}
	for key in ["clear_rate","reach_10F_rate","death_rate_per_normal_trip","normal_trips","exp_earned","gold_earned","loot_earned"]:
		if not before.metrics.has(key): return {"error":"Missing baseline metric"}
		delta[key]=float(after.metrics[key])-float(before.metrics[key])
	return {"strict":strict,"strict_equal":equal,"delta":delta,"before":before.metadata,"after":after.metadata,"before_metrics":before.metrics,"after_metrics":after.metrics}

static func summary(r: Dictionary) -> String:
	var m: Dictionary=r.metrics
	return "通常探索 / %s / %d新規セーブ / 最大%d探索\n10F到達 %.2f%% / 突破 %.2f%%\n通常探索 %d回 / 通常死亡 %d回 (%.2f%%/探索) / 帰還%d / 打切り%d\n初回探索・死亡%d件は分母・分子から除外\n突破まで探索数 %s\n最終Lv %s\nEXP獲得 %.3f / Gold獲得 %.3f / 戦利品 %.3f (各通常探索平均)\n異常seed %s / 未突破seed %s\n" % [r.policy.policy_id,m.trials,r.policy.max_trips,m.reach_10F_rate*100,m.clear_rate*100,m.normal_trips,m.normal_deaths,m.death_rate_per_normal_trip*100,m.returns,m.draws,m.story_deaths_excluded,JSON.stringify(m.trips_to_clear),JSON.stringify(m.final_level),m.mean_exp_earned_per_trip,m.mean_gold_earned_per_trip,m.mean_loot_earned_per_trip,JSON.stringify(r.anomalies),JSON.stringify(r.nonclear_seeds)]
