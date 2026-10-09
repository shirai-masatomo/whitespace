extends "res://tests/test_journal_layout_ui.gd"

func run():
	output=OS.get_environment("FARM_REVIEW_OUTPUT")
	if DisplayServer.get_name()=="headless" or output=="" or not "--isolated-review" in OS.get_cmdline_user_args():quit(2);return
	root.size=Vector2i(1280,800)
	game=load("res://game/main.tscn").instantiate();game.automated=true;game.world=Farm.new({},31).begin_day()
	game.world.story.intro_seen=true;game.world.tick=20;game.world.paused=true
	root.add_child(game);game.set_process(false);await process_frame;await process_frame
	var original=game.world.campaign.animals[0].duplicate(true)
	check(original.get("name","")=="","Initial individual has no custom name")
	# Explicit layout fixtures, never loaded from or written to a user's save.
	game.world.campaign.animals=[]
	var names=["","こむぎ","あいうえおかきくけこさし","WWWWWWWWWWWW"]
	var species=["shiba","hen","cat","doberman"]
	for i in range(names.size()):
		var animal=original.duplicate(true);animal.id=i+1;animal.species=species[i];animal.name=""
		animal.hp=Farm.AnimalData.stats(animal.species,animal.lv).hp
		game.world.campaign.animals.append(animal)
		check(game.world.rename_animal(animal.id,names[i]),"Existing naming accepts fixture "+str(i))
		check(game.Journal.grid_name(animal,false)==names[i],"Only explicit individual name is used: "+str(i))
	check(game.Journal.grid_name({"species":"shiba"},false)=="","Legacy missing name stays unlabeled")
	check(game.Journal.grid_name({"name":"  "},false)=="","Whitespace is not a nameplate")
	check(game.Journal.grid_name({"name":"サラリーマン"},true)=="","Enemy default catalog names are not individual names")
	game.choose_walk();game.refresh();await press("keeper_book")
	check(game.field_book and game.training_id<0,"Field journal opens its thumbnail spread")
	check(game.buttons.keys().filter(func(id):return id.begins_with("book_entry_")).size()==4,"All four individual hit targets retained")
	check_paper_controls()
	for i in range(1,names.size()):
		var card=game.Journal.list_rect(i);var plate=game.Journal.nameplate_rect(card)
		var ink=game.Journal.nameplate_layout(game,names[i],plate)
		check(ink.get_size().x<=plate.size.x-8 and ink.get_size().y<=plate.size.y-8,"Name ink fits plate including Japanese maximum: "+str(i))
		check(card.encloses(plate) and not plate.intersects(Rect2(card.position+Vector2(20,12),Vector2(108,76))),"Nameplate stays inside its card without covering portrait: "+str(i))
		record.events.append({"name":names[i],"ink_size":[ink.get_size().x,ink.get_size().y],"plate_size":[plate.size.x,plate.size.y]})
	await capture("01_thumbnail_names")
	var tick=game.world.tick
	await press("book_entry_3")
	check(game.training_id==3 and game.world.campaign.animals[2].name==names[2],"Thumbnail opens same named individual's detail")
	check(game.buttons.has("rename") and game.buttons.has("train_3"),"Detail naming and training remain available")
	await capture("02_named_detail_preserved")
	await press("book_enemies")
	for id in game.ProgressView.ENEMY_ORDER:game.world.campaign.enemy_knowledge[id]=2
	game.training_id=-1;game.book_next_id=-1;game.refresh();await settle()
	check(game.book_section=="enemies","Enemy thumbnail spread remains available")
	await capture("03_enemy_thumbnails")
	check(game.world.tick==tick,"Review navigation does not advance world time")
	record.method="Isolated GPU; explicit unnamed, named, 12-character Japanese/Latin and known-enemy display fixtures; no normal save or OS input."
	FileAccess.open(output+"/journal-names.json",FileAccess.WRITE).store_string(JSON.stringify(record,"  "))
	print("JOURNAL_NAMES: %d checks, failures=%d"%[checks,failures]);quit(1 if failures else 0)
