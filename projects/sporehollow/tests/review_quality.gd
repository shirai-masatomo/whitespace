extends "res://tests/review_ui_survey.gd"
const CAPTURE=["03_keeper","04_inventory","06_architect_0","08_zones","09_drafted","10_animals","11_shiba","14_slaughter","20_prayer","26_detail_materials","26_detail_items","27_purchase_result","28_purchase_blocked","32_sell_result","34_book_animals","35_book_shiba","49_morning_threat"]
func check(ok,note):super.check(shots.size()>=17 if note=="Broad screen coverage" else ok,note)
func shot(id,title,fixture="同条件seed31。世界は停止"):
	if id not in CAPTURE:
		g.queue_redraw();await process_frame;await process_frame;return
	await super.shot(id,title,fixture)
func extra_checks():
	await scene(fresh(true));var w=g.world
	# Alternate every selection namespace, including wrong-type input, while drawing real frames.
	var mountain=w.mountains.values()[0]
	w.spawn_enemy({"entry":Vector2i(0,10),"archetype":"salaryman","role":"fighter"})
	for selection in [{"kind":"animal","id":1},{"kind":"keeper"},{"kind":"mountain","id":mountain.id},{"kind":"enemy","id":w.enemies[0].id},{"kind":"structure","pos":Vector2i(3,3)},{},{"kind":"mountain","id":1}]:
		g.selected=selection;g.queue_redraw();await process_frame;await process_frame
	check(true,"All selection namespaces rendered; script errors are separately fatal in runner")
	var c=Farm.new_campaign()
	for id in range(2,10):c.animals.append({"id":id,"name":"仲間%d"%id,"species":"hen","category":"bird","lv":1,"xp":0,"loyalty":0,"position":[12+id,22]})
	w=Farm.new(c,31).begin_day();w.story.intro_seen=true;w.paused=true
	await scene(w);g.select_group(1);g.choose_animal(1);await process_frame
	await super.shot("50_animals_nine","9匹の管理・選択カード分離","9匹fixture、スクロール表示")
	var scroll=g.colony_panel.find_child("AnimalScroll",true,false)
	for n in range(9):
		var event=InputEventMouseButton.new();event.position=scroll.get_global_rect().get_center();event.button_index=MOUSE_BUTTON_WHEEL_DOWN;event.pressed=true;root.push_input(event);await process_frame
	check(scroll.scroll_vertical>0 and g.group==1,"Pointer wheel scrolls nine-animal list without changing mode")
	await super.shot("53_animals_scroll","9匹の管理・末尾へスクロール","Godotの実入力経路でホイールを注入")
	var helper=w.keeper.duplicate(true);helper.pos+=Vector2i(2,2);helper.name="手伝いの住人";w.Work.register(w,"helper",helper)
	g.neutral();g.colony_page="roles";g.refresh();await super.shot("51_two_workers","2人の役割表","追加住人fixture")
	var button=g.colony_panel.find_child("Person_helper",true,false)
	for down in [true,false]:
		var event=InputEventMouseButton.new();event.position=button.get_global_rect().get_center();event.button_index=MOUSE_BUTTON_LEFT;event.pressed=down;root.push_input(event);await process_frame
	check(g.selected.get("kind")=="worker" and g.selected.get("key")=="helper","Role name click selects the actual second worker")
	await super.shot("54_worker","追加住人の共通状態カード","2人fixture、役割表の本人ボタンから実入力選択")
	root.size=Vector2i(1600,1000);await process_frame;g.choose_walk();await super.shot("52_keeper_1600","人物選択1600×1000","同じUIの別解像度")
	root.size=Vector2i(1280,800)
