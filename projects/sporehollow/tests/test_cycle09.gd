extends SceneTree
const Farm=preload("res://game/world.gd")
const Snap=preload("res://game/research_snapshot.gd")
var out=""
var failures=0
var group={}
var report={"method":"Production World.step at explicitly positioned calendar boundaries; no elapsed-time or human-play claim. Separate-process snapshot resume. UI uses injected Godot mouse events on an isolated desktop.","groups":[]}
func _initialize():call_deferred("run")
func begin(title):group={"name":title,"checks":[]};report.groups.append(group)
func check(ok: bool,note: String):
	group.checks.append({"passed":ok,"check":note})
	if not ok:failures+=1;push_error(note)
func farm():
	var w=Farm.new({},31).begin_day();w.trees.clear();w.natural.clear();w.field_items.clear();w.stock_used={};w.zones=[];w.storage_cells=[];w.nature_config.spawn_chance_per_second=0
	w.keeper.pos=Vector2i(6,8);w.keeper_path=[[6,8]];w.keeper.satiety=100;w.keeper.sleepiness=0;w.story.intro_seen=true;w.animals[0].mode="stay";w.animals[0].pos=Vector2i(10,8);w.animals[0].home=w.animals[0].pos;w.Stock.sync(w);return w
func seek_before(w,at: int):
	var delta=at-1-w.calendar_ticks;w.tick+=delta;w.calendar_ticks=at-1;w.phase="defend" if w.Cycle.period(w)=="night" else "day"
func summary(w):
	return {"tick":w.tick,"calendar":w.calendar_ticks,"day":w.campaign.day,"daily":w.last_daily_day,"phase":w.phase,"zones":w.zones,"stock":w.field_items,"jobs":w.jobs,"claims":w.work_claims,"keeper":w.keeper,"enemies":w.enemies,"schedule":w.spawn_schedule,"schedule_index":w.schedule_index,"incidents":w.incidents,"prayers":w.story.prayers,"gold":w.campaign.gold,"used":w.stock_used,"rng":w.rng.state}
func run():
	out=OS.get_environment("FARM_REVIEW_OUTPUT")
	if out=="" or not "--isolated-review" in OS.get_cmdline_user_args():quit(2);return
	if "--resume-cycle" in OS.get_cmdline_user_args():
		begin("Separate process exact continuation")
		var restored=Snap.restore(out+"/coexist.snapshot")
		var expected=FileAccess.open(out+"/expected.bin",FileAccess.READ).get_var(false)
		check(summary(restored)==expected.before,"New process restores clock, zones, goods, work, enemy, incidents and prayer state exactly")
		for i in range(8):restored.step()
		check(summary(restored)==expected.after,"Eight production ticks match uninterrupted continuation")
		write("restart.json");return
	begin("1 Expanded live land; independent clock, daily results and overlapping raids")
	var w=farm()
	check(w.W==50 and w.H==34 and w.inside(Vector2i(48,32)) and not w.inside(Vector2i(49,33)),"Live world uses approved 50x34 geometry")
	check(w.Story.at(w)==Vector2i(24,16) and not w.find_path(w.keeper.pos,Vector2i(43,28)).is_empty(),"New idol has approved central anchor and expanded ground is reachable")
	var c=w.Cycle.clock(w);c.advance_ticks(1728)
	check(c.calendar_day()==2 and c.minute_of_day()==300 and c.period()=="morning" and w.Cycle.Clock.DAY_SECONDS==432,"1728 quarter-second ticks equal one 432-second day at 05:00")
	seek_before(w,360);w.step();check(w.Cycle.period(w)=="day" and w.Cycle.label(w).begins_with("10:00"),"World transitions morning to day at 10:00")
	w.spawn_enemy({"role":"kidnapper","entry":Vector2i(1,5),"lv":1});var old=w.enemies[-1];old.pos=Vector2i(40,25);old.arrival_complete=true;old.path=[old.pos]
	var owned={"id":2,"category":"hen","species":"hen","lv":1,"xp":0,"loyalty":60,"unavailable_through_day":0};w.campaign.animals.append(owned);w.add_resident(owned)
	w.story.prayers.append({"id":900,"rewarded":false,"reward_day":2});var gold=w.campaign.gold
	w.animals[0].hp=0;w.animals[0].unavailable_through_day=1
	seek_before(w,1728);w.step()
	check(w.phase=="day" and w.campaign.day==2 and not old.done and not old.flee and w.enemies.has(old),"05:00 keeps the same living enemy instead of forcing retreat or ending the world")
	check(w.metrics.eggs_produced==1 and w.stock_used.get("egg",0)==0 and w.story.prayers[0].rewarded and w.campaign.gold==gold+60 and w.animals[0].hp>0,"Morning lays one egg, settles prayer and releases convalescence without waiting for enemies")
	var eggs=w.metrics.eggs_produced;gold=w.campaign.gold;w.Cycle.daily(w,2);w.step()
	check(w.metrics.eggs_produced==eggs and w.campaign.gold==gold,"Daily guard prevents duplicate production or prayer payment")
	check(w.merchant_arrive_tick>w.tick and not w.merchant_present(),"Morning reschedules the existing merchant independently")
	for i in range(20):w.step()
	check(w.merchant_present(),"Rescheduled merchant actually becomes available")
	seek_before(w,1728+1008);w.step()
	check(w.phase=="defend" and not old.done and not old.flee and not w.spawn_schedule.is_empty(),"19:00 schedules another raid while previous enemy remains")
	var due=w.spawn_schedule[w.schedule_index].tick;var gap=due-w.tick-1;w.tick+=gap;w.calendar_ticks+=gap;var count=w.enemies.size();w.step()
	check(w.enemies.size()>count and w.enemies[0].id==old.id and not old.done,"The next scheduled attacker actually spawns alongside the old attacker")
	group.state={"calendar":w.Cycle.label(w),"day":w.campaign.day,"enemy_ids":w.enemies.map(func(e):return e.id),"eggs":eggs,"last_daily_day":w.last_daily_day}
	var recovery=farm();recovery.animals[0].hp=0;recovery.animals[0].unavailable_through_day=2;recovery.last_daily_day=2
	seek_before(recovery,3456-360);recovery.step()
	check(recovery.campaign.day==3 and recovery.animals[0].unavailable_through_day==2 and not recovery.available(recovery.animals[0]),"Midnight never extends an existing convalescence deadline or releases it before morning")
	seek_before(recovery,3456);recovery.step()
	check(recovery.available(recovery.animals[0]) and recovery.animals[0].hp>0,"The following 05:00 releases the same recovering dog")
	begin("2 Complete state save/restart; death, retreat and goal completion terminate")
	w.keeper.satiety=100;w.Stock.add(w,"wood",12,Vector2i(8,8));var zone=w.Zones.create(w,"stockpile",Vector2i(9,10),Vector2i(10,10));w.Zones.set_allowed(w,zone,["wood"]);w.act("wood_wall",Vector2i(6,10))
	for i in range(70):
		w.step()
		if not w.Stock.cargo(w,"keeper").is_empty():break
	check(not w.Stock.cargo(w,"keeper").is_empty(),"Snapshot fixture includes active physical cargo and work")
	check(Snap.save(w,out+"/coexist.snapshot"),"Combined state saved")
	var before=summary(w).duplicate(true)
	for i in range(8):w.step()
	var after=summary(w).duplicate(true);FileAccess.open(out+"/expected.bin",FileAccess.WRITE).store_var({"before":before,"after":after},false)
	var restored=Snap.restore(out+"/coexist.snapshot");check(summary(restored)==before,"Snapshot preserves all selected state including day guards and in-flight goods")
	for i in range(8):restored.step()
	check(summary(restored)==after,"Restored continuation matches uninterrupted production steps")
	var market=Snap.restore(out+"/coexist.snapshot");market.market_open=true;market.paused=false;Snap.save(market,out+"/market.snapshot");market=Snap.restore(out+"/market.snapshot");var market_tick=market.tick;market.step()
	check(not market.market_open and market.tick==market_tick+1,"Restoring a market-open save clears the missing UI pause and time advances")
	var legacy=farm();legacy.phase="defend";legacy.tick=1200;legacy.night_started_tick=300;legacy.story.prayers.append({"id":901,"rewarded":false,"reward_day":2});Snap.save(legacy,out+"/legacy.snapshot")
	var payload=FileAccess.open(out+"/legacy.snapshot",FileAccess.READ).get_var(false);payload.state.erase("colony_version");FileAccess.open(out+"/legacy.snapshot",FileAccess.WRITE).store_var(payload,false)
	legacy=Snap.restore(out+"/legacy.snapshot");check(legacy.calendar_ticks==1727 and legacy.tick==1200,"Long-running old night migrates just before morning without changing simulation tick")
	legacy.step();var legacy_gold=legacy.campaign.gold;legacy.step()
	check(legacy.last_daily_day==2 and legacy.story.prayers[0].rewarded and legacy.campaign.gold==legacy_gold,"Migrated old night applies the next morning's result exactly once")
	w=farm();w.spawn_enemy({"role":"kidnapper","entry":Vector2i(1,5),"lv":1});var dead=w.enemies[-1];dead.pos=Vector2i(40,20);w.Content.down(w,dead);w.tick=dead.corpse_until;w.enemy_step(dead)
	check(dead.done and dead.hp==0,"Expired corpse has a terminal state instead of movement")
	w.spawn_enemy({"role":"kidnapper","entry":Vector2i(1,5),"lv":1});var retreat=w.enemies[-1];retreat.flee=true;retreat.arrival_complete=true;retreat.pos=Vector2i(2,5);retreat.move_credit=1
	for i in range(32):
		w.tick+=1;w.enemy_step(retreat)
	check(retreat.done,"Retreat reaches its exit and terminates")
	w.spawn_enemy({"role":"thief","entry":Vector2i(1,5),"lv":1});var thief=w.enemies[-1];thief.arrival_complete=true;thief.pos=Vector2i(2,5);thief.stolen={"kind":"wood","amount":1,"pos":thief.pos}
	for i in range(32):
		w.tick+=1;w.enemy_step(thief)
	check(thief.done and thief.stolen.is_empty(),"A thief's completed delivery terminates without a boundary loop")
	if DisplayServer.get_name()!="headless":await visual()
	write("cycle09.json")
func write(name):
	report.passed=failures==0;report.failures=failures;FileAccess.open(out+"/"+name,FileAccess.WRITE).store_string(JSON.stringify(report,"\t"));print("Cycle09: ",report.groups.size()," groups, ",failures," failures");quit(0 if failures==0 else 1)
func motion(point):
	var e=InputEventMouseMotion.new();e.position=point;Input.parse_input_event(e);await process_frame
func mouse(point,down):
	var e=InputEventMouseButton.new();e.position=point;e.button_index=MOUSE_BUTTON_LEFT;e.pressed=down;Input.parse_input_event(e);await process_frame
func click(point):await motion(point);await mouse(point,true);await mouse(point,false)
func visual():
	begin("5 Integrated UI: zones, clock and saved world")
	root.size=Vector2i(1280,800);var g=load("res://game/main.tscn").instantiate();g.automated=true;g.world=farm();g.world.paused=true
	root.add_child(g);await process_frame;await process_frame;g.set_process(false);g.audio.set_process(false);g.reset_view();g.neutral();g.camera.position=g.center(Vector2i(13,11));g.camera.force_update_scroll()
	await click(g.buttons.group0.get_global_rect().get_center())
	var tab=g.buttons.values().filter(func(button):return is_instance_valid(button) and button.text=="ゾーン")[0];await click(tab.get_global_rect().get_center())
	await click(g.buttons.zone_stockpile.get_global_rect().get_center())
	var first=g.screen_cell(Vector2i(11,7));var last=g.screen_cell(Vector2i(13,8));await motion(first);await mouse(first,true);await motion(last)
	g.queue_redraw();await process_frame;await RenderingServer.frame_post_draw;root.get_texture().get_image().save_png(out+"/zone-preview.png")
	await mouse(last,false);check(g.world.zones.size()==1 and g.world.zones[0].cells.size()==6,"Architect drag creates a six-cell stockpile")
	await click(g.buttons.zone_type_food.get_global_rect().get_center());check("food" not in g.world.zones[0].allowed,"UI toggles the selected stockpile's food permission")
	await click(g.buttons.zone_residential.get_global_rect().get_center());await click(g.screen_cell(Vector2i(15,8)));check(g.world.zones.size()==2,"UI creates a separate residential area")
	await click(g.buttons.zone_resize.get_global_rect().get_center());await click(g.screen_cell(Vector2i(16,8)));check(g.world.zones[1].cells==[Vector2i(16,8)],"UI changes residential bounds without touching objects")
	g.world.calendar_ticks=1728;g.world.last_daily_day=2;g.world.campaign.day=2;g.refresh();g.queue_redraw();await process_frame;await RenderingServer.frame_post_draw;root.get_texture().get_image().save_png(out+"/zones-clock.png")
	check(g.clock_label_text()=="05:00  朝","HUD shows the actual colony clock")
	await click(g.buttons.roles.get_global_rect().get_center());await click(g.buttons.research_save.get_global_rect().get_center());g.world.calendar_ticks+=100;g.world.Zones.remove(g.world,1)
	await click(g.buttons.research_load.get_global_rect().get_center());check(g.world.calendar_ticks==1728 and g.world.zones.size()==2,"UI save/load restores zones and exact clock together")
