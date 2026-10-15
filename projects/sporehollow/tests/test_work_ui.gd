extends SceneTree
var checks=[]
var layouts=[]
var g
func check(ok,note):
	checks.append({"check":note,"passed":bool(ok)})
	if not ok:push_error(note)
func _initialize():call_deferred("run")
func xy(v):return [v.x,v.y]
func box(r):return [r.position.x,r.position.y,r.size.x,r.size.y]
func snapshot(label):
	var nodes=[]
	capture(g.controls,nodes)
	var card={}
	if g.selected.get("kind")=="animal" and not g.animal_list_open:
		var a=g.world.Orders.animal(g.world,g.selected.id)
		card={"rect":box(g.companion_card_rect()),"name":g.world.animal_name(a),"level":a.lv,"hp":a.hp,"max_hp":a.max_hp,"satiety":a.get("satiety",100),"stamina":a.stamina,"max_stamina":a.get("max_stamina",100),"effects":g.world.Needs.describe(g.world,a)}
	layouts.append({"name":label,"window":xy(root.size),"logical":xy(root.get_visible_rect().size),"nodes":nodes,"card":card})
func capture(node,rows):
	for n in node.get_children(true):
		if n is Control and n.is_visible_in_tree():
			var row={"type":n.get_class(),"name":str(n.name),"rect":box(n.get_global_rect())}
			if n is Button or n is Label or n is LineEdit:row.text=n.text;row.font=n.get_theme_font_size("font_size")
			if n is Button:
				var style=n.get_theme_stylebox("normal")
				if style is StyleBoxFlat:row.color=style.bg_color.to_html();row.border=style.border_color.to_html()
				elif style is StyleBoxTexture:row.color=style.modulate_color.to_html()
				row.disabled=n.disabled;row.font=n.get_theme_font_size("font_size")
			if n is Tree:row.rows=tree_text(n.get_root())
			if n is ProgressBar:row.value=n.value;row.maximum=n.max_value
			if n is TextureRect:row.texture=n.texture.resource_path if n.texture!=null else ""
			rows.append(row)
		capture(n,rows)
func tree_text(item):
	var text=[]
	for row in item.get_children():
		text.append(row.get_text(0))
		if not row.collapsed:text.append_array(tree_text(row))
	return text
func mouse(at,down):
	var e=InputEventMouseButton.new();e.button_index=MOUSE_BUTTON_LEFT;e.position=at;e.pressed=down;return e
func click_world(at):
	g.pointer=at;var e=mouse(at,true);g._route_input(e);g._unhandled_input(e);g._route_input(mouse(at,false))
func run():
	var out=OS.get_environment("FARM_REVIEW_OUTPUT")
	if DisplayServer.get_name()!="headless" or out=="":quit(2);return
	root.size=Vector2i(1280,800)
	var boot=load("res://game/loading.tscn").instantiate();boot.review_mode=true;root.add_child(boot)
	var deadline=Time.get_ticks_msec()+30000
	while not boot.finished and boot.failure=="" and Time.get_ticks_msec()<deadline:await process_frame
	if not boot.finished:check(false,"Headless initialization");quit(1);return
	g=boot.game;g.set_process(false);g.world.paused=true;g.story_modal="";g.field_shop=false;g.field_book=false;g.neutral()
	var w=g.world;var cats=["壁と扉","床","設置","ゾーン"]
	check(g.architect_category=="壁と扉" and g.ColonyModel.ARCHITECT.keys()==cats,"Default walls/doors and no Architect All category")
	var classified=[]
	for c in cats:classified.append_array(g.ColonyModel.ARCHITECT[c])
	check(g.GROUP_TOOLS[0].all(func(id):return classified.count(id)==1),"Every existing building/place tool has exactly one category")
	w.campaign.unlocked_blueprints.append_array(["wood_wall","stone_wall","locked_door"])
	for resolution in [Vector2i(1280,800),Vector2i(1600,1000)]:
		root.size=resolution;root.content_scale_size=Vector2i(1280,800);root.content_scale_mode=Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
		await process_frame
		g.select_group(0);var previous=[]
		for repeat in range(2):
			for category in cats:
				g.ColonyPanels.architecture_category(g,category);await process_frame;await process_frame
				var positions=[]
				for i in range(4):positions.append(g.buttons["architect_category_%d"%i].get_global_rect())
				if previous.is_empty():previous=positions
				check(positions==previous,"Fixed category geometry %s %s pass%d"%[resolution,category,repeat])
				check(positions[0].position.y==706 and positions[-1].end.x<=410 and positions.all(func(r):return r.end.y<=742),"Category strip inside panel and above main mode bar")
				for i in range(3):check(not positions[i].intersects(positions[i+1]),"Category buttons do not overlap")
				if category=="ゾーン":
					check(g.palette.find_child("ZoneDetails",true,false)==null and ["zone_stockpile","zone_residential","zone_resize","zone_cancel"].all(func(id):return g.buttons.has(id)),"Zone palette exposes only creation/edit tools")
				else:
					var sc=g.palette.get_node("ArchitectItems")
					check(sc.get_global_rect().end.y<=positions[0].position.y and sc.vertical_scroll_mode==ScrollContainer.SCROLL_MODE_SHOW_ALWAYS,"Only upper items scroll; scrollbar always visible")
					for id in g.subtask_choices():
							check(g.buttons[id].get_parent()==sc.get_child(0),"Building tool lives in clipped scroll body "+id)
							check(g.buttons[id].text==g.TOOLS[id].split(" ")[0],"Architect name-only label "+id)
				if repeat==0:snapshot("architect-"+category)
		g.select_group(1);await process_frame
		check(g.animal_list_open and g.palette.find_child("AnimalList",true,false)!=null and not g.buttons.has("animal_instructions"),"Animal main tab opens list only")
		snapshot("animal-list")
		var a=w.animals[0];g.choose_animal(a.id);await process_frame
		check(not g.animal_list_open and g.palette.find_child("AnimalList",true,false)==null and g.buttons.has("animal_instructions") and g.buttons.has("animal_back"),"Individual view replaces list")
		check(g.companion_card_rect().end.y==742 and g.companion_card_rect().size==Vector2(448,156),"Individual view is compact")
		snapshot("animal-individual")
		g.open_animal_commands(a.id);await process_frame
		check(g.companion_card_rect().end.y<660 and g.buttons.animal_back.get_global_rect().end.y<=g.companion_card_rect().end.y,"Command menu below card, not overlapping")
		snapshot("animal-commands")
		var ids=g.selected_animals.duplicate();g.show_animal_list();await process_frame
		check(g.selected_animals==ids and not g.buttons.has("animal_instructions") and not g.buttons.has("animal_back"),"Return to list retains selection and hides individual actions")
		g.pointer=Vector2(200,600);check(not g.pointer_over_ui() if g.colony_panel.position.y>600 else true,"Unused animal panel area does not block world input")
	# Overflow: real ScrollContainer wheel routing must not zoom the map.
	g.select_group(0);g.ColonyPanels.architecture_category(g,"壁と扉");await process_frame
	var sc=g.palette.get_node("ArchitectItems");sc.get_child(0).custom_minimum_size.y=720;await process_frame;await process_frame
	var move=InputEventMouseMotion.new();move.position=Vector2(60,620);root.push_input(move,true);await process_frame
	var zoom=g.camera.zoom;var scroll_before=sc.scroll_vertical
	var wheel=InputEventMouseButton.new();wheel.position=move.position;wheel.button_index=MOUSE_BUTTON_WHEEL_DOWN;wheel.pressed=true
	root.push_input(wheel,true);await process_frame;await process_frame
	check(g.camera.zoom==zoom and sc.scroll_vertical>scroll_before,"Overflow palette wheel scrolls items without map zoom")
	# Existing-zone click through the world input route; a creation drag must not open it.
	g.neutral();w.zones.clear();w.Zones.sync_storage(w)
	var p=w.keeper.pos+Vector2i(5,0)
	for cell in w.Zones.cells_in(w,p,p+Vector2i(2,2)):
		w.natural.erase(cell);w.trees.erase(cell);w.rocks.erase(cell);w.structures.erase(cell);w.floors.erase(cell)
	var stock=w.Zones.create(w,"stockpile",p,p+Vector2i(2,2));var home=w.Zones.create(w,"residential",p+Vector2i(0,4),p+Vector2i(2,5))
	check(w.Zones.title(w.Zones.find(w,stock))=="備蓄1" and w.Zones.title(w.Zones.find(w,home))=="居住1","Names auto-number independently of stable IDs")
	g.camera.force_update_scroll();click_world(g.screen_cell(p+Vector2i.ONE));await process_frame
	check(g.zone_controls.details_open and g.zone_controls.selected_id==stock,"Map left click opens existing stockpile details")
	var panel=g.palette.find_child("ZoneDetails",true,false);check(panel!=null,"Independent details panel exists")
	if panel==null:quit(1);return
	var saved_cells=w.Zones.find(w,stock).cells.duplicate();var goods=w.field_items.duplicate(true);var jobs=w.jobs.duplicate(true)
	var edit=panel.get_node("ZoneName");edit.grab_focus();await process_frame
	var paused=w.paused;var speed=g.speed;var group=g.group
	for key in [KEY_SPACE,KEY_1,KEY_TAB,KEY_W]:
		var e=InputEventKey.new();e.pressed=true;e.physical_keycode=key;e.keycode=key;g._route_input(e)
	check(g.speed==speed and w.paused==paused and g.group==group and g.keys_down.is_empty(),"Name typing cannot pause, change speed/mode, or move camera")
	edit.text="工房資材";edit.text_submitted.emit(edit.text);await process_frame
	check(w.Zones.title(w.Zones.find(w,stock))=="工房資材" and w.Zones.find(w,stock).cells==saved_cells and w.field_items==goods and w.jobs==jobs,"Rename changes metadata only")
	check(panel.get_node("ZoneSelector").get_item_text(0)=="工房資材","Rename also updates zone selector list")
	check(w.campaign.zones.filter(func(z):return z.id==stock)[0].name=="工房資材","Name stored alongside zone data without restoring save/load")
	check(not w.Zones.rename(w,stock,"  "),"Empty names rejected")
	panel.get_node("ZonePriority").item_selected.emit(2)
	check(w.Zones.find(w,stock).priority==2,"Priority setting still updates hauling data")
	var tree=panel.get_node("StockpileFilters");check(tree.get_root().get_children().size()==6,"All main/sub/individual filter hierarchy retained")
	for row in tree.get_root().get_children():row.collapsed=false
	await process_frame
	move.position=tree.get_global_rect().get_center();root.push_input(move,true);await process_frame
	zoom=g.camera.zoom;var tree_scroll=tree.get_scroll().y
	wheel.position=move.position;root.push_input(wheel,true);await process_frame;await process_frame
	check(g.camera.zoom==zoom and tree.get_scroll().y>tree_scroll,"Filter tree wheel scroll is local, not camera zoom")
	var ban=panel.get_children().filter(func(n):return n is Button and n.text=="全禁止")[0];ban.pressed.emit();await process_frame
	check(not w.Zones.accepts(w,p,"wood") and w.field_items==goods and w.Zones.find(w,stock).cells==saved_cells,"Filter changes preserve physical goods and area")
	for resolution in [Vector2i(1280,800),Vector2i(1600,1000)]:
		root.size=resolution;await process_frame;snapshot("zone-stockpile")
	g.zone_controls.open(g,home);await process_frame
	check(g.palette.find_child("StockpileFilters",true,false)==null and g.colony_panel.size.y==226,"Residential details have no unused stock filter region")
	snapshot("zone-residential")
	g.zone_controls.resize(g);await process_frame
	check(not g.zone_controls.details_open and g.tool=="zone_resize" and g.group==0,"Resize returns to basic palette")
	g.zone_controls.select(g,"zone_stockpile");var begin=g.screen_cell(p);var end=g.screen_cell(p+Vector2i.ONE)
	g.pointer=begin;g.zone_controls.input(g,mouse(begin,true));g.pointer=end;g.zone_controls.input(g,mouse(end,false));await process_frame
	check(not g.zone_controls.details_open and not g.zone_controls.pressed and w.zones.size()==2 and w.Zones.find(w,stock).cells.has(p+Vector2i.ONE),"Zone creation drag merges existing area once without opening details")
	g.zone_controls.open(g,stock);await process_frame;g.colony_panel.get_node("CloseZone").pressed.emit();await process_frame
	check(not g.zone_controls.details_open and g.selected.is_empty(),"Details close clears zone context")
	g.select_group(0);g.ColonyPanels.architecture_category(g,"ゾーン");g.buttons.zone_cancel.pressed.emit();begin=g.screen_cell(p+Vector2i.ONE)
	g.pointer=begin;g.zone_controls.input(g,mouse(begin,true));g.zone_controls.input(g,mouse(begin,false))
	check(not w.Zones.find(w,stock).cells.has(p+Vector2i.ONE),"Zone cancel button removes clicked cell through input handler")
	g.neutral();g.selected={"kind":"keeper"};g.refresh();await process_frame
	check(not g.buttons.has("inventory") and g.buttons.has("keeper_equip") and g.buttons.has("human_clothes"),"Resident status exposes equipment instead of inventory")
	# Map animal selection also uses the individual state; multi-selection survives list navigation.
	var a=w.animals[0];g.neutral();g.board_click(mouse(g.get_canvas_transform()*g.animal_hit_rect(a).get_center(),true));await process_frame
	check(g.selected.get("kind")=="animal" and g.selected.id==a.id and not g.animal_list_open,"Map animal click opens correct individual")
	var b=a.duplicate(true);b.id=999;b.name="比較猫";b.species="cat";b.pos+=Vector2i(3,3);w.animals.append(b)
	g.choose_animal(b.id,true);var selected=g.selected_animals.duplicate();g.show_animal_list();await process_frame
	check(g.selected_animals==selected and selected.size()==2,"Multiple animal selection survives list return")
	g.open_animal_commands(b.id)
	check(g.selected.id==999 and g.selected_animals==selected and g.animal_commands_open,"Instructions on a selected list row uses that individual without losing the multi-selection")
	g.choose_animal(b.id);check(g.selected.id==999,"Cat selection uses cat, not Shiba status")
	check(not g.SHOW_JOB_QUEUE and w.Jobs.LIMIT==100,"Hidden work queue and 100-job limit retained")
	FileAccess.open(out+"/ui-layouts.json",FileAccess.WRITE).store_string(JSON.stringify({"method":"Actual headless Godot Control geometry; CPU illustration, not GPU screenshots","layouts":layouts}))
	var fail=checks.filter(func(c):return not c.passed).size()
	FileAccess.open(out+"/work-ui.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":fail},"\t"))
	boot.queue_free();await process_frame;print("WORK_UI: ",checks.size()," checks, failures=",fail);quit(1 if fail else 0)
