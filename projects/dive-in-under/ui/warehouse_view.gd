extends Control
const E=preload("res://core/expedition.gd")
const Storage=preload("res://core/storage.gd")
const Grid=preload("res://ui/item_grid.gd")
const Skin=preload("res://ui/ui_skin.gd")
var game: Control
func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);build()
func refresh_storage() -> void:game.show_campaign()
func build() -> void:
	var s: Dictionary=game.campaign;var state: Dictionary=game.warehouse_state
	Skin.picture(self,preload("res://assets/interface/v2/surface-warehouse.png"),Rect2(0,0,1280,720),true)
	Skin.label(self,"アイテム",Rect2(28,14,510,45),28)
	Skin.label(self,"Shift＋右クリック：所持品⇔倉庫 / Shift＋ドラッグ：半分（1枚は1枚）",Rect2(440,20,805,30),16)
	var left:=Skin.panel(self,Rect2(16,78,296,347),"所持品  %d / 15"%s.inventory.size())
	for i in 15:
		var uid: String=s.inventory[i] if i<s.inventory.size() else ""
		Grid.cell(left,game,self,Rect2(12+(i%4)*68,55+int(i/4)*68,64,64),"inventory",uid,"",uid!="" and uid==state.get("uid",""))
	var cloth:=Skin.panel(self,Rect2(16,438,296,171),"父の風呂敷  %d / 3"%s.cloth.size())
	Skin.label(cloth,"死亡しても残る実収納",Rect2(14,47,270,24),14,Skin.MUTED)
	for i in 3:
		var uid: String=s.cloth[i] if i<s.cloth.size() else ""
		Grid.cell(cloth,game,self,Rect2(28+i*82,80,72,72),"cloth",uid,"",uid!="" and uid==state.get("uid",""))
	var middle:=Skin.panel(self,Rect2(324,78,580,531),"倉庫  /  %d点・容量制限なし"%s.warehouse.size())
	preload("res://ui/storage_grid.gd").build(middle,game,self,Rect2(16,54,548,453),state,6,4)
	var right:=Skin.panel(self,Rect2(916,78,348,531),"アイテムの詳細",true)
	details(right)
	var source: String=state.get("sort_source","warehouse")
	var destination:=OptionButton.new();destination.position=Vector2(330,630);destination.size=Vector2(140,38);add_child(destination)
	for name in ["倉庫","所持品","風呂敷"]:destination.add_item(name)
	var sources: Array=["warehouse","inventory","cloth"];destination.select(maxi(0,sources.find(source)));destination.item_selected.connect(func(i):state.sort_source=sources[i])
	var order:=OptionButton.new();order.position=Vector2(480,630);order.size=Vector2(130,38);add_child(order)
	for name in ["種別順","名前順","耐久順"]:order.add_item(name)
	var modes: Array=["category","name","condition"];order.select(maxi(0,modes.find(state.get("sort","category"))));order.item_selected.connect(func(i):state.sort=modes[i])
	Skin.button(self,"整理",Rect2(620,630,150,40),func():game.call_deferred("perform","organize",{"source":state.get("sort_source","warehouse"),"mode":state.get("sort","category")},int(s.revision))).set_meta("nav","organize")
	Skin.button(self,"戻る",Rect2(1052,630,212,48),func():game.call_deferred("go_back")).set_meta("nav","back")
	Skin.label(self,game.notice if game.notice!="" else "ドラッグ：指定マスへ / フィルタ中もマス番号を保持 / 整理は選んだ収納だけ / コイン結合は詳細から",Rect2(24,684,1230,26),15,Skin.INK)
func details(p: Control) -> void:
	var source: String=game.warehouse_state.get("source","inventory");var uid: String=game.warehouse_state.get("uid","")
	if uid not in game.campaign.get(source,[]):Skin.label(p,"品物を選んでください",Rect2(20,100,308,60),22,Skin.DARK,true);return
	var item: Dictionary=game.cfg.items[game.campaign.items[uid]]
	Skin.picture(p,preload("res://ui/equipment_art.gd").texture(game.campaign.items[uid],item.slot),Rect2(20,53,78,80))
	Skin.label(p,item.name,Rect2(110,57,218,70),22,Skin.DARK,true)
	Skin.label(p,{"inventory":"所持品","warehouse":"倉庫","cloth":"父の風呂敷"}[source]+" / "+game.cfg.slots.get(item.slot,"道具"),Rect2(22,139,304,26),16,Skin.DARK)
	var sc:=ScrollContainer.new();sc.position=Vector2(20,178);sc.size=Vector2(308,191);sc.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;p.add_child(sc)
	var box:=VBoxContainer.new();box.size_flags_horizontal=Control.SIZE_EXPAND_FILL;box.add_theme_constant_override("separation",12);sc.add_child(box)
	var lines: Array=[]
	if game.campaign.items[uid]=="C01":lines.append("この束 %d枚 / 上限999枚"%game.campaign.quantities[uid])
	if item.slot!="":lines.append(preload("res://ui/item_presenter.gd").performance(game.campaign,game.cfg,uid));lines.append(game.condition_text(uid));lines.append(preload("res://ui/item_presenter.gd").profile(game.campaign,game.cfg,uid))
	lines.append(item.get("description",preload("res://ui/warehouse_catalog.gd").DESCRIPTIONS.get(game.campaign.items[uid],"")))
	for line in lines:
		if str(line)=="":continue
		var l:=Label.new();l.text=str(line);l.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;l.add_theme_font_size_override("font_size",17);l.add_theme_color_override("font_color",Skin.DARK);box.add_child(l)
	var destination: String="inventory" if source in ["warehouse","cloth"] else "warehouse"
	var error: String=Storage.reason(game.campaign,uid,source,destination,game.cfg)
	var move:=Skin.button(p,"取り出す → 所持品" if destination=="inventory" else "預ける → 倉庫",Rect2(20,385,308,36),func():game.transfer_item(uid,source,destination,int(game.campaign.revision)));move.disabled=error!="";move.tooltip_text=error
	if source!="cloth":
		var cloth_error: String=Storage.reason(game.campaign,uid,source,"cloth",game.cfg)
		var cloth:=Skin.button(p,"風呂敷へ移す" if cloth_error=="" else "風呂敷に空きがありません",Rect2(20,428,308,36),func():game.transfer_item(uid,source,"cloth",int(game.campaign.revision)));cloth.disabled=cloth_error!="";cloth.tooltip_text=cloth_error
	if game.campaign.items[uid]=="C01":Skin.button(p,"コインの数量指定・分割・結合",Rect2(20,471,308,36),func():game.open_services("coin",uid,source))
func select_item(source: String, uid: String, _slot: String="") -> void:
	if uid=="":return
	game.warehouse_state.source=source;game.warehouse_state.uid=uid;game.flow_selection={"kind":source,"uid":uid};game.show_campaign()
func activate_item(_source: String, _uid: String, _slot: String="") -> void:pass
func quick_item(source: String, uid: String, _slot: String="") -> void:quick_transfer(source,uid)
func quick_transfer(source: String, uid: String) -> void:
	if uid!="":game.transfer_item(uid,source,"inventory" if source in ["warehouse","cloth"] else "warehouse",int(game.campaign.revision))
func accepts_cell(value: Variant, destination: String, _slot: String, cell: int) -> bool:
	if not value is Dictionary or value.get("kind")!="equipment-item" or int(value.get("revision",-1))!=int(game.campaign.revision):return false
	var copy: Dictionary=game.campaign.duplicate(true);var args: Dictionary={"uid":value.uid,"source":value.source,"destination":destination,"cell":cell}
	if value.has("quantity"):args.quantity=value.quantity
	return Storage.transfer(copy,args,game.cfg)==""
func drop_cell(value: Dictionary, destination: String, _slot: String, cell: int) -> void:
	var args: Dictionary={"uid":value.uid,"source":value.source,"destination":destination,"cell":cell}
	if value.has("quantity"):args.quantity=value.quantity
	game.perform("transfer",args,int(value.revision))
func visual_audit() -> Dictionary:return {"kind":"items","selected":game.warehouse_state.get("uid",""),"warehouse_cells":game.campaign.warehouse_positions.duplicate(),"filter":game.warehouse_state.get("filter","all")}
