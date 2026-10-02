extends RefCounted
## An AI controller produces intent; the world owns movement and rule resolution.
## A future human controller can supply the same target without changing rules.

static func target(enemy: Dictionary, world) -> Vector2i:
	if enemy.flee or enemy.carry != "":
		return enemy.entry
	if world.eggs > 0:
		return world.nest
	return world.store
