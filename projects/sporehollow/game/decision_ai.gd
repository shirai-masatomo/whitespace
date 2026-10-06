extends RefCounted
## Seeded decisions are sampled only on deadlines/context transitions, never per tick.
static func choose(w, actor: Dictionary, type: String, state: String, choices: Dictionary, rescue: bool = false) -> String:
	if actor.get("ai_context", "") == state and w.tick < actor.get("next_decision", 0): return actor.intent
	var key = type + "_%d" % actor.id
	if not w.actor_rngs.has(key):
		var generator = RandomNumberGenerator.new()
		generator.seed = w.seed_value * 1009 + actor.id * 97 + (701 if type == "shiba" else 1709)
		w.actor_rngs[key] = generator
	var rng: RandomNumberGenerator = w.actor_rngs[key]
	var weights = choices.duplicate(true)
	var accuracy=actor.get("ai_accuracy",40)
	var noise: float = w.Rules.AI.rescue_randomness if rescue else w.Rules.AI.randomness*(100-accuracy)/60.0
	for action in ["watch", "bark", "reposition", "hesitate", "detour"]:
		if weights.has(action): weights[action] *= noise
	# Bound inattentiveness: never chain two passive/inefficient decisions.
	if actor.get("inefficient", false):
		for action in ["watch", "bark", "reposition", "hesitate", "detour"]: weights.erase(action)
	var total = 0.0
	for weight in weights.values(): total += weight
	var roll = rng.randf()
	var cursor = roll * total
	var selected: String = weights.keys()[0]
	for action in weights:
		cursor -= weights[action]
		if cursor <= 0:
			selected = action
			break
	var seconds = rng.randf_range(w.Rules.AI.decision_min, w.Rules.AI.decision_max)*(1.0+(40-accuracy)/100.0)
	var ticks = ceili(seconds / w.DT)
	if rescue: ticks = 2 + int(roll < w.Rules.AI.rescue_randomness)
	actor.next_decision = w.tick + ticks
	actor.ai_context = state
	actor.intent = selected
	actor.intent_roll = roll
	actor.side_step_used = false
	actor.inefficient = selected in ["watch", "bark", "reposition", "hesitate", "detour"]
	var record = {"tick": w.tick, "time": w.tick * w.DT, "actor": key, "actor_type": type, "lv": actor.lv,
		"state": state, "choices": weights, "selected": selected, "roll": snappedf(roll, 0.00001),
		"randomness": w.Rules.AI.rescue_randomness if rescue else w.Rules.AI.randomness,
		"rescue_mode": rescue, "next_tick": actor.next_decision}
	w.decision_log.append(record)
	w.decision_count += 1
	# Retain opening and recent decisions; aggregate counters below never truncate.
	if w.decision_log.size() > w.Rules.AI.log_limit: w.decision_log.remove_at(w.Rules.AI.log_limit / 2)
	var counter_key = type + ":" + selected
	w.decision_counts[counter_key] = w.decision_counts.get(counter_key, 0) + 1
	return selected
