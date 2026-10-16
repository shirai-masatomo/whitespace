extends RefCounted
var pressed=false
var first=Vector2i.ZERO
var last=Vector2i.ZERO
var selected_id=-1
var details_open=false
var name_edit:LineEdit
var picker:OptionButton
var access_tab=false

func active(g) -> bool:return g.group==0 and g.architect_category=="ゾーン"
func select(g,kind:String):
	pressed=false;details_open=false;g.tool=kind;g.refresh()
func open(g,id:int):
	g.neutral();selected_id=id;details_open=true;g.selected={"kind":"zone","id":id};g.refresh()
func close(g):
	details_open=false
	if g.selected.get("kind")=="zone":g.selected.clear()
	g.refresh()
func resize(g,erase:bool=false):
	details_open=false;g.selected.clear();g.group=0;g.architect_category="ゾーン";g.tool="zone_subtract" if erase else "zone_resize";g.refresh()
func remove(g):
	if g.world.Zones.remove(g.world,selected_id):
		selected_id=-1;details_open=false;g.selected.clear();g.tool="";g.notice("ゾーンを削除しました。物資は元の場所に残ります。")
	g.refresh()
func rename(g,text:String):
	g.world.Zones.rename(g.world,selected_id,text)
	if is_instance_valid(name_edit):name_edit.text=g.world.Zones.title(g.world.Zones.find(g.world,selected_id))
	if is_instance_valid(picker):
		for i in range(picker.item_count):picker.set_item_text(i,g.world.Zones.title(g.world.Zones.find(g.world,picker.get_item_id(i))))
	g.queue_redraw()
func build(g):
	if not g.world.working() or g.field_shop or g.field_book or g.story_modal!="":return
	if active(g):
		# Creation palette has no filter editor and never opens details during a stroke.
		for entry in [["stockpile","備蓄追加",0],["residential","居住追加",1],["resize","範囲変更",2],["cancel","指定取消",3]]:
			var id="zone_"+(entry[0] if entry[0]!="" else "cancel")
			g.add_button(g.palette,id,entry[1],Rect2(144+(int(entry[2])%2)*208,458+(int(entry[2])/2)*48,196,36),select.bind(g,"zone_"+entry[0] if entry[0]!="" else ""))
			g.ColonyPanels.compact_button(g,g.buttons[id],12);g.UI.architect_selected(g.buttons[id],g.tool=="zone_"+entry[0]);g.ColonyPanels.compact_button(g,g.buttons[id],12,true);g.buttons[id].size=Vector2(196,36)
		g.buttons.zone_resize.disabled=g.world.Zones.find(g.world,selected_id).is_empty()
		g.buttons.zone_resize.tooltip_text="最後に作成・選択したゾーンの範囲を変更"
	if not details_open:return
	var z=g.world.Zones.find(g.world,selected_id)
	if z.is_empty() or g.selected.get("kind")!="zone":details_open=false;return
	var stock=z.kind=="stockpile";var height=400 if stock else 226
	var p=g.ColonyPanels.panel(g,Rect2(16,742-height,896,height));p.name="ZoneDetails"
	picker=OptionButton.new();picker.name="ZoneSelector";picker.position=Vector2(12,7);picker.size=Vector2(296,30);p.add_child(picker);g.ColonyPanels.compact_button(g,picker,14)
	for zone in g.world.zones:picker.add_item(g.world.Zones.title(zone),zone.id)
	picker.select(picker.get_item_index(selected_id));picker.tooltip_text="ゾーンを切り替える"
	picker.item_selected.connect(func(index):open(g,picker.get_item_id(index)))
	var exit_button=Button.new();exit_button.name="CloseZone";exit_button.text="閉じる";exit_button.position=Vector2(790,10);exit_button.size=Vector2(92,30);p.add_child(exit_button);g.ColonyPanels.compact_button(g,exit_button);exit_button.pressed.connect(close.bind(g))
	name_edit=LineEdit.new();name_edit.name="ZoneName";name_edit.position=Vector2(12,44);name_edit.size=Vector2(296,32);name_edit.max_length=32;name_edit.text=g.world.Zones.title(z);p.add_child(name_edit)
	name_edit.focus_entered.connect(func():g.keys_down.clear());name_edit.text_submitted.connect(func(text):rename(g,text);name_edit.release_focus())
	name_edit.focus_exited.connect(func():
		if is_instance_valid(name_edit) and name_edit.is_inside_tree() and not g.world.Zones.find(g.world,selected_id).is_empty():rename(g,name_edit.text))
	var apply=Button.new();apply.name="RenameZone";apply.text="変更";apply.position=Vector2(318,44);apply.size=Vector2(80,32);p.add_child(apply);g.ColonyPanels.compact_button(g,apply);apply.pressed.connect(func():rename(g,name_edit.text))
	var bounds=Rect2i(z.cells[0],Vector2i.ONE)
	for cell in z.cells:bounds=bounds.merge(Rect2i(cell,Vector2i.ONE))
	g.ColonyPanels.label(p,"%s · %dマス · 範囲 %d × %d"%["備蓄" if stock else "居住",z.cells.size(),bounds.size.x,bounds.size.y],Vector2(12,82),13)
	if stock:
		for entry in [["全許可",true,0],["全禁止",false,1]]:
			var button=Button.new();button.text=entry[0];button.position=Vector2(12+entry[2]*88,110);button.size=Vector2(82,30);p.add_child(button);g.ColonyPanels.compact_button(g,button);button.pressed.connect(func():g.world.Zones.filter_change(g.world,z.id,"all","",entry[1]);g.refresh())
		var priority=OptionButton.new();priority.name="ZonePriority";priority.position=Vector2(198,110);priority.size=Vector2(200,30);priority.focus_mode=Control.FOCUS_NONE;p.add_child(priority);g.ColonyPanels.compact_button(g,priority,13);priority.size=Vector2(200,30)
		for text in ["優先度：低","優先度：通常","優先度：高"]:priority.add_item(text)
		priority.select(z.get("priority",1));priority.item_selected.connect(func(i):g.world.Zones.set_priority(g.world,z.id,i))
		g.ColonyPanels.label(p,"保管するアイテム",Vector2(12,152),16)
		g.ColonyPanels.label(p,"利用権限（持ち出せる住民）",Vector2(464,78),16)
		var scroll=ScrollContainer.new();scroll.name="StockAccess";scroll.position=Vector2(464,108);scroll.size=Vector2(414,196);scroll.vertical_scroll_mode=ScrollContainer.SCROLL_MODE_SHOW_ALWAYS;p.add_child(scroll);g.ColonyPanels.readable_scroll(scroll)
		var list=VBoxContainer.new();scroll.add_child(list)
		for key in g.world.Sleep.people(g.world):
			var a=g.world.Sleep.people(g.world)[key];var allowed=z.cells.filter(func(q):return g.world.Access.allowed_at(g.world,q,a)).size()
			var check=CheckBox.new();check.name="Access_"+key;check.text=g.world.PlayerEvents.name_of(g.world,a)+("（部屋ごとに異なります）" if allowed>0 and allowed<z.cells.size() else "");check.button_pressed=allowed==z.cells.size();check.custom_minimum_size=Vector2(390,30);list.add_child(check);check.toggled.connect(func(value):g.world.Access.set_permission(g.world,z,key,value);g.refresh())
		var tree=Tree.new();tree.name="StockpileFilters";tree.position=Vector2(12,184);tree.size=Vector2(426,156);tree.visible=true;tree.hide_root=true;tree.add_theme_font_size_override("font_size",13);p.add_child(tree);var root=tree.create_item()
		# Godot Tree owns its own scrollbar; keep a legible track/thumb.
		var track=StyleBoxFlat.new();track.bg_color=Color("ddd5bf");track.content_margin_left=7;track.content_margin_right=7
		var grab=StyleBoxFlat.new();grab.bg_color=Color("718261");grab.set_corner_radius_all(3)
		tree.theme=Theme.new();tree.theme.set_stylebox("scroll","VScrollBar",track)
		for state in ["grabber","grabber_highlight","grabber_pressed"]:tree.theme.set_stylebox(state,"VScrollBar",grab)
		var catalog=g.world.Zones.Catalog
		for main in catalog.CATEGORIES:
			var main_ids=catalog.ROWS.keys().filter(func(id):return catalog.item(id).category==main)
			var parent=filter_row(tree,root,catalog.CATEGORIES[main][0],"categories",main,main_ids,g,z)
			for sub in catalog.CATEGORIES[main][1]:
				var sub_ids=main_ids.filter(func(id):return catalog.item(id).subcategory==sub)
				var branch=filter_row(tree,parent,catalog.CATEGORIES[main][1][sub],"subs",sub,sub_ids,g,z)
				for id in sub_ids:filter_row(tree,branch,catalog.title(id),"items",id,[id],g,z)
				branch.collapsed=true
			parent.collapsed=true
		tree.item_edited.connect(func():
			var item=tree.get_edited();var meta=item.get_metadata(0)
			g.world.Zones.filter_change(g.world,z.id,meta[0],meta[1],item.is_checked(0));update_checks(tree.get_root(),g,z))
		g.ColonyPanels.label(p,"40個/マス · 既存物資は移動しません",Vector2(12,344),12)
		g.ColonyPanels.label(p,"初期設定：居住者を許可。屋外は全員。\n手動設定が優先されます。通行・搬入は可能。",Vector2(464,310),12)
		var reset=Button.new();reset.name="ResetAccess";reset.text="利用権限を既定に戻す";reset.position=Vector2(464,358);reset.size=Vector2(414,30);p.add_child(reset);g.ColonyPanels.compact_button(g,reset)
		reset.pressed.connect(func():z.erase("access_cells");g.world.Access.changed(g.world);g.refresh())
	else:g.ColonyPanels.label(p,"到達可能な居住ゾーンで休息します。\n物資や建物は移動・削除しません。",Vector2(12,112),14)
	for entry in [["マス追加",resize.bind(g),12],["マス削除",resize.bind(g,true),142],["全体削除",remove.bind(g),272]]:
		var button=Button.new();button.text=entry[0];button.position=Vector2(entry[2],height-32);button.size=Vector2(126,28);p.add_child(button);g.ColonyPanels.compact_button(g,button);button.pressed.connect(entry[1])
func cell(g,point:Vector2) -> Vector2i:return Vector2i((g.get_canvas_transform().affine_inverse()*point/g.TILE).floor())
func input(g,event) -> bool:
	if not active(g) or not g.world.working() or g.menu_open or g.field_shop or g.field_book or g.story_modal!="" or g.cinematic():pressed=false;return false
	if event is InputEventMouseMotion:last=cell(g,event.position);return pressed
	if event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT:
		if event.pressed:
			if g.pointer_over_ui() or not g.tool.begins_with("zone_"):return false
			first=cell(g,event.position);last=first;pressed=true;return true
		elif pressed:
			pressed=false
			last=cell(g,event.position)
			if g.tool in ["zone_subtract","zone_cancel"]:
				var n=g.world.Zones.subtract(g.world,g.world.Zones.cells_in(g.world,first,last),selected_id if g.tool=="zone_subtract" else -1)
				g.notice("ゾーン%dマスの指定を解除しました。物資はその場に残ります"%n)
			elif g.tool=="zone_resize":
				var z=g.world.Zones.find(g.world,selected_id)
				if not z.is_empty():selected_id=g.world.Zones.add_cells(g.world,z.kind,g.world.Zones.cells_in(g.world,first,last))
			else:selected_id=g.world.Zones.create(g.world,g.tool.trim_prefix("zone_"),first,last)
			g.refresh();return true
	return false
func draw(g):
	for z in g.world.zones:
		var color=Color("83e9f5") if z.kind=="stockpile" else Color("e4adff")
		var cells={}
		for p in z.cells:cells[p]=true
		for p in z.cells:
			var corner=Vector2(p)*g.TILE;var selected=(active(g) or details_open) and z.id==selected_id
			g.draw_rect(Rect2(corner,g.TILE),Color(color,0.20 if selected else 0.08))
			for edge in [[Vector2i.UP,Vector2.ZERO,Vector2(g.TILE.x,0)],[Vector2i.RIGHT,Vector2(g.TILE.x,0),g.TILE],[Vector2i.DOWN,Vector2(0,g.TILE.y),g.TILE],[Vector2i.LEFT,Vector2.ZERO,Vector2(0,g.TILE.y)]]:
				if not cells.has(p+edge[0]):
					g.draw_line(corner+edge[1],corner+edge[2],Color("2a333b"),5 if selected else 3)
					g.draw_line(corner+edge[1],corner+edge[2],color,3 if selected else 1.8)

	if not active(g) or not g.tool.begins_with("zone_") or g.pointer_over_ui():return
	var from=first if pressed else cell(g,g.pointer);var to=last if pressed else from
	var low=Vector2i(mini(from.x,to.x),mini(from.y,to.y));var high=Vector2i(maxi(from.x,to.x),maxi(from.y,to.y))
	var area=Rect2(Vector2(low)*g.TILE,Vector2(high-low+Vector2i.ONE)*g.TILE)
	g.draw_rect(area,Color(0.9,0.3,0.25,0.3) if g.tool in ["zone_cancel","zone_subtract"] else Color(0.65,0.85,0.84,0.16));g.draw_rect(area,Color("f3df9e"),false,2)
	g.label_on(g,g.get_canvas_transform().affine_inverse()*g.pointer+Vector2(12,-12),"ゾーン %dマス"%g.world.Zones.cells_in(g.world,from,to).size(),15,g.UI.PAPER)

func filter_row(tree,parent,text,scope,key,ids,g,z):
	var row=tree.create_item(parent);row.set_cell_mode(0,TreeItem.CELL_MODE_CHECK);row.set_text(0,text);row.set_editable(0,true);row.set_metadata(0,[scope,key,ids]);set_check(row,g,z);return row
func set_check(row,g,z):
	var ids=row.get_metadata(0)[2];var enabled=ids.filter(func(id):return g.world.Zones.accepts_item(g.world,z,id)).size()
	row.set_checked(0,enabled==ids.size() and enabled>0);row.set_indeterminate(0,enabled>0 and enabled<ids.size())
func update_checks(parent,g,z):
	for child in parent.get_children():set_check(child,g,z);update_checks(child,g,z)

func draw_labels(g):
	for z in g.world.zones:
		if not (active(g) or details_open and z.id==selected_id) or z.cells.is_empty():continue
		var first_visible=null
		for p in z.cells:
			var screen=g.get_canvas_transform()*g.center(p)
			if Rect2(0,50,1280,690).has_point(screen):first_visible=screen;break
		if first_visible==null:continue
		var text=g.world.Zones.title(z);var width=g.FONT.get_string_size(text,HORIZONTAL_ALIGNMENT_LEFT,-1,14).x+16
		var at=(first_visible+Vector2(-17,-8)).clamp(Vector2(8,76),Vector2(1272-width,725))
		g.hud.draw_style_box(g.UI.surface(Color("f1eddb")),Rect2(at-Vector2(5,18),Vector2(width,25)))
		g.label_on(g.hud,at,text,14,g.UI.INK)
