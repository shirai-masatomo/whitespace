extends RefCounted
## Test-only UI driver: actual viewport clicks and the production Timer callback.
## The expected route is generated from fresh() + act(), never a prepared hero/save.
static func hash_state(s: Dictionary) -> String:
	return JSON.stringify(JSON.parse_string(JSON.stringify(s))).sha256_text()

static func find_command(node: Node, action: String, args: Dictionary) -> Button:
	if node is Button and node.get_meta("campaign_action","")==action and node.get_meta("campaign_args",{})==args: return node
	for child in node.get_children():
		var found:=find_command(child,action,args)
		if found!=null: return found
	return null

static func click(game: Control, action: String, args: Dictionary) -> bool:
	var target:=find_command(game.screen,action,args)
	if not game.smoke_check(target!=null and not target.disabled,"Missing/enabled command "+action): return false
	await game.get_tree().process_frame
	var parent:=target.get_parent()
	while parent!=null:
		if parent is ScrollContainer: parent.ensure_control_visible(target)
		parent=parent.get_parent()
	await game.click_control(target)
	return true

static func write_result(game: Control, record: Dictionary) -> void:
	var f:=FileAccess.open(game.smoke_dir.path_join("campaign-ui.json"),FileAccess.WRITE)
	f.store_string(JSON.stringify(record,"\t")); f.close()

static func run(game: Control) -> void:
	var report=JSON.parse_string(FileAccess.get_file_as_string(game.campaign_replay_path))
	if not game.smoke_check(report is Dictionary and report.has("replay") and report.replay.cleared,"Valid normal-campaign replay required"): return
	var replay: Dictionary=report.replay
	var rendered:=DisplayServer.get_name()!="headless"
	var index:=0
	game.play_timer.one_shot=true
	game.auto_play=false
	if game.campaign_final_probe:
		var prior=JSON.parse_string(FileAccess.get_file_as_string(game.smoke_dir.path_join("campaign-ui.json")))
		if not game.smoke_check(prior is Dictionary and prior.complete and game.loaded.ok and prior.save_sha256==game.save_store.digest() and game.campaign.highest_floor==11 and game.campaign.story_deaths==1,"Third EXE retains clear/EXP/Gold/equipment/storage state"): return
		var f:=FileAccess.open(game.smoke_dir.path_join("campaign-final.json"),FileAccess.WRITE)
		f.store_string(JSON.stringify({"run_id":game.smoke_run_id,"final_restart":true,"save_sha256":game.save_store.digest(),"highest_floor":game.campaign.highest_floor,"story_deaths":game.campaign.story_deaths,"rendered":rendered},"\t")); f.close()
		game.get_tree().quit(); return
	if game.campaign_resume:
		var prior=JSON.parse_string(FileAccess.get_file_as_string(game.smoke_dir.path_join("campaign-ui.json")))
		if not game.smoke_check(prior is Dictionary and prior.checkpoint and game.loaded.ok and prior.save_sha256==game.save_store.digest() and prior.state_sha256==hash_state(game.campaign),"Real EXE checkpoint restored exactly"): return
		index=int(prior.next_index)
		await game.click_control(game.continue_button)
	else:
		if rendered: await game.capture("11-campaign-title.png")
		await game.click_control(game.new_button)
		if is_instance_valid(game.confirm_button) and game.confirm_button.is_inside_tree(): await game.click_control(game.confirm_button)
		game.auto_play=false
		if not game.smoke_check(game.campaign.seed==replay.seed and game.campaign.exp==0 and not game.campaign.first_done,"Fresh normal starting stats/seed"): return
	var screenshots: Dictionary={}
	while index<replay.actions.size():
		var expected: Dictionary=replay.actions[index]
		game.auto_play=false; game.play_timer.stop()
		if expected.action=="round":
			var revision: int=game.campaign.revision
			# Same timeout signal as normal autoplay, accelerated only for this test.
			game.play_timer.start(0.001)
			while game.campaign.revision==revision: await game.get_tree().process_frame
		else:
			if not await click(game,expected.action,expected.args): return
		if not game.smoke_check(hash_state(game.campaign)==expected.state_sha256,"UI/core divergence at action %d %s"%[index,expected.action]): return
		index+=1
		if rendered:
			var name:=""
			if not game.campaign.first_done and game.campaign.floor==1: name="12-campaign-first.png"
			elif game.campaign.phase=="town": name="14-campaign-town.png"
			elif game.campaign.phase=="result" and game.campaign.result.kind=="story_death": name="13-campaign-first-death.png"
			elif game.campaign.phase=="result" and game.campaign.result.kind=="death": name="15-campaign-normal-death.png"
			elif game.campaign.phase=="battle" and game.campaign.floor==10: name="16-campaign-boss.png"
			elif game.campaign.phase=="result" and game.campaign.result.kind=="clear": name="17-campaign-clear.png"
			if name!="" and not screenshots.has(name): await game.capture(name); screenshots[name]=true
			# Art-review captures are observational: they do not mutate campaign state.
			var art_name := ""
			if game.campaign.phase=="battle" and game.campaign.battle.enemy_id=="E04": art_name="19-candidate-goblin.png"
			elif game.campaign.phase in ["explore","battle"] and game.campaign.floor>=7 and game.campaign.floor<10: art_name="22-candidate-deep.png"
			elif game.campaign.phase in ["explore","battle"] and game.campaign.floor>=4 and game.campaign.floor<=6: art_name="21-candidate-middle.png"
			elif game.campaign.phase=="explore" and game.campaign.floor==1: art_name="20-candidate-shallow.png"
			if art_name!="" and not screenshots.has(art_name): await game.capture(art_name); screenshots[art_name]=true
			if game.campaign.phase=="battle" and game.campaign.battle.enemy_id in ["E01","E02","E03","E05"]:
				var enemy_capture: String = "23-enemy-%s.png" % game.campaign.battle.enemy_id.to_lower()
				if not screenshots.has(enemy_capture): await game.capture(enemy_capture); screenshots[enemy_capture]=true
		if not game.campaign_resume and game.campaign.phase=="battle" and game.campaign.trips>=3 and game.campaign.battle.rounds==1:
			write_result(game,{"run_id":game.smoke_run_id,"checkpoint":true,"complete":false,"rendered":rendered,"next_index":index,"state_sha256":hash_state(game.campaign),"save_sha256":game.save_store.digest(),"seed":replay.seed})
			game.get_tree().quit(); return
	if not game.smoke_check(game.campaign.phase=="result" and game.campaign.result.kind=="clear" and game.campaign.highest_floor==11 and hash_state(game.campaign)==replay.state_sha256,"Normal 10F clear exactly matches headless"): return
	var clear_hash:=hash_state(game.campaign)
	if not game.smoke_check(game.Expedition.act(game.campaign,"descend",int(game.campaign.revision),{},game.data,game.cfg)==game.campaign,"11F not playable"): return
	await click(game,"town",{})
	# Warehouse roundtrip uses a real owned UID and visible, scrolled buttons.
	var uid: String=game.campaign.warehouse[0]
	await click(game,"withdraw",{"uid":uid})
	if not game.smoke_check(uid in game.campaign.inventory and not uid in game.campaign.warehouse,"Warehouse withdraw input"): return
	await click(game,"deposit",{"uid":uid})
	if not game.smoke_check(uid in game.campaign.warehouse and not uid in game.campaign.inventory,"Warehouse deposit input"): return
	await game.click_control(game.play_buttons.title); await game.click_control(game.continue_button)
	if not game.smoke_check(game.campaign.phase=="town" and game.campaign.highest_floor==11,"Saved clear/town reopened"): return
	if rendered: await game.capture("18-campaign-clear-town.png")
	await click(game,"depart",{})
	if not game.smoke_check(game.campaign.floor==0 and game.campaign.highest_floor==11,"Post-clear replay begins from 1F route"): return
	write_result(game,{"run_id":game.smoke_run_id,"complete":true,"checkpoint":false,"rendered":rendered,"restarted":game.campaign_resume,"verified_actions":index,"clear_state_sha256":clear_hash,"expected_clear_sha256":replay.state_sha256,"save_sha256":game.save_store.digest(),"seed":replay.seed,"normal_trips":replay.normal_trips,"normal_deaths":replay.normal_deaths,"story_deaths":game.campaign.story_deaths,"highest_floor":game.campaign.highest_floor,"warehouse_roundtrip":true,"post_clear_replay":true,"input":"viewport clicks; real Timer timeout callback; no OS input"})
	game.get_tree().quit()
