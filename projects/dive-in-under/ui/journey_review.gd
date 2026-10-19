extends RefCounted
const E=preload("res://core/expedition.gd")
const UI=preload("res://ui/integration_review.gd")
const Replay=preload("res://ui/campaign_replay.gd")
static func wait(game: Control, duration: float=0.08) -> void:
	await game.get_tree().create_timer(duration).timeout
static func checkpoint(game: Control, value: String) -> void:
	UI.write(game,{"stage":value,"run_id":game.smoke_run_id,"revision":game.campaign.get("revision",0),"phase":game.campaign.get("phase","")},"progress.json")
static func key(game: Control, code: Key, echo: bool=false) -> void:
	for pressed in [true,false]:
		var event:=InputEventKey.new(); event.keycode=code; event.physical_keycode=code; event.pressed=pressed; event.echo=echo
		game.get_viewport().push_input(event,true); await game.get_tree().process_frame
	await wait(game)
static func idle(game: Control) -> void:
	for i in 300:
		if not game.presenting and not game.intro_active: return
		await game.get_tree().process_frame
	game.smoke_check(false,"Presentation/intro did not finish")
static func nav(game: Control, name: String) -> void:
	var b: Button=UI.find_nav(game.screen,name)
	if not game.smoke_check(b!=null and not b.disabled,"Enabled navigation "+name): return
	await game.click_control(b); await wait(game,0.03)
static func command(game: Control, name: String, args: Dictionary={}) -> void:
	var b: Button=Replay.find_command(game.screen,name,args)
	if not game.smoke_check(b!=null and not b.disabled,"Enabled public command "+name+" "+str(args)): return
	await game.click_control(b); await wait(game,0.03)
static func close_equipment(game: Control) -> void:
	if game.field_equipment: await nav(game,"back")
static func town_page(game: Control, page: String) -> void:
	if game.town_page==page: return
	if game.town_page!="hub":
		var back: Button=UI.find_nav(game.screen,"back")
		if back==null: back=game.find_button(game.screen,"戻る")
		if not game.smoke_check(back!=null,"Town back path"): return
		await game.click_control(back); await wait(game,0.03)
	if page!="hub": await nav(game,page)
static func shift_click(game: Control, b: Button) -> void:
	var point: Vector2=b.get_global_rect().get_center()
	for pressed in [true,false]:
		var event:=InputEventMouseButton.new(); event.button_index=MOUSE_BUTTON_LEFT; event.position=point; event.global_position=point; event.pressed=pressed; event.shift_pressed=true
		game.get_viewport().push_input(event,true); await game.get_tree().process_frame
	await wait(game,0.08)
static func drag(game: Control, b: Button, destination: Vector2, screenshot: String="") -> void:
	var start: Vector2=b.get_global_rect().get_center()
	var motion:=InputEventMouseMotion.new(); motion.position=start; motion.global_position=start
	game.get_viewport().push_input(motion,true); await game.get_tree().process_frame
	var press:=InputEventMouseButton.new(); press.button_index=MOUSE_BUTTON_LEFT; press.position=start; press.global_position=start; press.pressed=true
	game.get_viewport().push_input(press,true); await game.get_tree().process_frame
	for i in range(1,7):
		var move:=InputEventMouseMotion.new(); move.position=start.lerp(destination,float(i)/6.0); move.global_position=move.position; move.relative=(destination-start)/6.0; move.button_mask=MOUSE_BUTTON_MASK_LEFT
		game.get_viewport().push_input(move,true); await game.get_tree().process_frame
	if screenshot!="": await game.capture(screenshot+".png")
	var release:=InputEventMouseButton.new(); release.button_index=MOUSE_BUTTON_LEFT; release.position=destination; release.global_position=destination; release.pressed=false
	game.get_viewport().push_input(release,true); await wait(game,0.12)
static func run(game: Control) -> void:
	if not game.smoke_check(DisplayServer.get_name()!="headless" and game.save_store==null and game.campaign.is_empty(),"Fresh normal EXE, isolated rendering, no SaveStore"): return
	var plan_path: String=""
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--journey-plan="): plan_path=arg.trim_prefix("--journey-plan=")
	var plan=JSON.parse_string(FileAccess.get_file_as_string(plan_path))
	if not game.smoke_check(plan is Dictionary and plan.complete and plan.seed==10000,"Bounded fresh acceptance plan"): return
	await game.capture("01-title.png"); await nav(game,"start"); await game.capture("02-preparation.png")
	var seen: Dictionary={}; var paused_tested:=false; var field_equips:=0; var clear_seen:=false; var steps:=0
	for expected in plan.actions:
		checkpoint(game,"route-%d-%s"%[steps,expected.action])
		if expected.action!="round": await idle(game)
		if game.campaign.phase=="battle" and game.intro_active and not seen.has("intro"):
			if not game.smoke_check(game.campaign.battle.rounds==0 and game.play_timer.is_stopped(),"No damage before encounter display"): return
			await game.capture("03-encounter.png"); seen.intro=true
		if expected.action=="round":
			var revision: int=game.campaign.revision
			for frame in 300:
				if game.campaign.revision>revision: break
				await game.get_tree().process_frame
			if not game.smoke_check(game.campaign.revision==int(expected.revision),"Exactly one normal Timer round"): return
			if not seen.has("impact"):
				await wait(game,0.06); await game.capture("04-attack-before-impact.png")
				await wait(game,0.04); await game.capture("04-attack-impact.png")
				await wait(game,0.05); await game.capture("04-attack-return.png"); seen.impact=true
			if not paused_tested and game.campaign.phase=="battle":
				await key(game,KEY_SPACE)
				var frozen: String=Replay.hash_state(game.campaign)
				await key(game,KEY_SPACE,true); await wait(game,1.3)
				if not game.smoke_check(not game.auto_play and game.play_timer.is_stopped() and not game.presenting and Replay.hash_state(game.campaign)==frozen,"Pause cancels visual motion and freezes full state through echo/time"): return
				await game.capture("05-battle-paused.png"); await key(game,KEY_SPACE); paused_tested=true
		else:
			if expected.action in ["equip","repair"]:
				if game.campaign.phase=="town": await town_page(game,"equipment")
				elif not game.field_equipment: await nav(game,"field-equipment")
				var uid: String=expected.args.uid
				if expected.action=="equip":
					await nav(game,"compare-"+uid)
					if game.campaign.phase!="town" and not seen.has("compare"):
						await game.capture("06-field-comparison.png"); seen.compare=true
					if game.campaign.phase!="town": field_equips+=1
				else:
					for slot in E.SLOTS:
						if game.campaign.equipment[slot]==uid: await nav(game,"slot-"+slot); break
			elif expected.action=="deposit":
				await town_page(game,"warehouse")
				await game.click_control(game.warehouse_view.rows[expected.args.uid]); await wait(game)
			elif expected.action=="depart": await town_page(game,"hub")
			else: await close_equipment(game)
			if game.campaign.phase=="treasure" and not seen.has("chest"):
				await game.capture("07-chest-discovered.png"); seen.chest=true
			if game.campaign.phase=="reward" and not seen.has("reward") and not game.campaign.pending_rewards.is_empty():
				await game.capture("08-reward-receipt.png"); seen.reward=true
			if game.campaign.phase=="event" and not seen.has("event"):
				await game.capture("09-event-choice.png"); seen.event=true
			if game.campaign.phase=="event_result" and not seen.has("event_result"):
				await game.capture("09-event-result.png"); seen.event_result=true
			if expected.action=="abandon_rewards": await nav(game,"confirm-abandon")
			await command(game,expected.action,expected.args)
		if not game.smoke_check(Replay.hash_state(game.campaign)==expected.sha256,"Same core state on public UI route at step %d %s"%[steps,expected.action]): return
		if game.campaign.phase=="battle" and game.campaign.floor==10 and not seen.has("boss"):
			await game.capture("10-boss-intro.png"); seen.boss=true
		if game.campaign.phase=="result" and game.campaign.result.kind=="clear":
			await game.capture("11-10F-clear.png"); clear_seen=true
		steps+=1
	if not game.smoke_check(clear_seen and paused_tested and field_equips>0 and game.campaign.trips>plan.cleared_trip and game.campaign.highest_floor==11,"Fresh normal loop cleared, field upgrades, return and redepart"): return
	game.auto_play=false; game.play_timer.stop(); game.cancel_presentation(); await game.capture("12-redeparture.png")
	var normal_result: Dictionary={"steps":steps,"clear_trip":plan.cleared_trip,"final_trips":game.campaign.trips,"field_equips":field_equips,"highest_floor":game.campaign.highest_floor,"prepared_growth_or_gear":false,"viewport_input":true,"normal_timer":true}
	# Safety fixtures are kept separate from the fresh route evidence above.
	checkpoint(game,"fixtures-warehouse")
	game.campaign=E.fresh(game.cfg,123); E.Journey.enable(game.campaign); game.campaign.phase="town"; game.campaign.trips=0
	var uid:=E.add_item(game.campaign,"I02"); game.campaign.item_condition[uid].current=37
	E.add_item(game.campaign,"I07"); game.open_town_page("warehouse"); await wait(game)
	var unchanged: String=Replay.hash_state(game.campaign)
	await game.click_control(game.warehouse_view.rows[uid]); await wait(game)
	if not game.smoke_check(game.warehouse_state.uid==uid and Replay.hash_state(game.campaign)==unchanged,"Click selects without transfer"): return
	await shift_click(game,game.warehouse_view.rows[uid])
	if not game.smoke_check(uid in game.campaign.warehouse and game.campaign.item_condition[uid].current==37,"Shift deposits one unchanged instance"): return
	await drag(game,game.warehouse_view.rows[uid],game.warehouse_view.bag_scroll.get_global_rect().get_center(),"13-warehouse-drag-target")
	if not game.smoke_check(uid in game.campaign.inventory and game.campaign.item_condition[uid].current==37,"Native drag withdraws same instance"): return
	unchanged=Replay.hash_state(game.campaign)
	await drag(game,game.warehouse_view.rows[uid],Vector2(-20,-20))
	if not game.smoke_check(Replay.hash_state(game.campaign)==unchanged,"Outside drop never destroys or duplicates"): return
	await game.capture("13-warehouse.png")
	checkpoint(game,"fixtures-full-receipt")
	game.campaign.phase="treasure"; game.campaign.trips=1; game.campaign.floor=2; game.campaign.highest_floor=2
	while game.campaign.inventory.size()<15: E.add_item(game.campaign,"I10")
	E.Journey.add_reward(game.campaign,"I11"); game.show_campaign(); await command(game,"open_chest")
	var token: String=game.campaign.pending_rewards[0].token
	await game.capture("14-backpack-full-reward.png"); unchanged=Replay.hash_state(game.campaign); await key(game,KEY_ESCAPE)
	if not game.smoke_check(Replay.hash_state(game.campaign)==unchanged and game.campaign.pending_rewards.size()==1,"Esc retains unclaimed full-bag reward"): return
	await nav(game,"replace-"+uid); await nav(game,"confirm-exchange")
	await command(game,"exchange_reward",{"confirmed":true,"replace_uid":uid,"token":token})
	if not game.smoke_check(game.campaign.inventory.size()==15 and game.campaign.pending_rewards.is_empty() and not game.campaign.items.has(uid) and E.validate(game.campaign,game.data,game.cfg)=="","Confirmed full bag exchange is atomic"): return
	await command(game,"continue_rewards")
	checkpoint(game,"fixtures-return-reset")
	game.route_map_open=true; E.finish(game.campaign,"death","固定の敗北遷移確認",game.cfg); game.show_campaign(); await command(game,"town")
	await key(game,KEY_ESCAPE)
	if not game.smoke_check(game.title_visible and not game.route_map_open and not game.presenting,"First town Esc, map and presentation reset after defeat"): return
	var quit: Button=UI.find_nav(game.screen,"quit")
	quit.pressed.connect(func():UI.write(game,{"complete":true,"rendered":true,"no_save_store":game.save_store==null,"run_id":game.smoke_run_id,"exit_button_pressed":true,"normal_route":normal_result,"fixtures":{"click_select":true,"shift":true,"native_drag":true,"outside_drop":true,"identity_durability":37,"full_receipt":true,"death_reset":true},"seen":seen},"journey-review.json"))
	await game.click_control(quit)
