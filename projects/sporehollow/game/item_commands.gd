extends RefCounted
const LABELS={"haul":"回収","forbid":"禁止","allow":"禁止解除"}
var pressed=false
var first=Vector2i.ZERO
var last=Vector2i.ZERO
func select(g,kind: String):
	pressed=false;g.tool=kind;g.refresh()
func build(g):
	if g.group!=4 or not g.world.working() or g.field_shop or g.field_book:return
	var p=g.ColonyPanels.panel(g,Rect2(8,647,730,96))
	g.ColonyPanels.label(p,"現物をクリック / 矩形ドラッグで指定。右クリック・Escで解除。",Vector2(12,10),15)
	var i=0
	for kind in LABELS:
		g.add_button(g.palette,"command_"+kind,LABELS[kind],Rect2(20+i*174,685,164,42),select.bind(g,kind))
		g.UI.selected(g.buttons["command_"+kind],g.tool==kind)
		g.buttons["command_"+kind].tooltip_text="地面の物資を保管域へ運ぶ仕事を登録。重複は登録しません。" if kind=="haul" else "未消費の現物に適用。建築・食事・装備・運搬・売却の利用可否を切り替えます。"
		i+=1
	g.add_button(g.palette,"command_clear","解除",Rect2(542,685,176,42),select.bind(g,""))
func cell(g,point: Vector2) -> Vector2i:return Vector2i((g.get_canvas_transform().affine_inverse()*point/g.TILE).floor())
func input(g,event) -> bool:
	if g.group!=4 or not g.world.working() or g.menu_open or g.field_shop or g.field_book or g.story_modal!="" or g.cinematic():pressed=false;return false
	if not LABELS.has(g.tool):return false
	if (event is InputEventKey and event.pressed and event.physical_keycode==KEY_ESCAPE) or (event is InputEventMouseButton and event.pressed and event.button_index==MOUSE_BUTTON_RIGHT):select(g,"");return true
	if event is InputEventMouseMotion:
		last=cell(g,event.position)
		return pressed
	if event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT:
		if event.pressed:
			if g.pointer_over_ui():return false
			first=cell(g,event.position);last=first;pressed=true;return true
		elif pressed:
			pressed=false
			if g.pointer_over_ui():return true
			last=cell(g,event.position)
			var result=g.world.Stock.designate(g.world,g.tool,first,last)
			g.notice("%s：%d件指定 / %d件登録済み・対象外"%[LABELS[g.tool],result.accepted,result.skipped]);g.refresh();return true
	return false
func draw(g):
	for row in g.world.field_items:
		if not row.get("forbidden",false):continue
		var q=g.center(g.world.Stock.command_pos(g.world,row))
		g.draw_line(q+Vector2(-9,-9),q+Vector2(9,9),Color("be5044"),3);g.draw_line(q+Vector2(-9,9),q+Vector2(9,-9),Color("be5044"),3)
	if g.group!=4 or not LABELS.has(g.tool) or g.pointer_over_ui():return
	var from=first if pressed else cell(g,g.pointer);var to=last if pressed else from
	var low=Vector2i(mini(from.x,to.x),mini(from.y,to.y));var high=Vector2i(maxi(from.x,to.x),maxi(from.y,to.y))
	var area=Rect2(Vector2(low)*g.TILE,Vector2(high-low+Vector2i.ONE)*g.TILE)
	g.draw_rect(area,Color(0.8,0.85,0.65,0.15));g.draw_rect(area,Color("f3df9e"),false,2)
	var targets=g.world.Stock.command_targets(g.world,from,to,g.tool)
	for row in targets:g.draw_rect(Rect2(g.center(g.world.Stock.command_pos(g.world,row))-Vector2(15,15),Vector2(30,30)),Color("ffeab4"),false,3)
	g.label_on(g,g.get_canvas_transform().affine_inverse()*g.pointer+Vector2(12,-12),"%s %d件"%[LABELS[g.tool],targets.size()],15,g.UI.PAPER)
