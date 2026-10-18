extends RefCounted
## Pure deterministic combat: no Node, file, UI, clock or global RNG access.
## Inputs are copied; only this core owns the combat formulas.

static func enemy(data: Dictionary, enemy_id: String, level: int) -> Dictionary:
	assert(level >= 1 and data.enemies.has(enemy_id))
	# Only raw catalog entries enter here. No floor/stat multiplier is accepted.
	var base: Dictionary = data.enemies[enemy_id]
	var growth: Dictionary = data.rules.enemy_growth
	var n := level - 1
	var hp := maxi(1, roundi(base.hp * (1.0 + growth.hp * n)))
	var sp := int(base.sp) + floori(float(n) / growth.sp_interval)
	return {"id": enemy_id, "name": base.name, "level": level,
		"max_hp": hp, "hp": hp, "atk": maxi(1, roundi(base.atk * (1.0 + growth.atk * n))),
		"def": int(base.def) + floori(float(n) / growth.def_interval), "spd": int(base.spd),
		"max_sp": sp, "sp": sp, "exp": maxi(1, roundi(base.exp * (1.0 + growth.exp * n))),
		"gold": maxi(0, roundi(base.gold * (1.0 + growth.gold * n))), "skills":base.get("skills",[]).duplicate()}

static func damage(attack: int, defense: float, variance: float = 1.0, critical: float = 1.0, multiplier: float = 1.0) -> int:
	var a := float(maxi(1, attack))
	var d := maxf(0.0, defense)
	return maxi(1, roundi(a * (a + 4.0) / (a + 4.0 + 2.0 * d) * multiplier * variance * critical))

static func normalized(unit: Dictionary) -> Dictionary:
	var result := unit.duplicate(true)
	result.max_hp = maxi(1, int(result.max_hp))
	result.max_sp = maxi(0, int(result.max_sp))
	result.hp = clampi(int(result.hp), 0, result.max_hp)
	result.sp = clampi(int(result.sp), 0, result.max_sp)
	result.atk = maxi(1, int(result.atk))
	result.def = maxi(0, int(result.def))
	result.spd = maxi(1, int(result.spd))
	result.skills = result.get("skills",[]).duplicate()
	result.action_count = 0
	result.defense_until = -1
	result.cooldown_until = 0
	result.statuses = {}
	result.skill_cooldowns = {}
	return result

static func start(hero: Dictionary, foe: Dictionary, rules: Dictionary, battle_seed: int) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = battle_seed
	var state := {"hero": normalized(hero), "enemy": normalized(foe), "rules": rules.duplicate(true),
		"seed": battle_seed, "rng_state": rng.state, "round": 0, "outcome": "ongoing", "log": [],
		"reward": {"exp": 0, "gold": 0}}
	finish_if_needed(state)
	return state

static func finish_if_needed(state: Dictionary) -> void:
	if state.hero.hp <= 0:
		state.outcome = "defeat"
	elif state.enemy.hp <= 0:
		state.outcome = "victory"
		state.reward = {"exp": int(state.enemy.get("exp", 0)), "gold": int(state.enemy.get("gold", 0))}
	elif state.round >= int(state.rules.max_rounds):
		state.outcome = "draw"

static func effective_def(unit: Dictionary, rules: Dictionary) -> float:
	var bonus: float = float(rules.get("skills",{}).get("S105",{}).get("def_bonus",0.0)) if int(unit.get("defense_until",-1))>=0 else 0.0
	return float(unit.def) * (1.0 + bonus)

static func end_defense(state: Dictionary, side: String, reason: String) -> void:
	var unit: Dictionary=state[side]
	if int(unit.get("defense_until",-1))<0: return
	unit.defense_until=-1
	state.log.append({"type":"status_removed","actor":side,"skill":"S105","round":state.round,"status":"defense","reason":reason})

static func finish_action(state: Dictionary, side: String) -> void:
	var unit: Dictionary=state[side]
	for id in unit.statuses.keys():
		unit.statuses[id].remaining-=1
		if unit.statuses[id].remaining<=0: remove_status(state,side,id,"expired")
	if int(unit.defense_until)>=0 and int(unit.action_count)>=int(unit.defense_until): end_defense(state,side,"expired")

static func use_defense(state: Dictionary, side: String) -> bool:
	var unit: Dictionary=state[side]
	var skill: Dictionary=state.rules.get("skills",{}).get("S105",{})
	if not "S105" in unit.skills or skill.is_empty(): return false
	if unit.hp>unit.max_hp*float(skill.hp_threshold) or unit.sp<int(skill.sp_cost) or unit.defense_until>=0 or unit.action_count<=unit.cooldown_until: return false
	unit.sp-=int(skill.sp_cost)
	unit.defense_until=unit.action_count+int(skill.duration_own_actions)
	unit.cooldown_until=unit.action_count+int(skill.cooldown_own_actions)
	state.log.append({"type":"skill","actor":side,"skill":"S105","round":state.round,"sp":unit.sp,"effective_def":effective_def(unit,state.rules),"expires_after_action":unit.defense_until,"cooldown_until":unit.cooldown_until})
	return true

static func remove_status(state: Dictionary, side: String, id: String, reason: String) -> void:
	var effect: Dictionary=state[side].statuses[id]
	state[side].statuses.erase(id)
	state.log.append({"type":"status_removed","actor":side,"status":id,"skill":effect.skill,"round":state.round,"reason":reason})

static func clear_statuses(state: Dictionary, side: String, reason: String) -> void:
	end_defense(state,side,reason)
	for id in state[side].statuses.keys(): remove_status(state,side,id,reason)

static func apply_status(state: Dictionary, side: String, target: String, skill_id: String) -> void:
	var skill: Dictionary=state.rules.skills[skill_id]
	var id: String=skill.status_id
	var effects: Dictionary=state[target].statuses
	var replaced:=effects.has(id)
	# Provisional contract: snapshot effective ATK once; replace, never stack.
	var potency: float=roundi(state[side].atk*skill.potency) if id=="poison" else float(skill.potency)
	effects[id]={"skill":skill_id,"source":side,"potency":potency,"remaining":int(skill.duration_own_actions)}
	state.log.append({"type":"status_applied","actor":side,"target":target,"skill":skill_id,"status":id,"round":state.round,"potency":potency,"remaining":int(skill.duration_own_actions),"reapplied":replaced})

static func start_opportunity(state: Dictionary, side: String) -> bool:
	var unit: Dictionary=state[side]
	if unit.statuses.has("poison"):
		var effect: Dictionary=unit.statuses.poison
		var amount:=int(effect.potency)
		unit.hp=maxi(0,int(unit.hp)-amount)
		state.log.append({"type":"status_damage","actor":side,"source":effect.source,"skill":effect.skill,"status":"poison","round":state.round,"damage":amount,"target_hp":unit.hp,"death":unit.hp==0})
		if unit.hp==0:
			clear_statuses(state,side,"death")
			return false
	if unit.statuses.has("paralysis"):
		state.log.append({"type":"action_skipped","actor":side,"status":"paralysis","round":state.round})
		return false
	return true

static func attack_skill(state: Dictionary, side: String) -> String:
	if not state.rules.get("status_pilot",false): return ""
	var unit: Dictionary=state[side]
	# Catalog order only. Smarter selection belongs to phase 4.
	for id in unit.skills:
		if not id in ["S102","S103","S104"]: continue
		var skill: Dictionary=state.rules.skills.get(id,{})
		if skill.is_empty() or unit.sp<skill.sp_cost or unit.action_count<=unit.skill_cooldowns.get(id,0): continue
		unit.sp-=int(skill.sp_cost)
		unit.skill_cooldowns[id]=unit.action_count+int(skill.cooldown_own_actions)
		state.log.append({"type":"skill","actor":side,"skill":id,"round":state.round,"sp":unit.sp,"cooldown_until":unit.skill_cooldowns[id]})
		return id
	return ""

static func advance(previous: Dictionary) -> Dictionary:
	var state := previous.duplicate(true)
	if state.outcome != "ongoing":
		return state
	state.round += 1
	var rng := RandomNumberGenerator.new()
	rng.seed = int(state.seed)
	rng.state = int(state.rng_state)
	var order: Array[String] = ["hero", "enemy"]
	if state.enemy.spd > state.hero.spd or (state.enemy.spd == state.hero.spd and rng.randi_range(0, 1) == 1):
		order.reverse()
	state.log.append({"type": "round", "round": state.round, "order": order.duplicate()})
	for side in order:
		var other := "enemy" if side == "hero" else "hero"
		var actor: Dictionary = state[side]
		var target: Dictionary = state[other]
		if actor.hp <= 0 or target.hp <= 0:
			break
		actor.action_count+=1
		if not start_opportunity(state,side):
			if actor.hp==0: break
			finish_action(state,side)
			continue
		if use_defense(state,side):
			finish_action(state,side)
			continue
		var skill_id:=attack_skill(state,side)
		var skill: Dictionary=state.rules.get("skills",{}).get(skill_id,{})
		var hit_chance:=clampf(float(state.rules.hit_chance)-float(actor.statuses.get("blind",{}).get("potency",0.0)),0.0,1.0)
		var hit := rng.randf() < hit_chance
		var critical := false
		var amount := 0
		if hit:
			critical = rng.randf() < float(state.rules.critical_chance)
			amount = damage(actor.atk, effective_def(target,state.rules), rng.randf_range(state.rules.variance_min, state.rules.variance_max),
				float(state.rules.critical_multiplier) if critical else 1.0,float(skill.get("damage_multiplier",1.0)))
			target.hp = maxi(0, int(target.hp) - amount)
		state.log.append({"type": "attack", "round": state.round, "actor": side, "target": other,
			"hit": hit, "critical": critical, "damage": amount, "target_hp": target.hp, "death": target.hp == 0})
		if target.hp==0: clear_statuses(state,other,"death")
		elif hit and not skill_id.is_empty() and rng.randf()<float(skill.apply_chance): apply_status(state,side,other,skill_id)
		finish_action(state,side)
	state.rng_state = rng.state
	finish_if_needed(state)
	if state.outcome!="ongoing":
		for side in ["hero","enemy"]: clear_statuses(state,side,"battle_end")
	return state

static func simulate(hero: Dictionary, foe: Dictionary, rules: Dictionary, battle_seed: int) -> Dictionary:
	var state := start(hero, foe, rules, battle_seed)
	while state.outcome == "ongoing":
		state = advance(state)
	return state
