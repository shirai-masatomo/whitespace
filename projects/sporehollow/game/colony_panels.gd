extends RefCounted
const Model=preload("res://game/colony_view_model.gd")

static func label(parent: Control,text: String,at: Vector2,size: int=16):
	var node=Label.new();node.text=text;node.position=at;node.add_theme_font_size_override("font_size",size);node.add_theme_color_override("font_color",Color("354b3d"));parent.add_child(node)

static func panel(g,area: Rect2) -> Panel:
	var p=Panel.new();p.position=area.position;p.size=area.size;p.add_theme_stylebox_override("panel",g.UI.surface(g.UI.PAPER));g.palette.add_child(p);g.palette.move_child(p,0);g.colony_panel=p;return p

static func research_save(g):
	var paused=g.world.paused
	if g.menu_open:g.world.paused=g.menu_was_paused
	var saved=g.world.Snapshot.save(g.world,g.development_save_path)
	g.world.paused=paused
	g.save_status="保存しました" if saved else "保存できませんでした"
	g.notice(g.save_status)
	if g.menu_open:g.ColonyMenu.build(g)

static func research_load(g):
	var path=g.development_save_path if FileAccess.file_exists(g.development_save_path) else "user://autonomy.snapshot"
	var restored=g.world.Snapshot.restore(path)
	if restored==null:
		g.save_status="保存を読み込めません。今の牧場は変更していません"
		if g.menu_open:g.ColonyMenu.build(g)
		return
	g.save_load_blocked=false
	var in_menu=g.menu_open
	g.world=restored;g.reset_view();g.menu_open=in_menu;g.menu.visible=in_menu;g.menu_was_paused=restored.paused
	if g.menu_open:g.world.paused=true
	g.save_status="保存した牧場を読み込みました";g.refresh();g.notice(g.save_status)
	if g.menu_open:g.ColonyMenu.build(g)

static func select_storage(g):
	g.group=0;g.colony_page="";g.architect_category="ゾーン";g.tool="zone_stockpile";g.refresh()

static func architecture_category(g,category: String):
	g.architect_category=category;g.tool="";g.cancel_wall_stroke();g.refresh()

static func person_selected(g,row: Dictionary):
	if row.key=="keeper":g.choose_walk()
	elif row.has("animal_id"):g.choose_animal(row.animal_id)

# Keep tab and tool geometry together; main uses architect_tool_rect for its buttons.
static func architect_area(g) -> Rect2:
	var rows=ceili(g.subtask_choices().size()/6.0)
	var height=44 if g.architect_category=="ゾーン" else 50+maxi(1,rows)*36
	return Rect2(8,742-height,688,height)

static func architect_tool_rect(g,index: int) -> Rect2:
	return Rect2(16+(index%6)*112,architect_area(g).position.y+42+floori(index/6.0)*36,104,32)

static func compact_button(g,button: Button,size: int=14):
	g.UI.button(button);button.add_theme_font_size_override("font_size",size)
	button.focus_mode=Control.FOCUS_NONE
	for state in ["normal","hover","pressed","disabled"]:
		var style=button.get_theme_stylebox(state).duplicate()
		for side in [SIDE_LEFT,SIDE_RIGHT]:style.set_content_margin(side,5)
		for side in [SIDE_TOP,SIDE_BOTTOM]:style.set_content_margin(side,3)
		button.add_theme_stylebox_override(state,style)

static func priority_style(button: Button,value: int):
	var colors=[Color("f5efdf"),Color("d2e5ba"),Color("e5e9c7"),Color("f1e8cf"),Color("eee9df")]
	for state in ["normal","hover","pressed","disabled"]:
		var box=StyleBoxFlat.new();box.bg_color=colors[value]
		if state=="hover":box.bg_color=Color("fff9e9")
		elif state=="pressed":box.bg_color=Color("bacd9f")
		elif state=="disabled":box.bg_color=Color("e5e2d8")
		box.border_color=Color("aab598") if state=="normal" else Color("6d8662")
		box.set_border_width_all(1);box.set_corner_radius_all(3)
		box.content_margin_top=3;box.content_margin_bottom=3
		button.add_theme_stylebox_override(state,box)

static func build_roles(g):
	var people=Model.people(g.world)
	var list_height=mini(174,maxi(34,people.size()*34))
	var panel_height=94+list_height
	var p=panel(g,Rect2(16,742-panel_height,640,panel_height))
	label(p,"仕事の優先度",Vector2(14,9),19)
	label(p,"1 最優先 → 4 最低 · 空欄は停止 · 同じ数字は左から",Vector2(14,35),13)
	label(p,"人 / 状態",Vector2(18,59),13)
	var order=g.world.Work.Policy.ORDER
	for i in range(order.size()):label(p,g.world.Work.Policy.LABELS[order[i]],Vector2(224+i*60,59),13)
	var scroll=ScrollContainer.new();scroll.position=Vector2(12,80);scroll.size=Vector2(616,list_height)
	scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;p.add_child(scroll)
	var list=VBoxContainer.new();list.add_theme_constant_override("separation",2);list.size_flags_horizontal=Control.SIZE_EXPAND_FILL;scroll.add_child(list)
	for row in people:
		var line=HBoxContainer.new();line.add_theme_constant_override("separation",4);list.add_child(line)
		var person=Button.new();person.name="Person_"+row.key;person.custom_minimum_size=Vector2(200,32)
		person.alignment=HORIZONTAL_ALIGNMENT_LEFT;person.clip_text=true
		person.text=row.name;person.disabled=row.key!="keeper" and not row.has("animal_id")
		person.tooltip_text="%s · HP %d/%d\n%s\nクリックで個体を確認"%[row.name,row.hp,row.max_hp,row.state if row.state!="" else row.role]
		compact_button(g,person);person.pressed.connect(person_selected.bind(g,row));line.add_child(person)
		var a=g.world.workers.get(row.key,{})
		for kind in order:
			var value=int(a.get("work_priorities",{}).get(kind,0))
			var choice=Button.new();choice.name="Priority_"+row.key+"_"+kind;choice.custom_minimum_size=Vector2(56,32)
			choice.text=str(value) if value>0 else "";choice.disabled=a.is_empty()
			choice.tooltip_text="%s / %s：%s\nクリックで 1 → 2 → 3 → 4 → 空欄 → 1。\n同じ数字は左の仕事から。"%[row.name,g.world.Work.Policy.LABELS[kind],str(value) if value>0 else "停止"] if not a.is_empty() else "%sは固有の支援行動を行います"%row.name
			compact_button(g,choice,17);priority_style(choice,value);choice.pressed.connect(priority_changed.bind(g,row.key,kind));line.add_child(choice)

static func build(g):
	if not g.world.working() or g.field_book or g.field_shop or g.story_modal!="":return
	if g.group==0:
		var area=architect_area(g);panel(g,area)
		var index=0
		for category in Model.ARCHITECT:
			var id="architect_category_%d"%index
			g.add_button(g.palette,id,category,Rect2(16+index*112,area.position.y+8,104,28),architecture_category.bind(g,category))
			compact_button(g,g.buttons[id]);priority_style(g.buttons[id],1 if g.architect_category==category else 0);index+=1
		if g.architect_category!="ゾーン" and g.subtask_choices().is_empty():label(g.colony_panel,"今は使えるものがありません",Vector2(12,47),14)
	elif g.colony_page=="roles":build_roles(g)
	elif g.group==1 and g.selected_animals.is_empty():
		var animals=g.world.animals.filter(func(a):return a.get("category","")!="human")
		var list_height=mini(190,maxi(34,animals.size()*36))
		var panel_height=70+list_height
		var p=panel(g,Rect2(16,742-panel_height,640,panel_height))
		label(p,"動物　%d匹"%animals.size(),Vector2(14,9),19)
		label(p,"個体を選んで、指示や装備を確認",Vector2(14,35),13)
		var scroll=ScrollContainer.new();scroll.position=Vector2(12,58);scroll.size=Vector2(616,list_height)
		scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;p.add_child(scroll)
		var list=VBoxContainer.new();list.add_theme_constant_override("separation",2);list.size_flags_horizontal=Control.SIZE_EXPAND_FILL;scroll.add_child(list)
		for a in animals:
			var button=Button.new();button.name="Animal_%d"%a.id;button.custom_minimum_size=Vector2(594,34);button.alignment=HORIZONTAL_ALIGNMENT_LEFT;button.clip_text=true
			button.text="%s (%s) ｜ 忠誠 %d ｜ HP %d/%d ｜ %s"%[g.world.animal_name(a),"家畜" if g.world.Livestock.classification(a)=="livestock" else "ペット",g.world.Progression.loyalty(a),a.hp,a.max_hp,a.state if a.placed else "到着待ち"]
			button.tooltip_text=button.text;compact_button(g,button);button.pressed.connect(g.choose_animal.bind(a.id));list.add_child(button)
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
	if g.colony_page=="roles":
		var states=[]
		for key in g.world.workers:
			var a=g.world.workers[key];states.append([key,a.get("work_priorities",{}),a.get("drafted",false)])
		return str(Model.people(g.world))+str(states)
	if g.group==1 and g.selected_animals.is_empty():return str(g.world.animals.map(func(a):return [a.id,a.get("name",""),a.state,a.hp,a.placed,g.world.Progression.loyalty(a)]))
	return ""
