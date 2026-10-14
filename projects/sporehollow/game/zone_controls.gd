extends RefCounted
var pressed=false
var first=Vector2i.ZERO
var last=Vector2i.ZERO
var selected_id=-1
var details_open=false
var name_edit:LineEdit
var picker:OptionButton

func active(g) -> bool:return g.group==0 and g.architect_category=="ゾーン"
func select(g,kind:String):
	pressed=false;details_open=false;g.tool=kind;g.refresh()
func open(g,id:int):
	g.neutral();selected_id=id;details_open=true;g.selected={"kind":"zone","id":id};g.refresh()
func close(g):
	details_open=false
	if g.selected.get("kind")=="zone":g.selected.clear()
	g.refresh()
func resize(g):
	details_open=false;g.selected.clear();g.group=0;g.architect_category="ゾーン";g.tool="zone_resize";g.refresh()
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
		for entry in [["stockpile","備蓄追加",0],["residential","居住追加",1],["resize","範囲変更",2],["","指定取消",3]]:
			var id="zone_"+(entry[0] if entry[0]!="" else "cancel")
			g.add_button(g.palette,id,entry[1],Rect2(16+int(entry[2])*96,586,90,32),select.bind(g,"zone_"+entry[0] if entry[0]!="" else ""))
			g.ColonyPanels.compact_button(g,g.buttons[id],12);g.UI.architect_selected(g.buttons[id],g.tool=="zone_"+entry[0]);g.ColonyPanels.compact_button(g,g.buttons[id],12,true);g.buttons[id].size=Vector2(90,32)
		g.buttons.zone_resize.disabled=g.world.Zones.find(g.world,selected_id).is_empty()
		g.buttons.zone_resize.tooltip_text="最後に作成・選択したゾーンの範囲を変更"
	if not details_open:return
	var z=g.world.Zones.find(g.world,selected_id)
	if z.is_empty() or g.selected.get("kind")!="zone":details_open=false;return
	var stock=z.kind=="stockpile";var height=486 if stock else 226
	var p=g.ColonyPanels.panel(g,Rect2(8,742-height,410,height));p.name="ZoneDetails"
	picker=OptionButton.new();picker.name="ZoneSelector";picker.position=Vector2(12,7);picker.size=Vector2(296,30);p.add_child(picker);g.ColonyPanels.compact_button(g,picker,14)
	for zone in g.world.zones:picker.add_item(g.world.Zones.title(zone),zone.id)
	picker.select(picker.get_item_index(selected_id));picker.tooltip_text="ゾーンを切り替える"
	picker.item_selected.connect(func(index):open(g,picker.get_item_id(index)))
	var exit_button=Button.new();exit_button.name="CloseZone";exit_button.text="閉じる";exit_button.position=Vector2(318,7);exit_button.size=Vector2(80,30);p.add_child(exit_button);g.ColonyPanels.compact_button(g,exit_button);exit_button.pressed.connect(close.bind(g))
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
		var tree=Tree.new();tree.name="StockpileFilters";tree.position=Vector2(12,148);tree.size=Vector2(386,250);tree.hide_root=true;tree.add_theme_font_size_override("font_size",13);p.add_child(tree);var root=tree.create_item()
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
		g.ColonyPanels.label(p,"40個/マス · 既存物資は移動しません",Vector2(12,407),12)
	else:g.ColonyPanels.label(p,"到達可能な居住ゾーンで休息します。\n物資や建物は移動・削除しません。",Vector2(12,112),14)
	for entry in [["範囲変更",resize.bind(g),12],["ゾーン削除",remove.bind(g),210]]:
		var button=Button.new();button.text=entry[0];button.position=Vector2(entry[2],height-44);button.size=Vector2(188,32);p.add_child(button);g.ColonyPanels.compact_button(g,button);button.pressed.connect(entry[1])
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
			if g.pointer_over_ui():return true
			last=cell(g,event.position)
			if g.tool=="zone_resize":g.world.Zones.resize(g.world,selected_id,first,last)
			else:selected_id=g.world.Zones.create(g.world,g.tool.trim_prefix("zone_"),first,last)
			g.refresh();return true
	return false
func draw(g):
	for z in g.world.zones:
		var color=Color("8dc5c9") if z.kind=="stockpile" else Color("d7ba86")
		var cells={}
		for p in z.cells:cells[p]=true
		for p in z.cells:
			var corner=Vector2(p)*g.TILE;var selected=(active(g) or details_open) and z.id==selected_id
			g.draw_rect(Rect2(corner,g.TILE),Color(color,0.16 if selected else 0.04))
			for edge in [[Vector2i.UP,Vector2.ZERO,Vector2(g.TILE.x,0)],[Vector2i.RIGHT,Vector2(g.TILE.x,0),g.TILE],[Vector2i.DOWN,Vector2(0,g.TILE.y),g.TILE],[Vector2i.LEFT,Vector2.ZERO,Vector2(0,g.TILE.y)]]:
				if not cells.has(p+edge[0]):g.draw_line(corner+edge[1],corner+edge[2],color,3 if selected else 1)
		if (active(g) or (details_open and z.id==selected_id)) and not z.cells.is_empty():
			var at=g.center(z.cells[0])+Vector2(-17,-8)
			g.label_on(g,at,g.world.Zones.title(z),14,g.UI.INK)
	if not active(g) or not g.tool.begins_with("zone_") or g.pointer_over_ui():return
	var from=first if pressed else cell(g,g.pointer);var to=last if pressed else from
	var low=Vector2i(mini(from.x,to.x),mini(from.y,to.y));var high=Vector2i(maxi(from.x,to.x),maxi(from.y,to.y))
	var area=Rect2(Vector2(low)*g.TILE,Vector2(high-low+Vector2i.ONE)*g.TILE)
	g.draw_rect(area,Color(0.65,0.85,0.84,0.16));g.draw_rect(area,Color("f3df9e"),false,2)
	g.label_on(g,g.get_canvas_transform().affine_inverse()*g.pointer+Vector2(12,-12),"ゾーン %dマス"%g.world.Zones.cells_in(g.world,from,to).size(),15,g.UI.PAPER)

func filter_row(tree,parent,text,scope,key,ids,g,z):
	var row=tree.create_item(parent);row.set_cell_mode(0,TreeItem.CELL_MODE_CHECK);row.set_text(0,text);row.set_editable(0,true);row.set_metadata(0,[scope,key,ids]);set_check(row,g,z);return row
func set_check(row,g,z):
	var ids=row.get_metadata(0)[2];var enabled=ids.filter(func(id):return g.world.Zones.accepts_item(g.world,z,id)).size()
	row.set_checked(0,enabled==ids.size() and enabled>0);row.set_indeterminate(0,enabled>0 and enabled<ids.size())
func update_checks(parent,g,z):
	for child in parent.get_children():set_check(child,g,z);update_checks(child,g,z)
