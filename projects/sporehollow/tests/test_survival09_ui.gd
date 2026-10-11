extends SceneTree
const Farm=preload("res://game/world.gd")
var out=""
var checks=[]
var failures=0
func _initialize():call_deferred("run")
func check(ok,note):
	checks.append({"passed":bool(ok),"check":note})
	if not ok:failures+=1;push_error(note)
func mouse(point,down):
	var e=InputEventMouseButton.new();e.position=point;e.button_index=MOUSE_BUTTON_LEFT;e.pressed=down;Input.parse_input_event(e);await process_frame
func click(point):
	var e=InputEventMouseMotion.new();e.position=point;Input.parse_input_event(e);await process_frame;await mouse(point,true);await mouse(point,false)
func run():
	out=OS.get_environment("FARM_REVIEW_OUTPUT")
	if out=="" or "--isolated-review" not in OS.get_cmdline_user_args() or DisplayServer.get_name()=="headless":quit(2);return
	root.size=Vector2i(1280,800)
	var data=Farm.new_campaign();data.animals.append({"id":2,"species":"hen","category":"bird","lv":1,"xp":0,"loyalty":0,"position":[8,8]})
	var w=Farm.new(data,31).begin_day();w.story.intro_seen=true;w.paused=true;w.trees.clear();w.natural.clear();w.field_items.clear();w.Stock.sync(w);w.keeper.pos=Vector2i(6,8);w.keeper.satiety=15;w.keeper.malnutrition=60
	var g=load("res://game/main.tscn").instantiate();g.automated=true;g.world=w;root.add_child(g);await process_frame;await process_frame;g.set_process(false);g.audio.set_process(false);g.reset_view();g.neutral();g.camera.position=g.center(Vector2i(13,11));g.camera.force_update_scroll()
	await click(g.buttons.group1.get_global_rect().get_center());await click(g.palette.find_child("Animal_2",true,false).get_global_rect().get_center())
	check(g.buttons.has("livestock_slaughter"),"Selecting one hen opens its husbandry controls")
	await click(g.buttons.livestock_class.get_global_rect().get_center());check(g.world.Livestock.classification(w.Orders.animal(w,2))=="pet" and g.buttons.livestock_slaughter.disabled,"Pet classification visibly disables slaughter")
	await click(g.buttons.livestock_class.get_global_rect().get_center());await click(g.buttons.livestock_forbid.get_global_rect().get_center());check(w.Orders.animal(w,2).forbidden and g.buttons.livestock_slaughter.disabled,"Explicit prohibition disables designation")
	await click(g.buttons.livestock_forbid.get_global_rect().get_center());await click(g.buttons.livestock_slaughter.get_global_rect().get_center());check(not w.Livestock.job(w,2).is_empty(),"Only the selected hen receives a slaughter job")
	g.queue_redraw();g.hud.queue_redraw();await process_frame;await RenderingServer.frame_post_draw;root.get_texture().get_image().save_png(out+"/livestock-designation.png")
	await click(g.buttons.livestock_slaughter.get_global_rect().get_center());check(w.Livestock.job(w,2).is_empty() and not w.Orders.animal(w,2).get("dead",false),"UI cancellation preserves the living animal")
	g.choose_walk();w.keeper.nutrition_down=true;w.keeper.malnutrition=75;g.refresh();g.queue_redraw();g.hud.queue_redraw();await process_frame;await RenderingServer.frame_post_draw;root.get_texture().get_image().save_png(out+"/nutrition-down.png")
	check(g.buttons.keeper_rest.disabled and g.buttons.resume_jobs.disabled,"Inability visibly disables rest and work-resume controls")
	# Native close/startup fixture: explicit queued animal work plus real held food mid-meal.
	w.paused=false;w.keeper.satiety=0;w.keeper.malnutrition=75;w.Livestock.designate(w,2);w.Stock.add(w,"meat",2,w.keeper.pos)
	for i in range(4):w.step()
	check(w.keeper.has("meal_remaining") and not w.Livestock.job(w,2).is_empty(),"Combined fixture contains gradual nutrition recovery and the explicit animal job")
	w.Snapshot.save(w,out+"/survival.snapshot")
	FileAccess.open(out+"/survival-ui.json",FileAccess.WRITE).store_string(JSON.stringify({"passed":failures==0,"failures":failures,"groups":[{"name":"5 Existing UI input and combined save fixture","checks":checks}],"method":"Injected Godot mouse events on isolated GPU; paused visible fixture and production steps for the combined native restart fixture. Not human play."},"\t"))
	print("Survival UI: 1 group, ",failures," failures");quit(0 if failures==0 else 1)
