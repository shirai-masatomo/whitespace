extends SceneTree
## Fixed cases for active new IDs, rewards, and unchanged legacy configuration.
const Catalog = preload("res://core/catalog.gd")
const Combat = preload("res://core/combat.gd")
const Expedition = preload("res://core/expedition.gd")
var checks:=0
var failures:=0
func check(value: bool,message: String) -> void:
	checks+=1
	if not value: failures+=1; printerr("FAIL: "+message)
func _initialize() -> void:
	var active:=Catalog.load_data()
	var active_hash:=JSON.stringify(active).sha256_text()
	var pack: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/v1/area1-enemies.json"))
	check(pack.schema_version==1 and pack.staged==false,"explicit active version")
	check(pack.enemies.keys()==["E06","E07","E08"],"exactly three approved new IDs")
	var candidate:=active.duplicate(true)
	for id in pack.enemies:
		check(active.enemies[id]==pack.enemies[id],"active catalog imports canonical enemy: "+id)
		candidate.enemies[id]=pack.enemies[id].duplicate(true)
	check(Catalog.validate(candidate)=="","new definitions accepted by shared catalog")
	var cfg:=Expedition.load_config().duplicate(true)
	for id in pack.drops: cfg.drops[id]=pack.drops[id].duplicate(true)
	check(Expedition.validate_config(cfg,candidate)=="","drop item IDs and rates valid")
	var high_hero: Dictionary=active.hero_fixture.duplicate(true)
	high_hero.atk=1000; high_hero.spd=100; high_hero.max_hp=1000; high_hero.hp=1000
	for id in pack.enemies:
		var base: Dictionary=pack.enemies[id]
		var foe:=Combat.enemy(candidate,id,1)
		for field in ["hp","atk","def","spd","sp","exp","gold"]:
			check(foe[field]==base[field],"Lv1 raw stat remains unchanged: "+id+"/"+field)
		var grown:=Combat.enemy(candidate,id,6)
		check(grown.max_hp>foe.max_hp and grown.atk>foe.atk and grown.spd==foe.spd,"shared level scaling: "+id)
		var rules: Dictionary=candidate.rules.duplicate(true); rules.hit_chance=1.0
		var result:=Combat.simulate(high_hero,foe,rules,17)
		check(result.outcome=="victory" and result.reward=={"exp":int(base.exp),"gold":int(base.gold)},"shared victory reward: "+id)
		var step:=Combat.start(high_hero,foe,rules,17)
		while step.outcome=="ongoing": step=Combat.advance(step)
		check(step==result,"same fixed-seed step replay: "+id)
	check(JSON.stringify(active).sha256_text()==active_hash,"preparation cannot mutate active catalog")
	check(candidate.floors==active.floors,"encounters remain unchanged")
	for version in ["2026-10-17.loop-provisional.1","2026-10-17.loop-provisional.2","2026-10-17.loop-provisional.3","2026-10-17.loop-provisional.4"]:
		var legacy:=Expedition.load_config(version)
		check(not legacy.is_empty() and Expedition.validate_config(legacy,active)=="","existing saved-config validation: "+version)
	print("ENEMY_PACK_TESTS: %d checks, %d failures"%[checks,failures])
	quit(0 if failures==0 else 1)
