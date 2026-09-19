extends Node3D
## Three small hypotheses: refuge, readable current, and a distant unknown animal.
const Rules = preload("res://game/discovery_rules.gd")
const Geo = preload("res://game/ocean_geometry.gd")
const Collision = preload("res://game/level_collision.gd")
const Animal = preload("res://game/great_swimmer.gd")
var bubbles: Array[MeshInstance3D] = []
var stream_motes: Array[MeshInstance3D] = []
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
		surface_bubbles.append(Geo.put(self, quad, glow))
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
	# Rejected the smooth torus: a rock opening must not read as a target hoop.
	for index in range(9):
		var theta := index * PI / 8
		var point := Vector3(cos(theta) * 18, sin(theta) * 20 + 10, sin(index * 2.1) * 1.5)
		var mass := Geo.put(arch, Geo.boulder(Vector3(13, 22, 18), 172 + index), stone, point)
		mass.rotation.z = cos(theta) * .15
	Collision.build(arch)


func update(time: float) -> void:
	var data := Rules.bubbles(time)
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
