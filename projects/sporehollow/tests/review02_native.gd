extends SceneTree
const Farm=preload("res://game/world.gd")
func _initialize():call_deferred("start")
func start():
	if OS.get_environment("FARM_REVIEW_OUTPUT")=="" or "--isolated-review" not in OS.get_cmdline_user_args():quit(2);return
	root.size=Vector2i(1280,800);root.title="Whistle Ranch - Review02 PRIVATE"
	if not FileAccess.file_exists("user://colony.snapshot"):
		var w=Farm.new({},31).begin_day();w.story.intro_seen=true;w.paused=true;w.enemies.clear();w.spawn_schedule.clear();w.natural.clear();w.trees.clear();w.rocks.clear();w.structures.clear();w.floors.clear();w.field_items.clear();w.jobs.clear();w.zones=[];w.storage_cells=[];w.keeper.pos=Vector2i(24,17);w.keeper.satiety=100;w.keeper.sleepiness=0;w.nature_config.spawn_chance_per_second=0
		for a in w.animals:a.pos=Vector2i(27,17);a.home=a.pos;a.mode="stay"
		w.Stock.add(w,"soil",40,Vector2i(23,17));w.Stock.add(w,"mushroom",3,Vector2i(23,18));w.Snapshot.save(w,"user://colony.snapshot")
	var g=load("res://game/main.tscn").instantiate();root.add_child(g)
