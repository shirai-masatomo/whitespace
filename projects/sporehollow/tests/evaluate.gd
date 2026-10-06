extends SceneTree
const Farm = preload("res://game/world.gd")
const SEEDS = 32

static func deploy(w, keeper: Vector2i = Vector2i(19, 8), dog: Vector2i = Vector2i(18, 8)):
	# Explicit initial-layout fixture for AI evaluation, not a player placement API.
	w.keeper.pos=keeper
	for a in w.animals: a.pos=dog; a.home=dog; a.order=dog

static func run_trial(strategy: String, number: int = 17):
	var w = Farm.new({}, number).begin_day()
	if strategy == "poor": deploy(w, Vector2i(3, 5), Vector2i(23, 15))
	elif strategy == "rescue": deploy(w, Vector2i(19, 8), Vector2i(19, 13))
	elif strategy in ["ordered", "uncommanded"]: deploy(w, Vector2i(8, 5), Vector2i(20, 13))
	elif strategy == "reserve":
		deploy(w)
		w.animals[0].mode="rest"
	else: deploy(w)
	if strategy == "rescue": w.act("stay", Vector2i(19, 13), 1)
	if strategy == "ordered": w.act("stay", Vector2i(9, 5), 1)
	if strategy == "guided":
		w.act("wall", Vector2i(17, 7))
		w.act("wall", Vector2i(17, 9))
		w.act("stay", Vector2i(18, 8), 1)
	w.start_night()
	while w.phase == "defend" and w.tick < 1200:
		w.step()
		if w.early_clear: w.act("end_night")
		if w.keeper.carrier >= 0 and w.phase == "defend": assert(w.keeper.state == "captured")
	return w

static func compact(w) -> Dictionary:
	var counts = {}
	for a in w.actions:
		if a.accepted: counts[a.kind] = counts.get(a.kind, 0) + 1
	var log = []
	var seen = {}
	for decision in w.decision_log:
		var key = decision.actor + ":" + decision.state + ":" + decision.selected
		if not seen.has(key) and log.size() < 24:
			seen[key] = true
			log.append(decision)
	for decision in w.decision_log.slice(maxi(0, w.decision_log.size() - 4)):
		if decision not in log: log.append(decision)
	log.sort_custom(func(a, b): return a.tick < b.tick)
	return {"seed": w.seed_value, "stage_config": w.config, "initial_positions": w.initial_positions,
		"result": w.result, "seconds": w.tick * Farm.DT, "dog_remaining_hp": w.animals[0].hp,
		"milestones": w.milestones, "combat": w.combat_log, "skill_log": w.skill_log, "metrics": w.metrics,
		"decision_log": log, "decision_total": w.decision_count, "decision_log_omitted": w.decision_count - log.size(), "decision_counts": w.decision_counts,
		"facilities": w.observation().structures, "soil_initial": 100, "soil_remaining": w.materials,
		"soil_spent_net": 100 - w.materials, "actions_summary": counts}

static func sample(w) -> Dictionary:
	var attacks = w.combat_log.filter(func(hit): return hit.source == "animal")
	var first_attack = -1.0 if attacks.is_empty() else (attacks[0].tick - w.enemies[0].born) * Farm.DT
	var passive = 0
	for key in ["shiba:watch", "shiba:bark", "shiba:reposition"]: passive += w.decision_counts.get(key, 0)
	return {"seed": w.seed_value, "win": w.result == "win", "abducted": w.result == "loss",
		"captures": w.metrics.captures, "rescues": w.metrics.rescues, "hp": w.animals[0].hp,
		"attacks": attacks.size(), "first_attack_after_spawn": first_attack,
		"first_attack_after_contact": -1.0 if attacks.is_empty() else (attacks[0].tick - w.animals[0].get("first_contact_tick", attacks[0].tick)) * Farm.DT,
		"non_attack_decisions": passive, "seconds": w.tick * Farm.DT}

func _initialize(): call_deferred("run")
func run():
	var report = {"seed_range": [1, SEEDS], "ai_settings": Farm.Rules.AI, "strategies": {}}
	var failed = false
	for strategy in ["front", "poor", "rescue", "uncommanded", "ordered", "reserve"]:
		var rows = []
		var hp_distribution = {}
		var wins = 0
		var captures = 0
		var rescues = 0
		var attacks = 0
		var passive = 0
		var first_times = []
		var reaction_times = []
		for seed_number in range(1, SEEDS + 1):
			var w = run_trial(strategy, seed_number)
			failed = failed or w.result == ""
			var row = sample(w)
			rows.append(row)
			wins += int(row.win)
			captures += row.captures
			rescues += row.rescues
			attacks += row.attacks
			passive += row.non_attack_decisions
			hp_distribution[str(row.hp)] = hp_distribution.get(str(row.hp), 0) + 1
			if row.first_attack_after_spawn >= 0: first_times.append(row.first_attack_after_spawn)
			if row.first_attack_after_contact >= 0: reaction_times.append(row.first_attack_after_contact)
		var summary = {"runs": SEEDS, "wins": wins, "dog_survival": rows.filter(func(row): return row.hp > 0).size(),
			"abductions": SEEDS - wins, "captures": captures, "rescues": rescues,
			"rescue_rate_when_carried": float(rescues) / captures if captures > 0 else null,
			"hp_distribution": hp_distribution, "dog_attacks": attacks, "non_attack_decisions": passive,
			"first_attack_after_spawn_min": first_times.min() if not first_times.is_empty() else null,
			"first_attack_after_spawn_max": first_times.max() if not first_times.is_empty() else null,
			"first_attack_after_contact_min": reaction_times.min() if not reaction_times.is_empty() else null,
			"first_attack_after_contact_max": reaction_times.max() if not reaction_times.is_empty() else null}
		report.strategies[strategy] = {"summary": summary, "samples": rows}
		print(strategy, ": ", JSON.stringify(summary))
		if strategy == "front": failed = failed or wins < SEEDS * 0.75 or passive == 0 or hp_distribution.size() < 2
		# TargetWeights now permit diversion to resting animals/structures; survival is measured,
		# not assumed impossible. Explicit rest must still suppress rescue AND attacks.
		if strategy == "reserve": failed = failed or rescues > 0 or attacks > 0
	FileAccess.open("res://artifacts/evaluation.json", FileAccess.WRITE).store_string(JSON.stringify(report, "  "))
	quit(1 if failed else 0)
