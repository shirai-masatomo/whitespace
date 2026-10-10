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
		var p=panel(g,Rect2(16,430,864,312))
		label(p,"役割と現在の仕事",Vector2(18,12),21)
		label(p,"個人を選ぶと、状態と現在使える操作を開きます。",Vector2(18,43),14)
		var scroll=ScrollContainer.new();scroll.position=Vector2(16,79);scroll.size=Vector2(828,168);p.add_child(scroll)
		var list=VBoxContainer.new();list.size_flags_horizontal=Control.SIZE_EXPAND_FILL;scroll.add_child(list)
		for row in Model.people(g.world):
			var button=Button.new();button.name="Person_"+row.key;button.custom_minimum_size=Vector2(804,42);button.alignment=HORIZONTAL_ALIGNMENT_LEFT;button.focus_mode=Control.FOCUS_NONE
			button.text="%s　｜ %s　｜ %s　｜ HP %d/%d"%[row.name,row.role,row.state if row.state!="" else "待機",row.hp,row.max_hp]
			g.UI.button(button);button.pressed.connect(person_selected.bind(g,row));list.add_child(button)
		label(p,"予定は全体の番号順に実行します。",Vector2(18,258),15)
		label(p,"個人別の優先設定は、まだ変更できません。",Vector2(18,282),13)
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

static func signature(g) -> String:
	if g.colony_page=="roles":return str(Model.people(g.world))
	if g.group==1 and g.selected_animals.is_empty():return str(g.world.animals.map(func(a):return [a.id,a.get("name",""),a.state,a.hp,a.placed,g.world.Progression.loyalty(a)]))
	return ""
