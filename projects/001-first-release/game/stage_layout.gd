extends RefCounted
## Shared platform data for collision, visuals, route hints and tests.


static func platforms() -> Array[Dictionary]:
	return [
		make("出発点", Vector3(0, 0, 0), Vector2(18, 16), true),
		make("漂う棚", Vector3(14, -30, -18), Vector2(14, 12)),
		make("酸素 01", Vector3(-8, -60, -35), Vector2(18, 16), true),
		make("青のひさし", Vector3(20, -90, -58), Vector2(14, 12)),
		make("酸素 02", Vector3(45, -125, -45), Vector2(18, 16), true),
		make("宙の階段", Vector3(20, -155, -77), Vector2(14, 12)),
		make("酸素 03", Vector3(-12, -190, -84), Vector2(18, 16), true),
		make("深海の棚", Vector3(-32, -225, -60), Vector2(14, 12)),
		make("酸素 04", Vector3(-7, -260, -36), Vector2(18, 16), true),
		make("海底の灯", Vector3(20, -300, -55), Vector2(22, 20), false, true),
		make("寄り道の酸素", Vector3(-28, -95, -52), Vector2(16, 14), true),
	]


static func make(
	label: String, point: Vector3, size: Vector2, oxygen: bool = false, goal: bool = false
) -> Dictionary:
	return {"label": label, "position": point, "size": size, "oxygen": oxygen, "goal": goal}


static func routes() -> Dictionary:
	return {
		"platforms": [1, 2, 3, 4, 5, 6, 7, 8, 9],
		"direct_oxygen": [2, 4, 6, 8, 9],
		"extra_oxygen": [1, 2, 10, 4, 5, 6, 7, 8, 9],
	}
