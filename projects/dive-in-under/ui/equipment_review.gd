extends RefCounted
## Isolated presentation/save fixture. Not normal-game economy or balance evidence.
static func run(game: Control) -> void:
	var rendered:=DisplayServer.get_name()!="headless"
	var resume: bool="--equipment-review-resume" in OS.get_cmdline_user_args()
	if resume:
		var prior=JSON.parse_string(FileAccess.get_file_as_string(game.smoke_dir.path_join("equipment-review.json")))
		if not game.smoke_check(game.loaded.ok and not game.loaded.migrated and game.campaign.schema_version==5 and game.save_store.digest()==prior.save_sha256,"Separate EXE reload retains repair/condition/Gold"): return
		game.auto_play=false; game.open_town_page("equipment")
		if rendered: await game.capture("equipment-restarted.png")
		write(game,{"run_id":game.smoke_run_id,"rendered":rendered,"complete":true,"save_sha256":game.save_store.digest(),"separate_restart":true},"equipment-review-resume.json")
		game.get_tree().quit(); return
	var old: Dictionary=game.Expedition.fresh(game.cfg,10000)
	old=game.Expedition.act(old,"return",int(old.revision),{},game.data,game.cfg)
	old=game.Expedition.act(old,"town",int(old.revision),{},game.data,game.cfg)
	var legacy_hat: String=game.Expedition.add_item(old,"I01")
	old=game.Expedition.act(old,"equip",int(old.revision),{"uid":legacy_hat},game.data,game.cfg)
	old.schema_version=3; old.erase("condition_version"); old.erase("item_condition")
	var legacy:=FileAccess.open(game.save_store.path,FileAccess.WRITE); legacy.store_string(JSON.stringify(old)); legacy.close()
	var original:=FileAccess.get_sha256(game.save_store.path)
	game.save_store=game.SaveStore.new(game.save_store.path,game.data,game.cfg)
	game.loaded=game.save_store.load_game()
	if not game.smoke_check(game.loaded.ok and game.loaded.migrated and FileAccess.get_sha256(game.save_store.path)==original,"Old save read without overwrite"): return
	game.campaign=game.loaded.state; game.auto_play=false
	game.campaign.gold=250 # Presentation fixture, never a production award.
	game.notice="耐久・修理の固定確認用 / 所持金は試験用"
	game.open_town_page("equipment")
	if rendered: await game.capture("equipment-full.png")
	var uid: String=game.campaign.equipment.head
	game.campaign.item_condition[uid].current=0
	game.open_town_page("equipment")
	if not game.smoke_check(game.Expedition.hero(game.campaign,game.cfg).def==1,"Broken gear has zero actual bonus"): return
	if rendered: await game.capture("equipment-broken.png")
	if not await game.CampaignReplay.click(game,"repair",{"uid":uid}): return
	if not game.smoke_check(game.campaign.item_condition[uid].current==100 and game.campaign.gold==150 and game.Expedition.hero(game.campaign,game.cfg).def==2,"Actual repair button restores effective stats and charges once"): return
	if not game.smoke_check(FileAccess.get_sha256(game.save_store.last_preserved_path)==original,"Legacy file archived before first replacement"): return
	if rendered: await game.capture("equipment-repaired.png")
	write(game,{"run_id":game.smoke_run_id,"rendered":rendered,"complete":true,"fixture_only":true,"manual_input":false,"repair_input":true,"legacy_archive_sha256":original,"save_sha256":game.save_store.digest(),"schema_version":game.campaign.schema_version,"gold":game.campaign.gold,"condition":game.campaign.item_condition[uid]},"equipment-review.json")
	game.get_tree().quit()
static func write(game: Control, record: Dictionary, filename: String) -> void:
	var file:=FileAccess.open(game.smoke_dir.path_join(filename),FileAccess.WRITE)
	file.store_string(JSON.stringify(record,"\t")); file.close()
	print("EQUIPMENT_REVIEW_OK run_id=",game.smoke_run_id)
