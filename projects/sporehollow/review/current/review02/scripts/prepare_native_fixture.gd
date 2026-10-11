extends SceneTree
const Farm=preload("res://game/world.gd")
func _initialize():
	var out=OS.get_environment("FARM_REVIEW_OUTPUT")
	if out=="" or "--isolated-review" not in OS.get_cmdline_user_args():quit(2);return
	var w=Farm.new({},31).begin_day();w.story.intro_seen=true;w.trees.clear();w.natural.clear();w.field_items.clear();w.structures.clear();w.floors.clear();w.jobs.clear();w.enemies.clear();w.spawn_schedule.clear();w.keeper.pos=Vector2i(10,10);w.keeper.satiety=100;w.keeper.sleepiness=0;w.paused=false;w.nature_config.spawn_chance_per_second=0
	var z=w.Zones.create(w,"stockpile",Vector2i(12,10),Vector2i(14,10));w.Stock.add(w,"soil",40,Vector2i(10,9));w.act("wall",Vector2i(8,10));w.spawn_enemy({"archetype":"kidnapper","role":"kidnapper","entry":Vector2i(0,10)});w.enemies.back().pos=Vector2i(32,20)
	for i in range(5):w.step()
	w.calendar_ticks=100;w.paused=true
	check(w.Snapshot.save(w,out+"/fixture.snapshot"));quit()
func check(ok):if not ok:push_error("Cannot prepare fixture");quit(1)
