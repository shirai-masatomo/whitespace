extends RefCounted
## One bounded acceptance route, not an autoplay feature in the shipped game.
const E=preload("res://core/expedition.gd")
static func score(s: Dictionary, cfg: Dictionary, uid: String) -> float:
	if uid=="": return 0.0
	var item: Dictionary=cfg.items[s.items[uid]]
	var value:=0.0
	for key in item.stats: value+=E.Condition.bonus(s,uid,int(item.stats[key]))*{"atk":3.0,"def":2.0,"spd":1.0,"max_hp":0.25,"max_sp":0.5}[key]
	return value
static func choose(s: Dictionary, cfg: Dictionary) -> Dictionary:
	if s.phase in ["town","explore","reward"]:
		for uid in s.inventory:
			var item: Dictionary=cfg.items[s.items[uid]]
			if item.slot!="" and score(s,cfg,uid)>score(s,cfg,s.equipment[item.slot])+0.001: return {"action":"equip","args":{"uid":uid}}
	match s.phase:
		"town":
			for uid in s.equipment.values():
				if uid!="" and s.item_condition[uid].current<94 and s.gold>=E.Condition.cost(s,uid,cfg): return {"action":"repair","args":{"uid":uid}}
			if not s.inventory.is_empty(): return {"action":"deposit","args":{"uid":s.inventory[0]}}
			return {"action":"depart","args":{}}
		"battle": return {"action":"round","args":{}}
		"treasure": return {"action":"open_chest","args":{}}
		"reward":
			if s.pending_rewards.is_empty(): return {"action":"continue_rewards","args":{}}
			if s.inventory.size()<15: return {"action":"claim_reward","args":{"token":s.pending_rewards[0].token}}
			return {"action":"abandon_rewards","args":{"confirmed":true}}
		"event": return {"action":"journey_event","args":{"choice":cfg.journey.events[s.event].choices[0].id}}
		"event_result": return {"action":"continue_event","args":{}}
		"result": return {"action":"town","args":{}}
		"explore":
			var h: Dictionary=E.hero(s,cfg)
			var limit: int=4 if h.level<3 else (8 if h.level<5 else 10)
			var threshold: float=0.82 if s.floor==9 else 0.48
			return {"action":"return" if s.floor>0 and (s.floor>=limit or float(h.hp)/h.max_hp<threshold) else "descend","args":{}}
	return {}
