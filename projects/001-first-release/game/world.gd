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
const Collision = preload("res://game/level_collision.gd")
const Discoveries = preload("res://game/discovery_world.gd")
const Playground = preload("res://game/playground_world.gd")
const Canyon = preload("res://game/canyon_world.gd")
const Seabed = preload("res://game/coastal_seabed.gd")
const Headland = preload("res://game/shallow_headland.gd")
var lighting: Node3D
var effects: Node3D
var environment: Environment
var platforms: Array[Node3D] = []
var life: Node3D
var discoveries: Node3D


func _ready() -> void:
	lighting = Lighting.new()
	add_child(lighting)
	environment = lighting.environment
	effects = Effects.new()
	add_child(effects)
	_make_platforms()
	_make_ocean()
	var landscape := Node3D.new()
	landscape.name = "ReefLandscape"
	add_child(landscape)
	Nature.landscape(landscape)
	Collision.build(landscape)
	life = Life.new()
	add_child(life)
	discoveries = Discoveries.new()
	add_child(discoveries)
	add_child(Playground.new())
	add_child(Canyon.new())
	add_child(Headland.new())
	add_child(Seabed.new())
	life.make_shoal(Vector3(84, -53, -63), 24)
	for plant in Playground.Rules.PLANTS:
		effects.vent(plant)
		life.make_shoal(plant + Vector3.UP * 4, 28, Life.Role.ALGAE)
	for zone in Layout.current_zones():
		effects.current(zone.center, zone.flow)


func _make_platforms() -> void:
	for index in range(Layout.platforms().size()):
		var data: Dictionary = Layout.platforms()[index]
		var root := Node3D.new()
		root.position = data.position
		add_child(root)
		platforms.append(root)
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
		Collision.build(root, index)


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
	Geo.put(self, seabed, sand, Vector3(0, -520, 0))
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
		platforms[index].get_node("SolidGeometry").force_update_transform()


func update_depth(camera_y: float, cave_air: bool = false) -> void:
	lighting.update(camera_y, cave_air)


func update_life(model) -> void:
	effects.update(model)
	discoveries.set_enabled(model.config.discovery_enabled)
	discoveries.update(model.elapsed, model.config.cove_stream_speed)
	life.update(
		model.position,
		model.elapsed,
		discoveries.giant.position if discoveries.visible else Vector3.INF
	)


func make_avatar() -> Node3D:
	var diver := Diver.new()
	add_child(diver)
	return diver


func make_bubble() -> MeshInstance3D:
	var bubble := ShaderMaterial.new()
	bubble.shader = preload("res://game/shaders/rescue.gdshader")
	return Geo.sphere(self, 1.25, bubble, Vector3.ZERO)
