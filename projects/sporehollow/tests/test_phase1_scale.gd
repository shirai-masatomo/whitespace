extends "res://tests/test_housing_sleep.gd"
var rows=[]
func weak_world():
	var a=Farm.new({},31).begin_day();return weakref(a)
func run():
	if DisplayServer.get_name()!="headless" or OS.get_environment("FARM_REVIEW_OUTPUT")=="":quit(2);return
	var base=Time.get_ticks_msec()
	for n in [10,50,100]:
		w=fixture();w.keeper.auto_collect=false;w.calendar_ticks=7*72;w.nature_config.spawn_chance_per_second=0;var at=Time.get_ticks_usec()
		for i in range(n):w.act("wall",Vector2i(30+i%10,30+i/10))
		var commit=(Time.get_ticks_usec()-at)/1000.0
		check(w.jobs.size()==n,"Register %d reservations"%n)
		if n==100:check(not w.act("wall",Vector2i(60,50)),"101st job rejected")
		for count in [1,5,10]:
			while w.workers.size()<count:
				var a=w.keeper.duplicate(true);a.pos=Vector2i(30+w.workers.size(),25);w.Work.register(w,"helper%d"%w.workers.size(),a)
			at=Time.get_ticks_usec()
			for key in w.workers:w.Work.choose(w,key)
			rows.append({"jobs":n,"humans":count,"register_ms":commit,"choose_ms":(Time.get_ticks_usec()-at)/1000.0,"static_bytes":int(Performance.get_monitor(Performance.MEMORY_STATIC)),"objects":int(Performance.get_monitor(Performance.OBJECT_COUNT))})
	for i in range(5):var reference=weak_world();check(reference.get_ref()==null,"World RefCounted lifetime releases after factory call %d"%i)
	w=fixture();w.keeper.auto_collect=false
	for i in range(1200):w.act("wall",Vector2i(35,25));w.Jobs.cancel(w,w.jobs[0].id)
	for i in range(32):w.step() # One periodic history-maintenance interval.
	rows.append({"event":"1200 build/cancel cycles","actions":w.actions.size(),"job_log":w.job_log.size(),"jobs":w.jobs.size(),"work_claims":w.work_claims.size(),"field_items":w.field_items.size()})
	check(w.actions.size()<=1024 and w.job_log.size()<=2048,"Build/cancel history stays bounded")
	check(w.jobs.is_empty() and w.work_claims.is_empty() and w.build_deliveries.is_empty(),"Repeated cancel leaves no live job/claims/deliveries")
	var failed=checks.filter(func(c):return not c.passed).size()
	FileAccess.open(OS.get_environment("FARM_REVIEW_OUTPUT")+"/phase1-scale.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"count":checks.size(),"failed":failed,"rows":rows,"wall_seconds":(Time.get_ticks_msec()-base)/1000.0,"scope":"Finite headless CPU and Godot managed memory samples; GPU/VRAM/Windows presentation/long-term leak not measured"},"  "))
	print("PHASE1_SCALE checks=",checks.size()," failed=",failed);quit(1 if failed else 0)
