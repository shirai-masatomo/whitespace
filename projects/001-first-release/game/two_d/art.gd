extends Node2D
## Original code-drawn pixel art; no Terraria assets or copied world layout.

const Terrain = preload("res://game/two_d/terrain.gd")
const BLUE := Color("8cf4ef")
const GOLD := Color("ffcf85")

var game: Node2D


func _draw() -> void:
	var inverse := get_canvas_transform().affine_inverse()
	var visible := Rect2(inverse * Vector2.ZERO, get_viewport_rect().size / game.camera.zoom)
	background(visible)
	land(visible)
	life(visible)
	for garden in Terrain.GARDENS:
		var point: Vector2 = garden * Terrain.TILE
		if visible.grow(100).has_point(point):
			glow(point, 78, Color(0.18, 1, 0.75, 0.035))
			for strand in range(7):
				var root := point + Vector2((strand - 3) * 7, 30)
				plant(root, 37 + (strand * 7) % 24, strand, true)
			for bubble in range(6):
				var rise := fmod(game.clock * 23 + bubble * 14, 88)
				draw_arc(
					point + Vector2(sin(rise * 0.09 + bubble) * 22, 20 - rise),
					2 + bubble % 3,
					0,
					TAU,
					8,
					Color(0.45, 1, 0.88, 0.6),
					1
				)
	for index in range(Terrain.RELICS.size()):
		var point: Vector2 = Terrain.RELICS[index] * Terrain.TILE
		if not game.collected.has(index) and visible.grow(100).has_point(point):
			glow(point, 64, Color(1, 0.65, 0.25, 0.04))
			draw_colored_polygon(
				PackedVector2Array(
					[
						point + Vector2(0, -14),
						point + Vector2(9, 0),
						point + Vector2(0, 14),
						point + Vector2(-9, 0)
					]
				),
				GOLD
			)
			draw_line(point + Vector2(0, -9), point + Vector2(0, 6), Color.WHITE, 2)
	goal()
	diver()
	if game.started and not game.paused and not game.complete:
		var at: Vector2i = game.terrain.tile_at(get_global_mouse_position())
		var rect := Rect2(Vector2(at) * Terrain.TILE, Vector2.ONE * Terrain.TILE)
		if game.player.position.distance_to(rect.get_center()) <= 115:
			draw_rect(rect, Color(0.8, 1, 1, 0.6), false, 1)


func background(area: Rect2) -> void:
	for y in range(int(area.position.y) - 24, int(area.end.y) + 24, 24):
		var deep := clampf((y - Terrain.SURFACE) / 4100.0, 0, 1)
		var color := Color("146985").lerp(Color("080f2c"), deep)
		if y < Terrain.SURFACE:
			color = Color("96dce0")
		draw_rect(Rect2(area.position.x, y, area.size.x, 25), color)
	# Background geology is darker and displaced to give the cave a second depth plane.
	for i in range(15):
		var x := i * 240.0 + sin(i * 6.7) * 70
		var top := 350 + fmod(i * 263.0, 840)
		var peak := Vector2(x, top)
		draw_colored_polygon(
			PackedVector2Array(
				[
					peak + Vector2(-120, 4300),
					peak + Vector2(-60, 80),
					peak,
					peak + Vector2(44, 170),
					peak + Vector2(120, 4300)
				]
			),
			Color(0.025, 0.10, 0.20, 0.33)
		)
	if area.position.y < 850:
		for i in range(7):
			var x := 980 + i * 85.0 + sin(game.clock * 0.2 + i) * 12
			draw_colored_polygon(
				PackedVector2Array(
					[
						Vector2(x, Terrain.SURFACE),
						Vector2(x + 17, Terrain.SURFACE),
						Vector2(x - 70, 990),
						Vector2(x - 190, 990)
					]
				),
				Color(0.7, 1, 0.86, 0.035)
			)
		for x in range(0, Terrain.WIDTH * Terrain.TILE, 8):
			var wave := sin(x * 0.026 + game.clock * 1.5) * 3
			draw_rect(Rect2(x, Terrain.SURFACE + wave, 8, 3), Color("a5ffed"))
		draw_circle(Vector2(1390, 55), 27, Color("fff5c2"))
		glow(Vector2(1390, 55), 65, Color(1, 1, 0.7, 0.035))
	# Constant density, deterministic locations: subtle drifting marine snow.
	for i in range(200):
		var x := fposmod(i * 179.7 + game.clock * 4, Terrain.WIDTH * Terrain.TILE)
		var y := 250 + fposmod(i * 67.1 - game.clock * 8, 4200)
		if area.has_point(Vector2(x, y)):
			draw_rect(Rect2(x, y, 2, 2), Color(0.6, 0.95, 1, 0.25))


func land(area: Rect2) -> void:
	var start: Vector2i = game.terrain.tile_at(area.position) - Vector2i.ONE
	var end: Vector2i = game.terrain.tile_at(area.end) + Vector2i.ONE
	for y in range(maxi(0, start.y), mini(Terrain.HEIGHT, end.y + 1)):
		for x in range(maxi(0, start.x), mini(Terrain.WIDTH, end.x + 1)):
			var at := Vector2i(x, y)
			var cell: int = game.terrain.get_cell(at)
			if cell == 0:
				continue
			var point := Vector2(at) * Terrain.TILE
			var hash_value := absi(x * 374761 + y * 668265) % 97
			var color := Color("244451").lerp(Color("121e35"), clampf(y / 190.0, 0, 1))
			color = color.lightened(float(hash_value % 7) * 0.016)
			if cell == 3:
				color = Color("9a9872").lerp(Color("4b686b"), y / 190.0)
			if cell == 1:
				color = Color("253743")
			draw_rect(Rect2(point, Vector2.ONE * Terrain.TILE), color)
			draw_rect(
				Rect2(point + Vector2(3 + hash_value % 8, 7), Vector2(9, 2)), color.lightened(0.04)
			)
			if hash_value % 3 == 0:
				draw_line(point + Vector2(16, 0), point + Vector2(8, 10), color.darkened(0.25), 1)
			if game.terrain.get_cell(at + Vector2i.UP) == 0:
				draw_rect(Rect2(point, Vector2(24, 3)), color.lightened(0.25))
				if y > 12 and hash_value % 3 == 0:
					plant(point + Vector2(10, 0), 20 + hash_value % 40, x, false)
				elif y > 15 and hash_value % 4 == 0:
					coral(point + Vector2(12, 0), hash_value)
			if game.terrain.get_cell(at + Vector2i.LEFT) == 0:
				draw_rect(Rect2(point, Vector2(3, 24)), color.lightened(0.1))
			if game.terrain.get_cell(at + Vector2i.RIGHT) == 0:
				draw_rect(Rect2(point + Vector2(21, 0), Vector2(3, 24)), color.darkened(0.2))
			if y > 40 and hash_value % 11 == 0:
				if game.terrain.get_cell(at + Vector2i.LEFT) == 0:
					draw_rect(Rect2(point + Vector2(-4, 9), Vector2(6, 4)), Color("76d4ce"))


func coral(root: Vector2, seed_value: int) -> void:
	var color := Color("b87e92") if seed_value % 2 == 0 else Color("a9a87a")
	for branch in range(4):
		var tip := root + Vector2(branch * 5 - 7, -9 - (seed_value + branch * 7) % 17)
		draw_line(root, tip, color.darkened(0.2), 3)
		draw_rect(Rect2(tip - Vector2(3, 2), Vector2(7, 4)), color)


func plant(root: Vector2, length: float, phase: float, oxygen: bool) -> void:
	var color := Color("52e6ab") if oxygen else Color("318c79")
	var prior := root
	for i in range(1, 7):
		var point := root + Vector2(sin(game.clock * 1.3 + phase + i * 0.6) * i, -i * length / 6)
		draw_line(prior, point, color, 3)
		var side := 1 if i % 2 == 0 else -1
		draw_line(point, point + Vector2(side * 7, -4), color.lightened(0.07), 3)
		prior = point
	if oxygen:
		draw_rect(Rect2(prior - Vector2(2, 2), Vector2(4, 4)), Color("d2ffca"))


func life(area: Rect2) -> void:
	for school in range(Terrain.ROUTE.size()):
		var origin: Vector2 = Terrain.ROUTE[school] * Terrain.TILE
		for i in range(9):
			var point := (
				origin
				+ Vector2(
					sin(game.clock * 0.3 + school) * 70 + i * 14 - 65,
					cos(game.clock * 0.4 + i) * 9 + (i % 3) * 9
				)
			)
			if not area.has_point(point) or game.terrain.get_cell(game.terrain.tile_at(point)) != 0:
				continue
			var color := Color("7db6ac") if school < 4 else Color("738ed0")
			draw_rect(Rect2(point, Vector2(9, 4)), color)
			draw_colored_polygon(
				PackedVector2Array(
					[point + Vector2(-4, -2), point + Vector2(1, 2), point + Vector2(-4, 6)]
				),
				color
			)
			draw_rect(Rect2(point + Vector2(7, 0), Vector2(1, 1)), Color("dcf9ef"))
	for i in range(8):
		var point := Vector2(2100 + sin(i * 1.7) * 60, 1910 + i * 38 + sin(game.clock + i) * 9)
		if area.has_point(point):
			glow(point, 26, Color(0.5, 0.4, 1, 0.03))
			draw_arc(point, 10, PI, TAU, 10, Color("cab6ff"), 4)
			for leg in range(4):
				var end := point + Vector2(leg * 5 - 8 + sin(game.clock * 2 + leg) * 3, 18)
				draw_line(point + Vector2(leg * 5 - 8, 0), end, Color("877cca"), 1)


func glow(point: Vector2, radius: float, color: Color) -> void:
	for i in range(4, 0, -1):
		draw_circle(point, radius * i / 4, color)


func goal() -> void:
	var point: Vector2 = Terrain.GOAL
	glow(point, 160, Color(0.2, 0.7, 1, 0.035))
	for i in range(5):
		var offset := Vector2(i * 15 - 30, 20 - abs(i - 2) * 5)
		draw_rect(Rect2(point + offset, Vector2(10, 44)), Color("436774"))
		draw_rect(Rect2(point + offset, Vector2(10, 3)), BLUE)
	draw_circle(point + Vector2(0, -12), 12 + sin(game.clock * 2), BLUE)
	draw_circle(point + Vector2(0, -12), 6, Color("edfff5"))


func diver() -> void:
	var point: Vector2 = game.player.position.round()
	if game.rescuing:
		glow(point, 42, Color(0.4, 1, 1, 0.04))
		draw_arc(point, 19, 0, TAU, 24, BLUE, 2)
		return
	# Lamp and a pixel diver with tank, mask, hands and animated fins.
	glow(point, 90, Color(0.45, 0.95, 1, 0.015))
	var flip: float = game.facing
	draw_rect(Rect2(point + Vector2(-9 * flip - 2, -6), Vector2(5, 16)), Color("709b9e"))
	draw_rect(Rect2(point + Vector2(-5, -5), Vector2(10, 15)), Color("e89c62"))
	draw_rect(Rect2(point + Vector2(-5, -14), Vector2(11, 10)), Color("f5c486"))
	draw_rect(Rect2(point + Vector2(-3 + flip * 3, -11), Vector2(7, 5)), Color("b0ffff"))
	draw_rect(Rect2(point + Vector2(-5, 8), Vector2(4, 6)), Color("264d63"))
	draw_rect(Rect2(point + Vector2(2, 8), Vector2(4, 6)), Color("264d63"))
	var kick := sin(game.clock * 10) * 3 if game.player.velocity.length() > 5 else 0.0
	draw_rect(Rect2(point + Vector2(-8, 12 + kick), Vector2(7, 3)), Color("f3b46e"))
	draw_rect(Rect2(point + Vector2(2, 12 - kick), Vector2(7, 3)), Color("f3b46e"))
	if point.y > Terrain.SURFACE:
		for i in range(5):
			var rise := fmod(game.clock * 35 + i * 10, 52)
			draw_arc(
				point + Vector2(9 * flip + sin(i + rise * 0.1) * 3, -15 - rise),
				2,
				0,
				TAU,
				8,
				Color(0.6, 1, 1, 1 - rise / 52),
				1
			)
