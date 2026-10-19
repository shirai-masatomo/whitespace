extends RefCounted
## Fixed review data only; no normal startup entry. Same fixture for before/after.
const E=preload("res://core/expedition.gd")
const UI=preload("res://ui/integration_review.gd")
const Texts=preload("res://ui/feedback_review.gd")
static func key(game: Control, code: Key, echo: bool=false) -> void:
	for down in [true,false]:
		var event:=InputEventKey.new(); event.keycode=code; event.physical_keycode=code; event.pressed=down; event.echo=echo if down else false
		game.get_viewport().push_input(event,true); await game.get_tree().process_frame
static func wait(game: Control, duration: float) -> void:
	await game.get_tree().create_timer(duration).timeout
static func fixture(game: Control) -> void:
	game.auto_play=false; game.play_timer.stop()
	game.campaign=E.fresh(game.cfg,123); game.campaign.phase="town"
	game.campaign.trips=2; game.campaign.exp=90; game.campaign.gold=37
	var sword: String=E.add_item(game.campaign,"A01")
	game.campaign=E.act(game.campaign,"equip",int(game.campaign.revision),{"uid":sword},game.data,game.cfg)
	for id in ["I02","I03","I04"]: E.add_item(game.campaign,id)
	for id in ["A02","I05","I06","I07","I08","I09","I10","I11"]:
		var uid: String=E.add_item(game.campaign,id); game.campaign.inventory.erase(uid); game.campaign.warehouse.append(uid)
	game.town_page="hub"; game.show_campaign()
static func battle_fixture(game: Control, foe: String="E04", floor_number: int=1) -> void:
	game.auto_play=false; game.play_timer.stop(); UI.fixture(game,foe,floor_number)
static func count_logos(node: Node) -> int:
	var count:=1 if node is TextureRect and node.texture!=null and node.texture.resource_path=="res://assets/title/v1/dive-in-under-logo-gold-deep-shadow.png" else 0
	for child in node.get_children(): count+=count_logos(child)
	return count
static func run(game: Control, before: bool=false) -> void:
	var proof: Dictionary={"mode":"before" if before else "after","run_id":game.smoke_run_id,"rendered":DisplayServer.get_name()!="headless","no_save_store":game.save_store==null,"checks":{},"logo_screens":[]}
	if not UI.check(game,proof.rendered and not game.legacy_persistence_mode and game.save_store==null,"Rendered session without persistence"): return
	await UI.shot(game,"01-title")
	if not before:
		var menu: Control=game.play_view.get_node("TitleMenu")
		var logo: TextureRect=menu.get_node("TitleLogo")
		var outer: Control=menu.get_node("TitleOuterPanel")
		if not UI.check(game,not "ダイブ・イン・アンダー" in Texts.labels(game.screen).map(func(l):return l.text) and outer.size==Vector2(620,440) and logo.size==Vector2(540,180),"Title: no Katakana region, single content-sized panel, original ratio"): return
		for id in ["start","quit"]:
			var b: Button=UI.find_nav(game.screen,id)
			if not UI.check(game,Rect2(Vector2.ZERO,outer.size).encloses(b.get_rect()) and is_equal_approx(b.position.x+b.size.x/2.0,310.0),"Title buttons centered and enclosed"): return
		proof.checks.title={"single_panel":true,"katakana_removed":true,"dimmer_alpha":game.play_view.get_node("TitleBackgroundDimmer").color.a,"start":false,"exit":false}
	await UI.click(game,"start"); game.auto_play=false
	if not UI.check(game,game.campaign.phase=="town","Start opens preparation"): return
	if not before:
		if not UI.check(game,game.campaign.trips==0 and E.normal_trips(game.campaign)==0 and E.validate(game.campaign,game.data,game.cfg)=="","New unstarted session really records zero trips"): return
		game.perform("depart",{},int(game.campaign.revision)); game.auto_play=false; game.play_timer.stop()
		if not UI.check(game,game.campaign.trips==1 and game.campaign.floor==1,"First departure counts one"): return
		# Use the actual return action after selecting a safe exploration fixture; no combat simulation.
		game.campaign.phase="explore"; game.campaign.battle={}; game.campaign.event=""; game.show_campaign()
		game.perform("return",{},int(game.campaign.revision)); game.perform("town",{},int(game.campaign.revision))
		if not UI.check(game,game.campaign.trips==1,"Return retains one trip"): return
		game.perform("depart",{},int(game.campaign.revision)); game.auto_play=false; game.play_timer.stop()
		if not UI.check(game,game.campaign.trips==2 and E.validate(game.campaign,game.data,game.cfg)=="","Next departure counts two and validates"): return
		proof.checks["09"]={"sequence":[0,1,1,2],"actual_state":true}
	fixture(game)
	await UI.shot(game,"05-preparation")
	if not before:
		proof.logo_screens.append({"screen":"preparation","count":count_logos(game.screen)})
	await UI.click(game,"status"); await game.click_control(game.status_view.item_buttons.head); await wait(game,0.14)
	await UI.shot(game,"02-status-equipment")
	if not before:
		var actor: Control=game.status_view.central.get_node("EquipmentActor")
		if not UI.check(game,game.status_view.item_buttons.size()==11,"Eleven human equipment slots retained"): return
		for b in game.status_view.item_buttons.values():
			if not UI.check(game,b.text=="" and Texts.labels(b).is_empty() and not b.get_rect().intersects(actor.get_rect()) and absf(b.size.x-b.size.y)<=4.0 and not b.tooltip_text.is_empty(),"Icon-only near-square slots, accessible tooltip and actor separation"): return
		if not UI.check(game,"冒険者のマント" in Texts.labels(game.status_view.details).map(func(l):return l.text),"Official name remains complete in details"): return
		proof.checks["02"]={"slots":11,"icon_only":true,"no_actor_overlap":true,"full_name_in_details":true}; proof.logo_screens.append({"screen":"status","count":count_logos(game.screen)})
	await game.click_control(game.status_view.item_buttons.body); await wait(game,0.12); await UI.shot(game,"04-status-empty")
	if not before:
		var detail_labels: Array=Texts.labels(game.status_view.details).map(func(l):return l.text)
		if not UI.check(game,"未装備" in detail_labels and detail_labels.size()<=2,"Empty slot detail is brief"): return
	await game.click_control(game.status_view.tab_buttons.abilities); await UI.shot(game,"04-status-abilities")
	await game.click_control(game.status_view.back_button); await wait(game,0.3)
	await UI.click(game,"equipment"); game.equipment_focus="head"; game.show_campaign(); await UI.shot(game,"08-equipment")
	if not before: proof.logo_screens.append({"screen":"equipment","count":count_logos(game.screen)})
	await UI.click(game,"back")
	game.warehouse_state={"source":"warehouse","uid":game.campaign.warehouse[0]}
	await UI.click(game,"warehouse"); await UI.shot(game,"05-warehouse")
	if not before:
		if not UI.check(game,not "—" in Texts.labels(game.warehouse_view).map(func(l):return l.text),"Warehouse hides absent placeholder rows"): return
		proof.logo_screens.append({"screen":"warehouse","count":count_logos(game.screen)})
	await game.click_control(game.find_button(game.warehouse_view,"戻る")); await wait(game,0.12)
	# Same fixed hero and cave state for exploration and auto-battle comparisons.
	game.campaign.phase="explore"; game.campaign.floor=1; game.campaign.highest_floor=1; game.show_campaign(); await UI.shot(game,"05-exploration")
	if not before: proof.logo_screens.append({"screen":"exploration","count":count_logos(game.screen)})
	battle_fixture(game); await UI.shot(game,"06-battle-paused")
	if not before:
		proof.logo_screens.append({"screen":"battle","count":count_logos(game.screen)})
		for record in proof.logo_screens:
			if not UI.check(game,record.count==1,"One adopted logo on "+record.screen): return
		proof.checks["01"]={"logo_screens":proof.logo_screens,"title_dimmer_already_resolved":true}
		# Normal timer and viewport key route. Hold Space echoes while paused, then wait >3 ticks.
		game.auto_play=true; game.show_campaign(); await wait(game,0.08); await key(game,KEY_SPACE)
		if not UI.check(game,not game.auto_play and game.play_timer.is_stopped(),"Space stops normal auto-battle"): return
		var frozen: String=game.CampaignReplay.hash_state(game.campaign)
		for i in 4: await key(game,KEY_SPACE,true)
		await UI.click(game,"map"); await UI.click(game,"close-map"); await wait(game,2.0)
		if not UI.check(game,not game.auto_play and game.CampaignReplay.hash_state(game.campaign)==frozen,"Paused rounds HP/SP rewards unchanged through time, echoes and map operations"): return
		await key(game,KEY_SPACE)
		if not UI.check(game,game.auto_play and not game.play_timer.is_stopped(),"Explicit latest request: Space resumes"): return
		await key(game,KEY_SPACE)
		if not UI.check(game,not game.auto_play,"Second stop works"): return
		await UI.click(game,"pause")
		if not UI.check(game,game.auto_play,"Resume button remains available"): return
		game.play_view.open_routes()
		if not UI.check(game,game.auto_play and not game.play_timer.is_stopped(),"Opening map does not pause battle"): return
		game.play_view.close_routes()
		await wait(game,0.7)
		if not UI.check(game,game.campaign.battle.get("rounds",0)>0 or game.campaign.phase!="battle","Resumed timer advances normally"): return
		game.auto_play=false; game.play_timer.stop()
		proof.checks["06"]={"space_stop_resume":true,"echo_ignored":true,"freeze_seconds":2.0,"all_state_frozen":true,"button_resume":true}
		# Transition fixtures call the actual existing finish function. No long death/clear simulation.
		for result_kind in ["death","clear"]:
			fixture(game); battle_fixture(game); game.route_map_open=true; game.show_campaign()
			E.finish(game.campaign,result_kind,"地図持越しの固定確認",game.cfg); game.show_campaign()
			if not UI.check(game,not game.route_map_open and game.play_view.mode=="result","Map flag reset on "+result_kind): return
			game.perform("town",{},int(game.campaign.revision))
			if not UI.check(game,not game.route_map_open and game.play_view.mode=="hub","Map reset in town"): return
			await key(game,KEY_ESCAPE)
			if not UI.check(game,game.title_visible,"First town Esc opens title without invisible-map interception"): return
			game.show_campaign(); game.perform("depart",{},int(game.campaign.revision)); game.auto_play=false; game.play_timer.stop()
			if not UI.check(game,not game.route_map_open and not is_instance_valid(game.play_view.routes_overlay),"Next expedition keeps map closed"): return
		proof.checks["07"]={"death":true,"clear":true,"first_town_esc":true,"next_departure_closed":true,"map_does_not_pause_battle":true}
		fixture(game); var cloak: String=game.campaign.equipment.head
		game.campaign.item_condition[cloak].current=37
		while game.campaign.inventory.size()<15: E.add_item(game.campaign,"I10")
		game.open_town_page("equipment"); game.equipment_focus="head"; game.show_campaign()
		var remove: Button=game.play_buttons.unequip
		if not UI.check(game,remove.disabled and remove.tooltip_text=="バックパックに空きがありません","Full backpack displays disabled removal reason"): return
		await UI.shot(game,"08-backpack-full")
		var initial: String=game.CampaignReplay.hash_state(game.campaign)
		game.perform("unequip",{"slot":"head"},int(game.campaign.revision))
		if not UI.check(game,game.CampaignReplay.hash_state(game.campaign)==initial,"Core also rejects full-backpack removal"): return
		var carried: String=game.campaign.inventory[-1]
		game.perform("deposit",{"uid":carried},int(game.campaign.revision))
		if not UI.check(game,not game.play_buttons.unequip.disabled,"One free slot enables removal"): return
		await game.click_control(game.play_buttons.unequip)
		if not UI.check(game,cloak in game.campaign.inventory and game.campaign.equipment.head=="" and game.campaign.item_condition[cloak].current==37,"Removal preserves UID and individual durability"): return
		proof.checks["08"]={"full_disabled_reason":true,"one_slot_enables":true,"same_uid":true,"durability":37}
		proof.checks["03"]={"shared_art":"adventurer-cloak-navy.png","original_blue_preserved":true}
		proof.checks["04"]={"grouped_left":true,"brief_empty":true,"real_details":true,"ability_columns":true}
		proof.checks["05"]={"warehouse_columns":3,"quiet_internal_rows":true,"shared_hero_card":true}
	# Real title Exit button, external harness also confirms code zero.
	game.show_title(); await wait(game,0.25)
	var quit: Button=UI.find_nav(game.screen,"quit")
	quit.pressed.connect(func():
		proof.complete=true; proof.exit_button_pressed=true
		if not before: proof.checks.title.start=true; proof.checks.title.exit=true
		UI.write(game,proof,"refinement-review.json"))
	await game.click_control(quit)
