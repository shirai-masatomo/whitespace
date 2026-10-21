extends RefCounted
## Generated once; every ownership path carries this immutable profile.
static func roll(s: Dictionary, id: String, origin: String="loot") -> Dictionary:
	var item: Dictionary=s.item_rules[id]
	var base: Dictionary=item.stats.duplicate(true)
	var supply: bool=item.get("supply",false)
	var affix: Dictionary={"id":"plain","stats":{}}
	if item.slot!="" and not supply:
		var total: int=0
		for candidate in s.affix_rules: total+=int(candidate.weight)
		var value: int=draw(s,total)
		for candidate in s.affix_rules:
			value-=int(candidate.weight)
			if value<0: affix=candidate; break
	return {"base_roll":base,"affix_id":affix.id,"affix_stats":affix.stats.duplicate(true),"seals":[],"seal_slots":int(item.get("seal_slots",0)),"origin":origin,"supply":supply,"special_effects":[],"granted_skills":[],"rarity":{"status":"unrated","label":"未評価"}}
static func draw(s: Dictionary, maximum: int) -> int:
	var rng:=RandomNumberGenerator.new(); rng.seed=(int(s.seed)+int(s.rng.instance)*1103515245+907)%2147483647
	s.rng.instance+=1; return rng.randi_range(0,maximum-1)
static func install(s: Dictionary, id: String, profile: Dictionary, source: String="inventory", quantity: int=1) -> String:
	var uid: String="item-%d"%int(s.next_item); s.next_item+=1
	s.items[uid]=id; s.item_condition[uid]={"current":100,"maximum":100}; s.item_details[uid]=profile.duplicate(true); s.quantities[uid]=quantity; s[source].append(uid); return uid
static func erase(s: Dictionary, uid: String) -> void:
	for source in ["inventory","cloth","warehouse"]: s[source].erase(uid)
	for slot in s.equipment:
		if s.equipment[slot]==uid: s.equipment[slot]=""
	for member in s.get("companions",{}).values():
		for slot in member.equipment:
			if member.equipment[slot]==uid:member.equipment[slot]=""
	if s.has("warehouse_positions"):s.warehouse_positions.erase(uid)
	for key in ["items","item_condition","item_details","quantities"]: s[key].erase(uid)
static func base(s: Dictionary, uid: String) -> Dictionary:
	var value: Dictionary=s.item_details[uid].base_roll.duplicate(true)
	for key in s.item_details[uid].affix_stats: value[key]=int(value.get(key,0))+int(s.item_details[uid].affix_stats[key])
	return value

static func evaluation_inputs(profile: Dictionary) -> Dictionary:
	return {"status":"unrated","additional_stats":profile.get("affix_stats",{}).duplicate(true),"special_effects":profile.get("special_effects",[]).duplicate(true),"granted_skills":profile.get("granted_skills",[]).duplicate(true),"seals":profile.get("seals",[]).duplicate(true)}
