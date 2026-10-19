extends "res://tests/test_housing_sleep.gd"
const Metrics=preload("res://game/terrain_metrics.gd")
var rows=[]
func measure(label):
	Metrics.take();Metrics.enabled=true;var start=Time.get_ticks_usec()
	for key in w.workers:w.Work.choose(w,key)
	var ms=(Time.get_ticks_usec()-start)/1000.0;var counters=Metrics.take();Metrics.enabled=false
	rows.append({"condition":label,"jobs":w.jobs.size(),"workers":w.workers.size(),"ms":ms,"counts":counters})
func run():
	if DisplayServer.get_name()!="headless" or OS.get_environment("FARM_REVIEW_OUTPUT")=="":quit(2);return
	w=fixture();w.keeper.auto_collect=false
	for i in range(1,10):var a=w.keeper.duplicate(true);a.pos=Vector2i(30+i,25);w.Work.register(w,"helper%d"%i,a)
	for i in range(100):w.act("wall",Vector2i(30+i%10,30+i/10))
	measure("no-materials")
	check(w.jobs.size()==100 and w.build_deliveries.is_empty(),"Unfunded plans remain pending without a fabricated delivery")
	w.Zones.create(w,"stockpile",Vector2i(24,20),Vector2i(38,20))
	for i in range(13):w.Stock.add(w,"soil",40 if i<12 else 20,Vector2i(24+i,20))
	measure("500-physical-soil")
	check(w.build_deliveries.size()==10,"Ten residents can obtain real deliveries after replenishment")
	var overclaim=false
	for r in w.field_items:
		var n=0
		for count in r.claims.values():n+=count
		if n>r.amount:overclaim=true
	check(not overclaim and w.Stock.totals(w).soil==500,"Concurrent material reservations conserve all500 units")
	var failures=checks.filter(func(c):return not c.passed).size()
	FileAccess.open(OS.get_environment("FARM_REVIEW_OUTPUT")+"/phase1-delivery-probe.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"rows":rows,"failures":failures},"  "))
	print("PHASE1_DELIVERY_PROBE failures=",failures," rows=",rows);quit(1 if failures else 0)
