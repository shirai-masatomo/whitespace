extends RefCounted
const Model=preload("res://game/colony_view_model.gd")

static func label(parent: Control,text: String,at: Vector2,size: int=16):
	var node=Label.new();node.text=text;node.position=at;node.add_theme_font_size_override("font_size",size);node.add_theme_color_override("font_color",Color("354b3d"));parent.add_child(node)

static func panel(g,area: Rect2) -> Panel:
	var p=Panel.new();p.position=area.position;p.size=area.size;p.add_theme_stylebox_override("panel",g.UI.surface(g.UI.PAPER));g.palette.add_child(p);g.palette.move_child(p,0);g.colony_panel=p;return p

static func research_save(g):
	g.notice("状態を保存しました" if g.world.Snapshot.save(g.world,g.development_save_path) else "保存できませんでした")

static func research_load(g):
	var path=g.development_save_path if FileAccess.file_exists(g.development_save_path) else "user://autonomy.snapshot"
	var restored=g.world.Snapshot.restore(path)
	if restored==null:g.notice("保存がありません");return
	g.world=restored;g.reset_view();g.colony_page="roles";g.group=2;g.refresh();g.notice("状態を読み込みました")

static func select_storage(g):
	g.group=0;g.colony_page="";g.architect_category="ゾーン";g.tool="zone_stockpile";g.refresh()

static func architecture_category(g,category: String):
	g.architect_category=category;g.tool="";g.cancel_wall_stroke();g.refresh()

static func person_selected(g,row: Dictionary):
	if row.key=="keeper":g.choose_walk()
	else:g.choose_animal(row.animal_id)

static func build(g):
	if not g.world.working() or g.field_book or g.field_shop or g.story_modal!="":return
	if g.group==0:
		panel(g,Rect2(8,623,996,122))
		var index=0
		for category in Model.ARCHITECT:
			var id="architect_category_%d"%index
			g.add_button(g.palette,id,category,Rect2(16+index*154,631,146,32),architecture_category.bind(g,category))
			g.UI.selected(g.buttons[id],g.architect_category==category);index+=1
		if g.architect_category!="ゾーン" and g.subtask_choices().is_empty():label(g.colony_panel,"今は使えるものがありません",Vector2(16,62),15)
	elif g.colony_page=="roles":
		var people=Model.people(g.world)
		var list_height=mini(186,maxi(96,people.size()*96))
		var panel_height=127+list_height
		var p=panel(g,Rect2(16,742-panel_height,900,panel_height))
		label(p,"役割と現在の仕事",Vector2(18,12),21)
		label(p,"優先：1 最優先 / 2 高 / 3 低 / 4 最低 / 空欄 停止。同じ優先は左から。",Vector2(18,43),14)
		var scroll=ScrollContainer.new();scroll.position=Vector2(16,79);scroll.size=Vector2(864,list_height);p.add_child(scroll)
		var list=VBoxContainer.new();list.size_flags_horizontal=Control.SIZE_EXPAND_FILL;scroll.add_child(list)
		for row in people:
			var button=Button.new();button.name="Person_"+row.key;button.custom_minimum_size=Vector2(840,38);button.alignment=HORIZONTAL_ALIGNMENT_LEFT;button.focus_mode=Control.FOCUS_NONE
			button.text="%s ｜ %s ｜ HP %d/%d"%[row.name,row.state if row.state!="" else row.role,row.hp,row.max_hp]
			g.UI.button(button);button.pressed.connect(person_selected.bind(g,row));list.add_child(button)
			if not g.world.workers.has(row.key):continue
			var priorities=HBoxContainer.new();list.add_child(priorities)
			var a=g.world.workers[row.key]
			for kind in g.world.Work.Policy.ORDER:
				var choice=Button.new();choice.name="Priority_"+row.key+"_"+kind;choice.custom_minimum_size=Vector2(132,36);choice.focus_mode=Control.FOCUS_NONE
				choice.text=g.world.Work.Policy.LABELS[kind]+"　"+(str(a.work_priorities[kind]) if a.work_priorities[kind]>0 else "")
				choice.tooltip_text="クリックで1→2→3→4→空欄。同優先は左のカテゴリから選択。"
				g.UI.button(choice);choice.add_theme_font_size_override("font_size",14);g.UI.selected(choice,a.work_priorities[kind]==1);choice.pressed.connect(priority_changed.bind(g,row.key,kind));priorities.add_child(choice)
			var draft=Button.new();draft.name="Draft_"+row.key;draft.custom_minimum_size=Vector2(132,36);draft.focus_mode=Control.FOCUS_NONE;draft.text="徴兵解除" if a.drafted else "徴兵する"
			g.UI.button(draft);draft.add_theme_font_size_override("font_size",14);g.UI.selected(draft,a.drafted);draft.pressed.connect(draft_changed.bind(g,row.key));priorities.add_child(draft)
		g.add_button(g.palette,"storage_zone","ゾーンを開く",Rect2(34,696,180,34),select_storage.bind(g))
		g.UI.selected(g.buttons.storage_zone,g.tool=="storage")
		label(p,"地面をクリック。40個/マス（仮）",Vector2(212,panel_height-34),13)
		g.add_button(g.palette,"research_save","保存",Rect2(636,696,122,34),research_save.bind(g))
		g.add_button(g.palette,"research_load","読込",Rect2(770,696,122,34),research_load.bind(g))
	elif g.group==1 and g.selected_animals.is_empty():
		var animals=g.world.animals.filter(func(a):return a.get("category","")!="human")
		var p=panel(g,Rect2(16,430,864,312))
		label(p,"動物　%d匹"%animals.size(),Vector2(18,12),21)
		label(p,"個体を選んで、指示や装備を確認します。",Vector2(18,43),14)
		var scroll=ScrollContainer.new();scroll.position=Vector2(16,79);scroll.size=Vector2(828,205);p.add_child(scroll)
		var list=VBoxContainer.new();list.size_flags_horizontal=Control.SIZE_EXPAND_FILL;scroll.add_child(list)
		for a in animals:
			var button=Button.new();button.name="Animal_%d"%a.id;button.custom_minimum_size=Vector2(804,42);button.alignment=HORIZONTAL_ALIGNMENT_LEFT;button.focus_mode=Control.FOCUS_NONE
			button.text="%s (%s) ｜ 忠誠 %d ｜ HP %d/%d ｜ %s"%[g.world.animal_name(a),"家畜" if g.world.Livestock.classification(a)=="livestock" else "ペット",g.world.Progression.loyalty(a),a.hp,a.max_hp,a.state if a.placed else "到着待ち"]
			g.UI.button(button);button.pressed.connect(g.choose_animal.bind(a.id));list.add_child(button)
		if animals.is_empty():label(list,"仲間の動物はいません",Vector2.ZERO)

static func priority_changed(g,key: String,kind: String):
	var a=g.world.workers[key]
	g.world.Work.set_priority(g.world,key,kind,(a.work_priorities[kind]+1)%5)
	g.refresh()

static func draft_changed(g,key: String):
	g.world.Work.set_drafted(g.world,key,not g.world.workers[key].drafted)
	g.refresh()

static func signature(g) -> String:
	if g.group==1 and not g.selected_animals.is_empty():return g.LivestockControls.signature(g)
	if g.colony_page=="roles":return str(Model.people(g.world))+str(g.world.keeper.get("work_priorities",{}))+str(g.world.keeper.get("drafted",false))
	if g.group==1 and g.selected_animals.is_empty():return str(g.world.animals.map(func(a):return [a.id,a.get("name",""),a.state,a.hp,a.placed,g.world.Progression.loyalty(a)]))
	return ""
