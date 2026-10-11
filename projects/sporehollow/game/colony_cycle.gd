extends RefCounted
const Clock=preload("res://game/colony_clock.gd")
const NIGHT_OFFSET=1008 # 05:00 -> 19:00 at 432 seconds / day.

static func clock(w):
	var c=Clock.new();c.elapsed_ticks=w.calendar_ticks;return c
static func period(w) -> String:return clock(w).period()
static func label(w) -> String:
	var minute=clock(w).minute_of_day()
	return "%02d:%02d  %s"%[minute/60,minute%60,{"morning":"朝","day":"昼","night":"夜"}[period(w)]]
static func until(w,minute: int) -> float:
	var c=clock(w);var now=fmod(c.absolute_minutes(),1440.0);var delta=fmod(minute-now+1440.0,1440.0)
	return delta*Clock.DAY_SECONDS/1440.0
static func init(w):
	w.colony_version=2
	w.calendar_ticks=int(w.campaign.get("calendar_ticks",(w.campaign.day-1)*Clock.TICKS_PER_DAY))
	w.last_daily_day=int(w.campaign.get("last_daily_day",w.campaign.day))
	w.merchant_arrive_tick=w.tick+ceili(w.MERCHANT_DELAY/w.DT)
	w.merchant_leave_at=w.tick*w.DT+w.MERCHANT_DELAY+w.MERCHANT_SECONDS
	w.spawn_schedule.clear();w.schedule_index=0;w.night_started_tick=0
	w.day_seconds=Clock.DAY_SECONDS
	if w.phase!="shop":w.phase="defend" if period(w)=="night" else "day"

static func migrate_snapshot(w):
	# Legacy nights could wait indefinitely for enemies. Put their clock just before
	# the pending morning instead of skipping that daily result; simulation tick stays intact.
	var night=w.phase=="defend"
	w.calendar_ticks=(w.campaign.day-1)*Clock.TICKS_PER_DAY+(NIGHT_OFFSET+clampi(w.tick-w.night_started_tick,0,Clock.TICKS_PER_DAY-NIGHT_OFFSET-1) if night else mini(w.tick,NIGHT_OFFSET-1))
	w.last_daily_day=w.campaign.day;w.colony_version=2;w.day_seconds=Clock.DAY_SECONDS
	if night:
		w.spawn_schedule=w.spawn_schedule.slice(w.schedule_index)
		for event in w.spawn_schedule:event.tick+=w.night_started_tick
	else:w.spawn_schedule=w.spawn_schedule.filter(func(event):return event.get("wave",0)==999)
	w.schedule_index=0;w.night_started_tick=0
	# Existing positions remain unchanged. Former right/bottom entrances now return to the expanded edge.
	for e in w.enemies:
		if e.entry.x==23:e.entry.x=w.W-2
		elif e.entry.y==15:e.entry.y=w.H-2
	w.merchant_arrive_tick=ceili(w.MERCHANT_DELAY/w.DT)
	w.phase="result" if w.result!="" else ("defend" if period(w)=="night" else "day")

static func daily(w,day: int):
	if day<=w.last_daily_day:return
	w.last_daily_day=day # Guard before any generated goods or prayer result.
	w.daily_rng.seed=w.seed_value*727+day*1597
	w.process_dawn();w.Story.morning(w,day)
	w.keeper.drinks_today=0
	for a in w.animals:
		if a.species=="shiba" and not a.get("lost",false) and not a.get("dead",false) and a.hp<=0 and day>a.unavailable_through_day:
			a.hp=maxi(1,a.max_hp/2);a.convalescent_ticks=0
	w.Stock.normalize(w);w.Stock.sync(w)
	w.merchant_arrive_tick=w.tick+ceili(w.MERCHANT_DELAY/w.DT)
	w.merchant_leave_at=w.tick*w.DT+w.MERCHANT_DELAY+w.MERCHANT_SECONDS
	w.shop_stock=w.Shop.generate(w.stage,w.seed_value+day,w.campaign.unlocked_blueprints,day)
	var remaining=preload("res://game/colony_ui_state.gd").threats(w).size()
	w.PlayerEvents.add(w,("%d日目の朝。敵%d体がまだ残っています"%[day,remaining]) if remaining>0 else "%d日目の朝になりました"%day,"calendar_morning:%d"%day)
	w.campaign.last_daily_day=day;w.campaign.calendar_ticks=w.calendar_ticks

static func step(w):
	var c=clock(w);var boundaries=c.advance_ticks();w.calendar_ticks=c.elapsed_ticks;w.campaign.day=c.calendar_day()
	for boundary in boundaries:
		if boundary.period=="morning":
			w.phase="day";daily(w,boundary.calendar_day)
			if w.rest_skip.get("target","")=="dawn":w.Life.stop_rest_until(w,"morning")
		elif boundary.period=="night":w.start_night()
		elif boundary.period=="day":supplies(w,boundary.calendar_day)
	if w.working():w.phase="defend" if c.period()=="night" else "day"
	w.campaign.calendar_ticks=w.calendar_ticks

static func settle_incidents(w):
	if w.result!="":return # A completed defeat is never a successful raid payout.
	w.early_clear=w.schedule_index>=w.spawn_schedule.size() and not w.enemies.any(func(e):return not e.done and not e.flee)
	for incident in w.incidents:
		if incident.settled or w.spawn_schedule.slice(w.schedule_index).any(func(event):return event.get("incident","")==incident.id):continue
		var actors=w.enemies.filter(func(e):return e.get("incident","")==incident.id)
		if actors.any(func(e):return not e.done):continue
		incident.settled=true;incident.finished_tick=w.tick
		if not actors.is_empty():
			var result_campaign=w.campaign.duplicate(true);result_campaign.day=incident.day
			w.Progression.Encounters.record_win(result_campaign,w.seed_value+incident.day)
			w.campaign.route_progress=result_campaign.route_progress
			w.campaign.gold+=32;w.campaign.exp_pool+=16
			w.PlayerEvents.add(w,"%d日目の襲撃が終了。+32G / 経験16"%incident.day,"raid_done:"+incident.id)

static func supplies(w,day: int):
	if day<=int(w.campaign.get("last_supply_day",0)):return
	w.campaign.last_supply_day=day
	for kind in ["wood","mushroom"]:
		var row=w.Stock.add(w,kind,8 if kind=="wood" else 3,w.logistics_entry)
		row.supply_day=day
	w.PlayerEvents.add(w,"木材8・キノコ3が届きました。入口で受け取れます","supplies:%d"%day)
