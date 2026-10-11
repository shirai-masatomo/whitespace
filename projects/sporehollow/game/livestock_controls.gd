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
	if a.species in g.world.Tasks.TRAIN_SPECIES:
		var dogpanel=g.ColonyPanels.panel(g,Rect2(376,569,608,120));var tj=g.world.Tasks.job(g.world,"train",Vector2i.ZERO,a.id)
		var reason=g.world.Tasks.training_reason(g.world,a,tj.get("id",-1))
		g.ColonyPanels.label(dogpanel,"調教：忠誠 +%d / %s秒 / 1日1回"%[g.world.Tasks.TRAIN_GAIN,str(g.world.Tasks.TRAIN_SECONDS)],Vector2(12,8),16)
		g.add_button(g.palette,"train","調教を取り消す" if not tj.is_empty() else "調教を予約",Rect2(388,604,224,34),g.TaskControls.task.bind(g,"train",Vector2i.ZERO,a.id))
		g.buttons.train.disabled=tj.is_empty() and reason!=""
		g.add_button(g.palette,"train_forbid","作業禁止を解除" if a.get("forbidden",false) else "動物作業を禁止",Rect2(626,604,224,34),forbid.bind(g,a.id))
		g.ColonyPanels.label(dogpanel,reason if reason!="" else g.Presentation.category_hint(g.world,"train"),Vector2(12,80),14)
		return
	var p=g.ColonyPanels.panel(g,Rect2(376,569,608,120))
	g.ColonyPanels.label(p,"家畜として飼育" if kind=="livestock" else "ペットとして保護",Vector2(12,8),16)
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
	var status=why if why!="" else (g.Presentation.category_hint(g.world,"slaughter") if not j.is_empty() else "明示した1体のみ現地で処理 → 肉%d個"%farm.MEAT.get(a.species,0))
	if not j.is_empty() and j.get("cancel_requested",false):status="取消待ち：再開時に取り消します。対象は処理しません。"
	g.ColonyPanels.label(p,status,Vector2(12,80),14)

static func signature(g) -> String:
	var a=selected(g)
	if a.is_empty():return ""
	return str([a.id,a.hp,a.get("forbidden",false),a.get("husbandry_class",""),a.get("abductor",-1),a.loyalty,a.get("last_training_day",-1),g.world.Tasks.job(g.world,"train",Vector2i.ZERO,a.id),g.world.Livestock.job(g.world,a.id)])
