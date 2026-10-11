extends RefCounted
# Simulation clock and boundary events only. No job, actor, raid, reward or save resets.
# World uses this clock through colony_cycle; incidents settle independently.
const DAY_SECONDS=432
const TICK_SECONDS=0.25
const TICKS_PER_DAY=1728
const START_MINUTE=300 # Begin at 05:00.
const BOUNDARIES={300:"morning",600:"day",1140:"night"}
var elapsed_ticks=0

func absolute_minutes() -> float:
	return START_MINUTE+elapsed_ticks*1440.0/TICKS_PER_DAY

func calendar_day() -> int:
	return 1+floori(absolute_minutes()/1440)

func minute_of_day() -> int:
	return floori(absolute_minutes())%1440

func period() -> String:
	var minute=minute_of_day()
	return "morning" if minute>=300 and minute<600 else ("day" if minute>=600 and minute<1140 else "night")

func advance_ticks(count: int=1) -> Array:
	if count<=0:return []
	var before=absolute_minutes()
	elapsed_ticks+=count
	var after=absolute_minutes();var events=[]
	for day_index in range(floori(before/1440),floori(after/1440)+1):
		for minute in BOUNDARIES:
			var at=day_index*1440+minute
			if at<=before or at>after:continue
			events.append({"id":"calendar:%d:%s"%[day_index+1,BOUNDARIES[minute]],"calendar_day":day_index+1,"period":BOUNDARIES[minute],"minute":minute,"elapsed_ticks":roundi((at-START_MINUTE)*TICKS_PER_DAY/1440.0)})
	return events
