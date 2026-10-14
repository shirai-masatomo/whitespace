extends SceneTree
var checks=[]
func check(ok,note):
	checks.append({"check":note,"passed":bool(ok)})
	if not ok:push_error(note)
func _initialize():call_deferred("run")
func run():
	var out=OS.get_environment("FARM_REVIEW_OUTPUT")
	if DisplayServer.get_name()!="headless" or out=="":quit(2);return
	var boot=load("res://game/loading.tscn").instantiate();boot.review_mode=true;root.add_child(boot)
	var deadline=Time.get_ticks_msec()+30000
	while not boot.finished and boot.failure=="" and Time.get_ticks_msec()<deadline:await process_frame
	if not boot.finished:check(false,"Headless UI initialization");quit(1);return
	var g=boot.game;g.set_process(false);g.world.paused=true;g.story_modal="";g.field_shop=false;g.field_book=false;g.group=-1
	var pos=Vector2i(30,20);g.world.structures[pos]={"id":10001,"kind":"cooking_bench","status":"ready","hp":16,"max_hp":16,"resource":"wood","open":false}
	g.crafting_panel.show(g,pos);await process_frame
	var panel=g.colony_panel
	check(panel!=null and panel.get_rect().size==Vector2(520,440),"Shared crafting panel has bounded layout")
	var recipe=panel.get_node_or_null("Recipe");check(recipe!=null and recipe.item_count==4,"Cooking choices come from shared recipe data")
	var add=panel.get_children().filter(func(c):return c is Button and c.text=="製作指示を追加")[0];add.pressed.emit();await process_frame
	check(g.world.jobs.any(func(j):return j.kind=="craft" and j.recipe=="roast_mushroom"),"Actual UI button registers a craft bill while paused")
	check(g.crafting_panel.labels.size()==1 and "焼きキノコ" in g.crafting_panel.labels[0][0].text,"Bill shows recipe and ingredient quantities")
	g.crafting_panel.close(g);g.group=0;g.architect_category="ゾーン";g.tool=""
	var id=g.world.Zones.create(g.world,"stockpile",Vector2i(32,20),Vector2i(34,20));g.zone_controls.selected_id=id;g.refresh();await process_frame
	var tree=g.colony_panel.get_node_or_null("StockpileFilters")
	check(tree!=null and tree.get_root().get_children().size()==6,"Stockpile UI has all six main categories")
	var priorities=g.colony_panel.get_children().filter(func(c):return c is OptionButton)
	priorities[0].item_selected.emit(2);check(g.world.Zones.find(g.world,id).get("priority")==2,"Priority UI changes destination priority")
	var ban=g.colony_panel.get_children().filter(func(c):return c is Button and c.text=="全禁止")[0];ban.pressed.emit();await process_frame
	check(not g.world.Zones.accepts(g.world,Vector2i(32,20),"wood"),"All-forbid UI uses the same stock filter as hauling")
	g.choose_walk();await process_frame
	check(g.buttons.has("human_clothes") and not g.buttons.human_clothes.get_rect().intersects(g.buttons.resume_jobs.get_rect()),"Clothing action does not overlap work/resume controls")
	var effects=g.world.Needs.describe(g.world,g.world.keeper);check(effects=="食事効果なし","Selection data shows explicit no-food-effect state")
	g.group=0;g.architect_category="設置";g.selected={};g.refresh();await process_frame
	check(["cooking_bench","carpentry_bench","sewing_bench"].all(func(id):return id in g.subtask_choices()),"All three benches available in Architect")
	var fail=checks.filter(func(c):return not c.passed).size();FileAccess.open(out+"/craft-ui.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":fail,"method":"Headless Control construction and signal dispatch, not visual/GPU review"},"\t"))
	boot.queue_free();await process_frame;print("CRAFT_UI: ",checks.size()," checks, failures=",fail);quit(1 if fail else 0)
