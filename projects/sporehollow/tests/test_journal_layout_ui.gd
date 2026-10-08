extends "res://tests/test_controls.gd"

func settle():
	game._process(0.6);game._process(0)
	await process_frame;await process_frame

func press(id: String):
	check(game.buttons.has(id),"Book control exists: "+id)
	if game.buttons.has(id):await mouse(game.buttons[id].get_global_rect().get_center())
	await settle()

func check_paper_controls():
	var left=game.Journal.screen_rect(game.Journal.LEFT_PAGE)
	var right=game.Journal.screen_rect(game.Journal.RIGHT_PAGE)
	var controls=[]
	for child in game.palette.get_children():
		if not child is Control or not child.visible or child.is_queued_for_deletion():continue
		var area=child.get_global_rect()
		check(left.encloses(area) or right.encloses(area),"Visible book control stays on one paper page: "+child.name)
		controls.append(child)
	for i in range(controls.size()):
		for j in range(i+1,controls.size()):
			check(not controls[i].get_global_rect().intersects(controls[j].get_global_rect()),"Book controls do not overlap: %s / %s"%[controls[i].name,controls[j].name])

func run():
	output=OS.get_environment("FARM_REVIEW_OUTPUT")
	if DisplayServer.get_name()!="headless" and (output=="" or not "--isolated-review" in OS.get_cmdline_user_args()):quit(2);return
	root.size=Vector2i(1280,800)
	game=load("res://game/main.tscn").instantiate();game.automated=true
	game.world=Farm.new({},31);root.add_child(game);game.set_process(false);await process_frame
	game.story_modal="";game.arrival_started=-10;game.world.paused=true
	# Explicit layout fixture: every supported species, maximum-length name and a bonus skill.
	var original=game.world.campaign.animals[0].duplicate(true)
	game.world.campaign.animals=[]
	for species in Farm.AnimalData.SPECIES:
		var animal=original.duplicate(true)
		animal.id=game.world.campaign.animals.size()+1;animal.species=species
		animal.name="とてもながいなまえの仲間";animal.lv=1;animal.bonus_skills=["hardy"]
		animal.rarity=Farm.ProgressData.Rarity.LEGENDARY
		game.world.campaign.animals.append(animal)
	game.world.campaign.exp_pool=120
	game.refresh();game.open_book();await settle()
	check(game.buttons.keys().filter(func(id):return id.begins_with("book_entry_")).size()==8,"First book spread has eight entry hit targets")
	check_paper_controls()
	await capture("01_journal_grid")
	await press("book_next")
	check(game.training_id==-2 and game.buttons.has("book_entry_9"),"Page navigation reaches the ninth animal without hiding it")
	await press("book_prev");await press("book_entry_1")
	check(game.training_id==1,"Clicking a fitted card opens the same animal ID")
	var before_tick=game.world.tick;var before_exp=game.world.campaign.exp_pool
	for animal in game.world.campaign.animals:
		game.training_id=animal.id;game.book_next_id=animal.id;game.refresh();await settle()
		check_paper_controls()
		var title=game.Journal.text_layout(game,animal.name,game.Journal.TITLE,26,18)
		check(title.get_size().y<=game.Journal.TITLE.size.y,"Maximum-length name fits: "+animal.species)
		var lore=game.Journal.text_layout(game,Farm.AnimalData.character_text(animal.species),game.Journal.DESCRIPTION,16)
		check(lore.get_size().y<=game.Journal.DESCRIPTION.size.y,"Species description fits: "+animal.species)
		var entries=game.Journal.animal_skills(game,animal)
		for i in range(entries.size()):
			var entry=entries[i];var id="skill_"+entry.id
			check(game.buttons.has(id),"Every animal skill retains a hover target: "+id)
			if not game.buttons.has(id):continue
			var button=game.buttons[id]
			check(button.text=="" and button.size.x>=80 and button.size.y>=80,"Skill is an enlarged icon without a permanent text label: "+id)
			check(button.get_global_rect()==game.Journal.screen_rect(game.Journal.skill_rect(i)),"Visible skill and hover target use the same coordinates: "+id)
			check(button.tooltip_text==entry.tooltip and "条件：" in button.tooltip_text,"Hover retains name, condition and effect: "+id)
			if entry.locked:check("未解放" in button.tooltip_text,"Locked skill explains its unlock level")
		game.buttons["skill_"+entries[0].id].pressed.emit()
	check(game.world.tick==before_tick and game.world.campaign.exp_pool==before_exp,"Inspecting skill icons never advances time or trains an animal")
	var maid=game.world.campaign.animals.filter(func(a):return a.species=="maid")[0]
	game.training_id=maid.id;game.book_next_id=maid.id;game.refresh();await settle()
	await press("rename")
	check(game.rename_open and is_instance_valid(game.name_edit),"Naming remains available from the fitted page")
	check_paper_controls();await capture("02_journal_detail_and_name")
	game.name_edit.release_focus();game.rename_open=false;game.refresh()
	await press("book_enemies")
	for known in [0,1,2,3]:
		for id in game.ProgressView.ENEMY_ORDER:
			game.world.campaign.enemy_knowledge[id]=known
			game.training_id=game.ProgressView.ENEMY_ORDER.find(id);game.book_next_id=game.training_id
			game.refresh();await settle()
			var buttons=game.buttons.keys().filter(func(key):return key.begins_with("enemy_skill_"))
			check(buttons.size()==(Farm.ProgressData.EnemySkills.BY_ACTOR[id].size() if known>=2 else 0),"Enemy knowledge preserves skill disclosure: %s / %d"%[id,known])
			if known>=2:
				for skill_id in Farm.ProgressData.EnemySkills.BY_ACTOR[id]:
					var button=game.buttons["enemy_skill_"+skill_id]
					check(button.text=="" and button.tooltip_text==Farm.ProgressData.EnemySkills.tooltip(Farm.ProgressData.EnemySkills.get_skill(skill_id)),"Enemy tooltip keeps shared name and explanation: "+skill_id)
			var lore=game.Journal.text_layout(game,game.ProgressView.NOTES[id],game.Journal.DESCRIPTION,16)
			check(lore.get_size().y<=game.Journal.DESCRIPTION.size.y,"Enemy description stays above paper footer: "+id)
	game.training_id=game.ProgressView.ENEMY_ORDER.find("dancer");game.book_next_id=game.training_id
	game.refresh();await settle();check_paper_controls()
	var motion=InputEventMouseMotion.new();motion.position=game.buttons.enemy_skill_resurrection.get_global_rect().get_center()
	Input.parse_input_event(motion);await create_timer(0.8).timeout
	await capture("03_journal_enemy_hover")
	check(game.world.tick==before_tick and game.world.campaign.exp_pool==before_exp,"Book navigation and hover remain read-only")
	if output!="":
		record.method="Isolated or headless book UI. Explicit species/name/bonus and knowledge fixtures; no user save, training, or game simulation."
		FileAccess.open(output+"/journal-layout.json",FileAccess.WRITE).store_string(JSON.stringify(record,"  "))
	print("JOURNAL_LAYOUT_UI: %d checks, failures=%d"%[checks,failures]);quit(1 if failures else 0)
