extends RefCounted
## Provisional role policy; perception never grants an unseen idol location.
const PRESSURE_ROLES=["kidnapper","salaryman","ninja","runner","doberman","destroyer"]
const DOWN_WEIGHTS={
	"kidnapper":{"keeper":0,"animal":10,"structure":10,"idol":80},
	"salaryman":{"keeper":0,"animal":20,"structure":10,"idol":70},
	"ninja":{"keeper":0,"animal":20,"structure":5,"idol":75},
	"runner":{"keeper":0,"animal":20,"structure":5,"idol":75},
	"doberman":{"keeper":0,"animal":25,"structure":0,"idol":75},
	"destroyer":{"keeper":0,"animal":0,"structure":30,"idol":70}}

static func keeper_down(w) -> bool:
	return w.keeper.hp<=0 or w.keeper.state in ["unconscious","restrained","captured","hidden_rest"]

static func weights(w,e) -> Dictionary:
	var row=DOWN_WEIGHTS.get(e.archetype,e.target_weights) if keeper_down(w) else e.target_weights
	var result=row.duplicate()
	if e.object_attack_power<=0:result.idol=0;result.structure=0
	return result

static func observe(w,e) -> Dictionary:
	if not w.story.idol.is_empty() and w.story.idol.hp>0 and w.story.idol.state!="lost":
		for cell in w.Story.idol_cells(w):
			if w.distance(e.pos,cell)<=e.sight_range and w.line_of_sight(e.pos,cell,true):
				e.last_known_idol_position=cell
				return {"kind":"idol","id":-1,"pos":cell}
	var last=e.get("last_known_idol_position")
	if last!=null and w.distance(e.pos,last)<=e.sight_range and w.line_of_sight(e.pos,last,true):
		# The remembered place can now be inspected and the idol is no longer there.
		e.erase("last_known_idol_position")
	return {}

static func focus(w,e,candidates: Array) -> Array:
	if e.archetype=="kidnapper" and w.Life.targetable(w,true):
		var keeper=candidates.filter(func(t):return t.kind=="keeper")
		if not keeper.is_empty():return keeper
	if not keeper_down(w) or e.archetype not in PRESSURE_ROLES or e.object_attack_power<=0:return candidates
	var idol=candidates.filter(func(t):return t.kind=="idol")
	if not idol.is_empty():return idol
	var last=e.get("last_known_idol_position")
	if last!=null:return [{"kind":"idol_memory","id":-1,"pos":last}]
	return candidates

static func support_target(w,e) -> Dictionary:
	var allies=w.enemies.filter(func(a):return a.id!=e.id and not a.done and not a.flee and a.hp>0 and a.archetype in PRESSURE_ROLES and w.distance(e.pos,a.pos)<=e.sight_range and w.line_of_sight(e.pos,a.pos))
	allies.sort_custom(func(a,b):return w.distance(e.pos,a.pos)<w.distance(e.pos,b.pos) if w.distance(e.pos,a.pos)!=w.distance(e.pos,b.pos) else a.id<b.id)
	return {} if allies.is_empty() else allies[0]
