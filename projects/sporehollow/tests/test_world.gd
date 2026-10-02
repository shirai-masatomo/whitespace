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
	check(w.materials == 100 and w.campaign.resources == {"soil": 100}, "Only soil as building material")
	check(not w.act("start"), "Placement before clock")
	w.step()
	check(w.tick == 0, "Placement freezes clock")
	check(w.act("place", Vector2i(19, 8)) and not w.animals[0].placed, "Keeper placement never places dog")
	check(not w.act("place", Vector2i(10, 8)), "Keeper placement is once per stage")
	check(w.ready_to_start(), "Keeper alone enables clock")
	check(w.valid_animal_site(1, Vector2i(18, 8)) and not w.act("place_animal", Vector2i(18, 8), 1), "Preview before clock, no world deployment")
	check(w.act("start") and not w.animals[0].placed, "Clock can start with every animal in reserve")
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
	check(w.act("wall", cell) and w.materials == 80 and w.campaign.gold == 12, "Wall consumes soil20, never Gold")
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
	check(crossing.structures[Vector2i(20, 8)].status == "interrupted" and crossing.materials == 90, "Actor entry at completion interrupts, partial refund only")
	check(crossing.walkable(Vector2i(20, 8)) and crossing.metrics.built == 0, "Interrupted site cannot entomb or block")
	var enemy_site = started()
	check(enemy_site.act("wall", Vector2i(2, 5)), "Enemy worksite")
	enemy_site.spawn_enemy(enemy_site.spawn_schedule[0])
	enemy_site.move_enemy(enemy_site.enemies[0], Vector2i(2, 5))
	check(enemy_site.structures[Vector2i(2, 5)].status == "interrupted", "Actual enemy movement interrupts immediately")
	w.structures[cell].hp = 3
	var before = w.materials
	check(w.act("repair", cell) and w.structures[cell].hp == 8 and before - w.materials == 13, "Proportional rounded repair of five HP")
	check(not w.act("repair", cell), "No overrepair")
	w.structures[cell].hp = 3
	w.materials = 4
	check(w.act("repair", cell) and w.structures[cell].hp == 4 and w.materials == 1, "Partial repair never overspends")
	check(not w.act("repair", cell) and w.materials == 1, "No free fractional repair")
	w.act("pause")
	check(not w.repair(cell), "Direct repair entry respects pause too")
	w.act("pause")
	w.spawn_enemy(w.spawn_schedule[0])
	var e = w.enemies[0]
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
	check(carry.buy("soil") and carry.materials == 60, "Shop soil pack uses Gold separately")
	var next = Farm.new(carry.next_campaign())
	check(next.materials == 60 and next.campaign.facilities == snapshot, "Shop and stage transition preserve exact facilities")
	check(next.structures[Vector2i(5, 5)].hp == 8 and next.structures[Vector2i(5, 6)].hp == 3 and next.structures[Vector2i(5, 7)].status == "destroyed", "No healing or resurrection")
	check(next.structures[Vector2i(5, 8)].remaining == 3 and next.structures[Vector2i(5, 8)].status == "building", "Unfinished facility retains remaining duration")
	check(not next.act("place", Vector2i(5, 5)), "Keeper can't start inside persisted wall")
	Trial.deploy(next)
	advance(next, 3)
	check(next.structures[Vector2i(5, 8)].status == "ready", "Construction resumes next stage")
	next.structures[Vector2i(5, 6)].hp = 1
	check(carry.campaign.facilities == snapshot and next.checkpoint.facilities == snapshot, "Runtime cannot mutate prior campaign or retry checkpoint")
	check(next.observation().resources.soil == 60 and not JSON.stringify(next.observation()).is_empty(), "Observation includes resources and serializable history")
	var idle = Trial.run_trial("poor", 17)
	var active = Trial.run_trial("guided", 17)
	check(idle.result == "loss" and idle.keeper.state == "abducted" and idle.spawned == 1, "Poor placement can lose to one kidnapper")
	check(active.result == "win" and active.spawned == 1 and active.metrics.built == 2 and active.metrics.orders > 0, "Good placement wins with building and commands")
	check(active.score.xp > 0 and active.score.gold > 0 and active.campaign.animals[0].lv == 2, "Win grants XP, level and Gold")
	check(active.buy("hen") and Farm.new(active.next_campaign()).animals.size() == 2, "Shop animal persists into Stage2")
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
	for y in range(1, 10): spam.act("wall", Vector2i(10, y))
	check(spam.structures.size() == 5 and spam.materials == 0, "Soil100 caps wall spam to five sites")
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
	check(production.buy("sell_egg") and production.campaign.eggs == 0, "Product economy preserved")
	var occupied_future = started()
	occupied_future.act("wall", Farm.NEST)
	occupied_future.act("wall", Vector2i(1, 12))
	advance(occupied_future, 4)
	occupied_future.finish(true)
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
	print("PASS: %d Stage1 and campaign checks" % checks)
	quit()
