extends RefCounted
## Local landmarks make the layer contrast visible without a stage-gate overlay.


static func paint(art: Node2D, game: Node2D, area: Rect2) -> void:
	for marker in game.markers():
		var point: Vector2 = game.encounters.position_of(marker)
		if not area.grow(500).has_point(point):
			continue
		match marker.kind:
			"bubble":
				art.glow(point, 120, Color(0.3, 0.8, 1, 0.04))
				art.draw_circle(point, marker.extent.x, Color(0.45, 0.8, 0.9, 0.09))
				art.draw_arc(point, marker.extent.x, 0, TAU, 48, Color("7fd7d9"), 2)
				art.draw_arc(point, marker.extent.x - 7, PI * 1.1, PI * 1.6, 16, Color("bdfff1"), 3)
			"orb":
				var radius := 17 + sin(game.clock * 1.5 + point.y) * 2
				art.glow(point, 130, Color(0.15, 0.5, 1, 0.055))
				art.draw_circle(point, radius, Color("5fadd9"))
				art.draw_arc(point, radius - 3, -PI * 0.8, 0.3, 18, Color("c3faff"), 3)
				art.draw_circle(point + Vector2(-4, -5), 4, Color("edfff8"))
			"air":
				art.draw_rect(Rect2(point - marker.extent, marker.extent * 2), Color("334749"))
				var bottom: float = point.y + marker.extent.y
				art.draw_line(
					Vector2(point.x - marker.extent.x, bottom),
					Vector2(point.x + marker.extent.x, bottom),
					Color("a2e7cb"),
					3
				)
				art.glow(point, 100, Color(0.95, 0.8, 0.5, 0.025))
			"current":
				current(art, game, marker)
			"rock":
				art.draw_set_transform(point, marker.global_rotation, marker.global_scale)
				point = Vector2.ZERO
				art.draw_rect(Rect2(point - marker.extent, marker.extent * 2), Color("766546"))
				for i in range(4):
					art.draw_line(
						point + Vector2(-marker.extent.x + 8, i * 4 - 8),
						point + Vector2(marker.extent.x - 8, i * 4 - 8),
						Color("aa9766"),
						1
					)
				art.draw_set_transform(Vector2.ZERO)
			"jelly":
				art.draw_set_transform(point, marker.global_rotation, marker.global_scale)
				jelly(art, game, marker, Vector2.ZERO)
				art.draw_set_transform(Vector2.ZERO)
			"octopus":
				octopus(art, game, point)


static func current(art: Node2D, game: Node2D, marker: Node2D) -> void:
	var center: Vector2 = marker.global_position
	for i in range(50):
		var local := Vector2(
			fposmod(i * 67.3 + game.clock * marker.flow.x, marker.extent.x * 2) - marker.extent.x,
			fposmod(i * 47.1 + game.clock * marker.flow.y, marker.extent.y * 2) - marker.extent.y
		)
		var point: Vector2 = marker.to_global(local)
		if game.terrain.get_cell(game.terrain.tile_at(point)) != 0:
			continue
		var color := (
			Color(0.75, 0.78, 0.59, 0.65) if center.y > 5300 else Color(0.5, 0.85, 0.9, 0.4)
		)
		var direction: Vector2 = marker.global_transform.basis_xform(marker.flow).normalized()
		art.draw_line(point, point + direction * 9, color, 1)
		if i % 6 == 0:
			art.draw_arc(point, 3, 0, TAU, 8, color, 1)
	if center.y > 5300:
		for i in range(6):
			var base := center + Vector2(-130 + i * 43, 70)
			var tile: Vector2i = game.terrain.tile_at(base)
			var found := false
			for offset in range(-3, 7):
				var at := tile + Vector2i(0, offset)
				if game.terrain.get_cell(at) != 0 and game.terrain.get_cell(at + Vector2i.UP) == 0:
					base.y = at.y * 24
					found = true
					break
			if not found:
				continue
			art.draw_line(
				base, base + marker.flow.normalized() * 25 + Vector2(0, -16), Color("365d58"), 3
			)


static func jelly(art: Node2D, game: Node2D, marker: Node2D, point: Vector2) -> void:
	art.glow(point, 76, Color(0.55, 0.25, 0.85, 0.025))
	art.draw_rect(Rect2(point - marker.extent, marker.extent * 2), Color("9a8aba"))
	art.draw_arc(point, marker.extent.x, PI, TAU, 20, Color("cab5e2"), 6)
	for leg in range(7):
		var start := point + Vector2(leg * 12 - 36, 8)
		var middle := start + Vector2(sin(game.clock * 2 + leg) * 8, 26)
		art.draw_line(start, middle, Color("8c79c5"), 2)
		art.draw_line(middle, middle + Vector2(cos(game.clock + leg) * 10, 20), Color("6e72a8"), 2)


static func octopus(art: Node2D, game: Node2D, point: Vector2) -> void:
	if game.encounters.stage == 0:
		return
	var reveal := smoothstep(620, 666, game.depth())
	var body := Color("12152b").lerp(Color("674359"), reveal)
	var limb := Color("171c37").lerp(Color("583b53"), reveal)
	var sway := sin(game.clock * 0.35) * 12
	for arm in range(8):
		var start := point + Vector2(-50 + arm * 12, 60)
		var end := point + Vector2(-350 + arm * 79, 110 + sin(arm * 1.7) * 200)
		if arm == 0:
			end = point + Vector2(-260, -170 + sin(game.clock) * 40)
		var previous := start
		var suckers := PackedVector2Array()
		for part in range(25):
			var t := part / 24.0
			var joint := (
				start.lerp(end, t)
				+ Vector2(
					sin(t * PI) * (arm - 4) * 12, sin(t * TAU + game.clock * 0.8 + arm) * t * 30
				)
			)
			joint = joint.snapped(Vector2(3, 3))
			var width := lerpf(34, 3, t)
			art.draw_line(previous, joint, limb, width)
			art.draw_circle(joint, width * 0.5, limb)
			previous = joint
			if part % 3 == 0:
				suckers.append(joint + Vector2(0, 5))
		if game.encounters.stage >= 3:
			for sucker in suckers:
				art.draw_circle(sucker, 3, Color("976179").darkened(1 - reveal))
	art.draw_set_transform(point + Vector2(0, sway), 0, Vector2(0.85, 1.3))
	art.draw_circle(Vector2(0, -35), 95, body)
	art.draw_circle(Vector2(12, -50), 67, body.lightened(0.025 * reveal))
	for spot in range(14):
		var local := Vector2(sin(spot * 7.3) * 58, -80 + fmod(spot * 23.1, 120))
		art.draw_circle(local, 4 + spot % 6, body.darkened(0.18))
	art.draw_set_transform(Vector2.ZERO)
	if game.encounters.stage >= 3:
		for eye in [-1, 1]:
			var at := point + Vector2(eye * 42, 15 + sway)
			art.draw_circle(at, 12, Color("b7a269"))
			art.draw_rect(Rect2(at + Vector2(-8, -2), Vector2(16, 5)), Color("131b29"))
