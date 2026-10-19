extends RefCounted
## Fixed inventory fixture, real viewport buttons and save pipeline; no balance claims.
static func run(game: Control) -> void:
	var rendered:=DisplayServer.get_name()!="headless"
	if "--warehouse-review-resume" in OS.get_cmdline_user_args():
		var prior=JSON.parse_string(FileAccess.get_file_as_string(game.smoke_dir.path_join("warehouse-review.json")))
		if not game.smoke_check(game.loaded.ok and game.campaign.schema_version==5 and game.save_store.digest()==prior.save_sha256,"Separate EXE restores all ownership and condition"): return
		game.auto_play=false; game.open_town_page("warehouse")
		if rendered: await game.capture("warehouse-restarted.png")
		write(game,{"complete":true,"rendered":rendered,"run_id":game.smoke_run_id,"separate_restart":true,"save_sha256":game.save_store.digest()},"warehouse-review-resume.json")
		game.get_tree().quit(); return
	var old: Dictionary=game.Expedition.fresh(game.cfg,10000)
	old=game.Expedition.act(old,"return",int(old.revision),{},game.data,game.cfg)
	old=game.Expedition.act(old,"town",int(old.revision),{},game.data,game.cfg)
	for i in 47: game.Expedition.add_item(old,"I%02d"%(1+i%11))
	while old.inventory.size()>12: old.warehouse.append(old.inventory.pop_back())
	old.gold=1024
	var damaged: String=old.warehouse[4]; old.item_condition[damaged].current=28
	old.schema_version=4; old.erase("cloth"); old.erase("storage_version")
	var legacy:=FileAccess.open(game.save_store.path,FileAccess.WRITE); legacy.store_string(JSON.stringify(old)); legacy.close()
	var original:=FileAccess.get_sha256(game.save_store.path)
	game.save_store=game.SaveStore.new(game.save_store.path,game.data,game.cfg); game.loaded=game.save_store.load_game()
	if not game.smoke_check(game.loaded.ok and game.loaded.migrated and FileAccess.get_sha256(game.save_store.path)==original and game.loaded.state.item_condition[damaged].current==28,"Schema4 migration preserves original bytes and damage"): return
	game.campaign=game.loaded.state; game.auto_play=false; game.open_town_page("warehouse")
	for i in 3:
		var uid: String=game.campaign.warehouse.back()
		if not await game.CampaignReplay.click(game,"to_cloth",{"uid":uid,"source":"warehouse"}): return
	if not game.smoke_check(game.campaign.cloth.size()==3 and FileAccess.get_sha256(game.save_store.last_preserved_path)==original,"Real cloth buttons and exact legacy archive"): return
	game.warehouse_state.grid_scroll=0; game.show_campaign()
	if rendered: await game.capture("warehouse-overview.png")
	var bag_uid: String=game.campaign.inventory[0]
	var count: int=game.campaign.items.size()
	if not await game.CampaignReplay.click(game,"deposit",{"uid":bag_uid}): return
	if not await game.CampaignReplay.click(game,"withdraw",{"uid":bag_uid}): return
	var cloth_uid: String=game.campaign.cloth[0]
	if not await game.CampaignReplay.click(game,"withdraw",{"uid":cloth_uid,"source":"cloth"}): return
	if not await game.CampaignReplay.click(game,"to_cloth",{"uid":cloth_uid}): return
	if not game.smoke_check(game.campaign.items.size()==count and bag_uid in game.campaign.inventory and cloth_uid in game.campaign.cloth,"Viewport transfers preserve instances"): return
	game.warehouse_state.uid=damaged; game.warehouse_state.source="warehouse"; game.open_town_page("warehouse")
	if rendered: await game.capture("warehouse-detail.png")
	var before: Dictionary=game.campaign.item_condition.duplicate(true)
	if not await game.CampaignReplay.click(game,"organize",{"mode":"category"}): return
	if not game.smoke_check(game.campaign.item_condition==before,"Organize preserves individual damage"): return
	await game.click_control(game.find_button(game.screen,"消耗品"))
	if not game.smoke_check(game.warehouse_view.visible_items.is_empty(),"Empty category handled without phantom items"): return
	if rendered: await game.capture("warehouse-filter-empty.png")
	await game.click_control(game.find_button(game.screen,"すべて"))
	await game.click_control(game.find_button(game.screen,"戻る"))
	if not game.smoke_check(game.town_page=="hub" and game.find_button(game.screen,"倉庫を開く")!=null,"Warehouse back opens separate town hub"): return
	await game.click_control(game.find_button(game.screen,"装備・修理"))
	if not game.smoke_check(game.town_page=="equipment" and game.find_button(game.screen,"預ける")==null,"Equipment remains separate from warehouse"): return
	await game.click_control(game.find_button(game.screen,"町へ戻る"))
	await game.click_control(game.find_button(game.screen,"倉庫を開く"))
	var restored: Dictionary=game.save_store.load_game()
	if not game.smoke_check(restored.ok and restored.state.cloth==game.campaign.cloth,"Last save retains protected ownership"): return
	write(game,{"complete":true,"rendered":rendered,"run_id":game.smoke_run_id,"fixture_only":true,"manual_input":false,"three_columns":true,"viewport_transfers":true,"category_empty":true,"equipment_separate":true,"schema4_archive_sha256":original,"save_sha256":game.save_store.digest(),"backpack":game.campaign.inventory.size(),"cloth":game.campaign.cloth.size(),"warehouse":game.campaign.warehouse.size(),"damaged_uid":damaged},"warehouse-review.json")
	game.get_tree().quit()
static func write(game: Control, record: Dictionary, filename: String) -> void:
	var file:=FileAccess.open(game.smoke_dir.path_join(filename),FileAccess.WRITE); file.store_string(JSON.stringify(record,"\t")); file.close()
	print("WAREHOUSE_REVIEW_OK run_id=",game.smoke_run_id)
