extends SceneTree

const SCENE = preload("res://game/two_d/main.tscn")
const Terrain = preload("res://game/two_d/terrain.gd")
var game: Node2D
var failures := 0
var checks := 0
var elapsed := 0.0


func _initialize() -> void:
	call_deferred("run")


func check(condition: bool, label: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		print("FAIL: " + label)


func run() -> void:
	root.unfocusable = true
	game = SCENE.instantiate()
	game.automated = true
	root.add_child(game)
	await physics_frame
	await physics_frame
	# Walk off the shore using the same controller as the real player.
	for frame in range(180):
		await tick(1, false, false)
	check(game.player.position.y > Terrain.SURFACE, "Walk from shore into the sea")
	await photograph("entry")
	var start_y: float = game.player.position.y
	for frame in range(30):
		await tick(0, true, false)
	check(game.player.position.y < start_y - 20, "Space swims upward")
	var before: float = game.oxygen
	for frame in range(60):
		await tick(0, false, true)
	check(before - game.oxygen > 3.5, "Fast dive consumes more oxygen")
	for target in [
		Vector2(58, 25),
		Vector2(52, 45),
		Vector2(30, 62),
		Vector2(32, 65),
		Vector2(47, 87),
		Vector2(63, 109)
	]:
		check(await swim_to(target), "Continuous input route to %s" % target)
		if failures > 0:
			break
	check(game.collected.has(0), "Optional cave relic is collected by contact")
	check(game.oxygen > 95, "Algae refill instantly")
	await photograph("cave")
	await mining()
	# A meaningful failure after leaving a safe spot; movement retraces recorded passage.
	var safe: Vector2 = game.checkpoint
	for frame in range(90):
		await tick(0, false, true)
	game.oxygen = 0.01
	await tick(0, false, false)
	check(game.rescuing, "Oxygen exhaustion starts seamless rescue")
	for frame in range(600):
		await tick(0, false, false)
		if not game.rescuing:
			break
	check(
		not game.rescuing and game.player.position.distance_to(safe) < 2,
		"Rescue returns to the last algae without reloading"
	)
	check(game.oxygen == 100, "Rescue restores oxygen")
	for target in [Vector2(48, 132), Vector2(65, 151), Vector2(58, 174), Vector2(58, 176)]:
		check(await swim_to(target), "Deep route to %s" % target)
	check(game.complete, "The final light completes the dive")
	print("2D: %d checks, failures=%d; simulated route %.1fs" % [checks, failures, elapsed])
	game.queue_free()
	await process_frame
	quit(1 if failures > 0 else 0)


func tick(horizontal: float, ascend: bool, dive: bool) -> void:
	await physics_frame
	game.step(1.0 / 60, horizontal, ascend, dive)
	elapsed += 1.0 / 60


func swim_to(tile: Vector2) -> bool:
	var from: Vector2i = game.terrain.tile_at(game.player.position)
	var destination := Vector2i(tile)
	var open: Array[Vector2i] = [from]
	var previous := {from: from}
	var cursor := 0
	while cursor < open.size() and not previous.has(destination):
		var current := open[cursor]
		cursor += 1
		for direction in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			var next: Vector2i = current + direction
			if previous.has(next) or not clear_cell(next):
				continue
			previous[next] = current
			open.append(next)
	if not previous.has(destination):
		return false
	var path: Array[Vector2i] = [destination]
	while path.back() != from:
		path.append(previous[path.back()])
	path.reverse()
	for cell in path:
		var point := (Vector2(cell) + Vector2(0.5, 0.5)) * Terrain.TILE
		var arrived := false
		for frame in range(150):
			if game.complete:
				return true
			var difference: Vector2 = point - game.player.position
			if difference.length() < 18:
				arrived = true
				break
			await tick(clampf(difference.x / 16, -1, 1), difference.y < -3, false)
			if game.rescuing:
				return false
		if not arrived:
			print("Stuck: ", game.player.position, " target ", point)
			return false
	return true


func clear_cell(at: Vector2i) -> bool:
	return (
		game.terrain.get_cell(at) == 0
		and game.terrain.get_cell(at + Vector2i.UP) == 0
		and game.terrain.get_cell(at + Vector2i.DOWN) == 0
	)


func mining() -> void:
	# Local fixture: real static-body landing, then remove/add a reachable collision tile.
	var saved: Vector2 = game.player.position
	game.player.position = Vector2(50.5, 40) * Terrain.TILE
	game.player.velocity = Vector2.ZERO
	for frame in range(90):
		await tick(0, false, true)
	check(game.player.is_on_floor(), "High-speed dive lands on a tile shelf")
	var at := Vector2i(50, 42)
	check(
		game.edit_tile((Vector2(at) + Vector2.ONE * 0.5) * Terrain.TILE, false), "Dig a nearby tile"
	)
	check(game.terrain.get_cell(at) == 0 and game.stones == 1, "Dig updates terrain and inventory")
	for frame in range(60):
		await tick(0, false, false)
	check(game.player.position.y > 42 * Terrain.TILE, "Removed rock no longer collides")
	var place: Vector2 = game.player.position + Vector2(-65, 65)
	check(game.edit_tile(place, true), "Place the collected stone beside the player")
	check(game.stones == 0, "Building spends inventory")
	check(not game.edit_tile(game.player.position, true), "Cannot build inside the diver")
	var placed_cell: Vector2i = game.terrain.tile_at(place)
	game.player.position = (Vector2(placed_cell) + Vector2(0.5, -3)) * Terrain.TILE
	game.player.velocity = Vector2.ZERO
	for frame in range(90):
		await tick(0, false, true)
	check(game.player.is_on_floor(), "A placed stone has real landing collision")
	game.player.position = saved
	game.player.velocity = Vector2.ZERO
	game.breadcrumbs.clear()


func photograph(label: String) -> void:
	if DisplayServer.get_name() == "headless" or "--capture-2d" not in OS.get_cmdline_user_args():
		return
	for frame in range(20):
		await process_frame
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute("res://artifacts/two-d")
	root.get_texture().get_image().save_png("res://artifacts/two-d/" + label + ".png")
