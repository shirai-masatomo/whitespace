extends SceneTree
const E=preload("res://core/expedition.gd")
const C=preload("res://core/combat.gd")
const P=preload("res://core/adventure.gd")
const M=preload("res://core/currency.gd")
const I=preload("res://core/item_instances.gd")
const T=preload("res://core/tactics.gd")
const S=preload("res://core/squad_combat.gd")
var cfg: Dictionary
var data: Dictionary
var checks: int=0
var evidence: Dictionary={"complete":false,"cases":[],"order":[],"unverified":["human gameplay quality","all 10F balance seeds"]}
func check(ok: bool, name: String) -> void:
	checks+=1
	if not ok: push_error("TACTICS_FAIL: "+name); quit(1); assert(false,name)
	evidence.cases.append(name)
func act(s: Dictionary, name: String, args: Dictionary={}) -> Dictionary:
	return E.act(s,name,int(s.revision),args,data,cfg)
func unit(id: String, speed: int, rank: String="front") -> Dictionary:
	return {"battle_id":id,"id":id,"name":id,"level":1,"hp":10000,"max_hp":10000,"sp":10,"max_sp":10,"atk":1,"def":100,"spd":speed,"skills":["S101","S105"],"rank":rank}
func strategy(ids: Array) -> Dictionary:
	var value: Dictionary={"id":"fixture","name":"指定順の検証","favorite":true,"order":ids.duplicate(),"characters":{}}
	for id in ids: value.characters[id]={"rank":"front","rows":[{"skill":"attack","conditions":[],"target":"enemy_front"}]}
	return value
func _init() -> void:
	cfg=E.load_config();data=P.combat_data(preload("res://core/catalog.gd").load_data(),cfg)
	currency();portals_supply();profiles();medicine();battle_cases();book_cases()
	evidence.complete=true;evidence.checks=checks
	DirAccess.make_dir_recursive_absolute("res://artifacts/tactics")
	var f:=FileAccess.open("res://artifacts/tactics/core.json",FileAccess.WRITE);f.store_string(JSON.stringify(evidence,"  "));f.close()
	print("TACTICS_CORE_OK checks="+str(checks));quit()
func currency() -> void:
	var s: Dictionary=E.fresh(cfg,1);check(M.credit(s,1000) and s.inventory.size()==2 and M.amount(s)==1000,"1000 coins become 999 + 1")
	check(s.quantities[s.inventory[0]]==999 and s.quantities[s.inventory[1]]==1,"999 boundary quantities")
	var uid: String=s.inventory[0];check(M.split(s,uid,"inventory",499) and M.amount(s)==1000,"split preserves 1000")
	check(M.combine(s,"inventory") and s.inventory.size()==2 and M.amount(s)==1000,"combine capped at 999")
	check(M.move(s,s.inventory[0],"inventory","cloth") and M.amount(s,"cloth")==999,"physical coins protected in cloth")
	check(M.move(s,s.cloth[0],"cloth","warehouse",400) and M.amount(s,"cloth")==599 and M.amount(s,"warehouse")==400,"partial move across storage")
	check(E.validate(s,data,cfg)=="","storage ownership and quantities valid")
	s=E.fresh(cfg,2);M.credit(s,998)
	for n in 14:E.add_item(s,"I10")
	check(M.credit(s,1) and M.amount(s)==999 and s.inventory.size()==15,"full bag receives to cap")
	var before: Dictionary=s.duplicate(true)
	check(not M.credit(s,1) and s==before,"full bag overflow atomic no loss")
	P.reward(s,"C01",2);s.phase="reward";s.floor=2;s.node={"resolved":true,"started":true,"kind":"treasure"};before=s.duplicate(true)
	check(act(s,"claim_all_advance")==before and s.pending_rewards.size()==1,"unreceived overflow retained")
func portals_supply() -> void:
	var s: Dictionary=E.fresh(cfg,12)
	check(s.equipment.left_hand!="" and s.equipment.feet=="" and s.items.size()==5,"starter sword shield body legs head; no sixth slot")
	check(s.items[s.equipment.head]=="A02" and s.items[s.equipment.left_hand]=="A06","cloak remains head and shield left hand")
	var cloth: String=s.equipment.head;s.equipment.head="";s.cloth.append(cloth);P.finish(s,"death","fixture");s=act(s,"town");s=act(s,"supply")
	check(s.items.size()==5 and s.equipment.head=="" and cloth in s.cloth,"resupply preserves cloth and cannot duplicate owned cloak")
	s=E.fresh(cfg,1);s=act(s,"depart");s.floor=4;s.phase="explore";s=act(s,"descend")
	check(s.floor==5 and s.phase=="portal" and P.can_return(s),"5F return offered before actual encounter")
	check(act(s,"return_ready").phase=="result","5F pre-stay return")
	s=act(s,"portal_stay");check(s.node.stayed and not P.can_return(s),"5F stay locks return")
	check(P.next_return_floor(s)==10,"next return map changes to 10F after staying")
	# All post-event phases must share the lock, no alternate return action bypass.
	for phase in ["portal_done","reward","event_result","explore"]:
		var resolved: Dictionary=s.duplicate(true);resolved.phase=phase;resolved.node.resolved=true;resolved.pending_rewards=[];resolved.battle={}
		check(not P.can_return(resolved) and act(resolved,"return_ready")==resolved,"5F no return after resolution "+phase)
	var ten: Dictionary=E.fresh(cfg,3);ten=act(ten,"depart");ten.floor=9;ten.phase="explore";ten=act(ten,"descend")
	check(ten.phase=="portal" and P.can_return(ten) and not ten.records.first_reward_issued,"10F preboss return retained")
	var processed: Dictionary=E.fresh(cfg,4);M.credit(processed,20);E.add_item(processed,"I10")
	check(act(processed,"seal",{"uid":processed.equipment.head,"status":"poison"})==processed,"unapproved paid processing inaccessible")
func profiles() -> void:
	var s: Dictionary=E.fresh(cfg,20);var values: Array=[]
	for n in 8:
		var uid: String=E.add_item(s,"W02");var d: Dictionary=s.item_details[uid]
		check(d.base_roll==cfg.items.W02.stats and d.has("special_effects") and d.has("granted_skills") and d.rarity.status=="unrated","fixed kind base and separate effect profile "+str(n));values.append(uid)
	var uid: String=values[0];var original: Dictionary=s.item_details[uid].duplicate(true)
	s=act(s,"equip",{"uid":uid});s=act(s,"organize_bag");s.item_condition[uid].current=80;M.credit(s,20);s=act(s,"repair",{"uid":uid})
	check(s.item_details[uid]==original and s.item_condition[uid].current==100,"equip sort repair never reroll profile")
func medicine() -> void:
	var s: Dictionary=E.fresh(cfg,7);M.credit(s,4);s=act(s,"buy_remedy",{"id":"RP"});var h: Dictionary=E.hero(s,cfg);h.spd=100;h.hp=10
	var b: Dictionary=C.start(h,C.enemy(data,"E04",2),data.rules,10,T.active(s.tactics));C.apply_status(b,"enemy","hero","S102")
	check(b.hero.statuses.has("poison") and b.hero.cures.size()==1,"antidote does not prevent application")
	b=C.advance(b)
	check(not b.hero.statuses.has("poison") and b.hero.hp==13 and b.hero.cures.is_empty(),"antidote cures heals three before poison damage")
	check(b.log.any(func(e):return e.type=="attack" and e.actor=="hero") and not b.log.any(func(e):return e.type=="status_damage" and e.actor=="hero"),"normal action still occurs after cure")
	var used: Array=b.log.filter(func(e):return e.type=="remedy_used");check(used.size()==1 and used[0].healing==3,"one real medicine UID consumed")
	var clean: Dictionary=C.start(h,C.enemy(data,"E04",2),data.rules,11,T.active(s.tactics));clean=C.advance(clean);check(clean.hero.cures.size()==1,"no poison means no consumption")
	b=C.start(h,C.enemy(data,"E04",2),data.rules,12,T.active(s.tactics));C.apply_status(b,"enemy","hero","S102");C.apply_status(b,"enemy","hero","S104");b=C.advance(b)
	check(not b.hero.statuses.has("poison") and b.hero.hp==13 and b.hero.action_count==1 and not b.log.any(func(e):return e.type=="attack" and e.actor=="hero"),"paralysis permits cure but still blocks attack and consumes opportunity")
	var uid: String=s.inventory.filter(func(k):return s.items[k]=="RP")[0];s.inventory.erase(uid);s.cloth.append(uid)
	check(E.hero(s,cfg).cures.is_empty(),"cloth medicine protected, not silently consumed")
func battle_cases() -> void:
	var st: Dictionary=strategy(["B","A","C"]);var b: Dictionary=S.start([unit("A",10),unit("B",20),unit("C",30)],[unit("O",5),unit("P",15),unit("Q",25)],data.rules,5,st);var order: Array=[]
	for n in 6:
		var before: int=b.log.size();b=S.advance(b)
		for event in b.log.slice(before):
			if event.type=="opportunity":order.append(event.actor)
	check(order==["Q","B","P","A","C","O"],"required Q B P A C O order");evidence.order=order
	check(b.round==1 and b.acted.size()==6 and b.units.values().all(func(u):return u.action_count==1),"all six units act once, no ally block")
	b=S.start([unit("A",10),unit("B",20),unit("C",30)],[unit("O",5),unit("P",15),unit("Q",25)],data.rules,5,st);b=S.advance(b);b=S.advance(b)
	var acted: Array=b.acted.duplicate();var switched: Dictionary=st.duplicate(true);switched.order=["C","B","A"]
	check(S.switch(b,switched) and b.acted==acted,"midround switch preserves acted ledger")
	b=S.advance(b);check(b.acted[-1]=="C" and b.units.B.action_count==1,"new order only among unacted; B cannot re-act")
	for n in 3:b=S.advance(b)
	check(b.round==1 and b.units.values().all(func(u):return u.action_count==1),"switch never resets round or grants extra action")
	var rows: Array=[{"skill":"attack","conditions":[{"kind":"hp_below","value":1}],"target":"enemy_front"},{"skill":"S101","conditions":[],"target":"enemy_front"},{"skill":"attack","conditions":[],"target":"enemy_back"},{"skill":"attack","conditions":[],"target":"enemy_front"}]
	st=strategy(["A"]);st.characters.A.rows=rows;b=S.start([unit("A",99)],[unit("F",1),unit("R",1,"back")],data.rules,8,st);b.units.A.sp=0;b.units.A.action_count=1
	var decision: Dictionary=S.decide(b,"A")
	check(decision.row==3 and decision.target=="F" and decision.skipped.size()==3,"condition SP range failure skips to next valid row")
	check("条件不成立" in decision.skipped[0] and "SP不足" in decision.skipped[1] and "射程内" in decision.skipped[2],"failure reasons readable")
	b.units.F.hp=0;decision=S.decide(b,"A");check(decision.target=="R","back reachable when no living front")
	b.units.A.sp=10;b.units.A.skill_cooldowns.S101=4;decision=S.decide(b,"A");check(decision.skipped.any(func(v):return "クールダウン" in v),"cooldown skip")
	st.characters.A.rows=[];b.strategy=st;decision=S.decide(b,"A");check(decision.skill=="attack","all rows fail defaults normal attack")
	b.rules.tactics_ranges.attack="none";check(S.decide(b,"A").skill=="wait","no reachable fallback waits");check(S.targets(b,"A","enemy_back","self").is_empty(),"target choice cannot bypass self range")
	b.units.A.hp=0;check(S.candidates(b).all(func(id):return id!="A"),"dead ally excluded")
	var defender: Dictionary=E.hero(E.fresh(cfg,5),cfg);defender.hp=defender.max_hp;defender.spd=100
	var boss: Dictionary=C.enemy(data,"B10",3);boss.spd=1
	var guard: Dictionary=C.start(defender,boss,data.rules,9,T.default_set("defense",true));guard.units.enemy.ai_phase=2;S.sync(guard)
	guard=C.advance(guard);check(guard.units.hero.last_decision.skill=="S105" and guard.units.hero.sp==defender.sp-2 and not guard.log.any(func(e):return e.type=="attack" and e.actor=="hero"),"strategy defense spends own action instead of attacking")
	guard=C.advance(guard);check(guard.units.enemy.last_decision.label=="強打" and guard.units.enemy.sp==boss.sp-4,"boss actual pattern action and SP match displayed decision")
	var lethal_rules: Dictionary=data.rules.duplicate(true);lethal_rules.hit_chance=1.0
	var o: Dictionary=unit("O",1);o.hp=1;o.exp=2;o.gold=3
	var p: Dictionary=unit("P",2);p.hp=1;p.exp=4;p.gold=5
	var multiple: Dictionary=S.start([unit("A",99),unit("B",90)],[o,p],lethal_rules,3,strategy(["A","B"]))
	multiple=S.advance(multiple);check(multiple.outcome=="ongoing" and multiple.units.O.hp==0,"first enemy defeat does not end multi-enemy battle")
	multiple=S.advance(multiple);check(multiple.outcome=="victory" and multiple.reward.exp==6 and multiple.reward.gold==8,"all enemies defeated then aggregate actual rewards once")
func book_cases() -> void:
	var book: Dictionary=T.initial();var value: Dictionary=T.default_set("custom");value.name="試遊作戦";value.favorite=false
	check(T.save(book,value)=="" and T.select(book,"custom") and T.active(book).name=="試遊作戦","named squad save select and favorite field")
	value.name="変更";check(T.active(book).name=="試遊作戦","saved assets copied, not shared editor references")
	for n in 5:check(T.save(book,T.default_set("set"+str(n)))=="","save slot "+str(n))
	check(T.save(book,T.default_set("overflow"))!="" and book.sets.size()==8,"eight set limit")
	value=T.default_set();value.characters.hero.rows=[]
	for n in 9:value.characters.hero.rows.append({"skill":"attack","conditions":[],"target":"enemy_front"})
	check(T.validate(value)!="","eight row limit validated in core")
	check(T.initial().sets.size()==2,"fresh session resets strategy storage")
	var session: Dictionary=E.fresh(cfg,40);var set_value: Dictionary=T.default_set("session-test");set_value.name="保存と適用"
	session=act(session,"tactic_save",{"value":set_value,"apply":true});check(T.active(session.tactics).name=="保存と適用","public transaction saves and selects")
	session=act(session,"depart");session=act(session,"descend");session=act(session,"round")
	var before_acted: Array=session.battle.current.acted.duplicate();var counts: Array=session.battle.current.units.values().map(func(u):return u.action_count)
	session=act(session,"tactic_select",{"id":"defense"});check(session.battle.current.acted==before_acted and session.battle.current.units.values().map(func(u):return u.action_count)==counts,"public switch consumes no extra action and resets no ledger")
	var st: Dictionary=strategy(["A","B"]);var one: Dictionary=S.start([unit("A",10),unit("B",30)],[unit("O",20)],data.rules,5,st)
	one=S.advance(one);one.units.B.spd=40;one=S.advance(one);check(one.acted==["O","A"],"faster waiting ally remains gated by specified head")
	one=S.advance(one);check(one.acted==["O","A","B"],"speed re-evaluation does not break order")
	var tie: Dictionary=S.start([unit("A",10)],[unit("O",10)],data.rules,9,strategy(["A"]))
	check(S.advance(tie).acted==S.advance(tie).acted,"same-speed choice deterministic for same seed")
