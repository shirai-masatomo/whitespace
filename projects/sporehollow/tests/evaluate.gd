extends SceneTree
const Farm = preload("res://game/world.gd")

static func intervene(w, strategy: String):
	if strategy == "idle": return
	if strategy in ["build", "combined"] and w.tick == 0:
		for cell in [Vector2i(17, 7), Vector2i(17, 9), Vector2i(18, 6)]: w.act("wall", cell)
	if strategy == "build": return
	var targets = w.enemies.filter(func(e): return not e.done and not e.flee)
	if targets.is_empty(): return
	var e = targets[0]
	var dog = w.animals[0]
	# A player-observable decision: retreat while the raider counterattacks, then send the dog back.
	if e.counter_target >= 0 and e.counter_until > w.tick and e.carry != "keeper":
		if dog.pending.is_empty() and (dog.mode != "whistle" or Farm.distance(dog.pos, e.pos) <= 2):
			var options = [dog.pos + Vector2i(0, 5), dog.pos - Vector2i(0, 5), dog.pos + Vector2i(5, 0), dog.pos - Vector2i(5, 0)]
			options = options.filter(func(p): return w.walkable(p))
			options.sort_custom(func(a, b): return Farm.distance(a, e.pos) > Farm.distance(b, e.pos))
			if not options.is_empty(): w.act("whistle", options[0])
	elif dog.pending.is_empty() and dog.mode != "attack_target":
		w.act("attack_target", e.pos)
	if dog.stamina < 30 and w.foods.is_empty(): w.act("feed", dog.pos)

static func run_trial(strategy: String, number: int, data: Dictionary = {}):
	var w = Farm.new(data, number)
	w.act("place", Vector2i(19, 8))
	w.act("start")
	while w.phase == "defend" and w.tick < 1200:
		intervene(w, strategy)
		w.step()
	return w

func _initialize(): call_deferred("run")
func run():
	var report = []
	var failed = false
	for strategy in ["idle", "build", "orders", "combined"]:
		var runs = []
		for number in [17, 29, 41, 53]:
			var w = run_trial(strategy, number)
			failed = failed or w.result == ""
			runs.append({"seed": number, "result": w.result, "seconds": w.tick * Farm.DT, "dog_hp": w.animals[0].hp, "enemy_hp": w.enemies[0].hp, "metrics": w.metrics, "score": w.score})
			if number == 17: FileAccess.open("res://artifacts/trial-" + strategy + ".json", FileAccess.WRITE).store_string(JSON.stringify(w.observation(), "  "))
		var wins = runs.filter(func(r): return r.result == "win").size()
		print("Stage 1 / %s: %d/%d wins; dog HP %d, time %.1fs" % [strategy, wins, runs.size(), runs[0].dog_hp, runs[0].seconds])
		failed = failed or (strategy == "idle" and wins != 0) or (strategy == "combined" and wins != runs.size())
		report.append({"stage": 1, "strategy": strategy, "wins": wins, "runs": runs})
	FileAccess.open("res://artifacts/evaluation.json", FileAccess.WRITE).store_string(JSON.stringify(report, "  "))
	quit(1 if failed else 0)
