extends RefCounted
const Model=preload("res://ui/status_model.gd")
static func text_in(node: Node) -> String:
	var result: String=node.text+"\n" if node is Label or node is Button else ""
	for child in node.get_children(): result+=text_in(child)
	return result
static func key(game: Control, code: Key) -> void:
	for pressed in [true,false]:
		var event:=InputEventKey.new(); event.keycode=code; event.physical_keycode=code; event.pressed=pressed; game.get_viewport().push_input(event,true); await game.get_tree().process_frame
	await game.get_tree().create_timer(0.12).timeout
static func unchanged(game: Control, state_hash: String, save_hash: String) -> bool:
	return game.CampaignReplay.hash_state(game.campaign)==state_hash and game.save_store.digest()==save_hash
static func write(game: Control, record: Dictionary, filename: String) -> void:
	var f:=FileAccess.open(game.smoke_dir.path_join(filename),FileAccess.WRITE); f.store_string(JSON.stringify(record,"\t")); f.close()
	print("STATUS_REVIEW_OK run_id=",game.smoke_run_id)
static func run(game: Control) -> void:
	var rendered:=DisplayServer.get_name()!="headless"
	var resume: bool="--status-review-resume" in OS.get_cmdline_user_args()
	if not resume:
		var s: Dictionary=game.Expedition.fresh(game.cfg,10000)
		s=game.Expedition.act(s,"return",int(s.revision),{},game.data,game.cfg)
		s=game.Expedition.act(s,"town",int(s.revision),{},game.data,game.cfg)
		game.Expedition.gain_exp(s,40,game.cfg)
		var hat: String=s.inventory[0]
		s=game.Expedition.act(s,"equip",int(s.revision),{"uid":hat},game.data,game.cfg)
		for id in ["I05","I07"]:
			var uid: String=game.Expedition.add_item(s,id)
			s=game.Expedition.act(s,"equip",int(s.revision),{"uid":uid},game.data,game.cfg)
		game.Expedition.add_item(s,"I10")
		var protected_uid: String=game.Expedition.add_item(s,"I02")
		s=game.Expedition.act(s,"to_cloth",int(s.revision),{"uid":protected_uid},game.data,game.cfg)
		s.item_condition[hat].current=64; s.item_condition[s.equipment.finger].current=28; s.item_condition[s.equipment.neck].current=0
		var h: Dictionary=game.Expedition.hero(s,game.cfg); s.hp=h.max_hp; s.sp=h.max_sp
		if not game.smoke_check(game.Expedition.validate(s,game.data,game.cfg)=="","Valid existing-data status fixture"): return
		var f:=FileAccess.open(game.save_store.path,FileAccess.WRITE); f.store_string(JSON.stringify(s)); f.close()
		game.save_store=game.SaveStore.new(game.save_store.path,game.data,game.cfg); game.loaded=game.save_store.load_game(); game.campaign=game.loaded.state
	else:
		var prior=JSON.parse_string(FileAccess.get_file_as_string(game.smoke_dir.path_join("status-review.json")))
		if not game.smoke_check(game.loaded.ok and not game.loaded.migrated and game.save_store.digest()==prior.save_sha256,"Status interactions leave save restartable"): return
	game.auto_play=false; game.play_timer.stop()
	var before: String=game.CampaignReplay.hash_state(game.campaign); var save_before: String=game.save_store.digest()
	game.open_town_page("hub")
	if rendered and not resume: await game.capture("status-town-before.png")
	await game.click_control(game.find_button(game.screen,"ステータス"))
	await game.get_tree().create_timer(0.25).timeout
	var view: Control=game.status_view
	if not game.smoke_check(game.town_page=="status" and view.active_tab=="equipment" and view.item_buttons.size()==11 and view.gauges.sp.maximum==game.Expedition.hero(game.campaign,game.cfg).max_sp,"Town opens equipment tab, actual gauges and eleven slots"): return
	var slot_keys: Array=view.item_buttons.keys()
	var separate:=true
	for i in slot_keys.size():
		for j in range(i+1,slot_keys.size()):
			if view.item_buttons[slot_keys[i]].get_global_rect().intersects(view.item_buttons[slot_keys[j]].get_global_rect()): separate=false
	if not game.smoke_check(separate and view.bars.hp.get_global_rect().end.y<=view.left_values.sp.get_global_rect().position.y,"All eleven equipment hit areas and compact gauge labels remain separate"): return
	if resume:
		if rendered: await game.capture("status-restarted.png")
		await game.click_control(view.back_button); await game.get_tree().create_timer(0.23).timeout
		if not game.smoke_check(game.town_page=="hub" and unchanged(game,before,save_before),"Restarted status closes without writes"): return
		write(game,{"run_id":game.smoke_run_id,"complete":true,"rendered":rendered,"separate_restart":true,"save_sha256":save_before},"status-review-resume.json"); game.get_tree().quit(); return
	var view_id: int=view.get_instance_id(); var left_id: int=view.left_panel.get_instance_id()
	if not game.smoke_check(view.container_counts.inventory.text=="%d / 15"%game.campaign.inventory.size() and view.container_counts.cloth.text=="%d / 3"%game.campaign.cloth.size(),"Read-only storage counters show actual contents"): return
	if rendered: await game.capture("status-equipment.png")
	await game.click_control(view.item_buttons.finger); await game.get_tree().create_timer(0.12).timeout
	if not game.smoke_check(view.selection.equipment=="finger" and "28 / 100" in text_in(view.details) and unchanged(game,before,save_before),"Equipment selection shows individual damage without unequip/save"): return
	if rendered: await game.capture("status-selected-ring.png")
	await game.get_tree().process_frame
	if not game.smoke_check(view.detail_scroll.get_v_scroll_bar().max_value>view.detail_scroll.size.y,"Long equipment details scroll"): return
	for i in 3:
		var wheel:=InputEventMouseButton.new(); wheel.position=view.detail_scroll.get_global_rect().get_center(); wheel.button_index=MOUSE_BUTTON_WHEEL_DOWN; wheel.pressed=true; game.get_viewport().push_input(wheel,true); wheel=wheel.duplicate(); wheel.pressed=false; game.get_viewport().push_input(wheel,true); await game.get_tree().process_frame
	if not game.smoke_check(view.detail_scroll.scroll_vertical>0,"Mouse wheel scrolls details"): return
	if rendered: await game.capture("status-detail-scrolled.png")
	await game.click_control(view.item_buttons.right_hand); await game.get_tree().create_timer(0.1).timeout
	if not game.smoke_check("装備なし" in text_in(view.details),"Empty equipment slot has clear detail"): return
	await key(game,KEY_2)
	await game.click_control(view.item_buttons.atk); await game.get_tree().create_timer(0.1).timeout
	if not game.smoke_check(view.active_tab=="abilities" and "攻撃力" in text_in(view.details) and str(game.Expedition.hero(game.campaign,game.cfg).atk) in text_in(view.details),"Numeric key switches tab and ability click shows actual value"): return
	if rendered: await game.capture("status-abilities.png")
	view.tab_buttons.abilities.grab_focus(); await key(game,KEY_RIGHT); await key(game,KEY_ENTER)
	if not game.smoke_check(view.active_tab=="conditions" and "状態異常なし" in text_in(view.central) and not "0%" in text_in(view.central),"Arrow/Enter tabs; no invented resistance values"): return
	if rendered: await game.capture("status-conditions.png")
	await game.click_control(view.item_buttons.poison); await game.get_tree().create_timer(0.1).timeout
	if not game.smoke_check("現在は未付与" in text_in(view.details) and "付与時の攻撃力" in text_in(view.details) and unchanged(game,before,save_before),"Status icon guide does not invent current poison or reference damage"): return
	if rendered: await game.capture("status-condition-guide.png")
	await key(game,KEY_4); await game.click_control(view.item_buttons.journey); await game.get_tree().create_timer(0.1).timeout
	if not game.smoke_check(view.active_tab=="profile" and "まだ設定されていません" in text_in(view.central) and not "湖の村" in text_in(view.central),"Profile excludes reference-image biography"): return
	if rendered: await game.capture("status-profile.png")
	if not game.smoke_check(view.get_instance_id()==view_id and view.left_panel.get_instance_id()==left_id and view.party_buttons.filter(func(b):return b.disabled).size()==5 and unchanged(game,before,save_before),"Tabs keep same screen/left panel; five future party slots disabled; save unchanged"): return
	# Presentation adapter reads statuses created by the actual combat core.
	var battle: Dictionary=game.Expedition.Combat.start(game.Expedition.hero(game.campaign,game.cfg),game.Expedition.Combat.enemy(game.data,"E04",4),game.data.rules,123)
	game.Expedition.Combat.apply_status(battle,"enemy","hero","S102")
	var states:=Model.effects(battle.hero,game.data.rules)
	if not game.smoke_check(states.size()==1 and states[0].remaining==battle.hero.statuses.poison.remaining and str(int(battle.hero.statuses.poison.potency)) in states[0].text,"Status adapter reads core potency and own-action duration"): return
	var defense_campaign: Dictionary=game.campaign.duplicate(true)
	game.Expedition.gain_exp(defense_campaign,int(game.cfg.growth.exp_step)*int(view.unit.level),game.cfg)
	battle=game.Expedition.Combat.start(game.Expedition.hero(defense_campaign,game.cfg),game.Expedition.Combat.enemy(game.data,"E04",4),game.data.rules,123)
	game.Expedition.Combat.apply_status(battle,"enemy","hero","S102")
	battle.hero.hp=1; battle.hero.action_count=1
	if not game.smoke_check(game.Expedition.Combat.use_defense(battle,"hero") and Model.effects(battle.hero,game.data.rules).size()==2,"Defense adapter uses actual core state"): return
	await key(game,KEY_ESCAPE); await game.get_tree().create_timer(0.23).timeout
	if not game.smoke_check(game.town_page=="hub" and unchanged(game,before,save_before),"Esc returns to originating town without state/save changes"): return
	if rendered: await game.capture("status-town-after.png")
	await game.click_control(game.find_button(game.screen,"ステータス")); await game.get_tree().create_timer(0.25).timeout
	if not game.smoke_check(game.status_view.active_tab=="equipment","Reopen always starts at equipment"): return
	await game.click_control(game.status_view.back_button); await game.get_tree().create_timer(0.23).timeout
	await game.click_control(game.find_button(game.screen,"倉庫を開く"))
	if not game.smoke_check(game.town_page=="warehouse" and unchanged(game,before,save_before),"Mouse Back and separate warehouse route preserve data"): return
	write(game,{"run_id":game.smoke_run_id,"complete":true,"rendered":rendered,"fixture_only":true,"manual_os_input":false,"tabs":4,"equipment_slots":11,"same_screen":true,"same_left_panel":true,"keyboard":true,"wheel_scroll":true,"no_mutation":true,"state_sha256":before,"save_sha256":save_before,"save_after_sha256":game.save_store.digest(),"origin_return":true,"read_only":true},"status-review.json")
	game.get_tree().quit()
