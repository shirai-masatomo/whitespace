extends "res://tests/test_revisions.gd"

func recovered():
	var w=fresh();w.keeper.state="hidden_rest";w.keeper.hp=8
	check(w.Life.recover_hidden(w),"Explicit recovery fixture returns keeper to free state")
	return w

func run():
	var baseline=OS.get_environment("FARM_WOUNDED_BASELINE")=="1"
	var wait_ticks=ceili(Farm.Life.AUTO_REST_IDLE_SECONDS/0.25)
	var w=recovered();steps(w,wait_ticks)
	if baseline:
		check(not w.keeper.resting and w.job_hold_reason=="rescue" and w.jobs.is_empty(),"Reproduce wounded idle blocked by an empty recovery hold")
	else:
		check(w.keeper.resting and w.keeper.rest_kind=="auto","Wounded keeper with no work rests after eight safe idle seconds following recovery")
		var hp=w.keeper.hp;steps(w,20);check(w.keeper.hp==hp+1,"Rest heals one HP in five seconds")
		w.act("keeper_move",Vector2i(12,13));check(not w.keeper.resting and not w.jobs_held,"New movement wakes recovery rest without leaving a stale hold")
		w=recovered();steps(w,wait_ticks-1);check(not w.keeper.resting,"Recovery does not shorten the eight-second idle grace")
		w.Life.user_activity(w);steps(w,wait_ticks-1);check(not w.keeper.resting,"UI activity restarts the complete idle grace")
		w.step();check(w.keeper.resting,"Idle rest starts after the renewed grace")
		w=fresh();w.keeper.hp=20;w.Life.hurt(w,{"id":-100,"attack_power":2});steps(w,wait_ticks)
		check(not w.keeper.resting,"Recent damage delays the idle timer")
		steps(w,8);check(w.keeper.resting,"Ordinary damage followed by inactivity also rests")
		w=recovered();w.paused=true;steps(w,wait_ticks+4);check(not w.keeper.resting and w.tick==0,"Paused time cannot trigger recovery rest")
		w=recovered();w.act("wall",Vector2i(7,12));w.Jobs.hold(w,"rescue");var jobs=w.jobs.duplicate(true);steps(w,wait_ticks+4)
		check(not w.keeper.resting and w.jobs==jobs and w.job_hold_reason=="rescue","Reserved work remains held for explicit resumption")
		for reason in ["explicit","manual","rest","travel","rest_end"]:
			w=fresh();w.keeper.hp=10;w.Jobs.hold(w,reason);steps(w,wait_ticks+4)
			check(not w.keeper.resting and w.job_hold_reason==reason,"Non-recovery hold is preserved: "+reason)
		w=recovered();w.keeper.hp=w.keeper.max_hp;steps(w,wait_ticks+4)
		check(not w.keeper.resting and w.job_hold_reason=="rescue","Healthy recovery hold does not silently turn into automatic rest")
		w=fresh();w.keeper.hp=10;w.Jobs.hold(w,"danger");steps(w,wait_ticks);check(w.keeper.resting,"Empty damage hold permits wounded idle rest")
		w=fresh();w.keeper.hp=10;w.spawn_enemy({"entry":w.keeper.pos+Vector2i(2,0),"role":"kidnapper"});var e=w.enemies[0]
		e.pos=w.keeper.pos+Vector2i(2,0)
		check(e.hp>0 and not e.done and w.distance(e.pos,w.keeper.pos)==2,"Stationary fixture is alive and exactly two cells away after spawn routing")
		# Step only Life with a stationary living threat to isolate its proximity gate.
		for i in range(wait_ticks+4):w.tick+=1;w.Life.step(w)
		check(not w.keeper.resting,"Living enemies within three cells prevent automatic rest")
		e.hp=0;e.dead_until=w.tick+1000
		for i in range(wait_ticks):w.tick+=1;w.Life.step(w)
		check(w.keeper.resting,"An inert corpse does not count as a living nearby threat")
		e.hp=10;w.tick+=1;w.Life.step(w);check(not w.keeper.resting,"A nearby revived enemy immediately wakes automatic rest")
		w=recovered();w.keeper.state="unconscious";steps(w,wait_ticks)
		check(not w.keeper.resting and w.keeper.state=="unconscious","Idle rest cannot bypass unconscious recovery")
	print("WOUNDED_IDLE: %d checks, failures=%d, baseline=%s"%[checks,failures,baseline]);quit(1 if failures else 0)
