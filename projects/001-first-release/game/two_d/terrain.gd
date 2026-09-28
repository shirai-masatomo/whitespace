extends RefCounted
## 1 = unbreakable deep bedrock, 2 = diggable rock, 3 = sand.

const TILE := 24
const WIDTH := 140
const HEIGHT := 375
const SURFACE := 240.0
const SPAWN := Vector2(46 * TILE, 8 * TILE)
const GOAL := Vector2(58 * TILE, 350 * TILE)
var cells := PackedByteArray()
var route: Array[Vector2] = []


func _init(layout: Node2D) -> void:
	cells.resize(WIDTH * HEIGHT)
	for y in range(HEIGHT):
		for x in range(WIDTH):
			var cell := 0 if y < 10 else 2
			if x < 3 or x >= WIDTH - 3 or y >= 240:
				cell = 1
			cells[y * WIDTH + x] = cell
	for passage in layout.get_node("Passages").get_children():
		var points: Array[Vector2] = []
		for i in range(passage.curve.point_count):
			points.append(passage.to_global(passage.curve.get_point_position(i)) / TILE)
		carve_path(points, passage.radius)
		if (
			passage.name
			in ["Introduction", "CanyonOutside", "DeepFault", "DarkNarrows", "BiologyChamber"]
		):
			route.append_array(points)
	carve_disk(Vector2(60, 26), 17)
	# Broad sand basin, one natural opening at its eastern deepest point.
	for x in range(31, 90):
		var floor_y := 238 + int(sin(x * 0.18) * 2)
		for y in range(228 + int(absf(x - 61) * 0.1), floor_y):
			set_cell(Vector2i(x, y), 0)
		for y in range(floor_y, floor_y + 3):
			set_cell(Vector2i(x, y), 3 if y < 240 else 1)
	var gate = layout.get_node("Passages/RockGate")
	var gate_points: Array[Vector2] = []
	for i in range(gate.curve.point_count):
		gate_points.append(gate.to_global(gate.curve.get_point_position(i)) / TILE)
	carve_path(gate_points, gate.radius)
	# The chamber opens only AFTER a substantial length of narrow dark rock.
	for y in range(309, 365):
		for x in range(32, 109):
			var distance := Vector2((x - 71.0) / 36, (y - 336.0) / 28).length()
			if distance < 1:
				set_cell(Vector2i(x, y), 0)
	for x in range(36, 52):
		set_cell(Vector2i(x, 10), 1)
		for y in range(11, 17):
			set_cell(Vector2i(x, y), 2)
	for shelf in [Vector2i(48, 42), Vector2i(39, 107), Vector2i(67, 121), Vector2i(65, 187)]:
		for dx in range(5):
			set_cell(shelf + Vector2i(dx, 0), 2)
	# Terraced cliff: walking landings, undercut, and a swim passage alongside.
	for x in range(32, 47):
		var top := 111 - (x - 32) / 3
		for y in range(int(top), 116):
			set_cell(Vector2i(x, y), 2)
	for y in range(11, 240):
		for x in range(3, WIDTH - 3):
			var at := Vector2i(x, y)
			if get_cell(at) == 2 and get_cell(at + Vector2i.UP) == 0:
				set_cell(at, 3)
	for marker in layout.get_node("Landmarks").get_children():
		if marker.kind in ["algae", "orb", "relic", "goal"]:
			carve_disk(marker.global_position / TILE, 2.5)
		elif marker.kind == "air":
			var center: Vector2 = marker.global_position / TILE
			var half: Vector2 = marker.extent / TILE
			for y in range(int(center.y - half.y), int(center.y + half.y)):
				for x in range(int(center.x - half.x) - 1, int(center.x + half.x) + 2):
					set_cell(Vector2i(x, y), 0)
			for x in range(int(center.x - half.x), int(center.x + half.x)):
				set_cell(Vector2i(x, int(center.y + half.y)), 2)


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
