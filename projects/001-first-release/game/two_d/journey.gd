extends RefCounted
## Compact final-act places. Depth is physical prototype distance, not a fake 11km HUD.

const LAYER_STARTS := [240.0, 5900.0, 8976.0, 11760.0, 16896.0, 22152.0]
const LAYER_NAMES := ["現実海", "生物", "沈没船", "神話", "星海", "最深部"]


static func layer(y: float) -> int:
	for index in range(LAYER_STARTS.size() - 1, -1, -1):
		if y >= LAYER_STARTS[index]:
			return index + 1
	return 1


static func water_color(y: float, original: Color) -> Color:
	var color := original
	color = color.lerp(Color("152b31"), smoothstep(8856, 9216, y))
	color = color.lerp(Color("233b46"), smoothstep(11520, 12000, y))
	color = color.lerp(Color("171329"), smoothstep(16416, 17400, y))
	color = color.lerp(Color("060f18"), smoothstep(21800, 22500, y))
	return color


static func background(art: Node2D, game: Node2D, area: Rect2) -> void:
	var current := layer(area.get_center().y)
	if current == 3:
		# Hull ribs and portholes behind the flooded corridor.
		for row in range(378, 465, 9):
			if absf(row * 24 - area.get_center().y) > 500:
				continue
			art.draw_rect(Rect2(600, row * 24, 1800, 9), Color("283b3d"))
			for x in range(800, 2300, 240):
				var at := Vector2(x, row * 24 + 85)
				art.draw_circle(at, 31, Color("314c51"))
				art.draw_circle(at, 24, Color("0d202c"))
				art.draw_arc(at, 24, PI, TAU, 16, Color("507176"), 2)
	elif current == 4:
		# Distant roof silhouettes suggest a submerged palace, not another rock cave.
		for i in range(5):
			var origin := Vector2(620 + i * 425, 12640 + i * 583)
			for storey in range(3):
				roof(art, origin + Vector2(0, storey * 65), 170 - storey * 25, Color("234d53"))
	elif current == 5:
		for i in range(170):
			var at := Vector2(80 + fmod(i * 317.3, 3200), 16750 + fmod(i * 139.7, 5700))
			if not area.has_point(at):
				continue
			var bright := 0.3 + sin(game.clock * 0.6 + i) * 0.15
			art.draw_rect(
				Rect2(at.snapped(Vector2(3, 3)), Vector2(3, 3)), Color(0.8, 0.74, 1, bright)
			)
			if i % 13 == 0:
				art.glow(at, 75, Color(0.55, 0.3, 1, 0.025))
		var planets := [
			Vector2(81, 716),
			Vector2(66, 743),
			Vector2(82, 771),
			Vector2(33, 800),
			Vector2(80, 828),
			Vector2(47, 876),
			Vector2(70, 903)
		]
		for i in range(planets.size()):
			var at: Vector2 = planets[i] * 24
			if area.grow(280).has_point(at):
				art.glow(at, 350, Color(0.38, 0.19, 0.72, 0.055))
				art.draw_set_transform(at, -0.35, Vector2(1, 0.35))
				art.draw_arc(Vector2.ZERO, 155, 0, TAU, 64, Color("5f557d"), 4)
				art.draw_set_transform(Vector2.ZERO)
				for row in range(-85, 86, 4):
					var half := floorf(sqrt(maxf(0, 85 * 85 - row * row)) / 4) * 4
					var tone := Color("302745").lerp(Color("645076"), (row + 85.0) / 170)
					art.draw_rect(Rect2(at + Vector2(-half, row), Vector2(half * 2, 4)), tone)
					art.draw_rect(
						Rect2(at + Vector2(-half, row), Vector2(minf(8, half), 4)), Color("827398")
					)
	elif current == 6:
		for i in range(7):
			var prior := Vector2(800 + i * 220, 22000)
			for segment in range(15):
				var next := Vector2(
					800 + i * 220 + sin(segment * 0.9 + i) * 30, 22000 + (segment + 1) * 155
				)
				art.draw_line(prior, next, Color("0c1d26"), 18 + i % 3 * 6)
				prior = next


static func decorate(art: Node2D, game: Node2D, area: Rect2) -> void:
	for marker in game.markers():
		var at: Vector2 = marker.global_position
		if not area.grow(300).has_point(at):
			continue
		if marker.kind == "shrine":
			# Roofs/columns match terrain cells; the central hall can be entered.
			roof(art, at + Vector2(12, -120), 228, Color("914a52"))
			for side in [-1, 1]:
				var column := at + Vector2(side * 192, -96)
				for offset in [0, 168]:
					art.draw_rect(
						Rect2(column + Vector2(0, offset), Vector2(24, 72)), Color("75434b")
					)
					art.draw_rect(
						Rect2(column + Vector2(4, offset), Vector2(4, 72)), Color("b46d60")
					)
				lantern(art, at + Vector2(side * 143, -65), game.clock)
		elif marker.kind == "chest":
			chest(art, at, game.encounters.chest_open, game.clock)
	if area.end.y > 23600:
		var bottom: Vector2 = game.goal_position()
		for i in range(9):
			var at := bottom + Vector2(i * 37 - 148, 118 + abs(i - 4) * 4)
			art.draw_rect(Rect2(at, Vector2(25, 5)), Color("688488"))
			art.draw_line(at + Vector2(10, 0), at + Vector2(15, -23), Color("819b99"), 3)


static func roof(art: Node2D, at: Vector2, width: float, color: Color) -> void:
	for step in range(3):
		var half := maxf(24, width - step * 72)
		var corner := at + Vector2(-half, -step * 24)
		art.draw_rect(Rect2(corner, Vector2(half * 2, 24)), color.darkened(step * 0.035))
		art.draw_rect(Rect2(corner, Vector2(half * 2, 3)), Color("b69c72"))


static func lantern(art: Node2D, at: Vector2, time: float) -> void:
	art.glow(at, 95, Color(1, 0.48, 0.21, 0.045))
	var sway := roundf(sin(time + at.x) * 2)
	art.draw_line(at + Vector2(0, -50), at + Vector2(sway, 0), Color("7a7763"), 2)
	art.draw_rect(Rect2(at + Vector2(-8 + sway, -11), Vector2(16, 22)), Color("dfb776"))
	art.draw_rect(Rect2(at + Vector2(-3 + sway, -9), Vector2(6, 18)), Color("fff0b0"))


static func chest(art: Node2D, at: Vector2, opened: bool, time: float) -> void:
	art.glow(at, 130, Color(0.75, 0.43, 0.8, 0.045))
	art.draw_rect(Rect2(at + Vector2(-33, -12), Vector2(66, 37)), Color("792d40"))
	art.draw_rect(
		Rect2(at + Vector2(-36, -23 if not opened else -44), Vector2(72, 13)), Color("b24852")
	)
	for side in [-1, 1]:
		art.draw_rect(Rect2(at + Vector2(side * 23, -12), Vector2(4, 37)), Color("d8b972"))
	art.draw_rect(Rect2(at + Vector2(-5, -7), Vector2(10, 12)), Color("e5cd8c"))
	if opened:
		for i in range(20):
			var rise := fmod(time * 35 + i * 13, 240)
			var spark := at + Vector2(sin(i + rise * 0.02) * rise * 0.4, -rise)
			art.draw_rect(
				Rect2(spark.snapped(Vector2(3, 3)), Vector2(3, 3)),
				Color(0.85, 0.7, 1, 1 - rise / 250)
			)


static func lotus(art: Node2D, at: Vector2, time: float) -> void:
	art.glow(at, 120, Color(0.6, 0.28, 0.68, 0.06))
	for petal in range(7):
		var angle := petal * TAU / 7 + sin(time) * 0.08
		var tip := at + Vector2(cos(angle) * 21, sin(angle) * 12)
		art.draw_rect(
			Rect2(tip.snapped(Vector2(3, 3)) - Vector2(6, 6), Vector2(12, 12)), Color("ce97bb")
		)
	art.draw_rect(Rect2(at - Vector2(6, 5), Vector2(12, 10)), Color("f4e2b8"))
	art.draw_line(at + Vector2(0, 8), at + Vector2(0, 31), Color("539e8d"), 3)
