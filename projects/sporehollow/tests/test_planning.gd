extends SceneTree
const Farm = preload("res://game/world.gd")
var checks = 0
var failures = 0
func check(ok, why):
	checks += 1
	if not ok:
		failures += 1
		push_error(why)
func fresh():
	var w = Farm.new({},17).begin_day()
	w.day_seconds = 9999
	w.natural.clear()
	return w
func steps(w,n):
	for i in range(n): w.step()
func until(w, predicate, limit=300):
	for i in range(limit):
		if predicate.call(): return
		w.step()
	check(false,"Bounded action did not finish")
func _initialize(): call_deferred("run")
func run():
	var w = fresh()
	w.act("pause")
	var pos = w.keeper.pos
	var fatigue = w.keeper.sleepiness
	for p in [Vector2i(10,8),Vector2i(11,8),Vector2i(12,8)]: check(w.act("wall",p),"Paused building reservation")
	w.natural[Vector2i(9,8)] = "stump"
	check(w.act("collect",Vector2i(9,8)),"Paused direct collection plan")
	check(not w.act("collect",Vector2i(9,8)),"Duplicate collection denied")
	check(w.act("place_animal",Vector2i(15,8),1),"Paused animal reservation")
	check(not w.act("place_animal",Vector2i(16,8),1),"Same individual cannot be reserved twice")
	var ids = w.jobs.map(func(j):return j.id)
	check(w.Jobs.reorder(w,ids[4],0),"Pending head can reorder during pause")
	check(w.jobs[0].id == ids[4] and w.materials == 70,"Order changes do not charge")
	check(w.act("cancel_job",Vector2i.ZERO,ids[1]) and w.materials == 80,"Paused unstarted refund exact")
	steps(w,50)
	check(w.tick == 0 and w.keeper.pos == pos and w.keeper.sleepiness == fatigue and w.structures.is_empty() and w.wood == 0 and not w.animals[0].placed,"Planning never advances world")
	w.act("pause")
	until(w,func():return w.animals[0].deployment == "transporting")
	check(Farm.distance(w.keeper.pos,Farm.HOLDING_SHED)<=1,"Pickup really occurs at holding shed")
	check(not w.animals[0].placed,"Transported animal has no active AI body")
	check(not w.Jobs.reorder(w,ids[4],2),"Active job locked")
	w.act("keeper_move",Vector2i(9,13))
	until(w,func():return w.manual_goal == null)
	check(w.animals[0].deployment == "transporting" and w.jobs_held,"Manual retreat retains companion")
	w.act("pause")
	check(w.act("cancel_job",Vector2i.ZERO,ids[4]),"Transport cancel becomes return")
	var return_pos = w.keeper.pos
	steps(w,20)
	check(w.keeper.pos == return_pos and w.animals[0].deployment == "transporting","Paused return has no movement/disappearance")
	w.act("resume_jobs")
	w.act("pause")
	until(w,func():return w.animals[0].deployment == "unplaced")
	check(Farm.distance(w.keeper.pos,Farm.HOLDING_SHED)<=1 and not w.animals[0].placed,"Return completes at shed")
	until(w,func():return w.jobs.is_empty())
	check(w.wood==20 and w.metrics.built==2,"Remaining FIFO executes after return")
	check(w.act("place_animal",Vector2i(15,8),1),"Returned individual deployable")
	until(w,func():return w.animals[0].placed)
	check(w.animals[0].deployment=="placed" and not w.act("place_animal",Vector2i(16,8),1),"Deployed never recalled")
	w=fresh()
	w.act("place_animal",Vector2i(15,8),1)
	check(w.act("cancel_job",Vector2i.ZERO,w.jobs[0].id) and w.animals[0].deployment=="unplaced","Prepickup cancellation releases individual")
	w.act("wall",Vector2i(7,13))
	until(w,func():return w.jobs[0].started)
	w.act("pause")
	var building=w.structures.duplicate(true)
	w.act("cancel_job",Vector2i.ZERO,w.jobs[0].id)
	check(w.structures==building,"Started-site cancel deferred while paused")
	w.act("pause")
	w.step()
	check(w.jobs.is_empty(),"Deferred interruption executes after resume")
	w=fresh()
	w.keeper.sleepiness=90
	w.act("keeper_rest")
	steps(w,20)
	check(w.keeper.sleepiness==90 and w.keeper.rest_elapsed==5,"Five full game seconds before fatigue recovery")
	w.act("pause")
	steps(w,40)
	check(w.keeper.rest_elapsed==5,"Pause freezes settling")
	w.act("pause")
	w.step()
	check(w.keeper.sleepiness==89.5,"Recovery after settling")
	w.act("keeper_move",Vector2i(10,13))
	check(not w.keeper.resting and w.keeper.rest_elapsed==0,"Movement resets sleep state and settling")
	w.act("keeper_rest")
	steps(w,10)
	var elapsed=w.keeper.rest_elapsed
	w.start_night()
	w.config.first_attack_seconds=9999
	w.make_schedule()
	w.step()
	check(w.keeper.rest_elapsed==elapsed+w.DT,"Dusk preserves continuous rest")
	w.act("resume_jobs")
	check(not w.keeper.resting and w.keeper.rest_elapsed==0,"Work resume wakes")
	w.keeper.sleepiness=100
	w.step()
	check(w.keeper.forced_rest,"Forced rest enters same state")
	steps(w,20)
	check(w.keeper.sleepiness==100,"Forced rest also settles")
	steps(w,41)
	check(not w.keeper.resting and not w.keeper.forced_rest and w.keeper.sleepiness<80,"Forced recovery clears sleep")
	w=fresh()
	w.act("place_animal",Vector2i(15,8),1)
	until(w,func():return w.animals[0].deployment=="transporting")
	w.structures[Vector2i(15,8)]={"kind":"wall","hp":8,"max_hp":8,"status":"ready","open":false}
	w.step()
	check(w.jobs[0].state=="blocked" and not w.animals[0].placed,"Blocked destination never silently relocates animal")
	w.act("keeper_rest")
	steps(w,21)
	check(w.Life.presentation(w)=="sleeping" and w.animals[0].deployment=="transporting","Rest preserves transport with current-state sleep")
	w.Life.hurt(w,{"id":9,"attack_power":30})
	check(w.Life.presentation(w)=="unconscious" and not w.keeper.resting,"Damage/down removes sleep presentation")
	w.keeper.carrier=9
	w.keeper.state="captured"
	check(w.Life.presentation(w)=="carried" and w.animals[0].placed and w.jobs.is_empty(),"Attacked transport becomes one deployed companion before keeper is carried")
	w.keeper.carrier=-1
	w.keeper.state="unconscious"
	steps(w,48)
	check(w.Life.presentation(w)=="settling" and w.jobs_held,"Rescued keeper starts new settling period")
	w.act("keeper_rest")
	check(w.Life.presentation(w)=="awake","Wake after rescue removes sleep")
	w.act("resume_jobs")
	check(w.animals[0].deployment=="placed","Lowered companion cannot be recalled after rescue")
	for value in [60,80,90]:
		w.keeper.sleepiness=value
		check(w.Life.presentation(w) not in ["settling","sleeping"],"Awake fatigue never means sleep")
	var restarted=Farm.new(w.checkpoint,w.seed_value)
	check(not restarted.keeper.resting and restarted.manual_goal==null,"Retry has no stale sleep or movement")
	# Reproduce the old empty-queue walk -> permanent held state; new orders must start.
	w=fresh()
	w.act("keeper_move",Vector2i(10,13))
	until(w,func():return w.manual_goal==null)
	check(not w.jobs_held,"Empty-queue walk clears its travel hold on arrival")
	w.act("wall",Vector2i(12,13))
	until(w,func():return w.jobs.is_empty())
	check(w.metrics.built==1,"New work after ordinary walking actually builds")
	w.act("wall",Vector2i(16,10))
	w.act("keeper_rest")
	steps(w,22)
	w.act("keeper_rest")
	check(not w.jobs_held,"Explicit wake resumes previously active work")
	until(w,func():return w.jobs.is_empty())
	check(w.metrics.built==2,"Wake returns to building")
	w.act("wall",Vector2i(18,10))
	w.act("keeper_move",Vector2i(10,13))
	until(w,func():return w.manual_goal==null)
	check(w.jobs_held and w.job_hold_reason=="manual","Interrupted work stays held after evacuation")
	w.act("keeper_rest"); w.act("keeper_rest")
	check(w.jobs_held,"Rest/wake never overrides evacuation hold")
	w.act("resume_jobs")
	until(w,func():return w.jobs.is_empty())
	check(w.metrics.built==3,"Explicit resume restores FIFO")
	# Paused ordinary move + plan uses world time only after resume.
	w=fresh(); w.act("pause")
	w.act("keeper_move",Vector2i(10,13)); w.act("wall",Vector2i(13,13))
	steps(w,10)
	check(w.tick==0 and w.structures.is_empty(),"Planning holds world frozen")
	w.act("pause")
	until(w,func():return w.jobs.is_empty())
	check(w.metrics.built==1,"Paused move then work completes after resume")
	# Returned animal and following building use the same bounded FIFO.
	w=fresh(); w.act("place_animal",Vector2i(10,8),1)
	until(w,func():return w.animals[0].deployment=="transporting")
	w.act("cancel_job",Vector2i.ZERO,w.jobs[0].id)
	w.act("wall",Vector2i(19,12))
	until(w,func():return w.jobs.is_empty())
	check(not w.animals[0].placed and w.metrics.built==1,"Return to southeast shed does not strand subsequent work")
	for returning in [false,true]:
		w=fresh(); w.act("place_animal",Vector2i(10,8),1)
		until(w,func():return w.animals[0].deployment=="transporting")
		if returning:w.act("cancel_job",Vector2i.ZERO,w.jobs[0].id)
		var original=w.keeper.pos
		w.Life.hurt(w,{"id":4,"attack_power":5})
		check(w.animals.size()==1 and w.animals[0].placed and w.jobs.is_empty(),"Hit lowers exactly one animal from carrying/returning")
		check(w.distance(original,w.animals[0].pos)==1 and w.animals[0].pos!=w.keeper.pos,"Emergency lowering adjacent and unoccupied")
		check(w.jobs_held and w.job_hold_reason=="danger","Work waits after attacked transport")
		check(not w.act("place_animal",Vector2i(12,8),1),"Emergency deployment cannot be recalled")
	# No adjacent space: retain individual, retry lowering without an extra queue.
	w=fresh(); w.act("place_animal",Vector2i(10,8),1)
	until(w,func():return w.animals[0].deployment=="transporting")
	for p in w.neighbors(w.keeper.pos):w.structures[p]={"kind":"wall","hp":8,"status":"ready","open":false}
	w.Life.hurt(w,{"id":4,"attack_power":30})
	check(not w.animals[0].placed and w.jobs.size()==1 and w.jobs[0].transport=="drop_pending","No free space retains one companion")
	var free=w.neighbors(w.keeper.pos)[0]
	w.structures.erase(free); w.step()
	check(w.animals[0].placed and w.animals[0].pos==free and w.jobs.is_empty(),"Lowering retry succeeds while keeper unconscious")
	w=fresh(); w.act("wall",Vector2i(12,8));w.act("place_animal",Vector2i(15,8),1)
	var before=w.observation()
	var paths=w.Jobs.preview(w)
	check(paths.size()==3,"Preview includes build, pickup and deployment legs")
	check(w.observation()==before,"Route preview never mutates the simulation")
	var traversable=true
	for leg in paths:
		for p in leg.path:traversable=traversable and w.walkable(p)
	check(traversable and w.blocks(w.HOLDING_SHED+Vector2i.RIGHT),"Routes respect walls and the shed body")
	print("PLANNING: ",checks," checks, failures=",failures)
	quit(1 if failures else 0)
