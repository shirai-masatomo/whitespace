extends RefCounted
const Forest=preload("res://game/forest_pattern.gd")

static func outward(w,p: Vector2i) -> Vector2i:
	if p.x<=0:return Vector2i.LEFT
	if p.x>=w.W-1:return Vector2i.RIGHT
	return Vector2i.UP if p.y<=0 else Vector2i.DOWN

static func advance(w,e,speed: float) -> bool:
	e.state="森の外へ運ぶ"
	if w.tick<e.move_stopped_until:return false
	e.move_credit=minf(1.9,e.move_credit+speed*w.Content.speed(w,e)*w.DT)
	if e.move_credit<1:return false
	var next=e.pos+outward(w,e.pos)
	if w.actor_occupied(next,e.pos) or not w.Combat.pay(e,"move"):return false
	e.move_credit-=1;e.pos=next;e.path.append(next)
	return true

static func keeper(w,e):
	if advance(w,e,1.0):w.keeper.pos=e.pos
	if not Forest.contains(e.pos,w.W,w.H):
		e.done=true;w.keeper.state="abducted";w.finish(false)

static func animal(w,e,a):
	# The animal follows the vacated cell, including the last forest cell.
	a.state="連れていかれる";e.action_id="lead"
	a.move_credit=minf(1.9,a.move_credit+a.move_speed*w.Content.speed(w,a)*w.DT)
	if w.distance(a.pos,e.pos)>1:
		if a.move_credit>=1:
			var next=w.animal_next(a,e.pos)
			if next!=a.pos and next!=e.pos:a.pos=next;a.move_credit-=1
		return
	if a.move_credit<1:return
	var previous=e.pos
	if advance(w,e,e.move_speed):a.pos=previous;a.move_credit-=1
	if not Forest.contains(a.pos,w.W,w.H):w.Progression.remove_animal(w,a,"abducted");e.done=true
