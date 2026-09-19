extends Node3D
## Original articulated suit, anatomical lofts and movement-driven pose blending.
const Geo = preload("res://game/ocean_geometry.gd")
var torso: Node3D
var arms: Array[Node3D] = []
var shins: Array[Node3D] = []
var thighs: Array[Node3D] = []
var pose: String = "idle"
var previous_grounded := true
var landing: float = 0.0
var previous_time: float = 0.0


func _ready() -> void:
	var suit := Geo.material(Color("143b4b"), 0.4)
	var orange := Geo.material(Color("df7b3d"), 0.42)
	var rubber := Geo.material(Color("12232a"), 0.65)
	var steel := Geo.material(Color("b4c4c1"), 0.25, 0.7)
	var glass := Geo.material(Color("4cc7d5"), 0.08, 0.65)
	torso = Node3D.new()
	torso.position.y = 1.05
	add_child(torso)
	Geo.put(
		torso,
		Geo.loft(
			[
				Vector3(-0.2, 0.22, 0.15),
				Vector3(0, 0.25, 0.17),
				Vector3(0.25, 0.30, 0.18),
				Vector3(0.5, 0.39, 0.19),
				Vector3(0.62, 0.25, 0.15),
				Vector3(0.65, 0.1, 0.1)
			]
		),
		suit
	)
	Geo.box(torso, Vector3(0.4, 0.28, 0.07), orange, Vector3(0, 0.31, -0.18))
	Geo.box(torso, Vector3(0.54, 0.08, 0.36), rubber, Vector3(0, -0.06, 0))
	Geo.box(torso, Vector3(0.10, 0.09, 0.06), steel, Vector3(0, -0.06, -0.21))
	for side in [-1, 1]:
		Geo.box(torso, Vector3(0.065, 0.63, 0.06), rubber, Vector3(side * 0.24, 0.3, -0.19))
		var tank := Geo.put(
			torso,
			Geo.loft(
				[
					Vector3(-0.18, 0.03, 0.03),
					Vector3(-0.12, 0.12, 0.12),
					Vector3(0.42, 0.12, 0.12),
					Vector3(0.5, 0.07, 0.07),
					Vector3(0.54, 0.03, 0.03)
				],
				16
			),
			steel,
			Vector3(side * 0.13, 0.1, 0.28)
		)
		Geo.box(tank, Vector3(0.25, 0.055, 0.26), rubber, Vector3(0, 0.08, 0))
	var head := Geo.put(
		torso,
		Geo.loft(
			[
				Vector3(0, 0.13, 0.13),
				Vector3(0.1, 0.22, 0.2),
				Vector3(0.32, 0.21, 0.2),
				Vector3(0.43, 0.08, 0.09),
				Vector3(0.45, 0.01, 0.01)
			],
			24
		),
		rubber,
		Vector3(0, 0.6, 0)
	)
	Geo.box(head, Vector3(0.40, 0.18, 0.11), steel, Vector3(0, 0.24, -0.17))
	Geo.box(head, Vector3(0.34, 0.12, 0.05), glass, Vector3(0, 0.24, -0.235))
	Geo.sphere(head, 0.078, steel, Vector3(0, 0.06, -0.23))
	# Curved regulator hose, separate from the helmet silhouette.
	for i in range(14):
		var angle := i * PI / 18
		Geo.sphere(
			torso,
			0.029,
			rubber,
			Vector3(0.25 * sin(angle), 0.69 - 0.36 * sin(angle), -0.22 + 0.22 * (1 - cos(angle)))
		)
	for side in [-1, 1]:
		var shoulder := Node3D.new()
		shoulder.position = Vector3(side * 0.36, 0.48, 0)
		torso.add_child(shoulder)
		arms.append(shoulder)
		Geo.put(
			shoulder,
			Geo.loft(
				[
					Vector3(-0.6, 0.075, 0.075),
					Vector3(-0.32, 0.1, 0.1),
					Vector3(-0.1, 0.14, 0.13),
					Vector3(0.06, 0.08, 0.08)
				]
			),
			suit
		)
		Geo.put(
			shoulder,
			Geo.loft(
				[Vector3(-0.22, 0.115, 0.12), Vector3(-0.08, 0.145, 0.14), Vector3(0.02, 0.1, 0.1)]
			),
			orange
		)
		Geo.put(
			shoulder,
			Geo.loft(
				[Vector3(-0.87, 0.06, 0.05), Vector3(-0.7, 0.10, 0.065), Vector3(-0.59, 0.08, 0.06)]
			),
			rubber
		)
		Geo.box(shoulder, Vector3(0.14, 0.07, 0.04), glass, Vector3(0, -0.53, -0.10))
		var hip := Node3D.new()
		hip.position = Vector3(side * 0.17, -0.15, 0)
		torso.add_child(hip)
		thighs.append(hip)
		Geo.put(
			hip,
			Geo.loft(
				[Vector3(-0.43, 0.10, 0.10), Vector3(-0.22, 0.13, 0.14), Vector3(0, 0.15, 0.16)]
			),
			suit
		)
		var knee := Node3D.new()
		knee.position.y = -0.43
		hip.add_child(knee)
		shins.append(knee)
		Geo.put(
			knee,
			Geo.loft(
				[
					Vector3(-0.42, 0.065, 0.085),
					Vector3(-0.22, 0.10, 0.12),
					Vector3(0.03, 0.105, 0.10)
				]
			),
			suit
		)
		Geo.box(knee, Vector3(0.15, 0.14, 0.045), orange, Vector3(0, -0.03, -0.105))
		var fin := Geo.put(
			knee,
			Geo.loft(
				[
					Vector3(0, 0.06, 0.07),
					Vector3(0.12, 0.12, 0.05),
					Vector3(0.48, 0.2, 0.028),
					Vector3(0.62, 0.15, 0.012)
				]
			),
			orange,
			Vector3(0, -0.42, 0.08)
		)
		fin.rotation.x = -PI / 2


func animate(model) -> void:
	var dt: float = clampf(model.elapsed - previous_time, 0, 0.1)
	previous_time = model.elapsed
	var grounded: bool = model.standing
	var horizontal: float = Vector2(model.velocity.x, model.velocity.z).length()
	if grounded and not previous_grounded:
		landing = 1.0
	previous_grounded = grounded
	landing = move_toward(landing, 0, dt * 3.0)
	pose = "idle" if grounded else "sink"
	if grounded and horizontal > 0.5:
		pose = "walk"
	elif not grounded:
		if model.velocity.y + model.current_flow.y < -8:
			pose = "dive"
		elif model.velocity.y + model.current_flow.y > 1:
			pose = "ascend"
		elif horizontal > 1:
			pose = "swim"
	if landing > 0.1:
		pose = "land"
	var lean := 0.0
	if pose == "dive":
		lean = -2.2
	elif pose == "swim":
		lean = -1.1
	elif pose == "ascend":
		lean = 0.35
	torso.rotation.x = lerp_angle(torso.rotation.x, lean, 1 - exp(-dt * 8))
	torso.position.y = 1.05 - landing * 0.18
	var blend := 1 - exp(-dt * 12)
	for i in range(2):
		var side := -1 if i == 0 else 1
		var stroke := sin(model.elapsed * (7 if pose == "walk" else 4) + i * PI)
		arms[i].rotation.z = lerp_angle(
			arms[i].rotation.z, side * (0.13 if grounded else 0.45), blend
		)
		var arm_pitch: float = stroke * 0.4 if horizontal > 0.5 else -0.1
		if pose == "ascend":
			arm_pitch = -2.1 + stroke * 0.3
		arms[i].rotation.x = lerp_angle(arms[i].rotation.x, arm_pitch, blend)
		var leg_pitch: float = stroke * (0.5 if horizontal > 0.5 else 0.25)
		var knee_pitch: float = maxf(0, stroke) * 0.55 + landing * 0.4
		if grounded and horizontal < 0.5:
			leg_pitch = 0.0
			knee_pitch = landing * 0.4
		thighs[i].rotation.x = lerp_angle(thighs[i].rotation.x, leg_pitch, blend)
		shins[i].rotation.x = lerp_angle(shins[i].rotation.x, knee_pitch, blend)
