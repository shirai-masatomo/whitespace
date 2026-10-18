extends RefCounted
## Fixed presentation fixtures only; not evidence of a normal 10F campaign.
static func run(game: Control) -> void:
	var rendered:=DisplayServer.get_name()!="headless"
	if not game.smoke_check(game.smoke_run_id!="","Asset review requires run ID"): return
	game.auto_play=false
	var cases: Array=[]
	var initial_save: String=game.save_store.digest()
	for fixture in [["E06",6,6],["E07",6,6],["E08",8,8],["E04",4,4],["B10",10,10]]:
		game.campaign=game.Expedition.fresh(game.cfg,10000)
		game.campaign.floor=fixture[1]
		game.campaign.phase="battle"
		game.campaign.battle={"enemy_id":fixture[0],"enemy_level":fixture[2],"seed":10000,"hero":game.Expedition.hero(game.campaign,game.cfg),"rounds":0,"rules_version":3,"encounter_version":2}
		game.campaign.journal=["静止画像確認用の固定遭遇 / 通常攻略の証拠ではありません"]
		var before: String=game.CampaignReplay.hash_state(game.campaign)
		game.show_campaign()
		await game.get_tree().process_frame
		await game.get_tree().process_frame
		var audits: Array=game.collect_visual_audits(game.screen).filter(func(a): return a.has("wide_layout"))
		if not game.smoke_check(audits.size()==1,"One production battle stage"): return
		var audit: Dictionary=audits[0]
		if not game.smoke_check(audit.wide_layout and audit.background_loaded,"Wide battle background loaded"): return
		for actor in audit.actors:
			if not game.smoke_check(actor.candidate_loaded and actor.within_stage,"Actor loaded and unclipped: "+actor.id): return
			if actor.id in ["E06","E07","E08"]:
				if not game.smoke_check(actor.visible_size[0]<=audit.stage_size[0]*0.34+0.01 and actor.visible_size[1]<=190.01,"New enemy size limit"): return
		var shot: String="enemy-%s.png"%fixture[0].to_lower()
		if rendered: await game.capture(shot)
		if not game.smoke_check(before==game.CampaignReplay.hash_state(game.campaign) and game.save_store.digest()==initial_save,"Presentation never mutates campaign or save"): return
		cases.append({"id":fixture[0],"floor":fixture[1],"screenshot":shot if rendered else "","audit":audit,"state_unchanged":true})
	# Reach the normal first-return/town controls once, using the unchanged core.
	game.campaign=game.Expedition.fresh(game.cfg,10000)
	game.campaign=game.Expedition.act(game.campaign,"descend",int(game.campaign.revision),{},game.data,game.cfg)
	while game.campaign.phase=="battle": game.campaign=game.Expedition.act(game.campaign,"round",int(game.campaign.revision),{},game.data,game.cfg)
	if game.campaign.phase=="event": game.campaign=game.Expedition.act(game.campaign,"event",int(game.campaign.revision),{"choice":"skip"},game.data,game.cfg)
	game.show_campaign()
	if not game.smoke_check(game.campaign.phase=="explore" and not game.play_buttons["return"].disabled,"First return enabled"): return
	await game.click_control(game.play_buttons["return"])
	if not game.smoke_check(game.campaign.result.kind=="return","First return input"): return
	await game.click_control(game.play_buttons.town)
	if not game.smoke_check(game.campaign.phase=="town" and not game.play_buttons.depart.disabled,"Town and retry controls"): return
	if rendered: await game.capture("first-return-town.png")
	var report:={"run_id":game.smoke_run_id,"engine":Engine.get_version_info().string,"rendered":rendered,"complete":true,"fixture_only":true,"manual_input":false,"first_return_town":true,"cases":cases}
	var file:=FileAccess.open(game.smoke_dir.path_join("enemy-art-review.json"),FileAccess.WRITE)
	file.store_string(JSON.stringify(report,"\t")); file.close()
	print("ENEMY_ART_REVIEW_OK run_id=",game.smoke_run_id)
	game.get_tree().quit()
