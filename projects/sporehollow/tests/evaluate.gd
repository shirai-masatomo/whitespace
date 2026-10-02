extends SceneTree
const Farm = preload("res://game/world.gd")

static func deploy(w, keeper: Vector2i = Vector2i(19, 8), dog: Vector2i = Vector2i(18, 8)):
	w.act("place", keeper)
	for a in w.animals: w.act("place_animal", dog if a.species == "shiba" else w.nest, a.id)
	w.act("start")

static func run_trial(strategy: String, number: int = 17, counter_seconds: float = 1.0):
	var w = Farm.new({}, number)
	if strategy == "poor": deploy(w, Vector2i(3, 5), Vector2i(23, 15))
	elif strategy == "rescue": deploy(w, Vector2i(19, 8), Vector2i(19, 13))
	else: deploy(w)
	if strategy == "rescue": w.act("stay", Vector2i(19, 13), 1)
	if strategy == "guided":
		build_and_guard(w)
	while w.phase == "defend" and w.tick < 1200:
		for e in w.enemies: e.counter_seconds = counter_seconds
		w.step()
		if w.keeper.carrier >= 0 and w.phase == "defend": assert(w.keeper.state == "captured")
	return w

static func build_and_guard(w):
	w.act("wall", Vector2i(17, 7))
	w.act("wall", Vector2i(17, 9))
	w.act("stay", Vector2i(18, 8), 1)

static func compact(w) -> Dictionary:
	var counts = {}
	for a in w.actions:
		if a.accepted: counts[a.kind] = counts.get(a.kind, 0) + 1
	return {"stage_config": w.config, "initial_positions": w.initial_positions,
		"result": w.result, "seconds": w.tick * Farm.DT, "dog_remaining_hp": w.animals[0].hp,
		"milestones": w.milestones, "combat": w.combat_log,
		"facilities": w.observation().structures, "soil_initial": 100, "soil_remaining": w.materials,
		"soil_spent_net": 100 - w.materials, "actions_summary": counts}

func _initialize(): call_deferred("run")
func run():
	var report = []
	var failed = false
	for interval in [1.0, 1.2]:
		var w = run_trial("front", 17, interval)
		print("Front counter %.2fs: %s dog HP%d" % [interval, w.result, w.animals[0].hp])
		failed = failed or w.result != "win" or w.animals[0].hp <= 0 or w.animals[0].hp >= 40
		report.append({"counter_setting": interval, "effective_counter_seconds": ceilf(interval / Farm.DT) * Farm.DT, "trial": compact(w)})
	for strategy in ["poor", "guided", "rescue"]:
		var w = run_trial(strategy)
		print("Placement / %s: %s HP%d captures%d rescues%d" % [strategy, w.result, w.animals[0].hp, w.metrics.captures, w.metrics.rescues])
		failed = failed or w.result != ("loss" if strategy == "poor" else "win")
		if strategy == "rescue": failed = failed or w.metrics.rescues != 1
		report.append({"strategy": strategy, "trial": compact(w)})
	FileAccess.open("res://artifacts/evaluation.json", FileAccess.WRITE).store_string(JSON.stringify(report, "  "))
	quit(1 if failed else 0)
