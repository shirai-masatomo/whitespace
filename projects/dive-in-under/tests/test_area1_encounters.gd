extends SceneTree
const E=preload("res://core/expedition.gd")
const C=preload("res://core/catalog.gd")
const Store=preload("res://core/save_store.gd")
var count:=0
var failures:=0
func check(ok: bool,label: String) -> void:
	count+=1
	if not ok: failures+=1; printerr("FAIL: "+label)
func normalized(value: Variant) -> Variant:
	return JSON.parse_string(JSON.stringify(value))
func same_battle(a: Dictionary,b: Dictionary) -> bool:
	return a.rng_state==b.rng_state and normalized(a)==normalized(b)
func _initialize() -> void:
	var data:=C.load_data(); var cfg:=E.load_config()
	check(data.enemies.size()==9 and data.floors.size()==10,"active nine enemies and ten floor rows")
	for floor_number in range(1,11):
		var row:=E.floor_row(data.floors,floor_number)
		check(row.encounters.reduce(func(a,b): return a+b,0)==100 and row.enemies.values().reduce(func(a,b): return a+b,0)==100,"both weight sums on floor "+str(floor_number))
		if floor_number>=6 and floor_number<=9:
			var water:=int(row.enemies.get("E06",0))+int(row.enemies.get("E07",0))+int(row.enemies.get("E08",0))
			check(water==(75 if floor_number==6 else 80),"water enemies dominate exactly as table")
	check(E.floor_row(data.floors,2).enemies.has("E03"),"no unapproved floor-three status restriction")
	check(normalized(E.floor_row(data.floors,10).enemies)==normalized({"B10":100}),"boss remains fixed")
	var save_path:=ProjectSettings.globalize_path("user://area1-checkpoint.json")
	for id in ["E06","E07","E08"]:
		var s:=E.fresh(cfg,17); E.gain_exp(s,5000,cfg)
		s.floor=7 if id=="E08" else 6; s.highest_floor=s.floor; s.phase="battle"
		s.battle={"enemy_id":id,"enemy_level":4,"seed":17,"hero":E.hero(s,cfg),"rounds":0,"rules_version":2,"encounter_version":2}
		check(E.validate(s,data,cfg)=="","new enemy valid checkpoint: "+id)
		var store:=Store.new(save_path,data,cfg)
		check(store.write_game(s)=="","write new enemy checkpoint: "+id)
		var loaded:=Store.new(save_path,data,cfg).load_game()
		check(loaded.ok and same_battle(E.battle_state(loaded.state,data),E.battle_state(s,data)),"restart new enemy: "+id)
		var exp_before: int=s.exp; var gold_before: int=s.gold
		while s.phase=="battle": s=E.act(s,"round",s.revision,{},data,cfg)
		var foe:=E.Combat.enemy(data,id,4)
		check(s.last_outcome=="victory" and s.exp==exp_before+foe.exp and s.gold==gold_before+foe.gold,"campaign reward via shared core: "+id)
		check(E.validate(s,data,cfg)=="","post-reward state valid: "+id)
	# An old floor-6 slime is no longer eligible for a new encounter, but an
	# existing save must retain its battle, RNG, possessions and growth settings.
	var old_cfg:=E.load_config("2026-10-17.loop-provisional.3")
	var old:=E.fresh(old_cfg,17); old.schema_version=2; old.erase("hero_skills")
	old.floor=6; old.highest_floor=6; old.phase="battle"
	old.battle={"enemy_id":"E02","enemy_level":3,"seed":17,"hero":E.hero(old,old_cfg),"rounds":0}
	old=E.act(old,"round",old.revision,{},data,old_cfg)
	check(E.validate(old,data,old_cfg)=="","old floor-six slime remains valid")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://artifacts/migration-fixtures"))
	var fixture:=FileAccess.open("res://artifacts/migration-fixtures/4-old-floor.json",FileAccess.WRITE)
	fixture.store_string(JSON.stringify(old,"\t")); fixture.close()
	var wrong:=old.duplicate(true); wrong.battle.encounter_version=2
	check(E.validate(wrong,data,old_cfg)!="","new floor-six slime rejected")
	wrong.battle.encounter_version=99
	check(E.validate(wrong,data,old_cfg)!="","unknown encounter version rejected")
	var f:=FileAccess.open(save_path,FileAccess.WRITE); f.store_string(JSON.stringify(old)); f.close()
	var loaded:=Store.new(save_path,data,cfg).load_game()
	check(loaded.ok and loaded.migrated,"old checkpoint migrates")
	if loaded.ok:
		check(same_battle(E.battle_state(old,data),E.battle_state(loaded.state,data)),"old battle replay unchanged by new table")
		for key in ["items","equipment","inventory","warehouse","exp","gold","hp","sp","rng","config_version"]:
			check(normalized(old[key])==normalized(loaded.state[key]),"old save preserved: "+key)
	# Actual descend() must stamp the new table, not merely accept prepared inputs.
	var s: Dictionary={}
	for seed_value in range(1,9):
		s=E.fresh(cfg,seed_value); s.floor=5; s.highest_floor=5
		E.descend(s,data,cfg)
		if s.phase=="battle": break
	check(s.phase=="battle" and s.battle.get("encounter_version")==2,"real descent marks new encounter table")
	check(E.validate(s,data,cfg)=="","real encounter state valid")
	var prior:=E.fresh(cfg,17); E.gain_exp(prior,72,cfg)
	prior.hp=20; prior.floor=6; prior.highest_floor=6; prior.phase="battle"
	prior.battle={"enemy_id":"E03","enemy_level":4,"seed":17,"hero":E.hero(prior,cfg),"rounds":0,"rules_version":2}
	prior=E.act(prior,"round",prior.revision,{},data,cfg)
	check(E.validate(prior,data,cfg)=="","schema3 defense-era checkpoint keeps legacy floor")
	var before:=E.battle_state(prior,data)
	var store:=Store.new(save_path,data,cfg)
	check(store.write_game(prior)=="","write schema3 old-floor defense checkpoint")
	loaded=Store.new(save_path,data,cfg).load_game()
	check(loaded.ok and not loaded.migrated and same_battle(before,E.battle_state(loaded.state,data)),"schema3 old defense replay stays exact")
	print("AREA1_ENCOUNTER_TESTS: %d checks, %d failures"%[count,failures])
	quit(0 if failures==0 else 1)
