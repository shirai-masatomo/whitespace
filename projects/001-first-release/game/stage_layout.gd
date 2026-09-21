extends RefCounted
## Shared platform data for collision, visuals, route hints and tests.
const JELLY_RADIUS_SCALE := .56
const JELLY_SEGMENTS := 48
const BUOY_TOP_SCALE := .54
const BUOY_SEGMENTS := 36
const Reef = preload("res://game/reef_layout.gd")
const Biology = preload("res://game/biology_layout.gd")
const Rift = preload("res://game/rift_layout.gd")


static func platforms() -> Array[Dictionary]:
	var data: Array[Dictionary] = [
		make("海へ続く桟橋", Vector3(0, 6, 0), Vector2(18, 16)),
		make("漂う棚", Vector3(14, -30, -18), Vector2(14, 12)),
		make("酸素 01", Vector3(-8, -60, -35), Vector2(18, 16), true),
		make("青のひさし", Vector3(20, -90, -58), Vector2(14, 12)),
		make("酸素 02", Vector3(45, -125, -45), Vector2(18, 16), true),
		make("漂流コンテナ", Vector3(20, -155, -77), Vector2(14, 12), false, false, Vector2(6, 0.5)),
		make("酸素 03", Vector3(-12, -190, -84), Vector2(18, 16), true),
		make("深海の棚", Vector3(-32, -225, -60), Vector2(14, 12)),
		make("酸素 04", Vector3(-7, -260, -36), Vector2(18, 16), true),
		make("岩礁の灯", Vector3(20, -300, -55), Vector2(22, 20), true),
		make("寄り道の酸素", Vector3(-28, -95, -52), Vector2(16, 14), true),
		make("潮待ちの藻庭", Vector3(-43, -140, -56), Vector2(17, 15), true),
		make("静かな藻の棚", Vector3(-42, -225, -32), Vector2(17, 15), true),
	]
	var kinds := [
		"pier",
		"cliff",
		"kelp",
		"driftwood",
		"jelly",
		"buoy",
		"rock",
		"kelp",
		"rock",
		"rock",
		"driftwood",
		"kelp",
		"rock"
	]
	var names := [
		"海へ続く桟橋",
		"岸壁の岩棚",
		"海藻の泉",
		"沈んだ流木",
		"漂うクラゲ",
		"観測ブイ",
		"浮遊岩",
		"海藻の棚",
		"深層の藻",
		"岩礁の灯",
		"流木の藻",
		"潮待ちの藻庭",
		"静かな藻の棚"
	]
	for index in range(data.size()):
		data[index]["kind"] = kinds[index]
		data[index]["shape_seed"] = index + 8
		data[index]["label"] = names[index]
		data[index]["round"] = kinds[index] not in ["pier", "driftwood"]
	for entry in Reef.platforms() + Rift.platforms() + Biology.platforms():
		var added := make(
			entry.label,
			entry.point,
			entry.size,
			entry.get("oxygen", false),
			entry.get("goal", false),
			entry.get("sway", Vector2.ZERO)
		)
		added["kind"] = entry.kind
		added["shape_seed"] = 100 + data.size()
		added["round"] = entry.kind != "driftwood"
		data.append(added)
	return data


static func make(
	label: String,
	point: Vector3,
	size: Vector2,
	oxygen: bool = false,
	goal: bool = false,
	sway: Vector2 = Vector2.ZERO
) -> Dictionary:
	return {
		"label": label,
		"position": point,
		"origin": point,
		"sway": sway,
		"size": size,
		"oxygen": oxygen,
		"goal": goal
	}


static func routes() -> Dictionary:
	var result := {
		"platforms": [1, 2, 3, 4, 5, 6, 7, 8, 9],
		"direct_oxygen": [2, 4, 6, 8, 9],
		"extra_oxygen": [1, 2, 10, 4, 5, 6, 7, 8, 9],
		"safe_gardens": [1, 2, 10, 11, 6, 12, 8, 9],
		"fast_drop": [2, 10, 6, 8, 9],
		"current_gardens": [1, 2, 10, 11, 6, 8, 9],
		"cliff_walk": [1, 2, 10, 11, 18, 13, 14, 15, 8, 9],
		"offshore_life": [2, 4, 5, 6, 17, 16, 8, 9],
		"reef_refuge": [2, 10, 6, 19, 15, 8, 9],
	}
	for route in result.values():
		route.append_array([20, 21, 22, 25])
	result["rift_offshore"] = [2, 4, 5, 6, 17, 16, 8, 9, 23, 24, 25]
	result["rift_shortcut"] = [2, 10, 6, 8, 23, 25]
	for route in result.values():
		route.append_array(biology_route())
	return result


static func finish_route() -> Array[int]:
	return [20, 21, 22, 25] + biology_route()


static func fast_routes() -> Array[String]:
	return ["fast_drop", "current_gardens", "rift_offshore", "rift_shortcut"]


static func goal_index() -> int:
	var entries := platforms()
	for index in range(entries.size()):
		if entries[index].goal:
			return index
	return -1


static func current_zones() -> Array[Dictionary]:
	return [
		{
			"center": Vector3(31, -374, -93),
			"radius": Vector3(20, 18, 19),
			"flow": Vector3(-.7, 2.8, -2)
		},
		{
			"center": Vector3(30, -232, -80),
			"radius": Vector3(18, 20, 16),
			"flow": Vector3(0, 2.5, -1.5)
		},
		{
			"center": Vector3(10, -43, -25),
			"radius": Vector3(22, 9, 20),
			"flow": Vector3(1.8, 0, .3)
		},
		{
			"center": Vector3(35, -142, -55),
			"radius": Vector3(22, 10, 24),
			"flow": Vector3(-1.6, 0, 0)
		},
		{
			"center": Vector3(-31, -150, -67),
			"radius": Vector3(32, 16, 28),
			"flow": Vector3(5.0, 0, -3.5)
		},
	]


static func biology_route() -> Array[int]:
	return [26, 27, 28, 29, 30, 31, 32, 33]
