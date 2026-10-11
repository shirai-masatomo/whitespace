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
func motion(point):
	var e=InputEventMouseMotion.new();e.position=point;e.relative=Vector2(24,12);Input.parse_input_event(e);await process_frame
func key(code):
	var e=InputEventKey.new();e.physical_keycode=code;e.pressed=true;Input.parse_input_event(e);await process_frame
func run():
	out=OS.get_environment("FARM_REVIEW_OUTPUT")
	if out=="" or "--isolated-review" not in OS.get_cmdline_user_args() or DisplayServer.get_name()=="headless":quit(2);return
	root.size=Vector2i(1280,800)
	var w=Farm.new({},31).begin_day();w.story.intro_seen=true;w.paused=true
	check(w.Story.at(w)==Vector2i(24,16) and w.keeper.pos in w.Story.goals(w) and w.walkable(w.keeper.pos),"New start keeps the idol at map center and places keeper on a safe adjacent cell")
	check(not w.campaign.has("start_near_idol"),"New-start relocation is consumed before any save or daily reload")
	var saved=w.keeper.pos;w.keeper.pos=Vector2i(42,26);w.persist_farm();var restored=Farm.new(w.campaign,31)
	check(restored.keeper.pos==Vector2i(42,26),"Campaign reload preserves an existing distant keeper position")
	w.Snapshot.save(w,out+"/existing.snapshot");restored=Farm.Snapshot.restore(out+"/existing.snapshot")
	check(restored.keeper.pos==Vector2i(42,26),"Snapshot reload preserves existing actor position without teleporting")
	w.keeper.pos=saved
	var g=load("res://game/main.tscn").instantiate();g.automated=true;g.world=w;root.add_child(g);await process_frame;await process_frame;g.neutral()
	var keeper_screen=g.get_canvas_transform()*g.center(w.keeper.pos);var idol_screen=g.get_canvas_transform()*((Vector2(w.Story.at(w))+Vector2.ONE)*g.TILE)
	check(keeper_screen.distance_to(Vector2(640,400))<130 and idol_screen.distance_to(Vector2(640,400))<130,"Initial camera places both keeper and idol near screen center")
	var a=Vector2(460,260);var b=a+Vector2(65,35);var origin=g.camera.position
	await motion(a);await mouse(a,true);check(not g.map_panning(),"Mouse press alone does not show grabbing state")
	await motion(b);check(g.map_panning() and Input.get_current_cursor_shape()==Input.CURSOR_DRAG and g.camera.position!=origin,"Neutral map drag moves the camera and selects the closed-hand drag cursor")
	await mouse(b,false);check(not g.map_panning() and Input.get_current_cursor_shape()==Input.CURSOR_ARROW,"Release restores the normal cursor")
	var free_camera=g.camera.position;await process_frame;await process_frame;check(g.camera.position==free_camera,"Camera does not continually follow/recenter after free scrolling")
	await mouse(a,true);await motion(b);var cancel=InputEventMouseButton.new();cancel.position=b;cancel.button_index=MOUSE_BUTTON_RIGHT;cancel.pressed=true;Input.parse_input_event(cancel);await process_frame
	check(not g.map_panning() and Input.get_current_cursor_shape()==Input.CURSOR_ARROW,"Right-click cancellation restores normal cursor")
	await mouse(b,false);await mouse(a,true);await motion(b);g.notification(Node.NOTIFICATION_WM_WINDOW_FOCUS_OUT);await process_frame
	check(not g.map_panning() and Input.get_current_cursor_shape()==Input.CURSOR_ARROW,"Focus loss clears drag and restores normal cursor immediately")
	await mouse(b,false);g.neutral();var ui=g.buttons.pause.get_global_rect().get_center();await mouse(ui,true);await motion(ui+Vector2(20,10))
	check(not g.map_panning() and Input.get_current_cursor_shape()!=Input.CURSOR_DRAG,"UI press/motion never activates map grabbing")
	await mouse(ui,false);w.paused=true;g.select_group(1);await motion(a);await mouse(a,true);await motion(b)
	check(not g.map_panning() and Input.get_current_cursor_shape()!=Input.CURSOR_DRAG,"Animal command/selection range drag never activates map grabbing")
	await mouse(b,false)
	var zones_before=w.zones.size();var jobs_before=w.jobs.size()
	for tool in ["","wood_wall","zone_stockpile"]:
		g.select_group(0);g.architect_category="ゾーン" if tool=="zone_stockpile" else "壁と扉";g.tool=tool;g.refresh()
		if tool!="":await motion(a);await mouse(a,true);await motion(b)
		var right=InputEventMouseButton.new();right.position=Vector2(500,490) if tool=="zone_stockpile" else b;right.button_index=MOUSE_BUTTON_RIGHT;right.pressed=true;Input.parse_input_event(right);await process_frame
		check(g.group==-1 and g.tool=="" and not g.zone_controls.pressed and g.wall_stroke.kind=="" and not g.dragging,"Architect right click returns to neutral without committing: "+tool)
		await mouse(b,false)
	check(w.zones.size()==zones_before and w.jobs.size()==jobs_before,"Right-click cancellation creates no zone or construction even across UI panel")
	# Right-click above an actual subtask button and command preview must not execute either.
	g.architect_category="壁と扉";g.select_group(0);await process_frame
	var sub=g.buttons.wood_wall.get_global_rect().get_center();await mouse(sub,true)
	var right_sub=InputEventMouseButton.new();right_sub.position=sub;right_sub.button_index=MOUSE_BUTTON_RIGHT;right_sub.pressed=true;Input.parse_input_event(right_sub);await process_frame;await mouse(sub,false)
	check(g.group==-1 and g.subtasks.pressed=="" and w.jobs.size()==jobs_before,"Right-click on pressed subtask button clears selection without executing or cancelling jobs")
	g.select_group(4);g.item_commands.select(g,"haul");await motion(a);await mouse(a,true);await motion(b)
	var cancel_command=InputEventMouseButton.new();cancel_command.position=Vector2(90,705);cancel_command.button_index=MOUSE_BUTTON_RIGHT;cancel_command.pressed=true;Input.parse_input_event(cancel_command);await process_frame;await mouse(b,false)
	check(g.group==-1 and not g.item_commands.pressed and w.jobs.size()==jobs_before,"Right-click on command UI cancels area preview without issuing collection")
	g.world=restored;g.reset_view();g.refresh();await process_frame
	keeper_screen=g.get_canvas_transform()*g.center(restored.keeper.pos);idol_screen=g.get_canvas_transform()*((Vector2(restored.Story.at(restored))+Vector2.ONE)*g.TILE)
	check(Rect2(80,80,1120,620).has_point(keeper_screen) and Rect2(80,80,1120,620).has_point(idol_screen) and restored.keeper.pos==Vector2i(42,26),"Load adjusts camera framing to both subjects while preserving saved location")
	g.world=w;g.reset_view();g.select_group(3);await process_frame
	var previous=-1.0
	var aligned=true
	for kind in w.Work.Policy.ORDER:
		var button=g.palette.find_child("Priority_keeper_"+kind,true,false)
		aligned=aligned and button.get_global_rect().position.x>previous
		previous=button.get_global_rect().position.x
	check(aligned and g.colony_panel.size.x==640 and g.colony_panel.size.y<=174,"Compact role matrix keeps the scheduler's left-to-right column order")
	var initial=w.keeper.work_priorities.build;var values=[]
	for i in range(5):
		var button=g.palette.find_child("Priority_keeper_build",true,false)
		await click(button.get_global_rect().get_center());values.append(w.keeper.work_priorities.build)
	check(values==[(initial+1)%5,(initial+2)%5,(initial+3)%5,(initial+4)%5,initial],"Table cell clicks apply 1-4/blank cycling to the actual person's priority")
	var btn=g.palette.find_child("Priority_keeper_build",true,false)
	check(btn.get_theme_stylebox("normal").bg_color!=btn.get_theme_stylebox("hover").bg_color and btn.get_theme_stylebox("hover").bg_color!=btn.get_theme_stylebox("pressed").bg_color and btn.tooltip_text!="","Priority cells have distinct hover/pressed feedback and explanations")
	g.queue_redraw();g.hud.queue_redraw();await process_frame;await RenderingServer.frame_post_draw;root.get_texture().get_image().save_png(out+"/centered-roles.png")
	FileAccess.open(out+"/pan-center.json",FileAccess.WRITE).store_string(JSON.stringify({"method":"3 scoped groups: placement/save; actual scene pan cursor transitions; framing/no-follow. Private GPU Godot InputEvent, not physical OS input.","checks":checks,"failures":failures,"keeper_start":[saved.x,saved.y]},"	"))
	print("PanCenter: ",failures," failures");g.queue_free();await process_frame;quit(1 if failures else 0)
