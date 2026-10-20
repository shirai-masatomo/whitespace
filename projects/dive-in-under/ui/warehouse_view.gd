extends Control
const E=preload("res://core/expedition.gd")
const InterfaceArt=preload("res://ui/interface_art.gd")
const UISkin=preload("res://ui/ui_skin.gd")
const Symbols=preload("res://ui/status_symbols.gd")
const Frame=preload("res://ui/warehouse_frame.gd")
const EquipmentArt=preload("res://ui/equipment_art.gd")
const Icons=preload("res://ui/item_icons.gd")
const Catalog=preload("res://ui/warehouse_catalog.gd")
const Storage=preload("res://core/storage.gd")
const GOLD=Color("e5c37e")
const INK=Color("e8e3ce")
const MUTED=Color("9caeac")
var game: Control
var selected_source: String
var selected_uid: String
var rows: Dictionary={}
var grid_scroll: ScrollContainer
var bag_scroll: ScrollContainer
var cloth_scroll: ScrollContainer
var visible_items: Array=[]
var drag_payload: Dictionary={}
var detail_move: Button
var guide_label: Label
func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	build()
func label_at(parent: Control, value: String, r: Rect2, font_size: int=18, color: Color=INK) -> Label:
	var l:=Label.new(); l.language="ja"; l.clip_text=true; l.text=value; l.position=r.position; l.size=r.size
	if parent.get_meta("paper_header",false) and r.position.y<40: color=Color("30291e")
	if parent.get_meta("paper_body",false) and r.position.y>=40: color=Color("655035") if color==MUTED else Color("30291e")
	l.set_meta("normal_color",color)
	if parent is Button and parent.get_meta("gold_surface",false): color=Color("302b23")
	l.add_theme_font_size_override("font_size",font_size); l.add_theme_color_override("font_color",color)
	l.clip_text=true; l.mouse_filter=Control.MOUSE_FILTER_IGNORE
	parent.add_child(l); l.size=r.size; return l
func icon_at(parent: Control, kind: String, r: Rect2, template_id: String="") -> void:
	var t:=TextureRect.new(); t.expand_mode=TextureRect.EXPAND_IGNORE_SIZE; t.texture=EquipmentArt.texture(template_id,kind) if template_id!="" else (preload("res://ui/interface_symbols.gd").texture("bag" if kind=="backpack" else kind) if kind in ["backpack","cloth","warehouse"] else Icons.texture(kind)); t.position=r.position; t.size=r.size
	t.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST; t.expand_mode=TextureRect.EXPAND_IGNORE_SIZE; t.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	t.mouse_filter=Control.MOUSE_FILTER_IGNORE; parent.add_child(t)
func panel(r: Rect2, title: String, kind: String, purple: bool=false, main: bool=false) -> Control:
	var p:=Control.new(); p.set_script(Frame); p.position=r.position; p.size=r.size; p.cloth=purple; p.prominent=main; add_child(p)
	p.set_meta("paper_header",true)
	if kind=="eyes":
		InterfaceArt.paper(p,Rect2(10,44,r.size.x-20,r.size.y-54)); p.set_meta("paper_body",true)
	InterfaceArt.paper(p,Rect2(11,9,r.size.x-22,46 if r.size.y==64 else 35))
	icon_at(p,kind,Rect2(13,8,32,32)); label_at(p,title,Rect2(50,8,r.size.x-65,32),22,Color("30291e"))
	return p
func skin(b: Button, selected: bool=false, purple: bool=false) -> void:
	var textured:=b.size.y>=45 or b.custom_minimum_size.y>=45
	b.set_meta("gold_surface",selected and textured)
	for child in b.get_children():
		if child is Label: child.add_theme_color_override("font_color",Color("302b23") if selected and textured else child.get_meta("normal_color",INK))
	b.add_theme_font_size_override("font_size",19)
	for state in ["normal","hover","pressed","disabled","focus"]:
		var st:=StyleBoxFlat.new()
		st.bg_color=Color("211a31") if purple else Color("0a1b21")
		st.border_color=Color("665a43")
		st.set_border_width_all(1); st.set_content_margin_all(3)
		if state=="hover": st.bg_color=Color("20343a"); st.border_color=GOLD
		if selected: st.bg_color=Color("303029"); st.border_color=Color("f0c975"); st.set_border_width_all(2)
		if state=="pressed": st.bg_color=Color("5a472a")
		if state=="disabled": st.bg_color=Color("0a1519"); st.border_color=Color("344045")
		if state=="focus": st.bg_color=Color(0,0,0,0); st.border_color=Color("69c1cb"); st.set_border_width_all(2)
		b.add_theme_stylebox_override(state,st if state=="focus" or not textured else InterfaceArt.button_style(state,selected))
		b.add_theme_color_override("font_"+("color" if state=="normal" else state+"_color"),INK if state!="disabled" else Color("697c7c"))
	b.add_theme_color_override("font_hover_color",Color("302b23") if selected and textured else INK)
	if selected and textured: b.add_theme_color_override("font_color",Color("302b23"))
func tile_skin(b: Button, selected: bool) -> void:
	# Tall inventory tiles need a quiet content area, not stretched button end caps.
	b.set_meta("gold_surface",false)
	for state in ["normal","hover","pressed","disabled"]:
		var st:=StyleBoxFlat.new(); st.bg_color=Color("25352f") if selected else Color("0b1c23")
		st.border_color=GOLD if selected or state=="hover" else Color("405156")
		st.set_border_width_all(2 if selected else 1); st.set_content_margin_all(8)
		if state=="hover": st.bg_color=Color("20343a")
		if state=="pressed": st.bg_color=Color("3a3b2f")
		b.add_theme_stylebox_override(state,st)
func rebuild() -> void:
	game.show_campaign()
func select_item(source: String, uid: String) -> void:
	remember_scroll()
	game.warehouse_state.source=source; game.warehouse_state.uid=uid; rebuild()
func remember_scroll() -> void:
	if is_instance_valid(bag_scroll): game.warehouse_state.bag_scroll=bag_scroll.scroll_vertical
	if is_instance_valid(grid_scroll): game.warehouse_state.grid_scroll=grid_scroll.scroll_vertical
	if is_instance_valid(cloth_scroll): game.warehouse_state.cloth_scroll=cloth_scroll.scroll_vertical
func scroll_area(p: Control, r: Rect2) -> ScrollContainer:
	var sc:=ScrollContainer.new(); sc.set_script(preload("res://ui/warehouse_drop.gd")); sc.view=self; sc.position=r.position; sc.size=r.size
	sc.theme=UISkin.scroll_theme(); sc.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED; p.add_child(sc)
	return sc
func build_list(p: Control, source: String, r: Rect2) -> ScrollContainer:
	var sc:=scroll_area(p,r); sc.destination=source
	var box:=VBoxContainer.new(); box.size_flags_horizontal=Control.SIZE_EXPAND_FILL; box.add_theme_constant_override("separation",4); sc.add_child(box)
	for uid in game.campaign[source]:
		var item: Dictionary=game.cfg.items[game.campaign.items[uid]]
		var b:=Button.new(); b.set_script(preload("res://ui/warehouse_item.gd")); b.view=self; b.source=source; b.uid=uid; b.custom_minimum_size=Vector2(r.size.x-12,34 if source=="cloth" else 42); b.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		UISkin.quiet_button(b,uid==selected_uid); box.add_child(b)
		icon_at(b,item.slot,Rect2(5,0,32,32) if source=="cloth" else Rect2(5,2,36,36),game.campaign.items[uid])
		var name_label:=label_at(b,Catalog.name_of(item),Rect2(46,0,r.size.x-118,32 if source=="cloth" else 36),17)
		name_label.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
		if game.campaign.items[uid]=="C01": label_at(b,"×%d"%game.campaign.quantities[uid],Rect2(r.size.x-65,0,55,32),16)
		if item.slot!="": label_at(b,"耐%d"%int(game.campaign.item_condition[uid].current),Rect2(r.size.x-65,0,55,32 if source=="cloth" else 34),13,MUTED)
		b.tooltip_text=Catalog.name_of(item)+" / "+game.condition_text(uid)
		b.pressed.connect(func(): if not Input.is_key_pressed(KEY_SHIFT): select_item(source,uid))
		rows[uid]=b
	if game.campaign[source].is_empty(): label_at(p,"中身はありません",Rect2(22,r.position.y+12,r.size.x-20,28),17,MUTED)
	return sc
func build() -> void:
	UISkin.picture(self,preload("res://assets/interface/v2/surface-warehouse.png"),Rect2(0,0,1280,720),true)
	selected_source=game.warehouse_state.get("source","inventory")
	selected_uid=game.warehouse_state.get("uid","")
	if not selected_uid in game.campaign.get(selected_source,[]):
		selected_uid=""; selected_source="inventory"
		for source in ["inventory","warehouse","cloth"]:
			if not game.campaign[source].is_empty():
				selected_source=source; selected_uid=game.campaign[source][0]; break
	game.warehouse_state.source=selected_source; game.warehouse_state.uid=selected_uid
	var header:=panel(Rect2(16,14,1248,64),"","lantern")
	label_at(header,"倉庫 ・ 所持品",Rect2(28,11,370,40),27)
	label_at(header,"持ち帰ったものを、次の旅へ。",Rect2(690,14,340,34),16,MUTED)
	label_at(header,"G  %d"%E.money(game.campaign),Rect2(1080,11,150,40),23,GOLD)
	var left:=panel(Rect2(16,92,296,300),"所持品","backpack")
	label_at(left,"%d / 15"%game.campaign.inventory.size(),Rect2(198,9,78,30),18)
	bag_scroll=build_list(left,"inventory",Rect2(14,55,268,228))
	var cloth:=panel(Rect2(16,404,296,198),"父親の風呂敷","cloth",true)
	label_at(cloth,"%d / 3"%game.campaign.cloth.size(),Rect2(226,11,55,30),17)
	label_at(cloth,"死亡しても失われない",Rect2(18,46,260,23),14,Color("d7bfed"))
	cloth_scroll=build_list(cloth,"cloth",Rect2(14,73,268,114))
	var center:=panel(Rect2(324,92,580,510),"倉庫","warehouse",false,true)
	label_at(center,"保管  %d 点"%game.campaign.warehouse.size(),Rect2(205,9,140,30),18)
	var order_names: Array=["種別","名前","耐久"]
	var order_keys: Array=["category","name","condition"]
	var order_index:=maxi(0,order_keys.find(game.warehouse_state.get("sort","category")))
	var order:=Button.new(); order.text="整理順："+order_names[order_index]+" ▾"; order.position=Vector2(365,11); order.size=Vector2(195,28); skin(order); order.add_theme_font_size_override("font_size",15); center.add_child(order)
	order.pressed.connect(func(): remember_scroll(); game.warehouse_state.sort=order_keys[(order_index+1)%3]; rebuild())
	var tab_index:=0
	for category in Catalog.CATEGORIES:
		var tab:=Button.new(); tab.text=Catalog.CATEGORIES[category]; tab.position=Vector2(14+tab_index*92,54); tab.size=Vector2(88,32); UISkin.quiet_button(tab,game.warehouse_state.get("category","all")==category); tab.add_theme_font_size_override("font_size",15); center.add_child(tab)
		tab.pressed.connect(func(): remember_scroll(); game.warehouse_state.category=category; game.warehouse_state.grid_scroll=0; rebuild())
		tab_index+=1
	grid_scroll=scroll_area(center,Rect2(14,98,552,379)); grid_scroll.destination="warehouse"
	var grid:=GridContainer.new(); grid.columns=6; grid.add_theme_constant_override("h_separation",5); grid.add_theme_constant_override("v_separation",6); grid_scroll.add_child(grid)
	var category: String=game.warehouse_state.get("category","all")
	for uid in game.campaign.warehouse:
		var item: Dictionary=game.cfg.items[game.campaign.items[uid]]
		if category!="all" and Storage.category(item)!=category: continue
		visible_items.append(uid)
		var tile:=Button.new(); tile.set_script(preload("res://ui/warehouse_item.gd")); tile.view=self; tile.source="warehouse"; tile.uid=uid; tile.custom_minimum_size=Vector2(84,112); skin(tile,uid==selected_uid); tile_skin(tile,uid==selected_uid); grid.add_child(tile)
		icon_at(tile,item.slot,Rect2(14,10,56,52),game.campaign.items[uid])
		if game.campaign.items[uid]=="C01": label_at(tile,"×%d"%game.campaign.quantities[uid],Rect2(22,58,52,18),15)
		if item.slot!="": label_at(tile,"耐%d"%int(game.campaign.item_condition[uid].current),Rect2(22,58,52,18),12)
		var title:=label_at(tile,Catalog.name_of(item),Rect2(10,76,64,22),12,INK); UISkin.fit_name(title,Catalog.name_of(item),64); title.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
		if item.slot!="":
			var bar:=ColorRect.new(); bar.position=Vector2(10,101); bar.size=Vector2(64.0*game.campaign.item_condition[uid].current/100,2); bar.color=Color("72b8a1") if game.campaign.item_condition[uid].current>0 else Color("a95646"); bar.mouse_filter=Control.MOUSE_FILTER_IGNORE; tile.add_child(bar)
		tile.tooltip_text=Catalog.name_of(item)+"\n"+game.condition_text(uid)
		tile.pressed.connect(func(): if not Input.is_key_pressed(KEY_SHIFT): select_item("warehouse",uid)); rows[uid]=tile
	if visible_items.is_empty(): label_at(center,"この分類にアイテムはありません",Rect2(40,230,500,32),19,MUTED)
	label_at(center,"容量制限なし / コイン99枚で1枠 / 装備は1個体1枠",Rect2(28,474,524,22),14,MUTED)
	var right:=panel(Rect2(916,92,348,510),"アイテム詳細","eyes")
	build_details(right)
	build_actions()
	var guide:=ColorRect.new(); guide.position=Vector2(16,610); guide.size=Vector2(1248,30); guide.color=Color("10242d"); guide.mouse_filter=Control.MOUSE_FILTER_IGNORE; add_child(guide)
	guide_label=label_at(self,game.notice if game.notice!="" else "左クリック：詳細 / Shift＋クリック：倉庫⇔所持品 / ドラッグ：光る収納へ / コインは数量指定可",Rect2(28,613,1224,24),15,INK)
	bag_scroll.set_deferred("scroll_vertical",game.warehouse_state.get("bag_scroll",0))
	grid_scroll.set_deferred("scroll_vertical",game.warehouse_state.get("grid_scroll",0))
	cloth_scroll.set_deferred("scroll_vertical",game.warehouse_state.get("cloth_scroll",0))
	if rows.has(selected_uid): reveal_selected.call_deferred()
func reveal_selected() -> void:
	if not is_inside_tree(): return
	await get_tree().process_frame
	if not is_inside_tree() or not rows.has(selected_uid): return
	var sc: ScrollContainer={"inventory":bag_scroll,"warehouse":grid_scroll,"cloth":cloth_scroll}[selected_source]
	sc.ensure_control_visible(rows[selected_uid])
func build_details(p: Control) -> void:
	if selected_uid=="":
		label_at(p,"アイテムを選んでください",Rect2(26,190,300,40),20,MUTED); return
	var item: Dictionary=game.cfg.items[game.campaign.items[selected_uid]]
	var d:=Catalog.details(game.campaign,selected_uid,game.cfg)
	icon_at(p,item.slot,Rect2(18,54,90,90),game.campaign.items[selected_uid])
	var title:=label_at(p,d.name,Rect2(116,56,212,52),22,GOLD); title.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	label_at(p,d.type+" / "+{"inventory":"バックパック","warehouse":"倉庫","cloth":"父親の風呂敷"}[selected_source],Rect2(116,110,213,28),14,MUTED)
	label_at(p,"所持数 %d     倉庫内数 %d"%[d.carried,d.stored],Rect2(20,151,310,28),17)
	var paper:=ColorRect.new(); paper.position=Vector2(18,190); paper.size=Vector2(312,73); paper.color=Color("c4b28a"); paper.mouse_filter=Control.MOUSE_FILTER_IGNORE; p.add_child(paper)
	var desc:=label_at(p,d.description,Rect2(26,196,296,62),17,Color("302c22")); desc.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	if game.campaign.items[selected_uid]=="C01":
		label_at(p,"この束：%d枚 / 1枚=1G"%game.campaign.quantities[selected_uid],Rect2(22,277,304,30),18)
		var coins:=UISkin.button(p,"数量指定 / 分割・結合",Rect2(22,328,304,44),func():game.open_services("coin",selected_uid,selected_source))
		coins.set_meta("nav","warehouse-coins")
	var values: Array=[]
	if not item.stats.is_empty(): values.append(["現在値",game.item_effects(item,selected_uid)])
	if item.slot!="": values.append(["耐久度",game.condition_text(selected_uid).replace("耐久 ","")]); values.append(["個体・印",preload("res://ui/item_presenter.gd").profile(game.campaign,game.cfg,selected_uid)])
	for field in [["使用回数",d.uses],["特殊効果",d.special],["刻印",d.marks]]:
		if str(field[1]) not in ["","—","未導入"]: values.append(field)
	for i in values.size():
		var y:=276+i*43
		UISkin.rule(p,Rect2(18,y,312,1))
		label_at(p,values[i][0],Rect2(21,y+5,78,32),15,MUTED)
		var value:=label_at(p,values[i][1],Rect2(102,y+5,225,36),16); value.autowrap_mode=TextServer.AUTOWRAP_WORD; value.tooltip_text=values[i][1]
	var destination: String="inventory" if selected_source=="warehouse" else "warehouse"
	detail_move=UISkin.button(p,("取り出す" if selected_source=="warehouse" else "預ける")+" [Enter]",Rect2(22,445,304,44),func():move_item(selected_uid,selected_source,destination,int(game.campaign.revision)),true)
	detail_move.tooltip_text=Storage.reason(game.campaign,selected_uid,selected_source,destination,game.cfg)
	if detail_move.tooltip_text!="": label_at(p,detail_move.tooltip_text,Rect2(22,412,304,28),14)
func build_actions() -> void:
	var entries: Array=[["預ける","deposit","warehouse","warehouse"],["引き出す","withdraw","inventory","body"],["整理","organize","","material"],["風呂敷へ","to_cloth","cloth","cloth"],["戻る","back","","lantern"]]
	for i in entries.size():
		var e: Array=entries[i]
		var b: Button
		if e[1]=="back":
			b=game.button(e[0],func(): game.open_town_page("hub"))
		else:
			var args: Dictionary
			if e[1]=="organize": args={"mode":game.warehouse_state.get("sort","category")}
			else:
				args={"uid":selected_uid}
				var default_source: String="warehouse" if e[1]=="withdraw" else "inventory"
				if selected_source!=default_source: args.source=selected_source
			if e[1]=="organize": b=game.command(e[0]+" [R]",e[1],args)
			else:
				b=game.button(e[0]+(" [F]" if e[1]=="to_cloth" else ""),func():move_item(selected_uid,selected_source,e[2],int(game.campaign.revision)))
				b.set_meta("campaign_action",e[1]); b.set_meta("campaign_args",args); game.play_buttons[e[1]]=b
			if e[1]!="organize":
				var error:=Storage.reason(game.campaign,selected_uid,selected_source,e[2],game.cfg)
				b.tooltip_text=error
		b.position=Vector2(16+i*252,646); b.size=Vector2(240,58); b.custom_minimum_size=Vector2.ZERO
		skin(b,false,e[1]=="to_cloth"); add_child(b)
		var ornament:=Control.new(); ornament.set_script(Frame); ornament.ornament_only=true; b.add_child(ornament); ornament.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		icon_at(b,e[3],Rect2(16,8,40,40))
		b.pressed.connect(remember_scroll)
		if i==0 and is_instance_valid(detail_move): detail_move.grab_focus()
func accepts(value: Variant, destination: String, explain: bool=false) -> bool:
	if not value is Dictionary or value.get("kind")!="dive-item" or value.get("revision")!=game.campaign.revision: return false
	var reason: String=Storage.reason(game.campaign,value.get("uid",""),value.get("source",""),destination,game.cfg)
	if explain and is_instance_valid(guide_label): guide_label.text=reason if reason!="" else "離すと%sへ全量移動します。数量・個体・耐久を保持"%{"inventory":"バックパック","warehouse":"倉庫","cloth":"風呂敷"}[destination]
	return reason==""
func move_item(uid: String, source: String, destination: String, revision: int) -> void:
	remember_scroll()
	game.transfer_item(uid,source,destination,revision)
func _notification(what: int) -> void:
	if what==NOTIFICATION_DRAG_END and not drag_payload.is_empty():
		if not get_viewport().gui_is_drag_successful():
			game.notice="移動を取り消しました。移動先の空き・収納制限を確認してください。"
			game.call_deferred("show_campaign")
		drag_payload={}
func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode in [KEY_ENTER,KEY_R,KEY_F]:
		get_viewport().set_input_as_handled()
		if event.keycode==KEY_R: game.call_deferred("perform","organize",{"mode":game.warehouse_state.get("sort","category")},int(game.campaign.revision))
		else: call_deferred("move_item",selected_uid,selected_source,"cloth" if event.keycode==KEY_F else ("inventory" if selected_source=="warehouse" else "warehouse"),int(game.campaign.revision))
		return
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled(); game.call_deferred("open_town_page","hub")
func visual_audit() -> Dictionary:
	return {"kind":"warehouse","columns":3,"selected_source":selected_source,"selected_uid":selected_uid,"visible_warehouse_items":visible_items.size(),"backpack_capacity":15,"cloth_capacity":3,"no_equipment_commands":true}
