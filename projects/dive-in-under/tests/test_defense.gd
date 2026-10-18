extends SceneTree
const C = preload("res://core/combat.gd")
const E = preload("res://core/expedition.gd")
const Store = preload("res://core/save_store.gd")
const Catalog = preload("res://core/catalog.gd")
var checks:=0
var failures: Array=[]
func check(ok: bool,label: String) -> void:
	checks+=1
	if not ok: failures.append(label); printerr("FAIL: "+label)
func casts(s: Dictionary) -> Array:
	return s.log.filter(func(e): return e.type=="skill")
func _initialize() -> void:
	var d:=Catalog.load_data(); var rules: Dictionary=d.rules.duplicate(true)
	rules.hit_chance=1.0; rules.critical_chance=0.0; rules.variance_min=1.0; rules.variance_max=1.0
	var h: Dictionary={"max_hp":100,"hp":60,"max_sp":30,"sp":30,"atk":1,"def":10,"spd":9,"skills":["S105"]}
	var e: Dictionary={"max_hp":1000,"hp":1000,"max_sp":0,"sp":0,"atk":1,"def":1,"spd":1}
	var start:=C.start(h,e,rules,17); var first:=C.advance(start)
	check(start.hero.sp==30 and first.hero.sp==27,"pure activation consumes SP once")
	check(casts(first).size()==1 and first.hero.def==10 and is_equal_approx(C.effective_def(first.hero,rules),13.0),"60 percent triggers 30 percent temporary DEF")
	check(first.hero.defense_until==2 and first.hero.cooldown_until==4,"expiry and cooldown are own opportunities")
	check(first.enemy.hp==1000,"defense consumes action instead of attacking")
	var second:=C.advance(first)
	check(second.hero.defense_until==-1 and C.effective_def(second.hero,rules)==10.0,"expires after next own action")
	check(second.log.any(func(v): return v.type=="status_removed" and v.reason=="expired"),"expiry logged")
	var fourth:=C.advance(C.advance(second))
	check(casts(fourth).size()==1 and fourth.hero.sp==27,"next three opportunities cannot recast")
	var fifth:=C.advance(fourth)
	check(casts(fifth).size()==2 and fifth.hero.sp==24,"fourth opportunity after use may recast")
	check(fifth.hero.def==10 and C.effective_def(fifth.hero,rules)==13.0,"recast never compounds the DEF bonus")
	check(C.damage(10,1)==9 and C.damage(10,1.3)==8,"fractional defense retained until final damage rounding")
	for pair in [[61,30],[60,2]]:
		var input:=h.duplicate(true); input.hp=pair[0]; input.sp=pair[1]
		var result:=C.advance(C.start(input,e,rules,3))
		check(casts(result).is_empty() and result.hero.sp==pair[1] and result.enemy.hp<1000,"threshold or SP failure falls back to attack")
	var no_skill:=h.duplicate(true); no_skill.skills=[]
	check(casts(C.advance(C.start(no_skill,e,rules,3))).is_empty(),"no skill is not granted implicitly")
	var lethal:=e.duplicate(true); lethal.atk=10000
	var death:=C.advance(C.start(h,lethal,rules,4))
	check(death.outcome=="defeat" and death.hero.hp==0 and death.hero.defense_until==-1,"death while defending clears status")
	check(death.log.any(func(v):return v.type=="status_removed" and v.reason=="death"),"death removal logged")
	check(C.advance(death)==death,"finished battle cannot charge SP or reward again")
	var fast:=e.duplicate(true); fast.spd=20; fast.atk=10
	var safe:=C.advance(C.start(h,fast,rules,5))
	var safe2:=C.advance(safe)
	var incoming: Array=safe2.log.filter(func(v):return v.type=="attack" and v.actor=="enemy")
	check(incoming.back().damage==C.damage(10,13.0),"faster enemy attacks before defended hero expires")
	for spd in [1,9,20]:
		var foe:=e.duplicate(true); foe.spd=spd
		for seed_value in range(100):
			var a:=C.simulate(h,foe,d.rules,seed_value)
			var b:=C.start(h,foe,d.rules,seed_value)
			while b.outcome=="ongoing": b=C.advance(b)
			check(a==b,"same core full trace across speed/tie seed %d/%d"%[spd,seed_value])
	var cfg:=E.load_config()
	var campaign:=E.fresh(cfg,10000)
	check(campaign.hero_skills==["S105"],"new hero owns S105")
	E.gain_exp(campaign,72,cfg)
	campaign.phase="battle"; campaign.floor=7; campaign.highest_floor=7
	campaign.hp=floori(E.hero(campaign,cfg).max_hp*0.6)
	campaign.battle={"enemy_id":"E05","enemy_level":4,"seed":17,"hero":E.hero(campaign,cfg),"rounds":0,"rules_version":2}
	campaign=E.act(campaign,"round",campaign.revision,{},d,cfg)
	check(E.validate(campaign,d,cfg)=="" and E.battle_state(campaign,d).hero.defense_until>=0,"valid active-defense campaign checkpoint")
	var path:=ProjectSettings.globalize_path("user://defense-save.json")
	var store:=Store.new(path,d,cfg)
	check(store.write_game(campaign)=="","save while defense active")
	var loaded:=Store.new(path,d,cfg).load_game()
	check(loaded.ok and not loaded.migrated,"new defense checkpoint reopens")
	if loaded.ok:
		var expected:=E.act(campaign,"round",campaign.revision,{},d,cfg)
		var resumed:=E.act(loaded.state,"round",loaded.state.revision,{},d,cfg)
		check(JSON.parse_string(JSON.stringify(expected))==JSON.parse_string(JSON.stringify(resumed)),"resume reproduces expiry and SP without duplicate cast")
		check(E.battle_state(resumed,d).hero.defense_until==-1,"resumed defense expires once")
	# Real 0.4.6 shape: no skills/state fields in battle input, schema2/config .3.
	var legacy_cfg:=E.load_config("2026-10-17.loop-provisional.3")
	var old:=E.fresh(legacy_cfg,123); old.schema_version=2; old.erase("hero_skills")
	E.gain_exp(old,72,legacy_cfg); old.gold=57
	var uid:=E.add_item(old,"I07")
	old.inventory.erase(uid); old.warehouse.append(uid)
	old.phase="battle"; old.floor=7; old.highest_floor=7
	var old_hero:=E.hero(old,legacy_cfg)
	for key in ["skills","action_count","defense_until","cooldown_until"]: old_hero.erase(key)
	old.battle={"enemy_id":"E05","enemy_level":4,"seed":17,"hero":old_hero,"rounds":0}
	old=E.act(old,"round",old.revision,{},d,legacy_cfg)
	check(E.validate(old,d,legacy_cfg)=="","schema2 old battle fixture valid")
	var fixture_dir:=ProjectSettings.globalize_path("res://artifacts/migration-fixtures")
	DirAccess.make_dir_recursive_absolute(fixture_dir)
	var fixture:=FileAccess.open(fixture_dir.path_join("3-battle.json"),FileAccess.WRITE)
	fixture.store_string(JSON.stringify(old,"\t")); fixture.close()
	var file:=FileAccess.open(path,FileAccess.WRITE); file.store_string(JSON.stringify(old,"\t")); file.close()
	var old_hash:=FileAccess.get_sha256(path)
	store=Store.new(path,d,cfg); loaded=store.load_game()
	check(loaded.ok and loaded.migrated,"schema2 migrates skill ownership")
	if loaded.ok:
		check(loaded.state.hero_skills==["S105"] and FileAccess.get_sha256(path)==old_hash,"migration grants once and leaves old bytes untouched")
		for key in ["items","inventory","warehouse","equipment","exp","gold","hp","sp","rng","trips","deaths","story_deaths","battle"]:
			check(loaded.state[key]==JSON.parse_string(JSON.stringify(old))[key],"schema2 migration preserves "+key)
		check(E.battle_state(loaded.state,d).hero.skills.is_empty(),"old active battle continues skill-free without retroactive changes")
		check(store.write_game(loaded.state)=="" and FileAccess.get_sha256(store.last_preserved_path)==old_hash,"schema2 archive before replacement")
		var reopened:=Store.new(path,d,cfg).load_game()
		check(reopened.ok and not reopened.migrated and E.migrate(reopened.state)==reopened.state,"migration is idempotent across reload")
		var next: Dictionary=reopened.state
		while next.phase=="battle": next=E.act(next,"round",next.revision,{},d,legacy_cfg)
		check(E.hero(next,legacy_cfg).skills==["S105"],"old campaign has S105 for subsequent battles")
	print("DEFENSE_TESTS: %d checks, %d failures"%[checks,failures.size()])
	quit(0 if failures.is_empty() else 1)
