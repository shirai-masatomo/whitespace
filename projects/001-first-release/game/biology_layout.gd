extends RefCounted
## The sole descending throat opens into a chamber; this is only the next layer's prologue.
const APPROACH: Array[Vector3] = [
	Vector3(5, -449, -109),
	Vector3(26, -449, -109),
	Vector3(38, -451, -114),
	Vector3(38, -456, -133),
	Vector3(38, -477, -133)
]
const PATH: Array[Vector3] = [
	Vector3(38, -457, -133),
	Vector3(38, -478, -133),
	Vector3(47, -505, -119),
	Vector3(32, -532, -129),
	Vector3(48, -559, -140),
	Vector3(48, -585, -150)
]
const GLOBES: Array[Vector3] = [
	Vector3(38, -478, -133),
	Vector3(47, -505, -119),
	Vector3(32, -532, -129),
	Vector3(48, -559, -140),
	Vector3(48, -585, -150),
	Vector3(40, -619, -166),
	Vector3(36, -650, -174),
	Vector3(35, -680, -174)
]
const OCTOPUS := Vector3(65, -633, -217)


static func platforms() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for i in range(GLOBES.size()):
		result.append(
			{
				"label": "水球",
				"point": GLOBES[i],
				"size": Vector2(4, 4),
				"kind": "water_globe",
				"oxygen": true,
				"goal": i == GLOBES.size() - 1
			}
		)
	return result


static func radius(t: float) -> Vector2:
	return Vector2(6.3 + 1.0 * sin(t * 7), 6.7 + .8 * cos(t * 8)).lerp(
		Vector2(6, 14), 1 - smoothstep(0, .13, t)
	)


static func sand_height(x: float, z: float) -> float:
	var dunes := sin(x * .09) * 1.1 + cos(z * .11 + x * .025) * .8
	var dune_bank := exp(-pow((x - 7) / 17, 2) - pow((z + 91) / 15, 2)) * 3.2
	dunes += dune_bank + exp(-pow((x - 60) / 12, 2) - pow((z + 110) / 19, 2)) * 4
	var rim := Vector2((x - 38) / 6, (z + 133) / 14).length()
	# The crevice is the basin's unique low point, not one hole on a level plain.
	var distance := Vector2(x - 38, z + 133).length()
	var shoulder := smoothstep(32, 190, distance) * 125
	var gully := 1 - smoothstep(6, 22, absf(x - 38 + (z + 133) * .35))
	shoulder *= 1 - gully * .35
	return -457 + shoulder + (dunes + 2.0) * smoothstep(1, 3, rim)


static func mouth_outline() -> PackedVector2Array:
	var result := PackedVector2Array()
	for side in range(32):
		var angle := side * TAU / 32
		var fracture := 1 + sin(angle * 3 + .4) * .18 + sin(angle * 7) * .08
		result.append(
			Vector2(
				38 + cos(angle) * 6 * fracture + sin(angle) * 2, -133 + sin(angle) * 14 * fracture
			)
		)
	return result
