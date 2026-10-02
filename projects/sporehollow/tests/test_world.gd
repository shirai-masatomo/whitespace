extends SceneTree
const Farm = preload("res://game/world.gd")
const Trial = preload("res://tests/evaluate.gd")
var assertions = 0

func check(value: bool, description: String):
	assertions += 1
	if not value:
		push_error(description)
		quit(1)
		assert(value, description)

func ready_world(pos: Vector2i = Vector2i(19, 8)):
	var w = Farm.new()
	w.act("place", pos)
	w.act("start")
	return w

func event_at(p: Vector2i) -> Dictionary:
	return {"entry": p, "morale": 4, "role": "kidnapper"}

func _initialize(): call_deferred("run")
func run():
	var w = Farm.new()
	check(w.structures.is_empty(), "A new day is an empty lot, without fixed walls/gates")
	check(w.animals.size() == 1 and w.animals[0].species == "shiba" and w.animals[0].lv == 1, "Only Lv1 Shiba initially")
	check(not w.act("start"), "Keeper placement is required before the clock starts")
	check(not w.act("place", Vector2i.ZERO) and not w.act("place", w.entries[0]), "Cannot place keeper outside or on entrance")
	check(w.act("place", Vector2i(19, 8)) and w.keeper.pos == Vector2i(19, 8), "Player chooses protagonist position")
	check(not w.act("wall", Vector2i(10, 5)), "Construction does not happen before the clock starts")
	w.step()
	check(w.tick == 0, "Preparation selection has no ticking")
	check(w.act("start"), "Starts timed preparation")
	check(w.act("wall", Vector2i(10, 5)), "Build while clock runs")
	check(w.materials == 57 and not w.walkable(Vector2i(10, 5)), "Wall costs materials and blocks")
	check(not w.act("wall", w.keeper.pos) and not w.act("wall", w.animals[0].pos) and not w.act("wall", w.entries[0]), "No trapping on occupied/entry cells")
	check(not w.act("attack", Vector2i(1, 5)), "No player attack")
	check(w.act("build_gate", Vector2i(10, 6)) and not w.walkable(Vector2i(10, 6)), "Placed gate starts closed")
	check(w.act("gate", Vector2i(10, 6)) and w.walkable(Vector2i(10, 6)), "Open gate lets animals through")
	var total: int = w.materials
	check(w.act("remove", Vector2i(10, 5)) and w.materials < total + 3, "Removal permits rebuilding without resource multiplication")
	while w.tick < 71: w.step()
	check(w.enemies.is_empty(), "No enemy before configured first attack")
	w.step()
	check(w.spawned == 1 and w.enemies[0].born == 72, "First attack occurs at 18 seconds")
	check(w.act("wall", Vector2i(11, 5)), "Can build during invasion")
	w.eggs = 2
	w.act("pause")
	var before = w.observation()
	for kind in ["wall", "build_gate", "feed", "gate", "remove", "collect", "place", "start"]:
		var p = w.nest if kind == "collect" else Vector2i(10, 6)
		check(not w.act(kind, p), "Paused world rejects " + kind)
	check(w.act("attack_target", w.enemies[0].pos), "Paused targeted order accepted")
	check(w.act("stay", Vector2i(16, 8)), "Paused stay order accepted")
	for i in range(20): w.step()
	check(w.tick == before.tick and w.materials == before.materials and w.command_power == before.command_power and w.campaign == before.campaign and w.eggs == 2, "Pause freezes clock, inventory and budget")
	check(w.animals[0].pos == Vector2i(before.animals[0].pos[0], before.animals[0].pos[1]) and w.structures.size() == before.structures.size(), "Paused orders move nobody and alter no facility")
	w.act("pause")
	w.step()
	check(w.animals[0].mode != "stay", "Loyalty introduces reaction delay")
	w.step()
	check(w.animals[0].mode == "stay", "Queued order activates on resumed simulation")
	check(w.act("collect", w.nest) and w.eggs == 0 and w.campaign.eggs == 2, "Produce collection works during live invasion")
	w.materials = 0
	check(not w.act("wall", Vector2i(11, 8)), "Cannot build for free")

	# Loyalty changes response/persistence, not bark power or stamina cost.
	var low = ready_world()
	var high = ready_world()
	low.animals[0].loyalty = 25
	high.animals[0].loyalty = 100
	low.act("stay", Vector2i(18, 8))
	high.act("stay", Vector2i(18, 8))
	low.step()
	high.step()
	check(high.animals[0].mode == "stay" and low.animals[0].mode == "auto", "Higher loyalty responds sooner")
	for i in range(3):
		low.step()
		high.step()
	check(high.animals[0].order_until > low.animals[0].order_until, "Higher loyalty maintains instructions longer")
	for subject in [low, high]:
		subject.spawn_enemy(event_at(Vector2i(1, 5)))
		subject.enemies[0].pos = Vector2i(17, 8)
		subject.tick = 5
		subject.animal_step(subject.animals[0])
	check(low.enemies[0].morale == high.enemies[0].morale and low.animals[0].stamina == high.animals[0].stamina, "Loyalty does not buff combat stats")
	low.animals[0].loyalty = 0
	check(not low.act("whistle", Vector2i(16, 8)), "No orders for an animal without loyalty")

	# Dynamic weighted routing: cheap detour, then enclosed goal, then weak gate.
	w = ready_world()
	w.act("wall", Vector2i(10, 8))
	check(w.next_step(Vector2i(9, 8), Vector2i(11, 8), true) != Vector2i(10, 8), "Healthy wall: raider prefers cheap detour")
	w.structures[Vector2i(10, 8)].hp = 1
	check(w.next_step(Vector2i(9, 8), Vector2i(11, 8), true) == Vector2i(10, 8), "Damaged wall: breach beats detour")
	w = ready_world()
	for y in range(1, 16): w.act("build_gate" if y == 8 else "wall", Vector2i(10, y))
	check(w.next_step(Vector2i(9, 8), Vector2i(12, 8)) == Vector2i(9, 8), "Closed barrier blocks animal path")
	check(w.next_step(Vector2i(9, 8), Vector2i(12, 8), true) == Vector2i(10, 8), "Sealed maze does not stop raiders; choose gate to breach")
	w.spawn_enemy(event_at(Vector2i(1, 5)))
	w.enemies[0].pos = Vector2i(9, 8)
	for i in range(6):
		w.tick = (i + 1) * 3
		w.enemy_step(w.enemies[0])
	check(not w.structures.has(Vector2i(10, 8)) and w.metrics.destroyed == 1 and w.result == "", "Gate destroyed by enemy; facility loss is not game loss")
	check(w.walkable(Vector2i(10, 8)), "Destroyed gate immediately updates animal navigation")
	w = ready_world(Vector2i(11, 8))
	w.animals[0].pos = Vector2i(20, 14)
	for p in [Vector2i(10, 8), Vector2i(12, 8), Vector2i(11, 7), Vector2i(11, 9)]: w.act("wall", p)
	w.spawn_enemy(event_at(Vector2i(1, 5)))
	w.enemies[0].pos = Vector2i(9, 8)
	for i in range(8):
		w.tick = (i + 1) * 3
		w.enemy_step(w.enemies[0])
	check(w.metrics.destroyed == 1 and w.walkable(Vector2i(10, 8)), "Enclosed protagonist remains reachable by wall destruction")

	# Capture, carrying, rescue, and true outside-loss use real enemy/dog actions.
	w = ready_world(Vector2i(5, 5))
	w.spawn_enemy(event_at(Vector2i(1, 5)))
	var e = w.enemies[0]
	e.pos = w.keeper.pos
	for at in [3, 6]:
		w.tick = at
		w.enemy_step(e)
	check(w.keeper.state == "captured" and w.result == "", "Capture alone is not defeat")
	w.tick = 8
	w.enemy_step(e)
	check(w.keeper.pos == e.pos and w.keeper.pos == Vector2i(4, 5), "Captive is physically escorted towards entrance")
	e.morale = 1
	w.animals[0].pos = Vector2i(4, 6)
	w.tick = 10
	w.animal_step(w.animals[0])
	check(w.keeper.carrier == -1 and w.keeper.state == "free" and w.metrics.rescues == 1 and e.flee, "A dog's bark rescues a carried protagonist")
	check(w.keeper.pos == Vector2i(4, 5) and w.result == "", "Rescued protagonist stays where rescued")
	w = ready_world(Vector2i(2, 5))
	w.spawn_enemy(event_at(Vector2i(1, 5)))
	e = w.enemies[0]
	e.pos = Vector2i(2, 5)
	for at in [3, 6, 8, 12]:
		w.tick = at
		w.enemy_step(e)
	check(w.result == "loss" and w.keeper.pos.x == 0, "Loss exactly when carried outside, not one tick later")
	check(w.campaign.gold == w.checkpoint.gold and w.score.xp == 0, "Failed abduction defense gives no clear rewards")

	# Configuration and seed are explicit inputs, including repeating waves.
	var cfg = Farm.StageData.STAGES[1].duplicate(true)
	cfg.first_attack_seconds = 1.0
	cfg.repeat_waves = true
	cfg.repeat_interval_seconds = 2.0
	cfg.time_limit_seconds = 6.0
	cfg.waves = [{"start_seconds": 0.0, "count": 2, "interval_seconds": 0.5, "jitter_seconds": 0.1, "role": "kidnapper", "entries": [[1, 5]], "morale": 3}]
	w = Farm.new({}, 42, cfg)
	w.act("place", Vector2i(23, 15))
	w.act("start")
	var same = Farm.new({}, 42, cfg)
	check(w.spawn_schedule == same.spawn_schedule, "Seeded wave jitter is reproducible")
	for i in range(24): w.step()
	check(w.spawned == 6 and w.result == "win", "Repeating config spawns subsequent cycles until survival goal")

	# Campaign, counterfactual policy, replay, score and serialization regression.
	var idle = Trial.run_trial("idle", 17)
	w = Trial.run_trial("combined", 17)
	check(idle.result == "loss" and w.result == "win", "Intervention changes the outcome on same seed")
	check(w.metrics.built > 0 and w.metrics.fed > 0 and w.metrics.barks > 0, "Successful defense uses construction, care and autonomous animals")
	var earned: int = w.campaign.gold
	w.finish(true)
	check(w.campaign.gold == earned, "No duplicate rewards")
	check(w.campaign.animals[0].lv >= 2 and w.campaign.gold > 12, "Clear awards EXP, level and Gold")
	check(w.buy("hen") and not w.buy("hen"), "Existing purchase phase remains usable")
	check(w.buy("feed"), "Buy supplies after clear")
	var next = Farm.new(w.next_campaign())
	check(next.stage == 2 and next.animals.size() == 2 and next.campaign.gold == w.campaign.gold and next.campaign.feed == w.campaign.feed, "Campaign carried into stage2")
	check(next.structures.is_empty(), "Next stage supplies a new empty lot")
	next.act("place", Vector2i(19, 8))
	next.act("start")
	for i in range(40): next.step()
	check(next.eggs > 0, "Hen still produces eggs")
	check(next.act("collect", next.nest), "Live collection")
	var retry = Farm.new(next.checkpoint)
	check(retry.campaign == next.checkpoint and retry.tick == 0, "Retry restores start-of-day inventory")
	var copy = Trial.run_trial("combined", 17)
	# Compare same-run repeat before purchases altered campaign.
	check(copy.metrics == w.metrics and copy.score == w.score, "Fixed tick simulation reproduces metrics")
	var record = JSON.stringify(w.observation())
	check(not record.contains("(19, 8)") and JSON.parse_string(record) is Dictionary, "Observation exports numeric coordinate arrays")
	check(w.actions.any(func(a): return a.kind == "wall" and a.accepted) and not w.traces.is_empty(), "Build actions and simulation samples retained")
	DirAccess.make_dir_recursive_absolute("res://artifacts")
	FileAccess.open("res://artifacts/campaign.json", FileAccess.WRITE).store_string(JSON.stringify(w.observation(), "  "))
	print("PASS: %d assertions / building, waves, capture-rescue, pause, campaign" % assertions)
	quit()
