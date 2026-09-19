extends RefCounted
## A sheltered fissure and an exposed offshore route, without a stage gate.


static func platforms() -> Array[Dictionary]:
	return [
		{
			"label": "谷の入口の藻",
			"point": Vector3(-7, -330, -80),
			"size": Vector2(14, 9),
			"kind": "cliff",
			"oxygen": true
		},
		{
			"label": "裂け目の岩棚",
			"point": Vector3(-27, -365, -100),
			"size": Vector2(7, 20),
			"kind": "rock"
		},
		{
			"label": "暗がりの藻",
			"point": Vector3(-12, -380, -122),
			"size": Vector2(12, 12),
			"kind": "kelp",
			"oxygen": true
		},
		{
			"label": "谷の外の流木",
			"point": Vector3(38, -350, -78),
			"size": Vector2(15, 12),
			"kind": "driftwood",
			"oxygen": true,
			"sway": Vector2(3, .35)
		},
		{
			"label": "浮き上がる群れ",
			"point": Vector3(30, -392, -111),
			"size": Vector2(9, 9),
			"kind": "jelly"
		},
		{
			"label": "裂け目の先",
			"point": Vector3(5, -450, -138),
			"size": Vector2(22, 18),
			"kind": "rock",
			"goal": true
		},
	]


static func geology() -> Array[Dictionary]:
	return [
		{"point": Vector3(-50, -312, -86), "size": Vector3(35, 153, 50), "seed": 931},
		{"point": Vector3(-45, -339, -126), "size": Vector3(28, 137, 50), "seed": 932},
		{"point": Vector3(0, -343, -153), "size": Vector3(30, 128, 28), "seed": 933},
		{"point": Vector3(65, -315, -110), "size": Vector3(35, 162, 70), "seed": 934},
		{"point": Vector3(-5, -458, -187), "size": Vector3(140, 100, 50), "seed": 935},
	]
