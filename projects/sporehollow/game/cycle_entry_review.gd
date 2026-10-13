extends Node
## Opt-in native entry/save proof. Only the provided isolated fixture is used.
func summary(w):
	return {"map_size":[w.W,w.H],"terrain":w.terrain,"mountains":w.mountains,"structures":w.structures,"floors":w.floors,"rocks":w.rocks,"tick":w.tick,"clock":w.calendar_ticks,"daily":w.last_daily_day,"zones":w.zones,"stock":w.field_items,"jobs":w.jobs,"claims":w.work_claims,"keeper":w.keeper,"enemies":w.enemies,"schedule":w.spawn_schedule,"incidents":w.incidents,"animals":w.animals,"campaign":w.campaign,"used":w.stock_used}
func run():
	var g=get_parent();var out=OS.get_environment("FARM_REVIEW_OUTPUT");var resume="--resume-cycle-entry" in OS.get_cmdline_user_args();var checks=[]
	if g.story_modal!="":g.StoryView.close(g)
	if not resume:
		g.world=g.Farm.Snapshot.restore(out+"/fixture.snapshot");g.world.paused=true;g.world.market_open=true
		var expected=summary(g.world).duplicate(true);FileAccess.open(out+"/expected-entry.bin",FileAccess.WRITE).store_var(expected,false)
		g.notification(NOTIFICATION_WM_CLOSE_REQUEST)
		var saved=g.Farm.Snapshot.restore(g.development_save_path)
		checks.append({"check":"Normal window-close handler saved all fixture state and cleared the transient market pause on restore","passed":saved!=null and summary(saved)==expected and not saved.market_open})
	else:
		var expected=FileAccess.open(out+"/expected-entry.bin",FileAccess.READ).get_var(false)
		checks.append({"check":"Normal startup automatically resumed clock/zones/goods/work/enemies from previous process","passed":summary(g.world)==expected and not g.world.market_open})
		g.world.paused=false;var tick=g.world.tick
		var deadline=Time.get_ticks_msec()+2500
		while g.world.tick==tick and Time.get_ticks_msec()<deadline:await get_tree().process_frame
		checks.append({"check":"Native main process actually advances after market-open restore","passed":g.world.tick>tick})
	checks.append({"check":"Uses ordinary persistent main scene, not automated test startup","passed":not g.automated and g.persistence_enabled and g.is_processing()})
	var passed=checks.all(func(row):return row.passed)
	FileAccess.open(out+("/resume-entry.json" if resume else "/close-entry.json"),FileAccess.WRITE).store_string(JSON.stringify({"pid":OS.get_process_id(),"passed":passed,"checks":checks,"method":"Exported normal main scene, controlled fixture only in first process; close notification and automatic startup restore; second process engine-owned ticks"},"\t"))
	get_tree().quit(0 if passed else 1)
