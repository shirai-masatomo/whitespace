extends SceneTree
const Trial = preload("res://tests/evaluate.gd")

func _initialize():
	root.unfocusable = true
	call_deferred("run")

func capture(game, name: String):
	for i in range(8): await process_frame
	await RenderingServer.frame_post_draw
	assert(root.get_texture().get_image().save_png("res://artifacts/" + name + ".png") == OK)
	print("Captured ", name)

func mouse_click(position: Vector2):
	var event = InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.position = position
	event.pressed = true
	Input.parse_input_event(event)
	await process_frame
	event = event.duplicate()
	event.pressed = false
	Input.parse_input_event(event)
	await process_frame

func key(code: int):
	var event = InputEventKey.new()
	event.physical_keycode = code
	event.pressed = true
	Input.parse_input_event(event)
	await process_frame
	event = event.duplicate()
	event.pressed = false
	Input.parse_input_event(event)
	await process_frame

func run():
	var game = load("res://game/main.tscn").instantiate()
	game.automated = true
	root.add_child(game)
	await process_frame
	await mouse_click(game.center(Vector2(19, 8)))
	assert(game.world.keeper.placed and game.world.keeper.pos == Vector2i(19, 8))
	await mouse_click(Vector2(1050, 608))
	assert(game.world.phase == "defend" and game.world.enemies.is_empty())
	# Build a player-authored yard: no fixed central fence.
	for x in range(17, 22):
		for y in [6, 10]: await mouse_click(game.center(Vector2(x, y)))
	for y in range(7, 10):
		await mouse_click(game.center(Vector2(21, y)))
		if y != 8: await mouse_click(game.center(Vector2(17, y)))
	await mouse_click(Vector2(1155, 322))
	await mouse_click(game.center(Vector2(17, 8)))
	assert(game.world.structures.size() == 16 and game.world.structures[Vector2i(17, 8)].kind == "gate")
	await key(KEY_SPACE)
	assert(game.world.paused and game.buttons.wall.disabled and game.buttons.feed.disabled)
	var resources: int = game.world.materials
	await key(KEY_1)
	await mouse_click(game.center(Vector2(15, 8)))
	assert(game.world.materials == resources and not game.world.structures.has(Vector2i(15, 8)))
	await mouse_click(Vector2(1155, 448))
	await mouse_click(game.center(Vector2(16, 8)))
	assert(game.world.animals[0].pending.kind == "stay")
	await key(KEY_SPACE)
	await key(KEY_3)
	await mouse_click(game.center(Vector2(17, 8)))
	assert(game.world.structures[Vector2i(17, 8)].open)
	await mouse_click(Vector2(1055, 531))
	for i in range(94):
		Trial.intervene(game.world, "orders_feed")
		game.world.step()
	# Building remains available with enemies present.
	await key(KEY_1)
	await mouse_click(game.center(Vector2(15, 10)))
	assert(game.world.structures.has(Vector2i(15, 10)))
	await key(KEY_R)
	await mouse_click(game.center(game.view_positions["e0"]))
	assert(game.world.animals[0].pending.target_id == 0)
	await mouse_click(Vector2(1155, 659))
	assert(game.speed == 2)
	await capture(game, "defense")
	var captured_shot = false
	var feed_clicked = false
	while game.world.phase == "defend" and game.world.tick < 1200:
		if not feed_clicked and game.world.animals[0].stamina < 58 and game.world.foods.is_empty():
			var before: int = game.world.campaign.feed
			await key(KEY_4)
			await mouse_click(game.center(game.world.animals[0].pos))
			assert(game.world.campaign.feed == before - 1)
			feed_clicked = true
		Trial.intervene(game.world, "orders_feed")
		game.world.step()
		if game.world.keeper.carrier >= 0 and not captured_shot:
			await capture(game, "rescue")
			captured_shot = true
	assert(game.world.result == "win" and feed_clicked)
	await capture(game, "shop")
	await mouse_click(Vector2(950, 402))
	assert(game.world.campaign.animals.size() == 2)
	await mouse_click(Vector2(1155, 402))
	await mouse_click(Vector2(1050, 608))
	assert(game.world.stage == 2 and game.world.structures.is_empty() and game.world.animals.size() == 2)
	await mouse_click(game.center(Vector2(19, 8)))
	await mouse_click(Vector2(1050, 608))
	while game.world.phase == "defend" and game.world.tick < 1200:
		Trial.intervene(game.world, "combined")
		game.world.step()
	assert(game.world.result == "win")
	FileAccess.open("res://artifacts/visual-play.json", FileAccess.WRITE).store_string(JSON.stringify(game.world.observation(), "  "))
	await mouse_click(Vector2(950, 708))
	assert(game.world.phase == "prepare" and game.world.stage == 2 and not game.world.keeper.placed)
	print("PASS: native input placement/start/build/pause/orders/gate/speed/shop/stage2/retry")
	quit()
