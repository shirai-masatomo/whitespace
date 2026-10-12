extends RefCounted
var pressed=false
var first=Vector2i.ZERO
var last=Vector2i.ZERO
var selected_id=-1

func active(g) -> bool:return g.group==0 and g.architect_category=="ゾーン"
func select(g,kind: String):pressed=false;g.tool=kind;g.refresh()
func choose(g,index: int,ids: Array):selected_id=ids[index];g.tool="";g.refresh()
func remove(g):
	if g.world.Zones.remove(g.world,selected_id):selected_id=-1;g.tool="";g.notice("ゾーンを削除しました。物資は元の場所に残ります。")
	g.refresh()
func toggle(g,kind: String):
	var z=g.world.Zones.find(g.world,selected_id)
	if z.is_empty():return
	var allowed=z.allowed.duplicate()
	if kind in allowed:allowed.erase(kind)
	else:allowed.append(kind)
	g.world.Zones.set_allowed(g.world,z.id,allowed);g.refresh()
func build(g):
	if not active(g) or not g.world.working() or g.field_shop or g.field_book or g.story_modal!="":return
	var top=g.ColonyPanels.architect_area(g).position.y-208
	var p=g.ColonyPanels.panel(g,Rect2(8,top,402,204))
	g.ColonyPanels.label(p,"ゾーン · クリック / 範囲指定",Vector2(12,8),15)
	for entry in [["stockpile","備蓄追加",0],["residential","居住追加",1],["resize","範囲変更",2],["","指定取消",3]]:
		var id="zone_"+(entry[0] if entry[0]!="" else "cancel")
		g.add_button(g.palette,id,entry[1],Rect2(20+int(entry[2])*96,top+36,90,32),select.bind(g,"zone_"+entry[0] if entry[0]!="" else ""));g.ColonyPanels.compact_button(g,g.buttons[id],12);g.UI.selected(g.buttons[id],g.tool=="zone_"+entry[0])
	var ids=[];var dropdown=OptionButton.new();dropdown.name="ZoneList";dropdown.position=Vector2(20,top+76);dropdown.size=Vector2(280,30);dropdown.focus_mode=Control.FOCUS_NONE;dropdown.add_theme_font_size_override("font_size",13);g.UI.button(dropdown);g.palette.add_child(dropdown)
	for z in g.world.zones:
		ids.append(z.id);dropdown.add_item("%s · %dマス"%["備蓄" if z.kind=="stockpile" else "居住",z.cells.size()])
	if selected_id not in ids:selected_id=ids[0] if not ids.is_empty() else -1
	if not ids.is_empty():dropdown.select(ids.find(selected_id))
	else:dropdown.add_item("ゾーン未指定");dropdown.disabled=true
	dropdown.item_selected.connect(func(index):choose(g,index,ids))
	g.add_button(g.palette,"zone_delete","削除",Rect2(310,top+76,88,30),remove.bind(g));g.buttons.zone_delete.disabled=selected_id<0;g.buttons.zone_resize.disabled=selected_id<0
	var z=g.world.Zones.find(g.world,selected_id)
	if not z.is_empty() and z.kind=="stockpile":
		var index=0
		for kind in g.world.Zones.TYPES:
			var id="zone_type_"+kind;g.add_button(g.palette,id,g.world.Zones.TYPES[kind],Rect2(20+(index%3)*128,top+116+floori(index/3.0)*32,120,28),toggle.bind(g,kind));g.ColonyPanels.compact_button(g,g.buttons[id],12);g.UI.selected(g.buttons[id],kind in z.allowed);index+=1
		g.ColonyPanels.label(p,"40個/マス · 搬入は命令の「回収」で指定",Vector2(12,182),12)
	else: g.ColonyPanels.label(p,"到達可能な居住ゾーンで休息します。\n物資や建物を移動・削除しません。",Vector2(12,120),14)
func cell(g,point: Vector2) -> Vector2i:return Vector2i((g.get_canvas_transform().affine_inverse()*point/g.TILE).floor())
func input(g,event) -> bool:
	if not active(g) or not g.world.working() or g.menu_open or g.field_shop or g.field_book or g.story_modal!="" or g.cinematic():pressed=false;return false
	if (event is InputEventKey and event.pressed and event.physical_keycode==KEY_ESCAPE) or (event is InputEventMouseButton and event.pressed and event.button_index==MOUSE_BUTTON_RIGHT):select(g,"");return true
	if event is InputEventMouseMotion:last=cell(g,event.position);return pressed
	if event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT:
		if event.pressed:
			if g.pointer_over_ui():return false
			if not g.tool.begins_with("zone_"):
				for z in g.world.zones:
					if cell(g,event.position) in z.cells:selected_id=z.id;g.refresh();return true
				return true
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
			var corner=Vector2(p)*g.TILE;var selected=active(g) and z.id==selected_id
			g.draw_rect(Rect2(corner,g.TILE),Color(color,0.16 if selected else 0.09))
			for edge in [[Vector2i.UP,Vector2.ZERO,Vector2(g.TILE.x,0)],[Vector2i.RIGHT,Vector2(g.TILE.x,0),g.TILE],[Vector2i.DOWN,Vector2(0,g.TILE.y),g.TILE],[Vector2i.LEFT,Vector2.ZERO,Vector2(0,g.TILE.y)]]:
				if not cells.has(p+edge[0]):g.draw_line(corner+edge[1],corner+edge[2],color,2)
		if active(g) and not z.cells.is_empty():
			var at=g.center(z.cells[0])+Vector2(-17,-8)
			g.label_on(g,at,"備蓄" if z.kind=="stockpile" else "休息",14,g.UI.INK)
	if not active(g) or not g.tool.begins_with("zone_") or g.pointer_over_ui():return
	var from=first if pressed else cell(g,g.pointer);var to=last if pressed else from
	var low=Vector2i(mini(from.x,to.x),mini(from.y,to.y));var high=Vector2i(maxi(from.x,to.x),maxi(from.y,to.y))
	var area=Rect2(Vector2(low)*g.TILE,Vector2(high-low+Vector2i.ONE)*g.TILE)
	g.draw_rect(area,Color(0.65,0.85,0.84,0.16));g.draw_rect(area,Color("f3df9e"),false,2)
	g.label_on(g,g.get_canvas_transform().affine_inverse()*g.pointer+Vector2(12,-12),"ゾーン %dマス"%g.world.Zones.cells_in(g.world,from,to).size(),15,g.UI.PAPER)
