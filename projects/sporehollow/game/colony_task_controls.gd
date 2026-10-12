extends RefCounted
static func task(g,kind: String,p: Vector2i,id: int=-1):
	var j=g.world.Tasks.job(g.world,kind,p,id)
	if not j.is_empty():g.world.Jobs.cancel(g.world,j.id)
	elif not g.world.Tasks.designate(g.world,kind,p,id):g.notice(g.world.Tasks.reason(g.world,kind,p,id))
	g.refresh()
static func forbid(g,p: Vector2i):
	var r=g.world.Mountains.resource(g.world,p)
	g.world.Tasks.set_forbidden(g.world,"mine",p,-1,not (g.world.rocks.get(p,{}) if r.is_empty() else r).get("forbidden",false));g.refresh()
static func gear(g,item: String):
	if not g.world.HumanCombat.equip(g.world,item):g.notice("装備は現物と作業可能な状態が必要です")
	g.refresh()
static func draft(g):
	if not g.world.Work.set_drafted(g.world,"keeper",not g.world.keeper.get("drafted",false)):g.notice("今は徴兵できません")
	g.refresh()
static func build(g):
	if not g.world.working() or g.field_book or g.field_shop or g.story_modal!="" or g.equipment_open:return
	if g.selected.get("kind")=="mountain":
		var r=g.world.mountains.get(g.selected.id,{})
		if r.is_empty():return
		var panel=g.ColonyPanels.panel(g,Rect2(376,569,608,120));var j=g.world.Tasks.job(g.world,"mine",r.pos)
		g.ColonyPanels.label(panel,("大岩山" if r.kind=="large" else "小岩山")+"  残り石材 %d / %d  %s"%[r.remaining,g.world.Mountains.CONFIG[r.kind].amount,"採掘済み" if r.remaining<=0 else "段階 %d"%(r.stage+1)],Vector2(12,8),16)
		g.add_button(g.palette,"mine","採掘を取り消す" if not j.is_empty() else "採掘を予約",Rect2(388,604,224,34),task.bind(g,"mine",r.pos))
		g.buttons.mine.disabled=j.is_empty() and (r.remaining<=0 or r.forbidden)
		g.add_button(g.palette,"mine_forbid","禁止を解除" if r.forbidden else "採掘を禁止",Rect2(626,604,224,34),forbid.bind(g,r.pos))
		g.ColonyPanels.label(panel,j.get("block_reason","") if j.get("state")=="blocked" else "採集担当が継続して採掘。石材は現地に残り、回収で備蓄へ運びます。",Vector2(12,80),14)
	elif g.selected.get("kind")=="rock" and g.world.rocks.has(g.selected.pos):
		var p=g.ColonyPanels.panel(g,Rect2(376,569,608,120));var cell=g.selected.pos
		g.ColonyPanels.label(p,"採掘：岩1個 → 石8個 / 4秒",Vector2(12,8),16)
		var j=g.world.Tasks.job(g.world,"mine",cell);var why=g.world.Tasks.reason(g.world,"mine",cell,-1,j.get("id",-1))
		g.add_button(g.palette,"mine","採掘を取り消す" if not j.is_empty() else "採掘を予約",Rect2(388,604,224,34),task.bind(g,"mine",cell))
		g.buttons.mine.disabled=j.is_empty() and why!=""
		g.add_button(g.palette,"mine_forbid","禁止を解除" if g.world.rocks[cell].get("forbidden",false) else "採掘を禁止",Rect2(626,604,224,34),forbid.bind(g,cell))
		g.ColonyPanels.label(p,why if why!="" else "採集の優先順位で実行。石は完成後に運搬できます。",Vector2(12,80),14)
	elif g.selected.get("kind")=="keeper":
		var a=g.world.keeper;var profile=g.world.HumanCombat.profile(a)
		var p=g.ColonyPanels.panel(g,Rect2(448,569,536,120))
		g.ColonyPanels.label(p,"装備：%s  射程%d / 威力%d"%[profile.name,profile.range,profile.damage],Vector2(12,8),16)
		g.add_button(g.palette,"keeper_draft","徴兵を解除" if a.get("drafted",false) else "徴兵する",Rect2(460,604,156,34),draft.bind(g))
		g.buttons.keeper_draft.disabled=not a.get("drafted",false) and (a.state!="free" or a.hp<=0 or a.forced_rest or a.get("nutrition_down",false))
		g.add_button(g.palette,"keeper_equip","長柄を装備",Rect2(624,604,166,34),gear.bind(g,"wood_staff"))
		g.add_button(g.palette,"keeper_unequip","装備を外す",Rect2(798,604,174,34),gear.bind(g,"unequip"))
		var pending=g.world.jobs.any(func(j):return j.kind=="keeper_equipment")
		g.buttons.keeper_equip.disabled=pending or g.world.Stock.available(g.world,"wood_staff")<1 or a.get("drafted",false)
		g.buttons.keeper_unequip.disabled=pending or a.get("equipment",{}).is_empty() or a.get("drafted",false)
		g.ColonyPanels.label(p,"徴兵中：敵クリックで指定攻撃 / 地面で移動" if a.get("drafted",false) else ("装備作業を予約中" if pending else "長柄は商人から購入。現物まで移動して装備。"),Vector2(12,80),14)
static func draw(g):
	for r in g.world.mountains.values():
		for p in g.world.Mountains.footprint(r):
			if g.selected.get("id")==r.id:g.draw_rect(Rect2(g.center(p)-Vector2(24,21),Vector2(48,42)),g.UI.GOLD,false,1)
		if r.forbidden:g.label_on(g,g.center(r.pos),"×",18,g.UI.DANGER)
	for p in g.world.rocks:
		var c=g.center(p)
		if g.world.rocks[p].get("forbidden",false):g.draw_line(c-Vector2(11,11),c+Vector2(11,11),g.UI.DANGER,3)
		if g.selected.get("kind")=="rock" and g.selected.pos==p:g.draw_rect(Rect2(c-Vector2(22,20),Vector2(44,40)),g.UI.GOLD,false,2)
static func signature(g) -> String:
	return str([g.selected,g.world.keeper.get("equipment",{}),g.world.keeper.get("drafted",false),g.world.Stock.available(g.world,"wood_staff"),g.world.rocks,g.world.mountains.values().map(func(r):return [r.id,r.stage,r.remaining,r.forbidden]),g.world.jobs.map(func(j):return [j.id,j.kind,j.state])])
