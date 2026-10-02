extends RefCounted
## Deterministic fixed-tick rules. No scene, Input, frame clock or rendering dependencies.
const RaiderAI = preload("res://game/raider_ai.gd")
const StageData = preload("res://game/stages.gd")
const W = 25
const H = 17
const DT = 0.25
const NEST = Vector2i(20, 12)
const PRICES = {"hen": 30, "feed": 8, "shelter": 28, "fence": 24, "soil": 15}
const Rules = preload("res://game/rules.gd")
const BUILD = Rules.BUILD
const ORDERS = ["auto", "stay", "wander", "attack_target", "whistle"]
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
var materials = 100 # Soil only; Gold is never spent by construction or repair.
var next_structure_id = 1
var combat_log: Array = []
var structures: Dictionary = {}
var keeper = {"pos": Vector2i(19, 8), "placed": false, "carrier": -1, "state": "free"}
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
	"captures": 0, "rescues": 0, "built": 0, "destroyed": 0, "orders": 0, "interrupted": 0, "repaired": 0, "soil_repair": 0}

static func new_campaign() -> Dictionary:
	return {"stage": 1, "gold": 12, "feed": 4, "eggs": 0, "shelter": false,
		"fence": 0, "resources": {"soil": 100}, "facilities": [], "next_structure_id": 1, "animals": [{"id": 1, "category": "dog", "species": "shiba", "lv": 1, "xp": 0, "loyalty": 75}]}

func _init(data: Dictionary = {}, seed_number: int = 17, stage_override: Dictionary = {}):
	campaign = new_campaign() if data.is_empty() else data.duplicate(true)
	checkpoint = campaign.duplicate(true)
	stage = campaign.stage
	seed_value = seed_number
	rng.seed = seed_number
	config = (StageData.STAGES[stage] if stage_override.is_empty() else stage_override).duplicate(true)
	materials = campaign.get("resources", {"soil": 100}).soil
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
		a.pos = Vector2i(17, 8) if a.species == "shiba" else nest
		a.home = a.pos
		a.stamina = 100.0
		a.max_hp = Rules.SHIBA.max_hp if a.species == "shiba" else 20
		a.hp = a.max_hp
		a.attack_power = Rules.SHIBA.attack_power if a.species == "shiba" else 0
		a.next_attack = 0
		a.move_credit = 0.0
		a.rescuing = false
		a.fear = 0
		a.order_until = 0
		a.order = a.pos
		a.mode = "auto"
		a.pending = {}
		a.target_id = -1
		a.state = "見張り" if a.species == "shiba" else "ついばむ"
		a.path = [a.pos]
		animals.append(a)
	say("牧場主の位置を選んで、時計を動かそう。")

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
	return structures.has(p) and structures[p].status == "ready" and not structures[p].open

func live_structure(p: Vector2i) -> bool:
	return structures.has(p) and structures[p].status in ["ready", "building"]

func occupied(p: Vector2i) -> bool:
	return p == keeper.pos or animals.any(func(a): return a.pos == p) or enemies.any(func(e): return not e.done and e.pos == p) or foods.any(func(f): return f.pos == p)

func has_nest() -> bool:
	return campaign.animals.any(func(a): return a.species == "hen")

func can_build(kind: String, p: Vector2i) -> bool:
	return phase == "defend" and not paused and BUILD.has(kind) and inside(p) and p not in entries and not (p == nest and has_nest()) and not occupied(p) and not live_structure(p) and materials >= BUILD[kind].cost

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

func act(kind: String, p: Vector2i = Vector2i.ZERO) -> bool:
	var accepted = false
	if phase == "prepare":
		if kind == "place" and walkable(p) and neighbors(p).any(func(n): return walkable(n)) and p not in entries and not (p == nest and has_nest()):
			keeper.pos = p
			keeper.placed = true
			var nearby = [p + Vector2i.LEFT, p + Vector2i.RIGHT, p + Vector2i.UP, p + Vector2i.DOWN].filter(func(n): return walkable(n))
			animals[0].pos = nearby[0]
			animals[0].home = animals[0].pos
			animals[0].path = [animals[0].pos]
			accepted = true
		elif kind == "start" and keeper.placed:
			phase = "defend"
			say("時計開始。襲来前に壁・門を築こう。")
			accepted = true
	elif phase == "defend":
		if kind == "pause":
			paused = not paused
			accepted = true
		elif kind in ORDERS:
			accepted = issue_order(kind, p)
		elif not paused:
			if BUILD.has(kind):
				if can_build(kind, p):
					materials -= BUILD[kind].cost
					var hp: int = BUILD[kind].hp + (campaign.fence * 4 if kind == "build_gate" else 0)
					structures[p] = {"id": next_structure_id, "kind": "gate" if kind == "build_gate" else "wall",
						"hp": 0, "max_hp": hp, "armor": 0, "open": false, "cost": BUILD[kind].cost,
						"status": "building", "remaining": ceili(BUILD[kind].seconds / DT), "total_ticks": ceili(BUILD[kind].seconds / DT)}
					next_structure_id += 1
					accepted = true
			elif kind == "gate" and live_structure(p) and structures[p].status == "ready" and structures[p].kind == "gate" and not occupied(p):
				structures[p].open = not structures[p].open
				accepted = true
			elif kind == "repair":
				accepted = repair(p)
			elif kind == "remove" and live_structure(p) and not occupied(p):
				materials += floori(structures[p].cost * 0.5 * structures[p].hp / structures[p].max_hp)
				structures[p].status = "removed"
				structures[p].hp = 0
				accepted = true
			elif kind == "feed" and walkable(p) and command_power >= 3 and campaign.feed > 0:
				campaign.feed -= 1
				command_power -= 3
				metrics.commands += 3
				foods.append({"pos": p, "until": tick + 64})
				accepted = true
			elif kind == "collect" and p == nest and eggs > 0:
				campaign.eggs += eggs
				metrics.eggs_collected += eggs
				eggs = 0
				accepted = true
	actions.append({"tick": tick, "kind": kind, "pos": [p.x, p.y], "accepted": accepted, "paused": paused})
	return accepted

func issue_order(kind: String, p: Vector2i) -> bool:
	var target_id = -1
	if kind == "attack_target":
		var found = enemies.filter(func(e): return not e.done and not e.flee and e.pos == p)
		if found.is_empty(): return false
		target_id = found[0].id
	elif kind in ["whistle", "stay", "wander"] and not walkable(p): return false
	var accepted = false
	for a in animals:
		if a.loyalty <= 0: continue
		# Paused orders change intent only. Their reaction countdown starts with resumed simulation.
		a.pending = {"kind": kind, "pos": p, "target_id": target_id,
			"at": tick + 1 + ceili((100 - a.loyalty) / 25.0)}
		accepted = true
	if accepted: metrics.orders += 1
	return accepted

func spawn_enemy(event: Dictionary):
	var entry: Vector2i = event.entry
	var origin = exit_for(entry) if blocks(entry) else entry
	enemies.append({"id": spawned, "pos": origin, "entry": entry, "lv": event.get("lv", 1), "hp": Rules.KIDNAPPER.max_hp, "max_hp": Rules.KIDNAPPER.max_hp,
		"attack_power": Rules.KIDNAPPER.attack_power, "object_attack_power": Rules.KIDNAPPER.object_attack_power,
		"counter_target": -1, "counter_until": 0, "counter_ready": 0, "next_attack": 0,
		"flee": false, "carry": "", "done": false, "capture_progress": 0,
		"born": tick, "path": [origin], "role": event.role, "state": "主人公へ"})
	spawned += 1
	say("入口から誘拐役！ 牧場主を守ろう。")

func release_keeper(e: Dictionary):
	if e.carry == "keeper":
		e.carry = ""
		keeper.carrier = -1
		keeper.state = "free"
		keeper.pos = e.pos
		metrics.rescues += 1
		say("救出！ 牧場主はその場で待っています。")

func animal_step(a: Dictionary):
	if a.hp <= 0:
		a.state = "休養中"
		a.rescuing = false
		return
	if not a.pending.is_empty() and tick >= a.pending.at:
		a.mode = a.pending.kind
		a.order = a.pending.pos
		a.target_id = a.pending.target_id
		if a.mode in ["stay", "wander", "whistle"]: a.home = a.order
		a.order_until = tick + 40 + a.loyalty * 2
		a.pending = {}
	if tick >= a.order_until: a.mode = "auto"
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
	var carrier = enemies.filter(func(e): return not e.done and not e.flee and e.carry == "keeper")
	a.rescuing = not carrier.is_empty()
	var targets = enemies.filter(func(e): return not e.done and not e.flee and distance(a.pos, e.pos) <= 4)
	targets.sort_custom(func(e, f): return distance(a.pos, e.pos) < distance(a.pos, f.pos))
	if a.mode == "attack_target":
		var selected = enemies.filter(func(e): return e.id == a.target_id and not e.done and not e.flee)
		if not selected.is_empty(): targets = selected
		else: a.mode = "auto"
	if a.rescuing: targets = carrier
	var goal: Vector2i = a.home
	var chasing = false
	var food = foods.filter(func(f): return distance(a.pos, f.pos) <= 8)
	if not a.rescuing and not food.is_empty() and a.stamina < 68:
		goal = food[0].pos
		a.state = "餌へ"
		if a.pos == goal:
			a.stamina = minf(100, a.stamina + 48)
			foods.erase(food[0])
			metrics.fed += 1
	elif not a.rescuing and a.mode == "whistle" and a.pos != a.order:
		goal = a.order
		a.state = "呼び戻し"
	elif not a.rescuing and a.stamina < 14:
		a.state = "ひと休み"
		a.stamina = minf(100, a.stamina + 0.8)
		return
	elif not targets.is_empty() and (a.rescuing or a.mode != "stay" or distance(a.pos, targets[0].pos) <= 1):
		chasing = true
		goal = targets[0].pos
		a.state = "救出本能" if a.rescuing else "追跡"
		if distance(a.pos, goal) <= 1 and tick >= a.next_attack:
			a.next_attack = tick + ceili(Rules.SHIBA.attack_seconds / DT)
			a.stamina = maxf(0, a.stamina - 8)
			var enemy = targets[0]
			enemy.hp = maxi(0, enemy.hp - a.attack_power)
			combat_log.append({"tick": tick, "source": "animal", "id": a.id, "target": enemy.id, "damage": a.attack_power})
			metrics.barks += 1
			if enemy.hp == 0:
				enemy.flee = true
				release_keeper(enemy)
				say("侵入者を追い返した！")
			elif tick >= enemy.counter_ready and enemy.counter_target < 0:
				enemy.counter_target = a.id
				enemy.counter_until = tick + ceili(Rules.KIDNAPPER.counter_duration / DT)
	elif a.mode == "wander":
		a.state = "徘徊"
		if tick % 12 == 0:
			var options = neighbors(a.pos).filter(func(p): return walkable(p) and distance(p, a.home) <= 3)
			if not options.is_empty(): a.order = options[rng.randi_range(0, options.size() - 1)]
		goal = a.order
	else:
		a.state = "待機" if a.mode == "stay" else "見張り"
		a.stamina = minf(100, a.stamina + (1.6 if campaign.shelter and distance(a.pos, nest) <= 3 else 0.3))
	a.move_credit = minf(1.75, a.move_credit + Rules.SHIBA.speed * DT * (Rules.SHIBA.rescue_multiplier if a.rescuing else 1.0))
	if a.move_credit >= 1 and distance(a.pos, goal) > (1 if chasing else 0):
		a.move_credit -= 1
		var move = next_step(a.pos, goal)
		if move != a.pos:
			a.pos = move
			a.stamina = maxf(0, a.stamina - 0.65)
	else:
		a.move_credit = minf(a.move_credit, 0.75)

func enemy_step(e: Dictionary):
	if e.done: return
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
					e.next_attack = tick + ceili(Rules.KIDNAPPER.counter_seconds / DT)
					target.hp = maxi(0, target.hp - e.attack_power)
					combat_log.append({"tick": tick, "source": "enemy", "id": e.id, "target": target.id, "damage": e.attack_power})
			elif tick % 3 == 0:
				move_enemy(e, next_step(e.pos, target.pos, true))
			return
	# Lv1 occasionally hesitates while approaching, but does not stagger when hit.
	if not e.flee and e.carry == "" and tick % 24 == 0: return
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
			e.state = "拘束中"
			if e.capture_progress >= 2:
				e.carry = "keeper"
				keeper.carrier = e.id
				keeper.state = "captured"
				metrics.captures += 1
				say("連れ去り中！ 犬で追い返すと救出できます。")
		return
	e.capture_progress = 0
	var next = next_step(e.pos, goal, true)
	move_enemy(e, next)

func move_enemy(e: Dictionary, next: Vector2i):
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
		materials += floori(structures[p].cost * Rules.INTERRUPT_REFUND)
		metrics.interrupted += 1
		say("建設中断：接触により土を半分返却。")

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

func repair(p: Vector2i) -> bool:
	if phase != "defend" or paused: return false
	if not structures.has(p) or structures[p].status != "ready": return false
	var b = structures[p]
	var unit_cost: float = b.cost * Rules.REPAIR_FACTOR / b.max_hp
	var recovery = mini(b.max_hp - b.hp, floori(materials / unit_cost))
	if recovery <= 0: return false
	var cost = ceili(recovery * unit_cost)
	materials -= cost
	b.hp += recovery
	metrics.repaired += recovery
	metrics.soil_repair += cost
	return true

func persist_farm():
	campaign.resources = {"soil": materials}
	campaign.next_structure_id = next_structure_id
	campaign.facilities = []
	for p in structures:
		var b = structures[p].duplicate(true)
		b.pos = [p.x, p.y]
		campaign.facilities.append(b)

func step():
	if phase != "defend" or paused: return
	tick += 1
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
		interrupt_site(a.pos)
		if a.path.back() != a.pos: a.path.append(a.pos)
	for e in enemies:
		enemy_step(e)
		if phase == "result": break
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
	phase = "result"
	paused = false
	var condition = float(animals[0].hp) / animals[0].max_hp
	var rating = (35 if won else 0) + maxi(0, 25 - metrics.captures * 8) + roundi(condition * 20) + maxi(0, 10 - metrics.structure_damage / 3) + maxi(0, 10 - int(metrics.commands / 3))
	var xp = 16 + rating / 10 if won else 0
	var gold = (32 + rating / 5 + metrics.coins) if won else 0
	score = {"rating": rating, "xp": int(xp), "gold": int(gold), "seconds": tick * DT, "condition": roundi(condition * 100), "time_bonus": 0}
	if won:
		persist_farm()
		campaign.gold += int(gold)
		campaign.eggs += eggs
		eggs = 0
		for owned in campaign.animals:
			owned.xp += int(xp)
			while owned.xp >= owned.lv * 20:
				owned.xp -= owned.lv * 20
				owned.lv += 1
			for a in animals:
				if a.id == owned.id:
					a.lv = owned.lv
					a.xp = owned.xp
		say("防衛成功！ 育成と購入をして次の日へ。")

func buy(kind: String) -> bool:
	if result != "win" or paused: return false
	if kind == "sell_egg" and campaign.eggs > 0:
		campaign.eggs -= 1
		campaign.gold += 9
		return true
	if kind == "cook_egg" and campaign.eggs > 0:
		campaign.eggs -= 1
		campaign.feed += 2
		return true
	if not PRICES.has(kind) or campaign.gold < PRICES[kind]: return false
	if kind == "hen" and campaign.animals.size() >= 2: return false
	if kind == "shelter" and campaign.shelter: return false
	if kind == "fence" and campaign.fence >= 1: return false
	campaign.gold -= PRICES[kind]
	match kind:
		"hen": campaign.animals.append({"id": 2, "category": "bird", "species": "hen", "lv": 1, "xp": 0, "loyalty": 0})
		"feed": campaign.feed += 3
		"shelter": campaign.shelter = true
		"fence": campaign.fence += 1
		"soil":
			materials += Rules.SOIL_PACK
			campaign.resources.soil = materials
	return true

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
		"campaign": campaign.duplicate(true), "animals": positions, "raiders": raiders, "keeper": owner,
		"metrics": metrics.duplicate(true), "score": score.duplicate(true), "structures": built, "materials": materials,
		"combat": combat_log.duplicate(true), "resources": {"soil": materials}, "actions": actions.duplicate(true), "samples": traces.duplicate(true), "schedule": schedule,
		"stage_config": config.duplicate(true), "eggs": eggs, "command_power": command_power}
