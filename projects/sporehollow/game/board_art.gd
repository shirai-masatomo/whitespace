extends RefCounted
# Original code-drawn farm. Visual detail does not alter collision or simulation RNG.
static func draw_ground(c: CanvasItem, world, tile: Vector2, time: float = 0):
	c.draw_rect(Rect2(-1500, -1500, 4200, 3600), Color("42634b"))
	for y in range(world.H):
		for x in range(world.W):
			var p = Vector2(x, y) * tile
			var patch = (sin(x * 0.37 + y * 0.29) + sin(x * 0.19 - y * 0.48) + 2) * 0.25
			var color = Color("637c48").lerp(Color("90a562"), patch * 0.75)
			if not world.inside(Vector2i(x, y)): color = Color("526d43")
			var corners = PackedVector2Array([p, p + Vector2(tile.x, 0), p + tile, p + Vector2(0, tile.y)])
			var colors = PackedColorArray()
			for corner in corners:
				var v = corner / tile
				var blend = (sin(v.x * 0.37 + v.y * 0.29) + sin(v.x * 0.19 - v.y * 0.48) + 2) * 0.25
				colors.append(Color("637c48").lerp(Color("90a562"), blend * 0.75) if world.inside(Vector2i(x, y)) else color)
			c.draw_polygon(corners, colors)
			var n = (x * 173 + y * 317) % 137
			for i in range(1 + n % 4 if sin(x * 0.63 + y * 0.4) > -0.2 else 0):
				var q = p + Vector2((n * (i + 3)) % 43 + 2, (n * (i + 7)) % 35 + 3)
				var sway = sin(time * 1.4 + x * 0.4 + y) * 1.4 if n % 5 == 0 else 0.0
				c.draw_line(q, q + Vector2(2 + sway, -4), Color("91a961"), 2)
				c.draw_line(q + Vector2(3, 0), q + Vector2(5, -5), Color("617c45"), 2)
			if n < 19:
				c.draw_rect(Rect2(p + Vector2(12, 23), Vector2(23, 7)), Color("a0a06a"))
				c.draw_rect(Rect2(p + Vector2(17, 20), Vector2(11, 3)), Color("96955f"))
			if n > 124:
				c.draw_rect(Rect2(p + Vector2(31, 20), Vector2(3, 3)), Color("ded3a2"))
	# Sparse drifting moths; never cover actors with a particle carpet.
	for i in range(3):
		var q = Vector2(230 + i * 370 + sin(time * 0.26 + i) * 34, 165 + i * 96 + cos(time * 0.38 + i) * 18)
		var wing = 2 + absf(sin(time * 7 + i)) * 2
		c.draw_line(q - Vector2(wing, 2), q, Color("d5d7a1"), 2)
		c.draw_line(q, q + Vector2(wing, -2), Color("c0c793"), 2)
	# Worn entrance trail stops short of the meadow, never implying a mandatory route.
	for entry in world.entries:
		var p = (Vector2(entry) + Vector2.ONE * 0.5) * tile
		c.draw_line((Vector2(world.exit_for(entry)) + Vector2.ONE * 0.5) * tile, p + Vector2(76, 0), Color("ad9d70"), 27)
		c.draw_line(p, p + Vector2(96, 8), Color("ad9d70"), 13)
	# Fence follows the actual immutable boundary; entrance cells remain visibly open.
	for y in range(world.H):
		for x in range(world.W):
			var cell = Vector2i(x, y)
			if world.inside(cell) or cell in world.entries or cell in world.entries.map(func(e): return world.exit_for(e)): continue
			var p = (Vector2(cell) + Vector2.ONE * 0.5) * tile
			var horizontal = y == 0 or y == world.H - 1
			var axis = Vector2(tile.x * 0.5, 0) if horizontal else Vector2(0, tile.y * 0.5)
			c.draw_line(p - axis + Vector2(3, 4), p + axis + Vector2(3, 4), Color("354c37"), 9)
			for offset in [-6, 5]:
				c.draw_line(p - axis + Vector2(0, offset), p + axis + Vector2(0, offset), Color("b6955e"), 5)
			c.draw_rect(Rect2(p - Vector2(4, 13), Vector2(8, 31)), Color("7d5a3e"))
			c.draw_rect(Rect2(p - Vector2(4, 13), Vector2(8, 5)), Color("d0b17a"))
	for entry in world.entries:
		var p = (Vector2(entry) + Vector2.ONE * 0.5) * tile
		var warning = world.phase == "defend" and (world.next_attack_seconds() >= 0 and world.next_attack_seconds() < 3 or world.enemies.any(func(e): return not e.done and not e.flee and e.entry == entry))
		# Heavy paired gate posts, open leaves and pennants; actual entrance remains walkable.
		for side in [-1, 1]:
			var post = p + Vector2(-24, side * 33)
			c.draw_rect(Rect2(post + Vector2(-3, 4), Vector2(20, 32)), Color(0.14, 0.22, 0.12, 0.4))
			c.draw_rect(Rect2(post - Vector2(8, 19), Vector2(16, 40)), Color("876044"))
			c.draw_rect(Rect2(post - Vector2(10, 21), Vector2(20, 7)), Color("d2b67e"))
			c.draw_line(post, post + Vector2(28, side * 15), Color("b49665"), 6)
			c.draw_line(post + Vector2(0, 9), post + Vector2(28, side * 15 + 9), Color("94714d"), 5)
			c.draw_line(post + Vector2(0, -16), post + Vector2(0, -49), Color("e0cca2"), 2)
			var flutter = sin(time * (9 if warning else 2) + side) * (5 if warning else 2)
			c.draw_colored_polygon(PackedVector2Array([post + Vector2(1, -48), post + Vector2(23, -42 + flutter), post + Vector2(1, -34)]), Color("e89559") if warning else Color("9ab6b0"))
	# Quiet props outside the playable area; no invisible obstacles on the board.
	for x in [3, 9, 19, 23]:
		var p = Vector2(x * tile.x, -8)
		c.draw_circle(p, 18, Color("304b39"))
		c.draw_circle(p + Vector2(-9, -9), 15, Color("577849"))
		c.draw_circle(p + Vector2(12, -10), 12, Color("63834b"))
		c.draw_rect(Rect2(p + Vector2(-2, 0), Vector2(5, 16)), Color("795a40"))

static func draw_resource(c: CanvasItem, p: Vector2, kind: String):
	match kind:
		"weed":
			c.draw_circle(p + Vector2(0, 7), 11, Color("516c3e"))
			for side in [-1, 1]:
				c.draw_line(p + Vector2(0, 8), p + Vector2(side * 9, -8), Color("c1d074"), 3)
				c.draw_line(p + Vector2(0, 5), p + Vector2(side * 12, -1), Color("91b55d"), 4)
			c.draw_line(p + Vector2(0, 8), p + Vector2(1, -14), Color("d4da89"), 3)
		"mushroom":
			c.draw_rect(Rect2(p + Vector2(-3, -1), Vector2(6, 13)), Color("efe1b3"))
			c.draw_circle(p + Vector2(0, -5), 10, Color("b66653"))
			c.draw_rect(Rect2(p + Vector2(-10, -4), Vector2(20, 5)), Color("db9170"))
			c.draw_rect(Rect2(p + Vector2(-5, -9), Vector2(4, 3)), Color("fae4b0"))
		"gold":
			c.draw_circle(p, 10, Color("a77732"))
			c.draw_circle(p + Vector2(-1, -2), 8, Color("ebc767"))
			c.draw_line(p + Vector2(-2, -7), p + Vector2(-2, 3), Color("fff0ac"), 2)
		"soil":
			c.draw_rect(Rect2(p - Vector2(11, 9), Vector2(22, 19)), Color("987045"))
			c.draw_rect(Rect2(p - Vector2(11, 10), Vector2(22, 5)), Color("97b168"))
			c.draw_line(p + Vector2(-9, 1), p + Vector2(9, 3), Color("c3a277"), 3)
		"wood", "stump":
			if kind == "stump":
				c.draw_rect(Rect2(p + Vector2(-10, -3), Vector2(20, 18)), Color("84593d"))
				c.draw_circle(p + Vector2(0, -4), 11, Color("c6a277"))
				c.draw_arc(p + Vector2(0, -4), 6, 0, TAU, 12, Color("927149"), 2)
			else:
				for y in [-4, 5]:
					c.draw_line(p + Vector2(-9, y), p + Vector2(7, y - 4), Color("8b6040"), 8)
					c.draw_circle(p + Vector2(8, y - 4), 4, Color("dbc094"))
		"stone":
			for offset in [Vector2(-7, 4), Vector2(6, 5), Vector2(0, -5)]:
				c.draw_colored_polygon(PackedVector2Array([p + offset + Vector2(-7, 4), p + offset + Vector2(-4, -4), p + offset + Vector2(4, -6), p + offset + Vector2(7, 4)]), Color("9caaa7"))

static func icon(kind: String) -> Texture2D:
	var img = Image.create(20, 20, false, Image.FORMAT_RGBA8)
	for y in range(4, 18):
		for x in range(2, 18):
			img.set_pixel(x, y, (Color("98ac6d") if y < 8 else Color("a47b4e")) if kind == "soil" else Color("c6a277"))
	return ImageTexture.create_from_image(img)
