extends Node3D
## Original procedural animal; all eight arms move with their collision surfaces.
const Geo = preload("res://game/ocean_geometry.gd")
const Collision = preload("res://game/level_collision.gd")
const Layout = preload("res://game/biology_layout.gd")
var arms: Array[Node3D] = []
var reveal: OmniLight3D


func _ready() -> void:
	name = "GiantOctopus"
	position = Layout.OCTOPUS
	var skin := Geo.material(Color("71606b"), .48)
	var body := Node3D.new()
	add_child(body)
	var mantle := Geo.sphere(body, 15, skin, Vector3(0, 10, 0))
	mantle.scale = Vector3(.85, 1.45, 1)
	Geo.sphere(body, 11, skin, Vector3(0, -6, 1))
	var eye := Geo.material(Color("191b1c"), .2)
	var iris := Geo.material(Color("a78e4d"), .3)
	iris.emission_enabled = true
	iris.emission = Color(.08, .06, .015)
	for side in [-1, 1]:
		Geo.sphere(body, 1.2, iris, Vector3(side * 8, -2, 8.5))
		var slit := Geo.sphere(body, .85, eye, Vector3(side * 8, -2, 9.5))
		slit.scale = Vector3(1, .22, .3)
	Collision.build(body)
	var sucker := Geo.material(Color("88747d"), .64)
	for index in range(8):
		var arm := Node3D.new()
		arm.position.y = -10
		add_child(arm)
		arms.append(arm)
		var st := SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		for row in range(32):
			for side in range(12):
				for pair in [
					Vector2i(row, side),
					Vector2i(row + 1, side),
					Vector2i(row + 1, side + 1),
					Vector2i(row, side),
					Vector2i(row + 1, side + 1),
					Vector2i(row, side + 1)
				]:
					var t: float = pair.x / 32.0
					var center := arm_center(t, index)
					var tangent := (
						(arm_center(minf(1, t + .01), index) - arm_center(maxf(0, t - .01), index))
						. normalized()
					)
					var right := tangent.cross(Vector3.UP).normalized()
					var up := right.cross(tangent).normalized()
					var angle: float = pair.y * TAU / 12
					st.add_vertex(
						center + (right * cos(angle) + up * sin(angle)) * lerpf(3.5, .18, t)
					)
		st.generate_normals()
		Geo.put(arm, st.commit(), skin)
		for row in range(4, 27, 2):
			var t := row / 32.0
			Geo.sphere(
				arm,
				.75 * (1 - t) + .15,
				sucker,
				arm_center(t, index) + Vector3.UP * lerpf(3.3, .2, t)
			)
		Collision.build(arm)
	reveal = OmniLight3D.new()
	reveal.position = Vector3(-26, 18, 22)
	reveal.light_color = Color("739bc2")
	reveal.omni_range = 90
	reveal.light_energy = 0
	add_child(reveal)


static func arm_center(t: float, index: int) -> Vector3:
	var angle := index * TAU / 8 + .2
	var length := 48 + index % 3 * 7
	return Vector3(
		cos(angle) * (8 + t * length),
		-t * 20 + sin(t * PI * 1.7 + index) * 8,
		sin(angle) * (8 + t * length) + sin(t * PI * 2) * 7
	)


func update(time: float, depth: float) -> void:
	for index in range(arms.size()):
		arms[index].rotation.y = sin(time * .17 + index) * .065
		arms[index].rotation.z = sin(time * .13 + index) * .025
		arms[index].get_node("SolidGeometry").force_update_transform()
	reveal.light_energy = smoothstep(606, 642, depth) * 7.5
