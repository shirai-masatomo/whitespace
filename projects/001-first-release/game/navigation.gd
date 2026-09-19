extends RefCounted
## Suggestions are geometric aids, not a promise of reaching a spot on remaining air.


static func candidates(model) -> Array[int]:
	var result: Array[int] = []
	for index in range(model.platforms.size()):
		var point: Vector3 = model.platforms[index].position
		var drop: float = -point.y - model.depth
		var distance := Vector2(point.x - model.position.x, point.z - model.position.z).length()
		if drop > 0.5 and drop <= 100 and distance <= 100:
			result.append(index)
	result.sort_custom(
		func(a, b): return model.platforms[a].position.y > model.platforms[b].position.y
	)
	if result.size() > 3:
		result.resize(3)
	return result


static func bearing(model, target: int, yaw: float) -> String:
	var offset: Vector3 = model.platforms[target].position - model.position
	var relative: float = wrapf(atan2(-offset.x, -offset.z) - yaw, -PI, PI)
	if absf(relative) < 0.4:
		return "前方 / 下を見る"
	if absf(relative) > 2.5:
		return "後方 / 振り向く"
	return "左方向" if relative > 0 else "右方向"
