extends RefCounted
## Presentation only. Reuses the delivered clip renderer and the existing actor clocks.
const SHURIKEN=preload("res://art_delivery/ninja_motion_v1/parts/shuriken.png")
const Art=preload("res://game/delivered_art.gd")
const SPECIES=["destroyer","martial_artist","salaryman","ninja","animal_tamer","runner","doberman","bullfrog","hedgehog"]

static func clip(who: String,action: String,facing: int) -> String:
	var key=who+"/"+action+("_left" if facing<0 else "_right")
	return key if Art.CLIPS.has(key) else who+"/idle"+("_left" if facing<0 else "_right")

static func duration(who: String,action: String) -> float:
	return Art.duration(clip(who,action,1))

static func update(g,a: Dictionary,enemy: bool):
	var who=a.get("archetype",a.get("species","")) if enemy else a.species
	if who not in SPECIES:return
	var id=("e" if enemy else "a")+str(a.id)
	var store=g.enemy_art if enemy else g.actor_art
	var key=a.id if enemy else id
	var p=store.get(key,{"action":"idle","at":g.visual_time,"facing":a.get("facing",1),"cell":a.pos,"hp":a.hp,"attack":a.next_attack})
	var dx=a.pos.x-p.get("cell",a.pos).x
	if dx!=0:p.facing=signi(dx)
	elif not enemy:p.facing=a.get("facing",p.facing)
	var walking=Vector2(a.pos).distance_to(g.view_positions.get(id,Vector2(a.pos)))>0.025
	var action=("move" if who in ["bullfrog","hedgehog"] else ("run" if who=="runner" else "walk")) if walking else "idle"
	if who=="doberman" and walking and a.get("rescuing",false):action="run"
	var state="phone" if a.get("phone_started",false) else ("defense" if g.world.tick<a.get("spines_until",0) else ("tired" if g.world.tick<a.get("tired_until",0) else ""))
	if state!=p.get("state",""):
		p.state_at=g.visual_time
		var exits={"phone":"phone_put","defense":"defense_exit","tired":"tired_exit"}
		if state=="" and exits.has(p.get("state","")):p.once=exits[p.state];p.once_at=g.visual_time
		p.state=state
	if state!="":
		var enter={"phone":"phone_take","defense":"defense_enter","tired":"tired_enter"}[state]
		var hold={"phone":"phone_call","defense":"defense","tired":"tired"}[state]
		action=enter if g.visual_time-p.state_at<duration(who,enter) else hold
	var raw=a.get("action_id","")
	if enemy and not walking and raw in ["bow","tame","attack","dagger","iron_ball_hit","shuriken"]:
		var target=a.get("chosen_target",{})
		if target.has("pos") and target.pos.x!=a.pos.x:p.facing=signi(target.pos.x-a.pos.x)
	if raw in ["bow","tame","lead"]:
		action="bow_end" if raw=="bow" and a.get("chosen_target",{}).is_empty() else raw
	if p.get("raw","")=="tame" and raw!="tame":p.once="tame_end";p.once_at=g.visual_time
	if who=="martial_artist" and not walking and raw=="attack":action="stance"
	if who=="destroyer" and not walking and raw=="iron_ball_hit" and a.next_attack>g.world.tick and (a.next_attack-g.world.tick)*g.world.DT<=duration(who,"iron_ball_windup"):
		action="iron_ball_windup"
	if a.next_attack>p.get("attack",a.next_attack) and who in ["doberman","martial_artist","ninja","destroyer","runner"]:
		p.swings=p.get("swings",0)+1
		p.once={"ninja":"dagger","destroyer":"iron_ball_hit"}.get(who,"kick" if who=="martial_artist" and p.swings%2==0 else "attack");p.once_at=g.visual_time
	if a.get("shuriken_at",0)>p.get("shuriken",a.get("shuriken_at",0)):
		p.once="shuriken";p.once_at=g.visual_time;p.shot_at=g.visual_time;p.shot_from=a.pos;p.shot_to=a.get("chosen_target",{}).get("pos",a.pos)
	if who=="bullfrog":
		var tongue=a.get("skill_ready",{}).get("tongue",0)
		if tongue>p.get("tongue",tongue):p.tongue_at=g.visual_time
		p.tongue=tongue
		if p.has("tongue_at"):
			var elapsed=g.visual_time-p.tongue_at
			if elapsed<0.3:action="tongue_extend"
			elif elapsed<g.world.ProgressData.SPECIAL.tongue_stop:action="tongue"
			elif elapsed<g.world.ProgressData.SPECIAL.tongue_stop+duration(who,"tongue_retract"):action="tongue_retract"
			else:p.erase("tongue_at")
	if a.hp<p.get("hp",a.hp) and a.hp>0 and p.get("once","")!="croak":p.once="hurt";p.once_at=g.visual_time
	if p.has("once"):
		if g.visual_time-p.once_at<duration(who,p.once):action=p.once
		else:p.erase("once")
	if a.get("flee",false):action="retreat" if walking else "idle"
	if a.hp<=0:action="death" if who=="doberman" else "idle"
	if action!=p.action:
		p.action=action;p.at=p.once_at if action==p.get("once","") else g.visual_time
	elif action==p.get("once",""):p.at=p.once_at
	p.cell=a.pos;p.hp=a.hp;p.attack=a.next_attack;p.raw=raw;p.shuriken=a.get("shuriken_at",0)
	store[key]=p

static func draw(g,c,a: Dictionary,foot: Vector2,enemy: bool=false):
	var who=a.get("archetype",a.get("species","")) if enemy else a.species
	var p=(g.enemy_art if enemy else g.actor_art).get(a.id if enemy else "a"+str(a.id),{})
	Art.draw_clip(c,clip(who,p.get("action","idle"),p.get("facing",1)),foot,g.visual_time-p.get("at",g.visual_time))
	if who=="ninja" and p.has("shot_at"):
		var flight=(g.visual_time-p.shot_at-0.12)/0.32
		if flight>=0 and flight<1:
			var point=g.center(p.shot_from).lerp(g.center(p.shot_to),flight)+Vector2(0,-14)
			c.draw_set_transform(point,flight*TAU*2)
			c.draw_texture(SHURIKEN,Vector2(-3,-3));c.draw_set_transform(Vector2.ZERO)

static func bounds(g,a: Dictionary,enemy: bool=false) -> Rect2:
	var id=("e" if enemy else "a")+str(a.id)
	var p=(g.enemy_art if enemy else g.actor_art).get(a.id if enemy else id,{})
	var key=clip(a.get("archetype",a.species) if enemy else a.species,p.get("action","idle"),p.get("facing",1))
	var frame=Art.CLIPS[key].frames[Art.frame_index(key,g.visual_time-p.get("at",g.visual_time))]
	var body=frame.body if frame is Dictionary else frame
	var used=Rect2(body.get_image().get_used_rect())
	var scale_value=1.15 if a.get("type_tag","")=="Human" else 1.0
	return Rect2(g.actor_pixel(id,a.pos)+Vector2(0,14)+(used.position-Art.CLIPS[key].anchor)*scale_value,used.size*scale_value).grow(3)

static func skill(g,event: Dictionary):
	if event.get("skill","") not in ["tongue","croak"]:return
	var key="a"+str(event.actor)
	var p=g.actor_art.get(key,{"action":"idle","at":g.visual_time,"facing":1})
	if event.skill=="tongue":p.tongue_target=event.target;p.tongue_at=g.visual_time
	else:p.once="croak";p.once_at=g.visual_time
	g.actor_art[key]=p

static func tongue_layer(g,e: Dictionary,front: bool):
	for a in g.world.animals:
		if a.species!="bullfrog" or not a.placed or a.hp<=0:continue
		var p=g.actor_art.get("a"+str(a.id),{})
		if p.get("tongue_target",-1)!=e.id or not p.has("tongue_at"):continue
		var key=clip("bullfrog",p.action,p.facing)
		if not Art.CLIPS[key].has("mouth"):continue
		var elapsed=g.visual_time-p.tongue_at
		var hold=g.world.ProgressData.SPECIAL.tongue_stop
		var reach=clampf(elapsed/0.3,0,1) if elapsed<hold else clampf(1-(elapsed-hold)/duration("bullfrog","tongue_retract"),0,1)
		var mouth=g.actor_pixel("a"+str(a.id),a.pos)+Vector2(0,14)-Art.CLIPS[key].anchor+Art.CLIPS[key].mouth[Art.frame_index(key,g.visual_time-p.at)]
		var target=g.actor_pixel("e"+str(e.id),e.pos)+Vector2(0,-8)
		var tip=mouth.lerp(target,reach)
		if not front:
			var body=Art.FROG_PARTS.tongue_body
			g.draw_set_transform(mouth,(tip-mouth).angle())
			g.draw_texture_rect(body.texture,Rect2(-body.anchor,Vector2(mouth.distance_to(tip),body.texture.get_height())),false)
			g.draw_set_transform(Vector2.ZERO)
			g.draw_texture(Art.FROG_PARTS.tongue_tip.texture,tip-Art.FROG_PARTS.tongue_tip.anchor)
		if is_equal_approx(reach,1):
			var wrap=Art.FROG_PARTS["tongue_wrap_front" if front else "tongue_wrap_back"]
			g.draw_texture(wrap.texture,target-wrap.anchor)
