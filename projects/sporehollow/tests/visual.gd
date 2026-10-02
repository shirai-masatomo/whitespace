extends SceneTree
const Trial = preload("res://tests/evaluate.gd")

func _initialize():
	root.unfocusable = true
	call_deferred("run")

func capture(name: String):
	for i in range(8): await process_frame
	await RenderingServer.frame_post_draw
	assert(root.get_texture().get_image().save_png("res://artifacts/" + name + ".png") == OK)
	print("Captured ", name)

func mouse(position: Vector2, button: int = MOUSE_BUTTON_LEFT):
	var event = InputEventMouseButton.new()
	event.button_index = button
	event.position = position
	event.pressed = true
	Input.parse_input_event(event)
	await process_frame
	event = event.duplicate()
	event.pressed = false
	Input.parse_input_event(event)
	await process_frame

func click_button(game, id: String):
	await mouse(game.buttons[id].get_global_rect().get_center())

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
	await mouse(game.center(Vector2(19, 8)))
	await click_button(game, "advance")
	assert(game.world.phase == "defend" and game.world.materials == 100)
	for cell in [Vector2(17, 7), Vector2(17, 9), Vector2(18, 6)]: await mouse(game.center(cell))
	game.world.step()
	game.world.step()
	assert(game.world.structures[Vector2i(17, 7)].status == "building")
	await capture("construction")
	await mouse(Vector2(300, 300), MOUSE_BUTTON_WHEEL_DOWN)
	assert(game.tool == "build_gate")
	await mouse(game.center(Vector2(5, 12)))
	assert(game.world.materials == 10)
	await key(KEY_SPACE)
	assert(game.world.paused and not game.buttons.wall.disabled)
	await click_button(game, "repair")
	await mouse(game.center(Vector2(17, 7)))
	await click_button(game, "wall")
	await mouse(game.center(Vector2(12, 8)))
	assert(game.world.materials == 10 and not game.world.structures.has(Vector2i(12, 8)))
	await click_button(game, "stay")
	await mouse(game.center(Vector2(18, 8)))
	assert(game.world.animals[0].pending.kind == "stay")
	await mouse(Vector2(300, 300), MOUSE_BUTTON_RIGHT)
	assert(game.tool == "")
	await mouse(Vector2(300, 300), MOUSE_BUTTON_WHEEL_DOWN)
	assert(game.tool == "wall")
	await click_button(game, "auto")
	await key(KEY_SPACE)
	for i in range(4): game.world.step()
	await click_button(game, "gate")
	await mouse(game.center(Vector2(5, 12)))
	assert(game.world.structures[Vector2i(5, 12)].open)
	# Controlled damaged facility fixture exercises repair through native input.
	game.world.structures[Vector2i(17, 7)].hp = 3
	await key(KEY_7)
	await mouse(game.center(Vector2(17, 7)))
	assert(game.world.structures[Vector2i(17, 7)].hp == 7 and game.world.materials == 0)
	var retreat_clicked = false
	var attack_clicked = false
	while game.world.phase == "defend" and game.world.tick < 1200:
		if not game.world.enemies.is_empty():
			var e = game.world.enemies[0]
			if not retreat_clicked and e.counter_target >= 0:
				await key(KEY_Q)
				await mouse(game.center(game.world.animals[0].pos + Vector2i(0, 5)))
				assert(game.world.animals[0].pending.kind == "whistle")
				retreat_clicked = true
				await capture("defense")
			elif retreat_clicked and not attack_clicked and e.counter_target < 0:
				await key(KEY_R)
				await mouse(game.center(game.view_positions["e0"]))
				assert(game.world.animals[0].pending.target_id == 0)
				attack_clicked = true
		Trial.intervene(game.world, "orders")
		game.world.step()
		await process_frame
	assert(game.world.result == "win" and retreat_clicked and attack_clicked)
	await capture("shop")
	var facilities = game.world.campaign.facilities.duplicate(true)
	await click_button(game, "soil")
	assert(game.world.materials == 50)
	await click_button(game, "hen")
	assert(game.world.campaign.animals.size() == 2)
	await click_button(game, "advance")
	assert(game.world.stage == 2 and game.world.campaign.facilities == facilities and game.world.materials == 50)
	await mouse(game.center(Vector2(19, 8)))
	await click_button(game, "advance")
	await click_button(game, "speed")
	assert(game.speed == 2 and game.world.animals.size() == 2)
	FileAccess.open("res://artifacts/visual-play.json", FileAccess.WRITE).store_string(JSON.stringify(game.world.observation(), "  "))
	await click_button(game, "retry")
	assert(game.world.phase == "prepare" and game.world.stage == 2 and game.world.campaign.facilities == facilities)
	print("PASS: native placement, wheel, build progress, pause restrictions, repair, gate, combat orders, shop, persisted Stage2, retry")
	quit()
