extends RefCounted
## Shared character identity for inspection/equipment. No joining or growth content.
static func api() -> GDScript: return load("res://core/expedition.gd")
static func ids(s: Dictionary) -> Array:
	return ["hero"]+s.get("companions",{}).keys()
static func exists(s: Dictionary, id: String) -> bool:
	return id in ids(s)
static func gear(s: Dictionary, id: String="hero") -> Dictionary:
	return s.equipment if id=="hero" else s.get("companions",{}).get(id,{}).get("equipment",{})
static func name_of(s: Dictionary, id: String) -> String:
	return "主人公" if id=="hero" else str(s.companions[id].name)
static func actor(s: Dictionary, cfg: Dictionary, id: String="hero", battle: Dictionary={}) -> Dictionary:
	if not exists(s,id): id="hero"
	if not battle.is_empty():
		if id=="hero": return battle.hero
		if battle.get("units",{}).has(id): return battle.units[id]
	if id=="hero": return api().hero(s,cfg)
	var member: Dictionary=s.companions[id]
	var u: Dictionary=member.base.duplicate(true);u.name=member.name;u.level=member.level;u.hp=member.hp;u.sp=member.sp;u.skills=member.get("skills",[]).duplicate();u.statuses={};u.action_count=0;u.defense_until=-1
	for uid in member.equipment.values():
		if uid!="":
			for key in api().Condition.stats(s,uid,cfg):u[key]=int(u.get(key,0))+int(api().Condition.stats(s,uid,cfg)[key])
	u.max_hp=maxi(1,int(u.max_hp));u.max_sp=maxi(0,int(u.max_sp));u.atk=maxi(1,int(u.atk));u.def=maxi(0,int(u.def));u.spd=maxi(1,int(u.spd));u.hp=mini(int(u.hp),int(u.max_hp));u.sp=mini(int(u.sp),int(u.max_sp));return u
static func all_equipped(s: Dictionary) -> Array:
	var result: Array=[]
	for id in ids(s):
		for uid in gear(s,id).values():
			if uid!="":result.append(uid)
	return result
static func clamp_member(s: Dictionary, cfg: Dictionary, id: String) -> void:
	if id=="hero":return
	var u: Dictionary=actor(s,cfg,id);s.companions[id].hp=u.hp;s.companions[id].sp=u.sp
static func add_dummy(s: Dictionary, id: String, name: String, base: Dictionary) -> void:
	assert(id!="hero" and not exists(s,id))
	s.verification_party=true
	if not s.has("companions"):s.companions={}
	var equipment: Dictionary={}
	for slot in api().SLOTS:equipment[slot]=""
	s.companions[id]={"name":name,"verification_dummy":true,"base":base.duplicate(true),"level":1,"hp":int(base.max_hp),"sp":int(base.max_sp),"skills":[],"equipment":equipment}
