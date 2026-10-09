extends RefCounted
## G–M content on the existing individual, fixed-tick and FIFO lifecycles.
const PLACEABLES=["kokeshi","fossil"]
const CORPSE_SECONDS=8.0
const RAGE={"UltimateID":"rage","Name":"激ギレ","Rarity":2,"UnlockLevel":1,"GaugeCost":100.0,"ConditionID":"enemy_near","Duration":6.0,"AIHints":{"threshold":0.5},"LevelScaling":{}}
const REVIVE={"UltimateID":"resurrection","Name":"復活の舞","Rarity":2,"UnlockLevel":1,"GaugeCost":100.0,"ConditionID":"ally_downed","Duration":0.0,"AIHints":{"threshold":0.5,"priority":0.5},"LevelScaling":{}}

static func speed(w,a: Dictionary) -> float:
	var factor=0.8 if w.tick<a.get("poison_until",0) else 1.0
	if w.field_items.any(func(i):return i.kind=="kokeshi" and i.get("placed",false) and w.distance(i.pos,a.pos)<=3): factor*=0.8
	if a.get("species","")=="bull" and a.hp>0 and a.hp<=a.max_hp*0.5: factor*=1.5
	if w.tick<a.get("dance_until",0): factor*=1.15
	return factor

static func attack_speed(w,a: Dictionary) -> float:
	return (1.15 if w.tick<a.get("dance_until",0) else 1.0)*(1.5 if a.get("species","")=="bull" and a.hp<=a.max_hp*0.5 else 1.0)

static func queue(w,kind: String,p: Vector2i,id: int) -> bool:
	if not w.working() or w.jobs.size()>=8:return false
	if kind=="milk":
		var a=w.Orders.animal(w,id)
		if not w.Orders.active(w,a) or a.species!="cow" or a.get("milked_day",-1)==w.campaign.day:return false
		if w.jobs.any(func(j):return j.kind==kind and j.animal_id==id):return false
		p=a.pos
	else:
		var item=kind.trim_prefix("place_")
		if item not in PLACEABLES or not can_place(w,p):return false
		if w.item_count(item)<=w.jobs.filter(func(j):return j.kind==kind).size():return false
		if w.jobs.any(func(j):return j.pos==p and j.kind.begins_with("place_")):return false
	if w.jobs.is_empty() and w.manual_goal==null and w.Life.able(w) and w.job_hold_reason in ["travel","manual","rescue","danger","rest_end"]:w.Jobs.hold(w,"")
	w.jobs.append({"id":w.next_job_id,"kind":kind,"pos":p,"animal_id":id,"state":"pending","started":false,"reserved":0,"resource":""})
	w.next_job_id+=1;w.Life.wake_auto(w)
	w.job_log.append({"tick":w.tick,"event":"queued","id":w.next_job_id-1,"kind":kind})
	return true

static func can_place(w,p: Vector2i) -> bool:
	return w.inside(p) and w.walkable(p) and not w.occupied(p) and not w.live_structure(p) and not w.natural.has(p) and w.items_at(p).is_empty()

static func job(w,j):
	var cow={}
	if j.kind=="milk":
		cow=w.Orders.animal(w,j.animal_id)
		if not w.Orders.active(w,cow) or cow.species!="cow" or cow.get("milked_day",-1)==w.campaign.day:w.Jobs.complete(w,j,false);return
		j.pos=cow.pos
	else:
		if not can_place(w,j.pos):j.state="blocked";j.block_reason="置く場所を空けてください";return
		if w.item_count(j.kind.trim_prefix("place_"))<1:w.Jobs.complete(w,j,false);return
	if not w.Jobs.walk(w,j,w.neighbors(j.pos)):return
	j.state="working";j.started=true;j.progress=j.get("progress",0.0)+w.DT*w.Life.factor(w)
	if j.progress<2.0:return
	if j.kind=="milk":
		cow.milked_day=w.campaign.day;w.add_item("milk",1)
		for owned in w.campaign.animals:
			if owned.id==cow.id:owned.milked_day=cow.milked_day
	else:
		var kind=j.kind.trim_prefix("place_")
		w.add_item(kind,-1);w.field_items.append({"id":"placed-%d-%d"%[w.campaign.day,j.id],"kind":kind,"pos":j.pos,"placed":true,"born_day":w.campaign.day})
	w.Jobs.complete(w,j,true)

static func ally_walk(w,a,goal: Vector2i,multiplier: float=1.0):
	a.move_credit=minf(1.9,a.move_credit+a.move_speed*speed(w,a)*multiplier*w.DT)
	if a.move_credit<1:return
	var next=w.animal_next(a,goal)
	if next!=a.pos and not w.actor_occupied(next,a.pos) and w.Combat.pay(a,"move"):
		a.move_credit-=1;w.open_for_ally(next);a.pos=next

static func drink(a) -> bool:
	var hp=a.hp;var stamina=a.get("stamina",0)
	a.hp=mini(a.max_hp,a.hp+3)
	if a.has("stamina"):a.stamina=minf(a.get("max_stamina",100.0),a.stamina+12)
	return a.hp>hp or a.get("stamina",0)>stamina

static func animal_step(w,a) -> bool:
	if a.species=="bull" and a.mode=="charge":
		if not a.has("charge_path"):
			if w.tick<a.get("charge_at",0):a.mode="auto";return true
			a.charge_at=w.tick+ceili(8.0/w.DT);a.charge_path=line(a.pos,a.order)
		a.state="突撃";a.move_credit+=4.0*speed(w,a)*w.DT
		if a.move_credit<1:return true
		a.move_credit-=1
		if a.charge_path.is_empty():end_charge(a);return true
		var next=a.charge_path[0]
		if not w.animal_walkable(a,next) or w.blocks(next):end_charge(a);return true
		var targets=w.enemies.filter(func(e):return not e.done and not e.flee and e.hp>0 and e.pos==next)
		if not targets.is_empty():w.Progression.enemy_hurt(w,targets[0],20,a.id,"charge",true);end_charge(a);return true
		if w.actor_occupied(next,a.pos):end_charge(a);return true
		a.pos=next;a.charge_path.pop_front()
		return true
	if a.has("charge_path"):a.erase("charge_path")
	if a.species!="maid":return false
	return maid_step(w,a,false)

static func recruit_maid(w,e) -> bool:
	if e.get("faction")!="enemy" or e.hp<=0 or e.done:return false
	var cows=w.animals.filter(func(a):return w.Orders.active(w,a) and a.species=="cow" and w.distance(e.pos,a.pos)<=w.ProgressData.EnemySkills.TUNING.maid_recruit_range and w.line_of_sight(e.pos,a.pos))
	if cows.is_empty() or w.tick<e.threat_until or w.tick<e.get("rage_until",0):return false
	var tested=e.get("recruit_cows",[])
	for cow in cows:
		if cow.id in tested:continue
		tested.append(cow.id);e.recruit_cows=tested
		if w.rng.randf()>=e.get("debug_recruit_chance",w.ProgressData.EnemySkills.TUNING.maid_recruit_chance):continue
		e.done=true;e.recruited=true
		var id=w.campaign.next_animal_id;w.campaign.next_animal_id+=1
		var owned={"id":id,"species":"maid","category":"human","lv":e.lv,"hp":e.hp,"rarity":e.rarity,"xp":0,"loyalty":85,"traits":{},"name":"","affinity":null,"unavailable_through_day":0,"position":[e.pos.x,e.pos.y],"source":"recruited","source_enemy_id":e.id}
		w.campaign.animals.append(owned);w.add_resident(owned)
		var a=w.animals.back();a.ultimate_gauge=e.ultimate_gauge;a.stamina=e.stamina
		w.Progression.knowledge(w,e,2);w.PlayerEvents.add(w,"乳牛に心を許し、メイドが仲間になった")
		return true
	return false

# Enemy support stays with its recipient even during the coffee cooldown.
static func escort_ally(w,a):
	var allies=w.enemies.filter(func(t):return t.id!=a.id and not t.done and not t.flee and t.hp>0 and not t.get("dead",false) and w.inside(t.pos))
	var preferred=a.get("escort_target",a.get("coffee_target",-1))
	allies.sort_custom(func(t,u):
		if (t.id==preferred)!=(u.id==preferred):return t.id==preferred
		return w.distance(a.pos,t.pos)<w.distance(a.pos,u.pos) if w.distance(a.pos,t.pos)!=w.distance(a.pos,u.pos) else t.id<u.id)
	for target in allies:
		if w.distance(a.pos,target.pos)<=2 and w.line_of_sight(a.pos,target.pos):
			a.escort_target=target.id;a.state="仲間のそばで待機";a.action_id="idle";return
		var best=[]
		for cell in w.neighbors(target.pos):
			if not w.walkable(cell) or w.actor_occupied(cell,a.pos):continue
			var path=w.find_path(a.pos,cell,false,true)
			if not path.is_empty() and (best.is_empty() or path.size()<best.size()):best=path
		if best.is_empty():continue
		a.escort_target=target.id;a.state="仲間に同行";a.action_id="walk"
		w.Progression.walk(w,a,best[-1]);return
	a.erase("escort_target");a.state="支援相手を待つ";a.action_id="idle"

static func maid_step(w,a,enemy: bool) -> bool:
	if enemy and recruit_maid(w,a):return true
	# Finish arrival and vacate the entry before starting a support/rest cycle.
	# Otherwise outside recipients are unreachable, and repeated rests seal the queue.
	if enemy and not a.get("arrival_cleared",false):
		if not w.inside(a.pos) or a.pos==a.entry:
			var goals=w.neighbors(a.entry).filter(func(p):return w.walkable(p) and not w.actor_occupied(p,a.pos))
			var best=[]
			for goal in goals:
				var route=w.find_path(a.pos,goal,false,true)
				if not route.is_empty() and (best.is_empty() or route.size()<best.size()):best=route
			a.state="入口を空ける";a.action_id="walk"
			if not best.is_empty():w.Progression.walk(w,a,best[-1])
			return true
		a.arrival_cleared=true
	if not enemy:w.Combat.recover(a,w.DT,a.mode=="rest")
	if not enemy and a.mode=="rest":w.rest_step(a,true);a.action_id="idle";return true
	var enemies=w.Progression.target_candidates(w,a).filter(func(t):return t.kind in ["keeper","animal"]) if enemy else w.animal_targets(a).filter(func(e):return e.hp>0)
	enemies.sort_custom(func(e,f):return w.distance(a.pos,e.pos)<w.distance(a.pos,f.pos))
	w.Combat.ai_use(w,a,RAGE,{"conditions":{"enemy_near":not enemies.is_empty()},"targets":enemies.size(),"tactical_score":1.0},func():a.rage_until=w.tick+ceili(RAGE.Duration/w.DT);return true)
	var raging=w.tick<a.get("rage_until",0)
	a.action_id="rage" if raging else "idle"
	if not enemies.is_empty() and raging:
		var target=enemies[0];a.state="激ギレ" if raging else "抵抗"
		if w.distance(a.pos,target.pos)<=1 and w.line_of_sight(a.pos,target.pos):
			if w.tick>=a.next_attack and w.Combat.pay(a,"attack"):
				a.next_attack=w.tick+ceili(1.2/w.DT/(2.0 if raging else 1.0))
				if enemy:w.Progression.strike(w,a,target,12 if raging else 3)
				else:w.Progression.enemy_hurt(w,target,12 if raging else 3,a.id)
		else:
			a.action_id="chase"
			if enemy:
				var original=a.move_speed;a.move_speed=original*2.0;w.Progression.walk(w,a,target.pos);a.move_speed=original
			else:ally_walk(w,a,target.pos,2.0)
		return true
	if not enemy and a.mode=="stay":a.state="待機";return true
	if w.tick<a.get("coffee_rest_until",0):
		a.state="休む"
		if not enemy:w.rest_step(a,false)
		else:escort_ally(w,a)
		return true
	if w.tick<a.get("coffee_wait",0):
		if enemy:escort_ally(w,a)
		else:a.state="配り終えた"
		return true
	var served=a.get("coffee_served",[])
	var allies=w.enemies.filter(func(t):return t.id!=a.id and not t.done and not t.flee and t.hp>0) if enemy else [w.keeper]+w.animals.filter(func(t):return t.id!=a.id and w.Orders.active(w,t))
	allies=allies.filter(func(t):return t.hp>0 and t.get("carrier",-1)<0 and t.get("state","")!="hidden_rest" and t.get("id",-1) not in served)
	if allies.is_empty():
		drink(a);a.coffee_served=[];a.coffee_rest_until=w.tick+ceili(10.0/w.DT);a.state="休む"
		# No recipients: follow without falling through to the generic combat AI.
		if enemy:escort_ally(w,a)
		return true
	allies.sort_custom(func(t,u):
		var t_buff=enemy and t.get("archetype","")=="dancer" and w.distance(a.pos,t.pos)<=a.sight_range
		var u_buff=enemy and u.get("archetype","")=="dancer" and w.distance(a.pos,u.pos)<=a.sight_range
		if t_buff!=u_buff:return t_buff
		return w.distance(a.pos,t.pos)<w.distance(a.pos,u.pos) if w.distance(a.pos,t.pos)!=w.distance(a.pos,u.pos) else t.get("id",-1)<u.get("id",-1))
	var target=allies[0];a.state="コーヒーを届ける"
	if a.get("coffee_target",-999)!=target.get("id",-1):
		a.coffee_target=target.get("id",-1);a.coffee_deadline=w.tick+ceili((8.0+w.distance(a.pos,target.pos)/a.move_speed*2.0)/w.DT)
	if w.tick>=a.coffee_deadline:served.append(target.get("id",-1));a.coffee_served=served;return true
	if w.distance(a.pos,target.pos)<=1 and w.line_of_sight(a.pos,target.pos):
		if enemy:a.escort_target=target.id
		var helped=drink(target)
		served.append(target.get("id",-1));a.coffee_served=served;a.coffee_wait=w.tick+ceili(1.0/w.DT)
		w.skill_log.append({"tick":w.tick,"actor":a.id,"skill":"coffee_support","faction":"enemy" if enemy else "owned","target":target.get("id",-1)})
		if helped:
			w.Combat.grant(w,a,"SkillHit","coffee_support",str(target.get("id",-1)));w.PlayerEvents.add(w,"メイド：コーヒー配布","coffee:"+str(a.get("faction"))+str(a.id))
	elif w.find_path(a.pos,target.pos).is_empty():served.append(target.get("id",-1));a.coffee_served=served
	elif enemy:w.Progression.walk(w,a,target.pos)
	else:ally_walk(w,a,target.pos)
	return true

static func end_charge(a):
	a.mode="auto";a.erase("charge_path");a.home=a.pos;a.order=a.pos

static func line(start: Vector2i,goal: Vector2i) -> Array:
	# Four-connected raster line; never diagonal corner cutting or A* detours.
	var path=[];var p=start;var dx=absi(goal.x-start.x);var dy=absi(goal.y-start.y);var x=0;var y=0
	while p!=goal and path.size()<128:
		if (x+0.5)*maxi(1,dy)<(y+0.5)*maxi(1,dx) and x<dx or y>=dy:p.x+=signi(goal.x-start.x);x+=1
		else:p.y+=signi(goal.y-start.y);y+=1
		path.append(p)
	return path

static func down(w,e) -> bool:
	if e.get("dead",false):return true
	if e.get("phone_started",false):w.PlayerEvents.add(w,e.name+"：電話を中断")
	drop_stolen(w,e)
	e.dead=true;e.revivable=not e.get("revived",false);e.corpse_started_tick=w.tick;e.corpse_until=w.tick+ceili(CORPSE_SECONDS/w.DT)
	e.done=false;e.flee=false;e.hp=0;e.state="倒れた";e.capture_progress=0;e.counter_target=-1;e.phone_started=false;e.chosen_target={}
	w.release_keeper(e);w.Progression.release_animal(w,e)
	if w.keeper.restrainer==e.id:
		w.keeper.restrainer=-1;w.keeper.state="unconscious" if w.keeper.hp<=0 else "free"
	if not e.get("defeat_recorded",false):
		e.defeat_recorded=true;w.metrics.repelled+=1;w.Progression.loot(w,e);w.Progression.knowledge(w,e,3)
		w.metrics.coins+=0 if e.get("archetype")=="salaryman" else 3
	w.PlayerEvents.add(w,e.name+"を倒した")
	return true

static func finalize(w,e):
	e.revivable=false;e.dead=true;e.done=true;e.flee=false

static func corpse_step(w,e):
	if not e.get("dead",false):down(w,e)
	if w.tick>=e.corpse_until:finalize(w,e)

static func drop_stolen(w,e):
	if not e.get("stolen",{}).is_empty():
		var item=e.stolen;item.pos=e.pos;w.field_items.append(item);e.stolen={}
		e.escape_theft=false

static func enemy_step(w,e) -> bool:
	if e.get("dead",false) or e.hp<=0:
		corpse_step(w,e)
		return true
	if e.flee or e.hp<=0:return false
	if e.archetype=="maid":return maid_step(w,e,true)
	if e.archetype=="dancer":
		var downed=w.enemies.filter(func(t):return t.get("dead",false) and not t.done and t.get("revivable",false) and t.get("corpse_until",0)>w.tick and t.archetype!="dancer" and not t.get("revived",false) and w.distance(e.pos,t.pos)<=3 and w.line_of_sight(e.pos,t.pos))
		downed.sort_custom(func(a,b):return a.archetype=="martial_artist" if (a.archetype=="martial_artist")!=(b.archetype=="martial_artist") else a.id<b.id)
		if not downed.is_empty():
			var target=downed[0]
			w.Combat.ai_use(w,e,REVIVE,{"conditions":{"ally_downed":true},"tactical_score":1.0,"priority_target":target.archetype=="martial_artist"},func():
				if not w.walkable(target.pos) or (w.keeper.placed and w.keeper.pos==target.pos) or w.animals.any(func(a):return a.placed and a.pos==target.pos) or w.enemies.any(func(a):return a.id!=target.id and not a.done and a.hp>0 and a.pos==target.pos):return false
				target.hp=mini(target.max_hp,e.hp);target.dead=false;target.revivable=false;target.revived=true;target.revived_count=1;target.done=false;target.flee=false;target.action_id="idle";target.state="復活";target.next_attack=w.tick+4
				w.PlayerEvents.add(w,target.name+"が復活")
				return true)
		var friends=w.enemies.filter(func(t):return t.id!=e.id and not t.done and not t.flee and t.hp>0 and w.distance(e.pos,t.pos)<=3 and w.line_of_sight(e.pos,t.pos))
		var close=w.animals.any(func(a):return w.Orders.active(w,a) and w.distance(a.pos,e.pos)<=1 and w.line_of_sight(a.pos,e.pos)) or (w.Life.targetable(w) and w.distance(w.keeper.pos,e.pos)<=1 and w.line_of_sight(e.pos,w.keeper.pos))
		if not close and w.tick<e.get("dancing_until",0):
			e.action_id="fan_raise" if (w.tick%4)<2 else "fan_spread";e.state="舞う";return true
		if not close and not friends.is_empty() and w.tick>=e.get("dance_at",0) and w.Combat.pay(e,"skill"):
			e.dancing_until=w.tick+ceili(w.ProgressData.EnemySkills.TUNING.dance_duration/w.DT)
			e.dance_at=w.tick+ceili(w.ProgressData.EnemySkills.get_skill("dance").Cooldown/w.DT)
			for t in friends:t.dance_until=w.tick+ceili(w.ProgressData.EnemySkills.TUNING.dance_buff/w.DT)
			e.action_id="fan_raise";e.state="舞う";w.PlayerEvents.add(w,"舞姫：舞");return true
		if not close and w.Progression.Targets.keeper_down(w):
			var advance=w.Progression.Targets.support_target(w,e)
			if not advance.is_empty() and w.distance(e.pos,advance.pos)>2:
				e.state="仲間に続く";e.action_id="walk";w.Progression.walk(w,e,advance.pos);return true

	if e.archetype!="thief":return false
	if not e.get("stolen",{}).is_empty():
		e.state="盗品を持って退却";e.action_id="steal"
		if e.pos==w.exit_for(e.entry):
			e.stolen={};e.done=true;w.milestones.append({"tick":w.tick,"kind":"theft_committed","enemy":e.id});return true
		w.Progression.walk(w,e,w.exit_for(e.entry));return true
	var targets=w.Progression.target_candidates(w,e).filter(func(t):return t.kind in ["keeper","animal"] and w.distance(e.pos,t.pos)<=5)
	if not targets.is_empty() and w.tick>=e.get("poison_at",0) and w.Combat.pay(e,"skill"):
		e.poison_fired=w.tick;e.poison_at=w.tick+ceili(8.0/w.DT);e.action_id="poison_windup";e.poison_visual_until=w.tick+3;e.poison_target=targets[0].pos;e.state="毒を投げる"
		w.PlayerEvents.add(w,"盗賊：毒瓶")
		for a in [w.keeper]+w.animals:
			if a.hp>0 and a.get("placed",true) and not preload("res://game/animal_recovery.gd").protected(w,a) and w.distance(a.pos,targets[0].pos)<=1 and w.line_of_sight(targets[0].pos,a.pos):a.poison_until=w.tick+ceili(5.0/w.DT);a.poison_source=e.id
		return true
	if w.tick<e.get("poison_visual_until",0):return true
	var items=w.field_items.filter(func(i):return i.kind!="chick" and w.distance(e.pos,i.pos)<=e.sight_range and w.line_of_sight(e.pos,i.pos))
	items.sort_custom(func(a,b):return w.distance(e.pos,a.pos)<w.distance(e.pos,b.pos) if w.distance(e.pos,a.pos)!=w.distance(e.pos,b.pos) else str(a.pos)<str(b.pos))
	if not items.is_empty():
		var item=items[0]
		e.action_id="steal";e.state="盗みに向かう"
		if w.distance(e.pos,item.pos)<=1:
			e.stolen=item.duplicate(true);w.field_items.erase(item)
			w.PlayerEvents.add(w,"盗賊が"+w.Shop.table().get(item.kind,{}).get("Name",item.kind)+"を盗んだ")
		else:w.Progression.walk(w,e,item.pos)
		return true
	return false

static func tick(w):
	if w.tick%ceili(1.0/w.DT)!=0:return
	for a in [w.keeper]+w.animals:
		if a.hp<=0 or w.tick>=a.get("poison_until",0):continue
		var sources=w.enemies.filter(func(e):return e.id==a.get("poison_source",-1))
		if sources.is_empty():continue
		var source=sources[0].duplicate();source.attack_power=1;source.combat_action="poison";source.combat_skill=true
		if a==w.keeper:w.Life.hurt(w,source)
		else:w.Progression.animal_hurt(w,a,source,1)
