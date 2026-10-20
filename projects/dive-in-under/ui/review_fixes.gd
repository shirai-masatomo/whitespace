extends RefCounted
## Focused review-defect acceptance. Prepared states below never enter normal new-game data.
const E=preload("res://core/expedition.gd")
const F=preload("res://ui/flow_review.gd")
const UI=preload("res://ui/integration_review.gd")
const Replay=preload("res://ui/campaign_replay.gd")
const Old=preload("res://ui/journey_review.gd")
const Text=preload("res://ui/status_review.gd")
const Info=preload("res://ui/item_presenter.gd")
static func check(game: Control, value: bool, message: String) -> bool:
	UI.write(game,{"last_check":message,"passed":value,"run_id":game.smoke_run_id,"phase":game.campaign.get("phase",""),"floor":game.campaign.get("floor",0),"ticks_ms":Time.get_ticks_msec(),"primary":game.primary_button.text if is_instance_valid(game.primary_button) else "", "primary_action":game.primary_button.get_meta("campaign_action","") if is_instance_valid(game.primary_button) else ""},"review-progress.json")
	return game.smoke_check(value,message)
static func text(game: Control) -> String:
	return Text.text_in(game.screen)
static func shot(game: Control, name: String) -> void:
	await F.wait(game,.12); await game.capture(name+".png")
static func fixture(game: Control, phase: String="reward", floor_number: int=2) -> void:
	F.fixture(game); game.campaign.phase=phase; game.campaign.floor=floor_number; game.campaign.highest_floor=floor_number; game.flow_memory={}; game.event_choice=""; game.event_choice_key=""; game.town_page="hub"; game.equipment_candidate=""; game.equipment_focus="head"
	if phase=="treasure": E.Journey.add_reward(game.campaign,"I02")
static func right(game: Control, point: Vector2=Vector2(700,400)) -> void:
	for pressed in [true,false]:
		var event:=InputEventMouseButton.new(); event.button_index=MOUSE_BUTTON_RIGHT; event.position=point; event.global_position=point; event.pressed=pressed
		game.get_viewport().push_input(event,true); await game.get_tree().process_frame
	await F.wait(game,.08)
static func double(game: Control, source: String, uid: String) -> void:
	await F.wait(game)
	var point: Vector2=F.cell(game.screen,source,uid).get_global_rect().get_center()
	await F.click_at(game,point); await F.wait(game,.1)
	for pressed in [true,false]:
		var event:=InputEventMouseButton.new(); event.button_index=MOUSE_BUTTON_LEFT; event.position=point; event.global_position=point; event.pressed=pressed; event.double_click=pressed
		game.get_viewport().push_input(event,true); await game.get_tree().process_frame
	await F.wait(game,.15)
static func primary(game: Control, action: String) -> bool:
	var b: Button=game.primary_button
	return is_instance_valid(b) and b.get_meta("campaign_action","")==action and b.get_global_rect().position==Vector2(30,140)
static func run(game: Control) -> void:
	if not check(game,DisplayServer.get_name()!="headless" and game.save_store==null and game.campaign.is_empty(),"Fresh isolated distribution EXE, no SaveStore"): return
	if not check(game,"リセット" in text(game) and "保存は行いません" in text(game),"Title explicitly states session reset on exit"): return
	await shot(game,"00-title-session-notice"); await F.nav(game,"start")
	if not check(game,game.campaign.trips==0 and game.campaign.phase=="town","New session starts before departure"): return
	await F.key(game,KEY_C); var original: Control=game.status_view
	await F.key(game,KEY_C)
	if not check(game,game.status_view==original and game.status_return_page=="hub","Repeated C cannot reenter status or overwrite origin"): return
	await game.click_control(game.status_view.back_button); await F.wait(game,.4)
	if not check(game,game.town_page=="hub","Town status Back returns to preparation"): return
	await F.nav(game,"equipment"); await F.key(game,KEY_C); await F.key(game,KEY_C); await F.key(game,KEY_ESCAPE); await F.wait(game,.4)
	if not check(game,game.town_page=="equipment","Town status Esc returns to original equipment page"): return
	await F.key(game,KEY_C); game.status_return_page="status"; await F.key(game,KEY_ESCAPE); await F.wait(game,.4)
	if not check(game,game.town_page=="hub","Invalid status origin safely falls back to preparation"): return
	await shot(game,"01-preparation-returned")
	# Public input still enters 1F and Space still stops and resumes the current battle.
	await F.key(game,KEY_E); await F.key(game,KEY_SPACE); await F.wait(game,.3)
	if not check(game,game.campaign.floor==1 and game.campaign.phase=="battle" and not game.auto_play,"Normal departure and Space stop remain reachable"): return
	var frozen: String=Replay.hash_state(game.campaign); await F.wait(game,.7)
	if not check(game,Replay.hash_state(game.campaign)==frozen,"Paused normal battle stays unchanged"): return
	await shot(game,"02-normal-battle-level"); await F.key(game,KEY_SPACE)
	if not check(game,game.auto_play,"Space resumes normal battle"): return
	game.auto_play=false; game.play_timer.stop(); game.cancel_presentation()
	# Same instance, deliberately worn: current value must agree on all four presentation paths.
	fixture(game); var worn: String=E.add_item(game.campaign,"I02"); game.campaign.item_condition[worn].current=37
	var fresh: String=E.add_item(game.campaign,"I02"); game.campaign.inventory.erase(fresh); game.campaign.equipment.body=fresh
	game.flow_selection={"kind":"inventory","uid":worn,"slot":""}; game.show_campaign(); await F.wait(game)
	var expected: String=Info.current(game.campaign,game.cfg,worn)
	if not check(game,expected in text(game) and "基礎値" in text(game) and "交換差" in text(game),"Exploration detail uses shared current, base and comparison"): return
	await shot(game,"03-owned-current-comparison"); await F.key(game,KEY_I); await F.wait(game)
	await game.click_control(F.cell(game.screen,"inventory",worn)); await F.wait(game,.15)
	if not check(game,expected in text(game) and "町で修理できます" in text(game),"Equipment shows same current and town-only repair reason"): return
	await shot(game,"04-equipment-current-backed"); await F.key(game,KEY_ESCAPE)
	# Equip the worn instance, then status uses the exact same current calculation.
	game.perform("equip",{"uid":worn},int(game.campaign.revision)); await F.wait(game)
	await F.key(game,KEY_C); await F.wait(game); await game.click_control(game.status_view.item_buttons.body); await F.wait(game,.1)
	if not check(game,expected in text(game) and "現在値" in text(game) and "基礎値" in text(game),"Status selected same worn instance uses effective and labelled base"): return
	await shot(game,"05-status-current"); await F.key(game,KEY_ESCAPE); await F.wait(game,.3)
	if not check(game,not game.field_status and game.campaign.phase=="reward","Status fade finishes before following reward selection"): return
	E.Journey.add_reward(game.campaign,"I02"); game.show_campaign(); await F.wait(game)
	await game.click_control(F.cell(game.screen,"pending",game.campaign.pending_rewards[0].token)); await F.wait(game,.1)
	if not check(game,"交換差：防御 +1" in text(game),"Fresh reward comparison uses same worn current difference"): return
	await shot(game,"06-reward-comparison")
	# A true item double click still swaps one-for-one at full capacity.
	while game.campaign.inventory.size()<15: E.add_item(game.campaign,"I10")
	game.campaign.pending_rewards=[]; game.show_campaign(); await F.key(game,KEY_I); await double(game,"inventory",fresh)
	if not check(game,game.campaign.equipment.body==fresh and worn in game.campaign.inventory and game.campaign.inventory.size()==15 and game.campaign.item_condition[worn].current==37,"Native full one-for-one double click preserves old UID and condition"): return
	await F.key(game,KEY_ESCAPE)
	# Left-only primary and input carry-through on overlapping main buttons.
	fixture(game,"treasure"); game.show_campaign(); await F.wait(game)
	if not check(game,primary(game,"open_chest"),"Treasure affirmative is in the fixed left position"): return
	await shot(game,"07-chest-left-primary")
	await F.key_event(game,KEY_E,true); await F.wait(game,.1)
	if not check(game,game.campaign.phase=="reward" and primary(game,"claim_all_advance"),"One E opens chest and left primary changes to receipt"): return
	frozen=Replay.hash_state(game.campaign)
	await F.key_event(game,KEY_E,true,true); await F.key_event(game,KEY_E,true); await F.wait(game,.6)
	if not check(game,Replay.hash_state(game.campaign)==frozen,"Held E and key echo cannot receive or advance destination"): return
	await F.key_event(game,KEY_E,false); await F.key(game,KEY_E)
	if not check(game,game.campaign.floor==3 and game.campaign.phase=="event" and game.campaign.pending_rewards.is_empty(),"One released E receives everything and advances exactly once"): return
	await shot(game,"08-simple-event"); await F.key(game,KEY_E)
	if not check(game,game.campaign.phase=="event_result" and primary(game,"advance_ready"),"Simple event executes directly with E, result primary stays left"): return
	await shot(game,"09-event-result"); await F.key(game,KEY_E)
	if not check(game,game.campaign.floor==4 and game.campaign.phase=="battle","Result E advances one node without exploration interstitial"): return
	game.auto_play=false; game.play_timer.stop(); game.cancel_presentation()
	fixture(game,"treasure"); game.show_campaign(); await F.wait(game); await F.key_event(game,KEY_X,true); await F.wait(game,.1)
	if not check(game,game.campaign.floor==3 and game.campaign.phase=="event","X skips only the unopened chest and advances once"): return
	frozen=Replay.hash_state(game.campaign); await F.key_event(game,KEY_X,true,true); await F.key_event(game,KEY_X,true)
	if not check(game,Replay.hash_state(game.campaign)==frozen,"Held X does not skip a destination event"): return
	await F.key_event(game,KEY_X,false)
	fixture(game,"treasure"); game.show_campaign(); await F.wait(game); await right(game)
	if not check(game,game.campaign.floor==3,"Explicit right-click skips an unopened chest"): return
	frozen=Replay.hash_state(game.campaign); await right(game)
	if not check(game,Replay.hash_state(game.campaign)==frozen,"Rapid right-click cannot skip destination event"): return
	# Mouse double click on a changing left primary must not activate the destination.
	fixture(game,"treasure"); game.show_campaign(); await F.wait(game)
	var main_point: Vector2=game.primary_button.get_global_rect().get_center()
	await F.click_at(game,main_point); await F.wait(game,.04); frozen=Replay.hash_state(game.campaign)
	for pressed in [true,false]:
		var twice:=InputEventMouseButton.new(); twice.button_index=MOUSE_BUTTON_LEFT; twice.position=main_point; twice.global_position=main_point; twice.pressed=pressed; twice.double_click=pressed
		game.get_viewport().push_input(twice,true); await game.get_tree().process_frame
	if not check(game,game.campaign.phase=="reward" and Replay.hash_state(game.campaign)==frozen,"Navigation double click cannot trigger destination receipt or advance"): return
	# Native drag cancellation must not invoke the underlying chest skip.
	fixture(game,"treasure"); var drag_uid: String=E.add_item(game.campaign,"I02"); game.show_campaign(); await F.wait(game)
	var point: Vector2=F.cell(game.screen,"inventory",drag_uid).get_global_rect().get_center()
	await F.click_at(game,point)
	var press:=InputEventMouseButton.new(); press.button_index=MOUSE_BUTTON_LEFT; press.position=point; press.global_position=point; press.pressed=true; game.get_viewport().push_input(press,true); await game.get_tree().process_frame
	for i in range(1,5):
		var move:=InputEventMouseMotion.new(); move.position=point+Vector2(i*20,0); move.global_position=move.position; move.relative=Vector2(20,0); move.button_mask=MOUSE_BUTTON_MASK_LEFT; game.get_viewport().push_input(move,true); await game.get_tree().process_frame
	if not check(game,game.get_viewport().gui_is_dragging(),"Real inventory drag started"): return
	frozen=Replay.hash_state(game.campaign); await right(game,point+Vector2(80,0)); press.pressed=false; game.get_viewport().push_input(press,true); await F.wait(game,.1)
	if not check(game,not game.get_viewport().gui_is_dragging() and Replay.hash_state(game.campaign)==frozen and game.campaign.phase=="treasure","Right-click cancels drag only, no chest action"): return
	# Complex keyboard and click conventions, using temporary test data only.
	var event_original: Dictionary=game.cfg.journey.events.EV01.duplicate(true)
	var complex: Dictionary=event_original.duplicate(true); complex.choices[1]={"id":"study","label":"記録を読む","effect":"exp","amount":1,"result":"記録を読んだ。"}; game.cfg.journey.events.EV01=complex
	fixture(game,"event",3); game.campaign.event="EV01"; game.show_campaign(); await F.wait(game); frozen=Replay.hash_state(game.campaign); await F.key(game,KEY_E)
	if not check(game,Replay.hash_state(game.campaign)==frozen and game.event_choice=="","Complex event E cannot choose an unselected option"): return
	await F.key(game,KEY_2)
	if not check(game,game.event_choice=="study" and game.campaign.phase=="event","Keyboard selection does not commit"): return
	await F.key(game,KEY_E)
	if not check(game,game.campaign.phase=="event_result","Selected complex event E commits once"): return
	fixture(game,"event",3); game.campaign.event="EV01"; game.show_campaign(); await F.nav(game,"choice-study")
	if not check(game,game.campaign.phase=="event_result","Complex choice click commits without a second confirmation"): return
	game.cfg.journey.events.EV01=event_original
	# Explicit full-bag picker, modal isolation and concrete loss/gain.
	fixture(game); var lost: String=E.add_item(game.campaign,"I02"); game.campaign.item_condition[lost].current=37
	while game.campaign.inventory.size()<15: E.add_item(game.campaign,"I10")
	E.Journey.add_reward(game.campaign,"I11"); var token: String=game.campaign.pending_rewards[0].token
	game.show_campaign(); await F.wait(game); await shot(game,"10-full-reward"); frozen=Replay.hash_state(game.campaign)
	await F.nav(game,"replace-reward-"+token); await shot(game,"11-replacement-picker")
	var view: Control=F.shell(game); await F.wait(game); await game.click_control(F.cell(view.modal_root,"inventory",lost)); await F.wait(game,.15)
	if not check(game,game.reward_confirmation=="exchange" and "失う品："+game.cfg.items.I02.name in text(game) and "得る品："+game.cfg.items.I11.name in text(game),"Replacement confirmation identifies both specific items"): return
	await shot(game,"12-loss-gain-confirmation")
	for code in [KEY_C,KEY_I,KEY_TAB,KEY_E,KEY_SPACE]: await F.key(game,code)
	await F.click_at(game,Vector2(120,270)); await F.wait(game,.1)
	if not check(game,Replay.hash_state(game.campaign)==frozen and not game.field_status and not game.field_equipment and game.reward_confirmation=="exchange" and view.modal_root.is_ancestor_of(game.get_viewport().gui_get_focus_owner()),"Modal blocks C I E Space and background clicks; Tab stays within modal"): return
	await F.key(game,KEY_ESCAPE)
	if not check(game,Replay.hash_state(game.campaign)==frozen and game.reward_confirmation=="","Esc cancels replacement without mutations"): return
	await F.nav(game,"confirm-abandon"); await F.key(game,KEY_X)
	if not check(game,Replay.hash_state(game.campaign)==frozen and game.reward_confirmation=="","X cancels abandonment without mutations"): return
	await F.nav(game,"confirm-abandon"); await F.wait(game); await right(game)
	if not check(game,Replay.hash_state(game.campaign)==frozen and game.reward_confirmation=="","Right-click cancels abandonment without mutations"): return
	await F.nav(game,"replace-reward-"+token); view=F.shell(game); await F.wait(game); await game.click_control(F.cell(view.modal_root,"inventory",lost)); await F.wait(game)
	await F.command(game,"exchange_reward",{"confirmed":true,"replace_uid":lost,"token":token})
	if not check(game,game.campaign.pending_rewards.is_empty() and lost not in game.campaign.items and game.campaign.inventory.size()==15,"Confirmed replacement loses only chosen UID, gains once, stays within capacity"): return
	await shot(game,"13-received-complete")
	if not check(game,"受け取り完了" in text(game) and not "クリックで比較・詳細" in text(game) and not "未受領 0" in text(game),"No-pending screen removes nonexistent reward guidance"): return
	# A reward can still directly equip into an empty slot at full capacity.
	E.Journey.add_reward(game.campaign,"I04"); game.show_campaign(); await F.wait(game); token=game.campaign.pending_rewards[0].token
	await F.command(game,"equip_reward",{"token":token})
	if not check(game,game.campaign.equipment.feet!="" and game.campaign.inventory.size()==15 and game.campaign.pending_rewards.is_empty(),"Full bag still accepts reward directly into empty equipment slot"): return
	# Numeric refresh updates existing controls; reconstruction restores scroll on the same context/target.
	fixture(game,"battle",4); game.campaign.highest_floor=10
	game.campaign.battle={"enemy_id":"E04","enemy_level":3,"seed":123,"hero":E.hero(game.campaign,game.cfg),"rounds":0,"rules_version":3,"encounter_version":2}
	game.presenting=true; game.presentation_battle=E.battle_state(game.campaign,game.data)
	game.presentation_battle.enemy.statuses={"poison":{"remaining":3,"potency":1,"skill":"S102"},"blind":{"remaining":2,"potency":.2,"skill":"S103"},"paralysis":{"remaining":1,"potency":0,"skill":"S104"}}
	game.presentation_battle.enemy.defense_until=3; game.presentation_battle.enemy.action_count=0
	game.flow_selection={"kind":"actor","side":"enemy"}; game.show_campaign(); await F.wait(game); view=F.shell(game)
	view.detail_scroll.scroll_vertical=65; await F.wait(game,.1); var scroll_y: int=view.detail_scroll.scroll_vertical; var scroll_control: Control=view.detail_scroll
	if not check(game,scroll_y>=50 and view.detail_heading.text=="敵の情報" and "Lv.3" in text(game),"Enemy detail has actual scroll and matching heading/level"): return
	game.impact({"type":"attack","target":"enemy","target_hp":game.presentation_battle.enemy.hp-1})
	if not check(game,view.detail_scroll==scroll_control and view.detail_scroll.scroll_vertical==scroll_y and game.flow_selection.side=="enemy","Numeric impact keeps same detail Control, selection and scroll"): return
	await shot(game,"14-detail-scroll-kept"); view.open_routes(); await F.wait(game,.15); view.map_scroll.scroll_vertical=35; await F.wait(game,.1); var map_y: int=view.map_scroll.scroll_vertical
	if not check(game,map_y>0,"Expanded map can scroll"): return
	game.show_campaign(); await F.wait(game); view=F.shell(game)
	if not check(game,game.route_map_open and view.map_scroll.scroll_vertical==map_y and view.detail_scroll.scroll_vertical==scroll_y and game.flow_selection.side=="enemy","Same-context rebuild keeps map and detail scroll and target"): return
	await shot(game,"15-map-scroll-kept"); await F.key(game,KEY_ESCAPE)
	game.presentation_battle.enemy.hp=0; view.refresh_live()
	if not check(game,game.flow_selection.side=="hero" and view.detail_heading.text=="主人公の状態" and not view.actor_huds.enemy.visible,"Dead enemy clears stale details and selects living hero"): return
	game.cancel_presentation(); game.campaign.phase="reward"; game.campaign.battle={}; game.campaign.pending_rewards=[]; game.show_campaign(); await F.wait(game)
	game.campaign.floor=5; game.campaign.highest_floor=10; game.campaign.phase="treasure"; game.show_campaign(); await F.wait(game)
	if not check(game,game.flow_memory.context.ends_with("/5") and game.flow_memory.map==-1,"Floor change intentionally clears old map context"): return
	# Repair reasons on actual UI, preserving normal equipment and gold rules.
	fixture(game,"town",0); worn=E.add_item(game.campaign,"I02"); game.campaign.inventory.erase(worn); game.campaign.equipment.body=worn; game.campaign.item_condition[worn].current=37; game.equipment_focus="body"; game.town_page="equipment"; game.show_campaign(); await F.wait(game)
	if not check(game,"所持金不足" in text(game) and "修理後" in text(game),"Town repair shortage and restored delta visible"): return
	game.campaign.gold=100; game.show_campaign(); await F.wait(game); await F.command(game,"repair",{"uid":worn})
	if not check(game,"修理不要" in text(game) and game.campaign.item_condition[worn].current==100,"Repair commits once and becomes unnecessary"): return
	await shot(game,"16-repaired-current")
	game.show_title(); await F.wait(game)
	UI.write(game,{"complete":true,"rendered":true,"run_id":game.smoke_run_id,"version":ProjectSettings.get_setting("application/config/version"),"no_save_store":game.save_store==null,"exit_button_pressed":true,"normal_fresh_status_return":true,"normal_departure_space":true,"checks":{"status_reentry":true,"shared_current":true,"left_primary":true,"simple_and_complex_input":true,"input_carry_and_drag_cancel":true,"scroll_and_target":true,"modal_isolation":true,"full_replacement":true,"empty_slot_reward_equip":true,"text_and_repair":true}},"review-fixes.json")
	await F.nav(game,"quit")
