extends RefCounted
const Model=preload("res://game/colony_view_model.gd")

static func label(parent: Control,text: String,at: Vector2,size: int=16):
	var node=Label.new();node.text=text;node.position=at;node.add_theme_font_size_override("font_size",size);node.add_theme_color_override("font_color",Color("354b3d"));parent.add_child(node)

static func panel(g,area: Rect2) -> Panel:
	var p=Panel.new();p.position=area.position;p.size=area.size;p.add_theme_stylebox_override("panel",g.UI.surface(g.UI.PAPER));g.palette.add_child(p);g.palette.move_child(p,0);g.colony_panel=p;return p

static func select_storage(g):
	g.group=0;g.colony_page="";g.architect_category="ゾーン";g.tool="zone_stockpile";g.refresh()

static func architecture_category(g,category: String):
	g.architect_category=category;g.tool="";g.cancel_wall_stroke();g.refresh()

static func person_selected(g,row: Dictionary):
	if row.key=="keeper":g.choose_walk()
	elif row.has("animal_id"):g.choose_animal(row.animal_id)
	elif g.world.workers.has(row.key):
		g.neutral();g.selected={"kind":"worker","key":row.key};g.refresh()

# Keep tab and tool geometry together; main uses architect_tool_rect for its buttons.
static func architect_area(g) -> Rect2:
	var rows=ceili(g.subtask_choices().size()/3.0)
	var height=82 if g.architect_category=="ゾーン" else 82+maxi(1,rows)*36
	return Rect2(8,742-height,402,height)

static func architect_tool_rect(g,index: int) -> Rect2:
	return Rect2(16+(index%3)*128,architect_area(g).position.y+78+floori(index/3.0)*36,120,32)

static func animal_tool_rect(index: int) -> Rect2:
	return Rect2(16+(index%6)*104,665+floori(index/6.0)*36,98,32)

static func portrait(g,species: String) -> Texture2D:
	var key=species+"/idle/right"
	if g.Art.CLIPS.has(key):return g.Art.CLIPS[key].frames[0]
	if species=="shiba":return preload("res://art_delivery/characters_v1/shiba_idle_right_00.png")
	if species in g.Direction.ACTORS:
		var art=g.Direction.ASSETS.get(("new."+species) if species in ["cow","bull"] else species+".idle",{})
		return art.get("texture",null)
	if species in g.ProgressArt.SPECIES:
		return g.Delivered.CLIPS[g.ProgressArt.clip(species,"idle",1)].frames[0]
	return g.Art.CLIPS["keeper/idle/right"].frames[0]

static func compact_button(g,button: Button,size: int=14):
	g.UI.button(button);button.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST;button.add_theme_font_size_override("font_size",size)
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
	label(p,"1 最優先 → 4 最低 · 空欄は停止 · 同順位は距離と条件で選択",Vector2(14,35),13)
	label(p,"人物",Vector2(18,59),13)
	var order=g.world.Work.Policy.ORDER
	for i in range(order.size()):label(p,g.world.Work.Policy.LABELS[order[i]],Vector2(224+i*60,59),13)
	var scroll=ScrollContainer.new();scroll.position=Vector2(12,80);scroll.size=Vector2(616,list_height)
	scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;p.add_child(scroll)
	var list=VBoxContainer.new();list.add_theme_constant_override("separation",2);list.size_flags_horizontal=Control.SIZE_EXPAND_FILL;scroll.add_child(list)
	for row in people:
		var line=HBoxContainer.new();line.add_theme_constant_override("separation",4);list.add_child(line)
		var person=Button.new();person.name="Person_"+row.key;person.custom_minimum_size=Vector2(200,32)
		person.alignment=HORIZONTAL_ALIGNMENT_LEFT;person.clip_text=true
		person.text=row.name;person.icon=portrait(g,"keeper" if row.key=="keeper" or not row.has("animal_id") else g.world.Orders.animal(g.world,row.animal_id).species);person.expand_icon=true;person.add_theme_constant_override("icon_max_width",22);person.disabled=not g.world.workers.has(row.key) and not row.has("animal_id")
		person.tooltip_text=row.name+" · クリックで個体を確認"
		compact_button(g,person);person.pressed.connect(person_selected.bind(g,row));line.add_child(person)
		var a=g.world.workers.get(row.key,{})
		for kind in order:
			var value=int(a.get("work_priorities",{}).get(kind,0))
			var choice=Button.new();choice.name="Priority_"+row.key+"_"+kind;choice.custom_minimum_size=Vector2(56,32)
			choice.text=str(value) if value>0 else "";choice.disabled=a.is_empty()
			choice.tooltip_text="%s / %s：%s\nクリックで 1 → 2 → 3 → 4 → 空欄 → 1。\n同順位は実行条件・経路・工程・待ち時間で選択。"%[row.name,g.world.Work.Policy.LABELS[kind],str(value) if value>0 else "停止"] if not a.is_empty() else "%sは固有の支援行動を行います"%row.name
			compact_button(g,choice,17);priority_style(choice,value);choice.pressed.connect(priority_changed.bind(g,row.key,kind));line.add_child(choice)

static func build(g):
	if not g.world.working() or g.field_book or g.field_shop or g.story_modal!="":return
	if g.group==0:
		var area=architect_area(g);panel(g,area)
		var index=0
		for category in Model.ARCHITECT:
			var id="architect_category_%d"%index
			g.add_button(g.palette,id,category,Rect2(16+(index%3)*128,area.position.y+8+floori(index/3.0)*32,120,28),architecture_category.bind(g,category))
			compact_button(g,g.buttons[id]);priority_style(g.buttons[id],1 if g.architect_category==category else 0);index+=1
		if g.architect_category!="ゾーン" and g.subtask_choices().is_empty():label(g.colony_panel,"今は使えるものがありません",Vector2(12,81),14)
	elif g.colony_page=="roles":build_roles(g)
	elif g.group==1 and g.animal_list_open:build_animals(g)

static func build_animals(g):
	var animals=g.world.animals.filter(func(a):return a.get("category","")!="human")
	var list_height=mini(160,maxi(34,animals.size()*34));var p=panel(g,Rect2(8,556-56-list_height,410,56+list_height))
	label(p,"動物　%d匹"%animals.size(),Vector2(12,8),18)
	for header in [["名前",16],["種類",126],["区分",172],["HP",236],["指示",298]]:label(p,header[0],Vector2(header[1],31),12)
	var scroll=ScrollContainer.new();scroll.name="AnimalScroll";scroll.position=Vector2(8,50);scroll.size=Vector2(394,list_height);scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;p.add_child(scroll)
	var list=VBoxContainer.new();list.add_theme_constant_override("separation",4);list.size_flags_horizontal=Control.SIZE_EXPAND_FILL;scroll.add_child(list)
	for a in animals:
		var line=HBoxContainer.new();line.custom_minimum_size.y=30;line.add_theme_constant_override("separation",4);list.add_child(line)
		var person=Button.new();person.name="Animal_%d"%a.id;person.text=g.world.animal_name(a);person.icon=portrait(g,a.species);person.expand_icon=true;person.add_theme_constant_override("icon_max_width",22);person.custom_minimum_size=Vector2(112,28);person.alignment=HORIZONTAL_ALIGNMENT_LEFT;person.clip_text=true;person.tooltip_text=g.world.animal_name(a);compact_button(g,person);person.pressed.connect(g.choose_animal.bind(a.id));line.add_child(person);g.UI.selected(person,a.id in g.selected_animals)
		var species=Label.new();species.text=g.world.SPECIES[a.species].title;species.clip_text=true;species.tooltip_text=species.text;species.custom_minimum_size=Vector2(42,28);species.add_theme_font_size_override("font_size",12);species.add_theme_color_override("font_color",g.UI.INK);line.add_child(species)
		var kind=Button.new();kind.name="AnimalClass_%d"%a.id;kind.text="家畜" if g.world.Livestock.classification(a)=="livestock" else "ペット";kind.custom_minimum_size=Vector2(60,28);kind.disabled=not g.world.Livestock.MEAT.has(a.species);compact_button(g,kind,12);kind.tooltip_text="家畜/ペットを切り替え。ペットはと殺しません。";kind.pressed.connect(g.LivestockControls.change_class.bind(g,a.id));line.add_child(kind)
		var hp=ProgressBar.new();hp.name="AnimalHP_%d"%a.id;hp.custom_minimum_size=Vector2(54,10);hp.size_flags_vertical=Control.SIZE_SHRINK_CENTER;hp.max_value=maxi(1,a.max_hp);hp.value=maxi(0,a.hp);hp.show_percentage=false;hp.tooltip_text="HP %d / %d"%[a.hp,a.max_hp]
		var fill=StyleBoxFlat.new();fill.bg_color=Color("bc7652") if a.hp<a.max_hp else Color("7c9b65");fill.set_corner_radius_all(3);hp.add_theme_stylebox_override("fill",fill);var back=StyleBoxFlat.new();back.bg_color=Color("d9d0b8");back.set_corner_radius_all(3);hp.add_theme_stylebox_override("background",back);line.add_child(hp)
		var control=Button.new();control.name="AnimalInstructions_%d"%a.id;control.text="指示";control.custom_minimum_size=Vector2(68,28);compact_button(g,control,13);control.pressed.connect(g.open_animal_commands.bind(a.id));line.add_child(control)
		if a.get("forbidden",false):line.modulate=Color("d2b4a0")
	if animals.is_empty():label(list,"仲間の動物はいません",Vector2.ZERO)

static func animal_reason(g,a,command: String) -> String:
	if command=="forbid":return "" if g.world.Livestock.owned(g.world,a) else "所有している動物だけ変更できます"
	if command=="train":return g.world.Tasks.training_reason(g.world,a,g.world.Tasks.job(g.world,"train",Vector2i.ZERO,a.id).get("id",-1))
	if command=="slaughter":return g.world.Livestock.reason(g.world,a,g.world.Livestock.job(g.world,a.id).get("id",-1))
	if command not in g.world.SPECIES[a.species].orders:return "この種類はこの指示に対応していません"
	if not a.placed or not g.world.available(a) or a.hp<=0:return "活動できる状態を待っています"
	if a.get("forbidden",false):return "動物の作業が禁止されています"
	return ""

static func animal_action(g,id: int,command: String):
	if command=="forbid":g.LivestockControls.forbid(g,id)
	elif command=="slaughter":g.LivestockControls.designate(g,id)
	elif command=="train":g.TaskControls.task(g,"train",Vector2i.ZERO,id)
	else:
		g.choose_animal(id)
		g.select_tool(command)


static func priority_changed(g,key: String,kind: String):
	var a=g.world.workers[key]
	g.world.Work.set_priority(g.world,key,kind,(a.work_priorities[kind]+1)%5)
	g.refresh()

static func draft_changed(g,key: String):
	g.world.Work.set_drafted(g.world,key,not g.world.workers[key].drafted)
	g.refresh()

static func signature(g) -> String:
	if g.group==1:return str(g.world.animals.map(func(a):return [a.id,a.get("name",""),a.hp,a.placed,a.get("dead",false),a.get("husbandry_class",""),a.get("forbidden",false),a.get("last_training_day",-1),g.world.Progression.loyalty(a)]))+str(g.world.jobs.filter(func(j):return j.kind in ["train","slaughter"]).map(func(j):return [j.id,j.get("cancel_requested",false)]))
	if g.colony_page=="roles":
		var states=[]
		for key in g.world.workers:
			var a=g.world.workers[key];states.append([key,a.get("work_priorities",{}),a.get("drafted",false)])
		return str(Model.people(g.world).map(func(row):return [row.key,row.name,row.role]))+str(states)
	if g.group==1 and g.selected_animals.is_empty():return str(g.world.animals.map(func(a):return [a.id,a.get("name",""),a.state,a.hp,a.placed,g.world.Progression.loyalty(a)]))
	return ""

static func build_animal_commands(g):
	if not g.animal_commands_open or g.selected.get("kind")!="animal":return
	var a=g.world.Orders.animal(g.world,g.selected.id)
	if a.is_empty():return
	var choices=g.subtask_choices()
	for command in ["train","slaughter","forbid"]:
		if command=="train" and a.species not in g.world.Tasks.TRAIN_SPECIES:continue
		if command=="slaughter" and not g.world.Livestock.MEAT.has(a.species):continue
		choices.append(command)
	for i in range(choices.size()):
		var id=choices[i];var text=g.TOOLS.get(id,{"train":"調教","slaughter":"と殺","forbid":"許可" if a.get("forbidden",false) else "禁止"}.get(id,id))
		var callback=animal_action.bind(g,a.id,id) if id in ["train","slaughter","forbid"] else g.select_tool.bind(id)
		g.add_button(g.palette,id,text,Rect2(16+(i%5)*90,660+floori(i/5.0)*38,84,34),callback)
		compact_button(g,g.buttons[id],13)
		var why=animal_reason(g,a,id) if id not in ["equip","milk"] else ""
		if id=="equip" and a.get("forbidden",false):why="動物の作業が禁止されています"
		g.buttons[id].disabled=why!="";g.buttons[id].tooltip_text=why if why!="" else g.ORDER_HELP.get(id,text+"：選択した個体に適用")
		g.UI.selected(g.buttons[id],g.tool==id)
	if g.equipment_open:g.ProgressView.equipment_buttons(g)
