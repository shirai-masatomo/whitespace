extends "res://tests/test_progression.gd"
const Save=preload("res://game/morning_save.gd")
func raw(path: String,record: Dictionary,version: int=1):
	var bytes=var_to_bytes(record);var file=FileAccess.open(path,FileAccess.WRITE)
	file.store_buffer(Save.MAGIC.to_ascii_buffer());file.store_32(version);file.store_32(bytes.size());file.store_buffer(Save.digest(bytes));file.store_buffer(bytes);file.close()
func run():
	var base="user://save-tests/";DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(base))
	check(Save.read(base+"missing.sav").status=="missing","A new profile is distinguished from a corrupt profile")
	for seed_value in [17,31,73]:
		var c=Farm.new_campaign();c.day=15;c.gold=500;c.exp_pool=100
		var w=Farm.new(c,seed_value);w.story.intro_seen=true;w.story.investigated=true
		var original=w.morning_checkpoint.duplicate(true)
		check(w.buy("berry") and w.train_animal(1) and w.rename_animal(1,"こまめ"),"Prepare purchase, training and Japanese name: "+str(seed_value))
		w.add_item("milk",2);check(w.sell("milk"),"Prepare a sale: "+str(seed_value))
		w.animals[0].equipment={"item_id":"collar","durability":-1};w.keeper.hp=17
		w.floors[Vector2i(4,6)]={"id":71,"kind":"wood_tile","hp":10,"max_hp":10,"status":"ready","resource":"wood","cost":2}
		var row=w.shop_stock.filter(func(r):return r.product=="berry")[0];row.remaining=0
		var record=Save.capture(w);var path=base+str(seed_value)+".sav"
		if not Save.valid(record):
			check(false,"Fixture must form a valid morning record")
			quit(1);return
		check(Save.valid(record) and Save.write(record,path).status=="ok","Morning record writes and verifies: "+str(seed_value))
		var loaded=Save.read(path);var restored=Save.restore(loaded.record)
		check(loaded.status=="ok" and restored.seed_value==seed_value and restored.phase=="shop" and restored.tick==0,"Reload starts the saved morning with its seed: "+str(seed_value))
		check(Save.capture(restored)==record,"All persisted farm state round trips without normalization drift: "+str(seed_value))
		check(restored.shop_stock==w.shop_stock and restored.morning_checkpoint==original,"Sold-out stock and the pre-purchase retry boundary both survive: "+str(seed_value))
		var day=restored.begin_day();var retry=Farm.new(day.checkpoint,seed_value)
		check(day.campaign.animals[0].lv==2 and day.campaign.animals[0].name=="こまめ" and retry.campaign.gold==day.campaign.gold,"Day entry and daytime retry preserve morning choices: "+str(seed_value))
		check(Save.capture(day).is_empty(),"Midday state cannot enter the morning store: "+str(seed_value))
		day.Story.pray(day,"animal");day.start_night();day.spawn_schedule.clear();day.finish(true)
		var dawn=Farm.new(day.next_campaign(),seed_value+1);var settled=Save.capture(dawn)
		check(Save.write(settled,path).status=="ok" and Save.read_one(path+".bak").record==record,"The next morning rotates a complete prior generation: "+str(seed_value))
		var again=Save.restore(Save.read(path).record);var twice=Save.restore(Save.capture(again))
		check(again.campaign.day==16 and again.seed_value==seed_value+1 and P.Encounters.reached(again.campaign) and Save.capture(twice)==Save.capture(again),"Prayer, reward and route settlement survive repeated reload exactly once: "+str(seed_value))
		var file=FileAccess.open(path,FileAccess.WRITE);file.store_string("truncated");file.close()
		check(Save.read(path).status=="recovered" and Save.read(path).record==record,"Corrupt main recovers the previous valid morning: "+str(seed_value))
		check(Save.write(settled,path).status=="ok" and Save.read_one(path+".bak").record==record,"Repairing a corrupt main never replaces a valid backup with corruption: "+str(seed_value))
	var w=Farm.new({},31);var first=Save.capture(w);w.campaign.gold+=10;var second=Save.capture(w)
	for stage in ["open","temporary","rotation"]:
		var path=base+stage+".sav";Save.write(first,path)
		check(Save.write(second,path,stage).status=="interrupted","Interrupt after "+stage)
		check(Save.read(path).record==first,"Interrupted "+stage+" retains the last committed morning")
		check(Save.write(second,path).status=="ok" and Save.read(path).record==second,"A subsequent save recovers after "+stage)
	var path=base+"initial.sav";Save.write(first,path,"temporary")
	check(Save.read(path).status=="recovered" and Save.read(path).record==first,"First-ever interrupted save can recover its verified temporary file")
	check(Save.write(second,path,"open").status=="interrupted" and Save.read(path).record==first and Save.read_one(path+".bak").record==first,"A recovered temporary-only morning survives failure at the next write's truncation")
	path=base+"failed.sav";Save.write(first,path)
	DirAccess.make_dir_absolute(ProjectSettings.globalize_path(path+".tmp"))
	check(Save.write(second,path).status=="io_error" and Save.read(path).record==first,"Failed temporary write leaves the existing morning intact")
	path=base+"blocked-backup.sav";Save.write(first,path);DirAccess.make_dir_absolute(ProjectSettings.globalize_path(path+".bak"))
	check(Save.write(second,path).status=="io_error" and Save.read(path).record==first,"Blocked backup destination cannot destroy the main save")
	path=base+"future.sav";raw(path,first,2);var future_bytes=FileAccess.get_file_as_bytes(path)
	check(Save.read(path).status=="unsupported_version" and Save.write(second,path).status=="unsupported_version" and FileAccess.get_file_as_bytes(path)==future_bytes,"A future format is never silently downgraded or overwritten")
	path=base+"bad-type.sav";var bad=first.duplicate(true);bad.campaign.animals[0].species="missing";raw(path,bad)
	check(Save.read(path).status=="corrupt" and Save.restore(bad)==null,"Invalid species is rejected before world construction")
	bad=first.duplicate(true);bad.stock[0].remaining=-1;check(not Save.valid(bad),"Negative stock rejected")
	bad=first.duplicate(true);bad.checkpoint.day+=1;check(not Save.valid(bad),"Mismatched retry day rejected")
	bad=first.duplicate(true);bad.campaign.animals.append(bad.campaign.animals[0].duplicate(true));check(not Save.valid(bad),"Duplicate individual IDs rejected")
	bad=first.duplicate(true);bad.campaign.world_story.prayers="invalid";check(not Save.valid(bad),"Malformed prayer container rejected")
	check(not Save.plain(func():return 1) and not Save.plain(w),"Executable values and objects are excluded")
	path=base+"checksum.sav";raw(path,first);var bytes=FileAccess.get_file_as_bytes(path);bytes[-1]=bytes[-1]^1;var file=FileAccess.open(path,FileAccess.WRITE);file.store_buffer(bytes);file.close()
	check(Save.read(path).status=="corrupt","An altered payload is rejected before Variant decoding")
	FileAccess.open("user://morning-save-tests.json",FileAccess.WRITE).store_string(JSON.stringify(records,"  "))
	print("MORNING_SAVE: %d checks, failures=%d"%[checks,failures]);quit(1 if failures else 0)
