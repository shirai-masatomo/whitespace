extends Node3D
## A cliff-rooted shore around an open sinkhole, replacing the long lower ribbon.
const Geo = preload("res://game/ocean_geometry.gd")
const Nature = preload("res://game/ocean_nature.gd")
const Collision = preload("res://game/level_collision.gd")
const OUTER = [
	Vector3(55, -211, -200),
	Vector3(74, -214, -196),
	Vector3(95, -216, -202),
	Vector3(118, -220, -215),
	Vector3(112, -241, -237),
	Vector3(105, -245, -256),
	Vector3(79, -241, -270),
	Vector3(57, -222, -255),
	Vector3(49, -214, -230)
]
const INNER = [
	Vector3(75, -223, -226),
	Vector3(84, -223, -223),
	Vector3(95, -224, -226),
	Vector3(101, -228, -232),
	Vector3(99, -243, -244),
	Vector3(91, -247, -254),
	Vector3(80, -242, -250),
	Vector3(73, -228, -241),
	Vector3(72, -224, -231)
]
const STEPS = 8
const LANES = 12


func _ready() -> void:
	name = "SunkenCove"
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for section in range(OUTER.size()):
		# A genuine opening onto offshore water, not a compulsory circular path.
		if section == 3:
			continue
		for step in range(STEPS):
			var a := section + step / float(STEPS)
			var b := section + (step + 1) / float(STEPS)
			for lane in range(LANES):
				var u := lane / float(LANES)
				var v := (lane + 1) / float(LANES)
				quad(st, surface(a, u), surface(b, u), surface(b, v), surface(a, v))
				quad(st, base(a, v), base(b, v), base(b, u), base(a, u))
				if (section == 2 and step == STEPS - 1) or (section == 4 and step == 0):
					var end := b if section == 2 else a
					quad(st, surface(end, u), surface(end, v), base(end, v), base(end, u))
			# The inside is an undercut bank with a narrow submerged ledge,
			# not one uniformly extruded tube wall.
			for tier in range(3):
				quad(st, wall(a, tier), wall(a, tier + 1), wall(b, tier + 1), wall(b, tier))
			quad(st, surface(b, 1), base(b, 1), base(a, 1), surface(a, 1))
	st.generate_normals()
	var stone := Nature.stone()
	stone.set_shader_parameter("strata_strength", .65)
	Geo.put(self, st.commit(), stone)
	Collision.build(self)


static func ring(points: Array, along: float) -> Vector3:
	var i := int(floor(along)) % points.size()
	return points[i].cubic_interpolate(
		points[(i + 1) % points.size()],
		points[posmod(i - 1, points.size())],
		points[(i + 2) % points.size()],
		fposmod(along, 1)
	)


static func surface(along: float, across: float) -> Vector3:
	var p := ring(INNER, along).lerp(ring(OUTER, along), across)
	# The existing living refuge stays on solid land. Elsewhere the shore
	# descends towards the open water, so walking changes the view into the hole.
	var refuge := 1 - smoothstep(3, 8, Vector2(p.x - 78, p.z + 222).length())
	p.y = lerpf(p.y, -220.45, refuge)
	return p


static func base(along: float, across: float) -> Vector3:
	var p := surface(along, across)
	p.y -= lerpf(17, 34, across)
	var centre := Vector3(86, p.y, -238)
	p = p.lerp(centre, .12 * across)
	return p


static func wall(along: float, tier: int) -> Vector3:
	if tier == 0:
		return surface(along, 0)
	if tier == 3:
		return base(along, 0)
	var p := surface(along, 0)
	var outward := Vector3(p.x - 86, 0, p.z + 238).normalized()
	p += outward * (4.0 if tier == 1 else 1.0)
	p.y -= 6.0 if tier == 1 else 8.0
	return p


static func quad(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3) -> void:
	for p in [a, b, c, a, c, d]:
		st.set_uv(Vector2(p.x, p.z) * .04)
		st.add_vertex(p)
