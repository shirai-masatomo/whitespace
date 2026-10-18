extends RefCounted
const Combat = preload("res://core/combat.gd")

static func distribution(values: Array) -> Dictionary:
	if values.is_empty():
		return {"count": 0, "mean": null, "median": null, "p10": null, "p90": null, "min": null, "max": null}
	var sorted := values.duplicate()
	sorted.sort()
	var sum := 0.0
	for value in sorted:
		sum += float(value)
	var size := sorted.size()
	var middle := size / 2
	var median := float(sorted[middle]) if size % 2 else (float(sorted[middle - 1]) + float(sorted[middle])) / 2.0
	return {"count": size, "mean": sum / size, "median": median,
		"p10": sorted[maxi(0, ceili(size * 0.1) - 1)], "p90": sorted[maxi(0, ceili(size * 0.9) - 1)],
		"min": sorted.front(), "max": sorted.back()}

static func run(data: Dictionary, scenario: Dictionary, seeds: Array) -> Dictionary:
	var foe := Combat.enemy(data, scenario.enemy_id, int(scenario.enemy_level))
	var records: Array = []
	var turns: Array = []
	var hp: Array = []
	var winning_hp: Array = []
	var wins := 0
	var deaths := 0
	var draws := 0
	var invalid := 0
	for battle_seed in seeds:
		var result := Combat.simulate(scenario.hero, foe, data.rules, int(battle_seed))
		wins += int(result.outcome == "victory")
		deaths += int(result.hero.hp == 0)
		draws += int(result.outcome == "draw")
		turns.append(result.round)
		hp.append(result.hero.hp)
		if result.outcome == "victory":
			winning_hp.append(result.hero.hp)
		if result.hero.hp < 0 or result.enemy.hp < 0 or result.round > 50 or result.outcome == "ongoing":
			invalid += 1
		records.append({"seed": battle_seed, "outcome": result.outcome, "rounds": result.round,
			"hero_hp": result.hero.hp, "enemy_hp": result.enemy.hp, "reward": result.reward,
			"log_sha256": JSON.stringify(result.log).sha256_text()})
	var count := float(seeds.size())
	return {"schema_version": 1, "scenario": scenario, "seeds": seeds,
		"metrics": {"trials": seeds.size(), "wins": wins, "deaths": deaths, "draws": draws,
			"win_rate": wins / count, "death_rate": deaths / count, "draw_rate": draws / count,
			"rounds": distribution(turns), "remaining_hp": distribution(hp), "winning_hp": distribution(winning_hp),
			"invalid_results": invalid, "ally_death_rate": null},
		"records": records,
		"limitations": ["Normal attacks and explicit S105 only; no other skills/status/durability/allies.", "Single battle; no exploration progression or forced-death event.", "Hero stats are provisional effective stats, not a growth curve."]}

static func compare(before: Dictionary, after: Dictionary, strict: bool = false) -> Dictionary:
	# JSON numbers reload as floats. Normalize both sides before deep comparison.
	before = JSON.parse_string(JSON.stringify(before))
	after = JSON.parse_string(JSON.stringify(after))
	for key in ["schema_version", "scenario", "seeds"]:
		if not before.has(key) or before[key] != after[key]:
			return {"error": "Comparison conditions differ: " + key}
	if not before.get("metadata") is Dictionary or not before.get("metrics") is Dictionary:
		return {"error": "Missing baseline metadata/metrics"}
	for key in ["engine", "runner_contract"]:
		if before.metadata.get(key) != after.metadata.get(key):
			return {"error": "Comparison environment differs: " + key}
	var differences := {}
	if not before.metrics is Dictionary or before.metrics.keys().size()!=after.metrics.keys().size():
		return {"error":"Invalid baseline metrics"}
	for key in after.metrics:
		if not before.metrics.has(key): return {"error":"Missing metric: "+key}
		if after.metrics[key] is Dictionary:
			if not before.metrics[key] is Dictionary: return {"error":"Invalid metric: "+key}
			for field in after.metrics[key]:
				if not before.metrics[key].has(field): return {"error":"Missing distribution field"}
				if before.metrics[key][field]!=null and not typeof(before.metrics[key][field]) in [TYPE_INT,TYPE_FLOAT]: return {"error":"Invalid distribution value"}
		elif before.metrics[key]!=null and not typeof(before.metrics[key]) in [TYPE_INT,TYPE_FLOAT]: return {"error":"Invalid metric value"}
	for key in ["win_rate", "death_rate", "draw_rate"]:
		differences[key] = float(after.metrics[key]) - float(before.metrics[key])
	for key in ["rounds", "remaining_hp", "winning_hp"]:
		for metric in ["mean", "median", "p10", "p90"]:
			var left = before.metrics[key][metric]
			var right = after.metrics[key][metric]
			differences[key + "." + metric] = null if left == null or right == null else float(right) - float(left)
	var identical: bool = before.metrics==after.metrics and before.get("records")==after.get("records")
	return {"before": before.metadata, "after": after.metadata, "trials": after.seeds.size(),
		"strict":strict,"strict_equal":identical,"records_equal":before.get("records")==after.get("records"),
		"before_metrics": before.metrics, "after_metrics": after.metrics, "delta": differences}

static func summary(report: Dictionary) -> String:
	var m: Dictionary = report.metrics
	return ("単発戦闘 / %s / %d seeds\n勝率 %.2f%% / 主人公死亡率 %.2f%% / 打切り %.2f%%\n平均ラウンド %.3f / 中央値 %.3f\n残HP（全戦闘） 平均 %.3f / 中央値 %.3f / p10 %s / p90 %s\n勝利時残HP %s\n異常結果 %d\nS102〜S105のみ先行対応。仲間・その他のスキル・耐久は未実装。この単発レポートは連続探索を含みません。難易度の適正を証明する試験ではありません。\n" %
		[report.scenario.scenario_id, m.trials, m.win_rate * 100.0, m.death_rate * 100.0, m.draw_rate * 100.0,
		m.rounds.mean, m.rounds.median, m.remaining_hp.mean, m.remaining_hp.median,
		str(m.remaining_hp.p10), str(m.remaining_hp.p90), JSON.stringify(m.winning_hp), m.invalid_results])
