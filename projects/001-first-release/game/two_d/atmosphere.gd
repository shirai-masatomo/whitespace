extends RefCounted
## Cheap water layers behind terrain, pixel motes in front. No screen blur/refraction.


static func water(art: Node2D, game: Node2D, area: Rect2) -> void:
	for y in range(floori(area.position.y / 12) * 12, ceili(area.end.y) + 12, 12):
		var color := Color("147c99").lerp(Color("123849"), smoothstep(240, 3600, y))
		color = color.lerp(Color("0c2538"), smoothstep(3500, 5700, y))
		color = color.lerp(Color("050c20"), smoothstep(5700, 6250, y))
		if y < 240:
			color = Color("98d9dd")
		art.draw_rect(Rect2(area.position.x, y, area.size.x, 13), color)
	# Very broad, low-opacity haze; never paints over collision silhouettes or UI.
	for i in range(3):
		var point := Vector2(area.get_center().x + (i - 1) * 360, area.get_center().y + 50)
		var strength := 0.013 if point.y < 5900 else 0.006
		art.glow(point, 380, Color(0.2, 0.56, 0.65, strength))
	if area.position.y < 1400 and area.end.y > 240:
		for beam in range(6):
			var x := 1230.0 + beam * 91 + sin(game.clock * 0.18 + beam) * 12
			for fringe in range(3):
				var width := 10.0 + fringe * 10
				var vertices := PackedVector2Array(
					[
						Vector2(x - width, 240),
						Vector2(x + width, 240),
						Vector2(x - 160 + width * 2, 1350),
						Vector2(x - 160 - width * 2, 1350),
					]
				)
				var lit := Color(0.66, 0.97, 0.88, 0.022)
				var dark := Color(0.66, 0.97, 0.88, 0.0)
				art.draw_polygon(vertices, PackedColorArray([lit, lit, dark, dark]))

		for x in range(maxi(0, int(area.position.x)), mini(3360, int(area.end.x)) + 8, 8):
			var wave := roundf(sin(x * 0.026 + game.clock * 1.5) * 3)
			art.draw_rect(Rect2(x, 240 + wave, 8, 3), Color("a5ffed"))
			if (x / 8) % 7 == 0:
				art.draw_rect(Rect2(x, 247 + wave, 5, 2), Color(0.7, 1, 0.91, 0.35))
		art.draw_circle(Vector2(1390, 55), 27, Color("fff5c2"))
		art.glow(Vector2(1390, 55), 85, Color(1, 1, 0.7, 0.065))


static func motes(art: Node2D, game: Node2D, area: Rect2) -> void:
	# World-anchored cells: bounded to the visible region, not the entire ocean.
	for y in range(floori(area.position.y / 64) - 1, ceili(area.end.y / 64) + 1):
		for x in range(floori(area.position.x / 80) - 1, ceili(area.end.x / 80) + 1):
			var seed_value := absi(x * 719 + y * 317)
			var point := (
				Vector2(
					x * 80 + fposmod(seed_value * 13.1 + game.clock * 5, 80),
					y * 64 + fposmod(seed_value * 9.7 - game.clock * 8, 64)
				)
				. snapped(Vector2(2, 2))
			)
			if point.y < 250 or game.terrain.get_cell(game.terrain.tile_at(point)) != 0:
				continue
			var alpha := 0.14 + 0.12 * sin(seed_value + game.clock * 0.5)
			if point.y > 5900:
				alpha *= 0.45
			if seed_value % 9 == 0:
				bubble(art, point, 2 + seed_value % 3, Color(0.42, 0.8, 0.93, alpha))
			else:
				art.draw_rect(Rect2(point, Vector2(2, 2)), Color(0.64, 0.85, 0.85, alpha))


static func bubble(art: Node2D, point: Vector2, radius: float, tint: Color) -> void:
	var at := point.snapped(Vector2(2, 2))
	var fill := tint
	fill.a *= 0.15
	art.draw_circle(at, radius, fill)
	art.draw_arc(at, radius, 0.0, TAU, 12, tint, 1)
	var glint := tint.lightened(0.45)
	glint.a = tint.a
	art.draw_rect(Rect2(at + Vector2(-radius * 0.5, -radius * 0.7), Vector2(2, 2)), glint)


static func orb(art: Node2D, game: Node2D, point: Vector2, radius: float) -> void:
	var pulse := 0.92 + sin(game.clock * 1.2 + point.y) * 0.08
	art.glow(point, radius * 8, Color(0.13, 0.49, 1.0, 0.06 * pulse))
	art.glow(point, radius * 2.6, Color(0.24, 0.8, 1.0, 0.065))
	# Two-pixel scanlines retain a stepped silhouette, with light inside the water.
	for y in range(-int(radius), int(radius) + 1, 2):
		var width := floorf(sqrt(maxf(0, radius * radius - y * y)) / 2) * 2
		var color := Color("164c7b").lerp(Color("52c6d8"), 1 - absf(y / radius))
		color.a = 0.65
		art.draw_rect(Rect2(point + Vector2(-width, y), Vector2(width * 2, 2)), color)
	art.draw_arc(point, radius, 0.1, PI * 0.9, 16, Color(0.3, 0.77, 0.93, 0.65), 2)
	art.draw_arc(point, radius - 1, PI * 1.08, PI * 1.8, 16, Color("b1fff3"), 2)
	var core := point + Vector2(sin(game.clock) * 3, cos(game.clock * 0.8) * 3)
	art.glow(core, radius, Color(0.44, 1, 0.92, 0.1))
	art.draw_rect(Rect2(core - Vector2(3, 3), Vector2(6, 6)), Color("dcfff6"))
	art.draw_rect(
		Rect2(point + Vector2(-radius * 0.45, -radius * 0.65), Vector2(5, 3)), Color("ddfff7")
	)
