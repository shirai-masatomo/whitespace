extends SceneTree
const Farm=preload("res://game/world.gd")
const Motion=preload("res://game/work_motion.gd")
const Art=preload("res://game/adopted_art.gd")
class Recorder:
	extends RefCounted
	var texture_filter=0
	var commands=[]
	func xy(v):return [v.x,v.y]
	func color(c):return [c.r,c.g,c.b,c.a]
	func draw_texture_rect(texture,rect,_tile,tint):commands.append({"type":"sprite","path":texture.resource_path,"rect":[rect.position.x,rect.position.y,rect.size.x,rect.size.y],"color":color(tint)})
	func draw_line(a,b,c,width):commands.append({"type":"line","points":[xy(a),xy(b)],"color":color(c),"width":width})
	func draw_polyline(points,c,width):
		var ps=[]
		for p in points:ps.append(xy(p))
		commands.append({"type":"line","points":ps,"color":color(c),"width":width})
	func draw_colored_polygon(points,c):
		var ps=[]
		for p in points:ps.append(xy(p))
		commands.append({"type":"polygon","points":ps,"color":color(c)})
	func draw_rect(rect,c):commands.append({"type":"rect","rect":[rect.position.x,rect.position.y,rect.size.x,rect.size.y],"color":color(c)})
var checks=[]
func check(ok,note):
	checks.append({"check":note,"passed":bool(ok)})
	if not ok:push_error(note)
func _initialize():call_deferred("run")
func run():
	var out=OS.get_environment("FARM_REVIEW_OUTPUT")
	if out=="" or DisplayServer.get_name()!="headless":quit(2);return
	var w=Farm.new(Farm.new_campaign(),31).begin_day();w.jobs.clear();w.jobs_held=false;w.manual_goal=null
	var a=w.keeper;a.pos=Vector2i(49,34);a.sleepiness=0;a.resting=false;a.needs_rest=false;a.drafted=false;a.state="free";a.life_need="";a.danger_near=false;a.hurt_until=0;w.tick=100
	var before=w.campaign.duplicate(true)
	var j={"id":900,"kind":"mine","pos":a.pos+Vector2i.RIGHT,"state":"working","started":true,"phase":"work","work_elapsed":0.75,"assigned_to":"keeper"}
	w.jobs.append(j)
	var event={"tick":w.tick,"kind":"mine","pos":j.pos}
	var pose=Motion.describe(w,"keeper",0,false,event)
	check(pose.get("official",false) and pose.facing==1,"Actual strike tick selects right contact")
	var r=Recorder.new();Motion.paint(r,pose,Vector2(160,128),1.4375)
	check(r.commands.size()==1 and r.commands[0].type=="sprite","Contact replaces body, no duplicate tool/body")
	check(pose.anchor==Vector2(28,56) and pose.texture.get_size()==Vector2(80,64),"Official right anchor and dimensions")
	j.pos=a.pos+Vector2i.LEFT;event.pos=j.pos;pose=Motion.describe(w,"keeper",0,false,event)
	check(pose.facing==-1 and pose.anchor==Vector2(52,56),"Target left selects left anchor")
	check(Motion.describe(w,"keeper",0,true,event).is_empty(),"Walking interpolation retains walk sprite")
	j.state="walking";check(Motion.describe(w,"keeper",0,false,event).is_empty(),"Approach is not work animation");j.state="working"
	for state in ["suspended","blocked","pending"]:
		j.state=state;check(Motion.describe(w,"keeper",0,false,event).is_empty(),"Stops during "+state)
	j.state="working";j.cancel_requested=true;check(Motion.describe(w,"keeper",0,false,event).is_empty(),"Cancel restores normal motion");j.erase("cancel_requested")
	a.needs_rest=true;check(Motion.describe(w,"keeper",0,false,event).is_empty(),"Low stamina rest restores normal motion");a.needs_rest=false
	a.life_need="food";check(Motion.describe(w,"keeper",0,false,event).is_empty(),"Eating restores normal motion");a.life_need=""
	w.jobs_held=true;w.job_hold_reason="auto_rest";check(Motion.describe(w,"keeper",0,false,event).is_empty() and w.jobs_held,"Presentation cannot release held jobs");w.jobs_held=false
	w.paused=true;var frozen=Motion.describe(w,"keeper",0,false,event);check(Motion.describe(w,"keeper",0.2,false,event)==frozen,"Pause freezes pose despite render time");w.paused=false
	w.tick+=1;j.work_elapsed=1.0;check(not Motion.describe(w,"keeper",0,false,event).official,"Contact returns to ordinary body")
	w.jobs.clear();check(Motion.describe(w,"keeper",0,false,event).is_empty(),"Completion restores normal motion")
	j.kind="wood_wall";j.remaining=8;j.phase="fetch";w.jobs.append(j);check(Motion.describe(w,"keeper",0,false).is_empty(),"Material pickup never swings hammer")
	j.phase="deliver";check(Motion.describe(w,"keeper",0,false).is_empty(),"Delivery never swings hammer")
	j.phase="work";pose=Motion.describe(w,"keeper",0,false)
	check(pose.get("kind")=="build","Construction stage gets common hammer")
	j.kind="craft";check(Motion.describe(w,"keeper",0,false).is_empty(),"Crafting is not mistaken for construction")
	j.kind="clear_tree";j.work_elapsed=0.75;event={"tick":w.tick,"kind":"clear_tree","pos":j.pos}
	check(Motion.describe(w,"keeper",0,false,event).official,"Logging uses its real strike")
	var resident=a.duplicate(true);resident.work_key="resident:preview";w.workers[resident.work_key]=resident;j.assigned_to=resident.work_key
	check(Motion.describe(w,resident.work_key,0,false,event).official,"Registered residents share work motion")
	check(w.campaign==before,"Presentation does not mutate campaign/resources")
	# Production timing (not simulated presentation phases): both directions and both target types.
	for kind in ["mine","clear_tree"]:
		for direction in [-1,1]:
			var live=Farm.new(Farm.new_campaign(),31).begin_day();live.jobs.clear();live.keeper.pos=Vector2i(49,34);live.keeper.sleepiness=0;live.keeper.satiety=100;live.keeper.resting=false
			live.enemies.clear();live.animals.clear();live.nature_config.spawn_chance_per_second=0
			var target=live.keeper.pos+Vector2i(direction,0)
			for cell in [live.keeper.pos,target]+live.neighbors(target):live.structures.erase(cell);live.rocks.erase(cell);live.trees.erase(cell);live.natural.erase(cell)
			if kind=="mine":live.rocks[target]={"amount":8,"forbidden":false}
			else:
				live.trees[target]="motion-tree"
				live.story.trees.append({"id":"motion-tree","position":[target.x,target.y]})
			live.Tasks.designate(live,kind,target)
			var hits=0;var aligned=true
			for tick in range(28):
				live.step()
				for e in live.harvest_events:
					if e.tick==live.tick and e.event=="strike":
						hits+=1
						var now=Motion.describe(live,"keeper",0,false,e)
						aligned=aligned and now.get("official",false) and now.get("facing")==direction
			check(hits>0 and aligned,"Production strike/contact alignment "+kind+str(direction))
			check(not live.Harvest.exists(live,kind,target) and Motion.describe(live,"keeper",0,false).is_empty(),"Production completion restores body "+kind+str(direction))
	var frames=[]
	for kind in ["mine","clear_tree","build"]:
		for direction in [-1,1]:
			for frame in range(36):
				var elapsed=frame/12.0
				var contact=elapsed>=0.75 and fposmod(elapsed,0.75)<Motion.CONTACT_SECONDS
				var state=Motion.sample(kind,elapsed,direction,contact if kind!="build" else false)
				var recorder=Recorder.new();Motion.paint(recorder,state,Vector2(100,110),1.4375)

				frames.append({"kind":kind,"direction":direction,"frame":frame,"stage":state.stage,"commands":recorder.commands})
			for stage in ["windup","contact","return"]:check(frames.any(func(f):return f.kind==kind and f.direction==direction and f.stage==stage),"Three-stage "+kind+str(direction)+stage)
	# Walk/idle comparison at the same foot using adopted original texture/anchor.
	var baselines=[]
	for direction in [-1,1]:
		for action in ["walk","idle"]:
			var clip=Art.CLIPS["keeper/"+action+("/left" if direction<0 else "/right")]
			var recorder=Recorder.new();recorder.draw_texture_rect(clip.frames[0],Rect2((Vector2(100,110)-clip.anchor*1.4375).round(),clip.frames[0].get_size()*1.4375),false,Color.WHITE)
			baselines.append({"direction":direction,"action":action,"commands":recorder.commands})
	check(frames.all(func(f):return f.commands.filter(func(c):return c.type=="sprite").size()==1),"All 216 sampled frames contain exactly one person")
	FileAccess.open(out+"/motion-draw-commands.json",FileAccess.WRITE).store_string(JSON.stringify({"frames":frames,"baselines":baselines,"method":"Production WorkMotion.paint commands, CPU review rendering; not a game screenshot"}))
	var fail=checks.filter(func(c):return not c.passed).size()
	FileAccess.open(out+"/work-motion.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":fail},"\t"))
	print("WORK_MOTION: ",checks.size()," checks, failures=",fail);quit(1 if fail else 0)
