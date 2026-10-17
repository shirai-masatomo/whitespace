extends SceneTree
const Combat = preload("res://core/combat.gd")
const Catalog = preload("res://core/catalog.gd")
const Simulation = preload("res://tools/simulation.gd")
const Runner = preload("res://tools/runner.gd")
var failures: Array[String] = []
var checks := 0

func check(condition: bool, label: String) -> void:
	checks += 1
	if not condition:
		failures.append(label)
		printerr("FAIL: " + label)

func _initialize() -> void:
	var data := Catalog.load_data()
	check(not data.is_empty(), "catalog loads")
	if data.is_empty():
		quit(1)
		return
	check(Combat.damage(10, 0) == 10, "zero defense")
	check(Combat.damage(10, 5) == 6 and Combat.damage(10, 10) == 4 and Combat.damage(10, 20) == 3, "COMBAT examples")
	check(Combat.damage(1, 100000) == 1, "minimum damage")
	check(Combat.damage(10, 0, 1.0, 1.5) == 15, "critical multiplier")
	var expected := {"E01": [1,8,3,0,0,4,2], "E04": [4,23,7,1,7,13,11],
		"E05": [6,36,9,4,7,20,19], "B10": [6,81,14,4,13,44,64]}
	for id in expected:
		var e: Array = expected[id]
		var unit := Combat.enemy(data, id, e[0])
		check([unit.max_hp,unit.atk,unit.def,unit.max_sp,unit.exp,unit.gold] == e.slice(1), "level golden vector " + id)
		check(unit.spd == data.enemies[id].spd, "SPD has no level multiplier " + id)
	var original := data.duplicate(true)
	var foe := Combat.enemy(data, "E04", 4)
	var hero: Dictionary = data.hero_fixture.duplicate(true)
	var hero_before := hero.duplicate(true)
	var result := Combat.simulate(hero, foe, data.rules, 91)
	check(result == Combat.simulate(hero, foe, data.rules, 91), "full trace deterministic")
	check(data == original and hero == hero_before, "inputs remain unchanged")
	var state := Combat.start(hero, foe, data.rules, 91)
	var snapshot := state.duplicate(true)
	var step := Combat.advance(state)
	check(state == snapshot and step.round == 1, "advance does not mutate caller")
	while state.outcome == "ongoing":
		state = Combat.advance(state)
	check(state == result, "UI stepping equals headless complete run")
	hero.spd = 100
	check(Combat.advance(Combat.start(hero, foe, data.rules, 42)).log[0].order == ["hero","enemy"], "higher hero SPD first")
	hero.spd = 1
	check(Combat.advance(Combat.start(hero, foe, data.rules, 42)).log[0].order == ["enemy","hero"], "higher enemy SPD first")
	hero.spd = foe.spd
	var firsts := {}
	for seed_value in range(100):
		var a := Combat.advance(Combat.start(hero, foe, data.rules, seed_value))
		check(a == Combat.advance(Combat.start(hero, foe, data.rules, seed_value)), "tie replay %d" % seed_value)
		firsts[a.log[0].order[0]] = true
	check(firsts.size() == 2, "ties allow both sides across seeds")
	hero.max_hp = 100000
	hero.hp = 100000
	foe.max_hp = 100000
	foe.hp = 100000
	var capped := Combat.simulate(hero, foe, data.rules, 17)
	check(capped.outcome == "draw" and capped.round == 50 and capped.hero.hp > 0, "50 round cap is draw not death")
	check(capped.reward == {"exp":0,"gold":0}, "draw grants no reward")
	hero.atk = 100000
	hero.spd = 100
	foe.hp = 1
	var lethal := Combat.simulate(hero, foe, data.rules, 17)
	check(lethal.outcome == "victory" and lethal.enemy.hp == 0 and lethal.hero.hp == hero.hp, "dead enemy cannot retaliate")
	check(lethal.reward == {"exp":13,"gold":11}, "reward scaled exactly once")
	check(Combat.advance(lethal) == lethal, "terminal states immutable")
	hero.hp = 0
	check(Combat.simulate(hero, foe, data.rules, 17).round == 0, "dead hero cannot act")
	var no_hits: Dictionary = data.rules.duplicate(true)
	no_hits.hit_chance = 0.0
	var missed := Combat.simulate(data.hero_fixture, Combat.enemy(data,"E01",1), no_hits, 0)
	check(missed.outcome == "draw" and missed.hero.hp == data.hero_fixture.hp, "miss does no damage")
	var scenario: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/scenarios/baseline.json"))
	check(Runner.validate_scenario(scenario,data).is_empty(), "scenario validation")
	var report := Simulation.run(data, scenario, range(1000))
	report.metadata = {"engine":"test","runner_contract":"single-battle-v1","game_commit":"test"}
	check(report.metrics.invalid_results == 0 and report.records.size() == 1000, "1000 fixed seeds invariants")
	check(report.metrics.wins + report.metrics.deaths + report.metrics.draws == 1000, "exclusive outcomes")
	check(Simulation.compare(report, report).delta.win_rate == 0.0, "same conditions zero diff")
	var wrong := report.duplicate(true)
	wrong.seeds[0] = 999999
	check(Simulation.compare(report, wrong).has("error"), "reject seed mismatch")
	wrong = report.duplicate(true)
	wrong.scenario.hero.atk += 1
	check(Simulation.compare(report, wrong).has("error"), "reject scenario mismatch")
	check(Simulation.distribution([1,2,10,20]).median == 6.0, "even median")
	check(Simulation.distribution([]).mean == null, "no wins is null not fabricated zero")
	print("TESTS: %d checks, %d failures" % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)
