extends Node3D
## Real layer: one coastline, natural route and renderer-aware light/atmosphere.
const Geo = preload("res://game/ocean_geometry.gd")
const Nature = preload("res://game/ocean_nature.gd")
const Lighting = preload("res://game/ocean_lighting.gd")
const Effects = preload("res://game/ocean_effects.gd")
const Diver = preload("res://game/diver.gd")
const Life = preload("res://game/marine_life.gd")
const Layout = preload("res://game/stage_layout.gd")
const Collision = preload("res://game/level_collision.gd")
const Discoveries = preload("res://game/discovery_world.gd")
const Playground = preload("res://game/playground_world.gd")
const Canyon = preload("res://game/canyon_world.gd")
const Biology = preload("res://game/biology_world.gd")
const Seabed = preload("res://game/coastal_seabed.gd")
var authored: Node3D
var biology: Node3D
var lighting: Node3D
var effects: Node3D
var environment: Environment
var platforms: Array[Node3D] = []
var life: Node3D
var discoveries: Node3D
var reef: Node3D


func _ready() -> void:
	lighting = Lighting.new()
	add_child(lighting)
	environment = lighting.environment
	effects = Effects.new()
	add_child(effects)
	if authored == null:
		authored = load("res://game/levels/l1_editable.tscn").instantiate()
		add_child(authored)
	platforms.assign(authored.get_node("RocksAndOxygen").get_children())
	for index in range(platforms.size()):
		if platforms[index].has_node("SolidGeometry"):
			platforms[index].get_node("SolidGeometry").set_meta("platform", index)
	for index in range(platforms.size()):
		var data: Dictionary = platforms[index].get_meta("gameplay")
		if data.oxygen and data.kind != "water_globe":
			effects.vent(oxygen_position(index) - Vector3.UP * 1.2)
	_make_ocean()
	var landscape := Node3D.new()
	landscape.name = "ReefLandscape"
	add_child(landscape)
	Nature.landscape(landscape)
	Collision.build(landscape)
	life = Life.new()
	life.authored_animals = true
	add_child(life)
	life.rays.assign(authored.get_node("Animals").get_children())
	life.reef_frame = authored.get_node("ReefExploration").global_transform
	discoveries = Discoveries.new()
	add_child(discoveries)
	reef = Playground.new()
	# Placement is an editable scene anchor; rules evaluate in this local frame.
	reef.transform = authored.get_node("ReefExploration").global_transform
	add_child(reef)
	add_child(Canyon.new())
	add_child(Seabed.new())
	biology = Biology.new()
	biology.authored_coast = true
	add_child(biology)
	life.make_shoal(reef.to_global(Vector3(84, -53, -63)), 24)
	life.make_shoal(Vector3(-9, -52, -29), 36, Life.Role.PASSAGE)
	life.make_shoal(Vector3(40, -130, -70), 42, Life.Role.PASSAGE)
	life.make_shoal(Vector3(42, -157, -106), 32, Life.Role.FLOW)
	for point in Layout.SHALLOW_RIDE:
		effects.current(point, Vector3(3, -.8, -1))
	for i in range(Biology.Layout.APPROACH.size() - 1):
		var start: Vector3 = Biology.Layout.APPROACH[i]
		effects.current(start, (Biology.Layout.APPROACH[i + 1] - start).normalized() * 2.4)
	for plant in authored.gardens():
		effects.vent(plant)
		life.make_shoal(plant + Vector3.UP * 4, 28, Life.Role.ALGAE)
	for zone in Layout.current_zones():
		effects.current(zone.center, zone.flow)


func oxygen_position(index: int) -> Vector3:
	var rock: Node3D = platforms[index]
	var algae: Node3D = rock.get_node_or_null("OxygenAlgae")
	return (algae if algae != null else rock).global_transform * (Vector3.UP * 1.6)


func _make_ocean() -> void:
	var surface := PlaneMesh.new()
	surface.size = Vector2(3000, 3000)
	surface.subdivide_width = 192
	surface.subdivide_depth = 192
	var water := ShaderMaterial.new()
	water.shader = preload("res://game/shaders/water.gdshader")
	var sea := Geo.put(self, surface, water)
	sea.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
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
		platforms[index].global_position = data[index].position
		if platforms[index].has_node("SolidGeometry"):
			platforms[index].get_node("SolidGeometry").force_update_transform()


func update_depth(camera_y: float, cave_air: bool = false) -> void:
	lighting.update(camera_y, cave_air)


func update_life(model) -> void:
	authored.update_animals(model.elapsed)
	biology.update(model)
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
