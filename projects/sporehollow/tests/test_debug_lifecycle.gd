extends "res://tests/test_keeper.gd"
func run():
	var rows=[]
	for role in Farm.ProgressData.ENEMY_ROWS.keys()+["doberman"]:
		var w=safe(31);w.debug_enabled=true;w.paused=true
		check(w.debug_spawn_enemy(role),"Day debug spawn accepts "+role)
		var e=w.enemies.back();var initial=e.pos;var visited={initial:true};var before=w.tick
		steps(w,12);check(w.tick==before and e.pos==initial,"Paused spawn waits by design: "+role)
		w.paused=false
		for i in range(160):
			w.step();visited[e.pos]=true
			if not w.working():break
		check(w.tick>before and (visited.size()>3 or e.done),"Day AI progresses after resume: "+role)
		check(e.object_attack_power>0,"Shared object capability is present: "+role)
		rows.append({"role":role,"visited":visited.size(),"ticks":w.tick,"phase":w.phase,"state":e.state})
	var w=safe(17);w.debug_enabled=true;w.paused=true
	for role in Farm.ProgressData.ENEMY_ROWS.keys()+["doberman"]:w.debug_spawn_enemy(role)
	var seen={};var unique=true
	for e in w.enemies:unique=unique and not seen.has(e.pos);seen[e.pos]=true
	check(unique and w.enemies.size()==11,"Mixed debug spawns occupy distinct legal outer cells")
	w.paused=false;steps(w,160)
	check(w.tick>0 and w.enemies.any(func(e):return e.path.size()>3 or e.done),"Mixed debug crowd advances the simulation and individual paths")
	check(w.keeper.object_attack_power>0,"Keeper shares the capability without receiving a new destruction command")
	FileAccess.open("user://debug-lifecycle.json",FileAccess.WRITE).store_string(JSON.stringify(rows,"  "))
	print("DEBUG_LIFECYCLE: %d checks, failures=%d"%[checks,failures]);quit(1 if failures else 0)
