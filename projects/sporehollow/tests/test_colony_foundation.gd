extends SceneTree
const Land=preload("res://game/colony_land.gd")
const Clock=preload("res://game/colony_clock.gd")
func _initialize():
	var records=[]
	var center=Vector2.ZERO
	for cell in Land.idol_cells():center+=Vector2(cell)+Vector2(0.5,0.5)
	center/=4
	records.append({"group":"1_geometry","passed":Land.WIDTH*Land.HEIGHT==1700 and center==Vector2(25,17) and Land.idol_cells().all(func(p):return Land.BOUNDS.has_point(p)),"idol_anchor":Land.IDOL_ANCHOR,"idol_center":center})
	var c=Clock.new();var events=c.advance_ticks(1728)
	records.append({"group":"2_day_length","passed":is_equal_approx(Clock.TICKS_PER_DAY*Clock.TICK_SECONDS,432) and c.period()=="morning" and c.minute_of_day()==300 and events.map(func(e):return e.elapsed_ticks)==[360,1008,1728],"events":events})
	var split=Clock.new();var split_events=[]
	for count in [359,1,647,1,719,1]:split_events.append_array(split.advance_ticks(count))
	records.append({"group":"3_boundary_delivery","passed":split_events==events and split.advance_ticks(0).is_empty() and c.advance_ticks(1).is_empty(),"calendar_day":split.calendar_day(),"note":"Chunking crosses 10:00, 19:00 and next-day 05:00 exactly once, without a dawn stop"})
	var output=OS.get_environment("FARM_REVIEW_OUTPUT")
	if output!="":FileAccess.open(output+"/foundation.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":records,"integrated_world":false,"method":"Headless pure geometry/clock checks; no world, actor or save mutation"},"\t"))
	var passed=records.all(func(r):return r.passed)
	print("Colony foundation: 3 groups; passed=",passed,"; world integration pending")
	quit(0 if passed else 1)
