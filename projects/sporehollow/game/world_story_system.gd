extends RefCounted
## Campaign-owned deterministic world history; no UI clock, rendering or hidden queues.
const CLEAR_SECONDS = 4.0
const CLEAR_WOOD = 8
const PRAYER_SECONDS = 3.0
const MIRACLE_GOLD = 60
const IDOL_HP = 180
const TOW_PREP_SECONDS = 8.0
const TOW_SPEED = 0.5
const ACTIONS = ["clear_tree","inspect_idol","pray_wealth","repair_idol","recover_idol"]
const INTRO = ["父は、遺跡と秘境を巡る探検家だった。", "最後の旅から持ち帰ったのは、大きな黄金像。\nそれからほどなく、父はいなくなった。", "私は、父の残した牧場で暮らし始めた。\n愛犬と過ごした静かな数日は、もう思い出になっている。", "父の日誌には、一言だけ残されていた。\n『像を壊してはいけない。』"]

static func cell(v) -> Vector2i:
	return v if v is Vector2i else Vector2i(v[0],v[1])

static func cells(at: Vector2i) -> Array:
	return [at,at+Vector2i.RIGHT,at+Vector2i.DOWN,at+Vector2i.ONE]

static func at(w) -> Vector2i:
	return cell(w.story.get("idol",{}).get("position",[12,8]))

static func idol_cells(w) -> Array:
	return [] if w.story.get("idol",{}).is_empty() else cells(at(w))

static func terrain_block(w,p: Vector2i) -> bool:
	return w.trees.has(p) or p in idol_cells(w)

static func init(w):
	w.story=w.campaign.get("world_story",{}).duplicate(true)
	if w.story.is_empty():
		w.story={"version":1,"intro_seen":false,"investigated":false,"radio":false,"prayed_day":0,"next_prayer_id":1,"prayers":[],"events":[],"news":[],"miracles":[],"cleared":[],"hidden":{"security":0,"economy":0,"disease":0,"anomaly":0,"recognition":0,"karma":0},"idol":{},"defeat_reason":""}
		var options=[Vector2i(12,8),Vector2i(10,8),Vector2i(14,8),Vector2i(12,6)]
		for candidate in options:
			if cells(candidate).any(func(p):return w.live_structure(p) or w.floors.has(p) or w.occupied(p) or not w.items_at(p).is_empty()): continue
			w.story.idol={"id":"father-idol","position":[candidate.x,candidate.y],"home":[candidate.x,candidate.y],"hp":IDOL_HP,"max_hp":IDOL_HP,"state":"installed","carrier":-1,"prepare":0.0}
			break
		if w.story.idol.is_empty():
			w.story.migration_error="黄金像を安全に置けません。建物を残して移行するには中央を空けるか、新しい牧場を始めてください。"
			say(w,w.story.migration_error)
		var records=[]
		for y in range(2,w.H-2):
			for x in range(2,w.W-2):
				var p=Vector2i(x,y)
				# Two-cell corridors connect the clearing to every edge; logistics remains separate.
				if x>3 and x<21 and y>3 and y<13: continue
				if x in [5,6,12,13,19,20] or y in [5,6,8,9,11,12]: continue
				if not preload("res://game/forest_pattern.gd").tree(p,w.seed_value):continue
				if w.distance(p,w.logistics_entry)<4 or w.distance(p,w.keeper.pos)<=2 or w.animals.any(func(a):return a.placed and w.distance(p,a.pos)<=2) or p in idol_cells(w) or w.occupied(p) or w.live_structure(p) or w.floors.has(p) or not w.items_at(p).is_empty(): continue
				records.append({"id":"tree-%d-%d"%[x,y],"position":[x,y]})
		w.story.trees=records
	for tree in w.story.get("trees",[]):
		if tree.id not in w.story.cleared: w.trees[cell(tree.position)]=tree.id
	morning(w,w.campaign.day)
	persist(w)

static func persist(w):
	w.campaign.world_story=w.story.duplicate(true)

static func entries(w) -> Array:
	var result=[]
	for y in [5,8,11]: result.append(Vector2i(1,y)); result.append(Vector2i(w.W-2,y))
	for x in [5,12,19]: result.append(Vector2i(x,1)); result.append(Vector2i(x,w.H-2))
	return result

static func schedule(w):
	var r=RandomNumberGenerator.new()
	r.seed=w.seed_value*4729+w.campaign.day*65537+w.schedule_cycle*97
	for event in w.spawn_schedule:
		event.entry=w.entries[r.randi_range(0,w.entries.size()-1)]
	# Delayed reaction events change real raid composition, capped independently of day scaling.
	var count=mini(2,w.story.get("hidden",{}).get("security",0))
	for i in range(count):
		var role="kidnapper"
		if w.story.hidden.recognition>=1: role="idol_breaker" if i==0 else "idol_extractor"
		w.spawn_schedule.append({"tick":ceili((60.0+i*24)/w.DT),"wave":100+i,"role":role,"entry":w.entries[r.randi_range(0,w.entries.size()-1)],"lv":1})
	w.spawn_schedule.sort_custom(func(a,b):return a.tick<b.tick)

static func goals(w) -> Array:
	var result=[]
	for p in idol_cells(w):
		for n in w.neighbors(p):
			if n not in idol_cells(w) and n not in result and w.walkable(n): result.append(n)
	return result

static func reason(w,kind: String,p: Vector2i) -> String:
	if kind=="clear_tree": return "伐採には道具が必要です"
	if w.story.idol.is_empty(): return w.story.get("migration_error","黄金像が見つかりません")
	if w.story.idol.state in ["preparing","transporting","lost"]: return "像が危険です。先に運び手を止めてください"
	if kind=="pray_wealth":
		if not w.config.get("legacy_prayer",false): return "祈りの報酬は準備中です"
		if not w.story.investigated: return "最初の夜を越えたら、像を調べてください"
		if w.story.prayed_day==w.campaign.day: return "今日は祈りを捧げました"
	if kind=="repair_idol":
		if w.story.idol.hp>=w.story.idol.max_hp: return "損傷はありません"
		if w.wood<5: return "修理には木材 ×5が必要です"
	if kind=="recover_idol" and w.story.idol.state!="interrupted": return "像は設置済みです"
	return ""

static func enqueue(w,kind: String,p: Vector2i) -> bool:
	if not w.working(): return false
	if w.jobs.size()>=8: say(w,"予定は8件までです"); return false
	var why=reason(w,kind,p)
	if why!="": say(w,why); return false
	var target=w.trees.get(p,"") if kind=="clear_tree" else "father-idol"
	if w.jobs.any(func(j):return j.get("world_target")==target): say(w,"予約済みです"); return false
	var j={"id":w.next_job_id,"kind":kind,"pos":p if kind=="clear_tree" else at(w),"world_target":target,"animal_id":-1,"state":"pending","started":false,"resource":"","reserved":0,"elapsed":0.0}
	w.next_job_id+=1
	if w.jobs.is_empty() and w.manual_goal==null and w.Life.able(w) and w.job_hold_reason in ["travel","manual","rescue","danger","rest_end"]: w.Jobs.hold(w,"")
	w.jobs.append(j); w.Life.wake_auto(w)
	w.job_log.append({"tick":w.tick,"event":"queued","id":j.id,"kind":kind,"target":target})
	return true

static func step_job(w,j):
	if j.kind=="clear_tree": w.Jobs.complete(w,j,false); return
	var why=reason(w,j.kind,j.pos)
	if why!="": j.state="blocked"; j.block_reason=why; return
	var destinations=w.neighbors(j.pos) if j.kind=="clear_tree" else goals(w)
	if w.keeper.pos not in destinations: w.Jobs.walk(w,j,destinations); return
	j.state="working"; j.started=true
	j.elapsed+=w.DT*w.Life.factor(w)
	var duration=CLEAR_SECONDS if j.kind=="clear_tree" else (PRAYER_SECONDS if j.kind=="pray_wealth" else 2.0)
	if j.elapsed<duration: return
	match j.kind:
		"clear_tree":
			if w.occupied(j.pos): j.state="blocked"; j.block_reason="誰かがいます"; return
			w.story.cleared.append(j.world_target); w.trees.erase(j.pos); w.add_resource("wood",CLEAR_WOOD)
			say(w,"木を片付けた。木材 +%d"%CLEAR_WOOD)
		"inspect_idol":
			if w.campaign.day>=2: w.story.investigated=true
			say(w,"父の日誌：像を壊してはいけない。"+(" 像に願いを託せそうだ。" if w.story.investigated else " 今は静かに佇んでいる。"))
		"pray_wealth": pray(w)
		"repair_idol":
			w.add_resource("wood",-5); w.story.idol.hp=mini(w.story.idol.max_hp,w.story.idol.hp+30)
		"recover_idol":
			# Re-anchor where the tow was stopped; never teleport the object home.
			w.story.idol.state="recovered"; w.story.idol.home=w.story.idol.position.duplicate()
			say(w,"黄金像をこの場所に固定し直した")
	persist(w)
	w.Jobs.complete(w,j,true)

static func interrupt_prayer(w):
	for j in w.jobs.duplicate():
		if j.kind=="pray_wealth" and j.started:
			w.Jobs.cancel(w,j.id,"prayer_interrupted"); say(w,"祈りが途切れた")

static func pray(w):
	var id="prayer-%d"%w.story.next_prayer_id
	w.story.next_prayer_id+=1; w.story.prayed_day=w.campaign.day
	w.story.prayers.append({"id":id,"day":w.campaign.day,"wish":"wealth","reward_day":w.campaign.day+1,"rewarded":false})
	w.story.hidden.karma+=1
	for spec in [[1,"gold_find"],[2,"trade_rumor"],[3,"robbery"]]:
		w.story.events.append({"id":id+"-"+spec[1],"prayer_id":id,"day":w.campaign.day+spec[0],"kind":spec[1],"applied":false,"news_id":id+"-news-"+spec[1],"published":false})
	say(w,"願いを託した。像は静かに光っている。")

static func morning(w,day: int):
	if day>=2 and not w.story.radio:
		w.story.radio=true
		w.story.news.append({"id":"father-radio","day":day,"title":"父の古いラジオ","text":"道具箱から、小さなラジオが見つかった。遠い町の放送が聞こえる。"})
	for prayer in w.story.prayers:
		if prayer.reward_day<=day and not prayer.rewarded:
			prayer.rewarded=true; w.campaign.gold+=MIRACLE_GOLD
			w.story.miracles.append({"id":prayer.id,"day":day,"gold":MIRACLE_GOLD})
			say(w,"像のそばに金貨が残されていた。+%dG"%MIRACLE_GOLD)
	for event in w.story.events:
		if event.day>day or event.applied: continue
		event.applied=true
		var title=""; var body=""
		match event.kind:
			"gold_find":
				w.story.hidden.economy+=1
				title="各地で金鉱脈の発見"; body="採掘地から新たな金の便りが相次いでいます。市場には人が集まり始めました。"
			"trade_rumor":
				w.story.hidden.recognition+=1
				title="街道に流れる噂"; body="珍しい宝を探す旅人が街道を行き交っています。商人たちも戸締まりを気にしています。"
			"robbery":
				w.story.hidden.security=mini(2,w.story.hidden.security+1)
				title="採掘地で強盗が増加"; body="物資と宝を狙う一団が、町の外へも足を延ばしているとのことです。"
		if not event.published:
			w.story.news.append({"id":event.news_id,"day":day,"title":title,"text":body}); event.published=true
	persist(w)

static func merchant(w) -> String:
	return "街道の噂が騒がしくてね。夜は気をつけて。" if w.story.get("hidden",{}).get("recognition",0)>0 else "今日は何を用意しようか。"

static func damage(w,amount: int):
	if w.story.idol.is_empty() or w.story.idol.hp<=0: return
	w.story.idol.hp=maxi(0,w.story.idol.hp-amount)
	w.Life.danger(w,"idol_hit")
	if w.story.idol.hp==0: lose(w,"idol_destroyed")

static func lose(w,why: String):
	w.story.defeat_reason=why
	if why=="idol_stolen": w.story.idol.state="lost"
	w.finish(false)

static func crisis(w) -> bool:
	return w.keeper.carrier>=0 or w.enemies.any(func(e):return not e.done and not e.flee and e.capture_progress>0) or w.story.get("idol",{}).get("state") in ["preparing","transporting"] or w.enemies.any(func(e):return not e.done and not e.flee and e.role in ["idol_breaker","idol_extractor"])

static func tick(w):
	if w.story.idol.is_empty(): return
	if w.keeper.resting or w.keeper.state!="free": interrupt_prayer(w)
	var idol=w.story.idol
	if idol.carrier>=0 and not w.enemies.any(func(e):return e.id==idol.carrier and not e.done and not e.flee and e.hp>0):
		idol.carrier=-1; idol.state="interrupted"; idol.prepare=0.0
		say(w,"像の搬出を止めた。現地で固定し直せます。")

static func exit_goal(w,e) -> Vector2i:
	var candidates=w.entries.duplicate()
	candidates.sort_custom(func(a,b):return w.distance(a,e.entry)<w.distance(b,e.entry))
	for entry in candidates:
		var goal=w.exit_for(entry)
		if not w.find_path(e.pos,goal,true).is_empty(): return goal
	return w.exit_for(e.entry)

static func tow_path(w,start: Vector2i,goal: Vector2i,offset: Vector2i) -> Array:
	# Search the whole 2x2 footprint AND the hauler cell; no squeezing through single doors.
	var open=[start]; var prev={start:start}
	while not open.is_empty():
		var p=open.pop_front()
		if p==goal:
			var route=[p]
			while p!=start: p=prev[p]; route.push_front(p)
			return route
		for n in w.neighbors(p):
			if prev.has(n) or n.x < -1 or n.y < -1 or n.x>w.W-1 or n.y>w.H-1: continue
			var footprint=cells(n)+[n+offset]
			if footprint.any(func(c):return w.trees.has(c)): continue
			# Going outside is permitted only in the chosen exit's two-cell lane.
			if footprint.any(func(c):return not w.inside(c)) and w.distance(n,goal)>2: continue
			prev[n]=p; open.append(n)
	return []

static func tow_route(w,e,anchor: Vector2i,offset: Vector2i) -> Array:
	var candidates=w.entries.duplicate()
	candidates.sort_custom(func(a,b):
		var da=w.distance(a,e.entry);var db=w.distance(b,e.entry)
		return da<db if da!=db else (a.y<b.y if a.y!=b.y else a.x<b.x))
	for entry in candidates:
		var exit=w.exit_for(entry)
		var goal=Vector2i(-1,clampi(exit.y,1,w.H-3)) if exit.x==0 else (Vector2i(w.W-1,clampi(exit.y,1,w.H-3)) if exit.x==w.W-1 else (Vector2i(clampi(exit.x,1,w.W-3),-1) if exit.y==0 else Vector2i(clampi(exit.x,1,w.W-3),w.H-1)))
		var route=tow_path(w,anchor,goal,offset)
		if route.size()>1:return route
	return []

static func idol_enemy(w,e) -> bool:
	if e.role not in ["idol_breaker","idol_extractor"] or e.flee or w.story.idol.is_empty(): return false
	var idol=w.story.idol
	if e.role=="idol_extractor" and idol.carrier==e.id:
		if idol.state=="preparing":
			e.state="像の固定を外す"; idol.prepare+=w.DT
			if idol.prepare>=TOW_PREP_SECONDS: idol.state="transporting"; w.Life.danger(w,"idol_towing")
			return true
		if idol.state=="transporting":
			e.state="黄金像を牽引"
			e.move_credit+=TOW_SPEED*w.Content.speed(w,e)*w.DT
			if e.move_credit<1 or w.tick<e.move_stopped_until: return true
			e.move_credit-=1
			var anchor=at(w)
			var offset=e.pos-anchor
			var route=tow_route(w,e,anchor,offset)
			if route.size()<2: e.state="搬出路がふさがっている"; return true
			var next=route[1]
			for p in cells(next)+[next+offset]:
				if w.actor_occupied(p,e.pos): e.state="搬出路で足止め"; return true
				if w.structures.get(p,{}).get("status")=="ready" and w.structures[p].kind in w.Buildings.WALLS+w.Buildings.DOORS:
					if not w.Combat.pay(e,"attack"):return true
					var b=w.structures[p]; b.hp=maxi(0,b.hp-e.object_attack_power)
					if b.hp==0: b.status="destroyed"; w.refresh_indoor()
					return true
			if not w.Combat.pay(e,"move"):e.state="息を整える";return true
			idol.position=[next.x,next.y]; e.pos=next+offset; e.path.append(e.pos); w.refresh_indoor()
			if cells(next).all(func(p):return not w.inside(p)): lose(w,"idol_stolen")
			return true
	var destinations=goals(w)
	if e.pos in destinations:
		if e.role=="idol_breaker":
			e.state="黄金像を壊す"
			if w.tick>=e.next_attack and w.Combat.pay(e,"attack"):
				e.next_attack=w.tick+ceili(e.counter_seconds/w.DT); damage(w,e.object_attack_power)
		elif idol.carrier<0:
			idol.carrier=e.id; idol.state="preparing"; idol.prepare=0.0; w.Life.danger(w,"idol_unfastening")
		return true
	e.move_credit+=e.move_speed*w.Content.speed(w,e)*w.DT
	if e.move_credit<1: return true
	e.move_credit-=1
	var best=[]
	for p in destinations:
		var route=w.find_path(e.pos,p,true)
		if not route.is_empty() and (best.is_empty() or route.size()<best.size()): best=route
	if best.size()>1: w.move_enemy(e,best[1])
	e.state="黄金像へ向かう"
	return true

static func say(w,text: String):
	w.say(text)
	w.milestones.append({"tick":w.tick,"kind":"order_notice","text":text})
