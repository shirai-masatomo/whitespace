extends RefCounted
## Fixed-tick keeper survival; no input/rendering dependency. Tuning is provisional.
const MAX_HP = 30
const ATTACK = 2
const FATIGUE_SECONDS = 270.0 # One 90s day + 180s night represents an active day.
const DRINKS = {"coffee": 12.0, "energy_drink": 25.0}

static func factor(w) -> float:
	return 0.6 if w.keeper.sleepiness >= 80 else 1.0

static func able(w) -> bool:
	return w.keeper.state == "free" and not w.keeper.resting

static func presentation(w) -> String:
	var k = w.keeper
	if k.carrier >= 0: return "carried"
	if k.state != "free": return "unconscious"
	if k.resting: return "settling" if k.get("rest_elapsed", 0.0) < 5.0 else "sleeping"
	return "exhausted" if k.sleepiness >= 90 else ("tired" if k.sleepiness > 80 else ("drowsy" if k.sleepiness > 50 else "awake"))

static func danger(w, kind: String):
	w.danger_serial += 1
	w.life_log.append({"tick": w.tick, "event": kind, "hp": w.keeper.hp, "sleepiness": snappedf(w.keeper.sleepiness, 0.1)})

static func command(w, kind: String, p: Vector2i) -> bool:
	var k = w.keeper
	if not w.working(): return false
	if w.paused:
		if kind == "keeper_move":
			if k.state != "free" or k.forced_rest or not w.walkable(p) or w.actor_occupied(p, k.pos): return false
			w.manual_goal = p
			w.jobs_held = true
			k.pending_command = {"kind": kind, "pos": p}
			return true
		if kind in ["keeper_rest", "resume_jobs"]:
			k.pending_command = {"kind": kind, "pos": p}
			return true
		return false
	if kind == "keeper_move":
		if k.state != "free" or k.forced_rest or not w.walkable(p) or w.actor_occupied(p, k.pos): return false
		set_rest(w, false)
		w.jobs_held = true
		w.manual_goal = p
		w.job_log.append({"tick": w.tick, "event": "manual_move", "pos": [p.x, p.y]})
		return true
	if kind == "keeper_rest":
		if k.state != "free" or k.forced_rest: return false
		set_rest(w, not k.resting)
		w.manual_goal = null
		w.jobs_held = true
		w.life_log.append({"tick": w.tick, "event": "rest" if k.resting else "wake"})
		return true
	if kind == "resume_jobs":
		if k.state != "free" or k.forced_rest: return false
		set_rest(w, false)
		w.manual_goal = null
		w.jobs_held = false
		return true
	if DRINKS.has(kind):
		if k.state != "free" or w.campaign.items.get(kind, 0) <= 0 or k.drinks_today >= 2 or k.sleepiness <= 0: return false
		w.campaign.items[kind] -= 1
		k.drinks_today += 1
		k.sleepiness = maxf(0, k.sleepiness - DRINKS[kind])
		w.life_log.append({"tick": w.tick, "event": kind})
		return true
	return false

static func set_rest(w, value: bool):
	var k = w.keeper
	if k.resting == value: return
	k.resting = value
	k.rest_elapsed = 0.0
	w.life_log.append({"tick": w.tick, "event": "rest_started" if value else "rest_ended"})

static func step(w):
	var k = w.keeper
	if k.has("pending_command"):
		var request = k.pending_command
		k.erase("pending_command")
		command(w, request.kind, request.pos)
	if k.state == "unconscious":
		k.recover_ticks += 1
		if k.recover_ticks >= 48:
			k.hp = 8
			k.state = "free"
			set_rest(w, true)
			w.jobs_held = true
			w.milestones.append({"tick": w.tick, "kind": "keeper_recovered"})
		return
	if k.state != "free": return
	var near = w.enemies.any(func(e): return not e.done and not e.flee and w.distance(e.pos, k.pos) <= 3)
	if near and not k.get("danger_near", false): danger(w, "approaching")
	k.danger_near = near
	if k.resting:
		k.rest_elapsed = k.get("rest_elapsed", 0.0) + w.DT
		if k.rest_elapsed == 5.0: w.life_log.append({"tick": w.tick, "event": "rest_recovery_started"})
		if k.rest_elapsed > 5.0: k.sleepiness = maxf(0, k.sleepiness - 2.0 * w.DT)
		k.heal_credit += w.DT
		if k.heal_credit >= 5:
			k.hp = mini(k.max_hp, k.hp + 1)
			k.heal_credit -= 5
		if k.forced_rest and k.sleepiness < 80:
			k.forced_rest = false
			set_rest(w, false)
	else:
		k.sleepiness = minf(100, k.sleepiness + 100.0 / FATIGUE_SECONDS * w.DT)
		for threshold in [60, 80, 90, 100]:
			if k.sleepiness >= threshold and k.warned < threshold:
				k.warned = threshold
				w.milestones.append({"tick": w.tick, "kind": "sleep_warning", "value": threshold})
		if k.sleepiness >= 100:
			k.forced_rest = true
			set_rest(w, true)
			w.manual_goal = null
	if k.sleepiness < 60: k.warned = 0
	# Minimum self-defense, never chasing; deliberately much weaker than the dog.
	if able(w) and w.tick >= k.next_attack:
		var threats = w.enemies.filter(func(e): return not e.done and not e.flee and w.distance(e.pos, k.pos) <= 1)
		if not threats.is_empty():
			var e = threats[0]
			k.next_attack = w.tick + ceili(1.5 / factor(w) / w.DT)
			e.hp = maxi(0, e.hp - ATTACK)
			w.combat_log.append({"tick": w.tick, "source": "keeper", "id": -1, "target": e.id, "damage": ATTACK})
			if e.hp == 0:
				e.flee = true
				if w.stage == 1 and e.id == 0: w.drop_blueprint(e.pos)
	if able(w) and w.manual_goal != null:
		if k.pos == w.manual_goal:
			w.manual_goal = null
			return
		k.move_credit = minf(1.9, k.move_credit + w.Jobs.SPEED * factor(w) * w.DT)
		if k.move_credit < 1: return
		var next = w.next_step(k.pos, w.manual_goal, false, true)
		if next == k.pos:
			# Wait for moving actors; solid unreachable destinations end just this direct order.
			if w.next_step(k.pos, w.manual_goal) == k.pos:
				w.manual_goal = null
				w.say("道がふさがっているよ")
			return
		if w.actor_occupied(next, k.pos): return
		k.move_credit -= 1
		k.pos = next
		w.keeper_path.append([next.x, next.y])
		if k.pos == w.manual_goal: w.manual_goal = null

static func hurt(w, e):
	var k = w.keeper
	if k.hp <= 0: return
	k.hp = maxi(0, k.hp - e.attack_power)
	k.hurt_until = w.tick + 8
	danger(w, "keeper_hit")
	w.combat_log.append({"tick": w.tick, "source": "keeper_hit", "id": e.id, "target": -1, "damage": e.attack_power})
	if k.hp == 0:
		k.state = "unconscious"
		k.recover_ticks = 0
		set_rest(w, false)
		w.manual_goal = null
		w.jobs_held = true
		w.milestones.append({"tick": w.tick, "kind": "keeper_down", "id": e.id})
