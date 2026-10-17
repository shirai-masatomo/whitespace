extends RefCounted
const E = preload("res://core/expedition.gd")

static func validate(p: Dictionary) -> String:
	if not p.has_all(["schema_version","policy_id","max_trips","floor_limits","return_hp_fraction","boss_min_hp_fraction","equipment_weights","skip_harmful_events","store_spares"]): return "Missing policy fields"
	if p.schema_version!=1 or not p.policy_id is String or not E.integer(p.max_trips,1,100): return "Invalid policy identity/budget"
	if not p.floor_limits is Array or p.floor_limits.is_empty() or not p.equipment_weights is Dictionary or not p.skip_harmful_events is bool or not p.store_spares is bool: return "Invalid policy containers"
	for key in ["return_hp_fraction","boss_min_hp_fraction"]:
		if not E.Catalog.numeric(p[key]) or p[key]<0 or p[key]>1: return "Invalid retreat fraction"
	var prior:=0
	for row in p.floor_limits:
		if not row is Dictionary or not E.integer(row.get("below_level"),1,101) or row.below_level<=prior or not E.integer(row.get("floor"),1,10): return "Invalid depth stages"
		prior=int(row.below_level)
	if prior!=101: return "Depth stages must cover all levels"
	for key in E.STATS:
		if not E.Catalog.numeric(p.equipment_weights.get(key)) or p.equipment_weights[key]<0: return "Invalid equipment weights"
	return ""

static func score(item: Dictionary, policy: Dictionary) -> float:
	var result:=0.0
	for key in item.stats: result+=float(item.stats[key])*float(policy.equipment_weights[key])
	return result

static func choose(s: Dictionary, cfg: Dictionary, policy: Dictionary) -> Dictionary:
	match s.phase:
		"town":
			for uid in s.inventory:
				var item: Dictionary=cfg.items[s.items[uid]]
				if item.slot=="": continue
				var equipped: String=s.equipment[item.slot]
				if equipped=="" or score(item,policy)>score(cfg.items[s.items[equipped]],policy):
					return {"action":"equip","args":{"uid":uid}}
			if policy.store_spares and not s.inventory.is_empty(): return {"action":"deposit","args":{"uid":s.inventory[0]}}
			return {"action":"depart","args":{}}
		"result": return {"action":"town","args":{}}
		"battle": return {"action":"round","args":{}}
		"event":
			var ev: Dictionary=cfg.events[s.event]
			var harmful: bool=ev.effect=="hp" and ev.amount<0
			return {"action":"event","args":{"choice":"skip" if harmful and policy.skip_harmful_events else "accept"}}
		"explore":
			var h:=E.hero(s,cfg)
			var limit:=10
			for row in policy.floor_limits:
				if h.level<row.below_level: limit=int(row.floor); break
			var threshold: float=policy.boss_min_hp_fraction if s.floor==9 else policy.return_hp_fraction
			var retreat: bool=s.floor>0 and (s.floor>=limit or float(h.hp)/h.max_hp<threshold)
			return {"action":"return" if retreat else "descend","args":{}}
	return {}
