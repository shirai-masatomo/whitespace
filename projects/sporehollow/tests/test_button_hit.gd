extends "res://tests/test_housing_sleep.gd"
var results=[]
class DrawProbe extends RefCounted:
	var buttons
	var pointer=Vector2.ZERO
	var overlay
	const UI=preload("res://game/ui_style.gd")
	func _init(g):buttons=g.buttons;overlay=self
	func draw_line(_a,_b,_c,_d):pass
	func draw_style_box(_a,_b):pass
	func label_on(_a,_b,_c,_d,_e):pass
func verify(ok,note):results.append({"passed":bool(ok),"check":note})
func move(at,held=false):
	var e=InputEventMouseMotion.new();e.position=root.get_final_transform()*at;e.button_mask=MOUSE_BUTTON_MASK_LEFT if held else 0;root.push_input(e,false)
func mouse(at,down):
	var e=InputEventMouseButton.new();e.position=root.get_final_transform()*at;e.button_index=MOUSE_BUTTON_LEFT;e.pressed=down;root.push_input(e,false)
func run():
	if DisplayServer.get_name()!="headless" or OS.get_environment("FARM_REVIEW_OUTPUT")=="":quit(2);return
	var boot=load("res://game/loading.tscn").instantiate();boot.review_mode=true;root.add_child(boot)
	var deadline=Time.get_ticks_msec()+25000
	while not boot.finished and boot.failure=="" and Time.get_ticks_msec()<deadline:await process_frame
	if not boot.finished:quit(2);return
	var g=boot.game;g.set_process(false);g.world=fixture();w=g.world;w.paused=true;g.story_modal="";g.field_book=false;g.field_shop=false
	for dimensions in [Vector2i(1280,800),Vector2i(1600,1000)]:
		root.size=dimensions
		for category in ["壁と扉","床","設置"]:
			g.select_group(0);g.ColonyPanels.architecture_category(g,category)
			var ids=g.subtask_choices().duplicate()
			for id in ids:
				for drift in [false,true]:
					for portion in [Vector2(.04,.04),Vector2(.5,.04),Vector2(.96,.04),Vector2(.04,.5),Vector2(.5,.5),Vector2(.96,.5),Vector2(.04,.96),Vector2(.5,.96),Vector2(.96,.96)]:
						g.tool="";g.refresh();await process_frame
						var r=g.buttons[id].get_global_rect();var at=r.position+r.size*portion;move(at);mouse(at,true)
						var release=at+Vector2(10 if portion.x<.5 else -10,0) if drift else at
						move(release,true);mouse(release,false)
						results.append({"window":str(dimensions),"category":category,"id":id,"portion":str(portion),"drift":drift,"passed":g.tool==id})
		g.select_group(0);g.ColonyPanels.architecture_category(g,"壁と扉");await process_frame
		var first=g.subtask_choices()[0];var second=g.subtask_choices()[1]
		var r=g.buttons[first].get_global_rect();var target=g.buttons[second].get_global_rect().get_center()
		move(r.get_center());mouse(r.get_center(),true);move(target,true)
		verify(g.subtasks.dragging,"Leaving a card still permits deliberate reordering "+str(dimensions))
		var probe=DrawProbe.new(g);probe.pointer=target;g.subtasks.draw(probe)
		for slot in g.subtasks.slots:
			var expected=slot.rect.position+Vector2(5 if slot.id!=first and g.subtasks.slots.find(slot)>=g.subtasks.insertion else 0,0)
			verify(g.buttons[slot.id].global_position==expected,"Reorder keeps card in scroll-container coordinates: "+slot.id)
		probe.overlay=null
		mouse(target,false);verify(g.subtask_choices()[1]==first and g.tool=="","Reordering does not select or place a building")
		g.refresh();await process_frame;r=g.buttons[first].get_global_rect()
		g.buttons[first].disabled=true;move(r.get_center());mouse(r.get_center(),true);mouse(r.get_center(),false)
		verify(g.tool=="" and g.subtasks.pressed=="","Disabled card cannot be selected")
		g.refresh();await process_frame;r=g.buttons[first].get_global_rect()
		move(r.get_center());mouse(r.get_center(),true)
		var cancel=InputEventMouseButton.new();cancel.position=root.get_final_transform()*r.get_center();cancel.button_index=MOUSE_BUTTON_RIGHT;cancel.pressed=true;root.push_input(cancel,false)
		cancel=cancel.duplicate();cancel.pressed=false;root.push_input(cancel,false);mouse(r.get_center(),false)
		verify(g.group==-1 and g.tool=="" and g.subtasks.pressed=="","Right click cancels held card without placement")
		g.select_group(0);g.ColonyPanels.architecture_category(g,"壁と扉");await process_frame
		var scroll=g.palette.get_node("ArchitectItems");scroll.size.y=50;await process_frame
		r=g.buttons[first].get_global_rect();var hidden=r.position+Vector2(30,80)
		move(hidden);mouse(hidden,true);mouse(hidden,false)
		verify(g.tool=="" and g.subtasks.pressed=="","Clipped caption does not capture clicks")
		scroll.scroll_vertical=35;await process_frame;r=g.buttons[first].get_global_rect()
		var at=g.subtasks.visible_rect(g.buttons[first]).get_center();move(at);mouse(at,true);mouse(at,false)
		verify(g.tool==first,"Visible part of scrolled card is selectable")
		g.tool="";g.refresh();await process_frame;r=g.buttons[first].get_global_rect()
		var gap=r.position+Vector2(r.size.x+3,30);move(gap);mouse(gap,true);mouse(gap,false)
		verify(g.tool=="","Gap between cards does not select either card")
		verify(w.jobs.is_empty(),"Button interactions never place building jobs")
	var failed=results.filter(func(c):return not c.passed).size()
	FileAccess.open(OS.get_environment("FARM_REVIEW_OUTPUT")+"/button-hit.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":results,"count":results.size(),"failed":failed},"  "))
	print("Button input: ",results.size()," failed=",failed)
	boot.queue_free();await process_frame;quit(1 if failed else 0)
