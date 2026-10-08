extends RefCounted
## Presentation only. Existing simulation owns damage, recovery, movement and capture.
const Data=preload("res://game/six_motion_clips.gd")
const ACTORS=["maid","dancer","thief","cow","bull"]

static func clip(who: String,action: String,facing: int=1) -> Dictionary:
	var key=who+"/"+action+("/left" if facing<0 else "/right")
	assert(Data.CLIPS.has(key),"Missing delivered motion: "+key)
	return Data.CLIPS.get(key,{})

static func duration(who: String,action: String) -> float:
	var total=0.0
	for f in clip(who,action).frames:total+=f.ms/1000.0
	return total

static func frame(who: String,action: String,facing: int,elapsed: float) -> Dictionary:
	var c=clip(who,action,facing);var t=maxf(0,elapsed)
	if c.loop:t=fmod(t,duration(who,action))
	for f in c.frames:
		if t<f.ms/1000.0:return f
		t-=f.ms/1000.0
	return c.frames.back()

static func paint(c: CanvasItem,who: String,action: String,facing: int,foot: Vector2,elapsed: float):
	var f=frame(who,action,facing,elapsed)
	c.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	c.draw_texture(f.texture,(foot-f.anchor).round())

static func key(a: Dictionary,enemy: bool) -> String:
	return ("e" if enemy else "a")+str(a.id)

static func once(p: Dictionary,action: String,time: float):
	p.once=action;p.once_at=time

static func update(g,a: Dictionary,enemy: bool):
	var who=a.get("archetype",a.get("species","")) if enemy else a.species
	if who not in ACTORS:return
	var id=key(a,enemy);var t=g.visual_time
	var p=g.six_art.get(id,{"action":"idle","at":t,"cell":a.pos,"hp":a.hp,"facing":a.get("facing",1)})
	if not p.has("cell"):p.cell=a.pos;p.hp=a.hp
	var delta=a.pos-p.cell
	if delta.x!=0:p.facing=signi(delta.x)
	var walking=Vector2(a.pos).distance_to(g.view_positions.get(id,Vector2(a.pos)))>0.025
	if not walking and a.get("chosen_target",{}).has("pos") and a.chosen_target.pos.x!=a.pos.x:p.facing=signi(a.chosen_target.pos.x-a.pos.x)
	var action=("run" if who in ["bull","thief"] else "walk") if walking else "idle"
	var raging=g.world.tick<a.get("rage_until",0)
	if who=="maid":
		if raging:
			action="rage_run" if walking else "rage_attack" if a.get("state","")=="激ギレ" else "idle"
			if not p.get("raging",false):once(p,"rage_start",t)
		elif p.get("raging",false):once(p,"rage_end",t)
		if not walking and (a.get("mode","")=="rest" or g.world.tick<a.get("coffee_rest_until",0)):action="rest"
		if a.get("coffee_rest_until",0)>p.get("coffee_rest",a.get("coffee_rest_until",0)):once(p,"drink",t)
		if p.get("once","")=="coffee_serve" and t-p.once_at>=duration(who,"coffee_serve"):once(p,"twirl",t)
	if who=="dancer" and not walking and g.world.tick<a.get("dancing_until",0):action="dance"
	if who=="thief":
		if a.get("poison_fired",-1)>p.get("poison",a.get("poison_fired",-1)):once(p,"poison_throw",t)
		if not a.get("stolen",{}).is_empty() and not p.get("stolen",false):once(p,"steal",t)
	if who=="cow":
		var milking=g.world.jobs.any(func(j):return j.kind=="milk" and j.get("animal_id",-1)==a.id and j.state=="working")
		if milking:action="milking_hold"
		if milking and not p.get("milking",false):once(p,"milking_start",t)
		if not milking and p.get("milking",false):once(p,"milking_end",t)
		p.milking=milking
	if who=="bull":
		var charging=a.get("mode","")=="charge"
		if charging:action="charge"
		elif not walking and a.hp>0 and a.hp<=a.max_hp*0.5:action="guts"
		if charging and not p.get("charging",false):once(p,"charge_start",t)
		if not charging and p.get("charging",false):once(p,"charge_end",t)
		p.charging=charging
	if a.get("next_attack",0)>p.get("attack",a.get("next_attack",0)) and who!="cow" and (who!="maid" or raging):once(p,"rage_attack" if who=="maid" else "attack",t)
	if a.hp>0 and p.hp<=0 and who in ["maid","dancer","thief"]:once(p,"get_up",t)
	elif a.hp>0 and a.hp<p.hp:once(p,"hurt",t)
	if p.has("once"):
		if t-p.once_at<duration(who,p.once):action=p.once
		else:p.erase("once")
	if a.get("flee",false) and a.hp>0 and walking and who in ["maid","dancer","thief"]:action="retreat"
	if a.hp<=0:
		action="downed" if who in ["dancer","thief"] else "death"
		if p.hp>0:p.death_at=t;p.death_pos=a.pos
	if action!=p.action:p.action=action;p.at=p.once_at if action==p.get("once","") else t
	elif action==p.get("once",""):p.at=p.once_at
	p.cell=a.pos;p.hp=a.hp;p.attack=a.get("next_attack",0);p.raging=raging;p.coffee_rest=a.get("coffee_rest_until",0);p.poison=a.get("poison_fired",-1);p.stolen=not a.get("stolen",{}).is_empty()
	g.six_art[id]=p

static func skill(g,event: Dictionary):
	var id=("e" if event.get("faction","")=="enemy" else "a")+str(event.actor)
	if event.skill not in ["coffee_support","resurrection"]:return
	var p=g.six_art.get(id,{"action":"idle","at":g.visual_time,"facing":1})
	once(p,"ultimate" if event.skill=="resurrection" else "coffee_serve",g.visual_time)
	g.six_art[id]=p

static func draw(g,c,a: Dictionary,foot: Vector2,enemy: bool=false):
	var who=a.get("archetype",a.get("species","")) if enemy else a.species
	var p=g.six_art.get(key(a,enemy),{"action":"idle","at":g.visual_time,"facing":a.get("facing",1)})
	var elapsed=g.visual_time-p.at
	if who=="maid" and g.world.tick<a.get("rage_until",0):paint(c,who,"rage_aura",p.facing,foot,elapsed)
	paint(c,who,p.action,p.facing,foot,elapsed)
	if who=="bull" and a.hp>0 and a.hp<=a.max_hp*0.5:paint(c,who,"guts_breath",p.facing,foot,elapsed)
	if who=="thief" and p.action=="steal" and not a.get("stolen",{}).is_empty():
		var f=frame(who,p.action,p.facing,elapsed)
		if f.sockets.has("item"):
			var pos=foot-f.anchor+Vector2(f.sockets.item[0],f.sockets.item[1])
			var tex=g.MarketView.texture_for(a.stolen.kind)
			if tex!=null:
				var size=tex.get_size();var scale_value=12.0/maxf(size.x,size.y)
				c.draw_texture_rect(tex,Rect2(pos-size*scale_value*0.5,size*scale_value),false)
			var index=0 if elapsed<0.36 else 1
			var hand=clip(who,"hand_front",p.facing).frames[index]
			c.draw_texture(hand.texture,foot-hand.anchor)

static func bounds(g,a: Dictionary,enemy: bool=false) -> Rect2:
	var who=a.get("archetype",a.get("species","")) if enemy else a.species
	var id=key(a,enemy);var p=g.six_art.get(id,{"action":"idle","at":g.visual_time,"facing":a.get("facing",1)})
	var f=frame(who,p.action,p.facing,g.visual_time-p.at);var used=Rect2(f.texture.get_image().get_used_rect())
	var scale_value=1.15 if who in ["maid","dancer","thief"] else 1.0
	return Rect2(g.actor_pixel(id,a.pos)+Vector2(0,14)+(used.position-f.anchor)*scale_value,used.size*scale_value).grow(3)
