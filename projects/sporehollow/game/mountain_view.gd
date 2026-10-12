extends RefCounted
## Fixed common canvas and anchors; no rescaling per stage.
const LARGE=[preload("res://art_delivery/mining_rock_objects_v1/rock_large_4x4_stage1.png"),preload("res://art_delivery/mining_rock_objects_v1/rock_large_4x4_stage2.png"),preload("res://art_delivery/mining_rock_objects_v1/rock_large_4x4_stage3.png"),preload("res://art_delivery/mining_rock_objects_v1/rock_large_4x4_stage4.png"),preload("res://art_delivery/mining_rock_objects_v1/rock_mined_remains.png")]
const SMALL=[preload("res://art_delivery/mining_rock_objects_v1/rock_small_1x1_stage1.png"),preload("res://art_delivery/mining_rock_objects_v1/rock_small_1x1_stage2.png"),preload("res://art_delivery/mining_rock_objects_v1/rock_small_1x1_stage3.png"),preload("res://art_delivery/mining_rock_objects_v1/rock_small_1x1_mined_remains.png")]
static func foot(g,r) -> Vector2:
	return g.center(r.pos)-g.TILE*0.5+Vector2(96,160) if r.kind=="large" else g.center(r.pos)+Vector2(0,14)
static func draw(g,r):
	var frames=LARGE if r.kind=="large" else SMALL
	var alpha=1.0 if r.remaining>0 else clampf(1.0-(g.world.tick-r.depleted_tick)*g.world.DT/g.world.Mountains.REMAINS_SECONDS,0,1)
	g.draw_texture(frames[mini(r.stage,frames.size()-1)],(foot(g,r)-(Vector2(112,224) if r.kind=="large" else Vector2(24,46))).round(),Color(1,1,1,alpha))
