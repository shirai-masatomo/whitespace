extends SceneTree
const E=preload("res://core/expedition.gd")
const Store=preload("res://core/save_store.gd")
var failures:=0
var checks:=0
func check(ok: bool, message: String) -> void:
	checks+=1
	if not ok: failures+=1; printerr("FAIL: "+message)
func _initialize() -> void:
	var cfg:=E.load_config(); var data:=E.Catalog.load_data(); var s:=E.fresh(cfg,123)
	var cape: String=s.equipment.head
	check(E.validate(s,data,cfg)=="" and s.equipment.size()==11 and cape!="" and s.items[cape]=="A02" and s.inventory.is_empty(),"Starter wears one blue cloak")
	check(E.hero(s,cfg).def==2 and s.item_condition[cape].current==100,"Cloak has actual provisional defense")
	var bad:=cfg.duplicate(true); bad.initial.equipment={"right_hand":"A02"}
	check(E.validate_config(bad,data)!="","Reject wrong starter slot")
	s=E.act(s,"return",int(s.revision),{},data,cfg); s=E.act(s,"town",int(s.revision),{},data,cfg)
	var hat:=E.add_item(s,"I01"); s=E.act(s,"equip",int(s.revision),{"uid":hat},data,cfg)
	check(s.equipment.head==hat and cape in s.inventory and E.validate(s,data,cfg)=="","Hat swap preserves both items")
	s=E.act(s,"equip",int(s.revision),{"uid":cape},data,cfg)
	var path:=ProjectSettings.globalize_path("user://starter-"+str(Time.get_ticks_usec())+".json")
	var store:=Store.new(path,data,cfg); check(store.write_game(s)=="","Starter saves")
	var loaded:=Store.new(path,data,cfg).load_game()
	check(loaded.ok and loaded.state.equipment.head==cape and loaded.state.items==JSON.parse_string(JSON.stringify(s.items)),"Restart retains new starter")
	var old_cfg:=E.load_config("2026-10-17.loop-provisional.4"); var old:=E.fresh(old_cfg,123)
	check(old.inventory.size()==1 and old.items[old.inventory[0]]=="I01" and old.equipment.head=="" and not old_cfg.items.has("A02"),"Old config remains immutable")
	var f:=FileAccess.open(path,FileAccess.WRITE); f.store_string(JSON.stringify(old)); f.close()
	var before:=FileAccess.get_sha256(path); var old_store:=Store.new(path,data,cfg); loaded=old_store.load_game()
	check(loaded.ok and loaded.state==JSON.parse_string(JSON.stringify(old)) and old_store.cfg.config_version==old_cfg.config_version and FileAccess.get_sha256(path)==before,"Existing .4 save keeps exact state and file")
	print("STARTER_EQUIPMENT_TESTS: %d checks, %d failures"%[checks,failures]); quit(0 if failures==0 else 1)
