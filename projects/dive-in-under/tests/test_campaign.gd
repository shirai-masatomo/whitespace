extends SceneTree
const E = preload("res://core/expedition.gd")
const C = preload("res://core/catalog.gd")
const Sim = preload("res://tools/campaign_simulation.gd")
const Store = preload("res://core/save_store.gd")
var checks:=0
var failures: Array=[]

func check(ok: bool, label: String) -> void:
	checks+=1
	if not ok: failures.append(label); printerr("FAIL: "+label)

func log_case(data: Dictionary, cfg: Dictionary, defeat: bool) -> void:
	var s:=E.fresh(cfg,7)
	s.first_done=true; s.story_deaths=1; s.deaths=1; s.trips=2; s.phase="battle"; s.floor=1; s.highest_floor=1
	var h:=E.hero(s,cfg)
	if defeat: h.hp=6; h.max_hp=6; h.atk=1; h.def=0; h.spd=1
	else: h.def=2
	s.hp=h.hp
	s.battle={"hero":h,"enemy_id":"E01","enemy_level":1,"seed":7,"rounds":0,"rules_version":2}
	while s.phase=="battle":
		var before:=E.battle_state(s,data)
		var expected:=E.Combat.advance(before)
		s.journal=[]
		E.step_battle(s,data,cfg)
		var attacks:=0
		for entry in expected.log.slice(before.log.size()):
			if entry.type=="attack": attacks+=1
		var displayed:=0
		for line in s.journal:
			if " → " in line: displayed+=1
		check(displayed==attacks,"journal contains only new round attacks")
		if expected.outcome!="ongoing":
			check(expected.round>1 and attacks==1,"first actor terminal round has a previous round")
			check(expected.outcome==("defeat" if defeat else "victory"),"terminal case outcome")

func _initialize() -> void:
	var data:=C.load_data(); var cfg:=E.load_config()
	log_case(data,cfg,false); log_case(data,cfg,true)
	var legacy:=E.load_config("2026-10-17.loop-provisional.1")
	var old:=E.fresh(legacy,123)
	old=E.act(old,"descend",int(old.revision),{},data,legacy)
	var path: String=ProjectSettings.globalize_path("user://legacy-campaign-test.json")
	var old_store:=Store.new(path,data,legacy)
	check(old_store.write_game(old)=="","write old config save")
	var new_store:=Store.new(path,data,cfg)
	var restored:=new_store.load_game()
	check(restored.ok and new_store.cfg.growth.max_hp==4,"old save pins old HP growth")
	check(Sim.state_hash(restored.state)==Sim.state_hash(old),"old save unchanged on load")
	var next:=E.act(restored.state,"descend",int(restored.state.revision),{},data,new_store.cfg)
	check(new_store.write_game(next)=="" and E.normal_deaths(next)==0,"old save continues with separated tutorial count")
	check(cfg.growth.max_hp==5 and E.fresh(cfg,123).config_version!=old.config_version,"new save uses adjusted config only")
	var policy: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/scenarios/campaign.json"))
	var one:=Sim.play(data,cfg,policy,10000,true)
	check(one.cleared and one.normal_trips>1 and one.highest_floor==11,"fresh normal campaign clears 10F")
	check(one.story_deaths==0 and one.trips.size()==one.normal_trips,"first expedition included in normal trips")
	var deaths:=0
	for trip in one.trips: deaths+=int(trip.outcome=="death")
	check(deaths==one.normal_deaths,"normal deaths derived from normal trip outcomes")
	check(one.error=="" and one.final_state.hp>0,"no progression anomaly")
	var s: Dictionary=Sim.normalized(one.final_state)
	check(E.act(s,"descend",int(s.revision),{},data,cfg)==s,"clear result cannot enter 11F")
	s=E.act(s,"town",int(s.revision),{},data,cfg)
	s=E.act(s,"depart",int(s.revision),{},data,cfg)
	check(s.floor==0 and s.highest_floor==11 and s.hp>0,"clear permits another ordinary expedition")
	var r:=Sim.run(data,cfg,policy,[10000,10001])
	r.metadata={"engine":"test","runner_contract":"campaign-v1"}
	check(Sim.compare(r,Sim.normalized(r),true).strict_equal,"campaign normalized replay")
	var changed:=r.duplicate(true); changed.records[0].trace_sha256="bad"
	check(not Sim.compare(r,changed,true).strict_equal,"campaign detects trace-only tampering")
	changed=r.duplicate(true); changed.metrics.clear_rate=0.5
	check(not Sim.compare(r,changed,true).strict_equal,"campaign detects metric-only tampering")
	check(not Sim.compare(r,changed,false).has("error"),"balance differences allowed")
	changed=r.duplicate(true); changed.seeds=[10001,10002]
	check(Sim.compare(r,changed,false).has("error"),"different seed sets refused")
	# Independent per-floor sampling exercises all canonical rows, not a debug clear.
	for floor_number in range(1,11):
		var counts: Dictionary={"battle":0,"event":0,"explore":0}
		var row:=E.floor_row(data.floors,floor_number)
		var valid:=true
		for seed_value in 16:
			var f:=E.fresh(cfg,seed_value); f.first_done=true; f.story_deaths=1; f.deaths=1; f.trips=2; f.floor=floor_number-1; f.highest_floor=f.floor
			E.descend(f,data,cfg); counts[f.phase]+=1
			if f.phase=="battle": valid=valid and row.enemies.has(f.battle.enemy_id) and f.battle.enemy_level>=row.levels[0] and f.battle.enemy_level<=row.levels[1]
			if f.phase=="event": valid=valid and f.event!="EV03" and f.event in E.floor_row(cfg.event_floors,floor_number).ids
		check(valid,"canonical IDs and enemy Lv on floor %d"%floor_number)
		check(counts.battle+counts.explore+counts.event==16,"one encounter result per draw on floor %d"%floor_number)
	print("CAMPAIGN_TESTS: %d checks, %d failures"%[checks,failures.size()])
	quit(0 if failures.is_empty() else 1)
