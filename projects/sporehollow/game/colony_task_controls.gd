extends RefCounted
static func task(g,kind: String,p: Vector2i,id: int=-1):
	var j=g.world.Tasks.job(g.world,kind,p,id)
	if not j.is_empty():g.world.Jobs.cancel(g.world,j.id)
	elif not g.world.Tasks.designate(g.world,kind,p,id):g.notice(g.world.Tasks.reason(g.world,kind,p,id))
	g.refresh()
static func forbid(g,p: Vector2i):
	g.world.Tasks.set_forbidden(g.world,"mine",p,-1,not g.world.rocks[p].get("forbidden",false));g.refresh()
static func gear(g,item: String):
	if not g.world.HumanCombat.equip(g.world,item):g.notice("装備は現物と作業可能な状態が必要です")
	g.refresh()
static func draft(g):
	g.world.Work.set_drafted(g.world,"keeper",not g.world.keeper.get("drafted",false));g.refresh()
static func build(g):
	if not g.world.working() or g.field_book or g.field_shop or g.story_modal!="" or g.equipment_open:return
	if g.selected.get("kind")=="rock" and g.world.rocks.has(g.selected.pos):
		var p=g.ColonyPanels.panel(g,Rect2(376,569,608,120));var cell=g.selected.pos
		g.ColonyPanels.label(p,"採掘：岩1個 → 現地に石8個・4秒（仮）",Vector2(12,8),16)
		var j=g.world.Tasks.job(g.world,"mine",cell);var why=g.world.Tasks.reason(g.world,"mine",cell,-1,j.get("id",-1))
		g.add_button(g.palette,"mine","採掘を取り消す" if not j.is_empty() else "採掘を予約",Rect2(388,604,224,34),task.bind(g,"mine",cell))
		g.buttons.mine.disabled=j.is_empty() and why!=""
		g.add_button(g.palette,"mine_forbid","禁止を解除" if g.world.rocks[cell].get("forbidden",false) else "採掘を禁止",Rect2(626,604,224,34),forbid.bind(g,cell))
		g.ColonyPanels.label(p,why if why!="" else "採集の優先順位で実行。石は完成後に運搬できます。",Vector2(12,80),14)
	elif g.selected.get("kind")=="keeper":
		var a=g.world.keeper;var profile=g.world.HumanCombat.profile(a)
		var p=g.ColonyPanels.panel(g,Rect2(448,569,536,120))
		g.ColonyPanels.label(p,"装備：%s  射程%d / 威力%d（仮）"%[profile.name,profile.range,profile.damage],Vector2(12,8),16)
		g.add_button(g.palette,"keeper_draft","徴兵を解除" if a.get("drafted",false) else "徴兵する",Rect2(460,604,156,34),draft.bind(g))
		g.add_button(g.palette,"keeper_equip","長柄を装備",Rect2(624,604,166,34),gear.bind(g,"wood_staff"))
		g.add_button(g.palette,"keeper_unequip","装備を外す",Rect2(798,604,174,34),gear.bind(g,"unequip"))
		var pending=g.world.jobs.any(func(j):return j.kind=="keeper_equipment")
		g.buttons.keeper_equip.disabled=pending or g.world.Stock.available(g.world,"wood_staff")<1 or a.get("drafted",false)
		g.buttons.keeper_unequip.disabled=pending or a.get("equipment",{}).is_empty() or a.get("drafted",false)
		g.ColonyPanels.label(p,"徴兵中：敵クリックで指定攻撃 / 地面で移動" if a.get("drafted",false) else ("装備作業を予約中" if pending else "長柄は商人から購入。現物まで移動して装備。"),Vector2(12,80),14)
static func draw(g):
	for p in g.world.rocks:
		var c=g.center(p);var points=PackedVector2Array([c+Vector2(-16,9),c+Vector2(-13,-6),c+Vector2(0,-14),c+Vector2(13,-6),c+Vector2(17,9)])
		g.draw_colored_polygon(points,Color("a6aa99"));g.draw_polyline(points,Color("667469"),2)
		if g.world.rocks[p].get("forbidden",false):g.draw_line(c-Vector2(11,11),c+Vector2(11,11),g.UI.DANGER,3)
		if g.selected.get("kind")=="rock" and g.selected.pos==p:g.draw_rect(Rect2(c-Vector2(22,20),Vector2(44,40)),g.UI.GOLD,false,2)
static func signature(g) -> String:
	return str([g.selected,g.world.keeper.get("equipment",{}),g.world.keeper.get("drafted",false),g.world.Stock.available(g.world,"wood_staff"),g.world.rocks,g.world.jobs.map(func(j):return [j.id,j.kind,j.state])])
