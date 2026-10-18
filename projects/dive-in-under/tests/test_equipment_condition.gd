extends SceneTree
const E=preload("res://core/expedition.gd")
const Store=preload("res://core/save_store.gd")
var checks:=0
var failures: Array=[]
var data: Dictionary
var cfg: Dictionary
func check(ok: bool, label: String) -> void:
	checks+=1
	if not ok: failures.append(label); printerr("FAIL: "+label)
func act(s: Dictionary, name: String, args: Dictionary={}) -> Dictionary:
	return E.act(s,name,int(s.revision),args,data,cfg)
func put(path: String, value: Dictionary) -> void:
	var file:=FileAccess.open(path,FileAccess.WRITE); file.store_string(JSON.stringify(value)); file.close()
func _initialize() -> void:
	data=E.Catalog.load_data(); cfg=E.load_config()
	var s:=act(act(E.fresh(cfg,10000),"return"),"town")
	var hat: String=s.inventory[0]
	s=act(s,"equip",{"uid":hat})
	var ring:=E.add_item(s,"I05"); s=act(s,"equip",{"uid":ring})
	var amulet:=E.add_item(s,"I07"); s=act(s,"equip",{"uid":amulet})
	var material:=E.add_item(s,"I10")
	check(E.validate(s,data,cfg)=="" and s.schema_version==5,"new schema and all instances valid")
	check(E.hero(s,cfg).atk==8 and E.hero(s,cfg).max_hp==29 and E.hero(s,cfg).def==2,"full equipment stats")
	s.item_condition[ring].current=50
	check(E.hero(s,cfg).atk==7,"damaged equipment changes actual hero stats")
	s.item_condition[ring].current=0; s.item_condition[hat].current=0; s.item_condition[amulet].current=0
	s.hp=24
	check(E.hero(s,cfg).atk==6 and E.hero(s,cfg).def==1 and E.hero(s,cfg).max_hp==24,"broken bonuses zero; base growth retained")
	check(act(s,"repair",{"uid":ring})==s,"unaffordable repair changes nothing")
	s.gold=500
	var revision: int=s.revision
	var repaired:=act(s,"repair",{"uid":ring})
	check(repaired.gold==400 and repaired.item_condition[ring].current==100 and E.hero(repaired,cfg).atk==8,"repair consumes exact provisional cost and restores bonus")
	check(E.act(repaired,"repair",revision,{"uid":ring},data,cfg)==repaired and act(repaired,"repair",{"uid":ring})==repaired,"stale/repeated repair cannot double charge")
	check(act(repaired,"repair",{"uid":material})==repaired and act(repaired,"repair",{"uid":"missing"})==repaired,"materials and unknown instances cannot repair")
	var outside:=act(repaired,"depart")
	check(act(outside,"repair",{"uid":hat})==outside,"repair available in town only")
	var moving:=act(s,"unequip",{"slot":"head"})
	moving=act(moving,"deposit",{"uid":hat}); moving=act(moving,"withdraw",{"uid":hat})
	check(moving.item_condition[hat].current==0 and moving.items.size()==s.items.size(),"moves preserve damaged individual and ownership")
	var path:=ProjectSettings.globalize_path("user://phase2-equipment-"+str(Time.get_ticks_usec())+".json")
	var store:=Store.new(path,data,cfg)
	check(store.write_game(s)=="","damaged/broken state saves")
	var loaded:=Store.new(path,data,cfg).load_game()
	check(loaded.ok and not loaded.migrated and loaded.state.item_condition==JSON.parse_string(JSON.stringify(s.item_condition)),"broken equipment survives reload")
	var bad:=s.duplicate(true); bad.item_condition[ring].current=-1
	check(E.validate(bad,data,cfg)!="","negative durability rejected")
	bad=s.duplicate(true); bad.item_condition[ring].current=101
	check(E.validate(bad,data,cfg)!="","excess durability rejected")
	bad=s.duplicate(true); bad.item_condition.erase(ring)
	check(E.validate(bad,data,cfg)!="","missing instance condition rejected")
	bad=s.duplicate(true); bad.condition_version=999
	check(E.validate(bad,data,cfg)!="","future condition version rejected")
	# A real battle checkpoint wears only at resolution, never every replay/render.
	var fighting:=E.fresh(cfg,10000)
	fighting=act(act(fighting,"return"),"town"); fighting=act(fighting,"equip",{"uid":fighting.inventory[0]})
	fighting=act(fighting,"depart")
	for attempt in range(8):
		fighting=act(fighting,"descend")
		if fighting.phase=="battle": break
		if fighting.phase=="event": fighting=act(fighting,"event",{"choice":"skip"})
	check(fighting.phase=="battle","fixed ordinary first encounter")
	var checkpoint:=fighting.duplicate(true)
	var worn_uid: String=fighting.equipment.head
	var before: int=fighting.item_condition[worn_uid].current
	E.battle_state(fighting,data); E.battle_state(fighting,data)
	check(fighting.item_condition[worn_uid].current==before,"reconstruction never wears equipment")
	var steps:=0
	while fighting.phase=="battle" and steps<50:
		fighting=act(fighting,"round"); steps+=1
		if fighting.phase=="battle": check(fighting.item_condition[worn_uid].current==before and E.validate(fighting,data,cfg)=="","active checkpoint remains stable")
	check(fighting.phase!="battle" and fighting.item_condition[worn_uid].current==before-1,"wear once at battle resolution")
	check(E.validate(fighting,data,cfg)=="","post-battle ownership and effective HP valid")
	# Each old schema remains readable without overwriting original bytes.
	for schema in [1,2,3,4]:
		var old:=E.fresh(cfg,123); old.schema_version=schema
		old.erase("storage_version"); old.erase("cloth")
		if schema<4: old.erase("condition_version"); old.erase("item_condition")
		if schema<3: old.erase("hero_skills")
		put(path,old)
		var original:=FileAccess.get_sha256(path)
		store=Store.new(path,data,cfg); loaded=store.load_game()
		check(loaded.ok and loaded.migrated and loaded.state.schema_version==5,"legacy schema %d loads"%schema)
		if loaded.ok:
			check(FileAccess.get_sha256(path)==original and loaded.state.items==JSON.parse_string(JSON.stringify(old.items)),"legacy possessions and bytes preserved")
			check(store.write_game(loaded.state)=="" and FileAccess.get_sha256(store.last_preserved_path)==original,"exact legacy archive before replacement")
			loaded=Store.new(path,data,cfg).load_game()
			check(loaded.ok and not loaded.migrated,"schema4 migration idempotent")
	# A schema3 active battle receives pristine condition without changing its input.
	var old_battle:=checkpoint.duplicate(true)
	old_battle.schema_version=3; old_battle.erase("condition_version"); old_battle.erase("item_condition")
	put(path,old_battle); store=Store.new(path,data,cfg); loaded=store.load_game()
	if not loaded.ok: printerr("LEGACY_ACTIVE_ERROR: ",loaded)
	check(loaded.ok and loaded.state.battle==JSON.parse_string(JSON.stringify(old_battle.battle)) and JSON.stringify(JSON.parse_string(JSON.stringify(E.battle_state(loaded.state,data))))==JSON.stringify(JSON.parse_string(JSON.stringify(E.battle_state(old_battle,data)))) ,"old active battle exactly preserved")
	print("EQUIPMENT_CONDITION_TESTS: %d checks, %d failures"%[checks,failures.size()])
	quit(0 if failures.is_empty() else 1)
