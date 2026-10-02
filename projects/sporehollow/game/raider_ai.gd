extends RefCounted
## Controller chooses intent; world owns movement, construction damage and capture rules.
static func target(enemy: Dictionary, world) -> Vector2i:
	if enemy.flee or enemy.carry == "keeper":
		return world.exit_for(enemy.entry)
	return world.keeper.pos
