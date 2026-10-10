extends RefCounted
const Model=preload("res://game/colony_view_model.gd")

static func label(parent: Control,text: String,at: Vector2,size: int=16):
	var node=Label.new();node.text=text;node.position=at;node.add_theme_font_size_override("font_size",size);node.add_theme_color_override("font_color",Color("354b3d"));parent.add_child(node)

static func panel(g,area: Rect2) -> Panel:
	var p=Panel.new();p.position=area.position;p.size=area.size;p.add_theme_stylebox_override("panel",g.UI.surface(g.UI.PAPER));g.palette.add_child(p);g.palette.move_child(p,0);g.colony_panel=p;return p

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
		if g.subtask_choices().is_empty():label(g.colony_panel,"今は使えるものがありません",Vector2(16,62),15)
	elif g.colony_page=="roles":
		var p=panel(g,Rect2(16,430,900,312))
		label(p,"役割と現在の仕事",Vector2(18,12),21)
		label(p,"各人が優先度と状態で仕事を選びます。数字は登録IDです。",Vector2(18,43),14)
		var scroll=ScrollContainer.new();scroll.position=Vector2(16,79);scroll.size=Vector2(864,186);p.add_child(scroll)
		var list=VBoxContainer.new();list.size_flags_horizontal=Control.SIZE_EXPAND_FILL;scroll.add_child(list)
		for row in Model.people(g.world):
			var button=Button.new();button.name="Person_"+row.key;button.custom_minimum_size=Vector2(840,38);button.alignment=HORIZONTAL_ALIGNMENT_LEFT;button.focus_mode=Control.FOCUS_NONE
			button.text="%s ｜ %s ｜ HP %d/%d"%[row.name,row.state if row.state!="" else row.role,row.hp,row.max_hp]
			g.UI.button(button);button.pressed.connect(person_selected.bind(g,row));list.add_child(button)
			if not g.world.workers.has(row.key):continue
			var priorities=HBoxContainer.new();list.add_child(priorities)
			var a=g.world.workers[row.key]
			for kind in g.world.Work.Policy.PRIORITIES:
				var choice=Button.new();choice.name="Priority_"+row.key+"_"+kind;choice.custom_minimum_size=Vector2(155,36);choice.focus_mode=Control.FOCUS_NONE
				choice.text=g.world.Work.Policy.LABELS[kind]+"："+["停止","高","中","低"][a.work_priorities[kind]]
				choice.tooltip_text="クリックで 高→中→低→停止。中断した進捗は保持します。"
				g.UI.button(choice);g.UI.selected(choice,a.work_priorities[kind]==1);choice.pressed.connect(priority_changed.bind(g,row.key,kind));priorities.add_child(choice)
			var draft=Button.new();draft.name="Draft_"+row.key;draft.custom_minimum_size=Vector2(155,36);draft.focus_mode=Control.FOCUS_NONE;draft.text="徴兵解除" if a.drafted else "徴兵する"
			g.UI.button(draft);g.UI.selected(draft,a.drafted);draft.pressed.connect(draft_changed.bind(g,row.key));priorities.add_child(draft)
		label(p,"徴兵中は自律作業を中断。解除後は現場と進捗を確認して復帰します。",Vector2(18,278),13)
	elif g.group==1 and g.selected_animals.is_empty():
		var animals=g.world.animals.filter(func(a):return a.get("category","")!="human")
		var p=panel(g,Rect2(16,430,864,312))
		label(p,"動物　%d匹"%animals.size(),Vector2(18,12),21)
		label(p,"個体を選んで、指示や装備を確認します。",Vector2(18,43),14)
		var scroll=ScrollContainer.new();scroll.position=Vector2(16,79);scroll.size=Vector2(828,205);p.add_child(scroll)
		var list=VBoxContainer.new();list.size_flags_horizontal=Control.SIZE_EXPAND_FILL;scroll.add_child(list)
		for a in animals:
			var button=Button.new();button.name="Animal_%d"%a.id;button.custom_minimum_size=Vector2(804,42);button.alignment=HORIZONTAL_ALIGNMENT_LEFT;button.focus_mode=Control.FOCUS_NONE
			button.text="%s　｜ 忠誠 %d　｜ HP %d/%d　｜ %s"%[g.world.animal_name(a),g.world.Progression.loyalty(a),a.hp,a.max_hp,a.state if a.placed else "到着待ち"]
			g.UI.button(button);button.pressed.connect(g.choose_animal.bind(a.id));list.add_child(button)
		if animals.is_empty():label(list,"仲間の動物はいません",Vector2.ZERO)

static func priority_changed(g,key: String,kind: String):
	var a=g.world.workers[key]
	g.world.Work.set_priority(g.world,key,kind,(a.work_priorities[kind]+1)%4)
	g.refresh()

static func draft_changed(g,key: String):
	g.world.Work.set_drafted(g.world,key,not g.world.workers[key].drafted)
	g.refresh()

static func signature(g) -> String:
	if g.colony_page=="roles":return str(Model.people(g.world))+str(g.world.keeper.get("work_priorities",{}))+str(g.world.keeper.get("drafted",false))
	if g.group==1 and g.selected_animals.is_empty():return str(g.world.animals.map(func(a):return [a.id,a.get("name",""),a.state,a.hp,a.placed,g.world.Progression.loyalty(a)]))
	return ""
