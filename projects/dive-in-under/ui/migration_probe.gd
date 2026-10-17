extends RefCounted
## Test-only exported-EXE driver. All inputs live under the supplied smoke directory.
static func run(game: Control, resume: bool) -> void:
	var path: String=game.smoke_dir.path_join("migration-ui.json")
	var rendered:=DisplayServer.get_name()!="headless"
	if resume:
		var prior=JSON.parse_string(FileAccess.get_file_as_string(path))
		if not game.smoke_check(prior is Dictionary and prior.complete and game.loaded.ok and not game.loaded.migrated and game.campaign.schema_version==2 and game.save_store.digest()==prior.save_sha256,"Migrated save reopens in a separate EXE"): return
		var f:=FileAccess.open(game.smoke_dir.path_join("migration-restart.json"),FileAccess.WRITE)
		f.store_string(JSON.stringify({"run_id":game.smoke_run_id,"complete":true,"rendered":rendered,"save_sha256":game.save_store.digest()},"\t")); f.close()
		game.get_tree().quit(); return
	var old=JSON.parse_string(FileAccess.get_file_as_string(game.save_store.path))
	var old_hash: String=game.save_store.digest()
	if not game.smoke_check(old is Dictionary and old.schema_version==1 and game.loaded.ok and game.loaded.migrated and game.campaign.schema_version==2,"Legacy fixture loads without rewriting original"): return
	for key in ["config_version","revision","seed","rng","first_done","story_deaths","floor","highest_floor","exp","gold","hp","sp","items","inventory","warehouse","equipment","next_item","battle","event","trips","deaths"]:
		if not game.smoke_check(game.campaign[key]==old[key],"Legacy EXE preserves "+key): return
	await game.click_control(game.continue_button)
	game.auto_play=false; game.play_timer.stop()
	if rendered: await game.capture("26-migration-loaded.png")
	while game.campaign.phase=="battle":
		var revision: int=game.campaign.revision
		game.play_timer.one_shot=true; game.play_timer.start(0.001)
		while game.campaign.revision==revision: await game.get_tree().process_frame
	if game.campaign.phase=="event": await game.CampaignReplay.click(game,"event",{"choice":"skip"})
	if game.campaign.phase=="result": await game.CampaignReplay.click(game,"town",{})
	if game.campaign.phase=="town": await game.CampaignReplay.click(game,"depart",{})
	if not game.smoke_check(game.campaign.phase=="explore" and not game.play_buttons["return"].disabled,"Legacy history never prevents return"): return
	await game.CampaignReplay.click(game,"return",{})
	if not game.smoke_check(game.campaign.result.kind=="return" and game.campaign.hp>0,"Legacy profile returns normally"): return
	if rendered: await game.capture("27-migration-return.png")
	await game.CampaignReplay.click(game,"town",{})
	await game.CampaignReplay.click(game,"depart",{})
	var archive: String=game.save_store.last_preserved_path
	if not game.smoke_check(archive!="" and FileAccess.get_sha256(archive)==old_hash and game.campaign.story_deaths==old.story_deaths,"Exact original archive and legacy history retained"): return
	var f:=FileAccess.open(path,FileAccess.WRITE)
	f.store_string(JSON.stringify({"run_id":game.smoke_run_id,"complete":true,"rendered":rendered,"old_sha256":old_hash,"archive_sha256":FileAccess.get_sha256(archive),"archive_path":archive,"save_sha256":game.save_store.digest(),"config_version":game.campaign.config_version,"story_deaths":game.campaign.story_deaths,"normal_deaths":game.Expedition.normal_deaths(game.campaign)},"\t")); f.close()
	game.get_tree().quit()
