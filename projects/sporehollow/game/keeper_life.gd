extends RefCounted
## Fixed-tick keeper survival; no input/rendering dependency. Tuning is provisional.
const MAX_HP = 30
const ATTACK = 2
const CLOSE_ATTACK_RANGE = 1 # Eight neighboring cells, with sight; never a pursuit radius.
const OBJECT_ATTACK = 1 # Shared capability; no new building-attack command is implied.
const CAPTURE_GRACE = 12.0
const HIDDEN_HEAL_SECONDS = 6.0
const HIDDEN_RECOVER_HP = 8
const AUTO_REST_IDLE_SECONDS = 8.0 # Provisional: give the player three more seconds to plan.

static func targetable(w, capture: bool=false) -> bool:
	return w.keeper.placed and (w.keeper.state=="free" and w.keeper.hp>0 or capture and w.keeper.state in ["unconscious","restrained"])
const FATIGUE_SECONDS = 432.0 # Provisional: one full colony calendar day.
const DRINKS = {"coffee": 12.0, "energy_drink": 25.0}

static func rest_until_reason(w, target: String) -> String:
	if not w.working(): return "今は休息できません"
	if target not in ["night","dawn"]:return "休息の行き先を確認してください"
	if w.keeper.get("drafted",false):return "徴兵を解除してください"
	if w.keeper.get("nutrition_down",false):return "栄養失調で行動不能です。手元の食料を待っています"
	if w.keeper.state != "free" or w.keeper.carrier >= 0: return "牧場主が行動できません"
	if w.jobs.any(func(j): return j.kind=="animal_order" and j.order=="guide"): return "仲間の誘導を先に終えてください"
	var period=w.Cycle.period(w)
	if target=="night" and period=="night":return "夜は朝までの休息を選んでください"
	if target=="dawn" and period!="night":return "朝までの休息は夜に使えます"
	if w.story.idol.get("state","") in ["preparing","transporting"]:return "黄金像の搬出を止めてください"
	if not preload("res://game/colony_ui_state.gd").threats(w).is_empty():return "敵が残っています"
	if target=="dawn" and (w.config.repeat_waves or w.schedule_index<w.spawn_schedule.size()):return "襲来の予定が残っています"
	return ""

static func plan_rest_until(w, target: String) -> bool:
	if not w.rest_skip.is_empty() or rest_until_reason(w,target)!="": return false
	w.rest_skip = {"target":target,"pending":true,"danger":w.danger_serial,"bonus":floori(w.remaining_night()/10.0) if target=="dawn" else 0}
	w.life_log.append({"tick":w.tick,"event":"rest_until_planned","target":target})
	return true

static func begin_rest_until(w):
	if w.rest_skip.is_empty() or not w.rest_skip.pending: return
	if rest_until_reason(w,w.rest_skip.target)!="":
		stop_rest_until(w,"unavailable")
		return
	w.rest_skip.pending=false
	w.keeper.erase("pending_command")
	w.keeper.hold_before_rest="rest_end"
	set_rest(w,true)
	w.manual_goal=null
	w.Jobs.hold(w,"rest")
	w.life_log.append({"tick":w.tick,"event":"rest_until_started"})

static func stop_rest_until(w, reason: String):
	if w.rest_skip.is_empty(): return
	w.rest_skip.clear()
	w.life_log.append({"tick":w.tick,"event":"rest_until_stopped","reason":reason})
	# Stopping the clock advance does not secretly wake forced sleepers or resume work.
	if reason in ["nightfall","morning"]:
		if not w.keeper.forced_rest: set_rest(w,false)
		w.Jobs.hold(w,"rest_end")

static func check_rest_until(w):
	if w.rest_skip.is_empty(): return
	if w.danger_serial != w.rest_skip.danger or w.keeper.state!="free":
		stop_rest_until(w,"danger")
	elif w.rest_skip.target=="night" and w.Cycle.period(w)=="night": stop_rest_until(w,"nightfall")

static func factor(w) -> float:
	return (0.6 if w.keeper.sleepiness >= 80 else 1.0)*w.Nutrition.factor(w.keeper)

static func able(w) -> bool:
	return w.keeper.state == "free" and not w.keeper.resting and not w.keeper.get("nutrition_down",false) and not w.keeper.get("dead",false)

static func presentation(w) -> String:
	var k = w.keeper
	if k.carrier >= 0: return "carried"
	if k.state == "hidden_rest":return "hidden_rest"
	if k.state != "free": return "unconscious"
	if k.resting: return "settling" if not k.get("asleep",false) else "sleeping"
	return "exhausted" if k.sleepiness >= 90 else ("tired" if k.sleepiness > 80 else ("drowsy" if k.sleepiness > 50 else "awake"))

static func danger(w, kind: String):
	wake_auto(w)
	w.danger_serial += 1
	w.life_log.append({"tick": w.tick, "event": kind, "hp": w.keeper.hp, "sleepiness": snappedf(w.keeper.sleepiness, 0.1)})

static func command(w, kind: String, p: Vector2i) -> bool:
	var k = w.keeper
	if not w.working() or k.get("nutrition_down",false): return false
	if k.get("drafted",false) and kind in ["keeper_rest","resume_jobs","wake_hidden"]:return false
	if kind=="wake_hidden" or (kind=="keeper_rest" and k.state=="hidden_rest"):
		if not can_wake_hidden(w):return false
		if w.paused:k.pending_command={"kind":"wake_hidden","pos":p};return true
		return recover_hidden(w)
	if kind == "keeper_move":
		if not k.get("drafted",false) or not w.walkable(p):return false
		# A drafted destination replaces the previous direct order; it is not a manual work queue.
		for previous in w.jobs.duplicate():
			if previous.get("direct_control",false):w.Jobs.cancel(w,previous.id)
		if not w.Jobs.enqueue(w,"move",p,-1):return false
		w.jobs.back().direct_control=true
		return true
	if w.paused:
		if kind in ["keeper_rest", "resume_jobs"]:
			if k.state != "free": return false
			stop_rest_until(w,"manual")
			k.pending_command = {"kind": kind, "pos": p}
			return true
		return false
	if kind == "keeper_rest":
		if k.state != "free": return false
		stop_rest_until(w,"manual")
		if not k.resting:
			k.hold_before_rest = w.job_hold_reason if w.jobs_held else ""
			set_rest(w, true)
			w.Jobs.hold(w, "rest")
		else:
			w.Sleep.wake(w,k,true)
			w.Jobs.hold(w, k.get("hold_before_rest", "") if k.get("hold_before_rest", "") != "travel" else "")
		w.manual_goal = null
		w.life_log.append({"tick": w.tick, "event": "rest" if k.resting else "wake"})
		return true
	if kind == "resume_jobs":
		if k.state != "free": return false
		stop_rest_until(w,"manual")
		w.Sleep.wake(w,k,true)
		w.manual_goal = null
		w.Jobs.hold(w, "")
		return true
	if DRINKS.has(kind):
		if k.state != "free" or w.campaign.items.get(kind, 0) <= 0 or k.drinks_today >= 2 or k.sleepiness <= 0: return false
		if not w.Stock.consume(w,kind,1):return false
		k.drinks_today += 1
		k.sleepiness = maxf(0, k.sleepiness - DRINKS[kind])
		w.life_log.append({"tick": w.tick, "event": kind})
		return true
	return false

static func end_move(w):
	w.manual_goal=null
	if w.job_hold_reason=="travel": w.Jobs.hold(w,"")

static func wake_auto(w):
	var k=w.keeper
	if k.get("rest_kind","")!="auto" or not k.resting: return
	if w.paused: k.auto_wake_pending=true; return
	set_rest(w,false)
	if w.job_hold_reason=="auto_rest": w.Jobs.hold(w,"")

static func idle_step(w, near: bool):
	var k=w.keeper
	# Empty recovery holds have no work to resume. Keep explicit waits and every queued job.
	var recovery_idle=k.hp<k.max_hp and w.job_hold_reason in ["rescue","danger"]
	var idle=able(w) and k.sleepiness<100 and not near and w.tick>=k.hurt_until and w.manual_goal==null and w.jobs.is_empty() and (not w.jobs_held or recovery_idle)
	k.idle_elapsed=k.get("idle_elapsed",0.0)+w.DT if idle else 0.0
	if k.idle_elapsed>=AUTO_REST_IDLE_SECONDS and (k.sleepiness>0 or k.hp<k.max_hp):
		set_rest(w,true,"auto")
		w.Jobs.hold(w,"auto_rest")

static func user_activity(w):
	# UI activity postpones only automatic idle rest; it cannot escape manual/forced rest or recovery.
	w.keeper.idle_elapsed=0.0
	wake_auto(w)

static func set_rest(w, value: bool, origin: String="manual"):
	var k = w.keeper
	if k.resting == value:
		if value: k.rest_kind=origin
		return
	k.resting = value
	k.rest_kind = origin if value else ""
	if value: k.rest_started_tick=w.tick;w.Zones.begin_rest(w,k)
	else:k.erase("rest_target");k.erase("rest_reason")
	if origin=="auto" and value: k.hold_before_rest=""
	k.idle_elapsed=0.0
	k.rest_elapsed = 0.0
	k.asleep = false
	w.life_log.append({"tick": w.tick, "event": "rest_started" if value else "rest_ended"})

static func step(w):
	var k = w.keeper
	if k.get("auto_wake_pending",false):
		k.erase("auto_wake_pending")
		wake_auto(w)
	if k.has("pending_command"):
		var request = k.pending_command
		k.erase("pending_command")
		command(w, request.kind, request.pos)
		if request.kind=="keeper_move":w.Jobs.hold(w,request.get("hold_reason","manual"))
	if k.state == "unconscious":
		k.recover_ticks += 1
		if k.restrainer>=0 and not w.enemies.any(func(e):return e.id==k.restrainer and e.hp>0 and not e.done and not e.flee and e.capture_progress>0 and w.distance(e.pos,k.pos)<=1): k.restrainer=-1
		var capturing=w.enemies.any(func(e):return not e.done and not e.flee and e.hp>0 and e.get("capture_progress",0)>0 and w.distance(e.pos,k.pos)<=1)
		if k.recover_ticks >= ceili(CAPTURE_GRACE/w.DT) and k.carrier<0 and k.restrainer<0 and not capturing:
			k.state="hidden_rest";k.heal_credit=0.0
			w.PlayerEvents.add(w,"牧場主：隠れて療養中")
		return
	if k.state=="hidden_rest":
		k.heal_credit+=w.DT
		if k.heal_credit>=HIDDEN_HEAL_SECONDS:
			k.heal_credit-=HIDDEN_HEAL_SECONDS;k.hp=mini(k.max_hp,k.hp+1)
		if k.hp>=HIDDEN_RECOVER_HP:recover_hidden(w)
		return
	if k.state != "free" or k.get("nutrition_down",false): return
	var near = w.enemies.any(func(e): return not e.done and not e.flee and e.hp>0 and w.distance(e.pos, k.pos) <= 3)
	if near and not k.get("danger_near", false): danger(w, "approaching")
	k.danger_near = near
	if near: wake_auto(w)
	if k.get("life_need","")=="food":return # Food owns movement until this meal ends.
	# Explicit target jobs own attack timing; otherwise defend within equipped reach.
	if able(w) and w.tick>=k.next_attack and not w.jobs.any(func(j):return j.kind=="direct_attack" and not j.get("cancel_requested",false)):
		var threats=w.enemies.filter(func(e):return close_attack_target(w,e))
		threats.sort_custom(func(a,b):return w.distance(k.pos,a.pos)<w.distance(k.pos,b.pos) if w.distance(k.pos,a.pos)!=w.distance(k.pos,b.pos) else a.id<b.id)
		if not threats.is_empty():w.HumanCombat.attack(w,k,threats[0])

static func close_attack_target(w,e) -> bool:
	return w.HumanCombat.in_range(w,w.keeper,e)

static func can_wake_hidden(w) -> bool:
	var k=w.keeper
	return k.state=="hidden_rest" and k.hp>0 and k.placed and k.carrier<0 and k.restrainer<0

static func recover_hidden(w) -> bool:
	if not can_wake_hidden(w):return false
	var k=w.keeper
	k.state="free";k.kill_gauge_awarded=false;k.hold_before_rest="rescue"
	k.resting=false;k.forced_rest=false;k.heal_credit=0.0;k.recover_ticks=0
	k.erase("pending_command");k.erase("rest_kind");k.asleep=false
	w.Jobs.hold(w,"rescue");w.PlayerEvents.add(w,"牧場主が復帰。作業再開を選べます")
	w.milestones.append({"tick":w.tick,"kind":"keeper_recovered"})
	return true

static func hurt(w, e):
	var k = w.keeper
	if not targetable(w): return
	var before=k.hp
	k.hp = maxi(0, k.hp - e.attack_power)
	var originals=w.enemies.filter(func(actor):return actor.id==e.id)
	if not originals.is_empty():w.Combat.hit(w,originals[0],k,e.get("combat_action","attack"),before-k.hp,e.get("combat_skill",false))
	k.hurt_until = w.tick + 8
	w.Resident.attacked(w,k)
	if before>k.hp:
		w.last_keeper_attacker_id=e.id;w.rescue_until=w.tick+ceili(6.0/w.DT)
	danger(w, "keeper_hit")
	w.Story.interrupt_prayer(w)
	w.Orders.interrupt(w)
	w.combat_log.append({"tick": w.tick, "source": "keeper_hit", "id": e.id, "target": -1, "damage": e.attack_power})
	if k.hp == 0:
		k.state = "unconscious"
		if originals.is_empty():w.PlayerEvents.add(w,"牧場主：気絶")
		k.recover_ticks = 0
		w.Sleep.wake(w,k,true)
		w.manual_goal = null
		w.Jobs.hold(w, "rescue")
		w.milestones.append({"tick": w.tick, "kind": "keeper_down", "id": e.id})
