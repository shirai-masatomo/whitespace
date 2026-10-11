extends RefCounted
## Final visible-boundary crossing. No forest extension or hidden walking lanes.
static func keeper(w,e):
	if not w.inside(e.pos):
		e.done=true;w.keeper.pos=e.pos;w.keeper.state="abducted";w.finish(false)

static func animal(w,e,a):
	# The follower is still rescuable on its last visible cell; removal waits for its own step.
	a.state="連れていかれる";e.action_id="lead";e.state="地図の外へ連れ去る"
	if not w.inside(a.pos):w.Progression.remove_animal(w,a,"abducted");e.done=true;return
	a.move_credit=minf(1.9,a.move_credit+a.move_speed*w.Content.speed(w,a)*w.DT)
	if a.move_credit<1 or w.tick<e.move_stopped_until:return
	if w.distance(a.pos,e.pos)>1:
		var next=w.animal_next(a,e.pos.clamp(Vector2i.ZERO,Vector2i(w.W-1,w.H-1)))
		if next!=a.pos and not w.actor_occupied(next,a.pos):a.pos=next;a.move_credit-=1
		return
	a.pos=e.pos;a.move_credit-=1
	w.Progression.remove_animal(w,a,"abducted");e.done=true
