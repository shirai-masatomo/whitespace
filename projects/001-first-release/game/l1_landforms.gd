extends Node3D
## Displaced strata form places to cross, dive beneath and follow to the final basin.
const Geo = preload("res://game/ocean_geometry.gd")
const Nature = preload("res://game/ocean_nature.gd")
const Collision = preload("res://game/level_collision.gd")
const Shelves = preload("res://game/cliff_shelves.gd")
const PROFILE: Array[Vector2] = [
	Vector2(-1, -.5),
	Vector2(-.92, .4),
	Vector2(-.68, .75),
	Vector2(-.36, .76),
	Vector2(-.25, 1),
	Vector2(.3, .93),
	Vector2(.47, .48),
	Vector2(.83, .45),
	Vector2(1, .05),
	Vector2(.72, -.66),
	Vector2(.13, -1),
	Vector2(-.58, -.86)
]


func _ready() -> void:
	name = "FaultedCoast"
	add_child(Shelves.new())
	# Seen above the first landing: fish cross an opening, not another flat target.
	mass(
		"WindowAboveGarden",
		[
			Vector3(-27, -45, -64),
			Vector3(-24, -26, -64),
			Vector3(-9, -21, -67),
			Vector3(9, -28, -65),
			Vector3(14, -45, -64)
		],
		Vector2(4.8, 3.2),
		53
	)
	# The exposed bridge spans a hollow bay. Its two roots descend into the reef;
	# the route runs OVER the displaced bed or UNDER it with the current.
	mass(
		"ShallowWestRoot",
		[Vector3(-29, -154, -134), Vector3(-24, -93, -123), Vector3(-18, -58, -114)],
		Vector2(17, 16),
		11
	)
	mass(
		"ShallowEastRoot",
		[Vector3(106, -202, -105), Vector3(82, -113, -114), Vector3(61, -61, -112)],
		Vector2(19, 19),
		12
	)
	mass(
		"BrokenSkyBridge",
		[
			Vector3(-23, -54, -114),
			Vector3(-1, -49, -112),
			Vector3(24, -43, -118),
			Vector3(44, -49, -122),
			Vector3(65, -64, -116)
		],
		Vector2(9, 6),
		13
	)
	# Fault scarps have offset upper and lower lips, not free-floating little decks.
	mass(
		"WestFault160",
		[
			Vector3(-86, -277, -139),
			Vector3(-76, -217, -137),
			Vector3(-58, -167, -140),
			Vector3(-40, -146, -153)
		],
		Vector2(25, 16),
		21
	)
	mass(
		"EastFault220",
		[
			Vector3(120, -325, -93),
			Vector3(112, -261, -89),
			Vector3(115, -225, -109),
			Vector3(107, -202, -124)
		],
		Vector2(25, 19),
		22
	)
	mass(
		"DeepWestUplift",
		[
			Vector3(-66, -459, -136),
			Vector3(-62, -405, -140),
			Vector3(-65, -366, -113),
			Vector3(-70, -308, -87)
		],
		Vector2(21, 18),
		31
	)
	mass(
		"DeepEastUplift",
		[
			Vector3(91, -456, -146),
			Vector3(90, -398, -132),
			Vector3(82, -351, -128),
			Vector3(84, -313, -140)
		],
		Vector2(24, 20),
		32
	)
	# Cross-bedding gives the bottom approach a substantial back wall and a low mouth.
	mass(
		"TerminalFaultShoulder",
		[
			Vector3(-59, -449, -186),
			Vector3(-21, -426, -184),
			Vector3(20, -421, -183),
			Vector3(68, -433, -184),
			Vector3(114, -452, -173)
		],
		Vector2(15, 19),
		41
	)
	# Vegetation roots are taken from the authored ridge, never suspended in water.
	var crest: Array[Vector3] = [
		Vector3(-23, -54, -114),
		Vector3(-1, -49, -112),
		Vector3(24, -43, -118),
		Vector3(44, -49, -122),
		Vector3(65, -64, -116)
	]
	for i in range(16):
		var ring := section(crest, Vector2(9, 6), (i + .5) / 16, 13)
		Nature.canopy(self, ring[12], 3 + i % 5, 1200 + i)


func mass(label: String, spine: Array[Vector3], size: Vector2, seed_value: int) -> void:
	var part := Node3D.new()
	part.name = label
	add_child(part)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var rows := (spine.size() - 1) * 16
	for row in range(rows):
		var first := section(spine, size, row / float(rows), seed_value)
		var second := section(spine, size, (row + 1) / float(rows), seed_value)
		for side in range(first.size()):
			var next := (side + 1) % first.size()
			tri(st, first[side], second[next], second[side])
			tri(st, first[side], first[next], second[next])
		if row == 0 or row == rows - 1:
			var ring := first if row == 0 else second
			var center := Vector3.ZERO
			for point in ring:
				center += point / ring.size()
			for side in range(ring.size()):
				if row == 0:
					tri(st, center, ring[(side + 1) % ring.size()], ring[side])
				else:
					tri(st, center, ring[side], ring[(side + 1) % ring.size()])
	st.generate_normals()
	var material := Nature.stone()
	material.set_shader_parameter("strata_strength", .85)
	Geo.put(part, st.commit(), material)
	Collision.build(part)


static func section(
	spine: Array[Vector3], size: Vector2, t: float, seed_value: int
) -> PackedVector3Array:
	var progress := t * (spine.size() - 1)
	var index := mini(int(progress), spine.size() - 2)
	var center := spine[index].lerp(spine[index + 1], progress - index)
	if seed_value == 53:
		center = spine[index].cubic_interpolate(
			spine[index + 1],
			spine[maxi(0, index - 1)],
			spine[mini(index + 2, spine.size() - 1)],
			progress - index
		)
	# Use a stable horizontal section to keep steeply tilted strata thick as well.
	var tangent := spine[-1] - spine[0]
	var across := Vector3(-tangent.z, 0, tangent.x).normalized()
	var result := PackedVector3Array()
	for edge in range(PROFILE.size()):
		for division in range(3):
			var p := PROFILE[edge].lerp(PROFILE[(edge + 1) % PROFILE.size()], division / 3.0)
			var taper := .45 + .55 * pow(sin(t * PI), .35)
			var width := size.x * taper * (1 + sin(t * 12 + seed_value) * .22)
			var height := size.y * taper * (1 + cos(t * 9 + seed_value) * .18)
			var ledge := smoothstep(.3, .45, t) * (1 - smoothstep(.55, .7, t))
			var point := center + across * (p.x * width + ledge * size.x * .22)
			point += Vector3.UP * p.y * height
			var weather := sin(point.z * .19 + seed_value) * sin(point.x * .16) * .9
			point += across * weather + Vector3.UP * sin(point.x * .22 + point.z * .13) * .65
			result.append(point)
	return result


static func tri(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3) -> void:
	for point in [a, b, c]:
		st.set_uv(Vector2(point.x, point.z) * .05)
		st.add_vertex(point)
