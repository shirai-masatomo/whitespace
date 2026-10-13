extends SceneTree
const Farm=preload("res://game/world.gd")
var checks=[]
func _initialize():call_deferred("run")
func check(ok,note):
	checks.append({"passed":ok,"check":note})
	if not ok:push_error(note)
func sample(w):
	return {"day":w.campaign.day,"time":w.Cycle.label(w),"tick":w.tick,"built":w.metrics.built,"jobs":w.jobs.size(),"keeper_hp":w.keeper.hp,"satiety":w.keeper.satiety,"sleepiness":w.keeper.sleepiness,"idol_hp":w.story.idol.hp,"gold":w.campaign.gold,"used":w.stock_used.duplicate(),"wood":w.Stock.summary(w,"wood"),"food":w.Stock.summary(w,"mushroom"),"enemies":w.enemies.filter(func(e):return not e.done and e.hp>0).size(),"result":w.result,"reason":w.story.defeat_reason}
func plan(w):
	var origin=w.keeper.pos
	for offset in [Vector2i(-3,-2),Vector2i(-3,-1),Vector2i(-3,0)]:w.act("wood_wall",origin+offset)
	var trees=w.trees.keys();trees.sort_custom(func(a,b):return w.distance(origin,a)<w.distance(origin,b))
	for p in trees:
		if w.Tasks.designate(w,"clear_tree",p):break
	var rocks=w.rocks.keys();rocks.sort_custom(func(a,b):return w.distance(origin,a)<w.distance(origin,b))
	for p in rocks:
		if w.Tasks.designate(w,"mine",p):break
	w.Tasks.designate(w,"train",Vector2i.ZERO,1)
func policy(w,mode):
	if mode=="wait":return
	if w.tick%20==0:
		for r in w.field_items.duplicate():
			if r.location=="ground" and not w.Stock.stored(w,r) and not r.get("forbidden",false):w.Stock.designate(w,"haul",r.pos,r.pos)
		if w.Stock.summary(w,"mushroom").owned<4:
			var cells=w.natural.keys().filter(func(p):return w.natural[p]=="mushroom")
			cells.sort_custom(func(a,b):return w.distance(w.keeper.pos,a)<w.distance(w.keeper.pos,b))
			if not cells.is_empty():w.act("collect",cells[0])
		if w.story.idol.hp<w.story.idol.max_hp:w.act("repair_idol_wood",w.Story.at(w))
		if w.keeper.get("rest_kind","")=="manual" and not w.keeper.forced_rest:w.act("keeper_rest")
func run():
	var output=OS.get_environment("FARM_REVIEW_OUTPUT")
	if output=="" or "--isolated-review" not in OS.get_cmdline_user_args():quit(2);return
	var reports=[]
	for mode in ["wait","prepare"]:
		var w=Farm.new({},31).begin_day();w.story.intro_seen=true
		if mode=="prepare":plan(w)
		var start=Time.get_ticks_msec();var samples=[sample(w)];var idle=0;var last_day=w.campaign.day;var stopped="three_days"
		for n in range(5184):
			if Time.get_ticks_msec()-start>65000:stopped="wall_time_budget";break
			policy(w,mode);w.step()
			if w.jobs.is_empty() and not w.keeper.resting:idle+=1
			if w.tick%432==0:samples.append(sample(w))
			if w.campaign.day!=last_day:
				last_day=w.campaign.day
				var before=w.Stock.totals(w);var tick=w.tick
				check(w.Snapshot.save(w,output+"/journey.snapshot"),"Daily snapshot saves: "+mode)
				w=w.Snapshot.restore(output+"/journey.snapshot")
				check(w!=null and w.tick==tick and w.Stock.totals(w)==before,"Daily reload preserves physical goods and time: "+mode)
			if w.result!="":stopped="game_result";break
		reports.append({"policy":mode,"seed":31,"stop":stopped,"samples":samples,"final":sample(w),"idle_game_seconds":idle*w.DT,"events":w.player_events.duplicate(true),"seconds":(Time.get_ticks_msec()-start)/1000.0})
		check(w.tick>1000,"Natural world reaches at least its first night: "+mode)
		check(w.field_items.all(func(r):return r.amount>0),"No nonpositive physical stacks in observed play: "+mode)
	var passed=checks.all(func(c):return c.passed)
	FileAccess.open(output+"/quality-journey.json",FileAccess.WRITE).store_string(JSON.stringify({"method":"Bounded production World.step with normal starting seed31 and two scripted policies, no forced victory/HP/resources. 3 days maximum, daily isolated save/load. This measures outcomes, not human comfort or fun.","checks":checks,"passed":passed,"reports":reports},"\t"))
	quit(0 if passed else 1)
