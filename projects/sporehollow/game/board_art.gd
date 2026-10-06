extends RefCounted
const Delivered = preload("res://game/delivered_art.gd")
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
	# Deep forest is outside the immutable boundary, not an enclosure wall.
	for y in range(-1,world.H+1):
		for x in range(-1,world.W+1):
			if x not in [-1,0,world.W-1,world.W] and y not in [-1,0,world.H-1,world.H]: continue
			if y in [5,6] and x<=0: continue # merchant trail, not the sole invasion route
			preload("res://game/story_view.gd").tree(c,Vector2i(x,y),true)

static func draw_resource(c: CanvasItem, p: Vector2, kind: String):
	if Delivered.RESOURCES.has(kind):
		Delivered.resource(c,kind,p,24)
		return
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
		"stump":
			c.draw_rect(Rect2(p + Vector2(-10, -3), Vector2(20, 18)), Color("84593d"))
			c.draw_circle(p + Vector2(0, -4), 11, Color("c6a277"))
			c.draw_arc(p + Vector2(0, -4), 6, 0, TAU, 12, Color("927149"), 2)

static func icon(kind: String) -> Texture2D:
	if Delivered.RESOURCES.has(kind):return Delivered.RESOURCES[kind][24]
	var img = Image.create(20, 20, false, Image.FORMAT_RGBA8)
	for y in range(4, 18):
		for x in range(2, 18):
			img.set_pixel(x, y, (Color("98ac6d") if y < 8 else Color("a47b4e")) if kind == "soil" else Color("c6a277"))
	return ImageTexture.create_from_image(img)
