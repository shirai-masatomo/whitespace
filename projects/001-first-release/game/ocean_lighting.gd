extends Node3D
const Geo = preload("res://game/ocean_geometry.gd")
var environment: Environment
var sun: DirectionalLight3D
var forward: bool
var beams: Array[SpotLight3D] = []


func _ready() -> void:
	forward = (
		RenderingServer.get_current_rendering_method() == "forward_plus"
		and DisplayServer.get_name() != "headless"
	)
	environment = Environment.new()
	environment.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	var material := ProceduralSkyMaterial.new()
	material.sky_top_color = Color("387ab4")
	material.sky_horizon_color = Color("d2dfdf")
	material.ground_bottom_color = Color("132c3a")
	material.ground_horizon_color = Color("9dced4")
	material.sun_angle_max = 3.0
	sky.sky_material = material
	environment.sky = sky
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	environment.fog_enabled = true
	if forward:
		environment.volumetric_fog_enabled = true
		environment.volumetric_fog_length = 160.0
		environment.volumetric_fog_detail_spread = 1.5
		environment.volumetric_fog_anisotropy = 0.55
		environment.volumetric_fog_temporal_reprojection_amount = 0.80
		environment.glow_enabled = true
		environment.glow_intensity = 0.5
		environment.ssao_enabled = true
		environment.ssao_radius = 1.4
		environment.ssao_intensity = 0.8
		environment.ssil_enabled = false
	var node := WorldEnvironment.new()
	node.environment = environment
	add_child(node)
	sun = DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-18, 165, 0)
	sun.light_color = Color("fff0d3")
	sun.light_energy = 2.0
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 160
	sun.light_angular_distance = 0.6
	add_child(sun)
	# Surface openings light the water column, with shadows in Forward+ fog.
	if forward:
		for index in range(5):
			var beam := SpotLight3D.new()
			beam.position = Vector3(-30 + index * 18, 5, -35 - index * 11)
			beam.rotation_degrees = Vector3(-68, 15, 0)
			beam.spot_range = 200
			beam.spot_angle = 5 + index
			beam.spot_attenuation = 0.5
			beam.light_color = Color("b4edf1")
			beam.light_energy = 9
			beam.light_volumetric_fog_energy = 35
			beam.shadow_enabled = true
			add_child(beam)
			beams.append(beam)


func update(camera_y: float) -> void:
	var immersion := 1.0 - smoothstep(-1.4, 0.8, camera_y)
	var depth := maxf(0, -camera_y)
	var middle := smoothstep(25, 170, depth)
	var deep := smoothstep(160, 300, depth)
	var tint := Color("184957").lerp(Color("102e48"), middle).lerp(Color("051622"), deep)
	environment.fog_light_color = Color("c1dce7").lerp(tint, immersion)
	environment.fog_density = lerpf(0.00018, lerpf(0.003, 0.008, deep), immersion)
	environment.fog_sky_affect = immersion
	environment.background_mode = Environment.BG_COLOR if camera_y < -1.4 else Environment.BG_SKY
	environment.background_color = tint
	environment.ambient_light_color = Color("c2d8e5").lerp(Color("45859c"), immersion)
	environment.ambient_light_energy = lerpf(0.55, 0.26, immersion)
	environment.ambient_light_sky_contribution = 1.0 - immersion * 0.8
	sun.light_energy = lerpf(2.3, lerpf(1.5, 0.25, deep), immersion)
	sun.light_color = Color("fff0d3").lerp(Color("6abedb"), middle * immersion)
	if forward:
		environment.volumetric_fog_density = immersion * 0.0025
		environment.volumetric_fog_albedo = Color("9bdce0").lerp(Color("477f99"), deep)
		environment.volumetric_fog_emission = tint
		environment.volumetric_fog_emission_energy = immersion * 0.08
		environment.volumetric_fog_sky_affect = immersion
		for beam in beams:
			beam.light_energy = 9 * immersion * (1 - deep)
