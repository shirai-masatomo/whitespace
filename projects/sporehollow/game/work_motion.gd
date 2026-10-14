extends RefCounted
## Presentation only: one body, fixed foot, bounded cached textures. No work/stock mutation.
const Art=preload("res://game/adopted_art.gd")
const CONTACTS={
	"mine_left":preload("res://art_delivery/colony_growth_assets_v1/work_pose/mining_contact_left.png"),
	"mine_right":preload("res://art_delivery/colony_growth_assets_v1/work_pose/mining_contact_right.png"),
	"clear_tree_left":preload("res://art_delivery/colony_growth_assets_v1/work_pose/logging_contact_left.png"),
	"clear_tree_right":preload("res://art_delivery/colony_growth_assets_v1/work_pose/logging_contact_right.png")}
const PERIOD=0.75
const CONTACT_SECONDS=0.18

static func sample(kind:String,elapsed:float,facing:int,contact:bool=false)->Dictionary:
	var phase=fposmod(maxf(0,elapsed),PERIOD)/PERIOD
	var stage="contact" if contact or (kind=="build" and elapsed>=PERIOD and phase<0.24) else ("return" if elapsed>=PERIOD and phase<0.55 else "windup")
	var side="left" if facing<0 else "right"
	var official=stage=="contact" and kind in ["mine","clear_tree"]
	var clip=Art.CLIPS["keeper/idle/"+side]
	var anchor=Vector2(52,56) if facing<0 else Vector2(28,56)
	return {"kind":kind,"stage":stage,"phase":phase,"facing":-1 if facing<0 else 1,"official":official,"initial":elapsed<PERIOD,
		"texture":CONTACTS[kind+"_"+side] if official else clip.frames[0],"anchor":anchor if official else clip.anchor}

static func describe(w,key:String,accumulated:float,walking:bool,strike:Dictionary={})->Dictionary:
	if walking or not w.workers.has(key) or not w.working():return {}
	var a=w.workers[key]
	if a.get("needs_rest",false) or a.get("dead",false) or a.get("lost",false) or a.get("hp",0)<=0 or a.get("state","")!="free" or not a.get("placed",false):return {}
	if a.get("resting",false) or a.get("drafted",false) or a.get("nutrition_down",false) or a.get("carrier",-1)>=0 or a.get("danger_near",false) or w.tick<a.get("hurt_until",0) or a.get("life_need","")=="food":return {}
	if key=="keeper" and (w.manual_goal!=null or w.jobs_held):return {}
	var j=w.Work.active(w,key)
	if j.is_empty() or j.get("state")!="working" or j.get("cancel_requested",false) or not j.get("started",false):return {}
	var kind=j.kind
	if kind not in w.Harvest.KINDS:
		if not w.BUILD.has(kind) or j.get("phase","")!="work":return {}
		kind="build"
	var target=j.get("contact",j.pos)
	if w.distance(a.pos,target)>1:return {}
	var facing=-1 if target.x<a.pos.x else (1 if target.x>a.pos.x else int(a.get("facing",1)))
	var extra=0.0 if w.paused else minf(accumulated,w.DT)*w.Jobs.factor(a)
	var elapsed=j.get("work_elapsed",0.0) if kind!="build" else (ceili(w.BUILD[j.kind].seconds/w.DT)-j.get("remaining",0))*w.DT
	var age=(w.tick-strike.get("tick",-100000))*w.DT+(0.0 if w.paused else accumulated)
	var contact=kind!="build" and strike.get("kind")==kind and strike.get("pos")==target and age>=0 and age<CONTACT_SECONDS
	return sample(kind,elapsed+extra,facing,contact)

static func paint(canvas,state:Dictionary,foot:Vector2,scale_value:float)->bool:
	if state.is_empty():return false
	canvas.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	canvas.draw_texture_rect(state.texture,Rect2((foot-state.anchor*scale_value).round(),state.texture.get_size()*scale_value),false,Color.WHITE)
	if state.official:return true # Contact frame already contains the complete person and tool.
	var direction=state.facing
	var hand=Vector2(7*direction,-23)
	var hit=Vector2((31 if state.kind=="clear_tree" else 23)*direction,-14 if state.kind!="mine" else -10)
	# The handle pivots around the hand instead of shrinking to a six-pixel stub.
	# Eased arc: a slower lift, a short accelerating strike, then a relaxed recovery.
	var rest=Vector2(25*direction,-33)
	var raised=Vector2(-7*direction,-46)
	var tip=hit
	if state.stage=="return":tip=arc(hand,hit,rest,ease_motion(clampf((state.phase-0.24)/0.31,0,1)))
	elif state.stage=="windup":
		var t=state.phase if state.initial else clampf((state.phase-0.55)/0.45,0,1)
		tip=arc(hand,rest,raised,ease_motion(t/0.7)) if t<0.7 else arc(hand,raised,hit,pow((t-0.7)/0.3,2.0))
	var h=foot+hand*scale_value;var end=foot+tip*scale_value
	canvas.draw_line(h,end,Color("8c6444"),2*scale_value)
	# Head rotates with the shaft, mirrored for the same silhouette in both directions.
	var forward=(tip-hand).normalized();var across=Vector2(-forward.y,forward.x)
	if state.kind=="mine":
		var points=PackedVector2Array()
		for offset in [Vector2(-9,-2),Vector2(-4,2),Vector2(5,2),Vector2(9,-2)]:points.append(end+(across*offset.x+forward*offset.y)*scale_value)
		canvas.draw_polyline(points,Color("bbc0b3"),2*scale_value)
	else:
		var points=PackedVector2Array()
		var shape=[Vector2(-3,-4),Vector2(5,-4),Vector2(7,1),Vector2(4,5),Vector2(-3,3)] if state.kind=="clear_tree" else [Vector2(-5,-3),Vector2(5,-3),Vector2(5,3),Vector2(-5,3)]
		for offset in shape:points.append(end+(across*offset.x+forward*offset.y)*scale_value)
		canvas.draw_colored_polygon(points,Color("bbc0b3") if state.kind=="clear_tree" else Color("c9c5a5"))
	return true

static func ease_motion(t:float)->float:
	t=clampf(t,0,1);return t*t*(3.0-2.0*t)

static func arc(pivot:Vector2,start:Vector2,end:Vector2,t:float)->Vector2:
	var a=start-pivot;var b=end-pivot
	return pivot+Vector2.from_angle(lerp_angle(a.angle(),b.angle(),t))*lerpf(a.length(),b.length(),t)
