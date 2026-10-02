extends RefCounted
## Fixed-tick, render-independent prototype. No Input, UI, scenes or wall-clock time.
const RaiderAI = preload("res://game/raider_ai.gd")
const W = 25
const H = 17
const DT = 0.25
const STORE = Vector2i(21, 8)
const NEST = Vector2i(20, 12)
const GATES = [Vector2i(12, 5), Vector2i(12, 12)]
const PRICES = {"hen": 30, "feed": 8, "shelter": 28, "fence": 24}
var campaign: Dictionary
var checkpoint: Dictionary
var stage = 1
var seed_value = 1
var rng = RandomNumberGenerator.new()
var tick = 0
var phase = "prepare"
var result = ""
var command_power = 10.0
var gate_open = [true, true]
var gate_hp = [6, 6]
var animals: Array = []
var enemies: Array = []
var foods: Array = []
var actions: Array = []
var traces: Array = []
var events: Array = []
var spawned = 0
var eggs = 0
var supplies = 4
var store = STORE
var nest = NEST
var score: Dictionary = {}
var spawn_schedule: Array = []
var metrics = {"repelled": 0, "stolen": 0, "gate_damage": 0, "commands": 0.0,
	"eggs_produced": 0, "barks": 0, "fed": 0, "coins": 0, "arrivals": 0}

static func new_campaign() -> Dictionary:
	return {"stage": 1, "gold": 12, "feed": 4, "eggs": 0, "shelter": false,
		"fence": 0, "animals": [{"id": 1, "category": "dog", "species": "shiba", "lv": 1, "xp": 0}]}

func _init(data: Dictionary = {}, seed_number: int = 17):
	campaign = new_campaign() if data.is_empty() else data.duplicate(true)
	checkpoint = campaign.duplicate(true)
	stage = campaign.stage
	seed_value = seed_number
	rng.seed = seed_number
	spawn_schedule = [8, 36 + rng.randi_range(-5, 5), 68 + rng.randi_range(-5, 5), 102 + rng.randi_range(-5, 5)]
	eggs = campaign.eggs
	gate_hp = [6 + campaign.fence * 4, 6 + campaign.fence * 4]
	for owned in campaign.animals:
		var a = owned.duplicate(true)
		a.pos = Vector2i(22, 2) if a.species == "shiba" else nest
		a.home = a.pos
		a.stamina = 100.0
		a.fear = 0
		a.order_until = 0
		a.order = a.pos
		a.state = "見張り" if a.species == "shiba" else "ついばむ"
		a.path = [a.pos]
		animals.append(a)
	say("柴犬の見張り場所を決めて、朝をはじめよう。")

func say(message: String):
	events.append({"tick": tick, "text": message})
	if events.size() > 5:
		events.pop_front()

func inside(p: Vector2i) -> bool:
	return p.x >= 1 and p.x < W - 1 and p.y >= 1 and p.y < H - 1

func is_fence(p: Vector2i) -> bool:
	return p.x == 12 and p not in GATES

func walkable(p: Vector2i) -> bool:
	if not inside(p) or is_fence(p):
		return false
	var g = GATES.find(p)
	return g < 0 or gate_open[g] or gate_hp[g] <= 0

func neighbors(p: Vector2i) -> Array:
	return [p + Vector2i.RIGHT, p + Vector2i.LEFT, p + Vector2i.UP, p + Vector2i.DOWN]

func next_step(start: Vector2i, goal: Vector2i, raider: bool = false) -> Vector2i:
	if start == goal:
		return start
	# Tiny weighted A*: a thief can choose to push through a closed gate.
	var frontier = [start]
	var cost = {start: 0.0}
	var first = {start: start}
	while not frontier.is_empty():
		var best = 0
		for i in range(1, frontier.size()):
			if cost[frontier[i]] + distance(frontier[i], goal) < cost[frontier[best]] + distance(frontier[best], goal):
				best = i
		var p: Vector2i = frontier.pop_at(best)
		if p == goal:
			return first[p]
		for n in neighbors(p):
			if not inside(n) or is_fence(n):
				continue
			var blocked = not walkable(n)
			if blocked and not raider:
				continue
			var value: float = cost[p] + (5.0 if blocked else 1.0)
			if not cost.has(n) or value < cost[n]:
				cost[n] = value
				first[n] = n if p == start else first[p]
				if n not in frontier:
					frontier.append(n)
	return start

static func distance(a: Vector2i, b: Vector2i) -> int:
	return absi(a.x - b.x) + absi(a.y - b.y)

func act(kind: String, p: Vector2i = Vector2i.ZERO) -> bool:
	var accepted = false
	if kind == "start" and phase == "prepare":
		phase = "defend"
		say("侵入者が柵の外へ。笛で知らせ、門で時間を作ろう。")
		accepted = true
	elif kind == "place" and phase == "prepare" and walkable(p) and p.x > 12:
		animals[0].pos = p
		animals[0].home = p
		animals[0].path = [p]
		accepted = true
	elif phase == "defend":
		if kind == "whistle" and walkable(p) and command_power >= 2:
			command_power -= 2
			metrics.commands += 2
			for a in animals:
				if a.category == "dog":
					a.order = p
					a.home = p
					a.order_until = tick + 36
			accepted = true
		elif kind == "feed" and walkable(p) and command_power >= 3 and campaign.feed > 0:
			campaign.feed -= 1
			command_power -= 3
			metrics.commands += 3
			foods.append({"pos": p, "until": tick + 64})
			accepted = true
		elif kind == "gate" and command_power >= 1:
			var g = GATES.find(p)
			var occupied = animals.any(func(a): return a.pos == p) or enemies.any(func(e): return not e.done and e.pos == p)
			if g >= 0 and gate_hp[g] > 0 and not occupied:
				gate_open[g] = not gate_open[g]
				command_power -= 1
				metrics.commands += 1
				accepted = true
	actions.append({"tick": tick, "kind": kind, "pos": [p.x, p.y], "accepted": accepted})
	return accepted

func spawn_enemy():
	var entry = Vector2i(1, 5 if (spawned + seed_value) % 2 == 0 else 12)
	if stage == 2 and spawned % 2 == 1:
		entry = Vector2i(1, 12)
	enemies.append({"id": spawned, "pos": entry, "entry": entry,
		"morale": 3 if stage == 1 else 4, "flee": false, "carry": "", "done": false,
		"born": tick, "path": [entry], "role": "thief" if spawned % 2 == 0 or stage == 1 else "scout"})
	spawned += 1
	say("%sから%sが来た！" % ["上の道" if entry.y == 5 else "下の道", "泥棒" if enemies.back().role == "thief" else "斥候"])

func animal_step(a: Dictionary):
	if a.species == "hen":
		var threat = enemies.filter(func(e): return not e.done and not e.flee and distance(a.pos, e.pos) <= 4)
		if not threat.is_empty():
			a.fear = 28
			a.state = "怖がる"
			if tick % 3 == 0:
				var options = neighbors(a.pos).filter(func(p): return walkable(p) and p.x > 12)
				if not options.is_empty():
					options.sort_custom(func(p, q): return distance(p, threat[0].pos) > distance(q, threat[0].pos))
					a.pos = options[0]
		else:
			a.fear = maxi(0, a.fear - 1)
			a.state = "落ち着く" if a.fear > 0 else "卵を育てる"
			if tick % 4 == 0:
				a.pos = next_step(a.pos, nest)
			if tick % maxi(24, 40 - (a.lv - 1) * 4) == 0 and a.fear == 0 and eggs < 8:
				eggs += 1
				metrics.eggs_produced += 1
				say("鶏が卵を産んだ。泥棒も巣を狙う。")
		return
	var food = foods.filter(func(f): return distance(a.pos, f.pos) <= 8)
	var targets = enemies.filter(func(e): return not e.done and not e.flee and distance(a.pos, e.pos) <= 3 + a.lv / 3)
	targets.sort_custom(func(e, f): return distance(a.pos, e.pos) < distance(a.pos, f.pos))
	var goal: Vector2i = a.home
	if not food.is_empty() and a.stamina < 68:
		goal = food[0].pos
		a.state = "餌へ"
		if a.pos == goal:
			a.stamina = minf(100, a.stamina + 48)
			foods.erase(food[0])
			metrics.fed += 1
			say("柴犬が餌を食べ、元気を取り戻した。")
	elif a.stamina < 14:
		a.state = "ひと休み"
		a.stamina = minf(100, a.stamina + 1.7)
		return
	elif not targets.is_empty():
		goal = targets[0].pos
		a.state = "追いかける"
		if distance(a.pos, goal) <= 1 and tick % 5 == 0:
			a.stamina -= 12.0 - minf(a.lv, 4)
			targets[0].morale -= 1
			metrics.barks += 1
			a.state = "吠える！"
			if targets[0].morale <= 0:
				targets[0].flee = true
				if targets[0].carry != "":
					if targets[0].carry == "egg": eggs += 1
					else: supplies += 1
					targets[0].carry = ""
				say("泥棒が荷物を置いて逃げ出した！")
	elif a.order_until > tick:
		goal = a.order
		a.state = "笛の場所へ"
	else:
		a.state = "見張り"
		a.stamina = minf(100, a.stamina + (1.6 if campaign.shelter and distance(a.pos, Vector2i(17, 3)) <= 3 else 0.4))
	if tick % 2 == 0 and distance(a.pos, goal) > (1 if not targets.is_empty() else 0):
		var move = next_step(a.pos, goal)
		if move != a.pos:
			a.pos = move
			a.stamina = maxf(0, a.stamina - 0.65)

func enemy_step(e: Dictionary):
	if e.done:
		return
	var interval = 2 if e.role == "scout" else 3
	if e.carry != "": interval += 1
	if tick % interval != 0:
		return
	var goal = RaiderAI.target(e, self)
	if e.pos == goal:
		if e.flee or e.carry != "":
			e.done = true
			if e.carry != "":
				metrics.stolen += 1
				say("持ち出された！ 2個奪われると防衛失敗。")
			else:
				metrics.repelled += 1
				metrics.coins += 3
			return
		metrics.arrivals += 1
		if goal == nest and eggs > 0:
			eggs -= 1
			e.carry = "egg"
		elif supplies > 0:
			supplies -= 1
			e.carry = "supply"
		else:
			e.flee = true
		return
	var next = next_step(e.pos, goal, true)
	if not walkable(next):
		var g = GATES.find(next)
		if g >= 0:
			gate_hp[g] -= 1
			metrics.gate_damage += 1
			if gate_hp[g] == 0:
				say("門が壊れた！ 閉めたままでは守りきれない。")
	else:
		e.pos = next
		e.path.append(next)

func step():
	if phase != "defend": return
	tick += 1
	command_power = minf(10, command_power + 0.07)
	foods = foods.filter(func(f): return f.until > tick)
	var total = 3 if stage == 1 else 4
	if spawned < total and tick >= spawn_schedule[spawned]:
		spawn_enemy()
	for a in animals:
		animal_step(a)
		if a.path.back() != a.pos: a.path.append(a.pos)
	for e in enemies: enemy_step(e)
	if tick % 8 == 0:
		traces.append({"tick": tick, "stamina": snappedf(animals[0].stamina, 0.1), "eggs": eggs, "power": snappedf(command_power, 0.1)})
	if metrics.stolen >= 2 or tick >= 960:
		finish(false)
	elif spawned == total and enemies.all(func(e): return e.done):
		finish(true)

func finish(won: bool):
	if result != "": return
	result = "win" if won else "loss"
	phase = "result"
	var condition = animals[0].stamina / 100.0
	var rating = (35 if won else 0) + maxi(0, 25 - metrics.stolen * 12) + roundi(condition * 20) + maxi(0, 10 - metrics.gate_damage) + maxi(0, 10 - int(metrics.commands / 3))
	var xp = 16 + rating / 10 if won else 0
	var gold = (32 + rating / 5 + metrics.coins) if won else 0
	score = {"rating": rating, "xp": int(xp), "gold": int(gold), "seconds": tick * DT,
		"condition": roundi(condition * 100), "time_bonus": 0}
	if won:
		campaign.gold += int(gold)
		campaign.eggs = eggs
		for owned in campaign.animals:
			owned.xp += int(xp)
			while owned.xp >= owned.lv * 20:
				owned.xp -= owned.lv * 20
				owned.lv += 1
			for a in animals:
				if a.id == owned.id:
					a.lv = owned.lv
					a.xp = owned.xp
		say("防衛成功！ 時間の速さだけでは評価しません。")

func buy(kind: String) -> bool:
	if result != "win": return false
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
		"hen": campaign.animals.append({"id": 2, "category": "bird", "species": "hen", "lv": 1, "xp": 0})
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
		positions.append(row)
	var raiders = []
	for e in enemies:
		var row = e.duplicate(true)
		row.pos = [e.pos.x, e.pos.y]
		row.entry = [e.entry.x, e.entry.y]
		row.path = e.path.map(func(p): return [p.x, p.y])
		raiders.append(row)
	return {"seed": seed_value, "stage": stage, "tick": tick, "result": result,
		"campaign": campaign.duplicate(true), "animals": positions, "raiders": raiders,
		"metrics": metrics.duplicate(true), "score": score.duplicate(true),
		"actions": actions.duplicate(true), "samples": traces.duplicate(true),
		"gate_open": gate_open.duplicate(), "gate_hp": gate_hp.duplicate(), "supplies": supplies,
		"eggs": eggs, "command_power": command_power}
