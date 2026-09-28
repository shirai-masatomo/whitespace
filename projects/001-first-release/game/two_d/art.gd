extends Node2D
## Original code-drawn pixel art; no Terraria assets or copied world layout.

const Journey = preload("res://game/two_d/journey.gd")
const Phenomena = preload("res://game/two_d/phenomena.gd")
const Atmosphere = preload("res://game/two_d/atmosphere.gd")
const Terrain = preload("res://game/two_d/terrain.gd")
const BLUE := Color("8cf4ef")
const GOLD := Color("ffcf85")

var game: Node2D
var glow_texture: ImageTexture


func _ready() -> void:
	var source := Image.create(64, 64, false, Image.FORMAT_RGBA8)
	for y in range(64):
		for x in range(64):
			var distance := Vector2(x - 31.5, y - 31.5).length() / 31.5
			var alpha := pow(maxf(0.0, 1.0 - distance), 2.4)
			source.set_pixel(x, y, Color(1, 1, 1, alpha))
	glow_texture = ImageTexture.create_from_image(source)


func _draw() -> void:
	var inverse := get_canvas_transform().affine_inverse()
	var visible := Rect2(inverse * Vector2.ZERO, get_viewport_rect().size / game.camera.zoom)
	background(visible)
	land(visible)
	life(visible)
	Phenomena.paint(self, game, visible)
	Journey.decorate(self, game, visible)
	for garden in game.markers("algae"):
		var point: Vector2 = garden.global_position
		if visible.grow(100).has_point(point):
			if Journey.layer(point.y) == 4:
				Journey.lotus(self, point, game.clock)
				continue
			glow(point, 130, Color(0.12, 0.85, 0.61, 0.075))
			glow(point + Vector2(0, 10), 48, Color(0.4, 1, 0.7, 0.07))
			for strand in range(7):
				var root := point + Vector2((strand - 3) * 7, 30)
				plant(root, 37 + (strand * 7) % 24, strand, true)
			for bubble in range(6):
				var rise := fmod(game.clock * 23 + bubble * 14, 88)
				Atmosphere.bubble(
					self,
					point + Vector2(sin(rise * 0.09 + bubble) * 22, 20 - rise),
					2 + bubble % 3,
					Color(0.45, 1, 0.88, 0.6 * (1 - rise / 105))
				)
	for index in range(game.markers("relic").size()):
		var point: Vector2 = game.markers("relic")[index].global_position
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
	Atmosphere.motes(self, game, visible)
	diver()
	if game.started and not game.paused and not game.complete:
		var at: Vector2i = game.terrain.tile_at(get_global_mouse_position())
		var rect := Rect2(Vector2(at) * Terrain.TILE, Vector2.ONE * Terrain.TILE)
		if game.player.position.distance_to(rect.get_center()) <= 115:
			draw_rect(rect, Color(0.8, 1, 1, 0.6), false, 1)


func background(area: Rect2) -> void:
	Atmosphere.water(self, game, area)
	# Background geology is darker and displaced to give the cave a second depth plane.
	for i in range(18):
		var x := i * 240.0 + sin(i * 6.7) * 70
		var top := 350 + fmod(i * 263.0, 840)
		var peak := Vector2(x, top)
		draw_colored_polygon(
			PackedVector2Array(
				[
					peak + Vector2(-120, 6000),
					peak + Vector2(-60, 80),
					peak,
					peak + Vector2(44, 170),
					peak + Vector2(120, 6000)
				]
			),
			Color(0.025, 0.10, 0.20, 0.33)
		)

	Journey.background(self, game, area)


func land(area: Rect2) -> void:
	var lamps: Array[Vector2] = []
	for marker in game.markers("orb"):
		if area.grow(160).has_point(marker.global_position):
			lamps.append(marker.global_position)
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
				if y > 220:
					color = Color("968c72").lightened(float(hash_value % 5) * 0.015)
			if cell == 1:
				color = Color("253743")
			if cell == 4:
				color = Color("485958").darkened(float(hash_value % 4) * 0.025)
			elif cell == 5:
				color = Color("345158").lightened(float(hash_value % 4) * 0.02)
			elif cell == 6:
				color = Color("302d4c").lightened(float(hash_value % 4) * 0.025)
			if y > 245:
				var light := clampf(1 - point.distance_to(game.player.position) / 650, 0.16, 0.75)
				color = color.darkened(1 - light)
				for lamp in lamps:
					var falloff := pow(maxf(0, 1 - point.distance_to(lamp) / 170), 2)
					color = color.lerp(Color("235769"), falloff * 0.5)
			draw_rect(Rect2(point, Vector2.ONE * Terrain.TILE), color)
			draw_rect(
				Rect2(point + Vector2(3 + hash_value % 8, 7), Vector2(9, 2)), color.lightened(0.04)
			)
			if cell == 4 and hash_value % 2 == 0:
				draw_rect(Rect2(point + Vector2(2, 2), Vector2(3, 3)), color.lightened(0.12))
				draw_rect(Rect2(point + Vector2(19, 19), Vector2(3, 3)), color.darkened(0.2))
			if cell == 3:
				for grain in range(3):
					var offset := Vector2(
						(hash_value + grain * 7) % 21, (hash_value * 3 + grain * 11) % 20
					)
					draw_rect(Rect2(point + offset, Vector2(2, 1)), color.lightened(0.11))
			if hash_value % 3 == 0 and cell not in [3, 4]:
				draw_line(point + Vector2(16, 0), point + Vector2(8, 10), color.darkened(0.25), 1)
			if game.terrain.get_cell(at + Vector2i.UP) == 0:
				draw_rect(Rect2(point, Vector2(24, 3)), color.lightened(0.18))
				if y < 55 and hash_value % 3 == 0:
					var glint := 0.09 + sin(game.clock * 1.4 + x * 0.6) * 0.07
					draw_rect(
						Rect2(point + Vector2(3, 0), Vector2(12, 2)), Color(0.5, 1, 0.87, glint)
					)
				if y > 12 and y < 239 and hash_value % 3 == 0:
					plant(point + Vector2(10, 0), 20 + hash_value % 40, x, false)
				elif y > 15 and y < 239 and hash_value % 4 == 0:
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
		var point := (
			(root + Vector2(sin(game.clock * 1.3 + phase + i * 0.6) * i, -i * length / 6))
			. snapped(Vector2(2, 2))
		)
		draw_line(prior, point, color.darkened(0.2), 4)
		draw_line(prior - Vector2(1, 0), point - Vector2(1, 0), color, 2)
		var side := 1 if i % 2 == 0 else -1
		draw_line(point, point + Vector2(side * 7, -4), color.lightened(0.07), 3)
		prior = point
	if oxygen:
		draw_rect(Rect2(prior - Vector2(2, 2), Vector2(4, 4)), Color("d2ffca"))


func life(area: Rect2) -> void:
	for school in range(game.terrain.route.size()):
		var origin: Vector2 = game.terrain.route[school] * Terrain.TILE
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
	var tint := color
	tint.a = minf(color.a * 9.0, 0.8)
	draw_texture_rect(
		glow_texture, Rect2(point - Vector2.ONE * radius, Vector2.ONE * radius * 2), false, tint
	)


func goal() -> void:
	var point: Vector2 = game.goal_position()
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
	if point.y > Terrain.SURFACE and not game.encounters.air_at(point):
		for i in range(5):
			var rise := fmod(game.clock * 35 + i * 10, 52)
			Atmosphere.bubble(
				self,
				point + Vector2(9 * flip + sin(i + rise * 0.1) * 3, -15 - rise),
				2 + i % 2,
				Color(0.6, 1, 1, 0.75 * (1 - rise / 52))
			)
