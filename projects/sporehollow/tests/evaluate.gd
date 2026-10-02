extends SceneTree
const Farm = preload("res://game/world.gd")

static func intervene(w, strategy: String):
	if strategy == "idle": return
	if strategy == "build" or strategy == "combined":
		if w.tick == 0:
			for y in range(1, 16): w.act("build_gate" if y == 8 else "wall", Vector2i(14, y))
		if strategy == "build": return
	if w.animals[0].stamina < 58 and w.tick % 12 == 0 and w.foods.is_empty(): w.act("feed", w.animals[0].pos)
	var targets = w.enemies.filter(func(e): return not e.done and not e.flee)
	if not targets.is_empty() and w.tick % 16 == 0:
		targets.sort_custom(func(a, b): return a.carry == "keeper" or (b.carry != "keeper" and Farm.distance(a.pos, w.keeper.pos) < Farm.distance(b.pos, w.keeper.pos)))
		w.act("attack_target", targets[0].pos)
	if strategy == "combined":
		var gate = Vector2i(14, 8)
		if w.structures.has(gate) and not w.structures[gate].open: w.act("gate", gate)

static func run_trial(strategy: String, number: int, data: Dictionary = {}):
	var w = Farm.new(data, number)
	w.act("place", Vector2i(19, 8))
	w.act("start")
	while w.phase == "defend" and w.tick < 2400:
		intervene(w, strategy)
		w.step()
	return w

func _initialize(): call_deferred("run")
func run():
	var report = []
	var unresolved = 0
	for stage in [1, 2]:
		var data = Farm.new_campaign()
		data.stage = stage
		if stage == 2:
			data.animals[0].lv = 2
			data.animals.append({"id": 2, "category": "bird", "species": "hen", "lv": 1, "xp": 0, "loyalty": 0})
		for strategy in ["idle", "build", "orders_feed", "combined"]:
			var runs = []
			for number in [17, 29, 41, 53]:
				var w = run_trial(strategy, number, data)
				if w.result == "": unresolved += 1
				runs.append({"seed": number, "result": w.result, "seconds": w.tick * Farm.DT, "metrics": w.metrics, "score": w.score})
			var wins = runs.filter(func(r): return r.result == "win").size()
			print("Stage %d / %s: %d/%d wins" % [stage, strategy, wins, runs.size()])
			report.append({"stage": stage, "strategy": strategy, "wins": wins, "runs": runs})
	DirAccess.make_dir_recursive_absolute("res://artifacts")
	FileAccess.open("res://artifacts/evaluation.json", FileAccess.WRITE).store_string(JSON.stringify(report, "  "))
	if unresolved > 0: push_error("Simulation exceeded safety bound: %d" % unresolved)
	quit(1 if unresolved > 0 else 0)
