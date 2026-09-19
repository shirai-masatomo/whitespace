extends Node3D
## Real layer: one coastline, natural route and renderer-aware light/atmosphere.
const Geo = preload("res://game/ocean_geometry.gd")
const Nature = preload("res://game/ocean_nature.gd")
const Lighting = preload("res://game/ocean_lighting.gd")
const Effects = preload("res://game/ocean_effects.gd")
const Diver = preload("res://game/diver.gd")
const Life = preload("res://game/marine_life.gd")
const Layout = preload("res://game/stage_layout.gd")
const TUNING = preload("res://game/default_config.tres")
var lighting: Node3D
var effects: Node3D
var environment: Environment
var platforms: Array[Node3D] = []


func _ready() -> void:
	lighting = Lighting.new()
	add_child(lighting)
	environment = lighting.environment
	effects = Effects.new()
	add_child(effects)
	_make_platforms()
	_make_ocean()
	Nature.landscape(self)
	add_child(Life.new())
	for zone in Layout.current_zones():
		effects.current(zone.center, zone.flow)


func _make_platforms() -> void:
	for index in range(Layout.platforms().size()):
		var data: Dictionary = Layout.platforms()[index]
		var root := Node3D.new()
		root.position = data.position
		add_child(root)
		platforms.append(root)
		if data.kind != "driftwood":
			var body := StaticBody3D.new()
			body.position.y = -1
			var shape := CollisionShape3D.new()
			var box := BoxShape3D.new()
			box.size = Vector3(data.size.x, 2, data.size.y)
			shape.shape = box
			body.add_child(shape)
			root.add_child(body)
		Nature.deck(root, data, index)
		if data.oxygen:
			Nature.oxygen_algae(root, index)
			effects.vent(data.position + Vector3.UP * .4)
			var light := OmniLight3D.new()
			light.position.y = 1.5
			light.light_color = Color("81e8ca")
			light.light_energy = 1.2
			light.omni_range = 8
			root.add_child(light)
		if data.goal:
			var lamp := Geo.material(Color("daa95b"), .25, .6)
			lamp.emission_enabled = true
			lamp.emission = Color("edb55a")
			for i in range(5):
				Geo.put(
					root,
					Geo.loft([Vector3(0, .25, .25), Vector3(2 + i % 2, .18, .18)], 12),
					lamp,
					Vector3(-4 + i * 2, 0, -3)
				)


func _make_ocean() -> void:
	var surface := PlaneMesh.new()
	surface.size = Vector2(3000, 3000)
	surface.subdivide_width = 192
	surface.subdivide_depth = 192
	var water := ShaderMaterial.new()
	water.shader = preload("res://game/shaders/water.gdshader")
	var sea := Geo.put(self, surface, water)
	sea.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var seabed := PlaneMesh.new()
	seabed.size = Vector2(2500, 2500)
	seabed.subdivide_width = 160
	seabed.subdivide_depth = 160
	var sand := ShaderMaterial.new()
	sand.shader = preload("res://game/shaders/seabed.gdshader")
	Geo.put(self, seabed, sand, Vector3(0, -370, 0))
	# Soft light ribbons support the volumetric light; also provide the GL fallback.
	if true:
		for i in range(7):
			var shaft := CylinderMesh.new()
			shaft.top_radius = .5
			shaft.bottom_radius = 8
			shaft.height = 90
			var mat := ShaderMaterial.new()
			mat.shader = preload("res://game/shaders/sunshaft.gdshader")
			mat.set_shader_parameter("tint", Color(.55, .85, 1, .018 if lighting.forward else .025))
			var instance := Geo.put(self, shaft, mat, Vector3(-30 + i * 15, -43, -40 - i * 8))
			instance.rotation.z = -.25


func sync_platforms(data: Array[Dictionary]) -> void:
	for index in range(platforms.size()):
		platforms[index].position = data[index].position


func update_depth(camera_y: float) -> void:
	lighting.update(camera_y)


func update_life(model) -> void:
	effects.update(model)


func make_avatar() -> Node3D:
	var diver := Diver.new()
	add_child(diver)
	return diver


func make_bubble() -> MeshInstance3D:
	var bubble := ShaderMaterial.new()
	bubble.shader = preload("res://game/shaders/rescue.gdshader")
	return Geo.sphere(self, 1.25, bubble, Vector3.ZERO)
