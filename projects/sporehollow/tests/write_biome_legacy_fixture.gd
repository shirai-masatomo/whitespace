extends SceneTree
const Farm=preload("res://game/world.gd")
func _initialize():call_deferred("run")
func write(path,value):
	var f=FileAccess.open(path,FileAccess.WRITE);f.store_var(value,false);f.close()
func run():
	var out=OS.get_environment("FARM_REVIEW_OUTPUT")
	if out=="" or "--isolated-review" not in OS.get_cmdline_user_args():quit(2);return
	var w=Farm.new({},31).begin_day();w.story.intro_seen=true;w.nature_config.spawn_chance_per_second=0
	var tree=w.trees.keys()[0];w.story.cleared.append(w.trees[tree]);w.trees.erase(tree)
	var rock=w.rocks.keys()[0];w.rocks.erase(rock)
	w.natural[Vector2i(2,2)]="weed"
	w.natural[Vector2i(44,30)]="stump"
	w.Stock.add(w,"wood",7,Vector2i(4,3))
	w.act("wall",Vector2i(49,33))
	w.act("collect",Vector2i(2,2))
	w.persist_farm()
	var facts={"trees":w.trees,"rocks":w.rocks,"natural":w.natural,"field_items":w.field_items,"jobs":w.jobs,"structures":w.structures,"keeper":w.keeper,"animals":w.animals,"tick":w.tick,"calendar_ticks":w.calendar_ticks,"removed_tree":tree,"removed_rock":rock,"stock":w.Stock.totals(w)}
	write(out+"/facts.bin",facts);write(out+"/campaign.bin",w.campaign)
	if not w.Snapshot.save(w,out+"/legacy.snapshot"):quit(1);return
	print("Legacy fixture saved from selected resource pack")
	quit()
