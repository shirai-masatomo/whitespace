extends RefCounted
## Deterministic fixed-tick rules. No scene, Input, frame clock or rendering dependencies.
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
const ORDERS = ["auto", "stay", "wander", "rest", "attack_target", "whistle"]
var campaign: Dictionary
var checkpoint: Dictionary
var stage = 1
var seed_value = 1
var rng = RandomNumberGenerator.new()
var tick = 0
var phase = "prepare"
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
var keeper = {"pos": Vector2i(19, 8), "placed": false, "carrier": -1, "state": "free", "restrainer": -1}
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
var spawn_schedule: Array = []
var schedule_index = 0
var schedule_cycle = 0
var entries: Array = []
var metrics = {"repelled": 0, "stolen": 0, "structure_damage": 0, "commands": 0.0,
	"eggs_produced": 0, "eggs_collected": 0, "barks": 0, "fed": 0, "coins": 0,
	"captures": 0, "rescues": 0, "built": 0, "destroyed": 0, "orders": 0, "interrupted": 0, "repaired": 0, "soil_repair": 0,
	"bark_casts": 0, "bark_targets": 0, "weed_spawned": 0, "mushroom_spawned": 0, "weed_collected": 0, "mushroom_collected": 0, "stump_spawned": 0, "stump_collected": 0, "nature_rolls": 0, "mushrooms_used": 0, "mushroom_healing": 0}

static func new_campaign() -> Dictionary:
	return {"stage": 1, "gold": 12, "eggs": 0, "mushrooms": 0, "shelter": false,
		"fence": 0, "resources": {"soil": 100, "wood": 0, "stone": 0}, "items": {"dog_food": 2, "hen_food": 0}, "unlocked_blueprints": [], "facilities": [], "next_structure_id": 1, "animals": [{"id": 1, "category": "dog", "species": "shiba", "lv": 1, "xp": 0, "loyalty": 75}]}

func _init(data: Dictionary = {}, seed_number: int = 17, stage_override: Dictionary = {}):
	campaign = new_campaign() if data.is_empty() else data.duplicate(true)
	for resource in Rules.RESOURCE_TYPES:
		if not campaign.resources.has(resource): campaign.resources[resource] = 0
	campaign.items = campaign.get("items", {"dog_food": 2, "hen_food": 0})
	campaign.unlocked_blueprints = campaign.get("unlocked_blueprints", [])
	checkpoint = campaign.duplicate(true)
	stage = campaign.stage
	seed_value = seed_number
	rng.seed = seed_number
	nature_rng.seed = seed_number * 1009 + 9871
	campaign.mushrooms = campaign.get("mushrooms", 0)
	config = (StageData.STAGES[stage] if stage_override.is_empty() else stage_override).duplicate(true)
	materials = campaign.resources.soil
	wood = campaign.resources.wood
	stone = campaign.resources.stone
	nature_config = config.get("nature", Rules.NATURE).duplicate(true)
	next_structure_id = campaign.get("next_structure_id", 1)
	for saved in campaign.get("facilities", []):
		var record = saved.duplicate(true)
		var cell = Vector2i(record.pos[0], record.pos[1])
		record.erase("pos")
		structures[cell] = record
	for wave in config.waves:
		for cell in wave.entries:
			var p = Vector2i(cell[0], cell[1])
			if p not in entries: entries.append(p)
	make_schedule()
	# A newly bought hen must not spawn inside a facility retained from the previous day.
	if has_nest() and (blocks(nest) or live_structure(nest)):
		var clear_cells = []
		for y in range(1, H - 1):
			for x in range(1, W - 1):
				var p = Vector2i(x, y)
				if walkable(p) and not live_structure(p) and p not in entries: clear_cells.append(p)
		clear_cells.sort_custom(func(a, b): return distance(a, NEST) < distance(b, NEST))
		if not clear_cells.is_empty(): nest = clear_cells[0]
	for owned in campaign.animals:
		var a = owned.duplicate(true)
		a.loyalty = a.get("loyalty", 0)
		a.pos = Vector2i(-10, -10)
		a.placed = false
		a.home = a.pos
		a.stamina = 100.0
		a.max_hp = Rules.SHIBA.max_hp if a.species == "shiba" else 20
		a.hp = clampi(a.get("hp", a.max_hp), 0, a.max_hp)
		a.next_bark = 0
		a.last_bark = -100
		a.attack_power = Rules.SHIBA.attack_power if a.species == "shiba" else 0
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
		a.order_until = 0
		a.order = a.pos
		a.mode = "auto"
		a.pending = {}
		a.target_id = -1
		a.state = "見張り" if a.species == "shiba" else "ついばむ"
		a.path = [a.pos]
		animals.append(a)
	say("主人公を配置してください")

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
	spawn_schedule.sort_custom(func(a, b): return a.tick < b.tick)

func next_attack_seconds() -> float:
	return maxf(0, (spawn_schedule[schedule_index].tick - tick) * DT) if schedule_index < spawn_schedule.size() else -1.0

func say(message: String):
	events.append({"tick": tick, "text": message})
	if events.size() > 5: events.pop_front()

func inside(p: Vector2i) -> bool:
	return p.x >= 1 and p.x < W - 1 and p.y >= 1 and p.y < H - 1

func walkable(p: Vector2i) -> bool:
	return inside(p) and not blocks(p)

func blocks(p: Vector2i) -> bool:
	return structures.has(p) and structures[p].status == "ready" and structures[p].kind != "kennel" and not structures[p].open

func live_structure(p: Vector2i) -> bool:
	return structures.has(p) and structures[p].status in ["ready", "building"]

func occupied(p: Vector2i) -> bool:
	return (keeper.placed and p == keeper.pos) or animals.any(func(a): return a.placed and a.pos == p) or enemies.any(func(e): return not e.done and e.pos == p) or foods.any(func(f): return f.pos == p)

func has_nest() -> bool:
	return campaign.animals.any(func(a): return a.species == "hen")

func can_build(kind: String, p: Vector2i) -> bool:
	return phase == "defend" and not paused and BUILD.has(kind) and inside(p) and p not in entries and not (p == nest and has_nest()) and not occupied(p) and not live_structure(p) and BUILD[kind].get("blueprint", "") in ([""] + campaign.unlocked_blueprints) and resource_amount(BUILD[kind].get("resource", "soil")) >= BUILD[kind].cost

func neighbors(p: Vector2i) -> Array:
	return [p + Vector2i.RIGHT, p + Vector2i.LEFT, p + Vector2i.UP, p + Vector2i.DOWN]

func exit_for(entry: Vector2i) -> Vector2i:
	# Configured entrance determines the return edge, not a fixed left-hand exit.
	var exits = [Vector2i(0, entry.y), Vector2i(W - 1, entry.y), Vector2i(entry.x, 0), Vector2i(entry.x, H - 1)]
	exits.sort_custom(func(a, b): return distance(entry, a) < distance(entry, b))
	return exits[0]

func next_step(start: Vector2i, goal: Vector2i, raider: bool = false) -> Vector2i:
	if start == goal: return start
	var frontier = [start]
	var cost = {start: 0.0}
	var first = {start: start}
	while not frontier.is_empty():
		var best = 0
		for i in range(1, frontier.size()):
			if cost[frontier[i]] + distance(frontier[i], goal) < cost[frontier[best]] + distance(frontier[best], goal): best = i
		var p: Vector2i = frontier.pop_at(best)
		if p == goal: return first[p]
		for n in neighbors(p):
			var exit_cell = raider and n == goal and entries.any(func(entry): return exit_for(entry) == n)
			if not inside(n) and not exit_cell: continue
			var blocked = blocks(n)
			if blocked and not raider: continue
			# Compare walking actions with the actual number of object attacks needed.
			var value: float = cost[p] + 1.0 + (ceilf(float(structures[n].hp) / Rules.KIDNAPPER.object_attack_power) if blocked else 0)
			if not cost.has(n) or value < cost[n]:
				cost[n] = value
				first[n] = n if p == start else first[p]
				if n not in frontier: frontier.append(n)
	return start

static func distance(a: Vector2i, b: Vector2i) -> int:
	return absi(a.x - b.x) + absi(a.y - b.y)

func valid_animal_site(id: int, p: Vector2i) -> bool:
	return animals.any(func(a): return a.id == id and not a.placed) and keeper.placed and walkable(p) and not live_structure(p) and p not in entries and not occupied(p)

func can_place_animal(id: int, p: Vector2i) -> bool:
	return phase == "defend" and not paused and valid_animal_site(id, p)

func act(kind: String, p: Vector2i = Vector2i.ZERO, animal_id: int = -1) -> bool:
	var accepted = false
	if phase == "prepare":
		if kind == "place" and not keeper.placed and walkable(p) and not live_structure(p) and p not in entries and not (p == nest and has_nest()):
			keeper.pos = p
			keeper.placed = true
			phase = "defend"
			initial_positions = {"keeper": [keeper.pos.x, keeper.pos.y], "animals": []}
			milestones.append({"tick": 0, "kind": "auto_start", "id": -1})
			say("敵の襲来に備えよ")
			accepted = true
	elif phase == "defend":
		if kind == "pause":
			paused = not paused
			accepted = true
		elif kind in ORDERS:
			accepted = issue_order(kind, p, animal_id)
		elif not paused:
			if kind == "place_animal" and can_place_animal(animal_id, p):
				for a in animals:
					if a.id != animal_id: continue
					a.pos = p
					a.home = p
					a.order = p
					a.path = [p]
					a.placed = true
					initial_positions.animals.append({"id": a.id, "pos": [p.x, p.y], "deployment_tick": tick})
					accepted = true
			elif BUILD.has(kind):
				if can_build(kind, p):
					add_resource(BUILD[kind].get("resource", "soil"), -BUILD[kind].cost)
					var hp: int = BUILD[kind].hp + (campaign.fence * 4 if kind == "build_gate" else 0)
					structures[p] = {"id": next_structure_id, "kind": "gate" if kind == "build_gate" else kind,
						"hp": 0, "max_hp": hp, "armor": 0, "open": false, "cost": BUILD[kind].cost, "resource": BUILD[kind].get("resource", "soil"),
						"status": "building", "remaining": ceili(BUILD[kind].seconds / DT), "total_ticks": ceili(BUILD[kind].seconds / DT)}
					next_structure_id += 1
					natural.erase(p)
					accepted = true
			elif kind == "gate" and live_structure(p) and structures[p].status == "ready" and structures[p].kind == "gate" and not occupied(p):
				structures[p].open = not structures[p].open
				accepted = true
			elif kind == "repair":
				accepted = repair(p)
			elif kind == "remove" and live_structure(p) and not occupied(p):
				add_resource(structures[p].get("resource", "soil"), dismantle_quote(p))
				structures[p].status = "removed"
				structures[p].hp = 0
				accepted = true
			elif Shop.FOOD.has(kind):
				accepted = use_food(kind, animal_id, p)
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
	actions.append({"tick": tick, "kind": kind, "pos": [p.x, p.y], "accepted": accepted, "paused": paused, "animal_id": animal_id})
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
		if not a.placed or a.loyalty <= 0 or (animal_id >= 0 and a.id != animal_id): continue
		if kind == "rest" and a.category != "dog": continue
		# Paused orders change intent only. Their reaction countdown starts with resumed simulation.
		a.pending = {"kind": kind, "pos": a.pos if kind == "wander" else p, "target_id": target_id,
			"at": tick + 1 + ceili((100 - a.loyalty) / 25.0)}
		accepted = true
	if accepted: metrics.orders += 1
	return accepted

func spawn_enemy(event: Dictionary):
	var entry: Vector2i = event.entry
	var origin = exit_for(entry) if blocks(entry) else entry
	enemies.append({"id": spawned, "pos": origin, "entry": entry, "lv": event.get("lv", 1), "hp": Rules.KIDNAPPER.max_hp, "max_hp": Rules.KIDNAPPER.max_hp,
		"attack_power": Rules.KIDNAPPER.attack_power, "object_attack_power": Rules.KIDNAPPER.object_attack_power,
		"counter_seconds": Rules.KIDNAPPER.counter_seconds, "counter_target": -1, "counter_until": 0, "counter_ready": 0, "next_attack": 0,
		"attacker": -1, "threat_until": 0,
		"move_stopped_until": 0,
		"flee": false, "carry": "", "done": false, "capture_progress": 0,
		"born": tick, "path": [origin], "role": event.role, "state": "主人公へ"})
	spawned += 1
	milestones.append({"tick": tick, "kind": "invasion", "id": spawned - 1})
	say("入口から誘拐役！ 牧場主を守ろう。")

func release_keeper(e: Dictionary):
	if e.carry == "keeper":
		e.carry = ""
		keeper.carrier = -1
		keeper.state = "free"
		keeper.pos = e.pos
		metrics.rescues += 1
		keeper.restrainer = -1
		milestones.append({"tick": tick, "kind": "rescue", "id": e.id})
		say("救出！ 牧場主はその場で待っています。")

func animal_step(a: Dictionary):
	if not a.placed: return
	if a.hp <= 0:
		a.state = "休養中"
		a.rescuing = false
		release_kennel(a)
		return
	if not a.pending.is_empty() and tick >= a.pending.at:
		release_kennel(a)
		a.rest_settled = false
		a.rest_ticks = 0
		a.auto_recovering = false
		a.mode = a.pending.kind
		a.order = a.pending.pos
		a.target_id = a.pending.target_id
		if a.mode in ["stay", "wander", "whistle"]: a.home = a.order
		a.order_until = tick + 40 + a.loyalty * 2
		a.pending = {}
		a.ai_context = "new_order"
	if a.mode != "rest" and tick >= a.order_until: a.mode = "auto"
	if a.species == "hen":
		var threat = enemies.filter(func(e): return not e.done and not e.flee and distance(a.pos, e.pos) <= 4)
		a.fear = 28 if not threat.is_empty() else maxi(0, a.fear - 1)
		a.state = "怖がる" if a.fear > 0 else "卵を育てる"
		if not threat.is_empty() and tick % 3 == 0:
			var options = neighbors(a.pos).filter(func(p): return walkable(p))
			options.sort_custom(func(p, q): return distance(p, threat[0].pos) > distance(q, threat[0].pos))
			if not options.is_empty(): a.pos = options[0]
		elif threat.is_empty():
			if tick % 4 == 0: a.pos = next_step(a.pos, nest)
			if tick % maxi(24, 40 - (a.lv - 1) * 4) == 0 and a.fear == 0 and eggs < 8:
				eggs += 1
				metrics.eggs_produced += 1
		return
	# Explicit rest suppresses all threat detection, barking and rescue, until another order.
	if a.mode == "rest":
		a.rescuing = false
		rest_step(a, true)
		return
	var carrier = enemies.filter(func(e): return not e.done and not e.flee and e.carry == "keeper")
	a.rescuing = not carrier.is_empty()
	var targets = enemies.filter(func(e): return not e.done and not e.flee and distance(a.pos, e.pos) <= Rules.SHIBA.detection_range)
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
	if a.mode == "attack_target":
		var selected = enemies.filter(func(e): return e.id == a.target_id and not e.done and not e.flee)
		if not selected.is_empty(): targets = selected
		else: a.mode = "auto"
	if a.rescuing: targets = carrier
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
		a.state = "救出本能" if a.rescuing else "追跡"
		var active_action = "attack" if distance(a.pos, goal) <= 1 else "approach"
		var choices = Rules.AI.dog.duplicate(true)
		choices[active_action] = choices.engage
		choices.erase("engage")
		# Rescue always pursues the carrier. Noise affects cadence, never the rescue objective.
		if a.rescuing or a.mode == "attack_target": choices = {active_action: 1.0}
		var intent = Decisions.choose(self, a, "shiba", ("rescue_" if a.rescuing else "enemy_") + active_action, choices, a.rescuing)
		if intent in ["watch", "bark"]:
			a.state = "様子見" if intent == "watch" else "吠える"
			return
		if intent == "reposition":
			a.state = "位置調整"
			if not a.side_step_used:
				a.pos = side_step(a.pos, goal, a.intent_roll)
				a.side_step_used = true
			return
		if distance(a.pos, goal) <= 1 and tick >= a.next_attack:
			a.next_attack = tick + ceili(Rules.SHIBA.attack_seconds / DT)
			a.stamina = maxf(0, a.stamina - 8)
			var enemy = targets[0]
			enemy.hp = maxi(0, enemy.hp - a.attack_power)
			combat_log.append({"tick": tick, "source": "animal", "id": a.id, "target": enemy.id, "damage": a.attack_power})
			if enemy.hp == 0:
				enemy.flee = true
				if stage == 1 and enemy.id == 0: grant_blueprint("kennel", enemy.pos)
				release_keeper(enemy)
				say("侵入者を追い返した！")
			else:
				enemy.attacker = a.id
				enemy.threat_until = tick + ceili(Rules.KIDNAPPER.counter_duration / DT)
	elif a.mode in ["wander", "auto"]:
		a.state = "徘徊"
		if tick % 12 == 0:
			var options = neighbors(a.pos).filter(func(p): return walkable(p) and distance(p, a.home) <= 3)
			if not options.is_empty(): a.order = options[rng.randi_range(0, options.size() - 1)]
		goal = a.order
	else:
		a.ai_context = "idle"
		a.state = "待機" if a.mode == "stay" else "見張り"
		a.stamina = minf(100, a.stamina + (1.6 if campaign.shelter and distance(a.pos, nest) <= 3 else 0.3))
	a.move_credit = minf(1.75, a.move_credit + Rules.SHIBA.speed * DT * (Rules.SHIBA.rescue_multiplier if a.rescuing else 1.0))
	if a.move_credit >= 1 and distance(a.pos, goal) > (1 if chasing else 0):
		a.move_credit -= 1
		var move = next_step(a.pos, goal)
		if move != a.pos and kennel_owner(move) in [-1, a.id]:
			a.pos = move
			a.stamina = maxf(0, a.stamina - 0.65)
	else:
		a.move_credit = minf(a.move_credit, 0.75)

func kennel_owner(p: Vector2i) -> int:
	if not structures.has(p) or structures[p].kind != "kennel": return -1
	for dog in animals:
		if dog.category == "dog" and dog.placed and dog.hp > 0 and (dog.kennel_id == structures[p].id or dog.pos == p): return dog.id
	return -1

func release_kennel(a: Dictionary):
	a.kennel_id = -1

func kennel_cell(a: Dictionary) -> Vector2i:
	for p in structures:
		if structures[p].id == a.kennel_id and structures[p].status == "ready" and structures[p].kind == "kennel": return p
	return Vector2i(-1, -1)

func rest_step(a: Dictionary, explicit: bool):
	var destination = kennel_cell(a)
	if a.kennel_id >= 0 and (destination.x < 0 or (a.rest_settled and a.pos != destination)):
		release_kennel(a)
		a.rest_settled = true
	if not a.rest_settled and a.kennel_id < 0:
		var options = structures.keys().filter(func(p): return structures[p].kind == "kennel" and structures[p].status == "ready" and distance(a.pos, p) <= Rules.REST.nearby and kennel_owner(p) in [-1, a.id] and (p == a.pos or (not occupied(p) and next_step(a.pos, p) != a.pos)))
		options.sort_custom(func(p, q): return distance(a.pos, p) < distance(a.pos, q) if distance(a.pos, p) != distance(a.pos, q) else structures[p].id < structures[q].id)
		if not options.is_empty():
			destination = options[0]
			a.kennel_id = structures[destination].id # Reserve also while approaching: never double book.
		else: a.rest_settled = true
	if a.kennel_id >= 0 and a.pos != destination:
		a.state = "小屋へ休養"
		a.rest_ticks = 0
		a.move_credit += Rules.SHIBA.speed * DT
		if a.move_credit >= 1:
			a.move_credit -= 1
			var next = next_step(a.pos, destination)
			if next == a.pos or kennel_owner(next) not in [-1, a.id]:
				release_kennel(a)
				a.rest_settled = true
			else: a.pos = next
		return
	a.rest_settled = true
	a.state = "休む" if explicit else "自主休養"
	a.stamina = minf(100, a.stamina + 0.8)
	a.rest_ticks += 1
	if a.rest_ticks >= ceili(Rules.REST.seconds / DT):
		a.hp = mini(a.max_hp, a.hp + 1)
		a.rest_ticks = 0

func kennel_heal_step(a: Dictionary):
	var house = structures.get(a.pos, {})
	if not a.placed or a.hp <= 0 or a.category != "dog" or house.get("kind") != "kennel" or house.get("status") != "ready" or kennel_owner(a.pos) != a.id:
		a.healing_kennel = -1
		a.kennel_ticks = 0
		return
	if a.healing_kennel != house.id:
		a.healing_kennel = house.id
		a.kennel_ticks = 0
	a.kennel_ticks += 1
	if a.kennel_ticks >= ceili(Rules.REST.kennel_seconds / DT):
		a.hp = mini(a.max_hp, a.hp + 1)
		a.kennel_ticks = 0

func side_step(p: Vector2i, goal: Vector2i, roll: float) -> Vector2i:
	var options = neighbors(p).filter(func(n): return walkable(n) and not occupied(n) and distance(n, goal) <= distance(p, goal) + 1)
	if options.is_empty(): return p
	return options[mini(int(roll * options.size()), options.size() - 1)]

func enemy_step(e: Dictionary):
	if e.done: return
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
				keeper.state = "free"
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
				if tick >= e.next_attack:
					e.next_attack = tick + ceili(e.counter_seconds / DT)
					var previous_hp: int = target.hp
					target.hp = maxi(0, target.hp - e.attack_power)
					if previous_hp > target.max_hp * Rules.LOW_HP_FRACTION and target.hp <= target.max_hp * Rules.LOW_HP_FRACTION:
						milestones.append({"tick": tick, "kind": "animal_danger", "id": target.id})
					combat_log.append({"tick": tick, "source": "enemy", "id": e.id, "target": target.id, "damage": e.attack_power})
			elif tick % 3 == 0:
				move_enemy(e, next_step(e.pos, target.pos, true))
			return
	var interval = 4 if e.carry == "keeper" else 3
	if tick % interval != 0: return
	var goal = RaiderAI.target(e, self)
	if e.pos == goal:
		if e.flee:
			e.done = true
			metrics.repelled += 1
			metrics.coins += 3
			return
		if e.carry == "keeper":
			e.done = true
			keeper.state = "abducted"
			finish(false)
			return
		if keeper.carrier < 0:
			e.capture_progress += 1
			if e.capture_progress == 1:
				keeper.state = "restrained"
				keeper.restrainer = e.id
				milestones.append({"tick": tick, "kind": "restrained", "id": e.id})
			e.state = "拘束中"
			if e.capture_progress >= 2:
				e.carry = "keeper"
				keeper.carrier = e.id
				keeper.state = "captured"
				metrics.captures += 1
				milestones.append({"tick": tick, "kind": "carried", "id": e.id})
				say("連れ去り中！ 犬で追い返すと救出できます。")
		return
	e.capture_progress = 0
	var next = next_step(e.pos, goal, true)
	if not e.flee and e.get("intent", "") == "detour" and not e.side_step_used:
		next = side_step(e.pos, goal, e.intent_roll)
		e.side_step_used = true
	move_enemy(e, next)

func move_enemy(e: Dictionary, next: Vector2i):
	# Living animals occupy space; carrying the keeper is the only deliberate actor overlap.
	var defenders = animals.filter(func(a): return a.placed and a.hp > 0 and a.pos == next)
	if not e.flee and not defenders.is_empty():
		e.attacker = defenders[0].id
		e.threat_until = tick + ceili(Rules.KIDNAPPER.counter_duration / DT)
		return
	if blocks(next):
		var b = structures[next]
		var damage = maxi(0, e.object_attack_power - b.armor)
		var applied = mini(b.hp, damage)
		b.hp -= applied
		metrics.structure_damage += applied
		combat_log.append({"tick": tick, "source": "object", "id": e.id, "target": b.id, "damage": applied})
		e.state = "門を壊す" if b.kind == "gate" else "壁を壊す"
		if b.hp <= 0:
			b.status = "destroyed"
			metrics.destroyed += 1
			say("施設が破壊された。土で建て直せます。")
	else:
		if tick < e.move_stopped_until and next != e.pos: return
		e.pos = next
		e.path.append(next)
		interrupt_site(next)
		e.state = "退散" if e.flee else ("反撃" if e.counter_target >= 0 else ("連れ去り" if e.carry == "keeper" else "主人公へ"))
		if e.carry == "keeper":
			keeper.pos = e.pos
			if not inside(e.pos):
				e.done = true
				keeper.state = "abducted"
				finish(false)

func interrupt_site(p: Vector2i):
	if structures.has(p) and structures[p].status == "building":
		structures[p].status = "interrupted"
		add_resource(structures[p].get("resource", "soil"), floori(structures[p].cost * Rules.INTERRUPT_REFUND))
		metrics.interrupted += 1
		say("建設中断：接触により建築素材を半分返却。")

func construction_step():
	# Actors move first: entry on the completion tick always interrupts, never entombs actors.
	for p in structures:
		var b = structures[p]
		if b.status != "building": continue
		if occupied(p):
			interrupt_site(p)
			continue
		b.remaining -= 1
		if b.remaining <= 0:
			b.status = "ready"
			b.hp = b.max_hp
			metrics.built += 1

func dismantle_quote(p: Vector2i) -> int:
	if not live_structure(p): return 0
	var b = structures[p]
	return floori(b.cost * clampf(float(b.hp) / b.max_hp, 0, 1) * Rules.DISMANTLE_REFUND)

func repair_quote(p: Vector2i) -> Dictionary:
	if not structures.has(p) or structures[p].status != "ready": return {"hp": 0, "cost": 0}
	var b = structures[p]
	var unit_cost: float = b.cost * Rules.REPAIR_FACTOR / b.max_hp
	var recovery = mini(b.max_hp - b.hp, floori(resource_amount(b.get("resource", "soil")) / unit_cost))
	return {"hp": recovery, "cost": ceili(recovery * unit_cost)}

func repair(p: Vector2i) -> bool:
	if phase != "defend" or paused: return false
	var quote = repair_quote(p)
	if quote.hp <= 0: return false
	add_resource(structures[p].get("resource", "soil"), -quote.cost)
	structures[p].hp += quote.hp
	metrics.repaired += quote.hp
	var resource = structures[p].get("resource", "soil")
	metrics[resource + "_repair"] = metrics.get(resource + "_repair", 0) + quote.cost
	return true

func persist_farm():
	campaign.resources = resource_snapshot()
	campaign.next_structure_id = next_structure_id
	campaign.facilities = []
	for p in structures:
		var b = structures[p].duplicate(true)
		b.pos = [p.x, p.y]
		campaign.facilities.append(b)

func step():
	if phase != "defend" or paused: return
	tick += 1
	if tick % ceili(Rules.NATURE.interval / DT) == 0: grow_nature()
	command_power = minf(10, command_power + 0.07)
	foods = foods.filter(func(f): return f.until > tick)
	while schedule_index < spawn_schedule.size() and tick >= spawn_schedule[schedule_index].tick:
		spawn_enemy(spawn_schedule[schedule_index])
		schedule_index += 1
	if config.repeat_waves and schedule_index == spawn_schedule.size():
		schedule_cycle += 1
		make_schedule()
	for a in animals:
		animal_step(a)
		kennel_heal_step(a)
		interrupt_site(a.pos)
		if a.path.back() != a.pos: a.path.append(a.pos)
	for e in enemies:
		enemy_step(e)
		if phase != "defend": break
	if phase == "defend": construction_step()
	if tick % 8 == 0:
		traces.append({"tick": tick, "stamina": snappedf(animals[0].stamina, 0.1), "eggs": eggs,
			"materials": materials, "keeper": keeper.state, "structures": structures.size()})
	if phase != "defend": return
	if config.repeat_waves and tick * DT >= config.time_limit_seconds:
		finish(true)
		say("継続襲来を守りきりました。")
	elif not config.repeat_waves and schedule_index == spawn_schedule.size() and enemies.all(func(e): return e.done):
		finish(true)

func finish(won: bool):
	if result != "": return
	result = "win" if won else "loss"
	phase = "shop" if won else "result"
	paused = false
	var condition = float(animals[0].hp) / animals[0].max_hp
	var rating = (35 if won else 0) + maxi(0, 25 - metrics.captures * 8) + roundi(condition * 20) + maxi(0, 10 - metrics.structure_damage / 3) + maxi(0, 10 - int(metrics.commands / 3))
	var xp = 16 + rating / 10 if won else 0
	var gold = (32 + rating / 5 + metrics.coins) if won else 0
	score = {"rating": rating, "xp": int(xp), "gold": int(gold), "seconds": tick * DT, "condition": roundi(condition * 100), "time_bonus": 0}
	heal_with_mushrooms()
	for owned in campaign.animals:
		for a in animals:
			if a.id == owned.id: owned.hp = a.hp
	if won:
		persist_farm()
		campaign.gold += int(gold)
		campaign.eggs += eggs
		eggs = 0
		for owned in campaign.animals:
			if not animals.any(func(a): return a.id == owned.id and a.placed): continue
			owned.xp += int(xp)
			while owned.xp >= owned.lv * 20:
				owned.xp -= owned.lv * 20
				owned.lv += 1
			for a in animals:
				if a.id == owned.id:
					a.lv = owned.lv
					a.xp = owned.xp
		shop_stock = Shop.generate(stage, seed_value, campaign.unlocked_blueprints)
	say("防衛成功！ 育成と購入をして次の日へ。")

func next_campaign() -> Dictionary:
	var data = campaign.duplicate(true)
	data.stage = 2
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
	return {"seed": seed_value, "stage": stage, "tick": tick, "phase": phase, "paused": paused, "result": result,
		"initial_campaign": checkpoint.duplicate(true),
		"campaign": campaign.duplicate(true), "animals": positions, "raiders": raiders, "keeper": owner,
		"metrics": metrics.duplicate(true), "score": score.duplicate(true), "structures": built, "materials": materials,
		"combat": combat_log.duplicate(true), "resources": resource_snapshot(), "shop_stock": shop_stock.duplicate(true), "shop_log": shop_log.duplicate(true), "actions": actions.duplicate(true), "samples": traces.duplicate(true), "schedule": schedule,
		"ai_settings": Rules.AI, "decision_log": decision_log.duplicate(true), "decision_count": decision_count, "decision_counts": decision_counts.duplicate(true),
		"bark_settings": Rules.BARK, "skill_log": skill_log.duplicate(true), "nature_settings": nature_config,
		"natural": natural.keys().map(func(p): return {"pos": [p.x, p.y], "kind": natural[p]}), "mushrooms": campaign.mushrooms,
		"initial_positions": initial_positions.duplicate(true), "milestones": milestones.duplicate(true), "stage_config": config.duplicate(true), "eggs": eggs, "command_power": command_power}

func try_bark(a: Dictionary):
	if a.mode == "rest": return
	if tick < a.next_bark: return
	var nearby = enemies.filter(func(e): return not e.done and not e.flee and distance(a.pos, e.pos) <= Rules.SHIBA.detection_range)
	if nearby.is_empty(): return
	a.next_bark = tick + ceili(Rules.BARK.cooldown / DT)
	a.last_bark = tick
	var targets = []
	for enemy in nearby:
		if distance(a.pos, enemy.pos) <= Rules.BARK.range:
			enemy.move_stopped_until = maxi(enemy.move_stopped_until, tick + ceili(Rules.BARK.stop_seconds / DT))
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
	if id in campaign.unlocked_blueprints: return
	campaign.unlocked_blueprints.append(id)
	campaign.items[id + "_plan"] = campaign.items.get(id + "_plan", 0) + 1
	milestones.append({"tick": tick, "kind": "blueprint", "id": id, "pos": [p.x, p.y]})

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
			if walkable(p) and not occupied(p) and not live_structure(p) and not natural.has(p) and p not in entries and not (has_nest() and p == nest): sites.append(p)
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
	if phase != "shop" or paused or not Shop.table().has(id): return false
	var product = Shop.table()[id]
	var available = shop_stock.filter(func(row): return row.product == id and row.remaining > 0)
	if available.is_empty() or campaign.gold < product.BuyPrice: return false
	var row = available[0]
	campaign.gold -= product.BuyPrice
	row.remaining -= 1
	if product.Category == "animals":
		var next_id = 1
		for a in campaign.animals: next_id = maxi(next_id, a.id + 1)
		campaign.animals.append({"id": next_id, "category": "dog" if id == "shiba" else "bird", "species": id, "lv": 1, "xp": 0, "loyalty": row.individual.loyalty, "traits": {}})
	elif product.Category == "materials": add_resource(id, product.Amount)
	else: add_item(id, product.Amount)
	shop_log.append({"side": "buy", "product": id, "amount": product.Amount, "gold": -product.BuyPrice})
	return true

func sell(id: String, animal_id: int = -1) -> bool:
	if phase != "shop" or paused or not Shop.table().has(id): return false
	var p = Shop.table()[id]
	if p.Category == "animals":
		var found = campaign.animals.filter(func(a): return a.id == animal_id and a.species == id)
		if found.is_empty() or campaign.animals.size() <= 1: return false
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
