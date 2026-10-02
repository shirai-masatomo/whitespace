extends SceneTree
const Farm = preload("res://game/world.gd")
const Trial = preload("res://tests/evaluate.gd")
var checks = 0

func check(value: bool, reason: String):
	checks += 1
	if not value:
		push_error(reason)
		quit(1)
		assert(value, reason)

func started():
	var w = Farm.new()
	Trial.deploy(w)
	return w

func advance(w, count: int):
	for i in range(count): w.step()

func _initialize(): call_deferred("run")
func run():
	var w = Farm.new()
	check(w.structures.is_empty() and w.animals.size() == 1 and w.animals[0].lv == 1, "Empty farm and one Lv1 Shiba")
	check(w.materials == 100 and w.campaign.resources == {"soil": 100, "wood": 0, "stone": 0}, "Three resource types, only soil funded initially")
	check(not w.act("start"), "Placement before clock")
	w.step()
	check(w.tick == 0, "Placement freezes clock")
	check(w.act("place", Vector2i(19, 8)) and not w.animals[0].placed, "Keeper placement never places dog")
	check(not w.act("place", Vector2i(10, 8)), "Keeper placement is once per stage")
	check(w.phase == "defend" and w.tick == 0, "Keeper placement starts clock immediately")
	check(w.valid_animal_site(1, Vector2i(18, 8)), "Deployment preview after autostart")
	check(not w.act("start") and not w.animals[0].placed, "No separate start action; animal remains optional")
	w.act("pause")
	check(w.valid_animal_site(1, Vector2i(18, 8)) and not w.act("place_animal", Vector2i(18, 8), 1), "Pause permits preview only")
	check(not w.act("stay", Vector2i(18, 8), 1), "Reserve animal cannot receive battlefield orders")
	w.act("pause")
	check(not w.act("place_animal", Vector2i(19, 8), 1), "No animal on keeper")
	check(w.act("place_animal", Vector2i(18, 8), 1), "Deploy only during running time")
	check(not w.act("place_animal", Vector2i(5, 5), 1), "Deployment is irreversible within stage")
	check(w.spawn_schedule.size() == 1 and w.spawn_schedule[0].tick == 40 and not w.config.repeat_waves, "Exactly one enemy scheduled at 10s")
	advance(w, 39)
	check(w.enemies.is_empty(), "No early invasion")
	w.step()
	check(w.enemies.size() == 1 and w.enemies[0].born == 40, "Enemy at 10 seconds exactly")
	check(w.enemies[0].hp == 50 and w.enemies[0].attack_power == 5 and w.enemies[0].object_attack_power == 2, "Enemy separate combat/object stats")
	check(w.animals[0].hp == 40 and w.animals[0].attack_power == 10, "Dog fixed attack and provisional HP")
	w = started()
	var cell = Vector2i(10, 8)
	check(w.act("wall", cell) and w.materials == 90 and w.campaign.gold == 12, "Wall consumes soil10, never Gold")
	check(w.structures[cell].status == "building" and w.walkable(cell), "Construction isn't instant or blocking")
	advance(w, 3)
	check(w.structures[cell].status == "building", "Still building at .75s")
	w.act("pause")
	advance(w, 8)
	check(w.structures[cell].remaining == 1, "Pause freezes progress")
	for action in ["wall", "build_gate", "repair", "gate", "remove", "feed", "collect"]:
		check(not w.act(action, cell), "Pause rejects " + action)
	var old_pos = w.animals[0].pos
	check(w.act("whistle", Vector2i(15, 8)) and not w.animals[0].pending.is_empty(), "Paused order queues")
	check(w.animals[0].pos == old_pos, "Queued command doesn't move animal")
	w.act("pause")
	w.step()
	check(w.structures[cell].status == "ready" and w.structures[cell].hp == 8 and not w.walkable(cell), "One second completion HP8")
	check(w.structures[cell].armor == 0 and w.structures[cell].max_hp == 8, "Armor distinct from durability")
	check(not w.act("wall", cell) and not w.act("wall", w.entries[0]), "No double build or entry seal")
	check(w.act("build_gate", Vector2i(10, 9)), "Gate uses provisional configurable cost")
	advance(w, 4)
	check(w.act("gate", Vector2i(10, 9)) and w.walkable(Vector2i(10, 9)), "Open gate traversable")
	check(w.act("gate", Vector2i(10, 9)) and not w.walkable(Vector2i(10, 9)), "Closed gate blocks")
	# A real order walks into the site exactly on its completion tick.
	var crossing = started()
	crossing.animals[0].mode = "whistle"
	crossing.animals[0].order_until = 100
	crossing.animals[0].order = Vector2i(20, 8)
	crossing.animals[0].home = Vector2i(20, 8)
	check(crossing.act("wall", Vector2i(20, 8)), "Start site ahead of animal")
	advance(crossing, 4)
	check(crossing.structures[Vector2i(20, 8)].status == "interrupted" and crossing.materials == 95, "Actor entry at completion interrupts, partial refund only")
	check(crossing.walkable(Vector2i(20, 8)) and crossing.metrics.built == 0, "Interrupted site cannot entomb or block")
	var enemy_site = started()
	check(enemy_site.act("wall", Vector2i(2, 5)), "Enemy worksite")
	enemy_site.spawn_enemy(enemy_site.spawn_schedule[0])
	enemy_site.move_enemy(enemy_site.enemies[0], Vector2i(2, 5))
	check(enemy_site.structures[Vector2i(2, 5)].status == "interrupted", "Actual enemy movement interrupts immediately")
	w.structures[cell].hp = 3
	var before = w.materials
	check(w.act("repair", cell) and w.structures[cell].hp == 8 and before - w.materials == 7, "Proportional rounded repair of five HP")
	check(not w.act("repair", cell), "No overrepair")
	w.structures[cell].hp = 3
	w.materials = 4
	check(w.act("repair", cell) and w.structures[cell].hp == 6 and w.materials == 0, "Partial repair never overspends")
	check(not w.act("repair", cell) and w.materials == 0, "No free fractional repair")
	w.act("pause")
	check(not w.repair(cell), "Direct repair entry respects pause too")
	w.act("pause")
	w.spawn_enemy(w.spawn_schedule[0])
	var e = w.enemies[0]
	w.structures[cell].hp = 4
	w.move_enemy(e, cell)
	check(w.structures[cell].hp == 2, "Object damage2 not animal damage5")
	w.move_enemy(e, cell)
	check(w.structures[cell].hp == 0 and w.structures[cell].status == "destroyed" and w.walkable(cell), "Destroyed record retained without collision")
	# Damage/cooldown fixture holds a chosen intent; probabilistic reactions are evaluated separately.
	var fight = started()
	fight.spawn_enemy(fight.spawn_schedule[0])
	fight.enemies[0].pos = Vector2i(17, 8)
	fight.animals[0].ai_context = "enemy_attack"
	fight.animals[0].intent = "attack"
	fight.animals[0].next_decision = 100
	fight.enemies[0].ai_context = "under_attack"
	fight.enemies[0].intent = "counter"
	fight.enemies[0].next_decision = 100
	fight.step()
	check(fight.enemies[0].hp == 40 and fight.animals[0].hp == 35, "Dog attack10 and immediate counter5, no stagger")
	check(fight.enemies[0].counter_target == 1, "Counterattack targets aggressor")
	fight.animals[0].hp = 0
	fight.step()
	check(fight.enemies[0].counter_target == -1, "Returns to kidnapping after animal incapacity")
	check(fight.result == "", "Animal incapacity isn't instant loss")
	# Identical paths: 2 cells/sec vs 3 cells/sec (not rounded up to 4).
	var normal = started()
	var rescue = started()
	for sim in [normal, rescue]:
		sim.animals[0].pos = Vector2i(2, 8)
		sim.animals[0].home = Vector2i(22, 8)
		sim.animals[0].mode = "whistle"
		sim.animals[0].order = Vector2i(22, 8)
		sim.animals[0].order_until = 100
	rescue.spawn_enemy(rescue.spawn_schedule[0])
	rescue.enemies[0].pos = Vector2i(22, 8)
	rescue.enemies[0].carry = "keeper"
	rescue.keeper.carrier = 0
	for i in range(8):
		normal.tick += 1
		rescue.tick += 1
		normal.animal_step(normal.animals[0])
		rescue.animal_step(rescue.animals[0])
	check(normal.animals[0].pos.x == 6 and rescue.animals[0].pos.x == 8, "Rescue movement is exactly 1.5x")
	check(rescue.animals[0].rescuing and rescue.animals[0].mode == "whistle", "Rescue overrides without erasing orders")
	rescue.animals[0].pos = Vector2i(21, 8)
	rescue.enemies[0].hp = 10
	rescue.animals[0].next_attack = 0
	rescue.animal_step(rescue.animals[0])
	check(rescue.keeper.carrier == -1 and rescue.metrics.rescues == 1, "Actual hit repels carrier and rescues")
	rescue.tick += 1
	rescue.animal_step(rescue.animals[0])
	check(not rescue.animals[0].rescuing and rescue.animals[0].mode == "whistle", "Rescue ends, existing order returns")
	for entry in [Vector2i(1, 5), Vector2i(23, 5), Vector2i(12, 1), Vector2i(12, 15)]:
		var escape = started()
		escape.entries = [entry]
		escape.spawn_enemy({"entry": entry, "role": "kidnapper", "lv": 1})
		escape.enemies[0].carry = "keeper"
		escape.move_enemy(escape.enemies[0], escape.exit_for(entry))
		check(escape.result == "loss" and escape.keeper.state == "abducted", "Capture defeat at configured edge")
	# Persistence: full, damaged, destroyed, gate and unfinished construction survive the shop.
	var carry = started()
	for p in [Vector2i(5, 5), Vector2i(5, 6), Vector2i(5, 7)]: carry.act("wall", p)
	advance(carry, 4)
	carry.structures[Vector2i(5, 6)].hp = 3
	carry.structures[Vector2i(5, 7)].hp = 0
	carry.structures[Vector2i(5, 7)].status = "destroyed"
	carry.act("build_gate", Vector2i(5, 8))
	carry.step()
	carry.finish(true)
	var snapshot = carry.campaign.facilities.duplicate(true)
	check(carry.buy("soil") and carry.materials == 90, "Shop soil pack uses Gold separately")
	var next = Farm.new(carry.next_campaign())
	check(next.materials == 90 and next.campaign.facilities == snapshot, "Shop and stage transition preserve exact facilities")
	check(next.structures[Vector2i(5, 5)].hp == 8 and next.structures[Vector2i(5, 6)].hp == 3 and next.structures[Vector2i(5, 7)].status == "destroyed", "No healing or resurrection")
	check(next.structures[Vector2i(5, 8)].remaining == 3 and next.structures[Vector2i(5, 8)].status == "building", "Unfinished facility retains remaining duration")
	check(not next.act("place", Vector2i(5, 5)), "Keeper can't start inside persisted wall")
	Trial.deploy(next)
	advance(next, 3)
	check(next.structures[Vector2i(5, 8)].status == "ready", "Construction resumes next stage")
	next.structures[Vector2i(5, 6)].hp = 1
	check(carry.campaign.facilities == snapshot and next.checkpoint.facilities == snapshot, "Runtime cannot mutate prior campaign or retry checkpoint")
	check(next.observation().resources.soil == 90 and not JSON.stringify(next.observation()).is_empty(), "Observation includes resources and serializable history")
	var idle = Trial.run_trial("poor", 17)
	var active = Trial.run_trial("guided", 17)
	check(idle.result == "loss" and idle.keeper.state == "abducted" and idle.spawned == 1, "Poor placement can lose to one kidnapper")
	check(active.result == "win" and active.spawned == 1 and active.metrics.built == 2 and active.metrics.orders > 0, "Good placement wins with building and commands")
	check(active.score.xp > 0 and active.score.gold > 0 and active.campaign.animals[0].lv == 2, "Win grants XP, level and Gold")
	check(active.buy(active.shop_stock[0].product) and Farm.new(active.next_campaign()).animals.size() == 2, "Shop animal persists into Stage2")
	check(idle.score.xp == 0 and not idle.buy("hen"), "Failure doesn't grant rewards or shop")
	var hits = active.combat_log.filter(func(c): return c.source == "animal")
	for i in range(1, hits.size()): check(hits[i].tick - hits[i - 1].tick >= 5, "Dog interval1.2s quantized to1.25s")
	# Dynamic pathfinding chooses a detour for sound walls and a breach for weakened walls.
	var paths = started()
	paths.act("wall", Vector2i(10, 8))
	advance(paths, 4)
	check(paths.next_step(Vector2i(9, 8), Vector2i(12, 8), true) != Vector2i(10, 8), "Detour cheaper than four object attacks")
	paths.structures[Vector2i(10, 8)].hp = 1
	check(paths.next_step(Vector2i(9, 8), Vector2i(12, 8), true) == Vector2i(10, 8), "Breach cheaper than detour for damaged wall")
	check(paths.next_step(Vector2i(9, 8), Vector2i(12, 8)) != Vector2i(10, 8), "Animal can't breach")
	var spam = started()
	for y in range(1, 13): spam.act("wall", Vector2i(10, y))
	check(spam.structures.size() == 10 and spam.materials == 0, "Soil100 caps wall spam to ten sites")
	var loyal = started()
	loyal.animals[0].loyalty = 0
	check(not loyal.act("whistle", Vector2i(5, 5)) and loyal.animals[0].attack_power == 10, "Zero loyalty blocks command, never lowers attack")
	loyal.animals[0].loyalty = 75
	loyal.act("whistle", Vector2i(5, 5))
	loyal.step()
	check(loyal.animals[0].mode == "auto", "Loyalty reaction isn't instant")
	loyal.step()
	check(loyal.animals[0].mode == "whistle", "Queued order reacts at .5s")
	var rhythm = Farm.StageData.STAGES[2].duplicate(true)
	var scheduled = Farm.new(Farm.new_campaign(), 17, rhythm)
	check(scheduled.spawn_schedule.size() == 5 and scheduled.spawn_schedule[0].tick == 56, "Stage2 keeps data-driven multiwave schedule")
	rhythm.repeat_waves = true
	rhythm.repeat_interval_seconds = 30.0
	var repeating = Farm.new({}, 17, rhythm)
	repeating.schedule_cycle = 1
	repeating.make_schedule()
	check(repeating.spawn_schedule[0].tick == 176, "Repeat schedules use seconds and cycle offset")
	var flock = Farm.new_campaign()
	flock.animals.append({"id": 2, "category": "bird", "species": "hen", "lv": 1, "xp": 0, "loyalty": 0})
	var production = Farm.new(flock)
	Trial.deploy(production)
	advance(production, 40)
	check(production.eggs == 1, "Hen still produces eggs")
	production.act("pause")
	check(not production.act("collect", production.nest) and production.eggs == 1, "Paused collection preserves eggs")
	production.act("pause")
	check(production.act("collect", production.nest) and production.campaign.eggs == 1, "Collection transfers inventory")
	production.finish(true)
	check(production.sell("egg") and production.campaign.eggs == 0, "Product economy preserved")
	var occupied_future = started()
	occupied_future.act("wall", Farm.NEST)
	occupied_future.act("wall", Vector2i(1, 12))
	advance(occupied_future, 4)
	occupied_future.finish(true)
	occupied_future.shop_stock.append({"product": "hen", "remaining": 1, "individual": {"loyalty": 0}})
	occupied_future.buy("hen")
	var inherited = Farm.new(occupied_future.next_campaign())
	check(inherited.nest != Farm.NEST and not inherited.animals[1].placed and inherited.walkable(inherited.nest), "Purchased hen doesn't spawn in retained wall")
	check(inherited.structures[Farm.NEST].hp == 8, "Relocating hen doesn't remove facility")
	inherited.spawn_enemy({"entry": Vector2i(1, 12), "role": "kidnapper", "lv": 1})
	check(inherited.enemies[0].pos == Vector2i(0, 12), "New-stage blocked entrance spawns enemy outside")
	inherited.move_enemy(inherited.enemies[0], Vector2i(1, 12))
	check(inherited.structures[Vector2i(1, 12)].hp == 6 and inherited.enemies[0].pos == Vector2i(0, 12), "Enemy must break persisted entry wall before entering")
	var front = Trial.run_trial("front")
	check(front.result == "win" and front.animals[0].hp > 0 and front.animals[0].hp < 40 and front.enemies[0].hp == 0, "Full-HP 1v1: Shiba wins, takes variable damage")
	var saved = Trial.run_trial("rescue")
	check(saved.result == "win" and saved.metrics.captures == 1 and saved.metrics.rescues == 1, "Real placement + stay leads to capture and instinct rescue")
	check(saved.milestones.any(func(m): return m.kind == "restrained") and saved.milestones.any(func(m): return m.kind == "carried"), "Distinct restraint/carriage alerts")
	var choose = Farm.new(flock)
	choose.act("place", Vector2i(19, 8))
	choose.act("start")
	choose.act("place_animal", Vector2i(18, 8), 1)
	check(not choose.act("place_animal", Vector2i(18, 8), 2), "Animals cannot overlap at placement")
	choose.act("place_animal", choose.nest, 2)
	choose.act("start")
	choose.animals[1].loyalty = 75
	choose.act("pause")
	choose.act("stay", Vector2i(14, 8), 1)
	check(not choose.animals[0].pending.is_empty() and choose.animals[1].pending.is_empty(), "Command targets chosen individual only")
	var hurt = started()
	hurt.spawn_enemy(hurt.spawn_schedule[0])
	hurt.enemies[0].pos = Vector2i(17, 8)
	hurt.enemies[0].counter_target = 1
	hurt.enemies[0].counter_until = 100
	hurt.enemies[0].attacker = 1
	hurt.enemies[0].threat_until = 100
	hurt.enemies[0].ai_context = "under_attack"
	hurt.enemies[0].intent = "counter"
	hurt.enemies[0].next_decision = 100
	hurt.animals[0].hp = 15
	hurt.enemy_step(hurt.enemies[0])
	check(hurt.milestones.any(func(m): return m.kind == "animal_danger") and hurt.animals[0].hp == 10, "HP threshold crossing emits warning")
	# Late deployment checks occupancy against actors, facilities and entrances.
	var late = Farm.new()
	late.act("place", Vector2i(19, 8))
	late.act("start")
	advance(late, 45)
	check(not late.animals[0].placed and late.animals[0].path.size() == 1, "Reserve animal neither moves nor attacks")
	check(not late.act("place_animal", late.enemies[0].pos, 1), "Cannot deploy on intruder")
	check(not late.act("place_animal", late.entries[0], 1), "Cannot deploy at entrance")
	late.act("wall", Vector2i(10, 8))
	check(not late.act("place_animal", Vector2i(10, 8), 1), "Cannot deploy inside construction")
	check(late.act("place_animal", Vector2i(18, 8), 1) and late.initial_positions.animals[0].deployment_tick == 45, "Late deployment records real tick")
	late.animals[0].hp = 0
	check(not late.act("place_animal", Vector2i(10, 9), 1), "Incapacitated deployed animal stays deployed")
	var reserve = Farm.new(flock)
	reserve.act("place", Vector2i(19, 8))
	reserve.act("start")
	reserve.act("place_animal", Vector2i(18, 8), 1)
	reserve.finish(true)
	check(reserve.campaign.animals[1].xp == 0, "Unfielded reserve receives no participation XP")
	var original = Trial.run_trial("guided", 17)
	var replay = Farm.new({}, original.seed_value)
	for action in original.actions:
		while replay.tick < action.tick: replay.step()
		check(replay.act(action.kind, Vector2i(action.pos[0], action.pos[1]), action.animal_id) == action.accepted, "Replay action accepted identically")
	while replay.phase == "defend" and replay.tick < 1200: replay.step()
	check(JSON.stringify(replay.observation()) == JSON.stringify(original.observation()), "Seed + exact timed actions reproduce full observation")
	check(JSON.stringify(front.decision_log) != JSON.stringify(Trial.run_trial("front", 18).decision_log), "Different seed changes decisions")
	var held = started()
	held.spawn_enemy(held.spawn_schedule[0])
	held.step()
	var count_before = held.decision_count
	held.step()
	check(held.decision_count == count_before, "Unchanged context holds decision, no per-tick draw")
	check(saved.decision_log.filter(func(d): return d.rescue_mode).all(func(d): return d.selected in ["attack", "approach"]), "Rescue never chooses passive behavior")
	check(saved.decision_log.size() <= Farm.Rules.AI.log_limit, "Decision log is bounded")
	check_new_rules()
	check_rest_and_kennels()
	check_dismantle()
	check_economy()
	print("PASS: %d Stage1 and campaign checks" % checks)
	quit()

func check_dismantle():
	var w = quiet_farm()
	var p = Vector2i(5, 5)
	check(w.act("wall", p), "Build refund fixture")
	check(w.dismantle_quote(p) == 0, "Unfinished construction has no completed durability to refund")
	for i in range(4): w.step()
	check(w.dismantle_quote(p) == 8, "Full 10-soil wall refunds 8")
	w.structures[p].hp = 4
	check(w.dismantle_quote(p) == 4, "Half wall refunds 4")
	w.structures[p].hp = 3
	check(w.dismantle_quote(p) == 3, "Damaged wall refund floors per facility")
	var before = w.materials
	w.paused = true
	check(not w.act("remove", p) and w.materials == before, "Paused dismantle cannot refund")
	w.paused = false
	check(w.act("remove", p) and w.materials == before + 3, "Remove credits quoted soil")
	check(not w.act("remove", p) and w.dismantle_quote(p) == 0 and w.materials == before + 3, "Cannot refund a facility twice")
	check(w.act("build_gate", p), "Gate refund fixture")
	for i in range(4): w.step()
	w.structures[p].hp = 1
	check(w.dismantle_quote(p) == 4, "Gate shares the cost/durability formula")
	w.structures[p].status = "destroyed"
	w.structures[p].hp = 0
	check(w.dismantle_quote(p) == 0 and not w.act("remove", p), "Destroyed facility has no refund")

func check_new_rules():
	var w = started()
	w.spawn_enemy(w.spawn_schedule[0])
	var a = w.animals[0]
	var e = w.enemies[0]
	e.pos = a.pos - Vector2i(4, 0)
	w.try_bark(a)
	check(w.metrics.bark_casts == 1 and w.metrics.bark_targets == 1 and e.hp == 50, "Bark detects at range4 without damage")
	var from: Vector2i = e.pos
	w.move_enemy(e, from + Vector2i.RIGHT)
	check(e.pos == from, "Bark blocks movement")
	w.tick = 3
	w.move_enemy(e, from + Vector2i.RIGHT)
	check(e.pos == from, "Stop persists through .75s")
	w.tick = 4
	w.move_enemy(e, from + Vector2i.RIGHT)
	check(e.pos != from, "Stop ends at 1s")
	w.tick = 23
	w.try_bark(a)
	check(w.metrics.bark_casts == 1, "Bark not ready at 5.75s")
	w.tick = 24
	w.try_bark(a)
	check(w.metrics.bark_casts == 2 and w.skill_log.size() == 2, "Bark cooldown6s logged")
	e.pos = a.pos - Vector2i.RIGHT
	e.attacker = a.id
	e.threat_until = 100
	e.counter_target = a.id
	e.counter_until = 100
	e.ai_context = "under_attack"
	e.intent = "counter"
	e.next_decision = 100
	w.enemy_step(e)
	check(a.hp == 35, "Movement stop does not interrupt enemy attacks")
	var n = started()
	n.act("pause")
	advance(n, 32)
	check(n.natural.is_empty(), "Paused world cannot grow resources")
	n.act("pause")
	advance(n, 16)
	check(n.metrics.nature_rolls == 4, "Four game seconds perform four probability rolls")
	var snapshot = Farm.new({}, n.seed_value)
	Trial.deploy(snapshot)
	advance(snapshot, 16)
	check(snapshot.natural == n.natural, "Growth uses reproducible independent seed")
	var p = Vector2i(10, 7)
	n.natural[p] = "weed"
	var gold = n.campaign.gold
	n.act("pause")
	check(not n.act("collect", p) and n.natural.has(p), "Paused harvest denied")
	n.act("pause")
	check(n.act("collect", p) and n.campaign.gold == gold + 1 and not n.act("collect", p), "Weed grants1Gold exactly once")
	n.natural[p] = "mushroom"
	n.animals[0].hp = 32
	check(n.act("collect", p) and n.campaign.mushrooms == 1 and n.animals[0].hp == 32, "Mushroom is stored, not instant healing")
	n.finish(true)
	check(n.animals[0].hp == 37 and n.campaign.mushrooms == 0 and n.metrics.mushroom_healing == 5, "Stage end spends mushroom to heal5")
	var next = Farm.new(n.next_campaign())
	check(next.animals[0].hp == 37, "Remaining HP survives stage transition")
	var full = started()
	full.campaign.mushrooms = 3
	full.animals[0].hp = 39
	full.finish(true)
	check(full.animals[0].hp == 40 and full.campaign.mushrooms == 2, "Healing capped; surplus mushrooms retained")
	var wander = started()
	check(wander.act("wander", Vector2i(-100, -100), 1) and wander.animals[0].pending.pos == wander.animals[0].pos, "Wander uses current position without destination")

func quiet_farm(two_dogs: bool = false):
	var data = Farm.new_campaign()
	data.unlocked_blueprints = ["kennel"] # Isolated rest/kennel fixture.
	data.resources.wood = 100
	if two_dogs:
		var second = data.animals[0].duplicate(true)
		second.id = 2
		data.animals.append(second)
	var conf = Farm.StageData.STAGES[1].duplicate(true)
	conf.first_attack_seconds = 999.0
	var w = Farm.new(data, 17, conf)
	w.act("place", Vector2i(19, 8))
	w.act("place_animal", Vector2i(12, 8), 1)
	if two_dogs: w.act("place_animal", Vector2i(12, 10), 2)
	return w

func check_rest_and_kennels():
	var w = quiet_farm()
	var a = w.animals[0]
	a.hp = 20
	w.act("pause")
	check(w.act("rest", Vector2i.ZERO, 1) and a.mode == "auto", "Pause queues rest without immediate AI or HP changes")
	advance(w, 40)
	check(a.hp == 20 and w.tick == 0, "Paused rest never heals or advances")
	w.act("pause")
	advance(w, 2)
	check(a.mode == "rest" and a.state == "休む", "Rest accepted at loyalty response deadline")
	var base = a.hp
	advance(w, 19)
	check(a.hp == base + 1, "Five stationary rest seconds heals exactly1")
	advance(w, 240)
	check(a.mode == "rest", "Explicit rest outlasts ordinary order timeout")
	w.spawn_enemy(w.spawn_schedule[0])
	var e = w.enemies[0]
	e.pos = a.pos + Vector2i.RIGHT
	e.carry = "keeper"
	w.keeper.carrier = e.id
	w.keeper.state = "captured"
	var pos = a.pos
	var casts = w.metrics.bark_casts
	for i in range(20):
		w.tick += 1
		w.animal_step(a)
	check(a.pos == pos and e.hp == 50 and not a.rescuing and w.metrics.bark_casts == casts, "Rest ignores carrier and nearby threat: no chase, attack or bark")
	w.act("auto", Vector2i.ZERO, 1)
	for i in range(2):
		w.tick += 1
		w.animal_step(a)
	check(a.mode == "auto" and a.rescuing, "Auto cancels rest and restores rescue priority")

	w = quiet_farm(true)
	var house = Vector2i(13, 8)
	check(w.act("kennel", house), "Kennel build uses normal live construction")
	advance(w, 8)
	check(w.structures[house].status == "ready" and w.walkable(house), "Kennel completes and is enterable")
	for dog in w.animals:
		dog.hp = 20
		w.act("rest", Vector2i.ZERO, dog.id)
	advance(w, 10)
	check(w.animals[0].pos == house and w.animals[0].kennel_id == w.structures[house].id, "Nearest available kennel claimed")
	check(w.animals[1].kennel_id == -1 and w.animals[1].state == "休む", "Second dog rests in place when house reserved")
	var owner = w.animals[0]
	owner.hp = 20
	owner.rest_ticks = 0
	owner.kennel_ticks = 0
	advance(w, 20)
	check(owner.hp == 26, "Five seconds: kennel+5 and rest+1 stack")
	owner.hp = 39
	advance(w, 20)
	check(owner.hp == 40, "Stacked healing capped at max HP")
	w.act("stay", Vector2i(17, 8), owner.id)
	advance(w, 10)
	check(owner.pos != house and w.kennel_owner(house) == -1, "Leaving releases exclusive house")
	w.act("rest", Vector2i.ZERO, 2)
	advance(w, 12)
	check(w.animals[1].pos == house, "Next dog can use released kennel")
	# Stationary stay still receives the facility effect, independent of the rest command.
	w.act("stay", house, 2)
	advance(w, 2)
	w.animals[1].hp = 20
	w.animals[1].kennel_ticks = 0
	advance(w, 20)
	check(w.animals[1].hp == 25, "Kennel alone heals1 per second without rest bonus")

	w = quiet_farm()
	w.act("kennel", Vector2i(13, 8))
	advance(w, 8)
	w.animals[0].hp = 15
	advance(w, 12)
	check(w.animals[0].auto_recovering and w.animals[0].kennel_id >= 0, "Hurt auto dog seeks available nearby house")
	w.spawn_enemy(w.spawn_schedule[0])
	w.enemies[0].pos = Vector2i(18, 8)
	w.enemies[0].carry = "keeper"
	w.keeper.carrier = 0
	w.keeper.state = "captured"
	w.tick += 1
	w.animal_step(w.animals[0])
	check(w.animals[0].rescuing and w.animals[0].kennel_id == -1, "Auto recovery yields immediately to rescue")
	w = quiet_farm()
	w.act("kennel", Vector2i(13, 8))
	advance(w, 8)
	w.act("rest", Vector2i.ZERO, 1)
	advance(w, 8)
	w.structures[Vector2i(13, 8)].status = "destroyed"
	advance(w, 8)
	check(w.animals[0].kennel_id == -1 and w.animals[0].mode == "rest", "Destroyed house releases claim, rest continues in place")

func check_economy():
	var locked = started()
	locked.add_resource("wood", 20)
	check(not locked.act("kennel", Vector2i(13, 8)), "Wood alone cannot bypass blueprint")
	locked.grant_blueprint("kennel", Vector2i(12, 8))
	check(locked.act("kennel", Vector2i(13, 8)) and locked.wood == 0 and locked.materials == 100, "Unlocked kennel consumes wood20 only")
	advance(locked, 8)
	locked.structures[Vector2i(13, 8)].hp = 6
	locked.add_resource("wood", 10)
	check(locked.act("repair", Vector2i(13, 8)) and locked.wood == 0, "Kennel repair consumes wood proportional to damage")
	check(locked.act("remove", Vector2i(13, 8)) and locked.wood == 16 and locked.materials == 100, "Kennel dismantle refunds wood, not soil")
	var won = Trial.run_trial("front", 17)
	check(won.phase == "shop" and won.campaign.unlocked_blueprints == ["kennel"] and won.item_count("kennel_plan") == 1, "First Stage1 defeat auto awards blueprint and enters shop")
	won.grant_blueprint("kennel", Vector2i.ZERO)
	check(won.item_count("kennel_plan") == 1, "Blueprint grant idempotent")
	check(won.sell("kennel_plan") and "kennel" in won.campaign.unlocked_blueprints, "Selling plan never revokes ability")
	check(won.buy("wood") and won.wood == 20, "Shop buys wood pack")
	var profit = won.campaign.gold
	check(won.sell("wood") and won.buy("wood") and won.campaign.gold < profit, "Resource roundtrip loses Gold")
	check(won.buy("dog_food"), "Category food stocked")
	var after = Farm.new(won.next_campaign(), 18)
	check(after.wood == 20 and "kennel" in after.campaign.unlocked_blueprints and after.campaign.items.dog_food == 3, "Resources, blueprint and food persist")
	var retry = Farm.new(won.checkpoint, won.seed_value)
	check(retry.phase == "prepare" and retry.materials == 100 and retry.wood == 0 and retry.campaign.gold == 12 and retry.campaign.unlocked_blueprints.is_empty(), "Restart discards Stage rewards and purchases")
	var assortments = {}
	for seed_id in range(1, 33):
		var list = Farm.Shop.generate(1, seed_id, [])
		check(list == Farm.Shop.generate(1, seed_id, []), "Shop seed reproducible")
		check(list.filter(func(row): return row.product in ["shiba", "hen"]).size() == 1, "Exactly one randomly stocked animal")
		assortments[list[0].product] = true
	check(assortments.size() == 2, "Seeds produce different animal stock")
	var trade = Trial.run_trial("front", 17)
	trade.campaign.gold = 500
	var species = trade.shop_stock[0].product
	var initial_gold = trade.campaign.gold
	check(trade.buy(species) and trade.campaign.animals.size() == 2, "Animal stock creates an individual")
	check(not trade.buy(species), "Purchased animal stock cannot be bought twice")
	check(trade.sell(species, trade.campaign.animals[1].id) and trade.campaign.gold < initial_gold, "Animal resale loses Gold")
	check(not trade.sell("shiba", 1), "Last owned animal cannot be sold")
	initial_gold = trade.campaign.gold
	var food_before = trade.item_count("hen_food")
	check(trade.buy("hen_food") and trade.sell("hen_food") and trade.item_count("hen_food") == food_before and trade.campaign.gold < initial_gold, "Item roundtrip loses Gold and preserves quantity")
	trade.paused = true
	check(not trade.buy("soil") and not trade.sell("soil"), "Paused shop rejects world mutations")
	for p in Farm.Shop.table().values(): check(p.BuyPrice > p.SellPrice, "Every product buys above its sale price")
	var n = quiet_farm()
	n.nature_config.spawn_chance_per_second = 1.0
	for i in range(1000):
		n.step()
		for p in n.natural.keys(): n.act("collect", p)
	check(n.metrics.nature_rolls == 250, "One draw per game second")
	for kind in n.nature_config.caps: check(n.metrics[kind + "_spawned"] == n.nature_config.caps[kind], "Harvest does not reopen stage spawn cap")
	check(n.metrics.stump_collected == 1 and n.wood == 120, "Rare stump grants wood20")
	var rolls = n.metrics.nature_rolls
	n.paused = true
	advance(n, 40)
	check(n.metrics.nature_rolls == rolls, "Pause never rolls nature")
	var f = quiet_farm(true)
	f.animals[0].hp = 20
	f.animals[1].hp = 21
	f.campaign.mushrooms = 2
	f.heal_with_mushrooms()
	check(f.animals[0].hp == 25 and f.animals[1].hp == 26, "Mushroom recomputes lowest ratio after each use")
	f.animals[0].hp = 0
	f.animals[1].hp = 40
	f.campaign.mushrooms = 1
	f.heal_with_mushrooms()
	check(f.campaign.mushrooms == 1 and f.animals[0].hp == 0, "Only deployed survivors receive mushrooms")
	f.animals[0].hp = 20
	var meals = f.campaign.items.dog_food
	f.paused = true
	check(not f.act("dog_food", f.animals[0].pos, 1), "Food disallowed while paused")
	f.paused = false
	check(f.act("dog_food", f.animals[0].pos, 1) and f.animals[0].hp == 30 and f.campaign.items.dog_food == meals - 1, "Dog food heals compatible animal")
	f.campaign.items.hen_food = 1
	check(not f.act("hen_food", f.animals[0].pos, 1) and f.campaign.items.hen_food == 1, "Wrong-category food not consumed")
