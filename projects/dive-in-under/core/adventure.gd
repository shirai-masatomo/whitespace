extends RefCounted
## Session rules v0.9.0. Old saves/rules never enter this dispatcher.
const Money=preload("res://core/currency.gd")
const Instances=preload("res://core/item_instances.gd")
const Combat=preload("res://core/combat.gd")
static func api() -> GDScript: return load("res://core/expedition.gd")
static func active(s: Dictionary) -> bool: return s.get("ruleset","")=="adventure-0.9.0"
static func configure(cfg: Dictionary) -> Dictionary:
	var rules: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/v1/adventure.json"))
	cfg.progression=rules; cfg.items.merge(rules.items,true); cfg.initial=rules.initial.duplicate(true); cfg.growth=rules.growth.duplicate(true)
	cfg.config_version=rules.version; cfg.intro="5階ごとのポータルで成果を持ち帰ろう。死亡時は装備とバッグ全損、風呂敷・倉庫・成長は残る。"
	cfg.journey={"version":1,"public_max_floor":10,"nodes":rules.nodes,"events":rules.events,"intro_seconds":0.65,"boss_intro_seconds":1.0}
	for id in rules.events: cfg.events[id]={"name":rules.events[id].name}
	return cfg
static func initialize(s: Dictionary, cfg: Dictionary) -> void:
	s.ruleset="adventure-0.9.0"; s.erase("gold"); s.item_rules=cfg.items.duplicate(true); s.affix_rules=cfg.progression.affixes.duplicate(true); s.rng.instance=0
	s.item_details={}; s.quantities={}; s.auto_remedy={"blind":true,"poison":true,"paralysis":true}; s.payment_source="inventory"
	s.records={"boss_kills":0,"first_reward_issued":false,"first_reward_claimed":false}; s.debug=false; s.debug_next=""; s.node={}; s.event_counts={}; s.event_target=""
	s.journey_version=1; s.pending_rewards=[]; s.reward_serial=0; s.reward_return="explore"; s.reward_origin=""; s.event_result={}; s.trip_exp=0; s.trip_gold=0; s.trip_items=0; s.last_reward={}
	s.phase="town"; s.trips=0
static func combat_data(data: Dictionary, cfg: Dictionary) -> Dictionary:
	var d: Dictionary=data.duplicate(true)
	for id in cfg.progression.enemies: d.enemies[id].merge(cfg.progression.enemies[id],true)
	for id in cfg.progression.skills:
		var skill: Dictionary=d.rules.skills.get(id,{})
		skill.merge(cfg.progression.skills[id],true); d.rules.skills[id]=skill
	d.rules.adventure=true; return d
static func note(s: Dictionary, message: String) -> void:
	s.journal.append(message)
	if s.journal.size()>24: s.journal.pop_front()
static func label(s: Dictionary, uid: String) -> String:
	return s.item_rules[s.items[uid]].name+(" ×%d"%s.quantities[uid] if s.items[uid]=="C01" else ("（耐久%d）"%s.item_condition[uid].current if s.item_rules[s.items[uid]].slot!="" else ""))
static func reward(s: Dictionary, id: String, quantity: int=1, origin: String="loot", guaranteed: bool=false) -> void:
	if quantity<=0: return
	s.reward_serial+=1
	s.pending_rewards.append({"id":id,"token":"reward-%d"%s.reward_serial,"quantity":quantity,"profile":Instances.roll(s,id,origin),"guaranteed":guaranteed})
static func receive(s: Dictionary, r: Dictionary) -> bool:
	if r.id=="C01": return Money.credit(s,int(r.quantity))
	if s.inventory.size()>=15: return false
	Instances.install(s,r.id,r.profile,"inventory",int(r.quantity)); s.trip_items+=1
	if r.get("guaranteed",false): s.records.first_reward_claimed=true
	return true
static func fits(s: Dictionary, rewards: Array) -> bool:
	var trial: Dictionary=s.duplicate(true)
	for r in rewards:
		if not receive(trial,r): return false
	return true
static func can_return(s: Dictionary) -> bool:
	return int(s.floor)>0 and int(s.floor)%5==0 and s.phase in ["portal","portal_done","reward","event_result","explore"] and (s.phase=="portal" or s.node.get("resolved",false)) and s.pending_rewards.is_empty()
static func finish(s: Dictionary, kind: String, reason: String) -> void:
	var lost: Array=[]; var kept: Array=[]; var coin_loss: int=Money.amount(s)
	if kind=="death":
		var doomed: Array=s.inventory.duplicate()
		for uid in s.equipment.values():
			if uid!="": doomed.append(uid)
		for uid in doomed: lost.append(label(s,uid)); Instances.erase(s,uid)
		s.deaths+=1; s.hp=0
	for source in ["cloth","warehouse"]:
		for uid in s[source]: kept.append(("風呂敷：" if source=="cloth" else "倉庫：")+label(s,uid))
	kept.append("成長EXP %d（レベル保持）"%s.exp)
	s.result={"kind":kind,"reason":reason,"floor":s.floor,"loss":{"gold":coin_loss if kind=="death" else 0,"exp":0,"items":lost.size()},"lost":lost,"kept":kept}
	s.phase="result"; s.battle={}; s.event=""; s.event_result={}; s.pending_rewards=[]; s.erase("round_presentation"); note(s,reason)
static func choose_node(s: Dictionary, cfg: Dictionary) -> void:
	var e: GDScript=api(); var definition: Dictionary={}
	for n in cfg.progression.nodes:
		if int(n.floor)==int(s.floor): definition=n.duplicate(true); break
	var kind: String=definition.kind
	if kind=="mixed": kind=e.weighted(s,"explore",definition.kinds)
	if s.debug and s.debug_next!="": kind=s.debug_next; s.debug_next=""
	definition.kind=kind; definition.resolved=false; definition.started=false; definition.encounter_id="%d/%d"%[s.trips,s.floor]
	s.node=definition
static func descend(s: Dictionary, data: Dictionary, cfg: Dictionary) -> void:
	s.floor+=1; s.highest_floor=maxi(s.highest_floor,s.floor); s.event=""; s.event_result={}; s.last_reward={}; choose_node(s,cfg)
	if int(s.floor)%5==0:
		s.phase="portal"; note(s,"地下%dF：地上に戻れるポータルを発見。居座るか帰還を選べる。"%s.floor)
	else: start_node(s,data,cfg)
static func eligible(s: Dictionary, definition: Dictionary, cfg: Dictionary) -> bool:
	if definition.get("candidate_only",false) or s.floor<int(definition.min_floor) or s.floor>int(definition.max_floor): return false
	if definition.get("requires_sp",false) and api().hero(s,cfg).max_sp==0: return false
	return int(s.event_counts.get(definition.get("id",""),0))<int(definition.get("limit_per_trip",1))
static func start_node(s: Dictionary, data: Dictionary, cfg: Dictionary) -> void:
	if s.node.started: return
	s.node.started=true
	var e: GDScript=api(); var n: Dictionary=s.node
	if n.kind in ["enemy","boss"]:
		var id: String=e.weighted(s,"explore",n.enemies); var level: int=int(n.levels[0])+e.draw(s,"explore",int(n.levels[1])-int(n.levels[0])+1)
		var seed_value: int=e.draw(s,"battle",2147483647)
		var d: Dictionary=combat_data(data,cfg); var h: Dictionary=e.hero(s,cfg)
		s.battle={"enemy_id":id,"enemy_level":level,"seed":seed_value,"hero":h,"rounds":0,"rules_version":3,"encounter_version":3,"current":Combat.start(h,Combat.enemy(d,id,level),d.rules,seed_value)}
		s.phase="battle"; note(s,"地下%dF：%s Lv.%d が現れた。"%[s.floor,d.enemies[id].name,level])
	elif n.kind=="treasure":
		reward(s,e.weighted(s,"loot",n.rewards),1,"chest")
		if s.floor==2: reward(s,"I10",1,"guaranteed-resource")
		s.phase="treasure"; s.reward_origin="宝箱"; s.reward_return="explore"; note(s,"宝箱を見つけた。")
	else:
		var weights: Dictionary={}
		for id in n.events:
			var def: Dictionary=cfg.progression.events[id].duplicate(true); def.id=id
			if eligible(s,def,cfg): weights[id]=def.weight
		if weights.is_empty(): s.node.resolved=true; s.phase="portal_done" if s.floor%5==0 else "explore"
		else:
			s.event=e.weighted(s,"explore",weights); s.event_counts[s.event]=int(s.event_counts.get(s.event,0))+1; s.event_target=""; s.phase="event"; note(s,cfg.progression.events[s.event].name)
static func round_step(s: Dictionary, data: Dictionary, cfg: Dictionary) -> void:
	var e: GDScript=api(); var previous: Dictionary=s.battle.current; var b: Dictionary=Combat.advance(previous)
	var events: Array=b.log.slice(previous.log.size())
	for event in events:
		if event.type=="remedy_used": Instances.erase(s,event.uid); note(s,"バッグの%sで%sを予防した。"%[s.item_rules[event.item].name,event.status])
		elif event.type=="telegraph": note(s,"石像が力を溜めた。次は強打！ 防御と装備で備えよう。")
		elif event.type=="opening": note(s,"石像に隙ができた。")
		elif event.type=="attack": note(s,"%s → %s：%s"%[b[event.actor].name,b[event.target].name,str(event.damage)+"ダメージ" if event.hit else "MISS"])
		elif event.type=="skill": note(s,b[event.actor].name+"："+b.rules.skills[event.skill].name)
		elif event.type=="status_prevented": note(s,"印で%sを防いだ。"%event.status)
		elif event.type=="status_applied": note(s,b[event.target].name+"："+event.status+"を付与")
	s.round_presentation={"before":previous,"after":b,"events":events}
	s.battle.current=b; s.battle.rounds+=1; s.hp=b.hero.hp; s.sp=b.hero.sp
	if b.outcome=="ongoing": return
	e.Condition.wear(s,cfg); var h: Dictionary=e.hero(s,cfg); s.hp=mini(s.hp,h.max_hp); s.sp=mini(s.sp,h.max_sp)
	if b.outcome=="defeat": finish(s,"death",b.enemy.name+"との戦闘で力尽きた。"); return
	if b.outcome=="draw": finish(s,"draw","戦闘上限で探索を中断した。"); return
	s.node.resolved=true; e.gain_exp(s,int(b.reward.exp),cfg); s.trip_exp+=int(b.reward.exp); s.trip_gold+=int(b.reward.gold)
	reward(s,"C01",int(b.reward.gold),"battle")
	for id in cfg.progression.drops.get(b.enemy.id,{}):
		if e.draw(s,"loot",100)<int(cfg.progression.drops[b.enemy.id][id]): reward(s,id,1,"drop")
	if s.node.kind=="boss" and b.enemy.id=="B10":
		s.records.boss_kills+=1; s.highest_floor=maxi(s.highest_floor,11)
		var first: bool=not s.records.first_reward_issued
		if first or e.draw(s,"loot",100)<int(cfg.progression.boss_repeat_chance): reward(s,cfg.progression.boss_reward,1,"first-clear" if first else "boss-drop",first)
		s.records.first_reward_issued=true
		s.reward_return="clear"
	else: s.reward_return="explore"
	s.reward_origin="戦闘の戦利品"; s.last_reward={"exp":b.reward.exp,"gold":b.reward.gold}; s.phase="reward"; s.last_outcome="victory"; s.battle={}
static func event_reason(s: Dictionary, choice: Dictionary, args: Dictionary, cfg: Dictionary) -> String:
	var cost: Dictionary=choice.cost; var source: String=args.get("payment_source",s.payment_source)
	if cost.has("coin") and (source not in ["inventory","cloth"] or Money.amount(s,source)<int(cost.coin)): return "選んだ収納のコインが不足しています。倉庫からは支払えません。"
	if cost.has("hp") and s.hp<=int(cost.hp): return "支払後にHP1以上必要です。"
	if cost.has("sp") and s.sp<int(cost.sp): return "SPが不足しています。"
	if cost.has("item"):
		var count: int=0
		for uid in s.inventory:
			if s.items[uid]==cost.item and not s.item_details[uid].supply: count+=1
		if count<int(cost.amount): return "バッグの補修石が不足しています。"
	if choice.get("target","")=="gear":
		var uid: String=args.get("uid",s.event_target)
		if not s.items.has(uid) or uid not in s.inventory+s.equipment.values() or cfg.items[s.items[uid]].slot=="": return "対象の装備を選んでください。"
		if cost.has("durability"):
			if s.item_details[uid].supply: return "支給品はイベントの対価にできません。"
			if s.item_condition[uid].current<int(cost.durability): return "対象装備の耐久が不足しています。"
		elif int(s.item_condition[uid].current)>=100: return "修理不要の装備です。"
	return ""
static func resolve_event(s: Dictionary, choice: Dictionary, args: Dictionary, cfg: Dictionary) -> void:
	var e: GDScript=api(); var old_hp: int=s.hp; var exp: int=0; var result: Array[String]=[]; var cost: Dictionary=choice.cost
	if cost.has("coin"): Money.pay(s,int(cost.coin),args.get("payment_source",s.payment_source)); result.append("支払：%dG / %s"%[cost.coin,args.get("payment_source",s.payment_source)])
	if cost.has("hp"): s.hp-=int(cost.hp)
	if cost.has("sp"): s.sp-=int(cost.sp)
	if cost.has("item"):
		var count: int=int(cost.amount)
		for uid in s.inventory.duplicate():
			if count>0 and s.items[uid]==cost.item: Instances.erase(s,uid); count-=1
	var target: String=args.get("uid",s.event_target)
	if cost.has("durability"): s.item_condition[target].current-=int(cost.durability)
	for op in choice.ops:
		match op.kind:
			"hp": s.hp=mini(s.hp+int(op.amount),e.hero(s,cfg).max_hp); result.append("HP %+d（上限まで）"%int(op.amount))
			"sp": s.sp=mini(s.sp+int(op.amount),e.hero(s,cfg).max_sp); result.append("SP %+d（上限まで）"%int(op.amount))
			"exp": e.gain_exp(s,int(op.amount),cfg); s.trip_exp+=int(op.amount); exp+=int(op.amount); result.append("EXP +%d"%op.amount)
			"coin": reward(s,"C01",int(op.amount),"event"); result.append("未受領：%dG"%op.amount)
			"item": reward(s,op.id,1,"event"); result.append("未受領："+cfg.items[op.id].name)
			"chance_item":
				if e.draw(s,"loot",100)<int(op.chance): reward(s,op.id,1,"event"); result.append("品物を見つけた："+cfg.items[op.id].name)
				else: result.append("何も見つからなかった。")
			"repair": s.item_condition[target].current=mini(100,int(s.item_condition[target].current)+int(op.amount)); result.append("対象の耐久を回復した。")
	s.node.resolved=true; s.event_result={"title":cfg.progression.events[s.event].name,"text":choice.label+"。\n"+("\n".join(result) if not result.is_empty() else "先へ進むことにした。"),"hp_delta":int(s.hp)-old_hp,"exp":exp}
	s.event=""; s.phase="event_result"; s.hp=mini(s.hp,e.hero(s,cfg).max_hp); s.sp=mini(s.sp,e.hero(s,cfg).max_sp); note(s,s.event_result.text)
static func transition(previous: Dictionary, action: String, args: Dictionary, data: Dictionary, cfg: Dictionary) -> Dictionary:
	var s: Dictionary=previous.duplicate(true); var error: String=""; var changed: bool=false; var e: GDScript=api()
	match action:
		"depart":
			if s.phase=="town":
				s.payment_source="inventory"; s.floor=0; s.phase="explore"; s.result={}; s.trips+=1; s.event_counts={}; s.node={}; s.trip_exp=0; s.trip_gold=0; s.trip_items=0; s.pending_rewards=[]; s.journal=[]; changed=true
		"descend":
			if s.phase=="explore" and s.floor<10: descend(s,data,cfg); changed=true
		"portal_stay":
			if s.phase=="portal": start_node(s,data,cfg); changed=true
		"portal_continue":
			if s.phase=="portal_done" and s.pending_rewards.is_empty():
				if s.floor==10 and s.node.kind=="boss" and s.records.boss_kills>0: finish(s,"clear","10Fの石像を討伐し、成果を持って帰還した。")
				elif s.floor<10: descend(s,data,cfg)
				else: finish(s,"return","10Fから帰還した。討伐記録は増えない。")
				changed=true
		"return","return_ready":
			if can_return(s): finish(s,"clear" if s.floor==10 and s.node.resolved and s.node.kind=="boss" else "return","ポータルを通って地上へ帰還した。"); changed=true
			else: error="帰還は5の倍数階のポータルで、未受領品の解決後にできます。戦闘中は帰還できません。"
		"round":
			if s.phase=="battle": round_step(s,data,cfg); changed=true
		"open_chest":
			if s.phase=="treasure": s.phase="reward"; s.node.resolved=true; changed=true
		"skip_chest":
			if s.phase=="treasure":
				s.pending_rewards=[]; s.node.resolved=true
				if s.floor%5==0: s.phase="portal_done"
				else: descend(s,data,cfg)
				changed=true
		"claim_all_advance","advance_ready","continue_rewards":
			if s.phase in ["reward","event_result","explore"]:
				if not s.pending_rewards.is_empty() and action!="claim_all_advance": error="未受領品を先に確認してください。"
				elif not fits(s,s.pending_rewards): error="入りきりません。整理・直接装備・入替を選んでください。"
				else:
					for r in s.pending_rewards: receive(s,r)
					s.pending_rewards=[]; s.event_result={}; s.erase("round_presentation")
					if s.floor%5==0 and s.floor>0: s.phase="portal_done"
					else: descend(s,data,cfg)
					changed=true
		"claim_reward","equip_reward","exchange_reward":
			if s.phase=="reward":
				var index: int=e.Journey.reward_index(s,args.get("token",""))
				if index>=0:
					var r: Dictionary=s.pending_rewards[index]; var slot: String=cfg.items[r.id].slot
					if action=="exchange_reward":
						var uid: String=args.get("replace_uid","")
						if not args.get("confirmed",false) or uid not in s.inventory: error="手放す品を確認してください。"
						elif s.item_details[uid].supply: error="支給品は交換の対価にできません。"
						else: Instances.erase(s,uid)
					if error=="" and action=="equip_reward":
						if slot=="" or args.get("slot",slot)!=slot: error="この部位には装備できません。"
						elif s.equipment[slot]!="" and s.inventory.size()>=15: error="外す装備の戻り先が必要です。"
						else:
							if s.equipment[slot]!="": s.inventory.append(s.equipment[slot])
							var uid: String=Instances.install(s,r.id,r.profile); s.inventory.erase(uid); s.equipment[slot]=uid
							if r.get("guaranteed",false): s.records.first_reward_claimed=true
							changed=true
					elif error=="":
						if receive(s,r): changed=true
						else: error="バッグに入りきりません。"
					if changed:
						s.pending_rewards.remove_at(index)
						if s.pending_rewards.is_empty() and s.floor%5==0: s.phase="portal_done"
		"abandon_rewards":
			if s.phase=="reward" and args.get("confirmed",false):
				if s.pending_rewards.any(func(r):return r.get("guaranteed",false)): error="初突破の保証装備は放棄できません。整理・装備・入替で受け取ってください。"
				else: s.pending_rewards=[]; changed=true
		"journey_event":
			if s.phase=="event":
				for choice in cfg.progression.events[s.event].choices:
					if choice.id!=args.get("choice",""): continue
					error=event_reason(s,choice,args,cfg)
					if error=="": resolve_event(s,choice,args,cfg); changed=true
		"event_target":
			if s.phase=="event" and s.items.has(args.get("uid","")): s.event_target=args.uid; changed=true
		"continue_event":
			if s.phase=="event_result": s.phase="reward" if not s.pending_rewards.is_empty() else ("portal_done" if s.floor%5==0 else "explore"); s.reward_origin="イベントの獲得品"; changed=true
		"town":
			if s.phase=="result": s.phase="town"; s.floor=0; s.node={}; changed=true
		"supply":
			if s.phase=="town":
				for slot in cfg.initial.equipment:
					var id: String=cfg.initial.equipment[slot]
					if s.equipment[slot]=="" and not id in s.items.values():
						var uid: String=Instances.install(s,id,Instances.roll(s,id,"supply")); s.inventory.erase(uid); s.equipment[slot]=uid; changed=true
				if not changed: error="不足部位がないか、同じ支給品を所持しています。風呂敷内も受領済みです。"
		"buy_remedy":
			if s.phase=="town" or (s.floor==5 and s.phase in ["portal","portal_done"]):
				var id: String=args.get("id","")
				if not id in ["RB","RP","RM"]: error="対策品を選んでください。"
				elif not Money.pay(s,int(cfg.items[id].price),args.get("source",s.payment_source)): error="選んだ収納のコインが不足しています。"
				elif s.inventory.size()>=15: error="薬を受け取るバッグの空きが必要です。"
				else: Instances.install(s,id,Instances.roll(s,id,"shop")); changed=true
		"auto_remedy":
			if s.phase!="battle" and args.get("status","") in s.auto_remedy: s.auto_remedy[args.status]=not s.auto_remedy[args.status]; changed=true
		"payment_source":
			if args.get("source","") in (["inventory","cloth","warehouse"] if s.phase=="town" else ["inventory","cloth"]): s.payment_source=args.source; changed=true
		"seal":
			if s.phase=="town":
				var uid: String=args.get("uid",""); var status: String=args.get("status","")
				if not s.items.has(uid) or status not in cfg.progression.seals or s.item_details[uid].seal_slots<1: error="印枠のある装備を選んでください。"
				elif s.item_details[uid].seals==[status]: error="同じ印が付いています。"
				else:
					var stones: Array=s.inventory.filter(func(k):return s.items[k]=="I10")
					if stones.is_empty(): error="バッグの補修石1個が必要です。"
					elif not Money.pay(s,2,args.get("source",s.payment_source)): error="選んだ収納のコイン2Gが必要です。"
					else: Instances.erase(s,stones[0]); s.item_details[uid].seals=[status]; changed=true
		"repair":
			if s.phase=="town":
				var uid: String=args.get("uid",""); var cost: int=e.Condition.cost(s,uid,cfg)
				if cost<=0: error="修理不要か修理対象外です。"
				elif not Money.pay(s,cost,args.get("source",s.payment_source)): error="選んだ収納のコインが不足しています。"
				else: s.item_condition[uid].current=100; changed=true
		"coin_split": changed=Money.split(s,args.get("uid",""),args.get("source","inventory"),int(args.get("quantity",0)))
		"coin_move": changed=Money.move(s,args.get("uid",""),args.get("source","inventory"),args.get("destination","warehouse"),int(args.get("quantity",-1)))
		"coin_combine": changed=Money.combine(s,args.get("source","inventory"))
		"transfer","deposit","withdraw","to_cloth":
			var source: String=args.get("source","warehouse" if action=="withdraw" else "inventory")
			var destination: String=args.get("destination",{"deposit":"warehouse","withdraw":"inventory","to_cloth":"cloth"}.get(action,"warehouse"))
			var uid: String=args.get("uid","")
			if s.phase!="town": error="収納移動は町で行います。"
			elif uid not in s.get(source,[]): error="移動する品を選んでください。"
			elif s.items[uid]=="C01": changed=Money.move(s,uid,source,destination)
			else:
				error=e.Storage.reason(s,uid,source,destination,cfg)
				if error=="": s[source].erase(uid); s[destination].append(uid); changed=true
		"organize","organize_bag":
			if s.phase!="battle":
				for source in (["inventory"] if action=="organize_bag" else ["inventory","cloth","warehouse"]): s[source].sort_custom(func(a,b):return e.Storage.sort_key(s,a,cfg,args.get("mode","category"))<e.Storage.sort_key(s,b,cfg,args.get("mode","category")))
				changed=s!=previous
		"equip","unequip":
			if s.phase not in ["battle","result"]:
				if action=="equip":
					var uid: String=args.get("uid","")
					if uid in s.inventory:
						var slot: String=cfg.items[s.items[uid]].slot
						if slot!="" and args.get("slot",slot)==slot:
							if s.equipment[slot]!="": s.inventory.append(s.equipment[slot])
							s.inventory.erase(uid); s.equipment[slot]=uid; changed=true
				else:
					var slot: String=args.get("slot","")
					if s.equipment.has(slot) and s.equipment[slot]!="" and s.inventory.size()<15: s.inventory.append(s.equipment[slot]); s.equipment[slot]=""; changed=true
		"debug_next":
			if s.debug and args.get("kind","") in ["enemy","treasure","event"]: s.debug_next=args.kind; changed=true
		"debug_return":
			if s.debug and s.phase!="town": finish(s,"return","デバッグ専用の帰還。通常の成果には混ぜない。"); changed=true
	if not changed: return {"state":previous,"error":error if error!="" else "今はこの操作を実行できません。"}
	if s.phase=="town":
		var h: Dictionary=e.hero(s,cfg); s.hp=h.max_hp; s.sp=h.max_sp
	elif s.phase!="battle" and s.phase!="result":
		var h: Dictionary=e.hero(s,cfg); s.hp=mini(s.hp,h.max_hp); s.sp=mini(s.sp,h.max_sp)
	s.revision+=1
	var problem: String=validate(s,data,cfg)
	return {"state":s,"error":""} if problem=="" else {"state":previous,"error":"操作を取り消しました："+problem}
static func validate(s: Dictionary, _data: Dictionary, cfg: Dictionary) -> String:
	if s.has("gold"): return "並行する財布は禁止"
	if s.inventory.size()>15 or s.cloth.size()>3: return "容量超過"
	var owned: Array=s.inventory+s.cloth+s.warehouse
	for slot in s.equipment:
		var uid: String=s.equipment[slot]
		if uid!="":
			if not s.items.has(uid) or cfg.items[s.items[uid]].slot!=slot: return "装備部位不正"
			owned.append(uid)
	var seen: Dictionary={}
	for uid in owned:
		if seen.has(uid) or not s.items.has(uid) or not s.item_details.has(uid) or not s.quantities.has(uid) or not s.item_condition.has(uid): return "個体の重複／欠落"
		seen[uid]=true
		if not cfg.items.has(s.items[uid]) or int(s.quantities[uid])<1 or int(s.quantities[uid])>(99 if s.items[uid]=="C01" else 1): return "数量不正"
		if s.item_condition[uid].current<0 or s.item_condition[uid].current>100: return "耐久不正"
	if seen.size()!=s.items.size() or s.item_details.size()!=seen.size() or s.quantities.size()!=seen.size() or s.item_condition.size()!=seen.size(): return "孤立個体"
	var tokens: Dictionary={}
	for r in s.pending_rewards:
		if tokens.has(r.token) or not cfg.items.has(r.id) or r.quantity<1 or not r.get("profile") is Dictionary: return "未受領品不正"
		tokens[r.token]=true
	if not s.phase in ["town","explore","portal","portal_done","battle","event","event_result","treasure","reward","result"]: return "状態不正"
	if s.phase=="battle" and (s.battle.is_empty() or not s.battle.has("current")): return "戦闘入力不足"
	var h: Dictionary=api().hero(s,cfg)
	if s.hp<0 or s.hp>h.max_hp or s.sp<0 or s.sp>h.max_sp or (s.hp==0 and s.phase!="result"): return "HP/SP範囲外"
	return ""
