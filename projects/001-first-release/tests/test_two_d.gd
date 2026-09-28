extends SceneTree

const SCENE = preload("res://game/two_d/main.tscn")
const Terrain = preload("res://game/two_d/terrain.gd")
var game: Node2D
var failures := 0
var checks := 0
var elapsed := 0.0
var obstacle_game: Node2D
var obstacles: Array = []


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
	for frame in range(180):
		await tick(1, false, false)
	check(game.player.position.y > Terrain.SURFACE, "Walk from shore into the sea")
	var start_y: float = game.player.position.y
	for frame in range(30):
		await tick(0, true, false)
	check(game.player.position.y < start_y - 20, "Space swims upward")
	var before: float = game.oxygen
	for frame in range(60):
		await tick(0, false, true)
	check(before - game.oxygen > 3.5, "Fast dive consumes more oxygen")
	for point in [Vector2(58, 25), Vector2(55, 46), Vector2(64, 73)]:
		check(await swim_to(point), "Shared introduction to %s" % point)
	await mining()
	# Exhaustion loses depth; the game remains in the same scene.
	var safe: Vector2 = game.checkpoint
	for frame in range(90):
		await tick(1, false, true)
	game.oxygen = 0.01
	await tick(0, false, false)
	check(game.rescuing, "Oxygen exhaustion starts seamless rescue")
	for frame in range(600):
		await tick(0, false, false)
		if not game.rescuing:
			break
	check(
		not game.rescuing and game.player.position.distance_to(safe) < 2,
		"Rescue returns to last refill without reloading"
	)
	check(game.oxygen == 100, "Rescue restores oxygen")
	for point in [Vector2(42, 100), Vector2(35, 109), Vector2(60, 124), Vector2(37, 144)]:
		check(await swim_to(point), "Cliff / inside route %s" % point)
	check(game.encounters.air_at(game.player.position), "Swim into an air-filled cave")
	for frame in range(90):
		await tick(0, false, false)
	check(game.player.is_on_floor(), "Stand on the air cave floor")
	check(game.oxygen == 100, "Air cave is safe to breathe")
	for point in [
		Vector2(35, 145),
		Vector2(38, 152),
		Vector2(58, 179),
		Vector2(71, 194),
		Vector2(82, 192),
		Vector2(69, 203),
		Vector2(58, 227),
		Vector2(68, 234)
	]:
		check(await swim_to(point), "Terraces / fault / seafloor %s" % point)
	check(game.collected.size() == 3, "Three optional discoveries are reachable")
	check(not game.complete, "Old 330m light is no longer the end")
	await photograph("seabed")
	for point in [Vector2(77, 238), Vector2(80, 247), Vector2(73, 262)]:
		check(await swim_to(point), "Seafloor converges through the rift %s" % point)
	check(
		game.encounters.current_at(Vector2(81, 244) * 24).y > 20,
		"Gate has a physical downward current"
	)
	check(game.encounters.stage == 0, "Do not reveal the creature inside the narrows")
	await photograph("narrows")
	for point in [Vector2(78, 275), Vector2(70, 287), Vector2(74, 300), Vector2(63, 317)]:
		check(await swim_to(point), "Follow water orbs through darkness %s" % point)
	check(game.encounters.stage >= 1, "A shadow precedes the creature reveal")
	for point in [Vector2(76, 331), Vector2(70, 336)]:
		check(await swim_to(point), "Open chamber approach %s" % point)
	check(game.encounters.stage == 3, "The octopus is recognized after shadow and arms")
	await photograph("encounter")
	check(await swim_to(Vector2(58, 350)), "Reach final water sphere")
	check(not game.complete and game.depth() > 670, "Old 680m goal now leads to the wreck")
	await final_journey()
	await editor_and_interactions()
	await click_controls()
	print("2D: %d checks, failures=%d; simulated route %.1fs" % [checks, failures, elapsed])
	game.queue_free()
	await process_frame
	quit(1 if failures > 0 else 0)


func final_journey() -> void:
	for point in [
		Vector2(51, 366),
		Vector2(38, 384),
		Vector2(52, 397),
		Vector2(67, 395),
		Vector2(77, 410),
		Vector2(49, 433),
		Vector2(58, 449),
		Vector2(60, 474),
		Vector2(38, 502),
		Vector2(49, 526),
		Vector2(70, 548),
		Vector2(84, 572),
		Vector2(68, 594),
		Vector2(51, 612),
		Vector2(47, 635),
		Vector2(62, 654),
		Vector2(70, 679),
	]:
		check(await swim_to(point), "Wreck / myth route %s" % point)
	check(
		game.encounters.chest_open,
		"Approaching the tamatebako opens it without a button or loading"
	)
	for point in [
		Vector2(65, 710),
		Vector2(83, 741),
		Vector2(63, 768),
		Vector2(45, 794),
		Vector2(65, 820),
		Vector2(85, 843),
		Vector2(64, 866),
		Vector2(43, 890),
		Vector2(57, 915),
		Vector2(55, 939),
		Vector2(68, 961),
		Vector2(65, 983),
		Vector2(64, 992),
	]:
		check(await swim_to(point), "Star sea / final trench %s" % point)
	check(game.complete and game.depth() > 1950, "Surface to final ending is continuous")
	check(game.play_seconds > 300, "Ending records time spent playing")
	check(game.markers("relic").size() == 9, "Optional memories extend across the whole journey")
	check(game.terrain.get_cell(Vector2i(65, 1001)) != 0, "The deepest point has an actual floor")


func editor_and_interactions() -> void:
	var jelly = game.markers("jelly")[0]
	game.encounters.update(0)
	var before: Vector2 = game.encounters.position_of(jelly)
	game.encounters.update(1)
	check(
		before.distance_to(game.encounters.position_of(jelly)) > 10, "Jelly platform actually moves"
	)
	game.encounters.stage = 3
	var animal = game.markers("octopus")[0]
	var arm: Vector2 = animal.global_position + Vector2(-260, -170 + sin(game.clock) * 40)
	check(game.encounters.current_at(arm).x < -30, "A nearby tentacle produces an escapable surge")
	var other = SCENE.instantiate()
	other.automated = true
	var algae = other.get_node("OceanLayout/Landmarks/Algae0")
	algae.position += Vector2(48, 24)
	var saved: Vector2 = algae.position
	root.add_child(other)
	await physics_frame
	check(algae.position == saved, "Editor marker Transform is not overwritten")
	other.player.position = algae.global_position
	other.oxygen = 10
	other.step(1.0 / 60, 0, false, false)
	check(other.oxygen == 100, "Moved algae refill at the saved position")
	var original_game := game
	game = other
	var platform = game.markers("jelly")[0]
	game.player.position = game.encounters.position_of(platform) + Vector2(0, -90)
	game.player.velocity = Vector2.ZERO
	var grounded_frames := 0
	for frame in range(150):
		await tick(0, false, false)
		if game.player.is_on_floor():
			grounded_frames += 1
	check(grounded_frames > 40, "Land on and ride a moving jelly platform")
	game.player.position = Vector2(64, 73) * 24
	game.player.velocity = Vector2.ZERO
	game.oxygen = 100
	for point in [Vector2(75, 103), Vector2(60, 124), Vector2(69, 155), Vector2(58, 179)]:
		check(await swim_to(point), "Outside route is also playable %s" % point)
	game = original_game
	other.queue_free()
	await process_frame


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
			# Consecutive route samples only need their local corridor, not all prior layers.
			if (
				next.y < mini(from.y, destination.y) - 35
				or next.y > maxi(from.y, destination.y) + 35
			):
				continue
			if previous.has(next) or not clear_cell(next):
				continue
			previous[next] = current
			open.append(next)
	if not previous.has(destination):
		print("No clear path from ", from, " to ", destination)
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
			var flow: Vector2 = game.encounters.current_at(game.player.position)
			await tick(
				clampf(difference.x / 16, -1, 1),
				difference.y < -3,
				flow.y < -40 and difference.y > 3
			)
			if game.rescuing:
				return false
		if not arrived:
			print("Stuck: ", game.player.position, " target ", point)
			return false
	return true


func clear_cell(at: Vector2i) -> bool:
	if (
		game.terrain.get_cell(at) != 0
		or game.terrain.get_cell(at + Vector2i.UP) != 0
		or game.terrain.get_cell(at + Vector2i.DOWN) != 0
	):
		return false
	if obstacle_game != game:
		obstacle_game = game
		obstacles = game.markers("rock") + game.markers("jelly")
	var point := (Vector2(at) + Vector2(0.5, 0.5)) * Terrain.TILE
	for marker in obstacles:
		if marker.kind in ["rock", "jelly"]:
			var margin: Vector2 = marker.extent + Vector2(10, 15)
			if marker.kind == "jelly":
				margin += marker.travel.abs()
			if Rect2(marker.global_position - margin, margin * 2).has_point(point):
				return false
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


func click_controls() -> void:
	# Local water fixture with a solid wall; use real CharacterBody2D and mouse events.
	game.complete = false
	game.paused = false
	game.rescuing = false
	for y in range(20, 46):
		for x in range(80, 106):
			game.terrain.set_cell(Vector2i(x, y), 1 if x == 100 else 0)
		game.rebuild_row(y)
	game.player.position = Vector2(90, 33) * 24
	game.player.velocity = Vector2.ZERO
	game.oxygen = 60
	await physics_frame
	game.camera.position = game.player.position + Vector2(0, 85)
	game.camera.force_update_scroll()
	var destination: Vector2 = game.player.position + Vector2(120, -90)
	await mouse_at(destination)
	check(game.click_swim.active, "A real left click starts swimming")
	check(
		game.click_swim.target.distance_to(destination) < 1, "Click respects camera world transform"
	)
	for frame in range(300):
		await physics_frame
		game.control_step(1.0 / 60.0, 0, false, false)
		if not game.click_swim.active:
			break
	check(
		game.player.position.distance_to(destination) < 15,
		"Click swims sideways and upward to target"
	)
	check(not game.click_swim.active, "Arrival ends the click command")
	check(game.oxygen < 60, "Click swimming consumes oxygen")
	var start_y: float = game.player.position.y
	for frame in range(30):
		await physics_frame
		game.control_step(1.0 / 60.0, 0, false, false)
	check(game.player.position.y > start_y, "Natural sinking resumes after arrival")
	await mouse_at(game.player.position + Vector2(25, 85))
	for frame in range(200):
		await physics_frame
		game.control_step(1.0 / 60.0, 0, false, false)
		if not game.click_swim.active:
			break
	check(
		game.player.position.distance_to(game.click_swim.target) < 15,
		"Click also descends to target"
	)
	await mouse_at(Vector2(103, 34) * 24)
	for frame in range(400):
		await physics_frame
		game.control_step(1.0 / 60.0, 0, false, false)
		if not game.click_swim.active:
			break
	check(game.player.position.x < 2400, "Click cannot cross a solid wall")
	check(not game.click_swim.active, "Blocked click cancels instead of pushing forever")
	await mouse_at(game.player.position - Vector2(90, 50))
	game.control_step(1.0 / 60.0, -1, false, false)
	check(not game.click_swim.active, "Keyboard immediately overrides click")
	await mouse_at(game.player.position - Vector2(30, 30), true)
	check(
		not game.click_swim.active and game.tool_button == 1,
		"Shift click selects digging, not movement"
	)
	var release := InputEventMouseButton.new()
	release.button_index = MOUSE_BUTTON_LEFT
	release.pressed = false
	root.push_input(release, true)
	Input.flush_buffered_events()
	await process_frame
	check(game.tool_button == 0, "Mouse release clears the mining tool")
	var map_click := InputEventMouseButton.new()
	map_click.button_index = MOUSE_BUTTON_LEFT
	map_click.pressed = true
	map_click.position = Vector2(root.get_visible_rect().size.x - 80, 140)
	root.push_input(map_click, true)
	Input.flush_buffered_events()
	await process_frame
	check(not game.click_swim.active, "Depth map consumes clicks without steering")
	game.click_swim.request(game.player.position - Vector2(60, 0))
	game.start_rescue()
	check(not game.click_swim.active, "Rescue clears click destination")
	var map = load("res://game/two_d/depth_map.gd")
	check(map.progress(240, game.goal_position().y) == 0, "Depth map starts at sea surface")
	check(
		map.progress(game.goal_position().y, game.goal_position().y) == 1,
		"Depth map uses actual goal"
	)
	check(
		is_equal_approx(
			map.progress((240 + game.goal_position().y) / 2, game.goal_position().y), 0.5
		),
		"Map midpoint is half the journey"
	)


func mouse_at(world: Vector2, shift: bool = false) -> void:
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = true
	event.shift_pressed = shift
	event.position = game.get_canvas_transform() * world
	root.push_input(event, true)
	Input.flush_buffered_events()
	await process_frame
