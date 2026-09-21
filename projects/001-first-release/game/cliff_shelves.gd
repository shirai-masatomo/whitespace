extends Node3D
## Broad fractured beds penetrate the cliff and become its walkable ledges.
const Geo = preload("res://game/ocean_geometry.gd")
const Nature = preload("res://game/ocean_nature.gd")
const Collision = preload("res://game/level_collision.gd")


func _ready() -> void:
	name = "JoinedTerraces"
	bed("HighAlgaeLip", Vector3(-74, -173, -107), 40, 17, 7, 6)
	bed("UpperBalcony", Vector3(-80, -190.8, -112), 46, 36, 8, 1)
	bed("RecessWalk", Vector3(-80, -214, -103), 28, 33, 11, 2)
	bed("LowerAlgaeStratum", Vector3(-77, -235.8, -74), 33, 27, 20, 3)
	bed("DeepUpperBed", Vector3(-53, -366, -104), 28, 30, 15, 4)
	bed("DeepLowerBed", Vector3(-43, -381, -125), 34, 22, 24, 5)


func bed(
	label: String, origin: Vector3, reach: float, width: float, thickness: float, seed_value: int
) -> void:
	var part := Node3D.new()
	part.name = label
	add_child(part)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for row in range(24):
		for col in range(18):
			var a := point(origin, reach, width, row / 24.0, col / 18.0, seed_value)
			var b := point(origin, reach, width, (row + 1) / 24.0, col / 18.0, seed_value)
			var c := point(origin, reach, width, (row + 1) / 24.0, (col + 1) / 18.0, seed_value)
			var d := point(origin, reach, width, row / 24.0, (col + 1) / 18.0, seed_value)
			quad(st, a, d, c, b)
			var down := Vector3.DOWN * thickness
			quad(st, a + down, b + down, c + down, d + down)
			for edge in [[a, b, col == 0], [b, c, row == 23], [c, d, col == 17], [d, a, row == 0]]:
				if edge[2]:
					quad(st, edge[0], edge[1], edge[1] + down, edge[0] + down)
	st.generate_normals()
	var material := Nature.stone()
	material.set_shader_parameter("strata_strength", .7)
	Geo.put(part, st.commit(), material)
	for i in range(9):
		var root := point(origin, reach, width, .7 + sin(i) * .18, (i + .5) / 9, seed_value)
		Nature.kelp(part, root, 1.4 + i % 3, seed_value * 20 + i)
	Collision.build(part)


static func point(
	origin: Vector3, reach: float, width: float, u: float, v: float, seed_value: int
) -> Vector3:
	# A deep connected root, scalloped outer edge and tilted bedding, not a disk.
	var edge := .84 + sin(v * 7 + seed_value) * .1 + sin(v * 19) * .06
	var x := origin.x + u * reach * edge
	var z := origin.z + (v - .5) * width + sin(u * 4 + seed_value) * 2
	var y := origin.y - (1 - u) * 2 + sin(v * 9 + u * 5) * .35
	return Vector3(x, y, z)


static func quad(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3) -> void:
	for vertex in [a, b, c, a, c, d]:
		st.set_uv(Vector2(vertex.x, vertex.z) * .05)
		st.add_vertex(vertex)
