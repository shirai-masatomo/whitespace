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

func _initialize(): call_deferred("run")

func run():
	var w = Farm.new()
	check(w.animals.size() == 1 and w.animals[0].species == "shiba" and w.animals[0].lv == 1, "Start with exactly one Lv1 Shiba")
	check(not w.act("attack", w.store), "No direct attack command")
	check(w.act("place", Vector2i(17, 8)), "Preparation placement")
	check(not w.act("place", Vector2i(12, 8)), "Cannot stand in fence")
	w.act("start")
	check(w.act("whistle", Vector2i(15, 5)), "Whistle accepted")
	check(w.command_power == 8 and w.animals[0].order == Vector2i(15, 5), "Whistle records intent and cost")
	check(w.act("gate", Farm.GATES[0]) and not w.walkable(Farm.GATES[0]), "Closed gate changes navigation")
	var p = w.animals[0].pos
	w.animals[0].stamina = 20
	check(w.act("feed", p), "Food consumes inventory")
	w.step()
	check(w.metrics.fed == 1 and w.animals[0].stamina > 60, "Tired animal autonomously eats")
	while w.command_power >= 2: w.act("whistle", Vector2i(15, 5))
	check(not w.act("whistle", Vector2i(15, 5)), "Command resource prevents spamming")
	var budget = w.command_power
	for i in range(16): w.step()
	check(w.command_power > budget, "Command resource recovers")
	var idle_wins = 0
	var active_wins = 0
	for seed_number in range(1, 9):
		var idle = Trial.run("idle", seed_number)
		var active = Trial.run("care", seed_number)
		idle_wins += int(idle.result == "win")
		active_wins += int(active.result == "win")
		check(active.tick < 960, "Simulation terminates before timeout")
		check(active.metrics.commands > 0 and active.actions.size() > 1, "Causal action telemetry")
	check(idle_wins < active_wins, "Intervention changes success rate")
	check(Trial.run("gates", 17) == Trial.run("gates", 17), "Seeded simulation is reproducible")
	w = Farm.new()
	w.act("start")
	while w.result == "":
		Trial.intervene(w, "care")
		w.step()
	check(w.result == "win", "Stage 1 can be completed")
	check(w.campaign.animals[0].lv == 2 and w.score.xp > 0 and w.score.gold > 0, "Rating awards EXP, level and Gold")
	var gold = w.campaign.gold
	w.finish(true)
	check(w.campaign.gold == gold, "No duplicate rewards")
	check(w.buy("hen"), "Buy a hen after victory")
	check(not w.buy("hen"), "Prototype limits duplicate animal purchase")
	check(w.buy("feed"), "Economic choice: replenish food")
	var second = Farm.new(w.next_campaign(), 18)
	check(second.stage == 2 and second.animals.size() == 2 and second.animals[0].lv == 2, "Ownership and level carry into Stage 2")
	check(second.campaign.gold == w.campaign.gold and second.campaign.feed == w.campaign.feed, "Inventory and Gold carry over")
	second.act("start")
	while second.result == "":
		Trial.intervene(second, "gates")
		second.step()
	check(second.metrics.eggs_produced > 0, "Hen produces a new defense/economy target")
	var fresh = Farm.new(second.checkpoint, second.seed_value)
	check(fresh.tick == 0 and fresh.campaign == second.checkpoint, "Retry restores the exact day checkpoint")
	w.campaign.eggs = 2
	gold = w.campaign.gold
	var feed = w.campaign.feed
	check(w.buy("sell_egg") and w.campaign.gold == gold + 9, "Egg sale")
	check(w.buy("cook_egg") and w.campaign.feed == feed + 2 and w.campaign.eggs == 0, "Egg as feed; no double spending")
	w.campaign.gold = 80
	check(w.buy("shelter") and w.buy("fence"), "Facility purchase")
	var upgraded = Farm.new(w.next_campaign())
	check(upgraded.gate_hp[0] == 10 and upgraded.campaign.shelter, "Farm upgrades persist")
	var obs = second.observation()
	check(not obs.raiders.is_empty() and obs.raiders[0].path.size() > 1 and not obs.samples.is_empty(), "Paths and time series exported")
	FileAccess.open("res://artifacts/campaign.json", FileAccess.WRITE).store_string(JSON.stringify(obs, "  "))
	print("PASS: %d assertions. Continuous Stage 2 result: %s" % [assertions, second.result])
	quit()
