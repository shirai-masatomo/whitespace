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
		"gold": maxi(0, roundi(base.gold * (1.0 + growth.gold * n)))}

static func damage(attack: int, defense: int, variance: float = 1.0, critical: float = 1.0) -> int:
	var a := float(maxi(1, attack))
	var d := float(maxi(0, defense))
	return maxi(1, roundi(a * (a + 4.0) / (a + 4.0 + 2.0 * d) * variance * critical))

static func normalized(unit: Dictionary) -> Dictionary:
	var result := unit.duplicate(true)
	result.max_hp = maxi(1, int(result.max_hp))
	result.max_sp = maxi(0, int(result.max_sp))
	result.hp = clampi(int(result.hp), 0, result.max_hp)
	result.sp = clampi(int(result.sp), 0, result.max_sp)
	result.atk = maxi(1, int(result.atk))
	result.def = maxi(0, int(result.def))
	result.spd = maxi(1, int(result.spd))
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
		var hit := rng.randf() < float(state.rules.hit_chance)
		var critical := false
		var amount := 0
		if hit:
			critical = rng.randf() < float(state.rules.critical_chance)
			amount = damage(actor.atk, target.def, rng.randf_range(state.rules.variance_min, state.rules.variance_max),
				float(state.rules.critical_multiplier) if critical else 1.0)
			target.hp = maxi(0, int(target.hp) - amount)
		state.log.append({"type": "attack", "round": state.round, "actor": side, "target": other,
			"hit": hit, "critical": critical, "damage": amount, "target_hp": target.hp, "death": target.hp == 0})
	state.rng_state = rng.state
	finish_if_needed(state)
	return state

static func simulate(hero: Dictionary, foe: Dictionary, rules: Dictionary, battle_seed: int) -> Dictionary:
	var state := start(hero, foe, rules, battle_seed)
	while state.outcome == "ongoing":
		state = advance(state)
	return state
