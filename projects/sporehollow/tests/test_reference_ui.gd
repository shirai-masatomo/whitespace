extends "res://tests/test_housing_sleep.gd"
var layouts=[]
func nodes(node,rows):
	if node is Control and not node.is_visible_in_tree():return
	if node is Control:
		var rect=node.get_global_rect();var row={"name":str(node.name),"type":node.get_class(),"rect":[rect.position.x,rect.position.y,rect.size.x,rect.size.y]}
		if node is Label or node is Button:row.text=node.text;row.font=node.get_theme_font_size("font_size")
		if node is Label:row.wrap=node.autowrap_mode!=TextServer.AUTOWRAP_OFF
		if node is TextureRect and node.texture!=null:row.texture=node.texture.resource_path
		if node is Button and node.icon!=null:row.icon=node.icon.resource_path
		if node is ProgressBar:row.value=node.value;row.maximum=node.max_value
		if node is Tree:
			row.text="";var item=node.get_root().get_first_child()
			while item!=null:row.text+="☑ "+item.get_text(0)+"\n";item=item.get_next()
		if node is OptionButton:row.text=node.get_item_text(node.selected) if node.selected>=0 else ""
		if node is LineEdit:row.text=node.text
		if node is Button:
			var style=node.get_theme_stylebox("normal")
			if style is StyleBoxFlat:row.color=style.bg_color.to_html()
			elif style is StyleBoxTexture:row.color=style.modulate_color.to_html()
		if node.get_script()==g_review().RoomMap:
			row.tiles=[]
			for t in node.tiles:row.tiles.append({"kind":t.get("kind",""),"texture":t.texture.resource_path if t.texture!=null else "","rect":[t.rect.position.x,t.rect.position.y,t.rect.size.x,t.rect.size.y]})
		rows.append(row)
	for child in node.get_children():nodes(child,rows)
func g_review():return preload("res://game/review_ui.gd")
func layout(g,title,size):
	var rows=[];nodes(g.palette,rows);layouts.append({"name":title,"window":[size.x,size.y],"nodes":rows})
	var panel=g.colony_panel;check(panel.get_global_rect().end.x<=932 and panel.get_global_rect().end.y<=742,"Panel avoids log and bottom menu: "+title)
func run():
	var boot=load("res://game/loading.tscn").instantiate();boot.review_mode=true;root.add_child(boot)
	var deadline=Time.get_ticks_msec()+25000
	while not boot.finished and boot.failure=="" and Time.get_ticks_msec()<deadline:await process_frame
	check(boot.finished,"Production loading ready")
	if boot.finished:
		var g=boot.game;g.set_process(false);g.world=fixture();w=g.world;w.paused=true;g.story_modal="";g.field_book=false;g.field_shop=false
		var helper=w.keeper.duplicate(true);helper.name="田中";w.Work.register(w,"helper",helper)
		for dimensions in [Vector2i(1280,800),Vector2i(1600,1000)]:
			root.size=dimensions;g.choose_walk();g.resident_tab="ステータス";g.refresh();await process_frame
			check(g.colony_panel.name=="ResidentDetails","Resident owns one detail panel")
			check(g.buttons.keeper_draft.visible and not g.buttons.keeper_equip.visible,"Status keeps draft, hides equipment actions")
			var status=g.colony_panel.get_node("ResidentStatus");check(status.nodes.size()==5,"Five live status bars")
			check(status.nodes.hp[0].size.y<27,"Status bars have clear separation")
			check(g.colony_panel.get_node("Traits").size.y<=120,"Trait lines fit without Windows CRLF duplication")
			w.keeper.hp=17;w.tick+=1;await process_frame;check(status.nodes.hp[0].value==17,"Status updates from live actor")
			layout(g,"resident",dimensions)
			g.buttons.resident_tab_1.pressed.emit();await process_frame
			check(g.buttons.keeper_equip.visible and not g.buttons.keeper_draft.visible,"Equipment tab uses original gear controls")
			layout(g,"equipment",dimensions)
			g.colony_panel.get_node("ResidentPicker").item_selected.emit(1);check(g.selected.key=="helper","Picker selects actual resident")
			g.buttons.time_tab.pressed.emit();check(g.life_actor=="helper","Life tab uses selected resident");g.HomeUI.back(g)
			g.buttons.resident_tab_2.pressed.emit();g.buttons.resident_roles.pressed.emit();check(g.roles_actor=="helper" and g.colony_page=="roles","Work opens selected roles")
			g.select_group(0);var before=[]
			for i in range(4):before.append(g.buttons["architect_category_%d"%i].get_global_rect())
			for category in g.ColonyModel.ARCHITECT:
				g.ColonyPanels.architecture_category(g,category)
				for i in range(4):check(g.buttons["architect_category_%d"%i].get_global_rect()==before[i],"Fixed left categories: "+category)
			g.ColonyPanels.architecture_category(g,"壁と扉");g.select_tool("wall");await process_frame
			check(g.buttons.wall.icon!=null and g.buttons.wall.size.y==96,"Construction grid uses building image")
			for kind in ["wall","wood_wall","stone_wall","soil_tile","wood_tile","stone_tile","door","locked_door","cooking_bench"]:check(g.ReviewUI.icon(kind)!=null,"Actual asset present: "+kind)
			check(g.colony_panel.has_node("BuildDescription"),"Selected construction has material details")
			layout(g,"architect",dimensions)
			var zid=w.Zones.create(w,"stockpile",Vector2i(31,25),Vector2i(32,25));g.zone_controls.open(g,zid);await process_frame
			var tree=g.colony_panel.find_child("StockpileFilters",true,false);var access=g.colony_panel.find_child("StockAccess",true,false)
			check(tree.visible and access.visible and not tree.get_global_rect().intersects(access.get_global_rect()),"Filters and access visible in separate columns")
			var cells=w.Zones.find(w,zid).cells.duplicate();var totals=w.Stock.totals(w).duplicate()
			access.find_child("Access_helper",true,false).toggled.emit(false);check(not w.Access.allowed_at(w,Vector2i(31,25),helper),"Permission callback retains restriction")
			g.colony_panel.get_node("ResetAccess").pressed.emit();check(w.Access.allowed_at(w,Vector2i(31,25),helper),"Reset returns outdoor access to existing default")
			g.zone_controls.rename(g,"食材置場");check(w.Zones.find(w,zid).cells==cells and w.Stock.totals(w)==totals,"Rename/access do not alter cells or items")
			await process_frame;layout(g,"stockpile",dimensions)
			g.neutral();house(Vector2i(15,15));ready("bed",Vector2i(17,17));w.refresh_indoor();w.Zones.create(w,"residential",Vector2i(16,16),Vector2i(18,18));w.Homes.assign_pending(w)
			g.selected={"kind":"house","id":w.homes.keys()[0]};g.refresh();await process_frame
			check(g.colony_panel.has_node("RoomPreview") and g.colony_panel.get_node("RoomPreview").tiles.size()>0,"House map from real cells")
			check(g.colony_panel.get_node("RoomPreview").tiles.all(func(t):return t.texture!=null or t.get("kind")=="bed"),"Room map has no missing wall/floor texture")
			check(g.colony_panel.get_node("HouseFacts").text.contains("ベッド：1"),"House bed count from data")
			layout(g,"house",dimensions)
			var cached=w.get_meta("room_preview_cache");g.refresh();check(w.get_meta("room_preview_cache")==cached,"Unchanged house reuses one bounded preview cache")
			w.invalidate_navigation();g.refresh();check(w.get_meta("room_preview_cache").revision==w.navigation_revision,"House topology invalidates preview cache")
		boot.queue_free();await process_frame
	var failed=checks.filter(func(c):return not c.passed).size()
	for entry in [["reference-ui.json",{"checks":checks,"count":checks.size(),"failed":failed}],["reference-ui-layouts.json",{"layouts":layouts}]]:
		var f=FileAccess.open(OS.get_environment("FARM_REVIEW_OUTPUT")+"/"+entry[0],FileAccess.WRITE);f.store_string(JSON.stringify(entry[1],"  "));f.close()
	print("Reference UI: %d checks, %d failed"%[checks.size(),failed]);quit(1 if failed else 0)
