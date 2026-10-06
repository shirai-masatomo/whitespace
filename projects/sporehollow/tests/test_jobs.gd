extends SceneTree
const Farm = preload("res://tests/open_ranch_fixture.gd")
var checks = 0

func check(ok: bool, why: String):
	checks += 1
	if not ok:
		push_error(why)
		quit(1)
		assert(ok, why)

func steps(w, n: int):
	for i in range(n): w.step()

func drain(w, limit: int = 600):
	for i in range(limit):
		if w.jobs.is_empty(): return
		w.step()
	check(false, "Worker failed to finish/cancel within bounded time")

func _initialize(): call_deferred("run")
func run():
	var morning = Farm.new({}, 17)
	check(morning.buy("soil"), "Morning material purchase")
	var w = morning.begin_day()
	check(w.phase == "day" and w.keeper.placed and w.tick == 0, "Shopping enters day without placement")
	check(not w.act("place", Vector2i(20, 8)), "Old keeper teleport removed")
	var origin: Vector2i = w.keeper.pos
	var soil: int = w.materials
	for p in [Vector2i(3, 6), Vector2i(8, 6), Vector2i(18, 6)]: check(w.act("wall", p), "Three plans accepted")
	check(w.jobs.size() == 3 and w.structures.is_empty() and w.materials == soil - 30, "Plans reserve soil, not structures")
	w.step()
	check(w.keeper.pos == origin and w.structures.is_empty(), "Travel cannot teleport or instantly build")
	for i in range(250):
		if w.metrics.built == 2: break
		w.step()
	check(w.metrics.built == 2, "First two jobs complete in order")
	var third: int = w.jobs.back().id
	check(w.act("cancel_job", Vector2i.ZERO, third), "Cancel travelling third job only")
	check(w.act("wall", Vector2i(16, 6)), "Append replacement during work")
	drain(w)
	check(not w.structures.has(Vector2i(18, 6)) and w.structures[Vector2i(16, 6)].status == "ready", "Cancelled job absent; replacement built")
	for event in w.job_log:
		if event.event == "started": check(w.structures.has(Vector2i(event.pos[0], event.pos[1])), "Only arrived sites start")
	for i in range(1, w.keeper_path.size()):
		check(abs(w.keeper_path[i][0] - w.keeper_path[i-1][0]) + abs(w.keeper_path[i][1] - w.keeper_path[i-1][1]) == 1, "Every movement is one grid edge")
	var cap = Farm.new().begin_day()
	for i in range(8): check(cap.act("wall", Vector2i(2 + i, 6)), "Accept through eighth job")
	check(not cap.act("wall", Vector2i(15, 6)) and cap.materials == 20, "Ninth job rejected without cost")
	var preserved = cap.jobs.map(func(j): return j.id)
	cap.act("cancel_job", Vector2i.ZERO, preserved[2])
	preserved.remove_at(2)
	check(cap.jobs.map(func(j): return j.id) == preserved and cap.materials == 30, "Middle removal preserves FIFO and refunds")
	cap.act("pause")
	var frozen = JSON.stringify(cap.observation())
	steps(cap, 10)
	check(JSON.stringify(cap.observation()) == frozen and cap.act("wall", Vector2i(15, 6)), "Pause freezes work and accepts reserved plans")
	cap.act("pause")
	# Finished wall blocks the direct path; movement must go around it.
	var path = Farm.new().begin_day()
	check(path.act("wall", Vector2i(7, 13)), "Obstacle queued")
	drain(path)
	path.act("move", Vector2i(9, 13))
	var start = path.keeper_path.size()
	drain(path)
	check(path.keeper.pos == Vector2i(9, 13), "Keeper reaches far side")
	check(not path.keeper_path.slice(start).has([7, 13]), "Keeper never crosses solid wall")
	# Unreachable target fails/refunds without freezing later jobs.
	for p in path.neighbors(Vector2i(12, 10)):
		path.structures[p] = {"kind": "wall", "status": "ready", "open": false, "hp": 8}
	path.act("move", Vector2i(12, 10))
	path.act("move", Vector2i(10, 13))
	drain(path)
	check(path.keeper.pos == Vector2i(10, 13) and path.job_log.any(func(e): return e.event == "unreachable"), "Blocked job skipped; next runs")
	var transition = Farm.new({}, 17).begin_day()
	transition.tick = 358
	transition.act("wall", Vector2i(22, 2))
	var job_id = transition.jobs[0].id
	steps(transition, 2)
	check(transition.phase == "defend" and transition.jobs[0].id == job_id and transition.night_started_tick == 360, "Night keeps location and pending queue")
	check(transition.enemies.is_empty(), "No daytime/instant dusk invasion")
	steps(transition, 39)
	check(transition.enemies.is_empty(), "Night-relative ten-second schedule")
	transition.step()
	check(transition.enemies.size() == 1 and transition.enemies[0].born == 400, "Intruder arrives ten seconds into night")
	check(transition.act("keeper_move", Vector2i(20, 13)) and transition.jobs_held and transition.jobs.size() == 1, "Direct travel holds queued construction")
	var before = transition.keeper.pos
	steps(transition, 4)
	check(transition.keeper.pos != before, "Player keeps moving during invasion")
	# Local collection and deployment use exactly the same queue.
	var local = Farm.new().begin_day()
	local.nature_config.spawn_chance_per_second=0
	local.animals[0].loyalty=100
	local.natural[Vector2i(20, 13)] = "stump"
	local.act("collect", Vector2i(20, 13))
	check(local.wood == 0 and local.natural.size() == 1, "Distant harvest isn't immediate")
	drain(local)
	check(local.wood == 20, "Harvest at arrival")
	local.act("guide", Vector2i(19, 12), 1)
	check(local.animals[0].placed and not local.act("guide", Vector2i(18, 12), 1), "Single pending deployment per animal")
	drain(local)
	check(local.animals[0].placed, "Animal deployed locally, AI retained")
	local.act("wall", Vector2i(22, 12))
	local.keeper.state = "captured"
	before = local.keeper.pos
	steps(local, 8)
	check(local.keeper.pos == before and not local.jobs.is_empty(), "Captured keeper cannot work or walk")
	local.keeper.state = "free"
	drain(local)
	check(local.structures[Vector2i(22, 12)].status == "ready", "Rescued keeper resumes work")
	var maintenance = Farm.new().begin_day()
	maintenance.wood=100
	maintenance.act("door", Vector2i(7, 13))
	drain(maintenance)
	maintenance.act("move", Vector2i(20, 13))
	drain(maintenance)
	maintenance.structures[Vector2i(7,13)].open=false
	maintenance.act("gate", Vector2i(7, 13))
	check(not maintenance.structures[Vector2i(7, 13)].open, "Remote gate request is only intent")
	drain(maintenance)
	check(maintenance.structures[Vector2i(7, 13)].open, "Gate opens at arrival")
	maintenance.structures[Vector2i(7, 13)].hp = 2
	maintenance.act("repair", Vector2i(7, 13))
	check(maintenance.structures[Vector2i(7, 13)].hp == 2, "Repair waits for work tick")
	drain(maintenance)
	check(maintenance.structures[Vector2i(7, 13)].hp == 16, "Local repair preserves durability/cost rule")
	maintenance.act("remove", Vector2i(7, 13))
	drain(maintenance)
	check(maintenance.structures[Vector2i(7, 13)].status == "removed", "Dismantle also performed locally")
	# Started work cannot advance while its worker is away, including after dawn.
	var unfinished = Farm.new().begin_day()
	unfinished.act("wall", Vector2i(7, 13))
	unfinished.step()
	check(unfinished.jobs[0].started and unfinished.structures[Vector2i(7, 13)].remaining == 3, "Arrival starts one-second local work")
	unfinished.keeper.state = "restrained"
	steps(unfinished, 5)
	check(unfinished.structures[Vector2i(7, 13)].remaining == 3, "Restraint freezes hammering")
	unfinished.keeper.pos = Vector2i(12, 13) # A carrier moved the worker before rescue.
	unfinished.keeper.state = "free"
	unfinished.step()
	check(unfinished.jobs[0].state == "walking" and unfinished.structures[Vector2i(7, 13)].remaining == 3, "Rescued away from unfinished site walks back before hammering")
	unfinished.act("wall", Vector2i(22, 3))
	unfinished.finish(true)
	check(unfinished.materials == 80, "Dawn carries reserved jobs and unfinished construction")
	var tomorrow = Farm.new(unfinished.next_campaign()).begin_day()
	check(tomorrow.jobs.size() == 2 and tomorrow.structures[Vector2i(7, 13)].remaining == 3, "Unfinished site gets a local resume job next day")
	drain(tomorrow)
	check(tomorrow.structures[Vector2i(7, 13)].hp == 8 and tomorrow.materials == 80, "Resume charges no second cost")
	var interrupted = Farm.new().begin_day()
	interrupted.act("wall", Vector2i(7, 13))
	interrupted.step()
	interrupted.act("cancel_job", Vector2i.ZERO, interrupted.jobs[0].id)
	check(interrupted.materials == 95 and not interrupted.structures.has(Vector2i(7,13)), "Cancelling paid work uses existing half-refund rule")
	# The same timed player requests reproduce movement, natural growth, work and enemy AI.
	var replay_a = Farm.new({}, 29).begin_day()
	var replay_b = Farm.new({}, 29).begin_day()
	for sim in [replay_a, replay_b]:
		sim.act("wall", Vector2i(10, 10))
		sim.animals[0].loyalty=100
		sim.act("guide", Vector2i(18, 8), 1)
		sim.act("move", Vector2i(19, 8))
		steps(sim, 400)
		sim.act("stay", Vector2i(18, 8), 1)
		steps(sim, 40)
	check(JSON.stringify(replay_a.observation()) == JSON.stringify(replay_b.observation()), "Same seed, timed commands and layout reproduce full new-loop observation")
	# End-to-end real production worlds, not the isolated combat fixture.
	for seed_id in range(1, 9):
		var sim = Farm.new({}, seed_id).begin_day()
		sim.animals[0].loyalty=100
		sim.act("guide", Vector2i(18, 8), 1)
		sim.act("move", Vector2i(19, 8))
		drain(sim)
		sim.act("stay", Vector2i(18, 8), 1)
		while sim.working() and sim.tick < 1100:
			sim.step()
			if sim.early_clear: sim.act("end_night")
		check(sim.phase == "dawn" and sim.result == "win" and sim.spawned == 1, "Real day travel + deployment + night defense reaches dawn")
		check(Farm.new(sim.next_campaign()).phase == "shop", "Dawn returns to next morning market")
	var survival = Farm.new().begin_day()
	survival.config.waves[0].start_seconds = 9999
	survival.make_schedule()
	steps(survival, 1080)
	check(survival.phase == "dawn" and survival.tick == 1080, "Natural dawn after90 daytime +180 night seconds")
	print("PASS: ", checks, " day/night and local work checks")
	quit()
