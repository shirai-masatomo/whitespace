extends Node3D
## A connected headland and eroded roof, not a chain of individual stepping stones.
const Geo = preload("res://game/ocean_geometry.gd")
const Nature = preload("res://game/ocean_nature.gd")
const Collision = preload("res://game/level_collision.gd")


func _ready() -> void:
	name = "CanyonMassif"
	# Each closed section is authored at landscape scale. The space BETWEEN the
	# roots is the cave; collision is baked from exactly the visible triangles.
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	_sweep(surface, false)
	_sweep(surface, true)
	surface.generate_normals()
	var stone := Nature.stone()
	stone.set_shader_parameter("strata_strength", .7)
	Geo.put(self, surface.commit(), stone)
	Collision.build(self)


static func _sweep(surface: SurfaceTool, roof: bool) -> void:
	var count := 72
	for row in range(count):
		var a := _section(row / float(count), roof)
		var b := _section((row + 1) / float(count), roof)
		for edge in range(a.size()):
			var next := (edge + 1) % a.size()
			_triangle(surface, a[edge], b[next], b[edge])
			_triangle(surface, a[edge], a[next], b[next])
		if row in [0, count - 1]:
			var ring := a if row == 0 else b
			var center := Vector3.ZERO
			for point in ring:
				center += point / ring.size()
			for edge in range(ring.size()):
				var next := (edge + 1) % ring.size()
				if row == 0:
					_triangle(surface, center, ring[edge], ring[next])
				else:
					_triangle(surface, center, ring[next], ring[edge])


static func _section(t: float, roof: bool) -> Array[Vector3]:
	# Non-elliptical, stepped cross sections leave broad standing surfaces,
	# recesses and thick broken lips. Erosion is subordinate to these big forms.
	var profile: Array[Vector2] = [
		Vector2(-.86, .08),
		Vector2(-.72, .75),
		Vector2(-.42, 1),
		Vector2(.12, .94),
		Vector2(.42, .80),
		Vector2(.51, .53),
		Vector2(.86, .44),
		Vector2(1, .07),
		Vector2(.69, -.53),
		Vector2(.13, -.85),
		Vector2(-.46, -.76),
		Vector2(-1, -.22)
	]
	var result: Array[Vector3] = []
	for edge in range(profile.size()):
		for division in range(4):
			var p := profile[edge].lerp(profile[(edge + 1) % profile.size()], division / 4.0)
			var point: Vector3
			if roof:
				var arch := pow(sin(t * PI), .85)
				var center := _roof_spine(t)
				var breadth := 20 + sin(t * 5.3 + .7) * 5
				var thickness := 12 + pow(1 - arch, 2) * 25
				point = center + Vector3(0, p.y * thickness, p.x * breadth)
			else:
				var z := lerpf(-124, -208, t)
				var crest := sin(t * PI)
				var center := Vector3(27, -193 + crest * 12, z)
				var width := 28 + sin(t * 4.2) * 2
				var height := 29 + pow(crest, .8) * 44
				point = center + Vector3(p.x * width, p.y * height, 0)
			var exposed := sin(t * PI)
			point += (
				Vector3(
					sin(point.z * .17 + point.y * .08) * 1.2,
					sin(point.x * .13 + point.z * .11) * 1.6,
					sin(point.x * .19 + point.y * .09) * 1.4
				)
				* exposed
			)
			result.append(point)
	return result


static func _roof_spine(t: float) -> Vector3:
	# Diagonal broken headland: one shoulder projects above the inner route,
	# another sinks into the far cliff. It is not a symmetrical arch gate.
	var points: Array[Vector3] = [
		Vector3(28, -175, -140),
		Vector3(55, -149, -158),
		Vector3(83, -146, -181),
		Vector3(115, -151, -206),
		Vector3(151, -179, -241),
		Vector3(185, -223, -251)
	]
	var scaled := t * (points.size() - 1)
	var index := mini(int(scaled), points.size() - 2)
	return points[index].lerp(points[index + 1], smoothstep(0, 1, scaled - index))


static func _triangle(surface: SurfaceTool, a: Vector3, b: Vector3, c: Vector3) -> void:
	for point in [a, b, c]:
		surface.set_uv(Vector2(point.x, point.z) * .08)
		surface.add_vertex(point)
