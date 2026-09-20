extends Node3D
## Three small hypotheses: refuge, readable current, and a distant unknown animal.
const Rules = preload("res://game/discovery_rules.gd")
const Geo = preload("res://game/ocean_geometry.gd")
const Collision = preload("res://game/level_collision.gd")
const Animal = preload("res://game/great_swimmer.gd")
var bubbles: Array[MeshInstance3D] = []
var stream_motes: Array[MeshInstance3D] = []
var cove_motes: Array[MeshInstance3D] = []
var giant: Node3D
var surface_bubbles: Array[MeshInstance3D] = []


func _ready() -> void:
	name = "Discoveries"
	for data in Rules.bubbles(0):
		var mat := ShaderMaterial.new()
		mat.shader = preload("res://game/shaders/air_pocket.gdshader")
		var bubble := Geo.sphere(self, data.radius, mat, data.center)
		bubble.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		bubbles.append(bubble)
		var light := OmniLight3D.new()
		light.light_color = Color("95e6df")
		light.light_energy = .8
		light.omni_range = data.radius * 2
		bubble.add_child(light)
	_make_arch()
	var glow := ShaderMaterial.new()
	glow.shader = preload("res://game/shaders/bubble.gdshader")
	for index in range(90):
		var quad := QuadMesh.new()
		quad.size = Vector2.ONE * (.16 + (index % 3) * .08)
		var mote := Geo.put(self, quad, glow)
		mote.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		stream_motes.append(mote)
	for index in range(24):
		var quad := QuadMesh.new()
		quad.size = Vector2.ONE * (.3 + index % 4 * .12)
		var bubble_mote := Geo.put(self, quad, glow)
		bubble_mote.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		surface_bubbles.append(bubble_mote)
	var streak := ShaderMaterial.new()
	streak.shader = preload("res://game/shaders/flow_mote.gdshader")
	for index in range(100):
		var quad := QuadMesh.new()
		quad.size = Vector2(.16, 2.0)
		var mote := Geo.put(self, quad, streak)
		mote.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		cove_motes.append(mote)
	giant = Animal.new()
	giant.name = "DistantGiant"
	add_child(giant)
	update(0)


func _make_arch() -> void:
	var arch := Node3D.new()
	arch.name = "SwimThroughArch"
	arch.position = Rules.ARCH
	add_child(arch)
	var stone := ShaderMaterial.new()
	stone.shader = preload("res://game/shaders/stone.gdshader")
	# One eroded span with unequal buttresses, not a row of boulders in a hoop.
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for step in range(40):
		for ring in range(24):
			var a := _arch_point(step * PI / 40, ring * TAU / 24)
			var b := _arch_point((step + 1) * PI / 40, ring * TAU / 24)
			var c := _arch_point((step + 1) * PI / 40, (ring + 1) * TAU / 24)
			var d := _arch_point(step * PI / 40, (ring + 1) * TAU / 24)
			for point in [a, d, c, a, c, b]:
				st.add_vertex(point)
	st.generate_normals()
	Geo.put(arch, st.commit(), stone)
	for side in [-1, 1]:
		var profile: Array[Vector3] = [
			Vector3(11, 6, 8),
			Vector3(0, 7, 9),
			Vector3(-16, 10, 11),
			Vector3(-35, 13, 12),
			Vector3(-57, 17, 15),
			Vector3(-69, 0, 0)
		]
		Geo.put(arch, Geo.loft(profile, 28, 290 + side), stone, Vector3(side * 18, 0, 0))
	Collision.build(arch)


func _arch_point(theta: float, ring: float) -> Vector3:
	var center := Vector3(cos(theta) * 18, sin(theta) * 25 + 9, sin(theta * 2.1) * 2)
	var radius := 5.5 + sin(theta * 3.4 + .7) * 1.3
	var erosion := 1 + sin(ring * 5 + theta * 7) * .08 + sin(ring * 3 - theta * 4) * .1
	return (
		center
		+ Vector3(
			cos(theta) * cos(ring) * radius * erosion,
			sin(theta) * cos(ring) * radius * erosion,
			sin(ring) * (8 + sin(theta * 4) * 2) * erosion
		)
	)


func set_enabled(value: bool) -> void:
	if visible == value:
		return
	visible = value
	$SwimThroughArch/SolidGeometry.collision_layer = 3 if value else 0


func update(time: float, cove_speed: float = 0) -> void:
	var data := Rules.bubbles(time)
	var length := 0.0
	for index in range(Rules.COVE_STREAM.size() - 1):
		length += Rules.COVE_STREAM[index].distance_to(Rules.COVE_STREAM[index + 1])
	for index in range(cove_motes.size()):
		cove_motes[index].visible = cove_speed > 0
		var distance := fposmod(index * length / cove_motes.size() + time * cove_speed, length)
		var section := 0
		while section < Rules.COVE_STREAM.size() - 2:
			var span := Rules.COVE_STREAM[section].distance_to(Rules.COVE_STREAM[section + 1])
			if distance < span:
				break
			distance -= span
			section += 1
		var flow := Rules.COVE_STREAM[section + 1] - Rules.COVE_STREAM[section]
		var point := Rules.COVE_STREAM[section] + flow.normalized() * distance
		point += Vector3(sin(index * 2.399), cos(index * 1.7), sin(index)) * 2.4
		cove_motes[index].position = point
		var across := Vector3.UP.cross(flow.normalized()).normalized()
		cove_motes[index].basis = Basis(across, flow.normalized(), across.cross(flow.normalized()))
	for index in range(bubbles.size()):
		bubbles[index].position = data[index].center
	for index in range(stream_motes.size()):
		var progress := fposmod(index / 30.0 + time * .22, 3.0)
		var section := int(progress)
		var point := Rules.STREAM[section].lerp(Rules.STREAM[section + 1], fmod(progress, 1.0))
		var angle := index * 2.399
		point += Vector3(cos(angle), sin(angle), cos(angle * .7)) * (1 + index % 4)
		stream_motes[index].position = point
	for index in range(surface_bubbles.size()):
		var rise := fposmod(index * 1.2 + time * 2, 28)
		surface_bubbles[index].position = (
			data[0].center + Vector3(sin(index) * 2, rise, cos(index) * 2)
		)
	giant.position = Rules.giant_position(time)
	giant.rotation.y = atan2(-cos(time * .025) * 20, sin(time * .025) * 8)
	giant.swim(time)
