extends RefCounted
## Per-instance equipment condition. Never alters base hero growth or combat RNG.
const MAXIMUM := 100
static func fresh() -> Dictionary:
	return {"current":MAXIMUM,"maximum":MAXIMUM}
static func bonus(s: Dictionary, uid: String, base_value: int) -> int:
	if int(s.schema_version)<4: return base_value
	var condition: Dictionary=s.item_condition[uid]
	return roundi(float(base_value)*int(condition.current)/int(condition.maximum))
static func cost(s: Dictionary, uid: String, cfg: Dictionary) -> int:
	if int(s.schema_version)<4 or not s.items.has(uid) or cfg.items[s.items[uid]].slot=="": return -1
	var condition: Dictionary=s.item_condition[uid]
	return (int(condition.maximum)-int(condition.current))*int(cfg.condition_rules.repair_gold_per_point)
static func wear(s: Dictionary, cfg: Dictionary) -> void:
	if int(s.schema_version)<4: return
	for uid in s.equipment.values():
		if uid!="": s.item_condition[uid].current=maxi(0,int(s.item_condition[uid].current)-int(cfg.condition_rules.wear_per_battle))
static func validate(s: Dictionary) -> String:
	if int(s.schema_version)<4: return ""
	if s.get("condition_version")!=1 or not s.get("item_condition") is Dictionary: return "Unsupported equipment condition version"
	if s.item_condition.size()!=s.items.size(): return "Missing/orphaned equipment condition"
	for uid in s.items:
		var value=s.item_condition.get(uid)
		if not value is Dictionary: return "Missing instance condition"
		for key in ["current","maximum"]:
			if not value.has(key) or not (value[key] is int or value[key] is float) or value[key]!=floorf(value[key]): return "Invalid condition number"
		if value.maximum!=MAXIMUM or value.current<0 or value.current>value.maximum: return "Condition out of range"
	return ""
