extends SceneTree
const Catalog = preload("res://core/catalog.gd")
const Simulation = preload("res://tools/simulation.gd")

func fail(message: String) -> void:
	printerr(message)
	quit(2)

func write_file(path: String, content: String) -> bool:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(content)
	file.close()
	return true

func _initialize() -> void:
	var options := {"trials": "1000", "seed": "10000", "scenario": "res://data/scenarios/baseline.json",
		"data": Catalog.PATH, "out": "", "commit": "unrecorded", "baseline": "", "strict":"false"}
	for argument in OS.get_cmdline_user_args():
		var pair := argument.trim_prefix("--").split("=", true, 1)
		if pair.size() != 2 or not options.has(pair[0]):
			fail("Unknown argument (use --key=value): " + argument)
			return
		options[pair[0]] = pair[1]
	if not options.trials.is_valid_int() or not options.seed.is_valid_int() or options.out.is_empty():
		fail("Require integer --trials, --seed and --out=path")
		return
	var count := int(options.trials)
	if not options.strict in ["true","false"] or (options.strict=="true" and options.baseline.is_empty()):
		fail("--strict=true requires a baseline; strict accepts true/false")
		return
	var first := int(options.seed)
	if count < 1 or count > 100000 or first < 0 or first > 2147383647:
		fail("Trials must be 1..100000; seed must be 0..2147383647")
		return
	var data := Catalog.load_data(options.data)
	if data.is_empty():
		fail("Data validation failed")
		return
	var scenario = JSON.parse_string(FileAccess.get_file_as_string(options.scenario))
	if not scenario is Dictionary:
		fail("Invalid scenario JSON")
		return
	var error := validate_scenario(scenario, data)
	if not error.is_empty():
		fail(error)
		return
	var seeds: Array = range(first, first + count)
	var report := Simulation.run(data, scenario, seeds)
	report.metadata = {"engine": Engine.get_version_info().string, "runner_contract": "single-battle-v1",
		"game_commit": options.commit, "data_version": data.data_version, "config_version": data.config_version,
		"data_sha256": FileAccess.get_sha256(options.data), "scenario_sha256": FileAccess.get_sha256(options.scenario),
		"combat_sha256": FileAccess.get_sha256("res://core/combat.gd")}
	var summary := Simulation.summary(report)
	if not options.baseline.is_empty():
		var baseline = JSON.parse_string(FileAccess.get_file_as_string(options.baseline))
		if not baseline is Dictionary:
			fail("Invalid baseline JSON")
			return
		report.comparison = Simulation.compare(baseline, report,options.strict=="true")
		if report.comparison.has("error"):
			fail(report.comparison.error)
			return
		summary += "同条件比較差分: " + JSON.stringify(report.comparison.delta) + "\n"
	if not write_file(options.out, JSON.stringify(report, "\t")) or not write_file(options.out + ".txt", summary):
		fail("Cannot write output: " + options.out)
		return
	print(summary)
	if options.strict=="true" and not report.comparison.strict_equal:
		printerr("STRICT_REPLAY_MISMATCH: normalized records/log hashes/metrics differ")
		quit(1)
		return
	quit(0 if report.metrics.invalid_results == 0 else 1)

static func validate_scenario(scenario: Dictionary, data: Dictionary) -> String:
	for key in ["schema_version", "scenario_id", "enemy_id", "enemy_level", "hero", "equipment", "skills"]:
		if not scenario.has(key):
			return "Missing scenario field: " + key
	if scenario.schema_version != 1 or not data.enemies.has(scenario.enemy_id):
		return "Unsupported scenario version/enemy"
	if not Catalog.numeric(scenario.enemy_level) or float(scenario.enemy_level) != floorf(float(scenario.enemy_level)) or scenario.enemy_level < 1 or scenario.enemy_level > 100:
		return "Enemy level must be an integer in 1..100"
	if not scenario.equipment is Array or not scenario.skills is Array or not scenario.hero is Dictionary:
		return "Invalid scenario container type"
	if not scenario.equipment.is_empty() or not scenario.skills.is_empty():
		return "Equipment/skills are not implemented; pass effective hero stats and empty arrays"
	return Catalog.validate_hero(scenario.hero)
