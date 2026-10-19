extends "res://tests/test_phase1_logic.gd"
func run():
	if DisplayServer.get_name()!="headless" or OS.get_environment("FARM_REVIEW_OUTPUT")=="":quit(2);return
	for seed_value in [31,731,20261019]:
		setup(seed_value);w.Stock.add(w,"soil",5,Vector2i(26,23));w.act("wall",Vector2i(35,25))
		# A post-combat fixture: the real kidnapper is already beside an injured
		# resident. Entry routing is covered by the unmodified generated-map runs.
		w.spawn_enemy({"role":"kidnapper","entry":Vector2i(31,25),"lv":1,"wave":999});var e=w.enemies[-1];e.pos=Vector2i(31,25);e.arrival_complete=true;w.keeper.hp=1
		w.Life.hurt(w,e);check(w.keeper.hp==0 and w.keeper.state=="unconscious","%d: real damage causes unconsciousness"%seed_value)
		check(until(func():return w.keeper.carrier>=0,80),"Kidnapper physically captures unconscious keeper")
		w.Progression.enemy_hurt(w,e,999)
		check(w.keeper.carrier==-1 and e.carry=="" and w.metrics.rescues==1,"Defeating carrier clears both capture links")
		check(until(func():return w.metrics.built==1,400),"Hidden recovery eventually returns to the existing construction")
		check(w.keeper.state=="free" and w.stock_used.get("soil",0)==5,"Recovery consumes original construction resources exactly once")
	var fail=checks.filter(func(c):return not c.passed).size()
	FileAccess.open(OS.get_environment("FARM_REVIEW_OUTPUT")+"/phase1-rescue.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"count":checks.size(),"failed":fail},"  "))
	print("PHASE1_RESCUE checks=",checks.size()," failed=",fail);quit(1 if fail else 0)
