extends SceneTree
## Local GPU comparison, never mistaken for a headless CI graphics check.
const SCENE = preload("res://game/main.tscn")


func _initialize() -> void:
	run.call_deferred()


func run() -> void:
	root.unfocusable = true
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	root.size = Vector2i(1280, 720)
	var game = SCENE.instantiate()
	game.automated_input = true
	root.add_child(game)
	await process_frame
	game.set_physics_process(false)
	game.begin()
	var scenes: Array[Dictionary] = []
	for depth in [12, 60, 155, 205, 235, 365, 140, 177, 30]:
		game.model.position = Vector3(10, -depth, -35)
		if depth == 30:
			game.model.position = Vector3(0, -30, -61)
		if depth > 200:
			game.model.position = Vector3(-55, -depth, -95)
		if depth > 300:
			game.model.position = Vector3(-27, -depth, -100)
		game.pitch = -.35
		game.yaw = 0
		if depth in [140, 177]:
			game.model.position = (
				Vector3(62, -140, -104) if depth == 140 else Vector3(81, -177, -165)
			)
			var target := Vector3(92, -181, -170) if depth == 140 else Vector3(108, -199, -217)
			var offset: Vector3 = target - game.model.position - Vector3.UP * 1.4
			game.yaw = atan2(-offset.x, -offset.z)
			game.pitch = atan2(offset.y, Vector2(offset.x, offset.z).length())
		game._update_camera()
		for warmup in range(90):
			await process_frame
			await RenderingServer.frame_post_draw
		var timings: Array[float] = []
		var draw_calls := 0.0
		for sample in range(180):
			var before := Time.get_ticks_usec()
			await process_frame
			await RenderingServer.frame_post_draw
			timings.append((Time.get_ticks_usec() - before) / 1000.0)
			draw_calls += Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)
		timings.sort()
		scenes.append(
			{
				"depth_m": depth,
				"median_frame_ms": snappedf(timings[90], .01),
				"p95_frame_ms": snappedf(timings[171], .01),
				"mean_draw_calls": roundi(draw_calls / 180)
			}
		)
	var method := RenderingServer.get_current_rendering_method()
	var report := {
		"renderer": method,
		"adapter": RenderingServer.get_video_adapter_name(),
		"resolution": "1280x720",
		"vsync": "disabled",
		"samples_per_scene": 180,
		"metric": "end-to-end render frame wall time, not isolated GPU duration",
		"scenes": scenes
	}
	var file := FileAccess.open("res://artifacts/render-%s.json" % method, FileAccess.WRITE)
	file.store_string(JSON.stringify(report, "  "))
	file.close()
	print(JSON.stringify(report))
	game.queue_free()
	await process_frame
	quit()
