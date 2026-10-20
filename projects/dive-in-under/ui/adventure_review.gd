extends RefCounted
## Actual exported EXE: first normal 5F trip, then explicitly labelled targeted fixtures.
const E=preload("res://core/expedition.gd")
const P=preload("res://core/adventure.gd")
const M=preload("res://core/currency.gd")
const F=preload("res://ui/flow_review.gd")
const UI=preload("res://ui/integration_review.gd")
const Replay=preload("res://ui/campaign_replay.gd")
static func check(game: Control, value: bool, message: String) -> bool:return game.smoke_check(value,message)
static func shot(game: Control, name: String) -> void:
	await F.wait(game,.12);await game.capture(name+".png")
static func settled(game: Control, seconds: float=25.0) -> void:
	var end: int=Time.get_ticks_msec()+int(seconds*1000)
	while Time.get_ticks_msec()<end and (game.campaign.phase=="battle" or game.presenting or game.intro_active):await F.wait(game,.08)
	check(game,game.campaign.phase!="battle" and not game.presenting and not game.intro_active,"Bounded battle resolves normally")
static func reset(game: Control, state: Dictionary, debug: bool=false) -> void:
	await F.wait(game,.3)
	game.play_timer.stop();game.cancel_presentation();game.intro_active=false;game.intro_seen={};game.field_equipment=false;game.field_status=false;game.route_map_open=false;game.service_mode="";game.modal_owner=null;game.reward_confirmation="";game.town_page="hub";game.flow_selection={"kind":"actor","side":"hero"};game.flow_memory={};game.debug_run=debug;state.debug=debug;game.campaign=state;game.auto_play=false;game.notice="限定確認用の準備データ（通常一周の画像とは区別）";game.show_campaign();await F.wait(game)
static func service(game: Control, name: String, args: Dictionary={}) -> void:
	await F.wait(game)
	var b: Button=find_service(game.screen,name,args)
	if not check(game,b!=null and not b.disabled,"Enabled service "+name):return
	await game.click_control(b);await F.wait(game,.15)
static func find_service(node: Node, name: String, args: Dictionary) -> Button:
	if node is Button and node.get_meta("service_action","")==name:
		var actual: Dictionary=node.get_meta("service_args",{});var match_args: bool=true
		for k in args:match_args=match_args and actual.get(k)==args[k]
		if match_args:return node
	for child in node.get_children():
		var b:=find_service(child,name,args)
		if b:return b
	return null
static func run(game: Control) -> void:
	if not check(game,DisplayServer.get_name()!="headless" and game.save_store==null and game.campaign.is_empty() and not game.debug_run,"Actual normal entry, no SaveStore"):return
	await shot(game,"00-title")
	await F.nav(game,"start");await shot(game,"01-normal-preparation")
	await F.nav(game,"services");await shot(game,"02-preparation-services");await F.key(game,KEY_ESCAPE)
	await F.key(game,KEY_E)
	await F.key(game,KEY_SPACE);await F.wait(game,.8)
	if not check(game,game.campaign.floor==1 and game.campaign.phase=="battle" and not game.auto_play,"Normal first encounter can pause"):return
	var frozen: String=Replay.hash_state(game.campaign);await F.wait(game,.7)
	if not check(game,Replay.hash_state(game.campaign)==frozen,"Pause preserves HP, rounds and reward"):return
	await shot(game,"03-normal-battle")
	await F.key(game,KEY_C);await F.wait(game,.25);await shot(game,"04-normal-status")
	await game.click_control(game.status_view.back_button);await F.wait(game,.4);await F.key(game,KEY_SPACE);await settled(game)
	await F.key(game,KEY_E)
	if not check(game,game.campaign.floor==2 and game.campaign.phase=="treasure","Normal 2F chest"):return
	await F.key(game,KEY_E);await shot(game,"05-normal-chest-reward")
	await F.key(game,KEY_E)
	if not check(game,game.campaign.floor==3 and game.campaign.phase=="event","Normal 3F event"):return
	var event: Dictionary=game.cfg.journey.events[game.campaign.event];var id: String=event.choices[0].id
	for choice in event.choices:
		if choice.cost.is_empty() and not choice.ops.is_empty():id=choice.id;break
	if preload("res://ui/event_choices.gd").simple(event):await F.key(game,KEY_E)
	else:await F.nav(game,"choice-"+id)
	await shot(game,"06-normal-event-result");await F.key(game,KEY_E)
	if game.campaign.phase=="event_result":await F.key(game,KEY_E)
	await settled(game);await F.key(game,KEY_E)
	if not check(game,game.campaign.floor==5 and game.campaign.phase=="portal" and game.campaign.battle.is_empty(),"Normal 5F portal precedes encounter"):return
	await shot(game,"07-normal-5f-portal");await F.command(game,"return_ready");await shot(game,"08-normal-first-return");await F.command(game,"town")
	# Currency quantity UI, protected storage and modal isolation: separate data.
	var s: Dictionary=E.fresh(game.cfg,77);M.credit(s,150);E.add_item(s,"W01")
	await reset(game,s);game.open_town_page("warehouse");await F.wait(game)
	var coin: String=game.campaign.inventory[0];game.warehouse_state={"source":"inventory","uid":coin};game.show_campaign();await F.wait(game)
	await shot(game,"09-fixture-coin-warehouse");await F.nav(game,"warehouse-coins")
	var modal: Control=game.modal_owner;modal.amount.value=30;await F.nav(game,"coin-split")
	if not check(game,M.amount(game.campaign)==150 and game.campaign.inventory.size()==4,"Actual split button preserves coins and adds one stack"):return
	frozen=Replay.hash_state(game.campaign);await F.key(game,KEY_C);await F.key(game,KEY_I)
	if not check(game,Replay.hash_state(game.campaign)==frozen and game.service_mode=="coin","Modal blocks underlying C/I"):return
	await shot(game,"10-fixture-coin-split");await F.key(game,KEY_ESCAPE)
	# Costed event: target and source are explicit, no implicit first keyboard choice.
	s=E.fresh(game.cfg,20);M.credit(s,8);s=E.act(s,"depart",int(s.revision),{},game.data,game.cfg);s.floor=7;s.highest_floor=7;s.phase="event";s.event="EV14";s.node={"kind":"event","started":true,"resolved":false};s.item_condition[s.equipment.head].current=30;s.event_target=s.equipment.head
	await reset(game,s);frozen=Replay.hash_state(game.campaign);await F.key(game,KEY_E)
	if not check(game,Replay.hash_state(game.campaign)==frozen,"Complex event E requires selected choice"):return
	await shot(game,"11-fixture-costed-event");await F.nav(game,"choice-"+game.cfg.journey.events.EV14.choices[0].id)
	if not check(game,game.campaign.phase=="event_result" and M.amount(game.campaign)==4 and game.campaign.item_condition[game.campaign.equipment.head].current==100,"Actual event click pays and repairs exactly once"):return
	await shot(game,"12-fixture-event-paid")
	# Visible boss telegraph and first guarantee: prepared level-8 fixture, not normal route proof.
	s=E.fresh(game.cfg,55);E.gain_exp(s,336,game.cfg)
	for item in ["W02","B02"]:
		var uid: String=E.add_item(s,item);s=E.act(s,"equip",int(s.revision),{"uid":uid},game.data,game.cfg)
	s=E.act(s,"depart",int(s.revision),{},game.data,game.cfg);s.floor=9;s.highest_floor=9;s=E.act(s,"descend",int(s.revision),{},game.data,game.cfg)
	await reset(game,s);await shot(game,"13-fixture-10f-before-boss");await F.key(game,KEY_E)
	await F.wait(game,1.3);game.auto_play=true;game.show_campaign()
	var end: int=Time.get_ticks_msec()+18000
	while Time.get_ticks_msec()<end and game.campaign.phase=="battle" and int(game.campaign.battle.current.enemy.ai_phase)!=2:await F.wait(game,.05)
	if not check(game,game.campaign.phase=="battle" and int(game.campaign.battle.current.enemy.ai_phase)==2,"Boss reached telegraph through normal timer"):return
	await F.key_event(game,KEY_SPACE,true);await F.key_event(game,KEY_SPACE,false);await F.wait(game,.2)
	await shot(game,"14-fixture-boss-telegraph");await F.key(game,KEY_SPACE);await settled(game,35)
	if not check(game,game.campaign.phase=="reward" and game.campaign.records.boss_kills==1 and game.campaign.pending_rewards.any(func(r):return r.id=="G10" and r.guaranteed),"Boss first guarantee exists once"):return
	if not check(game,"門守の継ぎ輪［保証］" in preload("res://ui/status_review.gd").text_in(game.screen),"Guarantee card keeps full equipment name on one line"):return
	await shot(game,"15-fixture-first-guarantee");await F.key(game,KEY_E)
	if not check(game,game.campaign.phase=="portal_done" and game.campaign.floor==10 and game.campaign.records.first_reward_claimed,"Receive at 10F stops for explicit return"):return
	await shot(game,"16-fixture-post-boss-portal");await F.key(game,KEY_E);await shot(game,"17-fixture-clear-result")
	# Common combat death removes dedicated gear, coin and bag, but keeps growth and protected containers.
	s=game.campaign.duplicate(true);s=E.act(s,"town",int(s.revision),{},game.data,game.cfg);M.credit(s,33,"cloth");var stored: String=E.add_item(s,"W03");s.inventory.erase(stored);s.warehouse.append(stored)
	s=E.act(s,"depart",int(s.revision),{},game.data,game.cfg);s.floor=8;s.highest_floor=10;s.hp=1;s=E.act(s,"descend",int(s.revision),{},game.data,game.cfg)
	await reset(game,s);var kept_exp: int=s.exp;game.auto_play=true;game.show_campaign();await settled(game)
	if not check(game,game.campaign.phase=="result" and game.campaign.result.kind=="death" and game.campaign.inventory.is_empty() and game.campaign.equipment.values().all(func(v):return v=="") and M.amount(game.campaign,"cloth")==33 and game.campaign.items.has(stored) and game.campaign.exp==kept_exp and not "G10" in game.campaign.items.values(),"Actual combat death keeps only protected belongings and growth"):return
	await shot(game,"18-fixture-death-loss-kept");await F.command(game,"town");await F.nav(game,"services");await service(game,"supply")
	if not check(game,game.campaign.equipment.values().filter(func(v):return v!="").size()==5,"Actual supply action restores minimum five slots"):return
	if not check(game,"5点支給" in game.notice,"Supply success and quantity visible in the open panel"):return
	await shot(game,"19-fixture-resupply");await F.key(game,KEY_ESCAPE);await F.key(game,KEY_E);await F.key(game,KEY_SPACE)
	if not check(game,game.campaign.floor==1 and game.campaign.phase=="battle","Resupply can depart again"):return
	# Debug-only fresh session and one-floor override, then escape during combat.
	s=E.fresh(game.cfg,66);s.debug=true;s=E.act(s,"depart",int(s.revision),{},game.data,game.cfg);s.floor=9;s.highest_floor=9;s=E.act(s,"debug_next",int(s.revision),{"kind":"event"},game.data,game.cfg);s=E.act(s,"descend",int(s.revision),{},game.data,game.cfg)
	await reset(game,s,true);await F.key(game,KEY_E)
	if not check(game,game.campaign.phase=="event" and game.campaign.node.kind=="event" and game.campaign.debug_next=="" and game.campaign.records.boss_kills==0,"Debug 10F event is actual event, no false boss reward"):return
	await shot(game,"20-fixture-debug-10f-event");await F.nav(game,"debug-services");await service(game,"debug_return");await F.key(game,KEY_ESCAPE)
	s=E.fresh(game.cfg,67);s.debug=true;s=E.act(s,"depart",int(s.revision),{},game.data,game.cfg);s=E.act(s,"descend",int(s.revision),{},game.data,game.cfg)
	await reset(game,s,true);await F.wait(game,1);await F.nav(game,"debug-services");await service(game,"debug_return");frozen=Replay.hash_state(game.campaign);await F.wait(game,1.2)
	if not check(game,game.campaign.phase=="result" and Replay.hash_state(game.campaign)==frozen and game.campaign.records.boss_kills==0,"Debug return cancels delayed attacks and rewards"):return
	await shot(game,"21-fixture-debug-return")
	var plan_path: String=""
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--normal-plan="):plan_path=arg.trim_prefix("--normal-plan=")
	var plan: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(plan_path))
	if not check(game,plan.no_stat_injection and plan.first_reward and plan.repeat and plan.five_return and plan.five_stay and plan.ten_early_return,"Normal table core route proof independently completed"):return
	game.debug_run=false;game.show_title();await F.wait(game)
	UI.write(game,{"complete":true,"rendered":true,"version":ProjectSettings.get_setting("application/config/version"),"run_id":game.smoke_run_id,"no_save_store":game.save_store==null,"exit_button_pressed":true,"normal_first_five_ui":true,"normal_full_route":"separate public-core transactions, no stat injection; see normal-plan.json","fixtures":["currency_modal","event_cost","boss_telegraph_and_guarantee","combat_death_and_resupply","debug_override_and_return"],"normal_tables_plan":plan.summary},"adventure-review.json")
	await F.nav(game,"quit")
