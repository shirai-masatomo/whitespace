extends RefCounted
const LABELS={"haul":"回収","forbid":"禁止","allow":"許可","clear":"キャンセル","mine":"採掘","clear_tree":"伐採"}
var pressed=false
var first=Vector2i.ZERO
var last=Vector2i.ZERO
func select(g,kind: String):
	pressed=false;g.tool=kind;g.refresh()
func build(g):
	if g.group!=4 or not g.world.working() or g.field_shop or g.field_book:return
	var p=g.ColonyPanels.panel(g,Rect2(8,665,702,78))
	g.ColonyPanels.label(p,"クリック / 範囲指定 · 右クリックで選択解除",Vector2(12,8),14)
	var i=0
	for kind in LABELS:
		g.add_button(g.palette,"command_"+kind,LABELS[kind],Rect2(16+i*114,697,108,36),select.bind(g,kind))
		g.UI.selected(g.buttons["command_"+kind],g.tool==kind)
		g.buttons["command_"+kind].tooltip_text="地面の物資を保管域へ運ぶ仕事を登録。重複は登録しません。" if kind=="haul" else ("範囲内の取消可能な仕事をキャンセル。建物や物資は削除しません。" if kind=="clear" else "物資の禁止/許可を変更。許可しても回収は登録しません。")
		if kind in g.world.Harvest.KINDS:g.buttons["command_"+kind].tooltip_text="採集担当が対象ごとに現地作業。成果は回収命令で備蓄へ運びます。"
		i+=1
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
			last=cell(g,event.position)
			var result=g.world.Stock.designate(g.world,g.tool,first,last)
			g.notice("%s：%d件指定 / %d件登録済み・対象外"%[LABELS[g.tool],result.accepted,result.skipped]);g.refresh();return true
	return false
func draw(g):
	if g.group!=4 or not LABELS.has(g.tool) or g.pointer_over_ui():return
	var from=first if pressed else cell(g,g.pointer);var to=last if pressed else from
	var low=Vector2i(mini(from.x,to.x),mini(from.y,to.y));var high=Vector2i(maxi(from.x,to.x),maxi(from.y,to.y))
	var area=Rect2(Vector2(low)*g.TILE,Vector2(high-low+Vector2i.ONE)*g.TILE)
	g.draw_rect(area,Color(0.8,0.85,0.65,0.15));g.draw_rect(area,Color("f3df9e"),false,2)
	var targets=g.world.Harvest.cells(g.world,from,to,g.tool).map(func(p):return {"pos":p}) if g.tool in g.world.Harvest.KINDS else (g.world.Stock.cancel_targets(g.world,from,to) if g.tool=="clear" else g.world.Stock.command_targets(g.world,from,to,g.tool))
	if g.tool in ["forbid","allow"]:
		targets.append_array(g.world.Harvest.cells(g.world,from,to).map(func(p):return {"pos":p}))
		var rect=Rect2i(low,high-low+Vector2i.ONE)
		for p in g.world.natural:
			if rect.has_point(p) and g.world.natural_forbidden.get(p,false)!=(g.tool=="forbid"):targets.append({"pos":p})
		for a in g.world.animals:
			if rect.has_point(a.pos) and g.world.Livestock.owned(g.world,a) and a.get("forbidden",false)!=(g.tool=="forbid"):targets.append({"pos":a.pos})
	var drawn={}
	for row in targets:
		var mountain=g.world.Mountains.resource(g.world,row.pos) if g.tool in ["mine","clear","forbid","allow"] else {}
		if not mountain.is_empty():
			if drawn.has(mountain.id):continue
			drawn[mountain.id]=true
			var cells=g.world.Mountains.footprint(mountain)
			if cells.is_empty():continue
			var bounds=Rect2(Vector2(cells[0])*g.TILE,g.TILE)
			for p in cells:bounds=bounds.merge(Rect2(Vector2(p)*g.TILE,g.TILE))
			g.draw_rect(bounds,Color("ffeab4"),false,3)
		else:g.draw_rect(Rect2(g.center(row.pos if g.tool=="clear" else (row.pos if row.get("stock_id",-1)<0 else g.world.Stock.command_pos(g.world,row)))-Vector2(15,15),Vector2(30,30)),Color("ffeab4"),false,3)
	pass # Result notification lives in the fixed HUD; no floating world notice.
