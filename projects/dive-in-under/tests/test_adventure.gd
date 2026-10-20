extends SceneTree
const E=preload("res://core/expedition.gd")
const P=preload("res://core/adventure.gd")
const M=preload("res://core/currency.gd")
const I=preload("res://core/item_instances.gd")
var cfg: Dictionary
var data: Dictionary
var checks: int=0
func check(value: bool, message: String) -> void:
	if not value: push_error("ADVENTURE_CHECK: "+message); quit(1); return
	checks+=1
func act(s: Dictionary, name: String, args: Dictionary={}) -> Dictionary:
	return E.act(s,name,int(s.revision),args,data,cfg)
func _initialize() -> void:
	cfg=E.load_config(); data=E.Catalog.load_data()
	check(not cfg.is_empty(),"current config loads")
	var s: Dictionary=E.fresh(cfg,123)
	check(P.active(s) and s.phase=="town" and s.equipment.values().filter(func(v):return v!="").size()==5 and not s.has("gold"),"five supplied items and no wallet")
	check(E.validate(s,data,cfg)=="","fresh ownership valid")
	M.credit(s,150); check(M.amount(s)==150 and s.inventory.size()==2,"99 stacks")
	var uid: String=s.inventory[0]
	s=act(s,"coin_split",{"uid":uid,"source":"inventory","quantity":30});check(M.amount(s)==150 and s.inventory.size()==3,"split preserves value")
	s=act(s,"coin_combine",{"source":"inventory"});check(M.amount(s)==150 and s.inventory.size()==2,"combine preserves value")
	s=act(s,"coin_move",{"uid":s.inventory[0],"source":"inventory","destination":"cloth","quantity":40});check(M.amount(s,"cloth")==40 and M.amount(s)==110,"explicit partial move")
	check(not M.pay(s,111) and M.amount(s,"cloth")==40,"no implicit cloth payment")
	uid=E.add_item(s,"W02");var profile: Dictionary=s.item_details[uid].duplicate(true)
	s=act(s,"equip",{"uid":uid});s=act(s,"unequip",{"slot":"right_hand"});s=act(s,"organize_bag")
	check(s.item_details[uid]==profile,"roll fixed through equip and organize")
	var exp: int=s.exp; var bag_count: int=s.inventory.size();var protected: String=E.add_item(s,"B01");s.inventory.erase(protected);s.warehouse.append(protected)
	P.finish(s,"death","test death")
	check(s.inventory.is_empty() and s.equipment.values().all(func(v):return v=="") and s.items.has(protected) and M.amount(s,"cloth")==40 and s.exp==exp,"full death with protected storage and growth")
	s=act(s,"town");s=act(s,"supply");check(s.equipment.values().filter(func(v):return v!="").size()==5,"resupply enables retry")
	var cloak: String=s.equipment.head;s=act(s,"unequip",{"slot":"head"});s=act(s,"to_cloth",{"uid":cloak});var count: int=s.items.size();s=act(s,"supply");check(s.items.size()==count and s.equipment.head=="","cloth cannot duplicate supply")
	check(E.Storage.reason(s,cloak,"cloth","warehouse",cfg)!="","supplied warehouse blocked")
	var portal: Dictionary=E.fresh(cfg,456);portal=act(portal,"depart");portal.floor=4;portal.highest_floor=4
	portal=act(portal,"descend");check(portal.phase=="portal" and portal.floor==5 and portal.battle.is_empty(),"portal before encounter")
	var return_state: Dictionary=act(portal,"return_ready");check(return_state.phase=="result" and return_state.result.kind=="return","5F return")
	check(return_state.result.kept.any(func(t):return str(t).begins_with("装備：")),"return result explicitly lists retained equipment")
	portal=act(portal,"portal_stay");var node: Dictionary=portal.node.duplicate(true);var revision: int=portal.revision;portal=act(portal,"portal_stay");check(portal.node==node and portal.revision==revision,"portal stay cannot reroll")
	var ten: Dictionary=E.fresh(cfg,789);ten=act(ten,"depart");ten.floor=9;ten.highest_floor=9;ten=act(ten,"descend");ten=act(ten,"return_ready");check(ten.records.boss_kills==0 and not ten.records.first_reward_issued,"10F early return no clear")
	var early: Dictionary=E.fresh(cfg,1);early=act(early,"depart");early=act(early,"descend");check(act(early,"return_ready")==early,"ordinary floors cannot return")
	check(E.validate(return_state,data,cfg)=="" and E.validate(ten,data,cfg)=="","result states valid")
	safety_cases()
	event_cases()
	normal_loop()
	print("ADVENTURE_CORE_OK checks="+str(checks));quit()

func safety_cases() -> void:
	var s: Dictionary=E.fresh(cfg,77)
	M.credit(s,90)
	for n in 14: E.add_item(s,"I10")
	check(s.inventory.size()==15 and M.credit(s,9) and M.amount(s)==99,"full bag receives existing coin stack")
	var original: Dictionary=s.duplicate(true)
	check(not M.credit(s,1) and s==original,"overflow coins remain undelivered without partial mutation")
	P.reward(s,"C01",5);s.phase="reward";s.floor=2;s.node={"kind":"treasure","started":true,"resolved":true}
	check(act(s,"claim_all_advance")==s and s.pending_rewards.size()==1,"full reward transaction rolls back and remains pending")
	s=act(s,"exchange_reward",{"token":s.pending_rewards[0].token,"replace_uid":s.inventory[-1],"confirmed":true})
	check(M.amount(s)==104 and s.pending_rewards.is_empty() and s.inventory.size()==15,"explicit replacement can accept overflowing coins")
	var uid: String=E.add_item(s,"W01");s.inventory.erase(uid);s.warehouse.append(uid);s.phase="town"
	var profile: Dictionary=s.item_details[uid].duplicate(true);s.item_condition[uid].current=25
	M.credit(s,100,"warehouse");s=act(s,"repair",{"uid":uid,"source":"warehouse"})
	check(s.item_details[uid]==profile and s.item_condition[uid].current==100,"repair preserves individual roll and uses explicit town storage")
	var pre: Dictionary=E.fresh(cfg,8);var sword: String=E.add_item(pre,"W02");pre=act(pre,"equip",{"uid":sword});sword=pre.equipment.right_hand
	while pre.inventory.size()<15: E.add_item(pre,"I10")
	uid=pre.inventory.filter(func(k):return pre.items[k]=="A01")[0]
	var before_count: int=pre.items.size();pre=act(pre,"equip",{"uid":uid})
	check(pre.inventory.size()==15 and pre.equipment.right_hand==uid and pre.items.size()==before_count and sword in pre.inventory,"full one-to-one equipment exchange")
	check(act(pre,"unequip",{"slot":"right_hand"})==pre,"full bag unequip rejects atomically")
	var ward: Dictionary=E.fresh(cfg,10);M.credit(ward,12);E.add_item(ward,"I10")
	ward=act(ward,"seal",{"uid":ward.equipment.head,"status":"poison","source":"inventory"});ward=act(ward,"buy_remedy",{"id":"RP","source":"inventory"})
	var b: Dictionary=E.Combat.start(E.hero(ward,cfg),E.Combat.enemy(P.combat_data(data,cfg),"E04",2),P.combat_data(data,cfg).rules,1)
	E.Combat.apply_status(b,"enemy","hero","S102")
	check(b.log[-1].type=="status_prevented" and b.hero.remedies.size()==1,"seal takes priority and does not consume bag medicine")
	ward.item_condition[ward.equipment.head].current=0
	b=E.Combat.start(E.hero(ward,cfg),E.Combat.enemy(P.combat_data(data,cfg),"E04",2),P.combat_data(data,cfg).rules,1)
	E.Combat.apply_status(b,"enemy","hero","S102");var used: String=b.log[-1].uid
	check(b.log[-1].type=="remedy_used" and b.hero.remedies.is_empty() and b.hero.statuses.is_empty(),"broken seal falls back to exactly one medicine")
	I.erase(ward,used);check(ward.inventory.filter(func(k):return ward.items[k]=="RP").is_empty(),"consumed medicine removed from real bag")
	E.Combat.apply_status(b,"enemy","hero","S102");check(b.hero.statuses.has("poison"),"medicine has no free repeat use")
	var rules: Dictionary=P.combat_data(data,cfg).rules
	b=E.Combat.start(E.hero(E.fresh(cfg,1),cfg),E.Combat.enemy(P.combat_data(data,cfg),"B10",3),rules,20)
	b.enemy.ai_phase=1;var rng:=RandomNumberGenerator.new();rng.seed=1
	check(E.Combat.boss_move(b,"enemy",rng).get("skip",false) and b.enemy.ai_phase==2,"boss telegraph phase")
	b.hero.action_count=1;var sp: int=b.hero.sp;check(E.Combat.use_defense(b,"hero") and b.hero.sp==sp-2,"defense uses one action only against warned heavy")
	check(E.Combat.boss_move(b,"enemy",rng).multiplier==1.8 and b.enemy.ai_phase==3,"boss heavy follows telegraph")
	check(E.Combat.boss_move(b,"enemy",rng).get("skip",false) and b.enemy.ai_phase==0,"boss opening")
	b.enemy.ai_phase=1;b.enemy.sp=0;check(not E.Combat.boss_move(b,"enemy",rng).get("skip",false) and b.enemy.ai_phase==3,"boss insufficient SP uses visible ordinary fallback")
	b.enemy.ai_phase=0;b.hero.defense_until=-1;b.hero.cooldown_until=0;b.hero.action_count=10;b.hero.hp=1
	check(not E.Combat.use_defense(b,"hero"),"low HP alone does not waste defense action")
	var full: Dictionary=E.fresh(cfg,1);full.phase="reward";full.floor=10;full.node={"kind":"boss","started":true,"resolved":true}
	for n in 15:E.add_item(full,"I10")
	P.reward(full,"G10",1,"first-clear",true);var token: String=full.pending_rewards[0].token
	check(act(full,"abandon_rewards",{"confirmed":true})==full and act(full,"claim_reward",{"token":token})==full,"first guarantee remains pending when full and cannot be discarded")
	full=act(full,"equip_reward",{"token":token})
	check(full.items[full.equipment.finger]=="G10" and full.records.first_reward_claimed and full.phase=="portal_done","full bag guarantee may equip an empty slot and stops at portal")
	check(act(full,"equip_reward",{"token":token})==full,"guarantee cannot be received twice")
	P.finish(full,"death","fixture");check(not "G10" in full.items.values(),"dedicated equipment has no death exemption")
	for kind in ["event","treasure","enemy"]:
		var d: Dictionary=E.fresh(cfg,66);d.debug=true;d=act(d,"depart");d.floor=9;d.highest_floor=9;d=act(d,"debug_next",{"kind":kind});d=act(d,"descend");d=act(d,"portal_stay")
		check(d.node.kind==kind and d.debug_next=="" and d.records.boss_kills==0 and not d.records.first_reward_issued,"debug 10F actual kind "+kind)
		check(d.phase=={"event":"event","treasure":"treasure","enemy":"battle"}[kind],"debug generated phase agrees "+kind)
		d=act(d,"debug_return");var frozen: Dictionary=d.duplicate(true);d=act(d,"round");check(d==frozen and d.phase=="result","debug return cancels late battle/reward")
	var normal: Dictionary=E.fresh(cfg,66);normal=act(normal,"depart");check(act(normal,"debug_return")==normal and act(normal,"debug_next",{"kind":"event"})==normal,"normal session cannot use debug bypass")
	var ev: Dictionary=E.fresh(cfg,4);ev=act(ev,"depart");ev.floor=7;ev.node={"kind":"event","started":true,"resolved":false};ev.phase="event";ev.event="EV14";ev.item_condition[ev.equipment.head].current=30
	var c: Dictionary=cfg.progression.events.EV14.choices[0]
	check(act(ev,"journey_event",{"choice":c.id,"uid":ev.equipment.head})==ev,"unaffordable event leaves cost and effect unchanged")
	M.credit(ev,4);ev=act(ev,"journey_event",{"choice":c.id,"uid":ev.equipment.head});check("バッグ" in ev.event_result.text and not "inventory" in ev.event_result.text,"event names the payment storage in readable Japanese")
	check(ev.phase=="event_result" and M.amount(ev)==0 and ev.item_condition[ev.equipment.head].current==100,"event payment and repair commit together")
	check(act(ev,"journey_event",{"choice":c.id})==ev,"event cannot apply twice")
func gear_score(s: Dictionary, uid: String) -> int:
	var value: Dictionary=E.Condition.stats(s,uid,cfg)
	return int(value.get("atk",0))*3+int(value.get("def",0))*2+int(value.get("spd",0))+int(value.get("max_hp",0))
func improve(s: Dictionary) -> Dictionary:
	for uid in s.inventory.duplicate():
		if not s.items.has(uid):continue
		var slot: String=cfg.items[s.items[uid]].slot
		if slot!="" and (s.equipment[slot]=="" or gear_score(s,uid)>gear_score(s,s.equipment[slot])):s=route_act(s,"equip",{"uid":uid})
	return s
var route: Array=[]
func route_act(s: Dictionary, name: String, args: Dictionary={}) -> Dictionary:
	var next: Dictionary=act(s,name,args)
	if next!=s:route.append({"action":name,"args":args,"floor":next.floor,"phase":next.phase,"exp":next.exp,"revision":next.revision})
	return next
func normal_loop() -> void:
	var s: Dictionary=E.fresh(cfg,10000);var summary: Array=[];var early_ten: bool=false;var first: bool=false;var repeat: bool=false;var death: bool=false;var five_return: bool=false;var five_stay: bool=false
	for trip in 12:
		if s.phase=="result":
			death=death or s.result.kind=="death";s=route_act(s,"town")
		s=route_act(s,"supply")
		for slot in E.SLOTS:
			var best: String=s.equipment[slot]
			for uid in s.warehouse:
				if cfg.items[s.items[uid]].slot==slot and (best=="" or gear_score(s,uid)>gear_score(s,best)):best=uid
			if best in s.warehouse:s=route_act(s,"transfer",{"uid":best,"source":"warehouse","destination":"inventory"});s=route_act(s,"equip",{"uid":best})
		s=improve(s)
		for uid in s.inventory.duplicate():
			if not s.item_details[uid].supply:s=route_act(s,"transfer",{"uid":uid,"source":"inventory","destination":"warehouse"})
		for id in ["RB","RP","RM"]:s=route_act(s,"buy_remedy",{"id":id,"source":"warehouse"})
		s=route_act(s,"depart");s=route_act(s,"descend")
		for step in 220:
			if s.phase=="result":break
			s=improve(s) if s.phase!="battle" else s
			match s.phase:
				"battle":s=route_act(s,"round")
				"treasure":s=route_act(s,"open_chest")
				"reward","event_result":
					if not P.fits(s,s.pending_rewards):
						for r in s.pending_rewards.duplicate():
							if cfg.items[r.id].slot!="":s=route_act(s,"equip_reward",{"token":r.token})
						if not P.fits(s,s.pending_rewards):
							var target: String=""
							for uid in s.inventory:
								if not s.item_details[uid].supply and s.items[uid]!="C01":target=uid;break
							if target!="" and not s.pending_rewards.is_empty():s=route_act(s,"exchange_reward",{"token":s.pending_rewards[0].token,"replace_uid":target,"confirmed":true})
					s=route_act(s,"claim_all_advance" if not s.pending_rewards.is_empty() else "advance_ready")
				"event":
					var chosen: String="leave"
					for choice in cfg.progression.events[s.event].choices:
						if choice.cost.is_empty() and not choice.ops.is_empty():chosen=choice.id;break
					s=route_act(s,"journey_event",{"choice":chosen})
				"portal":
					if s.floor==5 and trip==0:five_return=true;s=route_act(s,"return_ready")
					elif s.floor==10 and not early_ten:early_ten=true;s=route_act(s,"return_ready")
					else:five_stay=five_stay or s.floor==5;s=route_act(s,"portal_stay")
				"portal_done":s=route_act(s,"portal_continue")
				"explore":s=route_act(s,"descend")
			first=first or s.records.first_reward_claimed;repeat=repeat or s.records.boss_kills>=2
		summary.append({"trip":trip+1,"floor":s.floor,"kind":s.result.get("kind",""),"level":E.hero(s,cfg).level,"exp":s.exp,"kills":s.records.boss_kills})
		if repeat:break
	print("ADVENTURE_NORMAL_SUMMARY "+JSON.stringify(summary))
	var proof: Dictionary={"seed":10000,"normal_tables":true,"no_stat_injection":true,"five_return":five_return,"five_stay":five_stay,"ten_early_return":early_ten,"death_retry":death,"first_reward":first,"repeat":repeat,"summary":summary,"actions":route,"checks":checks}
	DirAccess.make_dir_recursive_absolute("res://artifacts/adventure")
	var file:=FileAccess.open("res://artifacts/adventure/normal-plan.json",FileAccess.WRITE);file.store_string(JSON.stringify(proof,"  "));file.close()
	check(five_return and five_stay and early_ten and first and repeat,"bounded normal route reaches return, first clear and repeat without stat injection")

func event_state(id: String) -> Dictionary:
	var s: Dictionary=E.fresh(cfg,42);s=act(s,"depart");s.floor=7;s.highest_floor=7;s.phase="event";s.event=id;s.node={"kind":"event","started":true,"resolved":false}
	return s
func event_cases() -> void:
	var s: Dictionary=event_state("EV11");s=act(s,"journey_event",{"choice":"take"})
	check(s.phase=="event_result" and s.pending_rewards.size()==1 and s.pending_rewards[0].quantity==5,"free coin event creates pending physical coins")
	s=event_state("EV12");s=act(s,"journey_event",{"choice":"stone"});check(s.pending_rewards.size()==1 and s.pending_rewards[0].id=="I10","benefit choice gives stone only")
	s=event_state("EV12");s=act(s,"journey_event",{"choice":"coin"});check(s.pending_rewards.size()==1 and s.pending_rewards[0].quantity==7,"alternative choice gives coin only")
	s=event_state("EV15");var stone: String=E.add_item(s,"I10");s=act(s,"journey_event",{"choice":"defense"});check(not s.items.has(stone) and s.pending_rewards.size()==1 and s.pending_rewards[0].id=="W03","material exchange consumes actual non-supply item")
	s=event_state("EV18");var before: Dictionary=s.duplicate(true);s=act(s,"journey_event",{"choice":"wear","uid":s.equipment.head});check(s==before,"supply cannot fund durability event")
	var gear: String=E.add_item(s,"W02");var profile: Dictionary=s.item_details[gear].duplicate(true);s=act(s,"journey_event",{"choice":"wear","uid":gear});check(s.item_condition[gear].current==85 and s.item_details[gear]==profile and s.pending_rewards[0].id=="B02","durability event preserves roll and pays once")
	s=event_state("EV18");var hp: int=s.hp;s=act(s,"journey_event",{"choice":"hp"});check(s.hp==hp-4 and s.pending_rewards[0].id=="B01","HP trade leaves explicit pending equipment")
	s=event_state("EV18");s.hp=4;check(act(s,"journey_event",{"choice":"hp"})==s,"HP cost cannot silently kill")
	s=event_state("EV13");hp=s.hp;s=act(s,"journey_event",{"choice":"dive"});var count: int=s.pending_rewards.size();check(s.hp==hp-4 and count in [0,1] and (count==0 or s.pending_rewards[0].id=="W02"),"probability event cost and one outcome commit together")
	check(act(s,"journey_event",{"choice":"dive"})==s,"chance event cannot reroll on replay")
	s=E.fresh(cfg,12);s=act(s,"depart");s.phase="explore";s.floor=1;s.highest_floor=1;s.hp=12
	gear=E.add_item(s,"B01");s.item_details[gear].affix_id="stout";s.item_details[gear].affix_stats={"max_hp":2};hp=s.hp
	s=act(s,"equip",{"uid":gear});s=act(s,"unequip",{"slot":"body"});check(s.hp==hp,"HP equipment exchange never heals during expedition")
	var rules: Dictionary=P.combat_data(data,cfg).rules
	var b: Dictionary=E.Combat.start(E.hero(E.fresh(cfg,1),cfg),E.Combat.enemy(P.combat_data(data,cfg),"B10",3),rules,20)
	b.enemy.ai_pattern.normal_weights={"attack":1,"strong":0};b.enemy.ai_pattern.low_weights={"attack":0,"strong":1};b.enemy.action_count=1
	var rng:=RandomNumberGenerator.new();rng.seed=1;var sp: int=b.enemy.sp
	check(E.Combat.boss_move(b,"enemy",rng).multiplier==1.0 and b.enemy.sp==sp,"boss high HP follows ordinary weight branch")
	b.enemy.ai_phase=0;b.enemy.hp=1;b.enemy.action_count=2
	check(E.Combat.boss_move(b,"enemy",rng).multiplier==1.3 and b.enemy.sp==sp-3,"boss low HP follows strong weight branch")
	b.enemy.ai_phase=0;b.enemy.action_count=3
	check(E.Combat.boss_move(b,"enemy",rng).multiplier==1.0 and b.enemy.sp==sp-3,"boss cooldown blocks immediate repeated strong")
