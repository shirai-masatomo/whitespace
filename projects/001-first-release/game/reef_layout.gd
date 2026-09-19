extends RefCounted
## A shelf walk and an offshore current bypass meet again below the rock arch.
## No gate: the open water remains a valid way around the terrain.


static func platforms() -> Array[Dictionary]:
	return [
		{
			"label": "岸壁の藻庭",
			"point": Vector3(-50, -190, -105),
			"size": Vector2(30, 8),
			"kind": "cliff",
			"oxygen": true
		},
		{
			"label": "崖沿いの細道",
			"point": Vector3(-64, -205, -93),
			"size": Vector2(8, 28),
			"kind": "rock"
		},
		{
			"label": "裂け目の光",
			"point": Vector3(-49, -235, -71),
			"size": Vector2(18, 8),
			"kind": "rock",
			"oxygen": true
		},
		{
			"label": "潮に乗る流木",
			"point": Vector3(16, -240, -60),
			"size": Vector2(10, 10),
			"kind": "driftwood",
			"oxygen": true,
			"sway": Vector2(4, .7)
		},
		{"label": "沖のクラゲ", "point": Vector3(35, -215, -73), "size": Vector2(7, 7), "kind": "jelly"},
		{
			"label": "岩陰の泉",
			"point": Vector3(-41, -172, -106),
			"size": Vector2(15, 12),
			"kind": "kelp",
			"oxygen": true
		},
		{
			"label": "岩陰の小さな藻",
			"point": Vector3(-28, -208, -88),
			"size": Vector2(8, 6),
			"kind": "rock",
			"oxygen": true
		},
	]


static func geology() -> Array[Dictionary]:
	# The left coast approaches, then an arch opens back onto the offshore basin.
	return [
		{"point": Vector3(-91, -166, -111), "size": Vector3(44, 115, 64), "seed": 801},
		{"point": Vector3(-88, -183, -68), "size": Vector3(39, 104, 38), "seed": 802},
		{"point": Vector3(-80, -220, -123), "size": Vector3(38, 100, 46), "seed": 803},
		{"point": Vector3(-72, -254, -91), "size": Vector3(24, 62, 30), "seed": 804},
		{"point": Vector3(-53, -256, -108), "size": Vector3(21, 48, 33), "seed": 805},
		{"point": Vector3(48, -238, -122), "size": Vector3(30, 102, 36), "seed": 806},
	]
