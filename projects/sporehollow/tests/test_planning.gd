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
	w.nature_config.spawn_chance_per_second=0
	w.animals[0].loyalty=100
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
	check(w.act("guide",Vector2i(15,8),1),"Paused animal reservation")
	check(not w.act("guide",Vector2i(16,8),1),"Same individual cannot be reserved twice")
	var ids = w.jobs.map(func(j):return j.id)
	check(w.Jobs.reorder(w,ids[4],0),"Pending head can reorder during pause")
	check(w.jobs[0].id == ids[4] and w.materials == 70,"Order changes do not charge")
	check(w.act("cancel_job",Vector2i.ZERO,ids[1]) and w.materials == 80,"Paused unstarted refund exact")
	steps(w,50)
	check(w.tick == 0 and w.keeper.pos == pos and w.keeper.sleepiness == fatigue and w.structures.is_empty() and w.wood == 0 and w.animals[0].placed,"Planning never advances world")
	w.act("pause")
	until(w,func():return w.animals[0].has("guide_job"))
	check(w.animals[0].placed,"Guided animal remains a living individual")
	check(not w.Jobs.reorder(w,ids[4],2),"Active job is fixed")
	w.act("pause")
	check(w.act("cancel_job",Vector2i.ZERO,ids[4]),"Paused guide cancellation is requested")
	var before=w.animals[0].pos
	steps(w,20)
	check(w.animals[0].pos==before,"Pause never physically moves a guided animal")
	w.act("pause")
	w.step()
	check(not w.animals[0].has("guide_job") and w.animals[0].placed,"Cancellation ends guide in place")
	until(w,func():return w.jobs.is_empty())
	check(w.wood==20 and w.metrics.built==2,"Following FIFO survives guide cancellation")
	w=fresh(); w.act("wall",Vector2i(7,13)); w.step()
	w.act("pause"); var building=w.structures.duplicate(true)
	w.act("cancel_job",Vector2i.ZERO,w.jobs[0].id)
	check(w.structures==building,"Started cancellation defers world mutation")
	w.act("pause"); w.step()
	check(w.jobs.is_empty(),"Deferred interruption completes")
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
	w=fresh(); w.act("guide",Vector2i(15,8),1)
	until(w,func():return w.animals[0].has("guide_job"))
	w.Life.hurt(w,{"id":9,"attack_power":30})
	check(w.Life.presentation(w)=="unconscious" and w.animals[0].placed and not w.animals[0].has("guide_job"),"Keeper unconscious stops guidance without removing the animal")
	w.keeper.state="unconscious";steps(w,48)
	check(w.Life.presentation(w)=="settling" and w.jobs_held,"Recovery begins a new rest period")
	w.act("keeper_rest")
	check(w.Life.presentation(w)=="awake","Wake clears sleep presentation")
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
	w=fresh(); w.act("wall",Vector2i(12,8)); w.act("guide",Vector2i(15,8),1)
	var snapshot=w.observation(); var paths=w.Jobs.preview(w)
	check(paths.size()==3,"Preview includes construction, current animal position, and guide destination")
	check(w.observation()==snapshot,"Route preview is read-only")
	var traversable=true
	for leg in paths:
		for p in leg.path: traversable=traversable and w.walkable(p)
	check(traversable,"Preview uses physical walkable paths")
	print("PLANNING: ",checks," checks, failures=",failures)
	quit(1 if failures else 0)
