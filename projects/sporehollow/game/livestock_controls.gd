extends RefCounted

static func selected(g) -> Dictionary:
	if g.group!=1 or g.selected_animals.size()!=1:return {}
	return g.world.Orders.animal(g.world,g.selected_animals[0])

static func change_class(g,id: int):
	var a=g.world.Orders.animal(g.world,id)
	if not a.is_empty():g.world.Livestock.set_class(g.world,id,"pet" if g.world.Livestock.classification(a)=="livestock" else "livestock")
	g.refresh()

static func forbid(g,id: int):
	var a=g.world.Orders.animal(g.world,id)
	if not a.is_empty():g.world.Livestock.set_forbidden(g.world,id,not a.get("forbidden",false))
	g.refresh()

static func designate(g,id: int):
	var j=g.world.Livestock.job(g.world,id)
	if not j.is_empty():g.world.Jobs.cancel(g.world,j.id)
	elif not g.world.Livestock.designate(g.world,id):g.notice(g.world.Livestock.reason(g.world,g.world.Orders.animal(g.world,id)))
	g.refresh()

static func build(g):
	var a=selected(g)
	if a.is_empty() or not g.world.working() or g.field_book or g.field_shop or g.story_modal!="" or g.equipment_open:return
	var farm=g.world.Livestock;var kind=farm.classification(a)
	if kind=="person":return
	var p=g.ColonyPanels.panel(g,Rect2(376,569,608,120))
	g.ColonyPanels.label(p,"管理区分："+("家畜" if kind=="livestock" else "ペット")+"  · 忠誠・戦闘AIはそのまま",Vector2(12,8),16)
	var j=farm.job(g.world,a.id);var why=farm.reason(g.world,a,j.get("id",-1))
	var eligible=farm.MEAT.has(a.species)
	g.add_button(g.palette,"livestock_class","ペットとして保護" if kind=="livestock" else "家畜に戻す",Rect2(388,604,184,34),change_class.bind(g,a.id))
	g.buttons.livestock_class.disabled=not eligible or not farm.owned(g.world,a)
	g.buttons.livestock_class.tooltip_text="鶏・乳牛・闘牛のみ家畜に指定できます。ペットはと殺しません。"
	g.add_button(g.palette,"livestock_forbid","と殺禁止を解除" if a.get("forbidden",false) else "と殺を禁止",Rect2(582,604,174,34),forbid.bind(g,a.id))
	g.buttons.livestock_forbid.disabled=not eligible or not farm.owned(g.world,a)
	g.UI.selected(g.buttons.livestock_forbid,a.get("forbidden",false)==true)
	g.add_button(g.palette,"livestock_slaughter","予約を取り消す" if not j.is_empty() else "と殺を予約",Rect2(766,604,206,34),designate.bind(g,a.id))
	g.buttons.livestock_slaughter.disabled=j.is_empty() and why!=""
	g.buttons.livestock_slaughter.tooltip_text="選択した1体のみ、作業者が近づいて3秒で処理します。完成までは取り消せます。"
	var status=why if why!="" else ("予約中：「その他」の優先順位に従って処理" if not j.is_empty() else "明示した1体のみ現地で処理 → 肉%d個（仮）"%farm.MEAT.get(a.species,0))
	if not j.is_empty() and j.get("cancel_requested",false):status="取消待ち：再開時に取り消します。対象は処理しません。"
	g.ColonyPanels.label(p,status,Vector2(12,80),14)

static func signature(g) -> String:
	var a=selected(g)
	if a.is_empty():return ""
	return str([a.id,a.hp,a.get("forbidden",false),a.get("husbandry_class",""),a.get("abductor",-1),g.world.Livestock.job(g.world,a.id)])
