extends RefCounted
const Data=preload("res://game/progression_data.gd")
const Encounters=preload("res://game/encounters.gd")

static func migrate(w):
	w.campaign.enemy_knowledge=w.campaign.get("enemy_knowledge",{})
	w.campaign.encounter_counts=w.campaign.get("encounter_counts",{})
	w.campaign.animal_history=w.campaign.get("animal_history",[])
	w.campaign.next_animal_id=w.campaign.get("next_animal_id",1)
	for a in w.campaign.animals:
		w.campaign.next_animal_id=maxi(w.campaign.next_animal_id,a.id+1)
		a.rarity=Data.rarity(a.get("rarity",0)); a.bonus_skills=a.get("bonus_skills",[])
		a.equipment=a.get("equipment",{}); a.faction=a.get("faction","owned")
		if a.get("hp",1)<=0 and w.SPECIES[a.species].mortal: a.dead=true
	for a in w.campaign.animals.duplicate():
		if a.get("dead",false):
			w.campaign.animal_history.append(a.duplicate(true)); w.campaign.animals.erase(a)

static func loyalty(a: Dictionary) -> float:
	return clampf(a.loyalty+equipment_effect(a,"loyalty")-a.get("loyalty_loss",0.0),0,100)

static func equipment_effect(a: Dictionary, effect: String) -> int:
	return Data.ITEMS.get(a.get("equipment",{}).get("item_id",""),{}).get("effects",{}).get(effect,0)

static func defense(a: Dictionary, tick: int) -> int:
	return a.get("defense",0)+equipment_effect(a,"defense")+(Data.SPECIAL.spines_defense if tick<a.get("spines_until",0) else 0)

static func can_equip(a: Dictionary, id: String) -> bool:
	if a.is_empty() or a.get("dead",false) or a.get("lost",false) or a.get("faction","owned")!="owned" or a.get("hp",1)<=0: return false
	if id=="unequip": return not a.get("equipment",{}).is_empty()
	if not Data.ITEMS.has(id): return false
	var tags=Data.ITEMS[id].equip_targets
	return "animal" in tags or a.get("category","") in tags or a.species in tags

static func equip_job(w, animal_id: int, item_id: String) -> bool:
	var a=w.Orders.animal(w,animal_id)
	if not w.working() or w.jobs.size()>=8 or not can_equip(a,item_id): return false
	if w.jobs.any(func(j):return j.kind=="equip" and j.animal_id==animal_id): w.say("装備は予約済みです"); return false
	var reserved=w.jobs.filter(func(j):return j.kind=="equip" and j.get("item_id")==item_id).size()
	if item_id!="unequip" and w.item_count(item_id)<=reserved: w.say("使える装備がありません"); return false
	if w.jobs.is_empty() and w.manual_goal==null and w.Life.able(w) and w.job_hold_reason in ["travel","manual","rescue","danger","rest_end"]: w.Jobs.hold(w,"")
	w.jobs.append({"id":w.next_job_id,"kind":"equip","animal_id":animal_id,"item_id":item_id,"expected_equipment":a.equipment.duplicate(true),"pos":a.pos,"state":"pending","started":false,"reserved":0,"resource":""})
	w.next_job_id+=1; w.Life.wake_auto(w)
	w.job_log.append({"tick":w.tick,"event":"equip_queued","animal_id":animal_id,"item":item_id})
	return true

static func equip_step(w,j):
	var a=w.Orders.animal(w,j.animal_id)
	if not can_equip(a,j.item_id) or a.get("equipment",{})!=j.expected_equipment or (j.item_id!="unequip" and w.item_count(j.item_id)<1): w.Jobs.complete(w,j,false); return
	if not w.Orders.active(w,a): j.state="blocked"; j.block_reason="療養中です"; return
	j.pos=a.pos
	if not w.Jobs.walk(w,j,w.neighbors(a.pos)): return
	if not a.equipment.is_empty(): w.add_item(a.equipment.item_id,1)
	a.equipment={}
	if j.item_id!="unequip":
		w.add_item(j.item_id,-1)
		a.equipment={"item_id":j.item_id,"durability":Data.ITEMS[j.item_id].durability}
	sync_owned(w,a)
	w.job_log.append({"tick":w.tick,"event":"equipped","animal_id":a.id,"item":j.item_id,"distance":w.distance(w.keeper.pos,a.pos)})
	w.Jobs.complete(w,j,true)

static func sync_owned(w,a):
	for owned in w.campaign.animals:
		if owned.id==a.id:
			for key in ["hp","equipment","rarity","bonus_skills"]: owned[key]=a.get(key)

static func remove_animal(w,a,reason: String):
	if a.get("dead",false) or a.get("lost",false): return
	a["dead" if reason=="death" else "lost"]=true
	a.placed=false; a.state="死亡" if reason=="death" else "連れ去られた"
	a.erase("abductor"); a.erase("guide_job"); a.pending={}; a.rescuing=false
	var record={"id":a.id,"species":a.species,"name":a.get("name",""),"day":w.campaign.day,"reason":reason,"equipment":a.equipment.duplicate(true)}
	w.campaign.animal_history.append(record)
	w.campaign.animals=w.campaign.animals.filter(func(row):return row.id!=a.id)
	# Lost/dead equipment stays in the history; it is not duplicated into inventory.
	a.equipment={}
	w.say(w.animal_name(a)+("を失いました" if reason=="death" else "が連れ去られました"))
	w.milestones.append({"tick":w.tick,"kind":reason,"animal_id":a.id})

static func animal_hurt(w,a,e,raw: int,nonlethal: bool=false):
	if a.hp<=0 or a.get("dead",false) or a.get("lost",false): return
	var damage=maxi(0,raw-defense(a,w.tick))
	if nonlethal: damage=mini(damage,maxi(0,a.hp-1))
	a.hp=maxi(0,a.hp-damage)
	w.Combat.hit(w,e,a,e.get("combat_action","attack"),damage,e.get("combat_skill",false))
	w.combat_log.append({"tick":w.tick,"source":"enemy","id":e.id,"target":a.id,"damage":damage})
	if a.hp<=a.max_hp*0.25: w.Life.danger(w,"animal_danger")
	if a.hp<=0:
		if w.SPECIES[a.species].mortal: remove_animal(w,a,"death")
		else:
			a.state="気絶"; a.unavailable_through_day=maxi(a.unavailable_through_day,w.campaign.day+1); a.rescuing=false
		return
	w.share_detection(a,e.id,5.0)
	if a.species=="hedgehog": a.spines_until=w.tick+ceili(Data.SPECIAL.spines_duration/w.DT)
	if a.species=="bullfrog":
		for ally in w.animals:
			if ally.placed and ally.hp>0 and w.distance(ally.pos,a.pos)<=Data.SPECIAL.croak_range: w.share_detection(ally,e.id,5.0)
		w.skill_log.append({"tick":w.tick,"actor":a.id,"skill":"croak","enemy":e.id})
	if a.equipment.get("item_id")=="berry" and a.hp<=a.max_hp*0.5:
		a.equipment={}; a.hp=mini(a.max_hp,a.hp+maxi(1,floori(a.max_hp*0.25)))
		w.skill_log.append({"tick":w.tick,"actor":a.id,"skill":"berry"})
	sync_owned(w,a)

static func enemy_hurt(w,e,raw: int,attacker: int=-1,action: String="attack",skill: bool=false):
	if e.done or e.flee or e.hp<=0: return
	var damage=maxi(0,raw-e.get("defense",0)); e.hp=maxi(0,e.hp-damage)
	var source=w.Orders.animal(w,attacker) if attacker>=0 else w.keeper
	w.Combat.hit(w,source,e,action,damage,skill)
	if attacker>=0: e.attacker=attacker; e.threat_until=w.tick+ceili(w.Rules.KIDNAPPER.counter_duration/w.DT)
	if e.hp<=0:
		e.flee=true; release_animal(w,e); w.release_keeper(e); loot(w,e); knowledge(w,e,3)
		if e.get("type_tag","")=="Animal": e.done=true; e.state="死亡"; e.action_id="death"; w.metrics.repelled+=1
	elif e.get("archetype","")=="salaryman" and not e.get("phone_success",false) and not e.get("phone_started",false) and damage>0:
		if w.rng.randf()<Data.SPECIAL.phone_chance and w.Combat.pay(e,"skill"):
			e.phone_started=true; e.phone_until=w.tick+ceili(Data.SPECIAL.phone_delay/w.DT); e.action_id="phone_take"

static func loot(w,e):
	if e.get("loot_granted",false): return
	e.loot_granted=true
	if e.get("loot_table","")=="small_gold": w.metrics.coins+=w.rng.randi_range(2,5)
	if e.get("loot_table","")=="scroll":
		var id="scroll-%d-%d"%[w.campaign.day,e.id]
		w.field_items.append({"id":id,"kind":"skill_scroll","skill_id":"hardy","rarity":Data.Rarity.UNCOMMON,"pos":e.pos,"born_day":w.campaign.day})

static func knowledge(w,e,level: int):
	var id=e.get("archetype","kidnapper")
	w.campaign.enemy_knowledge[id]=maxi(w.campaign.enemy_knowledge.get(id,0),level)

static func visible_to_farm(w,e) -> bool:
	if w.distance(w.keeper.pos,e.pos)<=6 and w.line_of_sight(w.keeper.pos,e.pos): return true
	return w.animals.any(func(a):return a.placed and a.hp>0 and w.distance(a.pos,e.pos)<=a.detection_range and w.line_of_sight(a.pos,e.pos))

static func release_animal(w,e):
	var id=e.get("led_animal",-1)
	if id<0: return
	var a=w.Orders.animal(w,id)
	if not a.is_empty(): a.erase("abductor"); a.home=a.pos; a.order=a.pos; a.state="解放された"
	e.led_animal=-1

static func tick(w):
	for a in w.animals:
		a.loyalty_loss=maxf(0,a.get("loyalty_loss",0.0)-Data.SPECIAL.tame_recovery*w.DT)
		if a.hp<=0 and w.SPECIES[a.species].mortal: remove_animal(w,a,"death")
		if a.get("abductor",-1)>=0:
			var holder=w.enemies.filter(func(e):return e.id==a.abductor and not e.done and not e.flee and e.hp>0)
			if holder.is_empty(): a.erase("abductor"); a.home=a.pos; a.order=a.pos
		if a.placed and a.hp>0 and w.tick<a.get("spines_until",0):
			for e in w.enemies:
				if not e.done and not e.flee and w.distance(a.pos,e.pos)<=1 and w.line_of_sight(a.pos,e.pos) and e.get("reflected_at",-1)!=w.tick:
					e.reflected_at=w.tick; enemy_hurt(w,e,Data.SPECIAL.spines_reflect,a.id,"spines",true)
	for e in w.enemies:
		if e.hp<=0 and not e.get("loot_granted",false): loot(w,e); release_animal(w,e)
		if not e.done and visible_to_farm(w,e):
			knowledge(w,e,2 if e.get("observed_action",false) else 1)
		e.observed_action=false

static func spawn_data(w,e,event):
	var id=event.get("archetype",event.role)
	if not Data.ENEMY_ROWS.has(id) and id!="doberman": id="kidnapper"
	var row=Data.enemy(id,event.get("lv",1))
	if id=="doberman":
		var animal=w.SPECIES.doberman
		row.merge({"species":"doberman","type_tag":"Animal","name":"ドーベルマン","max_hp":animal.hp,"move_speed":animal.move_speed,"sight_range":animal.detection_range,"human_attack":animal.attack,"animal_attack":animal.attack,"object_attack_power":animal.object_attack,"skills":animal.skills.duplicate(),"attack_interval":animal.attack_seconds,"target_weights":{"keeper":45,"animal":55,"structure":0,"idol":0}},true)
	e.merge(row,true)
	w.Combat.init_actor(e,e.type_tag=="Human")
	e.hp=e.max_hp; e.attack_power=e.human_attack; e.counter_seconds=e.attack_interval; e.faction="enemy"
	e.move_speed=event.get("move_speed",e.move_speed); e.sight_range=event.get("sight_range",e.sight_range)
	e.action_id="idle"; e.led_animal=-1
	w.campaign.encounter_counts[id]=w.campaign.encounter_counts.get(id,0)+1
	if id=="runner" and w.rng.randf()<Data.SPECIAL.companion_chance:
		w.spawn_schedule.append({"tick":w.tick-w.night_started_tick+4,"wave":999,"role":"doberman","entry":event.entry,"lv":1,"companion_of":e.id})
		w.spawn_schedule.sort_custom(func(a,b):return a.tick<b.tick)

static func target_candidates(w,e) -> Array:
	var candidates=[]
	if e.can_see_keeper and w.keeper.hp>0: candidates.append({"kind":"keeper","id":-1,"pos":w.keeper.pos})
	for a in w.animals:
		if a.placed and a.hp>0 and not a.get("dead",false) and w.distance(e.pos,a.pos)<=e.sight_range and w.line_of_sight(e.pos,a.pos): candidates.append({"kind":"animal","id":a.id,"pos":a.pos})
	for p in w.structures:
		if w.live_structure(p) and w.distance(e.pos,p)<=e.sight_range and w.line_of_sight(e.pos,p,true): candidates.append({"kind":"structure","id":w.structures[p].id,"pos":p})
	for p in w.Story.idol_cells(w):
		if w.distance(e.pos,p)<=e.sight_range and w.line_of_sight(e.pos,p,true): candidates.append({"kind":"idol","id":-1,"pos":p}); break
	return candidates.filter(func(t):return e.target_weights.get(t.kind,0)>0 and not (e.archetype=="martial_artist" and ((t.kind=="keeper" and w.keeper.hp<=1) or (t.kind=="animal" and w.Orders.animal(w,t.id).hp<=1))))

static func select_target(w,e,candidates: Array) -> Dictionary:
	if candidates.is_empty(): return {}
	# Normalize categories first so a farm with many walls does not multiply its category weight.
	var groups={}
	for t in candidates:
		if not groups.has(t.kind): groups[t.kind]=[]
		groups[t.kind].append(t)
	var kinds=groups.keys()
	var kind=kinds[Data.weighted(w.rng,kinds.map(func(k):return e.target_weights[k]))]
	var rows=groups[kind]
	rows.sort_custom(func(a,b):return w.distance(e.pos,a.pos)<w.distance(e.pos,b.pos) if w.distance(e.pos,a.pos)!=w.distance(e.pos,b.pos) else a.id<b.id)
	return rows[0] if w.rng.randf()*100<e.ai_accuracy else rows[w.rng.randi_range(0,rows.size()-1)]

static func enemy_step(w,e) -> bool:
	if e.flee: return false
	var kidnapper=e.get("archetype","kidnapper")=="kidnapper"
	if kidnapper and (e.carry!="" or w.keeper.hp<=0 or e.role!="kidnapper"): return false
	if e.hp<=0: e.flee=true; return false
	if e.get("phone_started",false):
		e.state="応援を呼ぶ"; e.action_id="phone_call"
		if w.tick>=e.phone_until:
			e.phone_started=false; e.phone_success=true; e.action_id="phone_put"; e.observed_action=true
			var calls=w.enemies.filter(func(n):return n.get("phone_success",false)).size()
			if calls<=Data.SPECIAL.night_reinforcement_cap:
				w.spawn_schedule.append({"tick":w.tick-w.night_started_tick+ceili(Data.SPECIAL.reinforcement_delay/w.DT),"wave":999,"role":"salaryman","entry":w.entries[w.rng.randi_range(0,w.entries.size()-1)],"lv":1})
				w.spawn_schedule.sort_custom(func(a,b):return a.tick<b.tick)
		return true
	if e.archetype=="animal_tamer" and e.led_animal>=0: lead_out(w,e); return true
	if w.tick<e.get("bow_until",0): e.state="礼"; e.action_id="bow"; return true
	var candidates=target_candidates(w,e)
	if w.tick<e.threat_until:
		var attacker=w.Orders.animal(w,e.attacker)
		if not attacker.is_empty() and attacker.placed and attacker.hp>0 and w.distance(e.pos,attacker.pos)<=1 and w.line_of_sight(e.pos,attacker.pos):
			if e.archetype!="martial_artist": candidates=[{"kind":"animal","id":attacker.id,"pos":attacker.pos}]
	var target=e.get("chosen_target",{})
	var current=candidates.filter(func(t):return t.kind==target.get("kind") and t.id==target.get("id"))
	if current.is_empty() or w.tick>=e.get("choose_at",0):
		target=select_target(w,e,candidates); e.chosen_target=target
		e.choose_at=w.tick+ceili((0.5+(100-e.ai_accuracy)*0.025)/w.DT)
	else: target=current[0]; e.chosen_target=target
	if kidnapper and (target.is_empty() or target.kind=="keeper"): return false
	if target.is_empty():
		e.action_id="walk"; walk(w,e,w.RaiderAI.target(e,w)); return true
	if w.tick<e.get("hesitate_until",0): e.state="様子見"; return true
	if e.archetype=="martial_artist" and e.get("bow_target","")!=str(target.kind)+str(target.id):
		e.bow_target=str(target.kind)+str(target.id); e.bow_until=w.tick+ceili(Data.SPECIAL.bow_seconds/w.DT); e.action_id="bow"; e.observed_action=true; return true
	if e.archetype=="animal_tamer" and target.kind=="animal" and tame(w,e,w.Orders.animal(w,target.id)): return true
	var dist=w.distance(e.pos,target.pos)
	if e.archetype=="ninja" and target.kind in ["keeper","animal"] and dist>1 and dist<=Data.SPECIAL.shuriken_range and w.line_of_sight(e.pos,target.pos) and w.tick>=e.get("shuriken_at",0) and w.Combat.pay(e,"skill"):
		e.shuriken_at=w.tick+ceili(Data.SPECIAL.shuriken_ct/w.DT); e.action_id="shuriken"; e.state="手裏剣"; strike(w,e,target,Data.SPECIAL.shuriken_damage); return true
	if dist<=1 and w.line_of_sight(e.pos,target.pos,target.kind in ["structure","idol"]):
		e.state="攻撃"; e.action_id="dagger" if e.archetype=="ninja" else ("iron_ball_hit" if e.archetype=="destroyer" else "attack")
		if w.tick>=e.next_attack and w.Combat.pay(e,"attack"):
			e.next_attack=w.tick+ceili(e.attack_interval/w.DT); strike(w,e,target)
		return true
	e.action_id="walk"; e.state="接近"; walk(w,e,target.pos)
	return true

static func walk(w,e,goal: Vector2i):
	var speed=e.move_speed
	if e.archetype=="runner":
		if w.tick-e.get("last_run_tick",w.tick)>maxi(4,ceili(1.0/speed/w.DT)+2): e.run_seconds=0.0
		if w.tick<e.get("tired_until",0): speed=Data.SPECIAL.runner_tired_speed; e.action_id="tired"; e.state="バテる"
		elif e.get("run_seconds",0.0)>=Data.SPECIAL.runner_run:
			e.tired_until=w.tick+ceili(Data.SPECIAL.runner_tired/w.DT); e.run_seconds=0.0; e.observed_action=true; return
		else: e.action_id="run"
	e.move_credit=minf(1.9,e.move_credit+speed*w.DT)
	if e.move_credit<1: return
	e.move_credit-=1
	var route=w.find_path(e.pos,goal,true,false,e.species=="doberman")
	if e.object_attack_power==0 and w.inside(goal):
		var detour=w.find_path(e.pos,goal,false,false,e.species=="doberman")
		if not detour.is_empty(): route=detour
	var next=route[1] if route.size()>1 else e.pos
	if e.species=="doberman" and w.is_indoor(next): e.state="外で待つ"; return
	if w.blocks(next) and e.object_attack_power==0:
		e.search_goal=null; e.chosen_target={}; e.state="道を探す"; return
	var before=e.pos
	w.move_enemy(e,next)
	if e.archetype=="runner" and before!=e.pos: e.run_seconds=e.get("run_seconds",0.0)+1.0/speed; e.last_run_tick=w.tick

static func strike(w,e,t,override_damage: int=-1):
	e.observed_action=true
	e.combat_action="shuriken" if override_damage>=0 else "attack"
	e.combat_skill=override_damage>=0
	if t.kind=="keeper":
		var damage=e.human_attack if override_damage<0 else override_damage
		if e.archetype=="martial_artist": damage=mini(damage,maxi(0,w.keeper.hp-1))
		damage=roundi(damage*(0.85 if w.tick<e.weakened_until else 1.0))
		var hit=e.duplicate(); hit.attack_power=damage; w.Life.hurt(w,hit)
		if e.archetype=="martial_artist" and w.keeper.hp<=1: bow_end(w,e)
	elif t.kind=="animal":
		var a=w.Orders.animal(w,t.id)
		if a.is_empty(): return
		animal_hurt(w,a,e,roundi((e.animal_attack if override_damage<0 else override_damage)*(0.85 if w.tick<e.weakened_until else 1.0)),e.archetype=="martial_artist")
		if e.archetype=="martial_artist" and a.hp<=1: bow_end(w,e)
	elif t.kind=="structure":
		var b=w.structures.get(t.pos,{})
		if b.is_empty() or b.status!="ready": return
		var damage=maxi(0,e.object_attack_power-b.armor); b.hp=maxi(0,b.hp-damage); w.metrics.structure_damage+=damage
		w.combat_log.append({"tick":w.tick,"source":"object","id":e.id,"target":b.id,"damage":damage})
		if b.hp<=0: b.status="destroyed"; w.metrics.destroyed+=1; w.refresh_indoor()
	elif t.kind=="idol":
		w.story.idol.hp=maxi(0,w.story.idol.hp-e.object_attack_power)
		if w.story.idol.hp<=0: w.story.defeat_reason="idol_destroyed"; w.finish(false)

static func bow_end(w,e):
	e.bow_until=w.tick+ceili(Data.SPECIAL.bow_seconds/w.DT); e.action_id="bow"; e.state="礼"; e.chosen_target={}

static func tame(w,e,a) -> bool:
	if a.is_empty() or w.distance(e.pos,a.pos)>Data.SPECIAL.tame_range or not w.line_of_sight(e.pos,a.pos): return false
	e.state="呼びかける"; e.action_id="tame"
	if w.tick>=e.get("tame_at",0) and w.Combat.pay(e,"skill"):
		e.tame_at=w.tick+ceili(Data.SPECIAL.tame_ct/w.DT)
		a.loyalty_loss=a.get("loyalty_loss",0.0)+Data.SPECIAL.tame_loss*(Data.SPECIAL.shiba_resistance if a.species=="shiba" else 1.0); e.observed_action=true
	if loyalty(a)<=Data.SPECIAL.tame_threshold:
		if w.distance(e.pos,a.pos)>1: walk(w,e,a.pos)
		elif a.get("abductor",-1)<0:
			for j in w.jobs.duplicate():
				if j.kind=="animal_order" and j.targets.any(func(t):return t.id==a.id): w.Orders.stop(w,j); w.Jobs.complete(w,j,false)
			a.abductor=e.id; e.led_animal=a.id; w.Life.danger(w,"animal_abduction")
	return true

static func lead_out(w,e):
	var a=w.Orders.animal(w,e.led_animal)
	if a.is_empty() or a.hp<=0 or a.get("dead",false): release_animal(w,e); return
	e.state="動物を連れ帰る"; e.action_id="lead"; a.state="連れていかれる"
	var goal=w.Story.exit_goal(w,e)
	if not w.inside(e.pos) and w.distance(a.pos,e.pos)>1:
		a.move_credit=minf(1.9,a.move_credit+a.move_speed*w.DT)
		var edges=w.neighbors(e.pos).filter(func(p):return w.animal_walkable(a,p) and not w.actor_occupied(p,a.pos))
		if a.move_credit>=1 and not edges.is_empty():
			var next=w.animal_next(a,edges[0])
			if next!=a.pos and not w.actor_occupied(next,a.pos): a.move_credit-=1; w.open_for_ally(next); a.pos=next
		return
	if not w.inside(e.pos):
		if w.distance(a.pos,e.pos)<=1:
			if a.move_credit<1: a.move_credit+=a.move_speed*w.DT; return
			# Both actors cross separately; they never share a live cell.
			var outer=e.pos+(e.pos-goal if e.pos!=goal else (e.pos-e.entry))
			e.pos=outer; a.pos=goal; remove_animal(w,a,"abducted"); e.done=true
		return
	if w.distance(a.pos,e.pos)>1:
		a.move_credit=minf(1.9,a.move_credit+a.move_speed*w.DT)
		if a.move_credit>=1:
			var next=w.animal_next(a,e.pos)
			if next!=e.pos and next!=a.pos and not w.actor_occupied(next,a.pos): a.move_credit-=1; w.open_for_ally(next); a.pos=next
		return
	var previous=e.pos
	walk(w,e,goal)
	if e.pos!=previous and w.animal_walkable(a,previous) and not w.actor_occupied(previous,a.pos):
		a.move_credit=minf(1.9,a.move_credit+a.move_speed*w.DT)
		if a.move_credit>=1: a.move_credit-=1; a.pos=previous
