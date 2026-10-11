extends RefCounted
## Numeric growth followed by cumulative explicit level overrides. No actor mutation.
static func resolve(base: Dictionary,level: int,growth: Dictionary={},overrides: Dictionary={}) -> Dictionary:
	var result=base.duplicate(true)
	for key in growth:
		result[key]=base.get(key,0)+growth[key]*maxi(0,level-1)
	var levels=overrides.keys();levels.sort_custom(func(a,b):return int(a)<int(b))
	for at in levels:
		if int(at)<=level:result.merge(overrides[at],true)
	result.lv=maxi(1,level)
	return result
