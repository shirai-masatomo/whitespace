extends Node3D
## A reachable continental shelf, cut open by a deep basin and an eastern canyon.
const Geo = preload("res://game/ocean_geometry.gd")
const Nature = preload("res://game/ocean_nature.gd")
const Collision = preload("res://game/level_collision.gd")
const STEP := 4
const Growth = preload("res://game/headland_growth.gd")


func _ready() -> void:
	name = "CoastalSeabed"
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for x in range(-240, 281, STEP):
		for z in range(-340, 121, STEP):
			if Vector2((x + 2 - 40) / 32.0, (z + 2 + 132) / 32.0).length() < 1:
				continue
			var a := vertex(x, z)
			var b := vertex(x + STEP, z)
			var c := vertex(x + STEP, z + STEP)
			var d := vertex(x, z + STEP)
			for point in [a, b, c, a, c, d]:
				st.set_uv(Vector2(point.x, point.z) * .06)
				st.add_vertex(point)
	st.generate_normals()
	var material := Nature.stone()
	material.set_shader_parameter("caustic_strength", .16)
	material.set_shader_parameter("strata_strength", .25)
	Geo.put(self, st.commit(), material)
	# Fringes grow on the shelf, not in the open descent lane.
	for i in range(28):
		var x := 125.0 + sin(i * 2.4) * 45
		var z := -12.0 - i * 3.7
		var y := height_at(x, z)
		if y > -117:
			Nature.kelp(self, Vector3(x, y, z), 3 + i % 5, 800 + i)
			if i % 3 == 0:
				Geo.put(self, Growth.fragment(Vector3(5, 2, 4), i), material, Vector3(x + 1, y, z))
	Collision.build(self)


static func vertex(x: float, z: float) -> Vector3:
	return Vector3(x, height_at(x, z), z)


static func height_at(x: float, z: float) -> float:
	var shelf := -91 + sin(x * .035) * 7 + sin(z * .046) * 5
	shelf += sin(x * .084 + sin(z * .04)) * cos(z * .071) * 3
	var angle := atan2(z + 64, x - 2)
	var basin := (
		Vector2((x - 2) / (105 + sin(angle * 3) * 9), (z + 64) / (77 + sin(angle * 5) * 6)).length()
	)
	var canyon := Vector2((x - 99) / 102, (z + 202) / 160).length()
	var cut := maxf(1 - smoothstep(.60, 1.15, basin), 1 - smoothstep(.55, 1.1, canyon))
	# An erosion finger cuts the rim; they are optional entrances, not a lid.
	var finger := Geometry2D.get_closest_point_to_segment(
		Vector2(x, z), Vector2(66, -46), Vector2(126, -9)
	)
	var gully := 1 - smoothstep(4, 15, Vector2(x, z).distance_to(finger))
	shelf -= gully * 19
	# The basin continues through a narrower incision to the 450m route.
	var deep_axis := Geometry2D.get_closest_point_to_segment(
		Vector2(x, z), Vector2(-8, -100), Vector2(8, -165)
	)
	cut = maxf(cut, 1 - smoothstep(21, 45, Vector2(x, z).distance_to(deep_axis)))
	# The relocated P2 cavern opens onto a rock basin, not into the old shelf.
	var cavern_bay := Vector2((x - 150) / 52, (z + 100) / 32).length()
	cut = maxf(cut, (1 - smoothstep(.7, 1.4, cavern_bay)) * .6)
	var arch_bay := Vector2((x + 85) / 42, (z + 45) / 35).length()
	cut = maxf(cut, (1 - smoothstep(.65, 1.3, arch_bay)) * .55)
	var coast := maxf(absf(x - 20) / 230, absf(z + 110) / 210)
	return lerpf(shelf - cut * 435, -535, smoothstep(.87, 1.07, coast))
