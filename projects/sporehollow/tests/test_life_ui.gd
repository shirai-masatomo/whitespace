extends "res://tests/test_housing_sleep.gd"
func run():
	var boot=load("res://game/loading.tscn").instantiate();boot.review_mode=true;root.add_child(boot)
	var deadline=Time.get_ticks_msec()+25000
	while not boot.finished and boot.failure=="" and Time.get_ticks_msec()<deadline:await process_frame
	check(boot.finished,"Production loading ready with life features")
	if boot.finished:
		var g=boot.game;g.set_process(false);g.world=fixture();g.world.paused=true;g.story_modal="";g.field_book=false;g.field_shop=false
		var helper=g.world.keeper.duplicate(true);helper.name="田中";g.world.Work.register(g.world,"helper",helper)
		g.neutral();g.refresh();check(g.buttons.has("life_main"),"Main screen life entry")
		g.select_group(3);check(g.buttons.time_tab.text=="生活","Roles opens same life screen")
		g.HomeUI.open_schedule(g,"helper");check(g.life_actor=="helper" and g.colony_page=="life","Individual opens selected human")
		g.schedule_brush="free";var hours=g.colony_panel.find_children("*","Control",true,false).filter(func(c):return c.get_script()==g.HomeUI.Hours)[0];hours.paint(0);hours.paint(4*24)
		check(helper.pending_timetable[4]=="free","Existing24-hour drag edits chosen resident")
		g.HomeUI.tab(g,"food");var choice=g.colony_panel.find_child("Food_raw0",true,false);choice.item_selected.emit(0)
		check(helper.food_order[0]=="raw:0" and not g.world.keeper.has("food_order"),"Priority UI changes only selected resident")
		g.HomeUI.person(g,"keeper");g.HomeUI.person(g,"helper");check(helper.food_order[0]=="raw:0","Resident switch retains food settings")
		for dimensions in [Vector2i(1280,800),Vector2i(1600,1000)]:
			root.size=dimensions;g.refresh();await process_frame
			var panel=g.colony_panel;var area=Rect2(Vector2.ZERO,panel.size)
			check(panel.position.y>=49 and panel.position.x+panel.size.x<=1280 and panel.position.y+panel.size.y<=742,"Life panel fits logical canvas "+str(dimensions))
			check(panel.find_children("Food_*","OptionButton",true,false).size()==8,"Eight unique matrix controls "+str(dimensions))
			var scroll=panel.find_child("LifeContent",true,false);check(scroll.vertical_scroll_mode==ScrollContainer.SCROLL_MODE_SHOW_ALWAYS,"Visible scroll track "+str(dimensions))
			check(panel.find_children("*","Control",true,false).filter(func(c):return c.get_script()==g.HomeUI.Hours).is_empty(),"Food tab does not duplicate timetable panel")
		g.buttons.life_main.pressed.emit();check(g.life_return.get("page")=="roles" and g.life_actor=="helper","Reopening life preserves return origin and resident")
		g.HomeUI.back(g);check(g.colony_page=="roles","Back restores role origin")
		g.neutral();g.selected={"kind":"worker","key":"helper"};g.refresh();g.buttons.time_tab.pressed.emit();check(g.life_actor=="helper","Individual status callback passes actual identity")
		g.HomeUI.back(g);check(g.selected.get("key")=="helper","Back restores individual status")
		var zid=g.world.Zones.create(g.world,"stockpile",Vector2i(31,25),Vector2i(32,25));g.zone_controls.open(g,zid);g.zone_controls.access_tab=true;g.refresh()
		var access=g.colony_panel.find_child("StockAccess",true,false)
		check(access!=null and not g.colony_panel.find_child("StockpileFilters",true,false).visible,"Access editor replaces filter tree without duplicate large panels")
		access.find_child("Access_helper",true,false).toggled.emit(false)
		check(not g.world.Access.allowed_at(g.world,Vector2i(31,25),helper),"Access checkbox edits actual withdrawal permission")
		var text=g.world.Resident.describe(helper);check("満足度" in text,"Resident details expose satisfaction and traits")
		boot.queue_free();await process_frame
	var failed=checks.filter(func(c):return not c.passed).size()
	var f=FileAccess.open(OS.get_environment("FARM_REVIEW_OUTPUT")+"/life-ui.json",FileAccess.WRITE);f.store_string(JSON.stringify({"checks":checks,"count":checks.size(),"failed":failed},"  "));f.close()
	print("Life UI: %d checks, %d failures"%[checks.size(),failed]);quit(1 if failed else 0)
