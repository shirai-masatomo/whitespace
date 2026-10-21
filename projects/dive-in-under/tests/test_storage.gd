extends SceneTree
const E=preload("res://core/expedition.gd")
const Store=preload("res://core/save_store.gd")
var checks:=0
var failures:=0
var data: Dictionary
var cfg: Dictionary
func check(value: bool, message: String) -> void:
	checks+=1
	if not value: failures+=1; printerr("FAIL: "+message)
func act(s: Dictionary, action: String, args: Dictionary={}) -> Dictionary:
	return E.act(s,action,int(s.revision),args,data,cfg)
func _initialize() -> void:
	data=E.Catalog.load_data(); cfg=E.load_config("2026-10-17.loop-provisional.4") # Keep the legacy empty-equipment fixture; new starter is tested separately.
	var s:=act(act(E.fresh(cfg,123),"return"),"town")
	var uid: String=s.inventory[0]; s.item_condition[uid].current=27
	s=act(s,"deposit",{"uid":uid}); s=act(s,"to_cloth",{"uid":uid,"source":"warehouse"})
	check(uid in s.cloth and s.inventory.is_empty() and s.item_condition[uid].current==27,"deposit and protected move preserve UID and condition")
	var stale: int=s.revision-1
	check(E.act(s,"withdraw",stale,{"uid":uid,"source":"cloth"},data,cfg)==s,"stale transfer cannot duplicate")
	s=act(s,"withdraw",{"uid":uid,"source":"cloth"})
	check(uid in s.inventory and s.cloth.is_empty(),"cloth withdraw returns item to backpack")
	for i in 3:
		var other:=E.add_item(s,"I%02d"%(i+2)); s=act(s,"to_cloth",{"uid":other})
	check(act(s,"to_cloth",{"uid":uid})==s and s.cloth.size()==3,"fourth cloth item rejected without loss")
	while s.inventory.size()<15: E.add_item(s,"I10")
	var cloth_uid: String=s.cloth[0]
	check(act(s,"withdraw",{"uid":cloth_uid,"source":"cloth"})==s,"full backpack rejects withdrawal")
	s=act(s,"deposit",{"uid":uid})
	var capacity_before: int=s.inventory.size()
	s=act(s,"withdraw",{"uid":cloth_uid,"source":"cloth"})
	check(s.inventory.size()==capacity_before+1 and E.validate(s,data,cfg)=="","freed backpack accepts exactly one")
	var protected: String=s.cloth[0]
	var loss_cfg:=cfg.duplicate(true); loss_cfg.death_penalty.lose_inventory=true
	var dead:=s.duplicate(true); E.finish(dead,"death","test",loss_cfg)
	check(protected in dead.cloth and dead.items.has(protected) and dead.inventory.is_empty() and E.validate(dead,data,loss_cfg)=="","cloth survives actual death loss policy")
	var snapshot: Dictionary=s.item_condition.duplicate(true); var ids: Dictionary=s.items.duplicate(true)
	s=act(s,"organize",{"mode":"condition"})
	check(s.item_condition==snapshot and s.items==ids and E.validate(s,data,cfg)=="","sorting never merges damaged instances")
	var outside:=act(s,"depart")
	check(act(outside,"deposit",{"uid":cloth_uid})==outside and act(outside,"organize",{"mode":"name"})==outside,"town-only operations")
	var supply_cfg:=cfg.duplicate(true); supply_cfg.items.I10.supply=true
	var supply: String=s.inventory.filter(func(key):return s.items[key]=="I10")[0]
	var stored: Dictionary=E.act(s,"deposit",int(s.revision),{"uid":supply},data,supply_cfg)
	check(supply in stored.warehouse and supply not in stored.inventory,"supply items may enter warehouse under 2026-10-21 instruction")
	var bad:=s.duplicate(true); bad.warehouse.append(s.inventory[0])
	check(E.validate(bad,data,cfg)!="","duplicate ownership rejected")
	bad=s.duplicate(true); bad.cloth.append_array(s.inventory.slice(0,3))
	check(E.validate(bad,data,cfg)!="","oversized cloth rejected")
	var legacy:=s.duplicate(true); legacy.schema_version=4
	legacy.inventory.append_array(legacy.cloth); legacy.cloth.clear(); legacy.erase("cloth"); legacy.erase("storage_version")
	while legacy.inventory.size()<19: E.add_item(legacy,"I10")
	var path:=ProjectSettings.globalize_path("user://warehouse-"+str(Time.get_ticks_usec())+".json")
	var f:=FileAccess.open(path,FileAccess.WRITE); f.store_string(JSON.stringify(legacy)); f.close()
	var original:=FileAccess.get_sha256(path); var store:=Store.new(path,data,cfg); var loaded:=store.load_game()
	check(loaded.ok and loaded.migrated and loaded.state.inventory.size()==19 and loaded.state.item_condition==JSON.parse_string(JSON.stringify(legacy.item_condition)) and FileAccess.get_sha256(path)==original,"legacy overcapacity and damage preserved without overwrite")
	check(store.write_game(loaded.state)=="" and FileAccess.get_sha256(store.last_preserved_path)==original,"first write archives exact old save")
	check(Store.new(path,data,cfg).load_game().state.cloth.is_empty(),"schema5 save reload")
	var future: Dictionary=loaded.state.duplicate(true); future.storage_version=2
	check(E.validate(future,data,cfg)!="","unknown storage schema rejected")
	print("STORAGE_TESTS: %d checks, %d failures"%[checks,failures]); quit(0 if failures==0 else 1)
