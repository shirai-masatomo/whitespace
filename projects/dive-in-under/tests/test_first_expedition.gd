extends SceneTree
const E = preload("res://core/expedition.gd")
const Store = preload("res://core/save_store.gd")
var checks:=0
var failures: Array=[]
func check(ok: bool, label: String) -> void:
	checks+=1
	if not ok: failures.append(label); printerr("FAIL: "+label)
func put(path: String, state: Dictionary) -> void:
	var f:=FileAccess.open(path,FileAccess.WRITE)
	f.store_string(JSON.stringify(state,"\t")); f.close()
func _initialize() -> void:
	var data:=E.Catalog.load_data(); var cfg:=E.load_config()
	var fields: Array=["config_version","revision","seed","rng","first_done","story_deaths","floor","highest_floor","exp","gold","hp","sp","items","inventory","warehouse","equipment","next_item","battle","event","trips","deaths"]
	for version in ["2026-10-17.loop-provisional.1","2026-10-17.loop-provisional.2"]:
		var legacy:=E.load_config(version)
		var before:=E.fresh(legacy,123); before.schema_version=1
		var inside:=before.duplicate(true); inside.floor=1; inside.highest_floor=1
		var result:=inside.duplicate(true)
		result.first_done=true; result.story_deaths=1; result.deaths=1; result.hp=0; result.floor=2; result.highest_floor=2; result.phase="result"
		result.result={"kind":"story_death","floor":2,"reason":"legacy story","loss":{"gold":0,"exp":0,"items":0}}
		var town:=E.act(result,"town",0,{},data,legacy)
		E.gain_exp(town,30,legacy); town.gold=57
		var head: String=town.inventory[0]
		town=E.act(town,"equip",town.revision,{"uid":head},data,legacy)
		var uid:=E.add_item(town,"I07")
		town=E.act(town,"deposit",town.revision,{"uid":uid},data,legacy)
		var explore:=E.act(town,"depart",town.revision,{},data,legacy)
		var battle:=explore.duplicate(true)
		battle.phase="battle"; battle.floor=10; battle.highest_floor=10
		battle.battle={"enemy_id":"B10","enemy_level":6,"seed":7,"hero":E.hero(battle,legacy),"rounds":0}
		battle=E.act(battle,"round",battle.revision,{},data,legacy)
		check(battle.phase=="battle","legacy active battle fixture")
		var dead:=explore.duplicate(true); E.finish(dead,"death","normal old death",legacy)
		var fixture_dir:=ProjectSettings.globalize_path("res://artifacts/migration-fixtures")
		DirAccess.make_dir_recursive_absolute(fixture_dir)
		var cases:={"before":before,"inside":inside,"story":result,"town":town,"explore":explore,"battle":battle,"death":dead}
		for name in cases: put(fixture_dir.path_join(version.right(1)+"-"+name+".json"),cases[name])
		for source in cases.values():
			check(E.validate(source,data,legacy)=="","valid legacy fixture "+source.phase)
			var path: String=ProjectSettings.globalize_path("user://first-migration-%d.json"%checks)
			put(path,source)
			var sha:=FileAccess.get_sha256(path)
			var store:=Store.new(path,data,cfg); var loaded:=store.load_game()
			check(loaded.ok and loaded.migrated,"legacy load and migration")
			if not loaded.ok: continue
			var s: Dictionary=loaded.state
			check(s.schema_version==4 and FileAccess.get_sha256(path)==sha,"read-only migration preserves original bytes")
			for key in fields: check(s[key]==JSON.parse_string(JSON.stringify(source))[key],"migration preserves "+key)
			check(store.cfg.growth==legacy.growth,"old growth remains pinned")
			check(E.normal_deaths(s)==source.deaths-source.story_deaths,"story history excluded from ordinary deaths")
			check(E.normal_trips(s)==source.trips-source.story_deaths,"active initial trip becomes normal; historical story trip excluded")
			check(E.migrate(s)==s,"migration idempotent")
			if s.phase=="battle":
				check(JSON.stringify(E.battle_state(s,data))==JSON.stringify(E.battle_state(JSON.parse_string(JSON.stringify(source)),data)),"old battle replay exact")
				while s.phase=="battle": s=E.act(s,"round",s.revision,{},data,store.cfg)
			if s.phase=="result": s=E.act(s,"town",s.revision,{},data,store.cfg)
			if s.phase=="town": s=E.act(s,"depart",s.revision,{},data,store.cfg)
			if s.phase=="explore": s=E.act(s,"return",s.revision,{},data,store.cfg)
			check(s.phase=="result" and s.result.kind=="return" and s.hp>0,"all legacy checkpoints can return alive")
			check(store.write_game(s)=="","migrated atomic save")
			check(store.last_preserved_path!="" and FileAccess.get_sha256(store.last_preserved_path)==sha,"exact legacy archive before replacement")
			var reopened:=Store.new(path,data,cfg).load_game()
			check(reopened.ok and reopened.state==JSON.parse_string(JSON.stringify(s)) and not reopened.migrated,"restart migrated save")
	# Initial normal return and death both work without ever setting the history flag.
	var s:=E.fresh(cfg,123)
	s=E.act(s,"return",s.revision,{},data,cfg)
	check(s.result.kind=="return" and s.deaths==0,"first return")
	s=E.act(s,"town",s.revision,{},data,cfg)
	var uid: String=s.inventory[0]
	for action in ["deposit","withdraw","equip"]: s=E.act(s,action,s.revision,{"uid":uid},data,cfg)
	check(s.equipment.head==uid and s.warehouse.is_empty(),"first return enables storage and equipment")
	s=E.act(s,"depart",s.revision,{},data,cfg)
	check(s.trips==2 and s.story_deaths==0,"first return enables retry")
	for seed_value in [123,10000]:
		s=E.fresh(cfg,seed_value)
		var steps:=0; var survived_two:=false
		while s.phase!="result" and steps<600:
			var action: String="round" if s.phase=="battle" else ("event" if s.phase=="event" else "descend")
			s=E.act(s,action,s.revision,{"choice":"skip"},data,cfg); steps+=1
			if s.floor>=2 and s.hp>0: survived_two=true
		check(survived_two and s.story_deaths==0,"2F does not force defeat with HP")
		check(s.result.kind=="death" and s.hp==0 and E.normal_deaths(s)==1 and E.normal_trips(s)==1,"real first-trip combat death counted normally")
		check(s.exp>0 and s.gold>=0,"first-trip combat grants rewards")
	print("FIRST_EXPEDITION_TESTS: %d checks, %d failures"%[checks,failures.size()])
	quit(0 if failures.is_empty() else 1)
