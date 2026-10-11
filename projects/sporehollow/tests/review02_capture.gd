extends SceneTree
const Farm=preload("res://game/world.gd")
var g
var out=""
func _initialize():call_deferred("run")
func farm():
	var c=Farm.new_campaign();c.animals.append({"id":2,"species":"hen","category":"bird","lv":1,"xp":0,"loyalty":0,"position":[12,12]})
	var w=Farm.new(c,31).begin_day();w.story.intro_seen=true;w.paused=true;w.enemies.clear();w.spawn_schedule.clear();w.natural.clear();w.trees.clear();w.rocks.clear();w.structures.clear();w.floors.clear();w.field_items.clear();w.jobs.clear();w.zones=[];w.storage_cells=[];w.nature_config.spawn_chance_per_second=0
	w.keeper.pos=Vector2i(10,10);w.keeper.satiety=100;w.keeper.sleepiness=0
	for a in w.animals:a.pos=Vector2i(12,12) if a.species=="hen" else Vector2i(12,10);a.home=a.pos;a.mode="stay";a.order_until=99999
	return w
func scene(w):
	if is_instance_valid(g):g.queue_free();await process_frame
	g=load("res://game/main.tscn").instantiate();g.automated=true;g.world=w;root.add_child(g);await process_frame;await process_frame
	g.set_process(false);g.audio.set_process(false);g.reset_view();g.camera.position=g.center(Vector2i(13,11));g.camera.zoom=Vector2.ONE;g.camera.force_update_scroll();g.neutral();g.refresh_jobs()
func shot(name):
	g.refresh_jobs();g.queue_redraw();g.hud.queue_redraw();await process_frame;await process_frame;await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(out+"/"+name+".png")
func run():
	out=OS.get_environment("FARM_REVIEW_OUTPUT")
	if out=="" or "--isolated-review" not in OS.get_cmdline_user_args():quit(2);return
	root.size=Vector2i(1280,800)
	var w=farm();w.Work.set_priority(w,"keeper","animal",1);w.Work.set_priority(w,"keeper","other",0);w.Tasks.designate(w,"train",Vector2i.ZERO,1);await scene(w);g.choose_animal(1);await shot("01-training")
	w=farm();w.Work.set_priority(w,"keeper","animal",1);w.Work.set_priority(w,"keeper","other",0);w.Livestock.designate(w,2);await scene(w);g.choose_animal(2);await shot("02-slaughter")
	w=farm();w.Stock.add(w,"soil",40,Vector2i(10,9));w.act("wall",Vector2i(8,10));w.act("wall",Vector2i(7,10));await scene(w);g.select_group(0);g.tool="wall";g.refresh();await shot("03-plans")
	w.paused=false
	for i in range(80):
		w.step()
		if not w.Stock.cargo(w,"keeper").is_empty():break
	w.paused=true;g.reset_view();g.camera.position=g.center(Vector2i(13,11));g.camera.force_update_scroll();g.choose_walk();g.pointer=Vector2(193,24);await shot("04-stock-carry")
	w=farm();w.calendar_ticks=1100;w.phase="day";w.keeper.equipment={"item_id":"wood_staff","durability":-1};w.Work.set_drafted(w,"keeper",true);w.spawn_enemy({"entry":Vector2i(0,10),"archetype":"kidnapper","role":"kidnapper"});w.enemies.back().pos=Vector2i(16,10);await scene(w);g.choose_walk();await shot("05-night-drafted")
	w=farm();w.calendar_ticks=1727;w.phase="defend";w.paused=false;w.spawn_enemy({"entry":Vector2i(0,10),"archetype":"kidnapper","role":"kidnapper"});var e=w.enemies.back();e.pos=Vector2i(19,11);e.arrival_complete=true;w.step();w.paused=true;await scene(w);await shot("06-morning-threat")
	w=farm();await scene(w);g.toggle_menu();await shot("07-menu")
	w=farm();await scene(w);g.StoryView.open(g,"intro");g.story_page=3;g.StoryView.rebuild(g);await shot("08-introduction")
	w=farm();w.Zones.create(w,"stockpile",Vector2i(12,11),Vector2i(14,12));w.Zones.create(w,"residential",Vector2i(16,11),Vector2i(18,12));await scene(w);g.select_group(0);g.architect_category="ゾーン";g.refresh();await shot("09-zones")
	w=farm();w.animals[0].pos=Vector2i(22,22);w.keeper.satiety=20;w.Stock.add(w,"mushroom",2,Vector2i(10,9));w.paused=false
	for i in range(100):
		w.step()
		if w.keeper.has("meal_remaining"):break
	w.paused=true;await scene(w);g.choose_walk();await shot("10-eating")
	g.queue_free();await process_frame;quit()
