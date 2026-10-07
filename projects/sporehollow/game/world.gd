extends RefCounted
const Content=preload("res://game/ranch_content.gd")
## Deterministic fixed-tick rules. No scene, Input, frame clock or rendering dependencies.
const Combat=preload("res://game/combat_events.gd")
const Progression = preload("res://game/progression.gd")
const ProgressData = preload("res://game/progression_data.gd")
const Story = preload("res://game/world_story_system.gd")
var story: Dictionary = {}
var trees: Dictionary = {}
const logistics_entry = Vector2i(1,5)
const RaiderAI = preload("res://game/raider_ai.gd")
const Decisions = preload("res://game/decision_ai.gd")
const StageData = preload("res://game/stages.gd")
const W = 25
const H = 17
const DT = 0.25
const NEST = Vector2i(20, 12)
const Shop = preload("res://game/shop_table.gd")
const Rules = preload("res://game/rules.gd")
const BUILD = Rules.BUILD
const ORDERS = ["auto", "stay", "wander", "rest", "attack_target", "guide", "charge"]
const Buildings = preload("res://game/buildings.gd")
const Orders = preload("res://game/animal_orders.gd")
var floors: Dictionary = {}
var indoor: Dictionary = {}
var debug_enabled = false
var debug_infinite = false
var campaign: Dictionary
var checkpoint: Dictionary
var stage = 1
var seed_value = 1
var rng = RandomNumberGenerator.new()
var tick = 0
var phase = "shop"
const Life = preload("res://game/keeper_life.gd")
var jobs_held = false
var job_hold_reason = ""
var manual_goal = null
var life_log: Array = []
var danger_serial = 0
const Jobs = preload("res://game/keeper_jobs.gd")
var jobs: Array = []
var next_job_id = 1
var job_log: Array = []
var keeper_path: Array = []
var night_started_tick = 0
var day_seconds = 90.0
var early_clear = false
var early_clear_tick = -1
var early_finish_bonus = 0
var rest_skip: Dictionary = {}
var dawn_summary: Dictionary = {}
var field_items: Array = []
var daily_rng = RandomNumberGenerator.new()
const AnimalData = preload("res://game/animal_data.gd")
const SPECIES = AnimalData.SPECIES
var sight_log: Array = []
var morning_checkpoint: Dictionary
var result = ""
var paused = false
var command_power = 10.0
var materials = 100 # Compatibility alias for soil; all costs carry an explicit ResourceType.
var wood = 0
var stone = 0
var shop_stock: Array = []
var shop_log: Array = []
var nature_config: Dictionary
var next_structure_id = 1
var combat_log: Array = []
var decision_log: Array = []
var decision_count = 0
var decision_counts: Dictionary = {}
var actor_rngs: Dictionary = {}
var nature_rng = RandomNumberGenerator.new()
var natural: Dictionary = {}
var skill_log: Array = []
var milestones: Array = []
var initial_positions: Dictionary = {}
var structures: Dictionary = {}
const HOLDING_SHED = Vector2i(21, 14) # Legacy coordinate only; no building or reserved cells.
var keeper = {"pos": Vector2i(6, 13), "placed": false, "carrier": -1, "state": "free", "restrainer": -1, "move_credit": 0.0, "hp": 30, "max_hp": 30, "sleepiness": 0.0, "resting": false, "forced_rest": false, "warned": 0, "heal_credit": 0.0, "recover_ticks": 0, "next_attack": 0, "hurt_until": 0, "drinks_today": 0}
var animals: Array = []
var enemies: Array = []
var foods: Array = []
var actions: Array = []
var traces: Array = []
var events: Array = []
var spawned = 0
var eggs = 0
var nest = NEST
var score: Dictionary = {}
var config: Dictionary
const PlayerEvents=preload("res://game/player_events.gd")
var player_events: Array = []
var last_keeper_attacker_id=-1
var rescue_until=0
var spawn_schedule: Array = []
var schedule_index = 0
var schedule_cycle = 0
var entries: Array = []
var metrics = {"repelled": 0, "stolen": 0, "structure_damage": 0, "commands": 0.0,
	"eggs_produced": 0, "eggs_collected": 0, "barks": 0, "fed": 0, "coins": 0,
	"captures": 0, "rescues": 0, "built": 0, "destroyed": 0, "orders": 0, "interrupted": 0, "repaired": 0, "soil_repair": 0,
	"bark_casts": 0, "bark_targets": 0, "weed_spawned": 0, "mushroom_spawned": 0, "weed_collected": 0, "mushroom_collected": 0, "stump_spawned": 0, "stump_collected": 0, "nature_rolls": 0, "mushrooms_used": 0, "mushroom_healing": 0}

static func new_campaign() -> Dictionary:
	return {"stage": 1, "day": 1, "exp_pool": 0, "night_ready": false, "gold": 40, "field_items": [], "eggs": 0, "mushrooms": 0, "shelter": false,
		"fence": 0, "resources": {"soil": 100, "wood": 0, "stone": 0}, "items": {"dog_food": 2, "hen_food": 0}, "unlocked_blueprints": [], "facilities": [], "next_structure_id": 1, "animals": [{"id": 1, "category": "dog", "species": "shiba", "lv": 1, "xp": 0, "loyalty": 75}]}

func _init(data: Dictionary = {}, seed_number: int = 17, stage_override: Dictionary = {}):
	Combat.init_actor(keeper,true)
	campaign = new_campaign() if data.is_empty() else data.duplicate(true)
	for resource in Rules.RESOURCE_TYPES:
		if not campaign.resources.has(resource): campaign.resources[resource] = 0
	campaign.items = campaign.get("items", {"dog_food": 2, "hen_food": 0})
	campaign.unlocked_blueprints = campaign.get("unlocked_blueprints", [])
	campaign.blueprint_records=campaign.get("blueprint_records",[])
	for id in campaign.unlocked_blueprints:
		if id not in campaign.blueprint_records: campaign.blueprint_records.append(id)
	for id in Buildings.NAMES:
		var key=id+"_plan"
		if campaign.items.get(key,0)>0:
			if id not in campaign.blueprint_records: campaign.blueprint_records.append(id)
			if id not in campaign.unlocked_blueprints: campaign.unlocked_blueprints.append(id)
			campaign.items.erase(key)
	campaign.day = campaign.get("day", 1)
	campaign.exp_pool = campaign.get("exp_pool", 0)
	campaign.night_ready = campaign.get("night_ready", false)
	campaign.field_items = campaign.get("field_items", [])
	Progression.migrate(self)
	for owned in campaign.animals:
		owned.name = owned.get("name", "")
		owned.object_attack_power = owned.get("object_attack_power", 0)
		owned.affinity = owned.get("affinity", 0 if SPECIES[owned.species].affinity else null)
		owned.unavailable_through_day = owned.get("unavailable_through_day", 0)
		if owned.species=="shiba" and owned.get("hp", 1) <= 0 and campaign.day > owned.unavailable_through_day:
			owned.hp = maxi(1, AnimalData.stats(owned.species,owned.lv).hp / 2) # Provisional return after one full day off.
	morning_checkpoint = campaign.get("morning_checkpoint", campaign).duplicate(true)
	morning_checkpoint.erase("morning_checkpoint")
	for key in ["hp", "sleepiness", "drinks_today","facing","stamina","ultimate_gauge"]:
		keeper[key] = campaign.get("keeper_vitals", {}).get(key, keeper.get(key,1))
	keeper.state=campaign.get("keeper_vitals",{}).get("recovery_state","unconscious" if keeper.hp<=0 else "free")
	if keeper.state in ["unconscious","hidden_rest"]:
		keeper.heal_credit=campaign.keeper_vitals.get("heal_credit",0.0)
		keeper.recover_ticks=campaign.keeper_vitals.get("recover_ticks",0)
		Jobs.hold(self,"rescue")
	if keeper.sleepiness >= 100:
		keeper.forced_rest = true
		keeper.resting = true
		keeper.rest_kind="forced"
	checkpoint = campaign.duplicate(true)
	phase = "day" if campaign.night_ready else "shop"
	stage = campaign.stage
	seed_value = seed_number
	rng.seed = seed_number
	nature_rng.seed = seed_number * 1009 + 9871
	daily_rng.seed = seed_number * 727 + campaign.day * 1597
	for item in campaign.field_items:
		var row = item.duplicate(true)
		row.pos = Vector2i(item.pos[0], item.pos[1])
		field_items.append(row)
	campaign.mushrooms = campaign.get("mushrooms", 0)
	config = (Progression.Encounters.plan(campaign.day,seed_number,campaign.get("world_story",{}).get("hidden",{}).get("karma",0),stage,[],campaign.encounter_counts) if stage_override.is_empty() else stage_override).duplicate(true)
	materials = campaign.resources.soil
	wood = campaign.resources.wood
	stone = campaign.resources.stone
	day_seconds = config.get("day_seconds", 90.0)
	nature_config = config.get("nature", Rules.NATURE).duplicate(true)
	next_structure_id = campaign.get("next_structure_id", 1)
	campaign.retired_facilities=campaign.get("retired_facilities",[])
	for saved in campaign.get("facilities", []):
		var record = saved.duplicate(true)
		var cell = Vector2i(record.pos[0], record.pos[1])
		record.erase("pos")
		if record.kind == "gate": record.kind = "door"
		if record.kind in ["kennel","coop"]:
			if not campaign.retired_facilities.any(func(b):return b.id==record.id): campaign.retired_facilities.append(saved.duplicate(true))
			if record.status=="building" and not record.get("migration_refunded",false) and not campaign.get("work_jobs",[]).any(func(j):return j.pos==saved.pos and j.kind==record.kind):
				add_resource(record.get("resource","wood"),record.get("cost",0))
				saved.migration_refunded=true
			record.status="disabled"
			saved.status="disabled"
		structures[cell] = record
	entries = Story.entries(self)
	# A newly bought hen must not spawn inside a facility retained from the previous day.
	if has_nest() and (blocks(nest) or live_structure(nest)):
		var clear_cells = []
		for y in range(1, H - 1):
			for x in range(1, W - 1):
				var p = Vector2i(x, y)
				if walkable(p) and not live_structure(p) and p not in entries: clear_cells.append(p)
		clear_cells.sort_custom(func(a, b): return distance(a, NEST) < distance(b, NEST))
		if not clear_cells.is_empty(): nest = clear_cells[0]
	for saved in campaign.get("floors",[]):
		var row=saved.duplicate(true)
		var cell=Vector2i(row.pos[0],row.pos[1]); row.erase("pos")
		floors[cell]=row
	refresh_indoor()
	keeper.placed=true
	var location=campaign.get("keeper_position",[6,13])
	keeper.pos=Vector2i(location[0],location[1])
	for owned in campaign.animals: add_resident(owned)
	if phase == "day":
		keeper.placed = true
		var saved_pos = campaign.get("keeper_position", [6, 13])
		keeper.pos = Vector2i(saved_pos[0], saved_pos[1])
		if not walkable(keeper.pos):
			for y in range(1, H - 1):
				for x in range(1, W - 1):
					if walkable(Vector2i(x, y)): keeper.pos = Vector2i(x, y)
		initial_positions = {"keeper": [keeper.pos.x, keeper.pos.y], "animals": []}
		keeper_path = [[keeper.pos.x, keeper.pos.y]]
	for saved in campaign.get("work_jobs",[]):
		var j=saved.duplicate(true); j.pos=Vector2i(j.pos[0],j.pos[1])
		if j.kind=="build_gate": j.kind="door"
		if j.kind in ["kennel","coop"]:
			add_resource(j.get("resource","wood"),j.get("reserved",0))
			continue
		jobs.append(j); next_job_id=maxi(next_job_id,j.id+1)
	campaign.work_jobs=campaign.get("work_jobs",[]).filter(func(j):return j.kind not in ["kennel","coop"])
	# Migrate paid unfinished legacy construction that predates persisted job records.
	for p in structures:
		var b=structures[p]
		if b.kind not in ["kennel","coop"] and b.status=="building" and not jobs.any(func(j):return j.pos==p):
			jobs.append({"id":next_job_id,"kind":b.kind,"pos":p,"animal_id":-1,"state":"pending","resource":b.get("resource","soil"),"reserved":b.cost,"started":true,"old":{},"remaining":b.remaining})
			next_job_id+=1
	Story.init(self)
	refresh_indoor()
	make_schedule()
	# The morning snapshot includes migrated terrain and one-time morning events.
	if not campaign.night_ready:
		morning_checkpoint=campaign.duplicate(true)
		morning_checkpoint.erase("morning_checkpoint")
	shop_stock = Shop.generate(stage, seed_value, campaign.unlocked_blueprints, campaign.day)
	say("牧場を整えよう")

func make_schedule():
	# Each wave has a start time relative to the first attack. Jitter affects gaps, never prep length.
	spawn_schedule.clear()
	schedule_index = 0
	for i in range(config.waves.size()):
		var wave = config.waves[i]
		var seconds: float = config.first_attack_seconds + wave.start_seconds + schedule_cycle * config.repeat_interval_seconds
		for j in range(wave.count):
			if j > 0: seconds += maxf(DT, wave.interval_seconds + rng.randf_range(-wave.jitter_seconds, wave.jitter_seconds))
			var cell = wave.entries[j % wave.entries.size()]
			spawn_schedule.append({"tick": ceili(seconds / DT), "wave": i + 1, "role": wave.role,
				"entry": Vector2i(cell[0], cell[1]), "lv": wave.get("lv", 1)})
			for key in ["move_speed", "sight_range"]:
				if wave.has(key): spawn_schedule.back()[key] = wave[key]
	Story.schedule(self)

func next_attack_seconds() -> float:
	if phase == "day": return maxf(0, day_seconds - tick * DT) + config.first_attack_seconds
	return maxf(0, (spawn_schedule[schedule_index].tick - (tick - night_started_tick)) * DT) if schedule_index < spawn_schedule.size() else -1.0

func say(message: String):
	events.append({"tick": tick, "text": message})
	if events.size() > 5: events.pop_front()

func inside(p: Vector2i) -> bool:
	return p.x >= 1 and p.x < W - 1 and p.y >= 1 and p.y < H - 1

func walkable(p: Vector2i) -> bool:
	return inside(p) and not Story.terrain_block(self,p) and (not blocks(p) or (structures.get(p,{}).get("kind") in Buildings.DOORS))

func blocks(p: Vector2i) -> bool:
	return structures.has(p) and structures[p].status == "ready" and structures[p].kind not in ["kennel", "coop"] and not structures[p].open

func live_structure(p: Vector2i) -> bool:
	return structures.has(p) and structures[p].status in ["ready", "building"]

func occupied(p: Vector2i) -> bool:
	return (keeper.placed and p == keeper.pos) or animals.any(func(a): return a.placed and a.pos == p) or enemies.any(func(e): return not e.done and e.pos == p) or foods.any(func(f): return f.pos == p)

func has_nest() -> bool:
	return campaign.animals.any(func(a): return a.species == "hen")

func can_build(kind: String, p: Vector2i) -> bool:
	return working() and Buildings.reason(self,kind,p)==""

func neighbors(p: Vector2i) -> Array:
	return [p + Vector2i.RIGHT, p + Vector2i.LEFT, p + Vector2i.UP, p + Vector2i.DOWN]

func exit_for(entry: Vector2i) -> Vector2i:
	# Configured entrance determines the return edge, not a fixed left-hand exit.
	var exits = [Vector2i(0, entry.y), Vector2i(W - 1, entry.y), Vector2i(entry.x, 0), Vector2i(entry.x, H - 1)]
	exits.sort_custom(func(a, b): return distance(entry, a) < distance(entry, b))
	return exits[0]

func actor_occupied(p: Vector2i, origin: Vector2i) -> bool:
	if p == origin: return false
	return (keeper.placed and keeper.pos == p) or animals.any(func(a): return a.placed and a.pos == p) or enemies.any(func(e): return not e.done and e.pos == p)

func next_step(start: Vector2i, goal: Vector2i, raider: bool = false, avoid_actors: bool = false) -> Vector2i:
	var path = find_path(start,goal,raider,avoid_actors)
	return path[1] if path.size()>1 else start

func find_path(start: Vector2i, goal: Vector2i, raider: bool = false, avoid_actors: bool = false, outdoor_only: bool = false) -> Array:
	if start == goal: return [start]
	var frontier = [start]
	var cost = {start: 0.0}
	var previous = {start: start}
	while not frontier.is_empty():
		var best = 0
		for i in range(1, frontier.size()):
			if cost[frontier[i]] + distance(frontier[i], goal) < cost[frontier[best]] + distance(frontier[best], goal): best = i
		var p: Vector2i = frontier.pop_at(best)
		if p == goal:
			var path=[p]
			while p != start:
				p=previous[p]
				path.push_front(p)
			return path
		for n in neighbors(p):
			var exit_cell = raider and n == goal and entries.any(func(entry): return exit_for(entry) == n)
			if not inside(n) and not exit_cell: continue
			if Story.terrain_block(self,n): continue
			if outdoor_only and is_indoor(n): continue
			if avoid_actors and n != goal and actor_occupied(n, start): continue
			var blocked = blocks(n)
			if blocked and not raider and structures.get(n,{}).get("kind") not in Buildings.DOORS: continue
			# Compare walking actions with the actual number of object attacks needed.
			var value: float = cost[p] + 1.0 + (ceilf(float(structures[n].hp) / Rules.KIDNAPPER.object_attack_power) if blocked else 0)
			if not cost.has(n) or value < cost[n]:
				cost[n] = value
				previous[n] = p
				if n not in frontier: frontier.append(n)
	return []

static func distance(a: Vector2i, b: Vector2i) -> int:
	return absi(a.x - b.x) + absi(a.y - b.y)

func working() -> bool:
	return phase in ["day", "defend"]

func start_night():
	if phase != "day": return
	for event in spawn_schedule:
		if event.get("wave",0)==999:event.tick=maxi(0,event.tick-(tick-night_started_tick))
	spawn_schedule.sort_custom(func(a,b):return a.tick<b.tick)
	phase = "defend"
	night_started_tick = tick
	milestones.append({"tick": tick, "kind": "nightfall"})

func act(kind: String, p: Vector2i = Vector2i.ZERO, animal_id: int = -1) -> bool:
	var accepted = false
	if kind in ["milk","place_kokeshi","place_fossil"]:
		accepted=Content.queue(self,kind,p,animal_id)
	elif kind in Story.ACTIONS:
		accepted = Story.enqueue(self,kind,p)
	elif kind in ["rest_until_night", "end_night"]:
		accepted = Life.plan_rest_until(self, "night" if kind == "rest_until_night" else "dawn")
	elif kind == "cancel_rest_until":
		accepted = not rest_skip.is_empty()
		Life.stop_rest_until(self, "cancelled")
	elif kind in ["keeper_move", "keeper_rest", "resume_jobs", "coffee", "energy_drink"]:
		accepted = Life.command(self, kind, p)
	elif kind in ORDERS:
		accepted = Orders.enqueue(self,kind,[animal_id],p)
	elif kind == "pause":
		accepted = _execute_local(kind, p, animal_id)
	elif kind == "cancel_job" and working():
		accepted = Jobs.cancel(self, animal_id)

	else:
		accepted = Jobs.enqueue(self, kind, p, animal_id)
	actions.append({"tick": tick, "kind": kind, "pos": [p.x, p.y], "accepted": accepted, "paused": paused, "animal_id": animal_id})
	return accepted

func _execute_local(kind: String, p: Vector2i = Vector2i.ZERO, animal_id: int = -1) -> bool:
	var accepted = false
	if working():
		if kind == "pause":
			paused = not paused
			accepted = true
		elif kind in ORDERS:
			accepted = issue_order(kind, p, animal_id)
		elif not paused:
			if kind == "gate" and live_structure(p) and structures[p].status == "ready" and structures[p].kind in Buildings.DOORS and not occupied(p):
				structures[p].open = not structures[p].open
				accepted = true
			elif kind in ["repair","repair_floor"]:
				accepted = repair(p,"floor" if kind=="repair_floor" else "structure")
			elif kind in ["remove","remove_floor"] and not occupied(p):
				var target_layer="floor" if kind=="remove_floor" else "structure"
				var store=building_store(target_layer)
				if store.get(p,{}).get("status")!="ready" or (target_layer=="floor" and live_structure(p)): return false
				add_resource(store[p].get("resource","soil"),dismantle_quote(p,target_layer))
				if target_layer=="floor": store.erase(p)
				else: store[p].status="removed"; store[p].hp=0
				refresh_indoor()
				accepted = true
			elif Shop.FOOD.has(kind):
				accepted = use_food(kind, animal_id, p)
			elif kind == "collect" and not items_at(p).is_empty():
				var item = items_at(p)[0]
				if item.kind=="skill_scroll":
					campaign.skill_scrolls=campaign.get("skill_scrolls",[])
					if not campaign.skill_scrolls.any(func(record):return record.id==item.id):
						campaign.skill_scrolls.append({"id":item.id,"skill_id":item.skill_id,"rarity":item.rarity})
						var target=animals.filter(func(a):return a.placed and a.hp>0 and item.skill_id not in a.bonus_skills)
						target.sort_custom(func(a,b):return a.id<b.id)
						if not target.is_empty():
							target[0].bonus_skills.append(item.skill_id); target[0].max_hp+=4; Progression.sync_owned(self,target[0]); campaign.skill_scrolls.back().animal_id=target[0].id
				elif item.kind.ends_with("_plan"):
					if not Buildings.NAMES.has(item.kind.trim_suffix("_plan")): return false
					grant_blueprint(item.kind.trim_suffix("_plan"), p)
				else: add_item(item.kind, 1)
				field_items.erase(item)
				milestones.append({"tick": tick, "kind": "item_collected", "item": item.kind})
				accepted = true
			elif kind == "collect" and natural.has(p):
				var harvest: String = natural[p]
				natural.erase(p)
				metrics[harvest + "_collected"] += 1
				if harvest == "weed": campaign.gold += Rules.NATURE.weed_gold
				elif harvest == "mushroom": campaign.mushrooms += 1
				elif harvest == "stump": add_resource("wood", Rules.NATURE.stump_wood)
				accepted = true
			elif kind == "collect" and p == nest and eggs > 0:
				campaign.eggs += eggs
				metrics.eggs_collected += eggs
				eggs = 0
				accepted = true
	return accepted

func issue_order(kind: String, p: Vector2i, animal_id: int = -1) -> bool:
	var target_id = -1
	if kind == "attack_target":
		var found = enemies.filter(func(e): return not e.done and not e.flee and e.pos == p)
		if found.is_empty(): return false
		target_id = found[0].id
	elif kind in ["whistle", "stay"] and not walkable(p): return false
	var accepted = false
	for a in animals:
		if not a.placed or a.hp <= 0 or not SPECIES[a.species].commands or a.loyalty <= 0 or (animal_id >= 0 and a.id != animal_id): continue
		if kind not in SPECIES[a.species].orders:continue
		# Paused orders change intent only. Their reaction countdown starts with resumed simulation.
		a.pending = {"kind": kind, "pos": a.pos if kind == "wander" else p, "target_id": target_id,
			"at": tick + 1 + ceili((100 - a.loyalty) / 25.0)}
		accepted = true
	if accepted: metrics.orders += 1
	return accepted

func spawn_enemy(event: Dictionary):
	var entry: Vector2i = event.entry
	var origin = exit_for(entry) + (exit_for(entry)-entry)*24
	# Keep every spawn outside, including multiple paused debug requests at one entrance.
	var gates=[entry]+entries.filter(func(p):return p!=entry)
	var found=false
	for gate in gates:
		if event.get("debug_single",false) and (not walkable(gate) or live_structure(gate)):continue
		for offset in range(24,56):
			var candidate=exit_for(gate)+(exit_for(gate)-gate)*offset
			if not enemies.any(func(e):return not e.done and e.pos==candidate):
				entry=gate;origin=candidate;found=true;break
		if found:break
	if not found:say("森の外に出現できる場所がありません");return
	var progress = mini(6, maxi(0, campaign.day - 1))
	enemies.append({"move_speed": event.get("move_speed", 1.333333 + progress * 0.27), "move_credit": 0.0, "id": spawned, "pos": origin, "entry": entry, "lv": event.get("lv", 1), "hp": Rules.KIDNAPPER.max_hp + progress * 4, "max_hp": Rules.KIDNAPPER.max_hp + progress * 4,
		"attack_power": Rules.KIDNAPPER.attack_power + progress / 2, "object_attack_power": Rules.KIDNAPPER.object_attack_power,
		"counter_seconds": Rules.KIDNAPPER.counter_seconds, "counter_target": -1, "counter_until": 0, "counter_ready": 0, "next_attack": 0,
		"attacker": -1, "threat_until": 0,
		"move_stopped_until": 0,
		"flee": false, "carry": "", "done": false, "capture_progress": 0,
		"sight_range": event.get("sight_range", Rules.KIDNAPPER.sight_range), "can_see_keeper": false, "last_known_keeper_position": null, "search_state": "探索中",
		"search_goal": null, "search_goal_until": 0, "search_visits": {}, "sight_reaction": "", "sight_reaction_until": 0,
		"weakened_until": 0, "born": tick, "path": [origin], "role": event.role, "state": "探索中"})
	Progression.spawn_data(self,enemies.back(),event)
	if event.get("wave",0)==999:PlayerEvents.add(self,enemies.back().name+"が森の外から到着")
	Life.danger(self, "invasion")
	spawned += 1
	milestones.append({"tick": tick, "kind": "invasion", "id": spawned - 1})
	say("森から人影が現れた！")

func release_keeper(e: Dictionary):
	if e.carry == "keeper":
		e.carry = ""
		keeper.carrier = -1
		keeper.state = "unconscious" if keeper.hp <= 0 else "free"
		keeper.recover_ticks = 0
		keeper.pos = e.pos
		Jobs.hold(self, "rescue")
		var clear = neighbors(e.pos).filter(func(p): return walkable(p) and not occupied(p))
		if not clear.is_empty(): e.pos = clear[0]
		else:
			e.done = true
			metrics.repelled += 1
		metrics.rescues += 1
		keeper.restrainer = -1
		milestones.append({"tick": tick, "kind": "rescue", "id": e.id})
		say("救出！ 牧場の仕事へ戻れます。")

func animal_step(a: Dictionary):
	if not a.placed or a.get("dead",false) or a.get("lost",false): return
	if a.get("abductor",-1)>=0: return
	if campaign.day <= a.unavailable_through_day:
		a.state="療養中" if campaign.day==a.unavailable_through_day else "気絶"; return
	if a.hp <= 0:
		if SPECIES[a.species].mortal: Progression.remove_animal(self,a,"death"); return
		a.state = "気絶"
		a.unavailable_through_day = maxi(a.unavailable_through_day, campaign.day + 1)
		a.rescuing = false
		release_kennel(a)
		return
	if Orders.follow(self,a): return
	if not a.pending.is_empty() and tick >= a.pending.at:
		release_kennel(a)
		a.rest_settled = false
		a.rest_ticks = 0
		a.auto_recovering = false
		a.mode = a.pending.kind
		a.order = a.pending.pos
		a.target_id = a.pending.target_id
		if a.mode=="attack_target":a.priority_seen=tick
		if a.mode in ["stay", "wander", "whistle"]: a.home = a.order
		a.order_until = tick + 40 + a.loyalty * 2
		a.pending = {}
		a.ai_context = "new_order"
	if a.mode != "rest" and tick >= a.order_until: a.mode = "auto"
	if Content.animal_step(self,a):return
	if a.species in ["hen", "cat", "cow"]:
		try_meow(a)
		var threat = enemies.filter(func(e): return not e.done and not e.flee and distance(a.pos, e.pos) <= a.detection_range)
		a.fear = 28 if not threat.is_empty() else maxi(0, a.fear - 1)
		a.state = "怖がる" if a.fear > 0 else ("ついばむ" if a.species == "hen" else "散歩")
		a.move_credit = minf(1.0, a.move_credit + a.move_speed * Content.speed(self,a) * DT)
		if not threat.is_empty() and a.move_credit >= 1:
			a.move_credit -= 1
			var options = neighbors(a.pos).filter(func(p): return walkable(p) and not actor_occupied(p, a.pos))
			options.sort_custom(func(p, q): return distance(p, threat[0].pos) > distance(q, threat[0].pos))
			if not options.is_empty(): a.pos = options[0]
		elif threat.is_empty():
			if a.move_credit >= 1 and tick % 4 == 0:
				a.move_credit -= 1
				var options = neighbors(a.pos).filter(func(p): return walkable(p) and not occupied(p))
				if not options.is_empty(): a.pos = options[daily_rng.randi_range(0, options.size() - 1)]
		return
	# Explicit rest suppresses all threat detection, barking and rescue, until another order.
	if a.mode == "rest":
		a.rescuing = false
		rest_step(a, true)
		return
	var carrier = enemies.filter(func(e): return not e.done and not e.flee and e.hp>0 and (e.carry == "keeper" or e.id==keeper.restrainer))
	if carrier.is_empty():carrier=enemies.filter(func(e):return not e.done and not e.flee and e.hp>0 and ((tick<rescue_until and e.id==last_keeper_attacker_id) or (keeper.state=="unconscious" and distance(e.pos,keeper.pos)<=2)))
	carrier.sort_custom(func(e,f):return e.id<f.id)
	a.rescuing = AnimalData.has_skill(a, "rescue") and not carrier.is_empty()
	var targets = animal_targets(a)
	targets.sort_custom(func(e, f): return distance(a.pos, e.pos) < distance(a.pos, f.pos))
	if a.mode == "auto" and not a.rescuing and targets.is_empty() and a.hp < a.max_hp and (a.auto_recovering or a.hp <= a.max_hp * Rules.REST.auto_hp_fraction):
		a.auto_recovering = true
		rest_step(a, false)
		return
	release_kennel(a)
	a.auto_recovering = false
	a.rest_settled = false
	a.rest_ticks = 0
	try_bark(a)
	if a.species=="bullfrog" and not targets.is_empty() and tick>=a.skill_ready.get("tongue",0):
		var enemy=targets[0]
		if distance(a.pos,enemy.pos)<=ProgressData.SPECIAL.tongue_range and line_of_sight(a.pos,enemy.pos):
			a.skill_ready.tongue=tick+ceili(ProgressData.SPECIAL.tongue_ct/DT)
			Combat.tongue(self,a,enemy)
			a.action_id="tongue"; skill_log.append({"tick":tick,"actor":a.id,"skill":"tongue","target":enemy.id})
	if a.mode == "attack_target": targets=Orders.priority_targets(self,a,targets)
	if a.rescuing: targets = carrier
	if not SPECIES[a.species].can_enter_indoor:
		if a.rescuing and not targets.is_empty() and is_indoor(targets[0].pos):
			a.state="外で待つ"
			a.move_credit=minf(1.75,a.move_credit+a.move_speed*Content.speed(self,a)*DT*Rules.SHIBA.rescue_multiplier)
			if a.move_credit>=1:
				var exit_cell=animal_next(a,rescue_exit(a,targets[0].pos))
				if exit_cell!=a.pos: a.move_credit-=1; open_for_ally(exit_cell); a.pos=exit_cell
			return
		targets=targets.filter(func(e):return not is_indoor(e.pos))
	var goal: Vector2i = a.home
	var chasing = false
	if not a.rescuing and a.mode == "whistle" and a.pos != a.order:
		goal = a.order
		a.state = "呼び戻し"
	elif not a.rescuing and a.stamina < 14:
		a.state = "ひと休み"
		a.stamina = minf(100, a.stamina + 0.8)
		return
	elif not targets.is_empty() and (a.rescuing or a.mode != "stay" or distance(a.pos, targets[0].pos) <= 1):
		if not a.has("first_contact_tick"): a.first_contact_tick = tick
		chasing = true
		goal = targets[0].pos
		if goal.x!=a.pos.x: a.facing=signi(goal.x-a.pos.x)
		a.state = "救出本能" if a.rescuing else "追跡"
		var active_action = "attack" if distance(a.pos, goal) <= 1 else "approach"
		var choices = Rules.AI.dog.duplicate(true)
		choices[active_action] = choices.engage
		choices.erase("engage")
		if not AnimalData.has_skill(a,"bark"): choices.erase("bark")
		# Rescue always pursues the carrier. Noise affects cadence, never the rescue objective.
		if a.rescuing or a.mode == "attack_target" or a.species=="doberman": choices = {active_action: 1.0}
		var intent = Decisions.choose(self, a, "shiba", ("rescue_" if a.rescuing else "enemy_") + active_action, choices, a.rescuing)
		if intent in ["watch", "bark"]:
			a.state = "様子見" if intent == "watch" else "吠える"
			return
		if intent == "reposition":
			a.state = "位置調整"
			if not a.side_step_used:
				var side=side_step(a.pos, goal, a.intent_roll)
				if animal_walkable(a,side): open_for_ally(side); a.pos=side
				a.side_step_used = true
			return
		if distance(a.pos, goal) <= 1 and line_of_sight(a.pos,goal) and tick >= a.next_attack:
			a.next_attack = tick + ceili(a.attack_seconds / DT / Content.attack_speed(self,a))
			a.stamina = maxf(0, a.stamina - 8)
			var enemy = targets[0]
			Progression.enemy_hurt(self,enemy,a.attack_power,a.id)
			combat_log.append({"tick": tick, "source": "animal", "id": a.id, "target": enemy.id, "damage": a.attack_power})
			if enemy.hp == 0:
				if not enemy.get("downed",false):enemy.flee = true
				if stage == 1 and enemy.id == 0: drop_blueprint(enemy.pos)
				release_keeper(enemy)
				say("侵入者を追い返した！")
			else:
				enemy.attacker = a.id
				enemy.threat_until = tick + ceili(Rules.KIDNAPPER.counter_duration / DT)
	elif a.mode in ["wander", "auto"]:
		a.state = "徘徊"
		if tick % 12 == 0:
			var options = neighbors(a.pos).filter(func(p): return animal_walkable(a,p) and distance(p, a.home) <= 3)
			if not options.is_empty(): a.order = options[rng.randi_range(0, options.size() - 1)]
		goal = a.order
	else:
		a.ai_context = "idle"
		a.state = "待機" if a.mode == "stay" else "見張り"
		a.stamina = minf(100, a.stamina + (0.3))
	a.move_credit = minf(1.75, a.move_credit + a.move_speed * Content.speed(self,a) * DT * (Rules.SHIBA.rescue_multiplier if a.rescuing else 1.0))
	if a.move_credit >= 1 and distance(a.pos, goal) > (1 if chasing else 0):
		a.move_credit -= 1
		var move = animal_next(a, goal)
		if move != a.pos and not actor_occupied(move, a.pos):
			open_for_ally(move)
			a.pos = move
			a.stamina = maxf(0, a.stamina - 0.65)
	else:
		a.move_credit = minf(a.move_credit, 0.75)

func release_kennel(a: Dictionary):
	a.kennel_id = -1

func rest_step(a: Dictionary, explicit: bool):
	a.rest_settled = true
	a.state = "休む" if explicit else "自主休養"
	a.stamina = minf(100, a.stamina + 0.8)
	a.rest_ticks += 1
	if a.rest_ticks >= ceili(Rules.REST.seconds / DT):
		a.hp = mini(a.max_hp, a.hp + 1)
		a.rest_ticks = 0

func side_step(p: Vector2i, goal: Vector2i, roll: float) -> Vector2i:
	var options = neighbors(p).filter(func(n): return walkable(n) and not occupied(n) and distance(n, goal) <= distance(p, goal) + 1)
	if options.is_empty(): return p
	return options[mini(int(roll * options.size()), options.size() - 1)]

func enemy_step(e: Dictionary):
	if e.done: return
	if e.pos.x<0 or e.pos.y<0 or e.pos.x>=W or e.pos.y>=H:
		e.state="森から接近"
		e.move_credit+=e.move_speed*Content.speed(self,e)*DT
		if e.move_credit>=1:
			var next=e.pos+(e.entry-exit_for(e.entry))
			if not actor_occupied(next,e.pos) and Combat.pay(e,"move"): e.pos=next; e.move_credit-=1; e.path.append(next)
		return
	RaiderAI.perceive(e, self)
	if Content.enemy_step(self,e):return
	if Progression.enemy_step(self,e): return
	if not e.flee:
		var threatened = tick < e.threat_until and tick >= e.counter_ready and animals.any(func(a): return a.placed and a.id == e.attacker and a.hp > 0)
		var context = "under_attack" if threatened else ("carrying" if e.carry == "keeper" else "kidnap")
		var choices = Rules.AI.counter if threatened else Rules.AI.raider
		var intent = Decisions.choose(self, e, "kidnapper", context, choices)
		if intent == "counter" and threatened:
			if e.counter_target < 0:
				e.counter_target = e.attacker
				e.counter_until = tick + ceili(Rules.KIDNAPPER.counter_duration / DT)
			if keeper.restrainer == e.id and e.carry == "":
				keeper.state = "unconscious" if keeper.hp<=0 else "free"
				keeper.restrainer = -1
				e.capture_progress = 0
		else:
			if e.counter_target >= 0:
				e.counter_target = -1
				e.counter_ready = tick + ceili(Rules.KIDNAPPER.counter_cooldown / DT)
			if intent == "hesitate":
				e.state = "迷う"
				return
	if not e.flee and e.counter_target >= 0:
		var found = animals.filter(func(a): return a.id == e.counter_target and a.hp > 0)
		if found.is_empty() or tick >= e.counter_until:
			e.counter_target = -1
			e.counter_ready = tick + ceili(Rules.KIDNAPPER.counter_cooldown / DT)
		else:
			var target = found[0]
			e.state = "反撃"
			if distance(e.pos, target.pos) <= 1:
				if tick >= e.next_attack and Combat.pay(e,"attack"):
					e.next_attack = tick + ceili(e.counter_seconds / DT)
					var previous_hp: int = target.hp
					var damage = roundi(e.attack_power * (1.0 - AnimalData.SKILLS.meow.reduction if tick < e.weakened_until else 1.0))
					Progression.animal_hurt(self,target,e,damage)
					if previous_hp > target.max_hp * Rules.LOW_HP_FRACTION and target.hp <= target.max_hp * Rules.LOW_HP_FRACTION:
						Life.danger(self, "animal_danger")
						milestones.append({"tick": tick, "kind": "animal_danger", "id": target.id})
					combat_log.append({"tick": tick, "source": "enemy", "id": e.id, "target": target.id, "damage": damage})
			elif tick % 3 == 0:
				move_enemy(e, next_step(e.pos, target.pos, true))
			return
	if Story.idol_enemy(self,e): return
	if not e.flee and e.carry == "" and e.can_see_keeper and distance(e.pos, keeper.pos) <= 1 and keeper.carrier < 0:
		e.state = "主人公へ攻撃" if keeper.hp > 0 else "担ぎ上げる"
		e.observed_action=true
		if keeper.hp > 0:
			if tick >= e.next_attack and Combat.pay(e,"attack"):
				e.next_attack = tick + ceili(e.counter_seconds / DT)
				Life.hurt(self, e)
		else:
			e.capture_progress += 1
			keeper.restrainer=e.id
			if e.capture_progress >= 4:
				e.carry = "keeper"
				keeper.carrier = e.id
				keeper.state = "captured"
				keeper.pos = e.pos
				metrics.captures += 1
				Life.danger(self, "carried")
				PlayerEvents.add(self,"牧場主が連れ去られている")
				milestones.append({"tick": tick, "kind": "carried", "id": e.id})
		return
	e.move_credit = minf(1.9, e.move_credit + (1.0 if e.carry == "keeper" else e.move_speed) * Content.speed(self,e) * DT)
	if e.move_credit < 1: return
	e.move_credit -= 1
	var goal = RaiderAI.target(e, self)
	if e.pos == goal:
		if e.flee:
			e.done = true
			metrics.repelled += 1
			metrics.coins += 0 if e.get("archetype")=="salaryman" else 3
			return
		if e.carry == "keeper":
			e.done = true
			keeper.state = "abducted"
			finish(false)
			return
		return
	e.capture_progress = 0
	var next = next_step(e.pos, goal, true)
	if not e.flee and e.get("intent", "") == "detour" and not e.side_step_used:
		next = side_step(e.pos, goal, e.intent_roll)
		e.side_step_used = true
	move_enemy(e, next)

func move_enemy(e: Dictionary, next: Vector2i):
	if Story.terrain_block(self,next): return
	# Living animals occupy space; carrying the keeper is the only deliberate actor overlap.
	var defenders = animals.filter(func(a): return a.placed and a.hp > 0 and a.pos == next)
	if not e.flee and not defenders.is_empty():
		e.attacker = defenders[0].id
		e.threat_until = tick + ceili(Rules.KIDNAPPER.counter_duration / DT)
		return
	if actor_occupied(next, e.pos) and not (e.carry == "keeper" and next == keeper.pos):
		var around = neighbors(e.pos).filter(func(p): return walkable(p) and not actor_occupied(p, e.pos) and distance(p, next) <= 2)
		if around.is_empty(): return
		var goal = RaiderAI.target(e, self)
		var go = around[0]
		for p in around:
			if distance(p, goal) < distance(go, goal): go = p
		next = go
	if blocks(next) and e.get("archetype","kidnapper")!="kidnapper":
		var obstacle=structures[next]
		var attack_needed=obstacle.kind not in Buildings.DOORS or obstacle.get("lock_hp",0)>0
		if attack_needed:
			if e.object_attack_power<=0 or tick<e.next_attack: return
			e.next_attack=tick+ceili(e.attack_interval/DT)
			e.observed_action=true
	if blocks(next) and (structures[next].kind not in Buildings.DOORS or structures[next].get("lock_hp",0)>0):
		if not Combat.pay(e,"attack"): e.state="息を整える"; return
	if blocks(next) and structures.get(next,{}).get("kind") in Buildings.DOORS:
		var door=structures[next]
		if door.get("lock_hp",0)>0:
			door.lock_hp=maxi(0,door.lock_hp-e.object_attack_power)
			e.state="ロックを壊す"
			combat_log.append({"tick":tick,"source":"lock","id":e.id,"target":door.id,"damage":e.object_attack_power})
			return
		door.open=true
		e.state="ドアを開ける"
		return
	if blocks(next):
		var b = structures[next]
		var damage = maxi(0, e.object_attack_power - b.armor)
		var applied = mini(b.hp, damage)
		b.hp -= applied
		metrics.structure_damage += applied
		combat_log.append({"tick": tick, "source": "object", "id": e.id, "target": b.id, "damage": applied})
		e.state = "ドアを壊す" if b.kind in Buildings.DOORS else "壁を壊す"
		if b.hp <= 0:
			b.status = "destroyed"
			refresh_indoor()
			metrics.destroyed += 1
			say("施設が壊れました")
	else:
		if tick < e.move_stopped_until and next != e.pos: return
		if not Combat.pay(e,"move"): e.state="息を整える"; return
		e.pos = next
		e.path.append(next)

		e.state = "退散" if e.flee else ("反撃" if e.counter_target >= 0 else ("連れ去り" if e.carry == "keeper" else e.search_state))
		if e.carry == "keeper":
			keeper.pos = e.pos
			if not inside(e.pos):
				e.done = true
				keeper.state = "abducted"
				finish(false)

func building_store(target_layer: String) -> Dictionary:
	return floors if target_layer=="floor" else structures

func dismantle_quote(p: Vector2i, target_layer: String="structure") -> int:
	if building_store(target_layer).get(p,{}).get("status")!="ready": return 0
	var b = building_store(target_layer)[p]
	return floori(b.cost * clampf(float(b.hp) / b.max_hp, 0, 1) * Rules.DISMANTLE_REFUND)

func repair_quote(p: Vector2i, target_layer: String="structure") -> Dictionary:
	if building_store(target_layer).get(p,{}).get("status") != "ready": return {"hp": 0, "cost": 0}
	var b = building_store(target_layer)[p]
	var unit_cost: float = maxf(1,b.cost) * Rules.REPAIR_FACTOR / b.max_hp
	var missing=b.max_hp-b.hp+b.get("max_lock_hp",0)-b.get("lock_hp",0)
	var recovery=(missing if debug_enabled and debug_infinite else mini(missing,floori(resource_amount(b.get("resource","soil"))/unit_cost)))
	return {"hp":recovery,"cost":ceili(recovery*unit_cost)}

func repair(p: Vector2i, target_layer: String="structure") -> bool:
	if not working() or paused: return false
	var quote=repair_quote(p,target_layer)
	if quote.hp<=0: return false
	var b=building_store(target_layer)[p]
	if not(debug_enabled and debug_infinite): add_resource(b.get("resource","soil"),-quote.cost)
	var body=mini(quote.hp,b.max_hp-b.hp)
	b.hp+=body
	b.lock_hp=b.get("lock_hp",0)+quote.hp-body
	metrics.repaired+=quote.hp
	return true

func persist_farm():
	Story.persist(self)
	campaign.floors=[]
	for p in floors:
		var row=floors[p].duplicate(true); row.pos=[p.x,p.y]; campaign.floors.append(row)
	for owned in campaign.animals:
		var a=Orders.animal(self,owned.id)
		if not a.is_empty():
			if a.placed: owned.position=[a.pos.x,a.pos.y]
			owned.facing=a.get("facing",1)
			for key in ["equipment","rarity","bonus_skills","ultimate_gauge","ultimate_gauge_max"]: owned[key]=a.get(key)
			owned.hp=a.hp; owned.mode=a.mode; owned.order_remaining=maxi(0,a.order_until-tick); owned.unavailable_through_day=a.unavailable_through_day
	campaign.work_jobs=[]
	for j in jobs:
		if not BUILD.has(j.kind) and j.kind not in Story.ACTIONS: continue
		var row=j.duplicate(true); row.pos=[j.pos.x,j.pos.y]; campaign.work_jobs.append(row)
	campaign.keeper_vitals = {"hp": keeper.hp, "sleepiness": keeper.sleepiness, "drinks_today": keeper.drinks_today,"facing":keeper.get("facing",1),"stamina":keeper.stamina,"ultimate_gauge":keeper.ultimate_gauge,"recovery_state":keeper.state if keeper.state in ["unconscious","hidden_rest"] else "free","heal_credit":keeper.heal_credit,"recover_ticks":keeper.recover_ticks}
	campaign.keeper_position = [keeper.pos.x, keeper.pos.y]
	campaign.resources = resource_snapshot()
	campaign.next_structure_id = next_structure_id
	campaign.facilities = []
	for p in structures:
		var b = structures[p].duplicate(true)
		b.pos = [p.x, p.y]
		campaign.facilities.append(b)
	campaign.field_items = field_items.map(func(item):
		var row = item.duplicate(true)
		row.pos = [item.pos.x, item.pos.y]
		return row)

func step():
	if not working() or paused: return
	var previous_positions={"keeper":keeper.pos}
	for a in animals: previous_positions[a.id]=a.pos
	for a in animals:
		if not a.placed: admit(a,logistics_entry)
	Life.begin_rest_until(self)
	tick += 1
	if not keeper.has("has_stamina"): Combat.init_actor(keeper,true)
	Combat.recover(keeper,DT,keeper.resting)
	for enemy in enemies: Combat.recover(enemy,DT)
	if phase == "day" and tick * DT >= day_seconds: start_night()
	Content.tick(self)
	Life.step(self)
	Jobs.step(self)
	if tick % ceili(Rules.NATURE.interval / DT) == 0: grow_nature()
	command_power = minf(10, command_power + 0.07)
	foods = foods.filter(func(f): return f.until > tick)
	while phase == "defend" and schedule_index < spawn_schedule.size() and tick - night_started_tick >= spawn_schedule[schedule_index].tick:
		spawn_enemy(spawn_schedule[schedule_index])
		schedule_index += 1
	if phase == "defend" and config.repeat_waves and schedule_index == spawn_schedule.size():
		schedule_cycle += 1
		make_schedule()
	if phase=="day":
		for event in spawn_schedule.duplicate():
			if event.get("wave",0)==999 and tick-night_started_tick>=event.tick:
				spawn_enemy(event);spawn_schedule.erase(event)
	for a in animals:
		animal_step(a)
		if a.placed: open_for_ally(a.pos)

		if a.path.back() != a.pos: a.path.append(a.pos)
	for e in enemies:
		enemy_step(e)
		if not working(): break

	if tick % 8 == 0:
		traces.append({"tick": tick, "stamina": snappedf(animals[0].stamina, 0.1), "eggs": eggs,
			"materials": materials, "keeper": keeper.state, "structures": structures.size()})
	update_facing(keeper,previous_positions.keeper)
	for a in animals: update_facing(a,previous_positions.get(a.id,a.pos))
	Progression.tick(self)
	Story.tick(self)
	Life.check_rest_until(self)
	if phase != "defend": return
	if remaining_night() <= 0 and not Story.crisis(self) and not spawn_schedule.slice(schedule_index).any(func(event):return event.get("wave",0)==999) and not enemies.any(func(e):return not e.done and not e.flee and e.get("phone_started",false)):
		if rest_skip.get("target", "") == "dawn": early_finish_bonus = rest_skip.get("bonus",0)
		rest_skip.clear()
		finish(true)
	elif not early_clear and not enemies.any(func(e):return e.get("phone_started",false) and not e.done and not e.flee) and not config.repeat_waves and schedule_index == spawn_schedule.size() and enemies.all(func(e): return e.done or e.flee):
		early_clear = true
		early_clear_tick = tick
		milestones.append({"tick": tick, "kind": "early_clear"})
		say("襲撃を退けた")

func finish(won: bool):
	if result != "": return
	if won and enemies.any(func(e):return not e.done and (e.get("downed",false) or not e.get("stolen",{}).is_empty())):return
	if won and (Story.crisis(self) or enemies.any(func(e):return not e.done and not e.flee and e.get("led_animal",-1)>=0)): return
	if not won and story.get("defeat_reason","")=="": story.defeat_reason="keeper_abducted"
	result = "win" if won else "loss"
	rest_skip.clear()
	phase = "dawn" if won else "result"
	paused = false
	var condition = float(animals[0].hp) / animals[0].max_hp if not animals.is_empty() else 0.0
	var rating = (35 if won else 0) + maxi(0, 25 - metrics.captures * 8) + roundi(condition * 20) + maxi(0, 10 - metrics.structure_damage / 3) + maxi(0, 10 - int(metrics.commands / 3))
	var xp = 16 + rating / 10 if won else 0
	var gold = (32 + rating / 5 + metrics.coins) if won else 0
	score = {"rating": rating, "xp": int(xp), "gold": int(gold), "seconds": (tick - night_started_tick) * DT, "condition": roundi(condition * 100), "time_bonus": early_finish_bonus}
	heal_with_mushrooms()
	for owned in campaign.animals:
		for a in animals:
			if a.id == owned.id:
				owned.hp = a.hp
				if a.hp <= 0 and a.placed:
					if a.unavailable_through_day<campaign.day: a.unavailable_through_day=campaign.day+1
					owned.unavailable_through_day=a.unavailable_through_day
	for j in jobs.duplicate():
		if BUILD.has(j.kind) or j.kind in Story.ACTIONS: continue
		if j.kind=="animal_order": Orders.stop(self,j)
		jobs.erase(j)
	manual_goal = null
	if won:
		campaign.gold += int(gold) + early_finish_bonus
		campaign.exp_pool += int(xp)
		process_dawn()
		Story.morning(self,campaign.day+1)
		persist_farm()
	say("防衛成功！ 育成と購入をして次の日へ。")

func next_campaign() -> Dictionary:
	var data = campaign.duplicate(true)
	data.erase("morning_checkpoint")
	data.day += 1
	if data.has("keeper_vitals"):
		data.keeper_vitals.drinks_today = 0
		if data.keeper_vitals.get("recovery_state","free") not in ["unconscious","hidden_rest"]:data.keeper_vitals.hp = maxi(8, data.keeper_vitals.hp)
	data.night_ready = false
	return data

func observation() -> Dictionary:
	var positions = []
	for a in animals:
		var row = a.duplicate(true)
		for key in ["pos", "home", "order"]: row[key] = [a[key].x, a[key].y]
		row.path = a.path.map(func(p): return [p.x, p.y])
		if not row.pending.is_empty(): row.pending.pos = [a.pending.pos.x, a.pending.pos.y]
		positions.append(row)
	var raiders = []
	for e in enemies:
		var row = e.duplicate(true)
		row.pos = [e.pos.x, e.pos.y]
		row.entry = [e.entry.x, e.entry.y]
		row.path = e.path.map(func(p): return [p.x, p.y])
		for key in ["last_known_keeper_position", "search_goal"]:
			if row[key] != null: row[key] = [row[key].x, row[key].y]
		row.search_visits = e.search_visits.keys().map(func(p): return {"pos": [p.x, p.y], "visits": e.search_visits[p]})
		raiders.append(row)
	var built = []
	for p in structures:
		var row = structures[p].duplicate(true)
		row.pos = [p.x, p.y]
		built.append(row)
	var owner = keeper.duplicate(true)
	owner.pos = [keeper.pos.x, keeper.pos.y]
	var schedule = []
	for event in spawn_schedule:
		var row = event.duplicate(true)
		row.entry = [event.entry.x, event.entry.y]
		schedule.append(row)
	return {"world_story":story.duplicate(true),"forest":trees.keys().map(func(p):return {"id":trees[p],"pos":[p.x,p.y]}),"indoor":indoor.keys().map(func(p):return [p.x,p.y]), "floors":floors.keys().map(func(p):return {"pos":[p.x,p.y],"kind":floors[p].kind,"status":floors[p].status}), "debug":debug_enabled, "seed": seed_value, "stage": stage, "day": campaign.day, "tick": tick, "phase": phase, "paused": paused, "result": result,
		"remaining_day": maxf(0, day_seconds - tick * DT), "night_started_tick": night_started_tick,
		"keeper_path": keeper_path, "life_log": life_log, "jobs_held": jobs_held, "job_hold_reason": job_hold_reason, "manual_goal": [manual_goal.x, manual_goal.y] if manual_goal != null else null, "job_log": job_log, "jobs": jobs.map(func(j):
			var row = j.duplicate(true)
			row.pos = [j.pos.x, j.pos.y]
			for key in ["leader_goal","command_pos"]:
				if row.has(key): row[key]=[j[key].x,j[key].y]
			for target in row.get("targets",[]): target.dest=[target.dest.x,target.dest.y]
			return row),
		"rest_until": rest_skip.duplicate(true), "remaining_night": remaining_night(), "early_clear": early_clear, "early_clear_tick": early_clear_tick, "early_finish_bonus": early_finish_bonus,
		"exp_pool": campaign.exp_pool, "dawn": dawn_summary, "field_items": field_items.map(func(item):
			var row = item.duplicate(true)
			row.pos = [item.pos.x, item.pos.y]
			return row),
		"initial_campaign": checkpoint.duplicate(true),
		"campaign": campaign.duplicate(true), "animals": positions, "raiders": raiders, "keeper": owner,
		"metrics": metrics.duplicate(true), "score": score.duplicate(true), "structures": built, "materials": materials,
		"combat": combat_log.duplicate(true), "resources": resource_snapshot(), "shop_stock": shop_stock.duplicate(true), "shop_log": shop_log.duplicate(true), "actions": actions.duplicate(true), "samples": traces.duplicate(true), "schedule": schedule,
		"sight_log": sight_log.duplicate(true), "ai_settings": Rules.AI, "decision_log": decision_log.duplicate(true), "decision_count": decision_count, "decision_counts": decision_counts.duplicate(true),
		"bark_settings": Rules.BARK, "skill_log": skill_log.duplicate(true), "nature_settings": nature_config,
		"natural": natural.keys().map(func(p): return {"pos": [p.x, p.y], "kind": natural[p]}), "mushrooms": campaign.mushrooms,
		"initial_positions": initial_positions.duplicate(true), "milestones": milestones.duplicate(true), "stage_config": config.duplicate(true), "eggs": eggs, "command_power": command_power}

func try_bark(a: Dictionary):
	if a.mode == "rest" or not AnimalData.has_skill(a, "bark"): return
	if tick < a.next_bark: return
	var nearby = enemies.filter(func(e): return not e.done and not e.flee and distance(a.pos, e.pos) <= a.detection_range)
	if nearby.is_empty(): return
	a.next_bark = tick + ceili(AnimalData.SKILLS.bark.cooldown / DT)
	a.last_bark = tick
	var targets = []
	for enemy in nearby:
		if distance(a.pos, enemy.pos) <= Rules.BARK.range:
			enemy.move_stopped_until = maxi(enemy.move_stopped_until, tick + ceili(Rules.BARK.stop_seconds / DT))
			Combat.grant(self,a,"SkillHit","bark","enemy"+str(enemy.id))
			targets.append(enemy.id)
	metrics.barks += 1
	metrics.bark_casts += 1
	metrics.bark_targets += targets.size()
	skill_log.append({"tick": tick, "time": tick * DT, "actor": "shiba_%d" % a.id, "skill": "bark", "targets": targets, "ready_tick": a.next_bark})
	if skill_log.size() > 64: skill_log.pop_front()

func resource_snapshot() -> Dictionary:
	return {"soil": materials, "wood": wood, "stone": stone}

func resource_amount(kind: String) -> int:
	return resource_snapshot().get(kind, 0)

func add_resource(kind: String, amount: int):
	match kind:
		"soil": materials += amount
		"wood": wood += amount
		"stone": stone += amount
	campaign.resources = resource_snapshot()

func grant_blueprint(id: String, p: Vector2i):
	if not Buildings.NAMES.has(id): return
	var title=Buildings.NAMES[id]
	var text=title+"の設計図を手に入れた。"
	if id not in campaign.blueprint_records: campaign.blueprint_records.append(id)
	if id not in campaign.unlocked_blueprints:
		campaign.unlocked_blueprints.append(id)
		text+="\n"+title+"の作り方を覚えた。"
	milestones.append({"tick":tick,"kind":"blueprint","id":id,"text":text,"pos":[p.x,p.y]})

func use_food(kind: String, animal_id: int, p: Vector2i) -> bool:
	if campaign.items.get(kind, 0) <= 0: return false
	var food = Shop.FOOD[kind]
	for a in animals:
		if (a.id == animal_id or (animal_id < 0 and a.pos == p)) and a.placed and a.category == food.category and a.hp > 0 and a.hp < a.max_hp:
			a.hp = mini(a.max_hp, a.hp + food.hp)
			campaign.items[kind] -= 1
			metrics.fed += 1
			return true
	return false

func grow_nature():
	metrics.nature_rolls += 1
	if nature_rng.randf() >= nature_config.spawn_chance_per_second or natural.size() >= nature_config.limit: return
	var choices = {}
	var total = 0.0
	for kind in nature_config.weights:
		if metrics[kind + "_spawned"] < nature_config.caps[kind]:
			choices[kind] = nature_config.weights[kind]
			total += choices[kind]
	if total <= 0: return
	var roll = nature_rng.randf() * total
	var kind = ""
	for candidate in choices:
		roll -= choices[candidate]
		if roll <= 0:
			kind = candidate
			break
	if kind == "": return
	var sites = []
	for y in range(1, H - 1):
		for x in range(1, W - 1):
			var p = Vector2i(x, y)
			if walkable(p) and not occupied(p) and not live_structure(p) and not natural.has(p) and floors.get(p,{}).get("status") not in ["ready","building"] and p not in entries and not field_items.any(func(item): return item.pos == p): sites.append(p)
	if sites.is_empty(): return
	var p = sites[nature_rng.randi_range(0, sites.size() - 1)]
	natural[p] = kind
	metrics[kind + "_spawned"] += 1

func heal_with_mushrooms():
	while campaign.mushrooms > 0:
		var candidates = animals.filter(func(a): return a.placed and a.hp > 0 and a.hp < a.max_hp)
		if candidates.is_empty(): break
		candidates.sort_custom(func(a, b): return a.id < b.id if a.hp * b.max_hp == b.hp * a.max_hp else a.hp * b.max_hp < b.hp * a.max_hp)
		var a = candidates[0]
		var restored = mini(Rules.NATURE.mushroom_hp, a.max_hp - a.hp)
		a.hp += restored
		campaign.mushrooms -= 1
		metrics.mushrooms_used += 1
		metrics.mushroom_healing += restored

func item_count(id: String) -> int:
	if id == "egg": return campaign.eggs
	if id == "mushroom": return campaign.mushrooms
	return campaign.items.get(id, 0)

func add_item(id: String, count: int):
	if id == "egg": campaign.eggs += count
	elif id == "mushroom": campaign.mushrooms += count
	else: campaign.items[id] = campaign.items.get(id, 0) + count

func buy(id: String) -> bool:
	if phase != "shop" or paused or not Shop.table().has(id) or not Shop.table()[id].Enabled: return false
	var product = Shop.table()[id]
	var available = shop_stock.filter(func(row): return row.product == id and row.remaining > 0)
	if available.is_empty() or campaign.gold < product.BuyPrice: return false
	var row = available[0]
	campaign.gold -= product.BuyPrice
	row.remaining -= 1
	if product.Category == "animals":
		var next_id = campaign.next_animal_id
		campaign.next_animal_id+=1
		campaign.animals.append({"id": next_id, "category": SPECIES[id].category, "species": id, "lv": 1, "xp": 0, "loyalty": row.individual.loyalty, "traits": {}, "name": "", "affinity": 0 if SPECIES[id].affinity else null, "unavailable_through_day": 0})
		for key in ["rarity","bonus_skills","equipment","source"]: campaign.animals.back()[key]=row.individual.get(key,{} if key=="equipment" else ([] if key=="bonus_skills" else (0 if key=="rarity" else "shop")))
		add_resident(campaign.animals.back())
	elif product.Category == "materials": add_resource(id, product.Amount)
	else:
		add_item(id, product.Amount)
		if id.ends_with("_plan"):
			grant_blueprint(id.trim_suffix("_plan"),keeper.pos); campaign.items.erase(id)
	shop_log.append({"side": "buy", "product": id, "amount": product.Amount, "gold": -product.BuyPrice})
	return true

func sell(id: String, animal_id: int = -1) -> bool:
	if id=="maid":return false
	if phase != "shop" or paused or not Shop.table().has(id): return false
	var p = Shop.table()[id]
	if p.Category == "animals":
		var found = campaign.animals.filter(func(a): return a.id == animal_id and a.species == id)
		if found.is_empty() or found[0].get("dead",false) or found[0].get("hp",1)<=0 or campaign.animals.size() <= 1: return false
		var resident=Orders.animal(self,animal_id)
		if not resident.get("equipment",{}).is_empty(): add_item(resident.equipment.item_id,1)
		animals=animals.filter(func(a):return a.id!=animal_id)
		campaign.animals.erase(found[0]) # No last-animal softlock. Placed facilities are not sale inventory.
	elif p.Category == "materials":
		if resource_amount(id) < p.Amount: return false
		add_resource(id, -p.Amount)
	elif p.Category == "items":
		if item_count(id) < p.Amount: return false
		add_item(id, -p.Amount) # Registry is independent: selling a plan never revokes unlock.
	else: return false
	campaign.gold += p.SellPrice
	shop_log.append({"side": "sell", "product": id, "animal_id": animal_id, "amount": p.Amount, "gold": p.SellPrice})
	return true

func remaining_night() -> float:
	if phase in ["shop", "day"]: return config.time_limit_seconds
	return maxf(0, config.time_limit_seconds - (tick - night_started_tick) * DT)

func available(a: Dictionary) -> bool:
	return a.placed and a.hp > 0 and not a.get("dead",false) and not a.get("lost",false) and a.get("abductor",-1)<0 and campaign.day > a.unavailable_through_day

static func animal_name(a: Dictionary) -> String:
	return a.get("name", "") if a.get("name", "") != "" else SPECIES[a.species].title

func begin_day():
	if story.has("migration_error"):
		Story.say(self,story.migration_error)
		return null
	if phase != "shop" or paused: return null
	persist_farm()
	var data = campaign.duplicate(true)
	data.night_ready = true
	data.morning_checkpoint = morning_checkpoint.duplicate(true)
	return get_script().new(data, seed_value, config)

func rename_animal(id: int, text: String) -> bool:
	if phase != "shop" or paused: return false
	for a in campaign.animals:
		if a.id == id:
			a.name = text.strip_edges().left(12)
			return true
	return false

func level_cost(id: int) -> int:
	for a in campaign.animals:
		if a.id == id: return a.lv * 20
	return 0

func train_animal(id: int) -> bool:
	if phase != "shop" or paused: return false
	for a in campaign.animals:
		if a.id == id and a.lv < 5 and campaign.exp_pool >= level_cost(id):
			campaign.exp_pool -= level_cost(id)
			a.lv += 1
			return true
	return false

func items_at(p: Vector2i) -> Array:
	return field_items.filter(func(item): return item.pos == p and item.kind != "chick")

func drop_blueprint(_p: Vector2i):
	# All active recipes are already available; disabled hut plans no longer drop.
	pass

func process_dawn():
	dawn_summary = {"eggs": 0, "chicks": 0, "hens": 0, "feathers": 0, "unconscious": [], "pending_blueprints": 0}
	# Age existing field items before laying new eggs; one transition per dawn.
	for item in field_items.duplicate():
		if item.kind == "kennel_plan": dawn_summary.pending_blueprints += 1
		if item.get("born_day", campaign.day) >= campaign.day: continue
		if item.kind == "egg":
			item.kind = "chick"
			item.born_day = campaign.day
			dawn_summary.chicks += 1
		elif item.kind == "chick":
			var id = campaign.next_animal_id
			campaign.next_animal_id+=1
			campaign.animals.append({"id": id, "species": "hen", "category": "bird", "lv": 1, "xp": 0, "loyalty": 0, "name": "", "affinity": null, "unavailable_through_day": 0})
			field_items.erase(item)
			dawn_summary.hens += 1
	for a in animals:
		if a.hp <= 0 and a.placed: dawn_summary.unconscious.append(a.id)
		if a.species != "hen" or not available(a): continue
		field_items.append({"kind": "egg", "pos": a.pos, "born_day": campaign.day,
			"protected_by": -1})
		dawn_summary.eggs += 1
		metrics.eggs_produced += 1
		if AnimalData.has_skill(a, "feather") and daily_rng.randf() < 0.15:
			field_items.append({"kind": "feather", "pos": a.pos, "born_day": campaign.day})
			dawn_summary.feathers += 1
	milestones.append({"tick": tick, "kind": "dawn"})

func line_of_sight(from: Vector2i, to: Vector2i, target_surface: bool=false) -> bool:
	# Supercover: no peeking through touching wall corners.
	var delta = to - from
	var count = maxi(absi(delta.x), absi(delta.y)) * 4
	var previous = from
	for i in range(1, count + 1):
		var p = Vector2i((Vector2(from) + Vector2(delta) * float(i) / count).round())
		if p != previous and p.x != previous.x and p.y != previous.y:
			if blocks_sight(Vector2i(p.x, previous.y)) or blocks_sight(Vector2i(previous.x, p.y)): return false
		if p != from and blocks_sight(p) and not (target_surface and p==to): return false
		previous = p
	return true

func blocks_sight(p: Vector2i) -> bool:
	if Story.terrain_block(self,p): return true
	if not structures.has(p) or structures[p].status != "ready": return false
	var b = structures[p]
	return b.get("blocks_sight", b.kind not in ["kennel", "coop"]) and not b.open

func animal_targets(a: Dictionary) -> Array:
	if SPECIES[a.species].combat_response==ProgressData.CombatResponse.NONE: return []
	for e in enemies:
		if SPECIES[a.species].combat_response==ProgressData.CombatResponse.AUTO and not e.done and not e.flee and distance(a.pos, e.pos) <= a.detection_range and line_of_sight(a.pos,e.pos):
			a.known_enemies[e.id] = tick + 8
	return enemies.filter(func(e): return not e.done and not e.flee and e.hp>0 and a.known_enemies.get(e.id, -1) >= tick and distance(a.pos, e.pos) <= a.attack_target_range)

func share_detection(a: Dictionary, enemy_id: int, seconds: float = 2.0):
	a.known_enemies[enemy_id] = tick + ceili(seconds / DT)

func try_meow(a: Dictionary):
	if not AnimalData.has_skill(a, "meow") or tick < a.skill_ready.get("meow", 0): return
	var skill = AnimalData.SKILLS.meow
	var nearby = enemies.filter(func(e): return not e.done and not e.flee and distance(a.pos, e.pos) <= skill.range)
	if nearby.is_empty(): return
	a.skill_ready.meow = tick + ceili(skill.cooldown / DT)
	for e in nearby:
		e.weakened_until = tick + ceili(skill.duration / DT)
		Combat.grant(self,a,"SkillHit","meow","enemy"+str(e.id))
	skill_log.append({"tick": tick, "actor": "cat_%d" % a.id, "skill": "meow", "targets": nearby.map(func(e): return e.id)})

func add_resident(owned: Dictionary):
	if owned.get("dead",false): return
	var a = owned.duplicate(true)
	a.rarity=ProgressData.rarity(a.get("rarity",0)); a.bonus_skills=a.get("bonus_skills",[]); a.equipment=a.get("equipment",{}); a.faction=a.get("faction","owned")
	a.loyalty = a.get("loyalty", SPECIES[a.species].loyalty)
	var stats=AnimalData.stats(a.species,a.lv)
	a.move_speed = stats.move_speed
	a.detection_range = SPECIES[a.species].detection_range
	a.attack_target_range = SPECIES[a.species].attack_target_range
	a.attack_seconds = stats.attack_seconds
	a.object_attack_power = SPECIES[a.species].object_attack
	a.skills = stats.skills.duplicate()
	a.defense=stats.get("defense",0)
	a.ai_accuracy=stats.get("ai_accuracy",50)
	a.ultimates=stats.get("ultimates",[])
	Combat.init_actor(a,stats.get("has_stamina",false))
	a.type_tag="Human" if a.has_stamina else "Animal"
	a.skill_ready = {}
	a.known_enemies = {}
	a.pos = Vector2i(-10, -10)
	a.placed = false
	a.deployment = "admission_pending"
	a.home = a.pos
	a.stamina = 100.0
	a.max_hp = stats.hp + (4 if "hardy" in a.bonus_skills else 0)
	a.hp = clampi(a.get("hp", a.max_hp), 0, a.max_hp)
	a.next_bark = 0
	a.last_bark = -100
	a.attack_power = stats.attack
	a.next_attack = 0
	a.move_credit = 0.0
	a.rescuing = false
	a.kennel_id = -1
	a.rest_settled = false
	a.rest_ticks = 0
	a.kennel_ticks = 0
	a.healing_kennel = -1
	a.auto_recovering = false
	a.fear = 0
	a.order_until = tick + owned.get("order_remaining",40+a.loyalty*2)
	a.order = a.pos
	a.mode = owned.get("mode", "auto")
	a.pending = {}
	a.target_id = -1
	a.state = "見張り" if a.species == "shiba" else "ついばむ"
	a.path = [a.pos]
	animals.append(a)

	var location=owned.get("position",[logistics_entry.x,logistics_entry.y])
	var preferred=Vector2i(location[0],location[1]) if owned.has("position") else (keeper.pos+Vector2i(2,0) if a.id==1 else logistics_entry)
	admit(a,preferred)

func admit(a: Dictionary,preferred: Vector2i):
	if a.get("dead",false) or a.get("lost",false): return
	var sites=[]
	var owned=campaign.animals.filter(func(row):return row.id==a.id)
	var retained=not owned.is_empty() and owned[0].has("position") and animal_walkable(a,preferred) and not occupied(preferred)
	if retained or (a.id==1 and preferred==keeper.pos+Vector2i(2,0) and animal_walkable(a,preferred) and not occupied(preferred)):
		sites.append(preferred)
	else:
		for entry in [logistics_entry]:
			if blocks(entry): continue
			for y in range(1,H-1):
				for x in range(1,W-1):
					var cell=Vector2i(x,y)
					if distance(entry,cell)>4 or cell in entries or not animal_walkable(a,cell) or occupied(cell): continue
					if not find_path(entry,cell,false,true,not SPECIES[a.species].can_enter_indoor).is_empty() and cell not in sites: sites.append(cell)
		sites.sort_custom(func(c,d):
			var dc=distance(c,logistics_entry); var dd=distance(d,logistics_entry)
			return dc<dd if dc!=dd else (c.y<d.y if c.y!=d.y else c.x<d.x))
	if sites.is_empty():
		if a.state!="受入待ち": Orders.report(self,"入口付近の通路と場所を空けてください")
		a.state="受入待ち"; return
	a.pos=sites[0]; a.home=a.pos; a.order=a.pos; a.path=[a.pos]; a.placed=true; a.deployment="resident"
	job_log.append({"tick":tick,"event":"admitted","animal_id":a.id,"pos":[a.pos.x,a.pos.y]})

func refresh_indoor():
	indoor=Buildings.rooms(self)

func is_indoor(p: Vector2i) -> bool:
	return indoor.has(p)

func animal_walkable(a: Dictionary,p: Vector2i) -> bool:
	return walkable(p) and (SPECIES[a.species].can_enter_indoor or not is_indoor(p))

func animal_path(a: Dictionary,start: Vector2i,goal: Vector2i) -> Array:
	return find_path(start,goal,false,true,not SPECIES[a.species].can_enter_indoor)

func animal_next(a: Dictionary,goal: Vector2i) -> Vector2i:
	var path=animal_path(a,a.pos,goal)
	return path[1] if path.size()>1 and not actor_occupied(path[1],a.pos) else a.pos

func open_for_ally(p: Vector2i):
	if structures.get(p,{}).get("kind") in Buildings.DOORS and structures[p].status=="ready": structures[p].open=true

func queue_order(kind: String,ids: Array,p: Vector2i) -> bool:
	return Orders.enqueue(self,kind,ids,p)

func rescue_exit(a: Dictionary, target: Vector2i=Vector2i(-1,-1)) -> Vector2i:
	if target.x<0: target=keeper.pos
	var region={}
	var frontier=[target] if is_indoor(target) else []
	while not frontier.is_empty():
		var cell=frontier.pop_back()
		if region.has(cell): continue
		region[cell]=true
		for n in neighbors(cell):
			if is_indoor(n) and not region.has(n): frontier.append(n)
	var sites=[]
	for p in structures:
		if structures[p].kind not in Buildings.DOORS or structures[p].status!="ready": continue
		if not neighbors(p).any(func(n):return region.has(n)): continue
		for cell in neighbors(p):
				if animal_walkable(a,cell) and not is_indoor(cell) and not actor_occupied(cell,a.pos) and not animal_path(a,a.pos,cell).is_empty(): sites.append(cell)
	sites.sort_custom(func(c,d):return distance(a.pos,c)<distance(a.pos,d) if distance(a.pos,c)!=distance(a.pos,d) else (c.y<d.y if c.y!=d.y else c.x<d.x))
	return sites[0] if not sites.is_empty() else a.pos

func debug_action(action: String, selection: Dictionary = {}) -> bool:
	if not debug_enabled: return false
	if action=="spawn_enemy": return debug_spawn_enemy(selection.get("enemy_kind",""))
	if action=="lock" and (selection.get("kind")!="structure" or structures.get(selection.get("pos"),{}).get("kind")!="locked_door" or structures.get(selection.get("pos"),{}).get("status")!="ready"): return false
	if action=="infinite": debug_infinite=not debug_infinite
	elif action=="whistle": campaign.items.whistle=1
	elif SPECIES.has(action):
		var id=campaign.next_animal_id
		campaign.next_animal_id+=1
		var owned={"id":id,"species":action,"category":SPECIES[action].category,"lv":1,"xp":0,"loyalty":SPECIES[action].loyalty,"unavailable_through_day":0}
		campaign.animals.append(owned); add_resident(owned)
	elif action in ["hurt","heal","lock"]:
		var amount=-10 if action=="hurt" else 10
		match selection.get("kind"):
			"idol":
				if action=="lock": return false
				if amount<0: Story.damage(self,10)
				else: story.idol.hp=mini(story.idol.max_hp,story.idol.hp+10)
			"keeper":
				if amount<0: Life.hurt(self,{"id":-1,"attack_power":10})
				else: keeper.hp=mini(keeper.max_hp,keeper.hp+10)
			"animal":
				var a=Orders.animal(self,selection.id)
				if a.is_empty(): return false
				a.hp=clampi(a.hp+amount,0,a.max_hp)
				if a.hp==0:
					if SPECIES[a.species].mortal: Progression.remove_animal(self,a,"death")
					else: a.unavailable_through_day=campaign.day+1; a.state="気絶"
			"enemy":
				for e in enemies:
					if e.id!=selection.id: continue
					e.hp=clampi(e.hp+amount,0,e.max_hp)
					if e.hp==0: e.flee=true; release_keeper(e); Progression.release_animal(self,e); Progression.loot(self,e)
			"structure", "floor":
				var b=building_store(selection.kind).get(selection.pos,{})
				if b.is_empty() or b.get("status")!="ready" or (selection.has("target_id") and selection.target_id!=b.id): return false
				if action=="lock": b.lock_hp=maxi(0,b.get("lock_hp",0)-4)
				else:
					b.hp=clampi(b.hp+amount,0,b.max_hp)
					if b.hp==0: b.status="destroyed"; refresh_indoor()
			_: return false
	else: return false
	job_log.append({"tick":tick,"event":"debug","action":action})
	return true

func debug_spawn_enemy(kind: String) -> bool:
	if not debug_enabled: return false
	if not ProgressData.ENEMY_ROWS.has(kind) and kind!="doberman": say("未実装の敵です"); return false
	if not working(): say("敵の出現は昼・夜に使えます"); return false
	var gates=entries.duplicate()
	gates.sort_custom(func(a,b):return distance(keeper.pos,a)<distance(keeper.pos,b) if distance(keeper.pos,a)!=distance(keeper.pos,b) else (a.y<b.y if a.y!=b.y else a.x<b.x))
	for gate in gates:
		if not walkable(gate) or live_structure(gate): continue
		var sites=[]
		for y in range(gate.y-3,gate.y+4):
			for x in range(gate.x-3,gate.x+4):
				var cell=Vector2i(x,y)
				if distance(cell,gate)>3 or not walkable(cell) or live_structure(cell) or occupied(cell) or is_indoor(cell):continue
				if not find_path(gate,cell,false,true,kind=="doberman").is_empty():sites.append(cell)
		sites.sort_custom(func(a,b):return distance(gate,a)<distance(gate,b) if distance(gate,a)!=distance(gate,b) else (a.y<b.y if a.y!=b.y else a.x<b.x))
		if sites.is_empty():continue
		var count=enemies.size()
		spawn_enemy({"role":kind,"entry":gate,"lv":1,"debug_single":true})
		if enemies.size()==count:continue
		var e=enemies.back()
		job_log.append({"tick":tick,"event":"debug","action":"spawn_enemy","enemy_kind":kind,"enemy_id":e.id,"pos":e.pos})
		say("%sを入口に出現させました"%e.name)
		return true
	say("入口付近に出現できる空きマスがありません")
	return false

func update_facing(actor: Dictionary, previous: Vector2i):
	if actor.pos.x!=previous.x: actor.facing=signi(actor.pos.x-previous.x)
