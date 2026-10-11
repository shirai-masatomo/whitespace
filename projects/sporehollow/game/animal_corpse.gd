extends RefCounted
## Owned animal corpses are visual residents of the finished day, never campaign roster entries.
## This boundary deliberately does not share the enemy corpse/ resurrection timer.
const DISAPPEAR_AT="next_morning"

static func visible(a: Dictionary) -> bool:
	return a.get("dead",false) and not a.get("lost",false) and a.get("hp",1)<=0 and a.get("pos") is Vector2i

static func mark(a: Dictionary,tick: int):
	a.visual_death_tick=tick
	a.corpse_disappear_at=DISAPPEAR_AT
