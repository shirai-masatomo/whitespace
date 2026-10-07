extends SceneTree
const Farm = preload("res://game/world.gd")
var checks = 0
var failures = 0
var reports: Array = []
func _initialize(): call_deferred("run")
func check(ok: bool, message: String):
	checks += 1
	if not ok:
		failures += 1
		push_error(message)
func safe(seed_id: int = 17):
	var config = Farm.StageData.STAGES[1].duplicate(true)
	config.day_seconds = 600.0
	config.first_attack_seconds = 9999.0
	var w=Farm.new({}, seed_id, config).begin_day()
	w.nature_config.spawn_chance_per_second=0
	return w
func steps(w, count: int):
	for i in range(count): w.step()
func clear_jobs(w):
	for i in range(600):
		if w.jobs.is_empty(): return
		w.step()
func no_overlap(w) -> bool:
	var cells = {}
	if w.keeper.placed and w.keeper.carrier < 0:
		cells[w.keeper.pos] = true
		if w.blocks(w.keeper.pos): return false
	for a in w.animals:
		if not a.placed: continue
		if cells.has(a.pos) or w.blocks(a.pos): return false
		cells[a.pos] = true
	for e in w.enemies:
		if e.done: continue
		if cells.has(e.pos) or w.blocks(e.pos): return false
		cells[e.pos] = true
	return true
func run():
	var w = safe()
	check(w.keeper.hp == 30 and w.keeper.sleepiness == 0, "Healthy starting keeper")
	for sample in [[0,"awake"],[50,"awake"],[50.01,"drowsy"],[80,"drowsy"],[80.01,"tired"],[90,"exhausted"],[50,"awake"]]:
		w.keeper.sleepiness = sample[0]
		check(Farm.Life.presentation(w)==sample[1],"Current fatigue visual boundary " + str(sample))
	w.keeper.sleepiness=80
	check(Farm.Life.factor(w)==0.6,"Mechanical debuff still starts at 80, independent of visual boundary")
	w.keeper.sleepiness=51
	check(Farm.Life.factor(w)==1.0,"Mild appearance does not add a debuff")
	w.keeper.sleepiness=85
	w.campaign.items.coffee=1
	check(w.act("coffee") and Farm.Life.presentation(w)=="drowsy","Drink immediately clears severe visual state")
	w.keeper.resting=true
	w.keeper.rest_elapsed=0
	check(Farm.Life.presentation(w)=="settling","Rest onset is not awake fatigue or sleep")
	w.keeper.rest_elapsed=5
	w.keeper.asleep=true
	check(Farm.Life.presentation(w)=="sleeping","Five elapsed seconds show sleep")
	w.keeper.state="unconscious"
	check(Farm.Life.presentation(w)=="unconscious","Unconscious overrides historical rest")
	w.keeper.carrier=0
	check(Farm.Life.presentation(w)=="carried","Transport overrides historical rest")
	w = safe()
	check(Farm.Life.presentation(w)=="awake","Retry begins with no retained sleep appearance")

	for cell in [Vector2i(7,13), Vector2i(10,10), Vector2i(14,10)]: w.act("wall", cell)
	w.step()
	var ids = w.jobs.map(func(j):return j.id)
	check(w.act("keeper_move",Vector2i(10,14)),"FIFO movement accepted")
	check(w.jobs.size()==4 and w.jobs.slice(0,3).map(func(j):return j.id)==ids and not w.jobs_held,"Move appends without interrupting existing work")
	clear_jobs(w)
	check(w.jobs.is_empty() and w.metrics.built==3 and w.keeper.pos==Vector2i(10,14),"Builds finish before queued movement")
	check(no_overlap(w), "No wall/keeper overlap on completion")
	# An occupied corridor must not be silently crossed.
	w = safe()
	w.act("guide", Vector2i(8,13), 1)
	clear_jobs(w)
	w.act("stay", Vector2i(8,13), 1)
	steps(w, 8)
	w.act("keeper_move", Vector2i(10,13))
	var unique = true
	for i in range(40):
		w.step()
		unique = unique and no_overlap(w)
	check(unique and w.keeper.pos == Vector2i(10,13), "Manual path skirts deployed animal")
	# Every awake second counts, pause does not; exact thresholds and recovery.
	w = safe()
	w.Jobs.hold(w,"explicit") # An outstanding wait prevents the new idle rest; test continuous waking fatigue.
	steps(w, 864)
	check(w.keeper.sleepiness >= 79.9 and w.Life.factor(w) < 1, "216 seconds reaches 80 percent fatigue")
	steps(w, 216)
	check(w.keeper.forced_rest and w.keeper.resting, "270 seconds reaches forced rest")
	check(w.act("keeper_move", Vector2i(10,13)) and not w.act("keeper_rest"), "Forced rest allows planning but blocks waking")
	steps(w, 61)
	check(w.keeper.sleepiness < 80 and not w.keeper.forced_rest and not w.keeper.resting, "Below80 returns normal activity")
	w.keeper.sleepiness = 70
	w.keeper.hp = 20
	w.act("keeper_rest")
	var before = w.tick
	steps(w, 20)
	check(w.tick == before + 20 and w.keeper.hp == 21 and w.keeper.sleepiness == 70, "First five seconds settle; existing HP healing unchanged")
	w.act("pause")
	steps(w, 20)
	check(w.tick == before + 20 and w.keeper.sleepiness == 70, "Pause freezes body as well as world")
	w.act("pause")
	check(w.act("keeper_rest") and not w.keeper.resting, "Voluntary wake anytime")
	w.keeper.sleepiness = 90
	w.act("keeper_rest")
	w.act("resume_jobs")
	check(w.act("keeper_move", Vector2i(9,13)) and not w.keeper.resting and w.Life.factor(w) == 0.6, "Escape wakes voluntary sleep with fatigue retained")
	# Speed/work reduction is real, not an icon only.
	var rested = safe()
	var tired = safe()
	tired.keeper.sleepiness = 85
	for sim in [rested,tired]: sim.act("wall",Vector2i(7,13))
	steps(rested,4)
	steps(tired,4)
	check(rested.structures[Vector2i(7,13)].status == "ready" and tired.structures[Vector2i(7,13)].status == "building", "Fatigue slows construction")
	for sim in [rested,tired]:
		sim.natural[Vector2i(6,12)] = "stump"
		sim.jobs.clear()
		sim.act("collect", Vector2i(6,12))
		sim.step()
	check(rested.wood == 20 and tired.wood == 0, "Fatigue slows collection")
	w = safe()
	w.campaign.items.coffee = 3
	w.campaign.items.energy_drink = 1
	w.keeper.sleepiness = 95
	check(w.act("coffee") and w.keeper.sleepiness == 83, "Coffee reduces12")
	check(w.act("energy_drink") and w.keeper.sleepiness == 58, "Drink reduces25")
	check(not w.act("coffee") and w.campaign.items.coffee == 2, "Daily drink cap prevents infinite stimulant use")
	w.persist_farm()
	var tomorrow = Farm.new(w.next_campaign()).begin_day()
	check(tomorrow.keeper.sleepiness == 58 and tomorrow.keeper.drinks_today == 0, "Fatigue persists, daily drinks reset at dawn")
	# Attack -> resistance -> unconscious -> carry -> rescue / exit. No forced result.
	for rescued in [false,true]:
		w = safe()
		w.keeper.pos = Vector2i(19,8)
		w.animals[0].pos=Vector2i(19,10)
		w.animals[0].mode="rest"
		w.start_night()
		w.spawn_enemy({"entry":Vector2i(1,5),"role":"kidnapper","lv":1})
		w.enemies[0].pos = Vector2i(18,8)
		var down = false
		var carried = false
		unique = true
		for i in range(650):
			w.step()
			down = down or w.keeper.state == "unconscious"
			if w.keeper.carrier >= 0 and not carried:
				carried = true
				if rescued: w.animals[0].mode="auto" # Fixture releases explicit rest to isolate rescue, not a remote player order.
			unique = unique and no_overlap(w)
			if (rescued and w.metrics.rescues > 0) or w.result != "": break
		check(down and carried, "Keeper must lose HP before being carried")
		check(w.combat_log.any(func(hit):return hit.source == "keeper" and hit.damage == 2), "Weak resistance actually attacks")
		check(unique, "Combat and carry never overlap except carried keeper")
		if rescued:
			check(w.metrics.rescues == 1 and w.keeper.hp == 0 and w.keeper.carrier < 0, "Dog rescues unconscious keeper, no instant healing")
			steps(w,48)
			check(w.keeper.hp == 8 and w.keeper.resting and w.jobs_held, "Safe gradual recovery, no automatic dangerous work")
		else: check(w.result == "loss" and w.keeper.state == "abducted", "Only exit causes loss")
		reports.append(w.observation())
	# Rest doesn't freeze perception or spawn and danger serial changes for UI slow-down.
	w = safe()
	w.keeper.sleepiness = 70
	w.act("keeper_rest")
	w.start_night()
	w.spawn_enemy({"entry": Vector2i(1,5),"role":"kidnapper"})
	var serial = w.danger_serial
	w.enemies[0].pos = w.keeper.pos + Vector2i.LEFT
	steps(w,8)
	check(w.danger_serial > serial and w.keeper.hp < 30 and w.keeper.resting, "Attack reaches sleeping keeper; player must wake voluntarily")
	check(w.act("keeper_move",Vector2i(12,13)), "Wake and escape during danger")
	var day7 = safe()
	day7.campaign.day = 7
	day7.spawn_enemy({"entry":day7.entries[0],"role":"runner"})
	check(day7.enemies[0].move_speed > Farm.Jobs.SPEED, "Later invader can outrun rested keeper")
	for seed_id in range(1,9):
		var morning = Farm.new({},seed_id)
		morning.campaign.gold = 100
		morning.buy("hen")
		morning.buy("cat")
		var sim = morning.begin_day()
		sim.act("guide",Vector2i(17,8),1)
		sim.act("guide",Vector2i(19,10),2)
		sim.act("guide",Vector2i(20,12),3)
		sim.act("wall",Vector2i(15,7))
		sim.act("door",Vector2i(15,8))
		sim.act("move",Vector2i(19,8))
		clear_jobs(sim)
		var all_clear = no_overlap(sim)
		while sim.working() and sim.tick < 1100:
			sim.step()
			all_clear = all_clear and no_overlap(sim)
			if sim.early_clear: sim.act("end_night")
		check(all_clear, "Three species, keeper, gate, wall and invading enemy stay on distinct walkable cells")
		check(sim.result != "", "Integrated day ends with dawn or abduction")
	var file = FileAccess.open("res://artifacts/keeper-tests.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"checks":checks,"failures":failures,"encounters":reports},"\t"))
	print("KEEPER: ", checks, " checks, failures=", failures)
	quit(1 if failures else 0)

