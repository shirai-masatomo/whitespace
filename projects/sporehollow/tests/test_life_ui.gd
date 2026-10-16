extends "res://tests/test_housing_sleep.gd"
var layouts=[]
func collect_nodes(node,rows):
	if node is Control and not node.is_visible_in_tree():return
	if node is Control:
		var rect=node.get_global_rect();var row={"name":node.name,"type":node.get_class(),"rect":[rect.position.x,rect.position.y,rect.size.x,rect.size.y]}
		if node is Label or node is Button:row.text=node.text;row.font=node.get_theme_font_size("font_size")
		if node is Button:
			var style=node.get_theme_stylebox("normal")
			if style is StyleBoxFlat:row.color=style.bg_color.to_html()
			elif style is StyleBoxTexture:row.color=style.modulate_color.to_html()
		if node.get_script()==preload("res://game/home_ui.gd").Hours:row.hours=node.actor.get("pending_timetable",node.actor.timetable)
		rows.append(row)
	for child in node.get_children(true):collect_nodes(child,rows)
func capture(g,title,dimensions):
	var rows=[];collect_nodes(g.colony_panel,rows)
	for id in ["group0","group1","roles","commands","life_main"]:
		if g.buttons.has(id):collect_nodes(g.buttons[id],rows)
	layouts.append({"name":title,"window":[dimensions.x,dimensions.y],"nodes":rows})
func migration():
	var prefs=preload("res://game/food_preferences.gd")
	var legacy=prefs.COMBINATIONS.duplicate();legacy.reverse();var a={"food_order":legacy.duplicate()}
	prefs.initialize(a)
	check(prefs.CELL_ORDER.all(func(key):return prefs.value(a,key)==legacy.find(key)+1) and a.food_order==legacy,"Legacy rank permutation migrates losslessly without rewriting original")
	var before=a.food_priorities.duplicate();prefs.change(a,"cooked:0",1)
	check(a.food_priorities.keys().all(func(key):return key=="cooked:0" or a.food_priorities[key]==before[key]),"Changing one cell never swaps another")
	for key in prefs.CELL_ORDER:prefs.change(a,key,1)
	var expected=prefs.order(a)
	check(expected==preload("res://game/work_policy.gd").HUMAN_FOOD,"All equal ranks use cooked/raw row then tier then existing item order")
	for i in range(20):check(prefs.order(a)==expected,"Stable tie ordering repeat "+str(i))
	var restored=JSON.parse_string(JSON.stringify(a));prefs.initialize(restored)
	check(prefs.order(restored)==expected and restored.food_priorities.values().all(func(v):return int(v)==1),"JSON round trip retains duplicate ranks")
	var partial={"food_order":legacy,"food_priorities":{"raw:0":3,"raw:1":3}};prefs.initialize(partial)
	check(partial.food_priorities.size()==8 and partial.food_priorities["raw:0"]==3 and partial.food_priorities["raw:1"]==3,"Partial newer data keeps equal values and fills missing cells")
func run():
	migration()
	var boot=load("res://game/loading.tscn").instantiate();boot.review_mode=true;root.add_child(boot)
	var deadline=Time.get_ticks_msec()+25000
	while not boot.finished and boot.failure=="" and Time.get_ticks_msec()<deadline:await process_frame
	check(boot.finished,"Production loading ready with life features")
	if boot.finished:
		var g=boot.game;g.set_process(false);g.world=fixture();g.world.paused=true;g.story_modal="";g.field_book=false;g.field_shop=false
		var helper=g.world.keeper.duplicate(true);helper.name="田中";g.world.Work.register(g.world,"helper",helper)
		g.neutral();g.refresh();check(g.buttons.has("life_main"),"Main screen life entry")
		g.buttons.life_main.pressed.emit();check(g.colony_page=="life","Bottom menu callback opens life");g.buttons.life_back.pressed.emit()
		g.selected={"kind":"worker","key":"helper"};g.select_group(3);check(g.buttons.time_tab.text=="生活" and g.roles_actor=="helper","Roles preserves selected resident")
		g.buttons.time_tab.pressed.emit();check(g.life_actor=="helper","Roles life callback uses selected human");g.HomeUI.back(g)
		g.colony_panel.find_child("RoleLifeResident",true,false).item_selected.emit(0);g.buttons.time_tab.pressed.emit();check(g.life_actor=="keeper","Roles resident picker chooses keeper");g.HomeUI.back(g)
		g.HomeUI.open_schedule(g,"helper");check(g.life_actor=="helper" and g.colony_page=="life","Individual opens selected human")
		g.schedule_brush="free";var hours=g.colony_panel.find_children("*","Control",true,false).filter(func(c):return c.get_script()==g.HomeUI.Hours)[0];hours.paint(0);hours.paint(4*24)
		check(helper.pending_timetable[4]=="free","Existing24-hour drag edits chosen resident")
		g.HomeUI.tab(g,"food");var choice=g.colony_panel.find_child("Food_raw0",true,false);choice.item_selected.emit(0)
		check(helper.food_priorities["raw:0"]==1 and g.world.FoodPrefs.value(g.world.keeper,"raw:0")==8,"Priority UI changes only selected resident")
		g.HomeUI.person(g,"keeper");g.HomeUI.person(g,"helper");check(helper.food_priorities["raw:0"]==1,"Resident switch retains food settings")
		g.colony_panel.find_child("Food_cooked0",true,false).item_selected.emit(0)
		check(helper.food_priorities["raw:0"]==1 and helper.food_priorities["cooked:0"]==1 and helper.food_priorities["cooked:3"]==1,"UI permits three tied cells without swaps")
		for dimensions in [Vector2i(1280,800),Vector2i(1600,1000)]:
			root.size=dimensions;g.refresh();await process_frame
			var panel=g.colony_panel;var area=Rect2(Vector2.ZERO,panel.size)
			check(panel.position.y>=49 and panel.position.x+panel.size.x<=1280 and panel.position.y+panel.size.y<=742,"Life panel fits logical canvas "+str(dimensions))
			check(panel.find_children("Food_*","OptionButton",true,false).size()==8,"Eight unique matrix controls "+str(dimensions))
			var scroll=panel.find_child("LifeContent",true,false);check(scroll.vertical_scroll_mode==ScrollContainer.SCROLL_MODE_SHOW_ALWAYS,"Visible scroll track "+str(dimensions))
			check(panel.find_children("*","Control",true,false).filter(func(c):return c.get_script()==g.HomeUI.Hours).is_empty(),"Food tab does not duplicate timetable panel")
			var summary=panel.find_child("LifeSummary",true,false)
			check(not summary.get_global_rect().intersects(g.buttons.life_food.get_global_rect()) and not summary.get_global_rect().intersects(g.buttons.life_back.get_global_rect()),"Header buttons do not overlap resident information")
			check(summary.text.split("\n").size()==2 and "生活タイプ" in summary.text and "食欲" in summary.text,"Life information fits two labelled lines")
			var choices=panel.find_children("Food_*","OptionButton",true,false)
			check(choices.all(func(c):return c.size.y==choices[0].size.y and c.position.x+c.size.x<=746),"Matrix controls align and fit content width")
			capture(g,"food",dimensions)
			var header=g.buttons.life_food.get_global_rect()
			g.buttons.life_schedule.pressed.emit();await process_frame
			check(g.buttons.life_food.get_global_rect()==header,"Tab switch preserves shared header coordinates")
			check(not g.colony_panel.find_child("ScheduleHours",true,false).get_global_rect().intersects(g.buttons.life_wake.get_global_rect()),"Wake action does not overlap hours")
			check(g.colony_panel.position.y+g.colony_panel.size.y<=g.buttons.life_main.position.y,"Life panel stays above main navigation")
			capture(g,"schedule",dimensions)
			g.HomeUI.back(g);await process_frame
			check(g.buttons.time_tab.position.y+g.buttons.time_tab.size.y<=43,"Role life button does not overlap description")
			capture(g,"roles",dimensions)
			g.HomeUI.open_schedule(g,"helper");g.HomeUI.tab(g,"food")
		g.buttons.life_main.pressed.emit();check(g.life_return.get("page")=="roles" and g.life_actor=="helper","Reopening life preserves return origin and resident")
		g.HomeUI.back(g);check(g.colony_page=="roles","Back restores role origin")
		g.neutral();g.selected={"kind":"worker","key":"helper"};g.refresh();g.buttons.time_tab.pressed.emit();check(g.life_actor=="helper","Individual status callback passes actual identity")
		g.HomeUI.back(g);check(g.selected.get("key")=="helper","Back restores individual status")
		var zid=g.world.Zones.create(g.world,"stockpile",Vector2i(31,25),Vector2i(32,25));g.zone_controls.open(g,zid);g.zone_controls.access_tab=true;g.refresh()
		var access=g.colony_panel.find_child("StockAccess",true,false)
		check(access!=null and g.colony_panel.find_child("StockpileFilters",true,false).visible,"Access and filters share a single two-column panel")
		access.find_child("Access_helper",true,false).toggled.emit(false)
		check(not g.world.Access.allowed_at(g.world,Vector2i(31,25),helper),"Access checkbox edits actual withdrawal permission")
		var text=g.world.Resident.describe(helper);check("満足度" in text,"Resident details expose satisfaction and traits")
		boot.queue_free();await process_frame
	var layout_file=FileAccess.open(OS.get_environment("FARM_REVIEW_OUTPUT")+"/life-layouts.json",FileAccess.WRITE);layout_file.store_string(JSON.stringify({"layouts":layouts},"  "));layout_file.close()
	var failed=checks.filter(func(c):return not c.passed).size()
	var f=FileAccess.open(OS.get_environment("FARM_REVIEW_OUTPUT")+"/life-ui.json",FileAccess.WRITE);f.store_string(JSON.stringify({"checks":checks,"count":checks.size(),"failed":failed},"  "));f.close()
	print("Life UI: %d checks, %d failures"%[checks.size(),failed]);quit(1 if failed else 0)
