extends SceneTree
const C=preload("res://core/combat.gd")
const E=preload("res://core/expedition.gd")
const Catalog=preload("res://core/catalog.gd")
const Store=preload("res://core/save_store.gd")
var checks:=0
var failures:=0
func check(ok: bool,label: String) -> void:
	checks+=1
	if not ok: failures+=1; printerr("FAIL: "+label)
func events(s: Dictionary,kind: String) -> Array:
	return s.log.filter(func(e):return e.type==kind)
func norm(v: Variant) -> Variant: return JSON.parse_string(JSON.stringify(v))
func _initialize() -> void:
	var d:=Catalog.load_data(); var r: Dictionary=d.rules.duplicate(true)
	r.hit_chance=1.0; r.critical_chance=0.0; r.variance_min=1.0; r.variance_max=1.0
	for id in ["S102","S103","S104"]: r.skills[id].apply_chance=1.0
	var h: Dictionary={"level":1,"max_hp":200,"hp":200,"atk":10,"def":0,"spd":10,"max_sp":50,"sp":50,"skills":[]}
	var f: Dictionary={"level":1,"max_hp":1000,"hp":1000,"atk":1,"def":0,"spd":1,"max_sp":0,"sp":0}
	for id in ["S102","S103","S104"]:
		var actor:=h.duplicate(true); actor.skills=[id]
		var first:=C.advance(C.start(actor,f,r,17))
		check(first.hero.sp==50-r.skills[id].sp_cost,"single SP debit "+id)
		check(events(first,"skill").size()==1 and events(first,"status_applied").size()==1,"cast and apply "+id)
		check(events(first,"attack")[0].damage==C.damage(10,0,1,1,r.skills[id].damage_multiplier),"multiplier before rounding "+id)
		var next:=C.advance(first)
		check(events(next,"skill").size()==1,"cooldown blocks immediate recast "+id)
		var timed:=first
		for opportunity in int(r.skills[id].cooldown_own_actions): timed=C.advance(timed)
		check(events(timed,"skill").size()==1,"all cooldown opportunities blocked "+id)
		timed=C.advance(timed)
		check(events(timed,"skill").size()==2,"recast after exact cooldown "+id)
		var poor:=actor.duplicate(true); poor.sp=r.skills[id].sp_cost-1
		check(events(C.advance(C.start(poor,f,r,17)),"skill").is_empty(),"SP shortage falls back "+id)
		var miss_rules:=r.duplicate(true); miss_rules.hit_chance=0.0
		var missed:=C.advance(C.start(actor,f,miss_rules,17))
		check(events(missed,"status_applied").is_empty() and missed.hero.sp==first.hero.sp,"miss spends SP without status "+id)
		var lethal:=actor.duplicate(true); lethal.atk=10000
		var killed:=C.advance(C.start(lethal,f,r,17))
		check(killed.outcome=="victory" and events(killed,"status_applied").is_empty(),"no status after lethal hit "+id)
		for speed in [1,10,20]:
			var opponent:=f.duplicate(true); opponent.spd=speed
			check(C.simulate(actor,opponent,r,17)==C.simulate(actor,opponent,r,17),"fixed seed incl tie "+id+str(speed))
	# Poison: start of next own opportunity, snapshot power, exactly three ticks.
	var s:=C.start(h,f,r,17); C.apply_status(s,"hero","enemy","S102")
	s.hero.atk=1
	for round_number in range(1,4): s=C.advance(s)
	check(events(s,"status_damage").size()==3 and events(s,"status_damage").all(func(e):return e.damage==2),"three poison ticks use snapshotted ATK")
	check(not s.enemy.statuses.has("poison"),"poison expires after three opportunities")
	C.apply_status(s,"hero","enemy","S102")
	check(s.enemy.statuses.poison.potency==0,"no invented minimum-one poison")
	C.apply_status(s,"hero","enemy","S102")
	check(s.enemy.statuses.size()==1 and events(s,"status_applied").back().reapplied,"same status replaces one slot")
	var fail_rules:=r.duplicate(true); fail_rules.skills.S102.apply_chance=0.0
	var failed_actor:=h.duplicate(true); failed_actor.skills=["S102"]
	var failed:=C.start(failed_actor,f,fail_rules,17); C.apply_status(failed,"hero","enemy","S102")
	failed.enemy.statuses.poison.remaining=2; failed=C.advance(failed)
	check(events(failed,"status_applied").size()==1 and failed.enemy.statuses.poison.remaining==1,"failed reapplication does not refresh duration")
	var blocked:=C.start(h,f,r,17); blocked.hero.skills=["S105"]; blocked.hero.hp=60; blocked.hero.defense_until=1
	C.apply_status(blocked,"enemy","hero","S104"); blocked=C.advance(blocked)
	check(blocked.hero.sp==50 and blocked.hero.defense_until==-1 and blocked.hero.action_count==1,"paralysis consumes defense lifetime but no SP")
	# Poison before paralysis; the skipped opportunity ages all statuses and defense.
	s=C.start(h,f,r,17); C.apply_status(s,"hero","enemy","S102"); C.apply_status(s,"hero","enemy","S103"); C.apply_status(s,"hero","enemy","S104")
	s=C.advance(s)
	check(events(s,"status_damage").size()==1 and events(s,"action_skipped").size()==1,"poison precedes paralysis")
	check(s.enemy.statuses.poison.remaining==2 and s.enemy.statuses.blind.remaining==1 and not s.enemy.statuses.has("paralysis"),"skipped opportunity consumes durations")
	check(events(s,"attack").filter(func(e):return e.actor=="enemy").is_empty() and s.enemy.sp==0,"paralysis gives no attack or SP charge")
	s=C.advance(s); check(not s.enemy.statuses.has("blind"),"blind expires after final affected opportunity")
	var blind_rules:=r.duplicate(true); blind_rules.hit_chance=.25
	s=C.start(h,f,blind_rules,17); C.apply_status(s,"enemy","hero","S103"); s=C.advance(s)
	check(not events(s,"attack")[0].hit,"blind subtracts 25 percentage points, clamped at zero")
	s=C.start(h,f,r,17); C.apply_status(s,"enemy","hero","S102"); s.hero.hp=1; s.hero.statuses.poison.potency=2
	s=C.advance(s)
	check(s.outcome=="defeat" and events(s,"attack").is_empty() and s.hero.statuses.is_empty(),"poison death prevents own action and clears effects")
	check(C.advance(s)==s,"finished battle idempotent")
	s=C.start(h,f,r,17); C.apply_status(s,"hero","enemy","S103"); s.round=49; s=C.advance(s)
	check(s.outcome=="draw" and s.enemy.statuses.is_empty(),"50-round cap cleans statuses")
	# Live catalog assignment, no new floor restriction or hero acquisition path.
	check(C.enemy(d,"E03",1).skills==["S103"] and C.enemy(d,"E04",1).skills==["S102"] and C.enemy(d,"E05",1).skills==["S105","S104"],"canonical three enemy assignments")
	var cfg:=E.load_config(); var old:=E.fresh(cfg,17); E.gain_exp(old,72,cfg)
	old.floor=4; old.highest_floor=4; old.phase="battle"
	old.battle={"enemy_id":"E04","enemy_level":3,"seed":17,"hero":E.hero(old,cfg),"rounds":1,"rules_version":2,"encounter_version":2}
	var legacy:=E.battle_state(old,d); old.hp=legacy.hero.hp; old.sp=legacy.hero.sp
	check(E.validate(old,d,cfg)=="" and legacy.enemy.skills.is_empty() and events(legacy,"status_applied").is_empty(),"version2 battle preserves old no-enemy-skill rule")
	var invalid:=old.duplicate(true); invalid.battle.rules_version=99
	check(E.validate(invalid,d,cfg)!="","unknown combat version rejected")
	var current:=old.duplicate(true); current.battle.rules_version=3; current.battle.rounds=0
	current.hp=current.battle.hero.hp; current.sp=current.battle.hero.sp
	# Fixed fixture with production probabilities: find a status-carrying checkpoint only.
	var found:=false
	for seed_value in range(1,17):
		current.battle.seed=seed_value
		var candidate:=E.act(current,"round",current.revision,{},d,cfg)
		if candidate.phase=="battle" and not E.battle_state(candidate,d).hero.statuses.is_empty(): current=candidate; found=true; break
	check(found,"bounded fixed seeds produce an active poison save")
	if found:
		var path:=ProjectSettings.globalize_path("user://status-checkpoint.json")
		var store:=Store.new(path,d,cfg)
		var error:=store.write_game(current)
		check(error=="","write active status checkpoint: "+error)
		var loaded:=Store.new(path,d,cfg).load_game()
		check(loaded.ok and norm(E.battle_state(current,d))==norm(E.battle_state(loaded.state,d)),"restore status power/duration/cooldown/events")
		if loaded.ok: check(norm(E.act(current,"round",current.revision,{},d,cfg))==norm(E.act(loaded.state,"round",loaded.state.revision,{},d,cfg)),"resume without repeated ticks or SP debit")
	print("STATUS_TESTS: %d checks, %d failures"%[checks,failures])
	quit(0 if failures==0 else 1)
