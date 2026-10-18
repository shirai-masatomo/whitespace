extends RefCounted
## Pure campaign transitions. UI, filesystem and combat formula are outside this core.
const Combat = preload("res://core/combat.gd")
const Catalog = preload("res://core/catalog.gd")
const STATS = ["max_hp","atk","def","spd","max_sp"]
const SLOTS = ["right_hand","left_hand","head","body","legs","feet","neck","ears","eyes","finger","wrist"]

static func load_config(version: String="") -> Dictionary:
	if not version in ["","2026-10-17.loop-provisional.1","2026-10-17.loop-provisional.2","2026-10-17.loop-provisional.3","2026-10-17.loop-provisional.4"]: return {}
	var filename: String="expedition-legacy.json" if version=="2026-10-17.loop-provisional.1" else ("expedition-legacy-2.json" if version=="2026-10-17.loop-provisional.2" else ("expedition-legacy-3.json" if version=="2026-10-17.loop-provisional.3" else "expedition.json"))
	var value = JSON.parse_string(FileAccess.get_file_as_string("res://data/v1/"+filename))
	if not value is Dictionary: return {}
	var problem:=validate_config(value,Catalog.load_data())
	if problem!="": push_error(problem); return {}
	return value

static func validate_config(c: Dictionary, data: Dictionary) -> String:
	for key in ["initial","growth","death_penalty","slots","items","drops","events"]:
		if not c.get(key) is Dictionary: return "Invalid loop config: "+key
	if c.get("schema_version")!=1 or not c.get("config_version") is String or c.config_version=="": return "Invalid config version"
	if c.slots.size()!=11: return "Config must contain 11 slots"
	for slot in SLOTS:
		if not c.slots.get(slot) is String: return "Missing slot name"
	for key in STATS:
		if not integer(c.initial.get(key),0,10000) or not integer(c.growth.get(key),0,1000): return "Invalid initial/growth stat"
	if c.initial.max_hp<1 or c.initial.atk<1 or c.initial.spd<1 or not integer(c.initial.get("gold"),0,1000000): return "Invalid initial bounds"
	if not integer(c.growth.get("exp_step"),1,1000000) or not integer(c.growth.get("level_cap"),1,100): return "Invalid growth bounds"
	if not c.get("intro",c.get("tutorial",{}).get("intro")) is String: return "Invalid introduction"
	for key in ["gold_fraction","unspent_exp_fraction"]:
		if not Catalog.numeric(c.death_penalty.get(key)) or c.death_penalty[key]<0 or c.death_penalty[key]>1: return "Invalid death penalty"
	if not c.death_penalty.get("lose_inventory") is bool: return "Invalid item-loss flag"
	for id in c.items:
		var item = c.items[id]
		if not item is Dictionary or not item.get("name") is String or not item.get("slot") in SLOTS+[""] or not item.get("stats") is Dictionary: return "Invalid item definition"
		for key in item.stats:
			if not key in STATS or not integer(item.stats[key],0,10000): return "Invalid equipment stat"
	if not c.initial.get("items") is Array: return "Invalid starting items"
	for id in c.initial.items:
		if not c.items.has(id): return "Unknown starting item"
	for enemy_id in data.enemies:
		var table=drop_table(c,data,enemy_id)
		if not table is Dictionary: return "Missing drop table"
		for id in table:
			if not c.items.has(id) or not integer(table[id],0,100): return "Invalid drop"
	for key in ["chests","event_floors"]:
		if not c.get(key) is Array: return "Invalid floor detail table"
		var expected:=1
		for row in c[key]:
			if not row is Dictionary or not integer(row.get("from"),1,9) or not integer(row.get("to"),1,9) or row.from!=expected or row.to<row.from: return "Floor details must cover 1..9"
			expected=int(row.to)+1
			if key=="chests":
				if not row.get("items") is Dictionary: return "Invalid chest items"
				var total:=0
				for id in row.items:
					if not c.items.has(id) or not integer(row.items[id],0,100): return "Invalid chest item"
					total+=int(row.items[id])
				if total!=100: return "Chest weights must sum to 100"
			else:
				if not row.get("ids") is Array or row.ids.is_empty(): return "Invalid event candidates"
				for id in row.ids:
					if id=="EV03" or not c.events.has(id): return "Ineligible event"
		if expected!=10: return "Incomplete floor details"
	for id in c.events:
		var e = c.events[id]
		if not e is Dictionary or not e.get("name") is String or not e.get("choice") is String or not e.get("effect") in ["hp","exp","item"]: return "Invalid event definition"
		if e.effect=="item":
			if not c.items.has(e.get("item")): return "Unknown event item"
		elif not integer(e.get("amount"),-10000 if e.effect=="hp" else 0,10000): return "Invalid event amount"
	return ""

static func drop_table(cfg: Dictionary, data: Dictionary, enemy_id: String) -> Variant:
	# Legacy growth/item configurations retain their own old-enemy drops. New IDs
	# have one shared table in the versioned enemy pack, without rewriting old configs.
	return cfg.drops.get(enemy_id,data.get("enemy_drops",{}).get(enemy_id))

static func fresh(cfg: Dictionary, seed_value: int) -> Dictionary:
	var s := {"schema_version":3,"hero_skills":cfg.get("hero_skills",["S105"]).duplicate(),"config_version":cfg.config_version,"revision":0,"seed":seed_value,
		"rng":{"explore":0,"battle":0,"loot":0},"phase":"explore","first_done":false,"story_deaths":0,
		"floor":0,"highest_floor":0,"exp":0,"gold":int(cfg.initial.gold),"hp":int(cfg.initial.max_hp),
		"sp":int(cfg.initial.max_sp),"items":{},"inventory":[],"warehouse":[],"equipment":{},"next_item":1,
		"battle":{},"event":"","result":{},"journal":[cfg.get("intro","主人公ひとりで地下へ踏み出した。探索の解決後は町へ帰還できる。")],"trips":1,"deaths":0}
	for slot in SLOTS: s.equipment[slot] = ""
	for id in cfg.initial.items: add_item(s,id)
	return s

static func level_info(s: Dictionary, cfg: Dictionary) -> Dictionary:
	var level := 1
	var spent := 0
	while level < int(cfg.growth.level_cap) and int(s.exp) - spent >= int(cfg.growth.exp_step) * level:
		spent += int(cfg.growth.exp_step) * level
		level += 1
	return {"level":level,"spent":spent,"progress":int(s.exp)-spent,"next":int(cfg.growth.exp_step)*level}

static func normal_deaths(s: Dictionary) -> int:
	# Legacy saves store lifetime deaths, including the one introductory event.
	return int(s.deaths)-int(s.story_deaths)

static func normal_trips(s: Dictionary) -> int:
	return int(s.trips)-(1 if s.schema_version==1 else int(s.story_deaths))

static func hero(s: Dictionary, cfg: Dictionary) -> Dictionary:
	var level: int = level_info(s,cfg).level
	var h := {"name":"主人公","level":level,"hp":int(s.hp),"sp":int(s.sp),"skills":s.get("hero_skills",[]) if s.schema_version>=3 else []}
	for key in STATS: h[key] = int(cfg.initial[key]) + (level-1)*int(cfg.growth[key])
	for uid in s.equipment.values():
		if uid == "": continue
		for key in cfg.items[s.items[uid]].stats: h[key] += int(cfg.items[s.items[uid]].stats[key])
	return Combat.normalized(h)

static func note(s: Dictionary, value: String) -> void:
	s.journal.append(value)
	if s.journal.size() > 24: s.journal.pop_front()

static func add_item(s: Dictionary, id: String) -> String:
	var uid := "item-%d" % int(s.next_item)
	s.next_item += 1
	s.items[uid] = id
	s.inventory.append(uid)
	return uid

static func draw(s: Dictionary, domain: String, maximum: int) -> int:
	var offsets := {"explore":101,"battle":307,"loot":503}
	var rng := RandomNumberGenerator.new()
	# Persist small integer seeds/counters, never JSON-round a 64-bit RNG state.
	rng.seed = (int(s.seed) + int(s.rng[domain])*1103515245 + offsets[domain]) % 2147483647
	s.rng[domain] += 1
	return rng.randi_range(0,maximum-1)

static func weighted(s: Dictionary, domain: String, weights: Dictionary) -> String:
	var total := 0
	var keys := weights.keys()
	keys.sort()
	for key in keys: total += int(weights[key])
	var roll := draw(s,domain,total)
	for key in keys:
		roll -= int(weights[key])
		if roll < 0: return key
	return ""

static func floor_row(rows: Array, floor_number: int) -> Dictionary:
	for row in rows:
		if floor_number >= row.from and floor_number <= row.to: return row
	return {}

static func gain_exp(s: Dictionary, amount: int, cfg: Dictionary) -> void:
	var before := hero(s,cfg)
	s.exp += amount
	var after := hero(s,cfg)
	# Keep the missing HP/SP on level-up; only town provides full recovery.
	s.hp += after.max_hp - before.max_hp
	s.sp += after.max_sp - before.max_sp
	if after.level > before.level: note(s,"Lv.%d に成長した。" % after.level)

static func finish(s: Dictionary, kind: String, reason: String, cfg: Dictionary) -> void:
	var loss := {"gold":0,"exp":0,"items":0}
	if kind=="story_death": return # Legacy history is read-only; never create a new forced death.
	if kind=="death":
		s.hp=0
		s.deaths+=1
		loss.gold = floori(s.gold * cfg.death_penalty.gold_fraction)
		loss.exp = floori(level_info(s,cfg).progress * cfg.death_penalty.unspent_exp_fraction)
		s.gold -= loss.gold
		s.exp -= loss.exp
		if cfg.death_penalty.lose_inventory:
			loss.items = s.inventory.size()
			for uid in s.inventory: s.items.erase(uid)
			s.inventory.clear()
	s.result = {"kind":kind,"reason":reason,"floor":int(s.floor),"loss":loss}
	s.phase = "result"
	s.battle = {}
	s.event = ""
	note(s,reason)

static func battle_state(s: Dictionary, data: Dictionary) -> Dictionary:
	if s.battle.is_empty(): return {}
	var b: Dictionary = s.battle
	var foe:=Combat.enemy(data,b.enemy_id,int(b.enemy_level))
	var rules: Dictionary=data.rules.duplicate(true)
	if b.get("rules_version",1)<3:
		foe.skills=[]
		rules.status_pilot=false
	var result := Combat.start(b.hero,foe,rules,int(b.seed))
	for i in int(b.rounds): result = Combat.advance(result)
	return result

static func step_battle(s: Dictionary, data: Dictionary, cfg: Dictionary) -> void:
	var previous := battle_state(s,data)
	var b := Combat.advance(previous)
	s.battle.rounds += 1
	s.hp = int(b.hero.hp)
	s.sp = int(b.hero.sp)
	for entry in b.log.slice(previous.log.size()):
		var who: String="主人公" if entry.get("actor","")=="hero" else b.enemy.name
		var statuses: Dictionary={"poison":"毒","blind":"暗闇","paralysis":"麻痺","defense":"防御"}
		if entry.type == "skill":
			var skill: Dictionary=data.rules.skills[entry.skill]
			note(s,"%s：%s  SP -%d" % [who,skill.get("name","防御"),int(skill.sp_cost)])
		elif entry.type == "status_applied":
			note(s,"%s：%s%s（残り%d行動機会）" % ["主人公" if entry.target=="hero" else b.enemy.name,statuses[entry.status],"を更新" if entry.reapplied else "を付与",entry.remaining])
		elif entry.type == "status_damage": note(s,"%s：毒 %d ダメージ%s" % [who,entry.damage," / HP0" if entry.death else ""])
		elif entry.type == "action_skipped": note(s,who+"：麻痺で行動できない。")
		elif entry.type == "status_removed":
			note(s,"%s：%s解除（%s）。" % [who,statuses.get(entry.get("status","defense"),"状態"),{"expired":"持続終了","death":"死亡","battle_end":"戦闘終了"}.get(entry.reason,entry.reason)])
		elif entry.type == "attack":
			note(s,"%s → %s  %s" % [who,b.enemy.name if entry.target=="enemy" else "主人公",str(entry.damage)+" ダメージ" if entry.hit else "MISS / ミス"])
	if b.outcome == "victory":
		s.last_outcome="victory"
		gain_exp(s,int(b.reward.exp),cfg)
		s.gold += int(b.reward.gold)
		note(s,"勝利  EXP +%d / Gold +%d" % [b.reward.exp,b.reward.gold])
		var drops: Dictionary=drop_table(cfg,data,b.enemy.id)
		for id in drops:
			if draw(s,"loot",100) < drops[id]:
				add_item(s,id)
				note(s,"入手："+cfg.items[id].name)
		s.phase = "explore"
		s.battle = {}
		if int(s.floor)==10:
			s.highest_floor = 11
			finish(s,"clear","10Fの門番を倒した。11Fへの到達を記録し、町へ帰還する。",cfg)
	elif b.outcome == "defeat": finish(s,"death",str(b.enemy.name)+"との戦闘で力尽きた。",cfg)
	elif b.outcome == "draw": finish(s,"draw","50ラウンドで戦闘を打ち切り、探索を中断した。",cfg)

static func descend(s: Dictionary, data: Dictionary, cfg: Dictionary) -> void:
	s.last_outcome=""
	s.floor += 1
	s.highest_floor = maxi(int(s.floor),int(s.highest_floor))
	var row := floor_row(data.floors,int(s.floor))
	var roll := draw(s,"explore",100)
	if roll < row.encounters[0]:
		var id := weighted(s,"explore",row.enemies)
		var level := int(row.levels[0]) + draw(s,"explore",int(row.levels[1]-row.levels[0])+1)
		s.battle = {"enemy_id":id,"enemy_level":level,"seed":draw(s,"battle",2147483647),"hero":hero(s,cfg),"rounds":0,"rules_version":3,"encounter_version":2}
		s.phase = "battle"
		note(s,"地下%dF：%s Lv.%d が現れた。" % [s.floor,data.enemies[id].name,level])
	elif roll < row.encounters[0]+row.encounters[1]:
		var id := weighted(s,"loot",floor_row(cfg.chests,int(s.floor)).items)
		add_item(s,id)
		note(s,"地下%dFの宝箱：%s を手に入れた。" % [s.floor,cfg.items[id].name])
	else:
		var candidates: Array = floor_row(cfg.event_floors,int(s.floor)).ids
		s.event = candidates[draw(s,"explore",candidates.size())]
		s.phase = "event"
		note(s,"地下%dF：%s" % [s.floor,cfg.events[s.event].name])

static func act(previous: Dictionary, action: String, expected_revision: int, args: Dictionary, data: Dictionary, cfg: Dictionary) -> Dictionary:
	# A queued old UI callback cannot repeat rewards, movement, or inventory operations.
	if int(previous.revision) != expected_revision: return previous
	var s := previous.duplicate(true)
	var changed := false
	match action:
		"descend":
			if s.phase=="explore" and s.floor<10:
				descend(s,data,cfg); changed=true
		"round":
			if s.phase=="battle": step_battle(s,data,cfg); changed=true
		"return":
			if s.phase=="explore":
				finish(s,"return","持ち帰った品を抱え、町への道を戻った。",cfg); changed=true
		"event":
			if s.phase=="event" and args.get("choice","") in ["accept","skip"]:
				var event: Dictionary = cfg.events[s.event]
				if args.choice == "accept":
					match event.effect:
						"hp": s.hp = clampi(int(s.hp)+int(event.amount),0,hero(s,cfg).max_hp)
						"exp": gain_exp(s,int(event.amount),cfg)
						"item": add_item(s,event.item)
				note(s,event.choice+"。" if args.choice=="accept" else "先を急いだ。")
				s.event=""; s.phase="explore"; changed=true
				if s.hp==0: finish(s,"death","崩れた足場で力尽きた。",cfg)
		"town":
			if s.phase=="result":
				s.phase="town"; s.floor=0
				var h := hero(s,cfg)
				s.hp=h.max_hp; s.sp=h.max_sp; changed=true
		"depart":
			if s.phase=="town":
				s.last_outcome=""
				s.phase="explore"; s.floor=0; s.result={}; s.journal=[]; s.trips+=1
				note(s,"町でHP/SPを回復し、地下へ向かった。"); changed=true
		"deposit","withdraw","equip","unequip":
			if s.phase=="town":
				var uid: String = args.get("uid","")
				if action=="deposit" and uid in s.inventory:
					s.inventory.erase(uid); s.warehouse.append(uid); changed=true
				elif action=="withdraw" and uid in s.warehouse:
					s.warehouse.erase(uid); s.inventory.append(uid); changed=true
				elif action=="equip" and uid in s.inventory:
					var slot: String = cfg.items[s.items[uid]].slot
					if slot in SLOTS:
						if s.equipment[slot] != "": s.inventory.append(s.equipment[slot])
						s.inventory.erase(uid); s.equipment[slot]=uid; changed=true
				elif action=="unequip":
					var slot: String = args.get("slot","")
					if slot in SLOTS and s.equipment[slot] != "":
						s.inventory.append(s.equipment[slot]); s.equipment[slot]=""; changed=true
				if changed:
					var h := hero(s,cfg)
					s.hp=h.max_hp; s.sp=h.max_sp
	if changed: s.revision += 1
	return s if changed else previous

static func integer(v: Variant, low: int, high: int) -> bool:
	return Catalog.numeric(v) and v==floorf(v) and v>=low and v<=high

static func validate(s: Dictionary, data: Dictionary, cfg: Dictionary) -> String:
	for key in ["schema_version","config_version","revision","seed","rng","phase","first_done","story_deaths","floor","highest_floor","exp","gold","hp","sp","items","inventory","warehouse","equipment","next_item","battle","event","result","journal","trips","deaths"]:
		if not s.has(key): return "Missing save field: "+key
	if (s.schema_version!=1 and s.schema_version!=2 and s.schema_version!=3) or s.config_version!=cfg.config_version: return "Unsupported save/config version"
	if s.schema_version==3 and (not s.get("hero_skills") is Array or s.hero_skills!=cfg.get("hero_skills",["S105"])): return "Invalid initial skill ownership"
	for key in ["revision","seed","story_deaths","floor","highest_floor","exp","gold","hp","sp","next_item","trips","deaths"]:
		if not integer(s[key],0,2147483647): return "Invalid number: "+key
	if not s.first_done is bool or s.story_deaths>1 or s.first_done!=(s.story_deaths==1): return "Invalid legacy history flags"
	if s.deaths<s.story_deaths or normal_deaths(s)>normal_trips(s): return "Invalid death counters"
	if s.floor>10 or s.highest_floor>11 or s.floor>s.highest_floor or s.next_item<1 or s.trips<1: return "Invalid progression"
	if not s.phase in ["explore","battle","event","result","town"]: return "Unknown phase"
	if not s.get("last_outcome","") in ["","victory"]: return "Invalid encounter outcome"
	for key in ["rng","items","equipment","battle","result"]:
		if not s[key] is Dictionary: return "Invalid dictionary: "+key
	for key in ["inventory","warehouse","journal"]:
		if not s[key] is Array: return "Invalid array: "+key
	if s.journal.size()>24 or not s.event is String: return "Invalid journal/event"
	for line in s.journal:
		if not line is String or line.length()>1000: return "Invalid journal entry"
	for domain in ["explore","battle","loot"]:
		if not integer(s.rng.get(domain),0,10000000): return "Invalid RNG counter"
	if s.equipment.size()!=11: return "Equipment must contain 11 slots"
	var owned: Array = s.inventory.duplicate()
	owned.append_array(s.warehouse)
	for slot in SLOTS:
		if not s.equipment.has(slot) or not s.equipment[slot] is String: return "Missing slot"
		var uid: String = s.equipment[slot]
		if uid!="":
			if not s.items.has(uid) or not cfg.items.has(s.items[uid]) or cfg.items[s.items[uid]].slot!=slot: return "Wrong equipment slot"
			owned.append(uid)
	var seen := {}
	for uid in owned:
		if not uid is String or seen.has(uid) or not s.items.has(uid): return "Duplicate/missing item ownership"
		seen[uid]=true
		if not uid.begins_with("item-") or not uid.trim_prefix("item-").is_valid_int(): return "Invalid item instance ID"
		if uid!="item-%d" % int(uid.trim_prefix("item-")): return "Noncanonical item instance ID"
		if int(uid.trim_prefix("item-"))<1 or int(uid.trim_prefix("item-"))>=s.next_item: return "Invalid next item ID"
		if not s.items[uid] is String or not cfg.items.has(s.items[uid]): return "Unknown item ID"
	if seen.size()!=s.items.size(): return "Orphaned item"
	var h := hero(s,cfg)
	if s.hp>h.max_hp or s.sp>h.max_sp: return "HP/SP out of range"
	if s.phase!="result" and s.hp==0: return "Dead hero outside result"
	if s.phase=="town" and (s.floor!=0 or s.hp!=h.max_hp or s.sp!=h.max_sp): return "Invalid town"
	if s.phase=="event":
		if not cfg.events.has(s.event) or s.floor<1 or s.floor>9: return "Invalid event"
	elif s.event!="": return "Event outside event phase"
	if s.phase=="battle":
		var b: Dictionary=s.battle
		if s.floor<1: return "Invalid battle phase"
		for key in ["enemy_id","enemy_level","seed","hero","rounds"]:
			if not b.has(key): return "Missing battle field"
		if not b.enemy_id is String or not data.enemies.has(b.enemy_id) or not integer(b.enemy_level,1,100) or not integer(b.seed,0,2147483647) or not integer(b.rounds,0,49) or not b.hero is Dictionary: return "Invalid battle input"
		if Catalog.validate_hero(b.hero)!="": return "Invalid battle hero"
		if not integer(b.get("rules_version",1),1,3): return "Unknown combat rules version"
		if b.get("rules_version",1)>=2 and b.hero.get("skills",[])!=h.skills: return "Invalid battle skill ownership"
		if b.get("rules_version",1)==1 and not b.hero.get("skills",[]).is_empty(): return "Legacy battle must remain skill-free"
		for key in STATS+["level"]:
			if b.hero[key]!=h[key]: return "Battle effective stats differ from campaign"
		if b.get("encounter_version",1)!=1 and b.get("encounter_version",1)!=2: return "Unknown encounter version"
		# Existing checkpoints are validated against the table that created them.
		# All newly drawn encounters use v2, including after a legacy save resumes.
		var table: Array=data.get("legacy_floors",data.floors) if b.get("encounter_version",1)==1 else data.floors
		var row:=floor_row(table,int(s.floor))
		if not row.enemies.has(b.enemy_id) or b.enemy_level<row.levels[0] or b.enemy_level>row.levels[1]: return "Battle enemy outside floor table"
		var combat := battle_state(s,data)
		if combat.outcome!="ongoing" or combat.hero.hp!=s.hp or combat.hero.sp!=s.sp: return "Inconsistent battle checkpoint"
	elif not s.battle.is_empty(): return "Battle outside battle phase"
	if s.phase=="result":
		if not s.result.has_all(["kind","reason","floor","loss"]) or not s.result.reason is String or not s.result.kind in ["story_death","death","return","draw","clear"]: return "Invalid result"
		if s.result.floor!=s.floor or not s.result.loss is Dictionary: return "Invalid result fields"
		for key in ["gold","exp","items"]:
			if not integer(s.result.loss.get(key),0,2147483647): return "Invalid result loss"
		if s.result.kind in ["story_death","death"] and s.hp!=0: return "Death result with positive HP"
	if s.schema_version==1 and not s.first_done and (s.phase!="explore" or s.floor>=cfg.get("tutorial",{}).get("death_floor",2)): return "Invalid legacy introduction"
	if s.phase=="result" and s.result.kind=="story_death" and s.story_deaths!=1: return "Invalid legacy death history"
	return ""

static func migrate(s: Dictionary) -> Dictionary:
	# Called only after validating the old schema/config. Preserve possessions and counters.
	if s.schema_version==3: return s
	var migrated:=s.duplicate(true)
	migrated.schema_version=3
	migrated.hero_skills=["S105"]
	note(migrated,"旧セーブを保全して防御を習得。戦闘途中の場合は次の戦闘から使用する。")
	if migrated.phase=="result" and migrated.result.kind=="story_death":
		migrated.result.reason="旧版で記録された導入イベントの結果です。町へ戻り、通常探索を続けられます。"
	return migrated
