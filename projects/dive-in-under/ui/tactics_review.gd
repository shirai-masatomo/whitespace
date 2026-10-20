extends RefCounted
## One isolated distribution process. Normal inputs first; named fixtures afterwards.
const E=preload("res://core/expedition.gd")
const P=preload("res://core/adventure.gd")
const M=preload("res://core/currency.gd")
const C=preload("res://core/combat.gd")
const S=preload("res://core/squad_combat.gd")
const T=preload("res://core/tactics.gd")
const F=preload("res://ui/flow_review.gd")
const A=preload("res://ui/adventure_review.gd")
const UI=preload("res://ui/integration_review.gd")
const Replay=preload("res://ui/campaign_replay.gd")
static func check(game: Control, value: bool, name: String) -> bool:
	UI.write(game,{"last_check":name,"passed":value,"phase":game.campaign.get("phase",""),"run_id":game.smoke_run_id},"tactics-progress.json")
	return game.smoke_check(value,name)
static func shot(game: Control, name: String) -> void:
	await F.wait(game,.15);await game.capture(name+".png")
static func battle_unit(id: String, speed: int, foe: bool=false, rank: String="front") -> Dictionary:
	return {"battle_id":id,"id":"E01" if foe else "hero","name":id,"level":1,"hp":80,"max_hp":80,"sp":10,"max_sp":10,"atk":1,"def":4,"spd":speed,"skills":["S101","S105"],"rank":rank}
static func run(game: Control) -> void:
	await shot(game,"00-title-retained");await F.nav(game,"start")
	if not check(game,game.campaign.items.size()==5 and game.campaign.equipment.left_hand!="" and game.campaign.equipment.feet=="","Normal start equips requested five types"):return
	await shot(game,"01-normal-five-starter");await F.nav(game,"tactics");await shot(game,"02-normal-tactics-editor")
	await F.nav(game,"tactics-new");await F.nav(game,"tactics-apply")
	if not check(game,game.campaign.tactics.sets.size()==3 and game.campaign.tactics.active.begins_with("session-"),"Actual editor clone save apply"):return
	await shot(game,"03-normal-saved-strategy");await F.key(game,KEY_ESCAPE)
	await F.key(game,KEY_E);await F.key(game,KEY_SPACE);await F.wait(game,.25)
	if not check(game,game.campaign.phase=="battle" and not game.auto_play,"Normal first battle pauses with Space"):return
	var before: Dictionary=game.campaign.battle.current.duplicate(true)
	await F.nav(game,"tactics");await F.nav(game,"tactics-edit-attack");await F.nav(game,"tactics-apply")
	if not check(game,game.campaign.tactics.active=="attack" and game.campaign.battle.current.acted==before.acted and game.campaign.battle.current.round==before.round,"Actual battle strategy change preserves action ledger"):return
	await F.key(game,KEY_ESCAPE);await shot(game,"04-normal-battle-strategy")
	var frozen: String=Replay.hash_state(game.campaign);await F.wait(game,.8)
	if not check(game,not game.auto_play and frozen==Replay.hash_state(game.campaign),"Close editor preserves explicit pause"):return
	await F.key(game,KEY_SPACE)
	var deadline: int=Time.get_ticks_msec()+26000
	while Time.get_ticks_msec()<deadline and (game.campaign.phase=="battle" or game.presenting):await F.wait(game,.1)
	if not check(game,game.campaign.phase=="reward" and not game.presenting,"Normal first battle reaches real rewards"):return
	await shot(game,"05-normal-battle-reward")
	# Currency fixture; quantities enter through the common transaction, UI uses real controls.
	var s: Dictionary=E.fresh(game.cfg,77);M.credit(s,1000);await A.reset(game,s)
	game.open_town_page("warehouse");await F.wait(game)
	game.warehouse_state={"source":"inventory","uid":game.campaign.inventory[0]};game.show_campaign();await F.wait(game)
	await shot(game,"06-fixture-999-and-one");await F.nav(game,"warehouse-coins")
	game.modal_owner.amount.value=400;await F.nav(game,"coin-split")
	if not check(game,M.amount(game.campaign)==1000 and game.campaign.inventory.size()==3,"Actual split controls preserve 1000 coins"):return
	await shot(game,"07-fixture-coin-split");await F.key(game,KEY_ESCAPE)
	# 5F is constructed before encounter, then resolved through common actions once.
	s=E.fresh(game.cfg,1);s=E.act(s,"depart",int(s.revision),{},game.data,game.cfg);s.floor=4;s.phase="explore";s=E.act(s,"descend",int(s.revision),{},game.data,game.cfg)
	await A.reset(game,s);await shot(game,"08-fixture-five-before-stay");await F.key(game,KEY_E)
	if game.campaign.phase=="battle":
		game.auto_play=true;game.show_campaign();await A.settled(game,30)
	if game.campaign.phase=="treasure":await F.key(game,KEY_E)
	if game.campaign.phase=="event":
		var event: Dictionary=game.cfg.progression.events[game.campaign.event]
		for choice in event.choices:
			if choice.ops.is_empty():
				if preload("res://ui/event_choices.gd").simple(event):await F.key(game,KEY_X)
				else:await F.nav(game,"choice-"+choice.id)
				break
	if game.campaign.phase in ["reward","event_result"]:await F.key(game,KEY_E)
	if not check(game,game.campaign.floor==5 and game.campaign.phase=="portal_done" and not P.can_return(game.campaign) and game.play_buttons.return_ready.disabled and "帰還地点 10F" in preload("res://ui/status_review.gd").text_in(game.screen),"5F after stay return disabled and next portal 10F shown"):return
	await shot(game,"09-fixture-five-return-locked")
	# Medicine fixture: actual turn commits consume one UID, then normal action occurs.
	s=E.fresh(game.cfg,7);M.credit(s,2);s=E.act(s,"buy_remedy",int(s.revision),{"id":"RP"},game.data,game.cfg);s=E.act(s,"depart",int(s.revision),{},game.data,game.cfg);s=E.act(s,"descend",int(s.revision),{},game.data,game.cfg)
	var b: Dictionary=s.battle.current;b.units.hero.hp=10;b.units.hero.spd=100;S.sync(b);s.hp=10;C.apply_status(b,"enemy","hero","S102")
	await A.reset(game,s);await shot(game,"10-fixture-poison-before");game.perform("round",{},int(game.campaign.revision));await F.wait(game,1)
	if not check(game,game.campaign.battle.current.hero.hp==13 and not game.campaign.battle.current.hero.statuses.has("poison") and game.campaign.inventory.filter(func(k):return game.campaign.items[k]=="RP").is_empty() and game.campaign.battle.current.hero.action_count==1,"Actual turn cures and consumes bag item and attacks"):return
	await shot(game,"11-fixture-antidote-and-action")
	# Real 3v3 core and live stage. Characters are explicit verification identities, no joining content.
	s=E.fresh(game.cfg,5);s=E.act(s,"depart",int(s.revision),{},game.data,game.cfg);s=E.act(s,"descend",int(s.revision),{},game.data,game.cfg)
	var strategy: Dictionary={"id":"six","name":"検証用 B→A→C","favorite":true,"order":["B","A","C"],"characters":{}}
	for id in strategy.order:strategy.characters[id]={"rank":"back" if id=="C" else "front","rows":[{"skill":"attack","conditions":[],"target":"enemy_front"}]}
	T.save(s.tactics,strategy);T.select(s.tactics,"six")
	s.battle.current=S.start([battle_unit("A",10),battle_unit("B",20),battle_unit("C",30,false,"back")],[battle_unit("O",5,true),battle_unit("P",15,true),battle_unit("Q",25,true,"back")],game.data.rules,5,strategy)
	s.exp=12000;var fixture_hero: Dictionary=E.hero(s,game.cfg);s.hp=mini(int(fixture_hero.max_hp),80);s.battle.current.units.A.hp=s.hp;S.sync(s.battle.current);await A.reset(game,s);await shot(game,"12-fixture-six-combatants")
	var order: Array=[]
	for n in 6:
		var offset: int=game.campaign.battle.current.log.size();game.perform("round",{},int(game.campaign.revision));await F.wait(game,.7)
		for event in game.campaign.battle.current.log.slice(offset):
			if event.type=="opportunity":order.append(event.actor)
		if n in [0,1,3,5]:await shot(game,"13-fixture-order-"+str(n+1))
	if not check(game,order==["Q","B","P","A","C","O"],"Actual distribution six-unit order Q B P A C O"):return
	var view: Control=F.shell(game);view.select_actor("Q");await shot(game,"14-fixture-selected-enemy-reason")
	UI.write(game,{"last_check":"about to open squad editor","passed":true,"run_id":game.smoke_run_id},"tactics-progress.json")
	await F.nav(game,"tactics")
	if not check(game,game.modal_owner.actor=="B" and game.modal_owner.draft.characters.size()==3,"Squad editor starts at actual first actor B, not absent hero"):return
	await shot(game,"15-fixture-squad-strategy-editor");await F.key(game,KEY_ESCAPE)
	game.show_title();await F.wait(game)
	UI.write(game,{"complete":true,"rendered":true,"version":ProjectSettings.get_setting("application/config/version"),"run_id":game.smoke_run_id,"no_save_store":game.save_store==null,"normal_new_game_and_first_battle":true,"fixtures":["currency_999_split","five_stay_lock","antidote_action","six_unit_order"],"order":order,"strategy_switch_ledger_preserved":true,"exit_button_pressed":true,"user_evaluation":"not_reviewed"},"tactics-review.json")
	await F.nav(game,"quit")
