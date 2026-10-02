extends SceneTree
const Trial = preload("res://tests/evaluate.gd")

func _initialize():
	root.unfocusable = true
	call_deferred("run")

func capture(game, name: String):
	for i in range(6): await process_frame
	await RenderingServer.frame_post_draw
	var error = root.get_texture().get_image().save_png("res://artifacts/" + name + ".png")
	assert(error == OK)
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

func run():
	var game = load("res://game/main.tscn").instantiate()
	game.automated = true
	root.add_child(game)
	await process_frame
	# Use Godot's input dispatch, not desktop mouse/focus automation.
	await mouse_click(game.center(Vector2(17, 8)))
	assert(game.world.animals[0].pos == Vector2i(17, 8))
	await mouse_click(Vector2(1050, 608))
	assert(game.world.phase == "defend")
	await mouse_click(game.center(Vector2(15, 5)))
	assert(game.world.metrics.commands == 2)
	for i in range(80):
		Trial.intervene(game.world, "care")
		game.world.step()
	await mouse_click(Vector2(1050, 405))
	var food_before = game.world.campaign.feed
	await mouse_click(game.center(Vector2(game.world.animals[0].pos)))
	assert(game.world.campaign.feed == food_before - 1)
	await mouse_click(Vector2(1050, 450))
	await mouse_click(game.center(Vector2(12, 5)))
	assert(not game.world.gate_open[0])
	await capture(game, "defense")
	while game.world.result == "":
		Trial.intervene(game.world, "care")
		game.world.step()
	assert(game.world.result == "win")
	await capture(game, "shop")
	await mouse_click(Vector2(944, 400))
	assert(game.world.campaign.animals.size() == 2)
	await mouse_click(Vector2(1142, 400))
	await mouse_click(Vector2(1050, 608))
	assert(game.world.stage == 2 and game.world.animals.size() == 2)
	await mouse_click(game.center(Vector2(17, 8)))
	await mouse_click(Vector2(1050, 608))
	for i in range(96):
		Trial.intervene(game.world, "gates")
		game.world.step()
	await capture(game, "stage2")
	while game.world.result == "":
		Trial.intervene(game.world, "gates")
		game.world.step()
	FileAccess.open("res://artifacts/visual-play.json", FileAccess.WRITE).store_string(JSON.stringify(game.world.observation(), "  "))
	print("Native input playthrough: ", game.world.result)
	await mouse_click(Vector2(949, 709))
	assert(game.world.phase == "prepare" and game.world.stage == 2)
	quit()
