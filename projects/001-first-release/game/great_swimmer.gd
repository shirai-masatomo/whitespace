extends Node3D
## Original slow whale-like silhouette, not a scaled platform animal.
const Geo = preload("res://game/ocean_geometry.gd")
var fins: Array[Node3D] = []


func _ready() -> void:
	var skin := Geo.material(Color("203c48"), .55)
	var body := Geo.put(
		self,
		Geo.loft(
			[
				Vector3(-18, .05, .05),
				Vector3(-16, 3, 2.3),
				Vector3(-12, 6, 4),
				Vector3(-3, 6.6, 4.3),
				Vector3(6, 4.2, 3),
				Vector3(14, 1.6, 1),
				Vector3(18, .5, .4),
				Vector3(19, .02, .02)
			],
			32
		),
		skin
	)
	body.rotation.x = PI / 2
	for side in [-1, 1]:
		Geo.sphere(self, .28, Geo.material(Color("071a20")), Vector3(side * 5.5, .5, -12))
		var fin := Geo.put(
			self,
			Geo.loft(
				[
					Vector3(0, 1.5, 2.5),
					Vector3(3, .8, 2.2),
					Vector3(7, .3, 1),
					Vector3(10, .01, .01)
				],
				16
			),
			skin,
			Vector3(side * 4, -1.5, -3)
		)
		fin.rotation.z = side * -1.5
		fin.rotation.x = .6
		fins.append(fin)
		var fluke := Geo.put(
			self,
			Geo.loft(
				[Vector3(0, .4, 1.3), Vector3(3, .7, 3), Vector3(7, .25, 2), Vector3(9, .01, .01)],
				16
			),
			skin,
			Vector3(0, 0, 17)
		)
		fluke.rotation.z = side * -PI / 2
		fins.append(fluke)


func swim(time: float) -> void:
	for index in range(fins.size()):
		fins[index].rotation.x = (.6 if index % 2 == 0 else 0) + sin(time * .7) * .12
