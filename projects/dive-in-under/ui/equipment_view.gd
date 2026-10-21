extends Control
const E=preload("res://core/expedition.gd")
const Party=preload("res://core/party_ui.gd")
const Gear=preload("res://core/gear_transfer.gd")
const Actions=preload("res://ui/gear_actions.gd")
const Grid=preload("res://ui/item_grid.gd")
const UISkin=preload("res://ui/ui_skin.gd")
const Art=preload("res://ui/visual_assets.gd")
var game: Control
func get_actor() -> String:return game.selected_actor
func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);build()
func refresh_storage() -> void:game.show_campaign()
func build() -> void:
	var s: Dictionary=game.campaign;var id: String=get_actor();var equipment: Dictionary=Party.gear(s,id)
	UISkin.readable_strip(self,Rect2(16,8,1248,56))
	UISkin.label(self,"装備  /  編集中："+Party.name_of(s,id),Rect2(28,18,540,40),27)
	preload("res://ui/party_picker.gd").build(self,game,Rect2(610,12,650,50))
	if s.phase!="town":game.gear_source="inventory"
	var left:=UISkin.panel(self,Rect2(16,78,300,548),"収納 / 旧装備の戻り先")
	for i in (2 if s.phase=="town" else 1):
		var source: String=["inventory","warehouse"][i]
		var b:=UISkin.button(left,["所持品","倉庫"][i],Rect2(12+i*140,51,136,34),func():game.gear_source=source;game.equipment_candidate="";game.call_deferred("show_campaign"));UISkin.quiet_button(b,source==game.gear_source);b.set_meta("gear_source",source)
	if game.gear_source=="inventory":Grid.bag(left,game,self,Vector2(24,102),3,80)
	else:preload("res://ui/storage_grid.gd").build(left,game,self,Rect2(12,99,276,431),game.gear_storage,3,4)
	var center:=UISkin.panel(self,Rect2(328,78,554,548),Party.name_of(s,id)+" / 11部位")
	UISkin.picture(center,Art.texture("cavern"),Rect2(94,53,366,449),true).modulate=Color(.57,.67,.68)
	UISkin.picture(center,Art.actor_texture("hero"),Rect2(112,142,330,350))
	for c in 2:
		var slots: Array=[["head","body","right_hand","legs","feet"],["neck","ears","eyes","left_hand","wrist","finger"]][c]
		for i in slots.size():
			var slot: String=slots[i];Grid.cell(center,game,self,Rect2(472 if c==1 else 14,65+i*68,68,64),"equipment",equipment[slot],slot,game.equipment_focus==slot)
	var backing:=ColorRect.new();backing.color=Color(.015,.04,.055,.94);backing.position=Vector2(94,58);backing.size=Vector2(366,74);backing.mouse_filter=MOUSE_FILTER_IGNORE;center.add_child(backing)
	UISkin.label(center,"Shift＋左クリック / ダブルクリックで交換\n旧装備・解除先："+("倉庫" if game.gear_source=="warehouse" else "所持品"),Rect2(106,66,344,58),15,UISkin.INK,true)
	var right:=UISkin.panel(self,Rect2(894,78,370,548),"装備の詳細",true)
	var selected: String=game.equipment_candidate if game.equipment_candidate in s[game.gear_source] else str(equipment[game.equipment_focus])
	if selected!="":
		var item: Dictionary=game.cfg.items[s.items[selected]];var candidate: bool=selected in s[game.gear_source]
		UISkin.picture(right,preload("res://ui/equipment_art.gd").texture(s.items[selected],item.slot),Rect2(22,55,80,80))
		UISkin.label(right,item.name,Rect2(115,57,230,74),22,UISkin.DARK,true)
		UISkin.label(right,game.cfg.slots.get(item.slot,"道具")+" / "+preload("res://ui/item_presenter.gd").performance(s,game.cfg,selected)+"\n"+game.condition_text(selected),Rect2(24,143,322,80),17,UISkin.DARK,true)
		if candidate and item.slot!="":
			var preview: Dictionary=s.duplicate(true);Gear.apply(preview,{"actor":id,"uid":selected,"source":game.gear_source},game.cfg)
			var rows: Array=preload("res://ui/item_presenter.gd").comparison(Party.actor(s,game.cfg,id),Party.actor(preview,game.cfg,id))
			for i in rows.size():
				var row: Dictionary=rows[i];UISkin.label(right,"%s  %d → %d (%+d)"%[row.name,row.before,row.after,row.delta],Rect2(24,235+i*21,322,22),16,UISkin.DARK)
		var args: Dictionary={"actor":id,"uid":selected,"slot":game.equipment_focus,"source":game.gear_source,"destination":game.gear_source}
		if candidate:args.slot=item.slot
		var reason: String=Gear.reason(s,args,game.cfg,not candidate)
		var b:=UISkin.button(right,"装備する / 交換" if candidate else "外す → "+("倉庫" if game.gear_source=="warehouse" else "所持品"),Rect2(22,395,326,46),func():game.call_deferred("perform","equip" if candidate else "unequip",args,int(s.revision)));b.disabled=reason!="";b.tooltip_text=reason
		UISkin.label(right,reason if reason!="" else "交換前の装備も選択中の収納へ戻ります。",Rect2(24,354,322,38),14,UISkin.DARK,true)
		var repair_reason: String=preload("res://ui/item_presenter.gd").repair_reason(s,game.cfg,selected)
		var repair:=UISkin.button(right,repair_reason if repair_reason!="" else "修理 %dG"%E.Condition.cost(s,selected,game.cfg),Rect2(22,452,326,44),func():game.call_deferred("perform","repair",{"uid":selected},int(s.revision)));repair.disabled=repair_reason!=""
	else:UISkin.label(right,game.cfg.slots[game.equipment_focus]+" / 未装備",Rect2(24,150,322,60),22,UISkin.DARK,true)
	UISkin.button(self,"戻る",Rect2(16,643,300,60),func():game.call_deferred("go_back")).set_meta("nav","back")
	var h: Dictionary=Party.actor(s,game.cfg,id)
	UISkin.readable_strip(self,Rect2(328,643,936,60))
	UISkin.label(self,game.notice if game.notice!="" else "攻撃 %d / 防御 %d / 素早さ %d   |   光る枠へドラッグ / 右クリック：戻る"%[h.atk,h.def,h.spd],Rect2(338,646,918,50),17,UISkin.INK,true)
func select_item(source: String, uid: String, slot: String="") -> void:
	game.flow_selection={"kind":source,"uid":uid,"slot":slot};game.equipment_candidate=uid if source in ["inventory","warehouse"] else ""
	if slot!="":game.equipment_focus=slot
	elif uid!="" and game.cfg.items[game.campaign.items[uid]].slot!="":game.equipment_focus=game.cfg.items[game.campaign.items[uid]].slot
	game.show_campaign()
func activate_item(source: String, uid: String, slot: String="") -> void:quick_item(source,uid,slot)
func quick_item(source: String, uid: String, slot: String="") -> void:
	if uid=="":return
	if source=="equipment":game.perform("unequip",{"actor":get_actor(),"slot":slot,"source":"inventory","destination":game.gear_source},int(game.campaign.revision))
	else:game.perform("equip",{"actor":get_actor(),"uid":uid,"source":source,"destination":source},int(game.campaign.revision))
func quick_transfer(source: String, uid: String) -> void:
	game.transfer_item(uid,source,"warehouse" if source=="inventory" else "inventory",int(game.campaign.revision))
func accepts_cell(value: Variant, destination: String, slot: String, cell: int) -> bool:
	return cell_reason(value,destination,slot,cell)==""
func cell_reason(value: Variant, destination: String, slot: String, cell: int) -> String:
	if not value is Dictionary or value.get("kind")!="equipment-item" or int(value.get("revision",-1))!=int(game.campaign.revision):return "表示が更新されました。"
	if destination=="equipment":return Actions.reason(game,value,destination,slot)
	if value.source=="equipment":return Gear.reason(game.campaign,{"actor":value.actor,"slot":value.slot,"source":"inventory","destination":destination,"cell":cell},game.cfg,true)
	if value.source=="warehouse" and destination=="warehouse":return "" if cell>=0 else "マスを選んでください。"
	var copy: Dictionary=game.campaign.duplicate(true);var args: Dictionary={"uid":value.uid,"source":value.source,"destination":destination,"cell":cell}
	if value.has("quantity"):args.quantity=value.quantity
	return E.Storage.transfer(copy,args,game.cfg)
func drop_cell(value: Dictionary, destination: String, slot: String, cell: int) -> void:
	var error: String=cell_reason(value,destination,slot,cell)
	if error!="":game.notice=error;game.show_campaign();return
	if destination=="equipment":Actions.apply(game,value,destination,slot)
	elif value.source=="equipment":game.perform("unequip",{"actor":value.actor,"slot":value.slot,"source":"inventory","destination":destination,"cell":cell},int(value.revision))
	else:
		var args: Dictionary={"uid":value.uid,"source":value.source,"destination":destination,"cell":cell}
		if value.has("quantity"):args.quantity=value.quantity
		game.perform("transfer",args,int(value.revision))
func visual_audit() -> Dictionary:return {"kind":"equipment","actor":get_actor(),"source":game.gear_source,"slots":11}
