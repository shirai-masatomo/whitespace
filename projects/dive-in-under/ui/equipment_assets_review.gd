extends RefCounted
const Art=preload("res://ui/equipment_art.gd")
static func write(game: Control, value: Dictionary, name: String) -> void:
	var f:=FileAccess.open(game.smoke_dir.path_join(name),FileAccess.WRITE); f.store_string(JSON.stringify(value,"\t")); f.close()
static func run(game: Control) -> void:
	var rendered:=DisplayServer.get_name()!="headless"
	if "--equipment-assets-review-resume" in OS.get_cmdline_user_args():
		var prior=JSON.parse_string(FileAccess.get_file_as_string(game.smoke_dir.path_join("equipment-assets-review.json")))
		if not game.smoke_check(game.loaded.ok and game.save_store.digest()==prior.save_sha256 and game.campaign.items[game.campaign.equipment.head]=="A02","Separate EXE restores exact blue cloak save"): return
		game.auto_play=false; game.play_timer.stop(); game.open_town_page("status")
		await game.get_tree().create_timer(0.25).timeout
		if rendered: await game.capture("blue-cloak-restarted.png")
		write(game,{"complete":true,"run_id":game.smoke_run_id,"rendered":rendered,"separate_restart":true,"save_sha256":game.save_store.digest()},"equipment-assets-review-resume.json")
		game.get_tree().quit(); return
	await game.click_control(game.new_button)
	game.auto_play=false; game.play_timer.stop()
	var cloak: String=game.campaign.equipment.head
	if not game.smoke_check(cloak!="" and game.campaign.items[cloak]=="A02" and game.campaign.inventory.is_empty() and game.campaign.equipment.size()==11,"Normal new-game button equips blue cloak in head without duplication"): return
	while game.campaign.phase=="battle": game.perform("round",{},int(game.campaign.revision))
	if game.campaign.phase=="event": game.perform("event",{"choice":"skip"},int(game.campaign.revision))
	await game.click_control(game.play_buttons["return"]); await game.click_control(game.play_buttons.town)
	await game.click_control(game.find_button(game.screen,"ステータス")); await game.get_tree().create_timer(0.25).timeout
	var before: String=game.save_store.digest()
	if not game.smoke_check(game.status_view.item_buttons.size()==11 and "冒険者のマント" in preload("res://ui/status_review.gd").text_in(game.status_view.details),"Real blue cloak detail and eleven slots"): return
	if rendered: await game.capture("blue-cloak-status.png")
	await game.click_control(game.status_view.back_button); await game.get_tree().create_timer(0.23).timeout
	if not game.smoke_check(game.save_store.digest()==before,"Viewing details does not change save"): return
	var condition: Dictionary=game.campaign.item_condition[cloak].duplicate(true)
	if not await game.CampaignReplay.click(game,"unequip",{"slot":"head"}): return
	for action in ["deposit","withdraw","to_cloth"]:
		if not await game.CampaignReplay.click(game,action,{"uid":cloak}): return
	if not await game.CampaignReplay.click(game,"withdraw",{"uid":cloak,"source":"cloth"}): return
	var hat: String=game.Expedition.add_item(game.campaign,"I01")
	if not await game.CampaignReplay.click(game,"equip",{"uid":hat}): return
	if not await game.CampaignReplay.click(game,"equip",{"uid":cloak}): return
	if not game.smoke_check(hat in game.campaign.inventory and game.campaign.equipment.head==cloak and game.campaign.item_condition[cloak]==condition,"Hat swap and storage preserve unique IDs and durability"): return
	for id in ["I01","I02","I03","I04","I05","I06","I07","I08","I09","I11"]:
		var icon:=Art.texture(id,game.cfg.items[id].slot)
		if not game.smoke_check(icon is AtlasTexture and icon.region.size.x>30 and icon.region.size.y>30,"Mapped item art "+id): return
		var uid: String=game.Expedition.add_item(game.campaign,id)
		game.campaign.inventory.erase(uid); game.campaign.warehouse.append(uid)
	if not game.smoke_check(Art.texture("I05")!=Art.texture("I11"),"Two rings use different artwork"): return
	if not game.smoke_check(game.save_store.write_game(game.campaign)=="","Gallery fixture saves valid ownership"): return
	game.warehouse_state.uid=hat; game.warehouse_state.source="inventory"; game.open_town_page("warehouse")
	await game.get_tree().process_frame
	if rendered: await game.capture("equipment-warehouse.png")
	var old_cfg: Dictionary=game.Expedition.load_config("2026-10-17.loop-provisional.4")
	var old: Dictionary=game.Expedition.fresh(old_cfg,123)
	old=game.Expedition.act(old,"return",int(old.revision),{},game.data,old_cfg); old=game.Expedition.act(old,"town",int(old.revision),{},game.data,old_cfg)
	old=game.Expedition.act(old,"equip",int(old.revision),{"uid":old.inventory[0]},game.data,old_cfg)
	old.item_condition[old.equipment.head].current=37
	var path: String=game.smoke_dir.path_join("legacy-0.5.3.json")
	var f:=FileAccess.open(path,FileAccess.WRITE); f.store_string(JSON.stringify(old)); f.close()
	var old_hash:=FileAccess.get_sha256(path)
	var store=game.SaveStore.new(path,game.data,game.cfg); var restored: Dictionary=store.load_game()
	if not game.smoke_check(restored.ok and store.cfg.config_version==old_cfg.config_version and FileAccess.get_sha256(path)==old_hash and game.CampaignReplay.hash_state(restored.state)==game.CampaignReplay.hash_state(old),"0.5.3 save keeps exact equipment, wear, progress and config"): return
	write(game,{"complete":true,"run_id":game.smoke_run_id,"rendered":rendered,"new_game_button":true,"starter_worn":true,"head_exclusive":true,"viewport_transfers":true,"legacy_preserved":true,"legacy_sha256":old_hash,"mapped_existing":10,"blue_cloak_uid":cloak,"save_sha256":game.save_store.digest(),"fixture_gallery_only":true},"equipment-assets-review.json")
	print("EQUIPMENT_ASSETS_REVIEW_OK"); game.get_tree().quit()
