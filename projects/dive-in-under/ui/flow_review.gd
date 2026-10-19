extends RefCounted
## Focused UI acceptance, one exported EXE. Normal first trip and separately labelled safety fixtures.
const E=preload("res://core/expedition.gd")
const UI=preload("res://ui/integration_review.gd")
const Old=preload("res://ui/journey_review.gd")
const Replay=preload("res://ui/campaign_replay.gd")
static func wait(game: Control, seconds: float=.55) -> void:
	await game.get_tree().create_timer(seconds).timeout
static func check(game: Control, value: bool, text: String) -> bool:
	return game.smoke_check(value,text)
static func nav(game: Control, id: String) -> void:
	await wait(game)
	var b:=UI.find_nav(game.screen,id)
	if not check(game,b!=null and not b.disabled,"Enabled nav "+id): return
	await game.click_control(b); await wait(game,.08)
static func command(game: Control, id: String, args: Dictionary={}) -> void:
	await wait(game)
	var b:=Replay.find_command(game.screen,id,args)
	if not check(game,b!=null and not b.disabled,"Enabled action "+id): return
	await game.click_control(b); await wait(game,.08)
static func key_event(game: Control, code: Key, pressed: bool, echo: bool=false) -> void:
	var event:=InputEventKey.new(); event.keycode=code; event.physical_keycode=code; event.pressed=pressed; event.echo=echo
	game.get_viewport().push_input(event,true); await game.get_tree().process_frame
static func key(game: Control, code: Key) -> void:
	await wait(game); await key_event(game,code,true); await key_event(game,code,false); await wait(game,.08)
static func click_at(game: Control, point: Vector2) -> void:
	for pressed in [true,false]:
		var event:=InputEventMouseButton.new(); event.button_index=MOUSE_BUTTON_LEFT; event.position=point; event.global_position=point; event.pressed=pressed
		game.get_viewport().push_input(event,true); await game.get_tree().process_frame
static func cell(node: Node, source: String, uid: String="", slot: String="") -> Button:
	if node is Button and node.get_meta("item_source","")==source and node.get_meta("item_uid","")==uid and node.get_meta("equip_slot","")==slot: return node
	for child in node.get_children():
		var found:=cell(child,source,uid,slot)
		if found: return found
	return null
static func meta_button(node: Node, key_name: String, value: String) -> Button:
	if node is Button and node.get_meta(key_name,"")==value: return node
	for child in node.get_children():
		var found:=meta_button(child,key_name,value)
		if found: return found
	return null
static func logos(node: Node) -> int:
	var n: int=1 if node.name in ["ProductLogo","TitleLogo"] else 0
	for child in node.get_children(): n+=logos(child)
	return n
static func shell(game: Control) -> Control:
	for child in game.play_view.get_children():
		if child.get_script()==preload("res://ui/flow_view.gd"): return child
	return null
static func shot(game: Control, filename: String) -> void:
	await game.capture(filename+".png")
	if not check(game,logos(game.screen)==0,"No in-game logo: "+filename): return
	var view:=shell(game)
	if view:
		var audit: Dictionary=view.visual_audit()
		if not check(game,audit.left_rect==[16,86,224,266] and audit.map_rect==[982,86,282,260],"Stable left/menu and map: "+filename): return
static func fixture(game: Control) -> void:
	game.cancel_presentation(); game.intro_active=false; game.intro_seen={}; game.auto_play=false; game.play_timer.stop(); game.route_map_open=false; game.field_equipment=false; game.field_status=false
	game.campaign=E.fresh(game.cfg,123); E.Journey.enable(game.campaign); game.campaign.phase="reward"; game.campaign.floor=2; game.campaign.highest_floor=2; game.campaign.reward_origin="宝箱"; game.campaign.reward_return="explore"; game.flow_selection={"kind":"actor","side":"hero"}; game.reward_confirmation=""; game.replace_selected=""
static func double_click(game: Control, button: Button) -> void:
	var point: Vector2=button.get_global_rect().get_center()
	for pressed in [true,false]:
		var event:=InputEventMouseButton.new(); event.button_index=MOUSE_BUTTON_LEFT; event.position=point; event.global_position=point; event.pressed=pressed; event.double_click=pressed
		game.get_viewport().push_input(event,true); await game.get_tree().process_frame
	await wait(game,.12)
static func run(game: Control) -> void:
	if not check(game,DisplayServer.get_name()!="headless" and game.save_store==null and game.campaign.is_empty(),"Fresh isolated actual distribution EXE"): return
	await game.capture("00-title.png"); if not check(game,logos(game.screen)==1,"Title retains exactly one adopted logo"): return
	await nav(game,"start"); await shot(game,"01-preparation")
	await key(game,KEY_E)
	await key_event(game,KEY_SPACE,true); await key_event(game,KEY_SPACE,false); await wait(game,.5)
	if not check(game,game.campaign.floor==1 and game.campaign.phase=="battle" and not game.auto_play,"Normal first encounter paused"): return
	await shot(game,"02-battle")
	var b: Button=meta_button(game.screen,"actor_select","enemy"); await game.click_control(b)
	if not check(game,game.flow_selection.get("side")=="enemy","Enemy HP click selects lower-right detail"): return
	await shot(game,"03-enemy-detail")
	var frozen: String=Replay.hash_state(game.campaign)
	await key(game,KEY_E); await wait(game,.7)
	if not check(game,Replay.hash_state(game.campaign)==frozen and game.flow_selection.get("side")=="enemy","Battle E cannot progress; selection stable through wait"): return
	await key(game,KEY_C); await wait(game,.25); await shot(game,"04-field-status")
	if not check(game,game.field_status and Replay.hash_state(game.campaign)==frozen,"Field status is read-only"): return
	await game.click_control(game.status_view.back_button); await wait(game,.3)
	if not check(game,not game.field_status and not game.auto_play and game.flow_selection.get("side")=="enemy","Status returns to same paused situation/target"): return
	await key(game,KEY_SPACE)
	for i in 350:
		if game.campaign.phase=="reward" and not game.presenting: break
		await game.get_tree().process_frame
	if not check(game,game.campaign.phase=="reward" and not game.presenting,"Normal battle timer reaches reward"): return
	await key(game,KEY_E)
	if not check(game,game.campaign.floor==2 and game.campaign.phase=="treasure","One primary moves from battle confirmation to one next node"): return
	await shot(game,"05-chest")
	await wait(game)
	await key_event(game,KEY_E,true); await wait(game,.12)
	if not check(game,game.campaign.phase=="reward","E opens chest"): return
	frozen=Replay.hash_state(game.campaign)
	await key_event(game,KEY_E,true,true); await key_event(game,KEY_E,true); await wait(game,.65)
	if not check(game,Replay.hash_state(game.campaign)==frozen,"E held and echo do not receive/advance destination"): return
	await key_event(game,KEY_E,false)
	await shot(game,"06-rewards")
	var receipt: Dictionary=game.campaign.duplicate(true)
	var view:=shell(game); await click_at(game,view.route.get_global_rect().position+Vector2(70,65)); await wait(game,.12)
	if not check(game,game.route_map_open,"Minimap opens detailed vertical map"): return
	await shot(game,"07-map-pending")
	await key(game,KEY_ESCAPE)
	if not check(game,not game.route_map_open and game.campaign==receipt,"Map close preserves pending receipt exactly"): return
	await key(game,KEY_E)
	if not check(game,game.campaign.floor==3 and game.campaign.phase=="event" and game.campaign.pending_rewards.is_empty() and game.campaign.inventory.size()==receipt.inventory.size()+1,"One E receives all and advances exactly one node"): return
	var event_state: String=Replay.hash_state(game.campaign)
	await key(game,KEY_E)
	if not check(game,Replay.hash_state(game.campaign)==event_state,"E cannot choose an unselected option"): return
	await shot(game,"08-event-choice")
	var choice: Dictionary=game.cfg.journey.events[game.campaign.event].choices[0]
	await game.click_control(meta_button(game.screen,"event_choice",choice.id)); await key(game,KEY_E)
	if not check(game,game.campaign.phase=="event_result","Explicit selected event choice resolves once"): return
	await shot(game,"09-event-result")
	var result_state: String=Replay.hash_state(game.campaign)
	await key(game,KEY_I)
	if not check(game,game.field_equipment and game.campaign.phase=="event_result","I opens equipment without acknowledging event result"): return
	var uid: String=game.campaign.inventory[0]; var item_slot: String=game.cfg.items[game.campaign.items[uid]].slot
	await game.click_control(cell(game.screen,"inventory",uid)); await wait(game,.1); await shot(game,"10-equipment")
	await double_click(game,cell(game.screen,"inventory",uid))
	if not check(game,game.campaign.equipment[item_slot]==uid and game.campaign.phase=="event_result","Native double click equips directly in field"): return
	await key(game,KEY_ESCAPE)
	if not check(game,not game.field_equipment and game.campaign.phase=="event_result","Equipment close retains event result"): return
	await key(game,KEY_E)
	if not check(game,game.campaign.floor==4 and game.campaign.phase=="battle" and game.campaign.battle.hero.def==E.hero(game.campaign,game.cfg).def,"Event result E reaches next battle with changed stats"): return
	game.auto_play=false; game.play_timer.stop(); await wait(game,.5)
	var normal: Dictionary={"from_fresh_start":true,"first_trip_to_floor":4,"received_all_one_input":true,"event_result_one_input":true,"field_double_click":true,"new_battle_stats":true}
	# Separate 15-slot fixture; never installed into normal new-game state.
	fixture(game)
	var old: String=E.add_item(game.campaign,"I02"); game.campaign.inventory.erase(old); game.campaign.equipment.body=old; game.campaign.item_condition[old].current=37
	var candidate: String=E.add_item(game.campaign,"I02")
	while game.campaign.inventory.size()<14: E.add_item(game.campaign,"I10")
	var boots: String=E.add_item(game.campaign,"I04")
	E.Journey.add_reward(game.campaign,"I11"); var token: String=game.campaign.pending_rewards[0].token
	game.show_campaign(); await wait(game); await shot(game,"11-full-reward")
	frozen=Replay.hash_state(game.campaign); await key(game,KEY_E)
	if not check(game,Replay.hash_state(game.campaign)==frozen,"Full primary keeps all pending items"): return
	await key(game,KEY_I)
	await Old.drag(game,cell(game.screen,"inventory",candidate),cell(game.screen,"equipment",old,"body").get_global_rect().get_center(),"12-valid-gear-drop")
	if not check(game,game.campaign.equipment.body==candidate and old in game.campaign.inventory and game.campaign.inventory.size()==15 and game.campaign.item_condition[old].current==37,"Native full one-for-one swap preserves old UID/condition"): return
	frozen=Replay.hash_state(game.campaign)
	await Old.drag(game,cell(game.screen,"inventory",old),cell(game.screen,"equipment","","eyes").get_global_rect().get_center())
	if not check(game,Replay.hash_state(game.campaign)==frozen,"Incompatible slot rejects without mutation"): return
	await Old.drag(game,cell(game.screen,"inventory",old),Vector2(-20,-20))
	if not check(game,Replay.hash_state(game.campaign)==frozen,"Outside drop restores source"): return
	await Old.drag(game,cell(game.screen,"equipment",candidate,"body"),cell(game.screen,"inventory",old).get_global_rect().get_center())
	if not check(game,Replay.hash_state(game.campaign)==frozen,"Full backpack rejects equipped-to-bag drag"): return
	await double_click(game,cell(game.screen,"inventory",boots))
	if not check(game,game.campaign.inventory.size()==14 and game.campaign.equipment.feet==boots,"Equip from bag frees one slot"): return
	await Old.drag(game,cell(game.screen,"equipment",candidate,"body"),cell(game.screen,"inventory",old).get_global_rect().get_center())
	if not check(game,game.campaign.equipment.body=="" and candidate in game.campaign.inventory and game.campaign.inventory.size()==15 and game.campaign.item_condition[old].current==37,"Equipped-to-bag drag succeeds with one free slot, preserving both instances"): return
	await key(game,KEY_ESCAPE)
	await double_click(game,cell(game.screen,"pending",token))
	if not check(game,game.campaign.pending_rewards.is_empty() and game.campaign.equipment.finger!="" and game.campaign.inventory.size()==15,"Pending reward equips directly into free slot without loss or extra capacity"): return
	await shot(game,"13-direct-reward-equip")
	await key(game,KEY_E)
	if not check(game,game.campaign.floor==3 and game.campaign.phase=="event","Received reward continues in one input"): return
	# Mouse double-click/carry-through on overlapping source/destination primary.
	fixture(game); E.Journey.add_reward(game.campaign,"I02"); game.campaign.phase="treasure"; game.show_campaign(); await wait(game)
	b=Replay.find_command(game.screen,"open_chest",{}); var point: Vector2=b.get_global_rect().get_center()
	await click_at(game,point); await wait(game,.03); await click_at(game,point)
	if not check(game,game.campaign.phase=="reward" and game.campaign.pending_rewards.size()==1,"Rapid mouse repeat does not pierce destination primary"): return
	await key_event(game,KEY_E,true); await key_event(game,KEY_E,false)
	if not check(game,game.campaign.phase=="reward","Transition input quarantine rejects immediate E"): return
	await wait(game,.15); await key_event(game,KEY_E,true); await key_event(game,KEY_E,false)
	if not check(game,game.campaign.phase=="reward","Rapid fresh E repeats are rejected after release too"): return
	# Fitting all-receipt native click counts are fixed by actual controls, not a macro.
	await key(game,KEY_E)
	if not check(game,game.campaign.floor==3 and game.campaign.phase=="event","One receipt primary still advances after release/quiet interval"): return
	# Existing status identities, read-only display fixture for movement/cleanup.
	fixture(game); game.campaign.phase="battle"; game.campaign.floor=4; game.campaign.highest_floor=4
	game.campaign.battle={"enemy_id":"E04","enemy_level":3,"seed":123,"hero":E.hero(game.campaign,game.cfg),"rounds":0,"rules_version":3,"encounter_version":2}
	game.presenting=true; game.presentation_battle=E.battle_state(game.campaign,game.data)
	game.presentation_battle.hero.statuses={"poison":{"remaining":3,"potency":1,"skill":"S102"},"blind":{"remaining":2,"potency":.2,"skill":"S103"}}
	game.presentation_battle.enemy.statuses={"paralysis":{"remaining":1,"potency":0,"skill":"S104"}}
	game.show_campaign(); await shot(game,"14-status-around-actors")
	var stage: Control=game.play_view.stage; var overlay: Control
	for child in stage.get_children():
		if child.get_script()==preload("res://ui/status_overlay.gd"): overlay=child
	var origin: Vector2=stage.hero_art.position; stage.hero_art.position+=Vector2(-18,0)
	if not check(game,overlay.point("hero")==stage.hero_art.position,"Status anchor follows real attack sprite"): return
	await shot(game,"15-status-follow-motion"); stage.hero_art.position=origin
	game.presentation_battle.hero.statuses={}; game.presentation_battle.enemy.statuses={}; shell(game).refresh_live()
	await shot(game,"16-status-cleared")
	game.flow_selection={"kind":"actor","side":"enemy"}; game.presentation_battle.enemy.hp=0; shell(game).refresh_live()
	if not check(game,game.flow_selection.get("side")=="hero" and not shell(game).actor_huds.enemy.visible,"Defeated target clears old enemy detail and HP"): return
	game.cancel_presentation(); game.intro_active=false; game.campaign.phase="reward"; game.campaign.battle={}; game.campaign.pending_rewards=[]; game.show_campaign(); await shot(game,"17-after-battle")
	if not check(game,not is_instance_valid(stage) or not stage.is_inside_tree(),"Old actor effects removed on screen switch"): return
	fixture(game); game.campaign.phase="battle"; game.campaign.floor=10; game.campaign.highest_floor=10
	game.campaign.battle={"enemy_id":"B10","enemy_level":10,"seed":123,"hero":E.hero(game.campaign,game.cfg),"rounds":0,"rules_version":3,"encounter_version":2}
	game.show_campaign(); await wait(game,1.0); await shot(game,"18-boss-and-deep-map")
	var deep: Control=shell(game).route
	var current_point: Vector2=deep.global_position+deep.positions()[9]
	if not check(game,deep.get_parent().get_global_rect().has_point(current_point) and not deep.nodes().any(func(n):return n.type_revealed),"Deep current node is scrolled into view without revealing contents"): return
	game.campaign.phase="reward"; game.campaign.battle={}; game.campaign.pending_rewards=[]; game.show_campaign()
	# Restoration and rejection checks use the same core revision guard after UI gestures.
	if not check(game,E.validate(game.campaign,game.data,game.cfg)=="","Final fixture retains valid ownership/state"): return
	game.show_title(); await wait(game)
	UI.write(game,{"complete":true,"rendered":true,"run_id":game.smoke_run_id,"no_save_store":game.save_store==null,"normal":normal,"fixtures":{"full_one_for_one":true,"invalid_drop":true,"outside_drop":true,"full_unequip":true,"unequip_with_space":true,"deep_map":true,"dead_target_cleared":true,"pending_direct_equip":true,"held_E":true,"mouse_repeat":true,"map_preserves_pending":true,"stable_shell":true,"status_follows_sprite":true,"status_cleanup":true},"exit_button_pressed":true},"flow-review.json")
	await nav(game,"quit")
