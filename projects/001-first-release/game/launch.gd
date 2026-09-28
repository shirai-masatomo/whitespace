extends Node
## Export templates disable positional scene overrides. Select the prototype explicitly.


func _ready() -> void:
	var scene := "res://game/two_d/main.tscn"
	if "--legacy-3d" in OS.get_cmdline_user_args():
		scene = "res://game/main.tscn"
	get_tree().change_scene_to_file.call_deferred(scene)
