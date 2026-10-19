extends RefCounted
## Data for the playable route. No combat math, UI dependencies or new companion features.
static func load_data() -> Dictionary:
	var value=JSON.parse_string(FileAccess.get_file_as_string("res://data/v1/journey.json"))
	return value if value is Dictionary else {}
static func enable(s: Dictionary) -> void:
	s.journey_version=1; s.pending_rewards=[]; s.reward_serial=0; s.reward_return="explore"; s.reward_origin=""; s.event_result={}; s.trip_exp=0; s.trip_gold=0; s.trip_items=0
static func active(s: Dictionary) -> bool: return s.get("journey_version",0)==1
static func node(cfg: Dictionary, floor_number: int) -> Dictionary:
	for row in cfg.get("journey",{}).get("nodes",[]):
		if int(row.floor)==floor_number: return row
	return {}
static func add_reward(s: Dictionary, id: String) -> void:
	s.reward_serial+=1
	s.pending_rewards.append({"id":id,"token":"reward-%d"%s.reward_serial,"quantity":1})
static func reward_index(s: Dictionary, token: String) -> int:
	for i in s.get("pending_rewards",[]).size():
		if s.pending_rewards[i].token==token: return i
	return -1
static func eligible(s: Dictionary, event: Dictionary, cfg: Dictionary) -> bool:
	if int(s.floor)<int(event.get("min_floor",1)) or int(s.floor)>int(event.get("max_floor",1000)): return false
	var required: String=event.get("requires_item","")
	if required!="":
		for uid in s.inventory:
			if s.items[uid]==required: return true
		return false
	return true
static func validate_definition(value: Dictionary, data: Dictionary, cfg: Dictionary) -> String:
	if value.get("version")!=1 or not value.get("nodes") is Array or not value.get("events") is Dictionary: return "Invalid journey definition"
	var maximum: int=int(value.get("public_max_floor",0))
	if maximum<1 or maximum>100: return "Invalid journey limit"
	var ids: Array=[]; var floors: Array=[]
	for n in value.nodes:
		if not n is Dictionary or not n.has_all(["id","floor","kind","background","bgm"]): return "Invalid node"
		if n.id in ids or n.floor in floors or not n.kind in ["enemy","boss","treasure","event"]: return "Duplicate or invalid node"
		ids.append(n.id); floors.append(n.floor)
		if not n.background in ["cavern","boss"]: return "Unknown background key"
		if n.bgm!="" and not ResourceLoader.exists(n.bgm): return "Missing node BGM"
		if n.kind in ["enemy","boss"]:
			if not n.get("enemies") is Dictionary or n.enemies.is_empty() or not n.get("levels") is Array or n.levels.size()!=2 or n.levels[0]<1 or n.levels[1]<n.levels[0]: return "Invalid enemy node"
			for id in n.enemies:
				if not data.enemies.has(id) or n.enemies[id]<=0: return "Unknown node enemy"
		elif n.kind=="treasure":
			if not n.get("rewards") is Dictionary or n.rewards.is_empty(): return "Empty treasure"
			for id in n.rewards:
				if not cfg.items.has(id) or n.rewards[id]<=0: return "Unknown reward"
		else:
			if not n.get("events") is Array or n.events.is_empty(): return "Empty events"
			for id in n.events:
				if not value.events.has(id) or not cfg.events.has(id) or id=="EV03": return "Unknown event"
	for n in range(1,maximum+1):
		if not n in floors: return "Missing floor"
	for id in value.events:
		var event: Dictionary=value.events[id]
		if not event.get("description") is String or not event.get("choices") is Array or event.choices.is_empty(): return "Invalid event text/choices"
		for choice in event.choices:
			if not choice.has_all(["id","label","effect","result"]) or not choice.effect in ["hp","exp","item","none"]: return "Invalid event choice"
			if choice.effect=="item" and not cfg.items.has(choice.get("item","")): return "Unknown event reward"
	return ""
