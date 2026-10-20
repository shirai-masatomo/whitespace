extends RefCounted
## One committed action per step. Presentation and strategy changes never reset acted.
const T=preload("res://core/tactics.gd")
static func core() -> GDScript: return load("res://core/combat.gd")
static func start(allies: Array, enemies: Array, rules: Dictionary, seed_value: int, strategy: Dictionary) -> Dictionary:
	var c: GDScript=core(); var rng:=RandomNumberGenerator.new(); rng.seed=seed_value
	var s: Dictionary={"units":{},"allies":[],"enemies":[],"rules":rules.duplicate(true),"seed":seed_value,"rng_state":rng.state,"round":0,"acted":[],"outcome":"ongoing","log":[],"reward":{"exp":0,"gold":0},"strategy":strategy.duplicate(true),"squad":true}
	for team in ["allies","enemies"]:
		var roster: Array=allies if team=="allies" else enemies
		for i in roster.size():
			var id: String=roster[i].get("battle_id",("hero" if team=="allies" else "enemy") if i==0 else team+str(i))
			assert(not s.units.has(id))
			var unit: Dictionary=c.normalized(roster[i]); unit.battle_id=id; unit.team=team; unit.rank=roster[i].get("rank","front")
			s.units[id]=unit; s[id]=unit; s[team].append(id)
	sync(s); finish(s); return s
static func sync(s: Dictionary) -> void:
	for id in s.units: s[id]=s.units[id]
	if not s.allies.is_empty(): s.hero=s.units[s.allies[0]]
	if not s.enemies.is_empty(): s.enemy=s.units[s.enemies[0]]
static func living(s: Dictionary, team: String) -> Array:
	return s[team].filter(func(id):return int(s.units[id].hp)>0)
static func finish(s: Dictionary) -> void:
	if living(s,"allies").is_empty(): s.outcome="defeat"
	elif living(s,"enemies").is_empty():
		s.outcome="victory"; s.reward={"exp":0,"gold":0}
		for id in s.enemies:
			s.reward.exp+=int(s.units[id].get("exp",0)); s.reward.gold+=int(s.units[id].get("gold",0))
	elif s.round>=int(s.rules.max_rounds) and (living(s,"allies")+living(s,"enemies")).all(func(id):return id in s.acted): s.outcome="draw"
static func switch(s: Dictionary, strategy: Dictionary) -> bool:
	if s.outcome!="ongoing" or T.validate(strategy)!="": return false
	s.strategy=strategy.duplicate(true)
	s.log.append({"type":"strategy_changed","id":strategy.id,"name":strategy.name,"round":s.round,"acted":s.acted.duplicate()}); return true
static func candidates(s: Dictionary) -> Array:
	var remaining: Array=living(s,"allies").filter(func(id):return id not in s.acted)
	var order: Array=s.strategy.get("order",[]).duplicate()
	for id in remaining:
		if id not in order: order.append(id)
	var result: Array=living(s,"enemies").filter(func(id):return id not in s.acted)
	for id in order:
		if id in remaining: result.append(id); break
	return result
static func next_actor(s: Dictionary, rng: RandomNumberGenerator) -> String:
	var values: Array=candidates(s); var best: Array=[]; var speed: int=-1
	for id in values:
		var value: int=int(s.units[id].spd)
		if value>speed: best=[id]; speed=value
		elif value==speed: best.append(id)
	return "" if best.is_empty() else str(best[rng.randi_range(0,best.size()-1)] if best.size()>1 else best[0])
static func rank(s: Dictionary, id: String) -> String:
	return s.strategy.get("characters",{}).get(id,{}).get("rank",s.units[id].rank) if id in s.allies else str(s.units[id].rank)
static func targets(s: Dictionary, id: String, selector: String, range_name: String) -> Array:
	if range_name=="self": return [id] if selector=="self" else []
	if selector=="self": return []
	var other: String="enemies" if id in s.allies else "allies"
	var alive: Array=living(s,other)
	var has_front: bool=alive.any(func(key):return rank(s,key)=="front")
	var result: Array=[]
	for key in alive:
		var r: String=rank(s,key)
		if selector=="enemy_back" and r!="back": continue
		if selector=="enemy_front" and has_front and r!="front": continue
		if range_name=="front" and has_front and r!="front": continue
		result.append(key)
	return result
static func condition(s: Dictionary, actor: String, value: Dictionary) -> bool:
	var u: Dictionary=s.units[actor]
	match value.kind:
		"always": return true
		"hp_below": return float(u.hp)*100<=float(u.max_hp)*float(value.get("value",50))
		"sp_above": return float(u.sp)*100>=float(u.max_sp)*float(value.get("value",50))
		"poisoned": return u.statuses.has("poison")
		"enemy_telegraph": return living(s,"enemies" if actor in s.allies else "allies").any(func(id):return s.units[id].has("ai_pattern") and int(s.units[id].ai_phase)==2)
	return false
static func decide(s: Dictionary, actor: String) -> Dictionary:
	var u: Dictionary=s.units[actor]; var skipped: Array=[]
	var rows: Array=s.strategy.get("characters",{}).get(actor,{}).get("rows",[]) if actor in s.allies else []
	if actor in s.enemies:
		for id in u.skills:
			if id!="S105": rows.append({"skill":id,"conditions":[],"target":"enemy_front"})
	for i in rows.size():
		var row: Dictionary=rows[i]; var skill_id: String=row.skill; var why: String=""
		var skill: Dictionary=s.rules.get("skills",{}).get(skill_id,{})
		if not row.conditions.all(func(v):return condition(s,actor,v)): why="条件不成立"
		elif skill_id!="attack" and (skill_id not in u.skills or skill.is_empty()): why="未習得・未装備"
		elif skill_id!="attack" and int(u.sp)<int(skill.sp_cost): why="SP不足"
		elif skill_id!="attack" and int(u.action_count)<=int(u.skill_cooldowns.get(skill_id,0)): why="クールダウン中"
		elif skill_id=="S105" and (int(u.defense_until)>=0 or int(u.def)<=0): why="防御中または防御力なし"
		var range_name: String=s.rules.tactics_ranges.get(skill_id,"front")
		var available: Array=targets(s,actor,row.target,range_name)
		if why=="" and available.is_empty(): why="射程内に指定対象なし"
		if why!="": skipped.append("%d行目：%s"%[i+1,why]); continue
		return {"skill":skill_id,"target":available[0],"row":i,"skipped":skipped}
	var fallback: Array=targets(s,actor,"enemy_front",s.rules.tactics_ranges.get("attack","front"))
	return {"skill":"attack" if not fallback.is_empty() else "wait","target":fallback[0] if not fallback.is_empty() else "","row":-1,"skipped":skipped}
static func advance(previous: Dictionary) -> Dictionary:
	var s: Dictionary=previous.duplicate(true); sync(s)
	if s.outcome!="ongoing": return s
	var c: GDScript=core(); var rng:=RandomNumberGenerator.new(); rng.seed=int(s.seed); rng.state=int(s.rng_state)
	if candidates(s).is_empty(): s.acted=[]
	if s.acted.is_empty(): s.round+=1; s.log.append({"type":"round","round":s.round,"order":[]})
	var id: String=next_actor(s,rng)
	if id=="": finish(s); return s
	s.acted.append(id); var unit: Dictionary=s.units[id]; unit.action_count+=1
	s.log.append({"type":"opportunity","actor":id,"round":s.round})
	if c.start_opportunity(s,id):
		var decision: Dictionary=decide(s,id); var skill_id: String=decision.skill; var target_id: String=decision.target
		decision.label=s.rules.get("skills",{}).get(skill_id,{}).get("name","通常攻撃" if skill_id=="attack" else "待機")
		decision.target_name=s.units[target_id].name if target_id!="" else "なし"
		unit.last_decision=decision.duplicate(true)
		s.log.append({"type":"decision","actor":id,"round":s.round,"decision":decision.duplicate(true),"strategy":s.strategy.get("name","")})
		if skill_id!="wait":
			var skill: Dictionary=s.rules.get("skills",{}).get(skill_id,{})
			var move: Dictionary=c.boss_move(s,id,rng) if unit.has("ai_pattern") else {}
			if not move.get("skip",false):
				if unit.has("ai_pattern"): skill_id="attack"; skill={}
				if skill_id!="attack":
					unit.sp-=int(skill.sp_cost); unit.skill_cooldowns[skill_id]=unit.action_count+int(skill.cooldown_own_actions)
					s.log.append({"type":"skill","actor":id,"skill":skill_id,"sp":unit.sp,"round":s.round,"expires_after_action":unit.action_count+int(skill.get("duration_own_actions",0))})
				if skill_id=="S105": unit.defense_until=unit.action_count+int(skill.duration_own_actions)
				else:
					skill=skill.duplicate(true); skill.id=skill_id; strike(s,id,target_id,skill,move,rng)
	else:
		unit.last_decision={"label":"行動不能" if unit.hp>0 else "死亡","target_name":"なし","skipped":["状態により通常行動なし"]}
	c.finish_action(s,id); finish(s)
	if s.outcome!="ongoing":
		for key in s.units: c.clear_statuses(s,key,"battle_end")
	s.rng_state=rng.state; sync(s); return s
static func strike(s: Dictionary, actor: String, target_id: String, skill: Dictionary, move: Dictionary, rng: RandomNumberGenerator) -> void:
	var c: GDScript=core(); var unit: Dictionary=s.units[actor]; var target: Dictionary=s.units[target_id]
	var hit: bool=rng.randf()<clampf(float(s.rules.hit_chance)-float(unit.statuses.get("blind",{}).get("potency",0)),0,1)
	var critical: bool=false; var amount: int=0
	if hit:
		critical=rng.randf()<float(s.rules.critical_chance)
		amount=c.damage(unit.atk,c.effective_def(target,s.rules),rng.randf_range(s.rules.variance_min,s.rules.variance_max),float(s.rules.critical_multiplier) if critical else 1.0,float(move.get("multiplier",skill.get("damage_multiplier",1.0))))
		target.hp=maxi(0,int(target.hp)-amount)
	s.log.append({"type":"attack","actor":actor,"target":target_id,"round":s.round,"hit":hit,"critical":critical,"damage":amount,"target_hp":target.hp,"death":target.hp==0})
	if target.hp==0: c.clear_statuses(s,target_id,"death")
	elif hit and skill.has("status_id") and rng.randf()<float(skill.get("apply_chance",0)): c.apply_status(s,actor,target_id,str(skill.get("id","")))
