extends Node3D
## Three small hypotheses: refuge, readable current, and a distant unknown animal.
const Rules = preload("res://game/discovery_rules.gd")
const Geo = preload("res://game/ocean_geometry.gd")
const Collision = preload("res://game/level_collision.gd")
const Life = preload("res://game/marine_life.gd")
var bubbles: Array[MeshInstance3D] = []
var stream_motes: Array[MeshInstance3D] = []
var giant: Node3D


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
	var glow := Geo.material(Color("a0e6cc"))
	glow.emission_enabled = true
	glow.emission = Color("67c4b3")
	glow.emission_energy_multiplier = .6
	for index in range(90):
		var mote := Geo.sphere(self, .09 + (index % 3) * .05, glow, Vector3.ZERO)
		mote.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		stream_motes.append(mote)
	var maker := Life.new()
	giant = maker.make_ray()
	maker.free()
	giant.name = "DistantGiant"
	giant.scale = Vector3.ONE * 6.0
	add_child(giant)
	update(0)


func _make_arch() -> void:
	var arch := Node3D.new()
	arch.name = "SwimThroughArch"
	arch.position = Rules.ARCH
	add_child(arch)
	var ring := TorusMesh.new()
	ring.inner_radius = 12
	ring.outer_radius = 18
	ring.rings = 48
	ring.ring_segments = 12
	var stone := ShaderMaterial.new()
	stone.shader = preload("res://game/shaders/stone.gdshader")
	var body := Geo.put(arch, ring, stone)
	body.rotation.x = PI / 2
	body.scale = Vector3(1, 1, 1.25)
	# Broken outer masses keep the hole readable without resembling a UI hoop.
	for side in [-1, 1]:
		Geo.put(arch, Geo.boulder(Vector3(12, 32, 14), 172 + side), stone, Vector3(side * 17, 0, 0))
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
	giant.position = Rules.giant_position(time)
	giant.rotation.y = PI / 2 if cos(time * .06) > 0 else -PI / 2
