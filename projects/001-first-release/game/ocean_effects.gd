extends Node3D
## Separate GPU systems for breath, wake, fast descent, ascent, rescue and vents.
const Geo = preload("res://game/ocean_geometry.gd")
var motes: GPUParticles3D
var breath: GPUParticles3D
var wake: GPUParticles3D
var fast: GPUParticles3D
var ascent: GPUParticles3D
var rescue: GPUParticles3D
var splash: GPUParticles3D
var entry_cloud: GPUParticles3D
var cavern_jet: GPUParticles3D
var previous_y: float = 6


func _ready() -> void:
	motes = particles(500, 14, 0.035, 0.075, Vector3(1.0, .1, .2), Vector3(32, 24, 32), false)
	breath = particles(35, 3, 0.035, 0.11, Vector3(0, 1, 0), Vector3(.08, .08, .08), true)
	wake = particles(70, 2, 0.025, 0.07, Vector3(0, 1, 0), Vector3(.5, .8, .3), true)
	fast = particles(150, 1.7, 0.025, 0.11, Vector3(0, 7, 0), Vector3(.45, .3, .45), true)
	ascent = particles(60, 2.2, 0.06, 0.16, Vector3(0, -2, 0), Vector3(.5, .3, .4), true)
	rescue = particles(140, 2.4, 0.1, 0.32, Vector3(0, -5, 0), Vector3(1.0, 1.2, 1.0), true)
	splash = particles(80, 1.5, .06, .20, Vector3(0, 4, 0), Vector3(1.2, .1, 1.2), true)
	splash.one_shot = true
	splash.explosiveness = .95
	entry_cloud = particles(280, 2.1, .012, .045, Vector3(0, 3.4, 0), Vector3(1.8, 1, 1.8), true)
	entry_cloud.one_shot = true
	entry_cloud.explosiveness = .75
	cavern_jet = particles(260, 4, .065, .22, Vector3.UP * 7, Vector3(3, 16, 3), true)
	cavern_jet.position = preload("res://game/playground_rules.gd").UPDRAFT
	for emitter in [breath, wake, fast, ascent, rescue, splash, entry_cloud]:
		emitter.emitting = false


func particles(
	count: int,
	life: float,
	minimum: float,
	maximum: float,
	drift: Vector3,
	bounds: Vector3,
	bubbles: bool
) -> GPUParticles3D:
	var emitter := GPUParticles3D.new()
	emitter.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	emitter.amount = count
	emitter.lifetime = life
	emitter.preprocess = minf(3, life)
	emitter.visibility_aabb = AABB(Vector3(-80, -80, -80), Vector3(160, 160, 160))
	var process := ParticleProcessMaterial.new()
	process.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	process.emission_box_extents = bounds
	process.direction = drift.normalized()
	process.spread = 12.0 if bubbles else 4.0
	process.initial_velocity_min = drift.length() * .7
	process.initial_velocity_max = drift.length() * 1.3
	process.gravity = Vector3(0, .45, 0) if bubbles else Vector3.ZERO
	process.scale_min = minimum
	process.scale_max = maximum
	emitter.process_material = process
	var quad := QuadMesh.new()
	quad.size = Vector2.ONE * 2
	if bubbles:
		var mat := ShaderMaterial.new()
		mat.shader = preload("res://game/shaders/bubble.gdshader")
		quad.material = mat
	else:
		var mat := ShaderMaterial.new()
		mat.shader = preload("res://game/shaders/mote.gdshader")
		quad.material = mat
	emitter.draw_pass_1 = quad
	add_child(emitter)
	return emitter


func vent(point: Vector3) -> void:
	var emitter := particles(50, 5, .08, .25, Vector3(0, 1.4, 0), Vector3(1.4, .1, 1.4), true)
	emitter.position = point


func current(point: Vector3, direction: Vector3) -> void:
	var emitter := particles(120, 9, .025, .06, direction * 1.8, Vector3(16, 7, 12), false)
	emitter.position = point


func update(model) -> void:
	cavern_jet.emitting = model.config.cavern_current_enabled
	cavern_jet.visible = model.config.cavern_current_enabled
	cavern_jet.speed_scale = model.Playground.updraft_pulse(model.elapsed)
	var position_above: Vector3 = model.position + Vector3.UP * 1.3
	motes.position = model.position
	motes.emitting = model.position.y < 0 and not model.in_dry_cave()
	breath.position = position_above + Vector3(0, .25, -.28)
	wake.position = model.position
	fast.position = model.position + Vector3.UP * .5
	ascent.position = model.position
	rescue.position = position_above
	var underwater: bool = model.position.y < -1 and not model.in_dry_cave()
	var returning: bool = model.mode == model.Mode.RETURNING
	breath.emitting = underwater and not returning
	wake.emitting = (
		underwater and not returning and Vector2(model.velocity.x, model.velocity.z).length() > 1
	)
	fast.emitting = underwater and not returning and model.velocity.y < -8
	ascent.emitting = underwater and not returning and model.velocity.y > 1
	rescue.emitting = returning
	if (
		(previous_y > -.5 and model.position.y <= -.5)
		or (previous_y < -.5 and model.position.y >= -.5)
	):
		splash.position = Vector3(model.position.x, 0, model.position.z)
		splash.restart()
		splash.emitting = true
		if model.position.y < -.5:
			entry_cloud.position = Vector3(model.position.x, -1.6, model.position.z)
			entry_cloud.restart()
			entry_cloud.emitting = true
	previous_y = model.position.y
