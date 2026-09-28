extends RefCounted
## Small deterministic, editable-by-digging ocean. 1 = bedrock, 2 = rock, 3 = sand.

const TILE := 24
const WIDTH := 120
const HEIGHT := 190
const SURFACE := 240.0
const SPAWN := Vector2(46 * TILE, 8 * TILE)
const GOAL := Vector2(58 * TILE, 176 * TILE)
const ROUTE := [
	Vector2(58, 10),
	Vector2(60, 25),
	Vector2(55, 45),
	Vector2(65, 65),
	Vector2(47, 85),
	Vector2(63, 108),
	Vector2(48, 130),
	Vector2(65, 149),
	Vector2(58, 176)
]
const GARDENS := [
	Vector2(58, 25),
	Vector2(52, 45),
	Vector2(32, 65),
	Vector2(65, 67),
	Vector2(88, 92),
	Vector2(47, 87),
	Vector2(63, 109),
	Vector2(30, 127),
	Vector2(48, 132),
	Vector2(65, 151),
	Vector2(58, 174)
]
const RELICS := [Vector2(30, 62), Vector2(92, 95), Vector2(28, 127)]

var cells := PackedByteArray()


func _init() -> void:
	cells.resize(WIDTH * HEIGHT)
	for y in range(HEIGHT):
		for x in range(WIDTH):
			var cell := 0 if y < 10 else 2
			if x < 3 or x >= WIDTH - 3 or y >= HEIGHT - 3:
				cell = 1
			cells[y * WIDTH + x] = cell
	carve_path(ROUTE, 8.0)
	carve_path([Vector2(55, 45), Vector2(34, 52), Vector2(30, 67), Vector2(47, 85)], 5)
	carve_path([Vector2(65, 65), Vector2(87, 77), Vector2(91, 99), Vector2(63, 108)], 6)
	carve_path([Vector2(63, 108), Vector2(30, 119), Vector2(28, 134), Vector2(48, 130)], 5)
	carve_disk(Vector2(60, 26), 16)
	carve_disk(Vector2(65, 66), 12)
	carve_disk(Vector2(58, 174), 13)
	# A real shore: walking off the right edge starts the dive.
	for x in range(36, 52):
		set_cell(Vector2i(x, 10), 1)
		for y in range(11, 17):
			set_cell(Vector2i(x, y), 2)
	# Short shelves remain attached to the cave wall; never seal the passage.
	for shelf in [Vector2i(48, 42), Vector2i(69, 73), Vector2i(40, 93), Vector2i(67, 121)]:
		for dx in range(5):
			set_cell(shelf + Vector2i(dx, 0), 2)
	for y in range(11, HEIGHT - 3):
		for x in range(3, WIDTH - 3):
			var at := Vector2i(x, y)
			if get_cell(at) == 2 and get_cell(at + Vector2i.UP) == 0:
				set_cell(at, 3)
	for point in GARDENS:
		carve_disk(point, 2.5)
	for point in RELICS:
		carve_disk(point, 2.5)


func carve_path(points: Array, radius: float) -> void:
	for i in range(points.size() - 1):
		var steps := int(points[i].distance_to(points[i + 1]) * 2) + 1
		for step in range(steps + 1):
			var point: Vector2 = points[i].lerp(points[i + 1], float(step) / steps)
			carve_disk(point, radius + sin(point.y * 0.43) * 1.2)


func carve_disk(center: Vector2, radius: float) -> void:
	for y in range(maxi(1, int(center.y - radius)), mini(HEIGHT - 3, int(center.y + radius) + 1)):
		for x in range(
			maxi(3, int(center.x - radius)), mini(WIDTH - 3, int(center.x + radius) + 1)
		):
			if Vector2(x, y).distance_to(center) < radius:
				set_cell(Vector2i(x, y), 0)


func get_cell(at: Vector2i) -> int:
	if at.x < 0 or at.x >= WIDTH or at.y < 0 or at.y >= HEIGHT:
		return 1
	return cells[at.y * WIDTH + at.x]


func set_cell(at: Vector2i, value: int) -> void:
	if at.x >= 0 and at.x < WIDTH and at.y >= 0 and at.y < HEIGHT:
		cells[at.y * WIDTH + at.x] = value


func tile_at(point: Vector2) -> Vector2i:
	return Vector2i(floori(point.x / TILE), floori(point.y / TILE))


func visible_from(from: Vector2, to: Vector2, target: Vector2i) -> bool:
	var count := int(from.distance_to(to) / 5) + 1
	for i in range(count):
		var cell := tile_at(from.lerp(to, float(i) / count))
		if cell != target and get_cell(cell) != 0:
			return false
	return true
