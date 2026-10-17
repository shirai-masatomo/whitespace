extends SceneTree
const E = preload("res://core/expedition.gd")
const Store = preload("res://core/save_store.gd")
const Catalog = preload("res://core/catalog.gd")
const Simulation = preload("res://tools/simulation.gd")
var data: Dictionary
var cfg: Dictionary
var checks := 0
var failures: Array = []

func check(ok: bool, label: String) -> void:
	checks+=1
	if not ok: failures.append(label); printerr("FAIL: "+label)

func normalized(s: Dictionary) -> Dictionary:
	return JSON.parse_string(JSON.stringify(s))

func action(s: Dictionary, name: String, args: Dictionary = {}) -> Dictionary:
	return E.act(s,name,int(s.revision),args,data,cfg)

func put(path: String, text: String) -> void:
	var f:=FileAccess.open(path,FileAccess.WRITE)
	f.store_string(text); f.close()

func _initialize() -> void:
	data=Catalog.load_data(); cfg=E.load_config()
	check(E.validate_config(cfg,data)=="","loop config valid")
	var bad_config:=cfg.duplicate(true); bad_config.event_floors[3].ids.append("EV03")
	check(E.validate_config(bad_config,data)!="","recruitment event excluded")
	bad_config=cfg.duplicate(true); bad_config.chests[0].items.I01=1
	check(E.validate_config(bad_config,data)!="","invalid chest probabilities rejected")
	var s:=E.fresh(cfg,123)
	check(E.validate(s,data,cfg)=="","new save valid")
	check(E.hero(s,cfg).max_hp==24 and s.equipment.size()==11,"provisional initial stats and 11 slots")
	check(action(s,"return")==s and action(s,"town")==s,"no town or return during first exploration")
	var before:=s.duplicate(true)
	s=action(s,"descend")
	check(before.floor==0 and s.floor==1,"pure transition")
	var resumed:=normalized(s)
	check(action(resumed,"descend").result.kind=="story_death","quit during tutorial resumes guaranteed scenario death")
	var revision:=int(s.revision)
	s=action(s,"descend")
	check(s.first_done and s.story_deaths==1 and s.hp==0 and s.phase=="result","story flag committed at death, before acknowledgement")
	check(E.act(s,"descend",revision,{},data,cfg)==s,"double click old revision ignored")
	check(E.validate(normalized(s),data,cfg)=="","death-result checkpoint valid")
	s=action(normalized(s),"town")
	check(s.hp==E.hero(s,cfg).max_hp and s.sp==E.hero(s,cfg).max_sp,"town restores HP/SP")
	check(action(s,"town")==s,"repeated acknowledgement ignored")
	var uid: String=s.inventory[0]
	var count: int=s.items.size()
	s=action(s,"equip",{"uid":uid})
	check(s.equipment.head==uid and E.hero(s,cfg).def==2 and s.items.size()==count,"equip exactly once")
	check(action(s,"deposit",{"uid":uid})==s and action(s,"equip",{"uid":uid})==s,"equipped item cannot duplicate or deposit")
	s=action(s,"unequip",{"slot":"head"}); s=action(s,"deposit",{"uid":uid})
	check(uid in s.warehouse and not uid in s.inventory,"deposit transfers ownership")
	check(action(s,"deposit",{"uid":uid})==s,"repeat deposit ignored")
	s=action(s,"withdraw",{"uid":uid})
	check(uid in s.inventory and not uid in s.warehouse,"withdraw transfers ownership")
	check(action(s,"withdraw",{"uid":uid})==s,"repeat withdraw ignored")
	var second:=E.add_item(s,"I01")
	s=action(s,"equip",{"uid":uid}); s=action(s,"equip",{"uid":second})
	check(uid in s.inventory and s.equipment.head==second and s.items.size()==2,"replace equipped item returns old item")
	E.add_item(s,"I07")
	var amulet: String=s.inventory.back()
	s=action(s,"equip",{"uid":amulet})
	check(E.hero(s,cfg).max_hp==29 and s.hp==29,"equipment HP in town")
	s=action(s,"unequip",{"slot":"neck"})
	check(s.hp==24 and E.validate(s,data,cfg)=="","removing HP gear clamps/restores correctly")
	var state_town:=normalized(s)
	for i in 15:
		s=action(s,"depart"); s=action(s,"return"); s=action(s,"town")
	check(s.first_done and s.story_deaths==1 and s.items==state_town.items,"repeated depart/return retains items and tutorial flag")
	E.gain_exp(s,12,cfg)
	check(E.hero(s,cfg).level==2 and E.hero(s,cfg).atk==7,"minimal growth is applied once")
	var level_two:=normalized(s)
	s=action(s,"depart")
	E.finish(s,"death","test normal death",cfg)
	check(s.story_deaths==1 and s.result.loss.exp==0,"normal death never repeats story, default XP retained")
	s=action(s,"town")
	check(s.exp==level_two.exp and s.items==level_two.items and s.hp>0,"no irreversible depletion after normal death")
	var alternate:=cfg.duplicate(true)
	alternate.death_penalty.lose_inventory=true
	alternate.death_penalty.gold_fraction=0.5
	alternate.death_penalty.unspent_exp_fraction=0.5
	var penalized:=s.duplicate(true); penalized.gold=21; penalized.exp=17
	var gear: Dictionary=penalized.equipment.duplicate()
	E.finish(penalized,"death","test alternate",alternate)
	check(penalized.gold==11 and penalized.exp==15 and penalized.equipment==gear and penalized.warehouse==s.warehouse,"switchable penalty retains attained level/equipment/warehouse")
	check(E.validate(penalized,data,alternate)=="","alternate penalty maintains ownership")
	var bad:=s.duplicate(true); bad.inventory.append(bad.inventory[0])
	check(E.validate(bad,data,cfg)!="","duplicate item rejected")
	bad=s.duplicate(true); bad.items["orphan"]="I01"
	check(E.validate(bad,data,cfg)!="","orphan item rejected")
	bad=s.duplicate(true); bad.schema_version=999
	check(E.validate(bad,data,cfg)!="","future save rejected")
	bad=s.duplicate(true); bad.gold="broken"
	check(E.validate(bad,data,cfg)!="","wrong typed number rejected")
	bad=s.duplicate(true); bad.equipment={}
	check(E.validate(bad,data,cfg)!="","missing slots rejected")
	# Replay mid-battle from a JSON-safe seed + round checkpoint, then apply rewards only once.
	var fighting:=action(state_town,"depart")
	fighting.phase="battle"; fighting.floor=1; fighting.highest_floor=1
	fighting.battle={"enemy_id":"E01","enemy_level":1,"seed":7,"hero":E.hero(fighting,cfg),"rounds":0}
	fighting=action(fighting,"round")
	check(normalized(E.battle_state(fighting,data))==normalized(E.battle_state(normalized(fighting),data)),"midbattle JSON replay retains exact trace")
	while fighting.phase=="battle": fighting=action(fighting,"round")
	check(fighting.phase=="explore" and fighting.exp==4 and fighting.gold==2,"battle rewards from shared core")
	check(fighting.get("last_outcome")=="victory" and action(fighting,"descend").get("last_outcome")=="","victory banner belongs only to the resolved encounter")
	check(action(fighting,"round")==fighting,"replayed finish cannot grant reward again")
	for event_id in ["EV01","EV02","EV04","EV05"]:
		var event_state:=action(state_town,"depart")
		event_state.phase="event"; event_state.event=event_id; event_state.floor=7; event_state.highest_floor=7; event_state.hp=3
		var skipped:=action(event_state,"event",{"choice":"skip"})
		check(skipped.phase=="explore" and skipped.hp==3,"event skip "+event_id)
		var accepted:=action(event_state,"event",{"choice":"accept"})
		match event_id:
			"EV01": check(accepted.hp==9,"spring restores six HP")
			"EV02": check(accepted.result.kind=="death" and accepted.story_deaths==1,"event death is normal death")
			"EV04": check(accepted.exp==4,"sign grants four EXP")
			"EV05": check(accepted.items.size()==event_state.items.size()+1,"residue grants repair stone without durability system")
	# High-level fixture covers the boss transition, not a normal-progression balance proof.
	var boss_fixture:=state_town.duplicate(true)
	E.gain_exp(boss_fixture,10000,cfg)
	boss_fixture=action(boss_fixture,"depart"); boss_fixture.floor=9; boss_fixture.highest_floor=9
	boss_fixture=action(boss_fixture,"descend")
	check(boss_fixture.battle.enemy_id=="B10" and boss_fixture.battle.enemy_level==6,"10F fixed boss and exact Lv")
	while boss_fixture.phase=="battle": boss_fixture=action(boss_fixture,"round")
	check(boss_fixture.result.kind=="clear" and boss_fixture.highest_floor==11,"boss victory records 11F")
	check(action(boss_fixture,"descend")==boss_fixture,"11F content cannot be entered")
	boss_fixture=action(boss_fixture,"town"); boss_fixture=action(boss_fixture,"depart")
	check(boss_fixture.floor==0 and boss_fixture.highest_floor==11,"10F clear allows replay from start")
	var encounters: Dictionary={"battle":0,"explore":0,"event":0,"E01":0,"E02":0}
	for seed_value in 1000:
		var trial:=action(state_town,"depart"); trial.seed=seed_value
		trial=action(trial,"descend")
		encounters[trial.phase]+=1
		if trial.phase=="battle": encounters[trial.battle.enemy_id]+=1
	check(abs(encounters.battle-700)<60 and abs(encounters.explore-200)<50 and abs(encounters.event-100)<40,"1F encounter weights sampled over 1000 seeds")
	check(abs(encounters.E01-490)<60 and abs(encounters.E02-210)<50,"1F conditional enemy weights distinct from drops")
	# A real 50-round stall uses the same core and returns an interruption, not a death.
	var stall:=action(state_town,"depart")
	stall.phase="battle"; stall.floor=1; stall.highest_floor=1
	var h:=E.hero(stall,cfg); h.max_hp=10000; h.hp=10000; h.atk=1; h.def=10000
	stall.hp=10000; stall.battle={"enemy_id":"B10","enemy_level":6,"seed":42,"hero":h,"rounds":0}
	while stall.phase=="battle": stall=action(stall,"round")
	check(stall.result.kind=="draw" and stall.deaths==state_town.deaths,"50-round interruption distinct from death")
	# Filesystem failure cases are confined to test-owned user:// paths.
	var path: String=ProjectSettings.globalize_path("user://loop-test.json")
	put(path,JSON.stringify(state_town))
	var store:=Store.new(path,data,cfg)
	check(store.read_one(path+".never-created").status=="missing","new profile without save")
	check(store.load_game().ok,"existing save loaded")
	var initial_checkpoint:=action(E.fresh(cfg,55),"descend")
	var death_checkpoint:=action(initial_checkpoint,"descend")
	check(E.normal_deaths(death_checkpoint)==0 and E.normal_trips(death_checkpoint)==0,"tutorial excluded from normal numerator and denominator")
	var legacy_death:=normalized(death_checkpoint)
	check(E.normal_deaths(legacy_death)==0 and E.validate(legacy_death,data,cfg)=="","legacy total-death save remains compatible")
	legacy_death.deaths=0
	check(E.validate(legacy_death,data,cfg)!="","invalid lifetime/story counters rejected")
	for checkpoint in [E.fresh(cfg,55),initial_checkpoint,death_checkpoint,state_town]:
		check(store.write_game(checkpoint)=="","write each lifecycle checkpoint")
		var reopened:=Store.new(path,data,cfg)
		check(normalized(reopened.load_game().state)==normalized(checkpoint),"fresh store restores lifecycle checkpoint")
	var next:=action(state_town,"depart")
	check(store.write_game(next)=="","atomic save success")
	check(normalized(store.load_game().state)==normalized(next),"fresh store/restart keeps state")
	var previous_hash:=FileAccess.get_sha256(path)
	store.fault="after_temp"
	check(store.write_game(action(next,"descend"))!="" and FileAccess.get_sha256(path)==previous_hash,"failed temp write preserves main")
	store.fault="before_replace"
	check(store.write_game(action(next,"descend"))!="" and FileAccess.get_sha256(path)==previous_hash,"failed replacement preserves main")
	store.fault=""
	var other:=Store.new(path,data,cfg)
	check(other.write_game(action(next,"return"))=="","second instance save")
	check(store.write_game(action(next,"descend"))!="","stale writer refused")
	put(path,"{broken")
	var recovery:=Store.new(path,data,cfg).load_game()
	check(recovery.status=="recoverable" and recovery.has("state") and FileAccess.get_file_as_string(path)=="{broken","corrupt main kept; backup offered, not silently loaded")
	var repair:=Store.new(path,data,cfg)
	check(repair.preserve_current()=="" and FileAccess.get_file_as_string(repair.last_preserved_path)=="{broken","explicit recovery preserves exact corrupt bytes")
	check(repair.write_game(recovery.state)=="" and Store.new(path,data,cfg).load_game().ok,"explicit backup recovery commits valid state")
	put(path,JSON.stringify({"schema_version":999}))
	# Fully shaped future schema is blocked even with a valid old backup.
	var future:=state_town.duplicate(true); future.schema_version=999
	put(path,JSON.stringify(future))
	check(Store.new(path,data,cfg).load_game().status=="version","future version must not roll back to old backup")
	put(path,"{broken"); put(path+".bak","also broken")
	check(Store.new(path,data,cfg).load_game().status=="invalid","two corrupt saves do not silently start new game")
	put(path,JSON.stringify(state_town))
	# Strict replay must catch trace-only changes, even when aggregate metrics are unchanged.
	var scenario: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/scenarios/baseline.json"))
	var report:=Simulation.run(data,scenario,[1,2,3])
	report.metadata={"engine":"test","runner_contract":"single-battle-v1"}
	var changed:=report.duplicate(true); changed.records[0].log_sha256="tampered"
	check(not Simulation.compare(report,changed,true).strict_equal,"strict comparison catches log-only drift")
	changed=report.duplicate(true); changed.metrics.win_rate+=0.1
	check(not Simulation.compare(report,changed,true).strict_equal,"strict comparison catches metric drift")
	check(not Simulation.compare(report,changed).has("error"),"normal balance comparison permits differences")
	check(Simulation.compare(report,normalized(report),true).strict_equal,"strict JSON normalization")
	# Repeated normal trips check liveness and data IDs, not a final 10F balance acceptance.
	var records: Array=[]
	for seed_value in 100:
		var campaign:=E.fresh(cfg,seed_value)
		while not campaign.first_done: campaign=action(campaign,"descend")
		campaign=action(campaign,"town")
		var valid:=true
		for trip in 12:
			for item_uid in campaign.inventory.duplicate():
				var slot: String=cfg.items[campaign.items[item_uid]].slot
				if slot!="" and campaign.equipment[slot]=="": campaign=action(campaign,"equip",{"uid":item_uid})
			campaign=action(campaign,"depart")
			var budget:=0
			while campaign.phase!="result" and budget<600:
				match campaign.phase:
					"explore": campaign=action(campaign,"return" if campaign.floor>=3 else "descend")
					"battle": campaign=action(campaign,"round")
					"event": campaign=action(campaign,"event",{"choice":"accept"})
				budget+=1
			valid=valid and budget<600 and E.validate(campaign,data,cfg)==""
			campaign=action(normalized(campaign),"town")
			valid=valid and campaign.hp>0 and campaign.story_deaths==1
		check(valid,"12 repeated trips remain valid, seed %d" % seed_value)
		records.append({"seed":seed_value,"trips":12,"level":E.hero(campaign,cfg).level,"normal_deaths":E.normal_deaths(campaign),"story_deaths":campaign.story_deaths,"lifetime_deaths":campaign.deaths,"items":campaign.items.size(),"highest_floor":campaign.highest_floor})
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://artifacts"))
	put("res://artifacts/loop-summary.json",JSON.stringify({"checks":checks,"failures":failures,"seeds":100,"trips_each":12,"policy":"return after 3F; equip empty slots; accept events","final_10F_balance_verified":false,"records":records},"\t"))
	print("LOOP_TESTS: %d checks, %d failures" % [checks,failures.size()])
	quit(0 if failures.is_empty() else 1)
