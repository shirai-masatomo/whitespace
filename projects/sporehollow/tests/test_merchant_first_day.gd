extends SceneTree
const Farm=preload("res://game/world.gd")
var checks=[]
func _initialize():call_deferred("run")
func check(ok,note):
	checks.append({"passed":bool(ok),"check":note})
	if not ok:push_error(note)
func run():
	var out=OS.get_environment("FARM_REVIEW_OUTPUT")
	if out=="" or "--isolated-review" not in OS.get_cmdline_user_args():quit(2);return
	var game=load("res://game/main.tscn").instantiate()
	game.automated=true;game.world=Farm.new({},31).begin_day();game.world.story.intro_seen=true
	root.add_child(game);game.set_process(false)
	await process_frame
	var w=game.world
	for at in [0,19,20,28,139,140,148]:
		w.tick=at
		check(not w.merchant_present() and game.merchant_visual_elapsed()<0,"Day 1 has no cart, bubble or interaction at tick "+str(at))
	check(not w.request_merchant("keeper") and "2日目" in w.merchant_reason("keeper"),"Day 1 rejects negotiation with an accurate reason")
	game._process(0)
	check(not game.arrival_bell and game.departure_started<0,"Day 1 starts neither arrival sound nor departure")
	check(w.Snapshot.save(w,out+"/large.snapshot"),"Save the current 100x68 world for separate-process EXE verification")
	var restored=w.Snapshot.restore(out+"/large.snapshot")
	check(not restored.merchant_present(),"Restoring day 1 does not restore a merchant visit")
	w.calendar_ticks=w.Cycle.Clock.TICKS_PER_DAY-1;w.tick=w.calendar_ticks;w.paused=false;w.step()
	check(w.campaign.day==2 and not w.merchant_present(),"Actual dawn crossing schedules day 2 without an immediate arrival")
	w.tick=w.merchant_arrive_tick-1
	check(not w.merchant_present() and game.merchant_visual_elapsed()<0,"Day 2 still waits five seconds")
	w.tick+=1
	check(w.merchant_present() and is_zero_approx(game.merchant_visual_elapsed()),"Day 2 cart animation starts from its own arrival tick")
	w.tick+=8
	check(w.merchant_present() and is_equal_approx(game.merchant_visual_elapsed(),2.0),"Day 2 cart remains visible after arrival")
	w.tick=ceili(w.merchant_leave_at/w.DT)
	check(not w.merchant_present(),"Day 2 leaves after its normal 30-second stay")
	var failed=checks.filter(func(c):return not c.passed).size()
	FileAccess.open(out+"/merchant-first-day.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failed},"\t"))
	print("Merchant first day: ",checks.size()," checks, ",failed," failures")
	quit(1 if failed else 0)
