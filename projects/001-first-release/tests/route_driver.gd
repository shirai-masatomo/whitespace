extends RefCounted
## Steering uses only the same horizontal/descent inputs as a player.


static func input_for(model, target_index: int, fast: bool = false) -> Vector3:
	var target: Vector3 = model.platforms[target_index].position
	var offset := Vector2(target.x - model.position.x, target.z - model.position.z)
	var axis: Vector2 = (offset * 1.6 / model.config.horizontal_speed).limit_length()
	# Slow descent while far from the landing surface; never suspend gravity.
	var descent := -1.0 if offset.length() > 5 else 0.0
	if fast:
		var drop: float = model.position.y - target.y
		# Compare travel time, accelerating vertically only with alignment room.
		if drop > 0 and offset.length() / model.config.horizontal_speed < drop / 15.0 - .3:
			descent = 1.0
	return Vector3(axis.x, descent, axis.y)


static func reach(model, target_index: int, timeout: float = 40.0, fast: bool = false) -> bool:
	for frame in range(int(timeout * 60)):
		var command := input_for(model, target_index, fast)
		model.step(1.0 / 60, Vector2(command.x, command.z), command.y)
		if model.grounded == target_index:
			# Centre on the oxygen spot before advancing the route.
			if not model.platforms[target_index].oxygen or model.at_oxygen():
				return true
		if model.mode == model.Mode.RETURNING:
			return false
	return false


static func refill(model) -> void:
	model.step(1.0 / 60, Vector2.ZERO)
