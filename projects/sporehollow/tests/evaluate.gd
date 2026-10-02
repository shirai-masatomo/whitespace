extends SceneTree
const Farm = preload("res://game/world.gd")

static func intervene(w, strategy: String):
	if strategy in ["idle", "placement"]: return
	var dog = w.animals[0]
	var targets = w.enemies.filter(func(e): return not e.done and not e.flee)
	if strategy in ["care", "gates"] and dog.stamina < 60 and w.tick % 12 == 0:
		w.act("feed", dog.pos)
	if strategy == "gates" and w.tick % 12 == 0:
		for i in range(2):
			var near = targets.any(func(e): return Farm.distance(e.pos, Farm.GATES[i]) <= 3)
			if near and w.gate_open[i] and Farm.distance(dog.pos, Farm.GATES[i]) > 4:
				w.act("gate", Farm.GATES[i])
			elif not w.gate_open[i] and Farm.distance(dog.pos, Farm.GATES[i]) <= 3:
				w.act("gate", Farm.GATES[i])
	if not targets.is_empty() and w.tick % 16 == 0:
		targets.sort_custom(func(a, b): return Farm.distance(a.pos, w.store) < Farm.distance(b.pos, w.store))
		if Farm.distance(dog.pos, targets[0].pos) > 4:
			w.act("whistle", targets[0].pos)

static func run(strategy: String, seed_number: int, data: Dictionary = {}) -> Dictionary:
	var w = Farm.new(data, seed_number)
	if strategy == "placement": w.act("place", Vector2i(17, 8))
	w.act("start")
	while w.result == "":
		intervene(w, strategy)
		w.step()
	return w.observation()

func _initialize():
	call_deferred("evaluate")

func evaluate():
	var summary = {}
	for stage in [1, 2]:
		for strategy in ["idle", "placement", "whistle", "care", "gates"]:
			var wins = 0
			var steals = 0
			var points = 0
			for seed_number in range(1, 9):
				var c = Farm.new_campaign()
				if stage == 2:
					c.stage = 2
					c.animals[0].lv = 2
					c.animals.append({"id": 2, "category": "bird", "species": "hen", "lv": 1, "xp": 0})
				var r = run(strategy, seed_number, c)
				wins += int(r.result == "win")
				steals += r.metrics.stolen
				points += r.score.rating
			summary["stage%d_%s" % [stage, strategy]] = {"runs": 8, "wins": wins, "stolen": steals, "average_rating": points / 8.0}
	DirAccess.make_dir_recursive_absolute("res://artifacts")
	FileAccess.open("res://artifacts/evaluation.json", FileAccess.WRITE).store_string(JSON.stringify(summary, "  "))
	print(JSON.stringify(summary))
	quit()
