extends SceneTree
const Farm = preload("res://tests/rule_fixture.gd")
const Trial = preload("res://tests/evaluate.gd")
var checks = 0

func check(value: bool, reason: String):
	checks += 1
	if not value:
		push_error(reason)
		quit(1)
		assert(value, reason)

func started():
	var w = night()
	Trial.deploy(w)
	return w

func advance(w, count: int):
	for i in range(count): w.step()

func _initialize(): call_deferred("run")
func run():
	var w = night()
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
	check(w.act("wall", cell) and w.materials == 90 and w.campaign.gold == 40, "Wall consumes soil10, never Gold")
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
	crossing.keeper.pos = Vector2i(19, 7)
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
	carry = Farm.new(carry.next_campaign())
	check(carry.buy("soil") and carry.materials == 90, "Shop soil pack uses Gold separately")
	var next = night(carry.next_campaign())
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
	check(active.score.xp > 0 and active.score.gold > 0 and active.campaign.animals[0].lv == 1 and active.campaign.exp_pool > 0, "Win grants shared XP and Gold without auto leveling")
	var morning = Farm.new(active.next_campaign())
	check(morning.buy("hen") and morning.begin_night().animals.size() == 2, "Shop animal persists into next night")
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
	var scheduled = night(Farm.new_campaign(), 17, rhythm)
	check(scheduled.spawn_schedule.size() == 5 and scheduled.spawn_schedule[0].tick == 56, "Stage2 keeps data-driven multiwave schedule")
	rhythm.repeat_waves = true
	rhythm.repeat_interval_seconds = 30.0
	var repeating = night({}, 17, rhythm)
	repeating.schedule_cycle = 1
	repeating.make_schedule()
	check(repeating.spawn_schedule[0].tick == 176, "Repeat schedules use seconds and cycle offset")
	var flock = Farm.new_campaign()
	flock.animals.append({"id": 2, "category": "bird", "species": "hen", "lv": 1, "xp": 0, "loyalty": 0})
	var production = night(flock)
	Trial.deploy(production)
	advance(production, 40)
	check(production.field_items.is_empty(), "No continuous night egg production")
	production.finish(true)
	check(production.field_items.any(func(item): return item.kind == "egg"), "Dawn lays eggs on field")
	var occupied_future = started()
	occupied_future.act("wall", Farm.NEST)
	occupied_future.act("wall", Vector2i(1, 12))
	advance(occupied_future, 4)
	occupied_future.finish(true)
	occupied_future = Farm.new(occupied_future.next_campaign())
	occupied_future.shop_stock.append({"product": "hen", "remaining": 1, "individual": {"loyalty": 0}})
	occupied_future.buy("hen")
	var inherited = night(occupied_future.next_campaign())
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
	check(saved.milestones.any(func(m): return m.kind == "keeper_down") and saved.milestones.any(func(m): return m.kind == "carried"), "Distinct unconscious/carriage alerts")
	var choose = night(flock)
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
	var late = night()
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
	var reserve = night(flock)
	reserve.act("place", Vector2i(19, 8))
	reserve.act("start")
	reserve.act("place_animal", Vector2i(18, 8), 1)
	reserve.finish(true)
	check(reserve.campaign.animals[1].xp == 0, "Unfielded reserve receives no participation XP")
	var original = Trial.run_trial("guided", 17)
	var replay = Farm.new(original.checkpoint, original.seed_value)
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
	sight_and_skills()
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
	var snapshot = night({}, n.seed_value)
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
	var next = night(n.next_campaign())
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
	conf.time_limit_seconds = 999.0
	var w = night(data, 17, conf)
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

func night(data: Dictionary = {}, seed_id: int = 17, config: Dictionary = {}):
	var campaign = Farm.new_campaign() if data.is_empty() else data.duplicate(true)
	campaign.night_ready = true
	return Farm.new(campaign, seed_id, config)

func check_economy():
	var shop = Farm.new({}, 17)
	check(shop.phase == "shop" and shop.campaign.gold == 40 and shop.animals.size() == 1, "Campaign starts at funded shop with one Shiba")
	check(shop.buy("hen") and shop.campaign.gold == 10 and not shop.buy("wood"), "Hen purchase limits material budget")
	var w = shop.begin_night()
	check(w.phase == "prepare" and w.animals.size() == 2, "Bought animal enters night preparation")
	Trial.deploy(w)
	check(not w.issue_order("rest", Vector2i.ZERO, 2), "Hen cannot receive commands")
	while not w.early_clear and w.phase == "defend": w.step()
	check(w.early_clear and w.phase == "defend" and w.result == "", "Repelling enemies confirms defense but leaves work time")
	check(w.field_items.any(func(item): return item.kind == "kennel_plan") and "kennel" not in w.campaign.unlocked_blueprints, "Blueprint drops without unlocking")
	var plan = w.field_items.filter(func(item): return item.kind == "kennel_plan")[0].pos
	w.paused = true
	check(not w.act("collect", plan) and not w.act("end_night"), "Pause blocks collection and early ending")
	var frozen = w.tick
	advance(w, 20)
	check(w.tick == frozen, "Pause freezes night time")
	w.paused = false
	check(w.act("collect", plan) and "kennel" in w.campaign.unlocked_blueprints, "Manual collection unlocks kennel")
	w.add_resource("wood", 20)
	check(w.act("kennel", Vector2i(12, 9)), "Can construct after early clear")
	advance(w, 8)
	var before = w.remaining_night()
	check(w.act("end_night") and w.phase == "dawn", "Player chooses early dawn")
	check(w.early_finish_bonus == floori(before / 10) and w.campaign.exp_pool == w.score.xp and w.campaign.animals[0].lv == 1, "Remaining-time bonus and pooled XP, no auto level")
	var day = Farm.new(w.next_campaign(), 18)
	check(day.campaign.day == 2 and day.stage == 1 and day.phase == "shop", "Next day reuses Stage1 rather than adding a stage")
	check(day.rename_animal(1, "こむぎ") and day.campaign.animals[0].name == "こむぎ", "Individual can be named")
	check(day.train_animal(1) and day.campaign.animals[0].lv == 2, "Player allocates shared XP")
	day.campaign.exp_pool = 1000
	for i in range(8): day.train_animal(1)
	check(day.campaign.animals[0].lv == 5 and not day.train_animal(1), "Level cap5 enforced")
	var next = day.begin_night()
	check(next.animals[0].name == "こむぎ" and next.animals[0].lv == 5 and not next.train_animal(1), "Name/level carried, night training forbidden")
	var retry = Farm.new(next.checkpoint, next.seed_value)
	check(retry.phase == "prepare" and retry.campaign == next.checkpoint, "Retry preserves post-shopping night checkpoint")
	# Survive the clock, even when scheduled enemies are not all beaten.
	var survival = night()
	survival.config.first_attack_seconds = 999
	survival.make_schedule()
	survival.act("place", Vector2i(19, 8))
	advance(survival, 719)
	check(survival.phase == "defend" and survival.remaining_night() == 0.25, "Night lasts full180 game seconds")
	survival.spawn_enemy(survival.spawn_schedule[0]) # Dawn must win even with a live raider still on the field.
	survival.step()
	check(survival.phase == "dawn" and survival.result == "win" and survival.early_finish_bonus == 0, "Dawn survival succeeds without early bonus")
	var missed = Trial.run_trial("front", 17)
	check("kennel" not in missed.campaign.unlocked_blueprints and missed.campaign.field_items.any(func(item): return item.kind == "kennel_plan"), "Early finish does not discard or auto collect blueprint")
	var carry = Farm.new(missed.next_campaign()).begin_night()
	Trial.deploy(carry)
	var retained = carry.field_items.filter(func(item): return item.kind == "kennel_plan")[0]
	check(carry.act("collect", retained.pos) and "kennel" in carry.campaign.unlocked_blueprints, "Missed blueprint can be collected next night")
	# Unconscious today, unavailable all tomorrow, returns following day at half HP.
	var faint = started()
	faint.animals[0].hp = 0
	faint.finish(true)
	var restday = Farm.new(faint.next_campaign()).begin_night()
	restday.act("place", Vector2i(19, 8))
	check(not restday.available(restday.animals[0]) and not restday.act("place_animal", Vector2i(18, 8), 1), "Unconscious dog cannot deploy tomorrow")
	restday.finish(true)
	var recovered = Farm.new(restday.next_campaign()).begin_night()
	check(recovered.animals[0].hp == 20 and recovered.available(recovered.animals[0]), "Dog returns on following day with provisional half HP")
	# Day-aged eggs transform once per dawn, never inside inventory.
	var hatch = started()
	hatch.field_items = [{"kind": "egg", "pos": Vector2i(8, 8), "born_day": 0}]
	hatch.finish(true)
	check(hatch.field_items[0].kind == "chick", "One day field egg becomes chick")
	var hatch2 = Farm.new(hatch.next_campaign()).begin_night()
	hatch2.finish(true)
	check(hatch2.campaign.animals.size() == 2 and hatch2.field_items.is_empty(), "Following day chick becomes owned hen")
	var cat = Farm.new()
	check(cat.buy("cat"), "Cat available in first shop")
	cat = cat.begin_night()
	Trial.deploy(cat)
	check(cat.animals[1].affinity == 0 and cat.animals[1].attack_power == 0 and not cat.issue_order("stay", Vector2i(8, 8), 2), "Cat affinity supported, no attack or instructions")
	for p in Farm.Shop.table().values(): check(p.BuyPrice > p.SellPrice, "No product has resale profit")
	var budget = Farm.new()
	check(budget.buy("wood") and budget.sell("wood") and budget.campaign.gold == 32, "Resource roundtrip loses Gold")
	var n = quiet_farm()
	n.nature_config.spawn_chance_per_second = 1.0
	for i in range(1000):
		n.step()
		for p in n.natural.keys(): n.act("collect", p)
	for kind in n.nature_config.caps: check(n.metrics[kind + "_spawned"] == n.nature_config.caps[kind], "Harvest never reopens finite cap")
	# Coop basic recovery and persistent, sheltered eggs; no new thief AI is introduced.
	var poultry = Farm.new()
	poultry.buy("hen")
	poultry.add_resource("wood", 30)
	poultry = poultry.begin_night()
	poultry.config.first_attack_seconds = 999
	poultry.make_schedule()
	poultry.act("place", Vector2i(19, 8))
	check(poultry.act("coop", Vector2i(12, 12)), "Coop consumes wood30")
	advance(poultry, 8)
	check(poultry.act("place_animal", Vector2i(13, 12), 2), "Hen deploys beside completed coop")
	advance(poultry, 8)
	poultry.animals[1].hp = 10
	advance(poultry, 20)
	check(poultry.animals[1].hp == 15 and poultry.animals[1].pos == Vector2i(12, 12), "Coop heals1 per second without commands")
	poultry.finish(true)
	var laid = poultry.field_items.filter(func(item): return item.kind == "egg")[0]
	check(laid.protected_by == poultry.structures[Vector2i(12, 12)].id, "Coop egg retains protection metadata")
	var tomorrow = Farm.new(poultry.next_campaign()).begin_night()
	tomorrow.act("place", Vector2i(19, 8))
	check(tomorrow.act("collect", laid.pos) and tomorrow.item_count("egg") == 1, "Field egg can be collected next night")
	tomorrow.finish(true)
	check(tomorrow.dawn_summary.chicks == 0 and tomorrow.campaign.eggs == 1, "Collected egg never hatches")
	var planned = started()
	planned.drop_blueprint(Vector2i(10, 10))
	check(not planned.act("wall", Vector2i(10, 10)), "Cannot bury field blueprint under construction")
	# Natural dawn after early clear is a distinct choice, without an early-finish bonus.
	var full_night = Farm.new({}, 17)
	full_night.buy("hen")
	full_night = full_night.begin_night()
	Trial.deploy(full_night)
	while full_night.phase == "defend": full_night.step()
	check(full_night.early_clear and full_night.tick == 720 and full_night.early_finish_bonus == 0, "Work until natural dawn after early clear")
	check(full_night.dawn_summary.eggs == 1, "Dawn production runs once after full night")
	var duplicate = Farm.new({}, 17)
	duplicate.buy("hen")
	duplicate = duplicate.begin_night()
	Trial.deploy(duplicate)
	while duplicate.phase == "defend": duplicate.step()
	check(JSON.stringify(duplicate.observation()) == JSON.stringify(full_night.observation()), "Day biology and AI reproduce from identical seed/actions")
func sight_and_skills():
	var w = started()
	w.spawn_enemy(w.spawn_schedule[0])
	var e = w.enemies[0]
	e.pos = Vector2i(5, 8)
	Farm.RaiderAI.perceive(e, w)
	check(not e.can_see_keeper and e.last_known_keeper_position == null, "No knowledge outside sight range")
	var goal = Farm.RaiderAI.target(e, w)
	w.keeper.pos = Vector2i(23, 14)
	check(Farm.RaiderAI.target(e, w) == goal, "Unseen keeper changes do not change exploration goal")
	w.keeper.pos = Vector2i(9, 8)
	w.act("wall", Vector2i(7, 8))
	w.structures[Vector2i(7, 8)].status = "ready"
	Farm.RaiderAI.perceive(e, w)
	check(not e.can_see_keeper, "Wall occludes a keeper within range")
	w.structures[Vector2i(7, 8)].kind = "gate"
	w.structures[Vector2i(7, 8)].open = false
	Farm.RaiderAI.perceive(e, w)
	check(not e.can_see_keeper, "Closed gate occludes")
	w.structures[Vector2i(7, 8)].open = true
	Farm.RaiderAI.perceive(e, w)
	check(e.can_see_keeper and e.last_known_keeper_position == Vector2i(9, 8) and e.sight_reaction == "!", "Open gate reveals keeper with brief reaction")
	w.keeper.pos = Vector2i(23, 14)
	Farm.RaiderAI.perceive(e, w)
	check(not e.can_see_keeper and e.sight_reaction == "?" and Farm.RaiderAI.target(e, w) == Vector2i(9, 8), "Lost target follows last seen position, not true position")
	e.pos = Vector2i(9, 8)
	var next = Farm.RaiderAI.target(e, w)
	check(e.last_known_keeper_position == null and next != w.keeper.pos, "Empty last known position returns to searching")
	w.structures[Vector2i(7, 8)].open = false
	check(not w.line_of_sight(Vector2i(6, 8), Vector2i(7, 9)), "No sight through blocked diagonal corner")
	var a = w.animals[0]
	a.pos = Vector2i(18, 8)
	a.detection_range = 1
	a.attack_target_range = 4
	e.pos = Vector2i(13, 8)
	w.share_detection(a, e.id)
	check(w.animal_targets(a).is_empty(), "Shared detection cannot exceed attack target range")
	e.pos = Vector2i(15, 8)
	check(w.animal_targets(a).size() == 1, "Shared sight supplies knowledge within target range")
	check(a.object_attack_power == 0 and a.skills == ["bark", "rescue"], "Generic object attack and skills present")
	var morning = Farm.new({}, 91)
	var stock = morning.shop_stock.duplicate(true)
	check(not stock.any(func(row): return row.product == "shiba" or Farm.Shop.FOOD.has(row.product)), "No companion dog or food stocked")
	check(morning.buy("cat"), "Cat remains a funded alternative")
	var night_world = morning.begin_night()
	var reset = Farm.new(night_world.morning_checkpoint, night_world.seed_value)
	check(reset.phase == "shop" and reset.campaign.gold == 40 and reset.campaign.animals.size() == 1 and reset.shop_stock == stock, "Morning retry undoes purchases and reproduces stock")
	var cat = night_world.animals[1]
	cat.lv = 1
	cat.pos = Vector2i(4, 8)
	night_world.spawn_enemy(night_world.spawn_schedule[0])
	night_world.enemies[0].pos = Vector2i(5, 8)
	night_world.try_meow(cat)
	check(night_world.skill_log.is_empty(), "Lv1 cat has passive charm only")
	cat.lv = 2
	night_world.try_meow(cat)
	check(night_world.enemies[0].weakened_until == 16 and cat.skill_ready.meow == 48, "Lv2 meow weakens for four seconds with twelve-second cooldown")
	night_world.try_meow(cat)
	check(night_world.skill_log.size() == 1 and cat.attack_power == 0, "Meow respects cooldown and is not an attack")
	var raider = night_world.enemies[0]
	var dog = night_world.animals[0]
	dog.placed = true
	dog.pos = Vector2i(5, 9)
	raider.attacker = dog.id
	raider.threat_until = 100
	raider.ai_context = "under_attack"
	raider.next_decision = 100
	raider.intent = "counter"
	night_world.tick = 1
	night_world.enemy_step(raider)
	check(dog.hp == 36, "Meow reduces a real counterattack from five to four after integer rounding")
	night_world.tick = 17
	raider.counter_until = 100
	night_world.enemy_step(raider)
	check(dog.hp == 31 and raider.attack_power == 5, "Weakening expires without mutating base AttackPower")