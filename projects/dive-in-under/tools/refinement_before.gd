extends SceneTree
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var game: Control=load("res://ui/main.tscn").instantiate()
	root.add_child(game); await process_frame
	var script_path: String=""
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--review-dir="): game.smoke_dir=arg.trim_prefix("--review-dir=")
		if arg.begins_with("--review-run-id="): game.smoke_run_id=arg.trim_prefix("--review-run-id=")
		if arg.begins_with("--review-script="): script_path=arg.trim_prefix("--review-script=")
	await load(script_path).run(game,true)
