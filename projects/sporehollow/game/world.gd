extends RefCounted
## Deterministic fixed-tick rules. No scene, Input, frame clock or rendering dependencies.
const RaiderAI = preload("res://game/raider_ai.gd")
const StageData = preload("res://game/stages.gd")
const W = 25
const H = 17
const DT = 0.25
const NEST = Vector2i(20, 12)
const PRICES = {"hen": 30, "feed": 8, "shelter": 28, "fence": 24}
const BUILD = {"wall": {"cost": 3, "hp": 8}, "build_gate": {"cost": 5, "hp": 6}}
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
var materials = 60
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
	"captures": 0, "rescues": 0, "built": 0, "destroyed": 0, "orders": 0}

static func new_campaign() -> Dictionary:
	return {"stage": 1, "gold": 12, "feed": 4, "eggs": 0, "shelter": false,
		"fence": 0, "animals": [{"id": 1, "category": "dog", "species": "shiba", "lv": 1, "xp": 0, "loyalty": 75}]}

func _init(data: Dictionary = {}, seed_number: int = 17, stage_override: Dictionary = {}):
	campaign = new_campaign() if data.is_empty() else data.duplicate(true)
	checkpoint = campaign.duplicate(true)
	stage = campaign.stage
	seed_value = seed_number
	rng.seed = seed_number
	config = (StageData.STAGES[stage] if stage_override.is_empty() else stage_override).duplicate(true)
	materials = config.materials
	for wave in config.waves:
		for cell in wave.entries:
			var p = Vector2i(cell[0], cell[1])
			if p not in entries: entries.append(p)
	make_schedule()
	for owned in campaign.animals:
		var a = owned.duplicate(true)
		a.loyalty = a.get("loyalty", 0)
		a.pos = Vector2i(17, 8) if a.species == "shiba" else nest
		a.home = a.pos
		a.stamina = 100.0
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
				"entry": Vector2i(cell[0], cell[1]), "morale": wave.morale})
	spawn_schedule.sort_custom(func(a, b): return a.tick < b.tick)

func next_attack_seconds() -> float:
	return maxf(0, (spawn_schedule[schedule_index].tick - tick) * DT) if schedule_index < spawn_schedule.size() else -1.0

func say(message: String):
	events.append({"tick": tick, "text": message})
	if events.size() > 5: events.pop_front()

func inside(p: Vector2i) -> bool:
	return p.x >= 1 and p.x < W - 1 and p.y >= 1 and p.y < H - 1

func walkable(p: Vector2i) -> bool:
	return inside(p) and (not structures.has(p) or structures[p].open)

func occupied(p: Vector2i) -> bool:
	return p == keeper.pos or animals.any(func(a): return a.pos == p) or enemies.any(func(e): return not e.done and e.pos == p) or foods.any(func(f): return f.pos == p)

func has_nest() -> bool:
	return campaign.animals.any(func(a): return a.species == "hen")

func can_build(kind: String, p: Vector2i) -> bool:
	return phase == "defend" and not paused and BUILD.has(kind) and inside(p) and p not in entries and not (p == nest and has_nest()) and not occupied(p) and not structures.has(p) and materials >= BUILD[kind].cost

func neighbors(p: Vector2i) -> Array:
	return [p + Vector2i.RIGHT, p + Vector2i.LEFT, p + Vector2i.UP, p + Vector2i.DOWN]

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
			var exit_cell = raider and n == goal and n.x == 0 and Vector2i(1, n.y) in entries
			if not inside(n) and not exit_cell: continue
			var blocked = structures.has(n) and not structures[n].open
			if blocked and not raider: continue
			# Attacking consumes the same action cadence as moving: actual remaining HP is the breach cost.
			var value: float = cost[p] + 1.0 + (structures[n].hp if blocked else 0)
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
		if kind == "place" and inside(p) and p not in entries and not (p == nest and has_nest()):
			keeper.pos = p
			keeper.placed = true
			animals[0].pos = p + (Vector2i.LEFT if p.x > 1 else Vector2i.RIGHT)
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
					structures[p] = {"kind": "gate" if kind == "build_gate" else "wall", "hp": hp, "max_hp": hp, "open": false, "cost": BUILD[kind].cost}
					metrics.built += 1
					accepted = true
			elif kind == "gate" and structures.has(p) and structures[p].kind == "gate" and not occupied(p):
				structures[p].open = not structures[p].open
				accepted = true
			elif kind == "remove" and structures.has(p) and not occupied(p):
				materials += floori(structures[p].cost * 0.5 * structures[p].hp / structures[p].max_hp)
				structures.erase(p)
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
	enemies.append({"id": spawned, "pos": entry, "entry": entry, "morale": event.morale,
		"flee": false, "carry": "", "done": false, "capture_progress": 0,
		"born": tick, "path": [entry], "role": event.role, "state": "主人公へ"})
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
		if not threat.is_empty():
			a.fear = 28
			a.state = "怖がる"
			if tick % 3 == 0:
				var options = neighbors(a.pos).filter(func(p): return walkable(p))
				if not options.is_empty():
					options.sort_custom(func(p, q): return distance(p, threat[0].pos) > distance(q, threat[0].pos))
					a.pos = options[0]
		else:
			a.fear = maxi(0, a.fear - 1)
			a.state = "落ち着く" if a.fear > 0 else "卵を育てる"
			if tick % 4 == 0: a.pos = next_step(a.pos, nest)
			if tick % maxi(24, 40 - (a.lv - 1) * 4) == 0 and a.fear == 0 and eggs < 8:
				eggs += 1
				metrics.eggs_produced += 1
		return
	var food = foods.filter(func(f): return distance(a.pos, f.pos) <= 8)
	var targets = enemies.filter(func(e): return not e.done and not e.flee and distance(a.pos, e.pos) <= 4 + a.lv / 3)
	targets.sort_custom(func(e, f): return distance(a.pos, e.pos) < distance(a.pos, f.pos))
	if a.mode == "attack_target":
		var selected = enemies.filter(func(e): return e.id == a.target_id and not e.done and not e.flee)
		if not selected.is_empty(): targets = selected
		else: a.mode = "auto"
	var goal: Vector2i = a.home
	var chasing = false
	if not food.is_empty() and a.stamina < 68:
		goal = food[0].pos
		a.state = "餌へ"
		if a.pos == goal:
			a.stamina = minf(100, a.stamina + 48)
			foods.erase(food[0])
			metrics.fed += 1
	elif a.stamina < 14:
		a.state = "ひと休み"
		a.stamina = minf(100, a.stamina + 0.8)
		return
	elif not targets.is_empty() and (a.mode != "stay" or distance(a.pos, targets[0].pos) <= 1):
		chasing = true
		goal = targets[0].pos if a.mode != "stay" else a.pos
		a.state = "追跡" if a.mode != "stay" else "待機"
		if distance(a.pos, targets[0].pos) <= 1 and tick % 5 == 0:
			a.stamina -= 12.0 - minf(a.lv, 4)
			targets[0].morale -= 1
			metrics.barks += 1
			a.state = "吠える！"
			if targets[0].morale <= 0:
				targets[0].flee = true
				release_keeper(targets[0])
				say("侵入者が逃げ出した！")
	elif a.mode == "wander":
		a.state = "徘徊"
		if tick % 12 == 0:
			var options = neighbors(a.pos).filter(func(p): return walkable(p) and distance(p, a.home) <= 3)
			if not options.is_empty(): a.order = options[rng.randi_range(0, options.size() - 1)]
		goal = a.order
	else:
		a.state = "待機" if a.mode == "stay" else "見張り"
		a.stamina = minf(100, a.stamina + (1.6 if campaign.shelter and distance(a.pos, nest) <= 3 else 0.16))
	if tick % 2 == 0 and distance(a.pos, goal) > (1 if chasing else 0):
		var move = next_step(a.pos, goal)
		if move != a.pos:
			a.pos = move
			a.stamina = maxf(0, a.stamina - 0.65)

func enemy_step(e: Dictionary):
	if e.done: return
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
	if structures.has(next) and not structures[next].open:
		structures[next].hp -= 1
		metrics.structure_damage += 1
		e.state = "門を壊す" if structures[next].kind == "gate" else "壁を壊す"
		if structures[next].hp <= 0:
			structures.erase(next)
			metrics.destroyed += 1
			say("施設が破壊された。建て直せます。")
	else:
		e.pos = next
		e.path.append(next)
		e.state = "連れ去り" if e.carry == "keeper" else ("退散" if e.flee else "主人公へ")
		if e.carry == "keeper":
			keeper.pos = e.pos
			if not inside(e.pos):
				e.done = true
				keeper.state = "abducted"
				finish(false)

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
		if a.path.back() != a.pos: a.path.append(a.pos)
	for e in enemies:
		enemy_step(e)
		if phase == "result": break
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
	var condition = animals[0].stamina / 100.0
	var rating = (35 if won else 0) + maxi(0, 25 - metrics.captures * 8) + roundi(condition * 20) + maxi(0, 10 - metrics.structure_damage / 3) + maxi(0, 10 - int(metrics.commands / 3))
	var xp = 16 + rating / 10 if won else 0
	var gold = (32 + rating / 5 + metrics.coins) if won else 0
	score = {"rating": rating, "xp": int(xp), "gold": int(gold), "seconds": tick * DT, "condition": roundi(condition * 100), "time_bonus": 0}
	if won:
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
		"actions": actions.duplicate(true), "samples": traces.duplicate(true), "schedule": schedule,
		"stage_config": config.duplicate(true), "eggs": eggs, "command_power": command_power}
