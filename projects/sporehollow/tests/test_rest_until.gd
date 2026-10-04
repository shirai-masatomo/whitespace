extends SceneTree
const Farm=preload("res://game/world.gd")
var checks=0
var failures=0
func check(ok: bool, message: String):
	checks+=1
	if not ok:
		failures+=1
		push_error(message)
func _initialize():call_deferred("run")
func fresh():
	var w=Farm.new({},71).begin_day()
	w.keeper.hp=15
	w.keeper.sleepiness=90.0
	return w
func signature(w):
	return [w.tick,w.keeper.hp,w.keeper.sleepiness,w.natural,w.nature_rng.state,w.animals,w.structures,w.field_items,w.campaign.resources]
func steps(w,n):
	for i in range(n):w.step()
func run():
	var normal=fresh();var fast=fresh()
	normal.act("keeper_rest")
	fast.paused=true
	check(fast.act("rest_until_night"),"Rest advance may be planned while paused")
	steps(fast,20)
	check(fast.tick==0 and not fast.keeper.resting and fast.keeper.sleepiness==90,"Planning never advances or recovers")
	fast.paused=false
	steps(normal,20);steps(fast,20)
	check(fast.keeper.sleepiness==90,"First five seconds have no fatigue recovery")
	steps(normal,340);steps(fast,340)
	check(signature(normal)==signature(fast),"Rest advance uses identical fixed-tick world simulation to night boundary")
	check(fast.phase=="defend" and fast.rest_skip.is_empty() and not fast.keeper.resting,"Night boundary ends advance and wakes voluntary rest")
	check(fast.jobs_held and fast.job_hold_reason=="rest_end","Work never silently resumes after rest advance")
	check(not fast.act("end_night"),"Scheduled future invasion prevents ending night")
	# A safe night, including a continuous existing rest and delayed recovery.
	for already_resting in [false,true]:
		normal=fresh();fast=fresh()
		for w in [normal,fast]:
			w.start_night();w.schedule_index=w.spawn_schedule.size();w.early_clear=true
			if already_resting:
				w.act("keeper_rest");steps(w,12)
		if not already_resting:normal.act("keeper_rest")
		var bonus=floori(fast.remaining_night()/10.0)
		check(fast.act("end_night") and not fast.act("end_night"),"Advance and bonus cannot be duplicated")
		while normal.working():normal.step()
		while fast.working():fast.step()
		check(signature(normal)==signature(fast),"Normal and accelerated rest produce identical vitals, animals, nature and production")
		check(fast.early_finish_bonus==bonus,"Bonus uses request-time remainder once")
		check(fast.milestones.filter(func(m):return m.kind=="dawn").size()==1,"Exactly one dawn")
		var gold=fast.campaign.gold;steps(fast,20)
		check(fast.campaign.gold==gold and not fast.act("end_night"),"No duplicate reward after dawn")
	fast=fresh();fast.act("rest_until_night");steps(fast,24)
	check(fast.act("cancel_rest_until") and fast.rest_skip.is_empty() and fast.keeper.resting,"Interrupt advances without secretly waking")
	check(fast.early_finish_bonus==0,"Interrupted advance has no prepaid bonus")
	fast=fresh();fast.act("rest_until_night");steps(fast,1)
	fast.Life.danger(fast,"test_danger");fast.step()
	check(fast.rest_skip.is_empty(),"Danger ends acceleration")
	fast=fresh();fast.day_seconds=1;fast.keeper.sleepiness=100;fast.keeper.forced_rest=true;fast.Life.set_rest(fast,true)
	fast.act("rest_until_night");steps(fast,4)
	check(fast.keeper.resting and fast.keeper.forced_rest,"Night boundary never bypasses forced rest")
	fast=fresh();fast.animals[0].loyalty=100;fast.act("guide",Vector2i(15,10),1)
	steps(fast,4)
	check(not fast.act("rest_until_night"),"Unfinished animal guidance prevents bulk rest")
	# Empty stale holds are cleared by a new request, active interrupted work is not.
	fast=fresh();fast.Jobs.hold(fast,"manual")
	check(fast.act("wall",Vector2i(7,12)) and not fast.jobs_held,"New request with an empty queue clears obsolete manual hold")
	fast.Jobs.hold(fast,"manual");fast.act("wall",Vector2i(8,12))
	check(fast.jobs_held,"Appending to evacuation-held work never resumes it")
	print("REST UNTIL: ",checks," checks, failures=",failures)
	quit(1 if failures else 0)
