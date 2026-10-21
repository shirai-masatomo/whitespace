extends Control
## Town-only, read-only character view. Tabs never rebuild the outer screen.
const InterfaceArt=preload("res://ui/interface_art.gd")
const Symbols=preload("res://ui/status_symbols.gd")
const Model=preload("res://ui/status_model.gd")
const E=preload("res://core/expedition.gd")
const Art=preload("res://ui/visual_assets.gd")
const EquipmentArt=preload("res://ui/equipment_art.gd")
const Icons=preload("res://ui/item_icons.gd")
const Frame=preload("res://ui/warehouse_frame.gd")
const UISkin=preload("res://ui/ui_skin.gd")
const Paper=preload("res://ui/panel_frame.gd")
const GOLD=Color("e5c37e")
const INK=Color("e8e3ce")
const MUTED=Color("9caeac")
const DARK=Color("302b23")
const TABS={"equipment":"装備","abilities":"能力","conditions":"状態・耐性","profile":"プロフィール"}
var game: Control
var active_tab: String="equipment"
var selection: Dictionary={"equipment":"head","abilities":"atk","conditions":"current","profile":"species"}
var tab_buttons: Dictionary={}
var item_buttons: Dictionary={}
var party_buttons: Array[Button]=[]
var central: Control
var detail_scroll: ScrollContainer
var details: VBoxContainer
var left_panel: Control
var back_button: Button
var unit: Dictionary
var left_values: Dictionary={}
var bars: Dictionary={}
var gauges: Dictionary={}
var container_counts: Dictionary={}
var tab_tween: Tween
var detail_tween: Tween
var gauge_tween: Tween
var closing:=false
var input_locked:=true
var return_page: String="hub"
func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	unit=Model.actor(game.campaign,game.cfg,game.data,game.selected_actor)
	active_tab=game.status_memory.get("tab","equipment");selection=game.status_memory.get("selection",selection).duplicate(true)
	build()
	modulate.a=0.0
	var entry:=create_tween(); entry.tween_property(self,"modulate:a",1.0,0.20)
	entry.finished.connect(func(): input_locked=false; tab_buttons[active_tab].grab_focus())
func label_at(parent: Control, value: String, r: Rect2, font_size: int=18, color: Color=INK) -> Label:
	var l:=Label.new(); l.language="ja"; l.vertical_alignment=VERTICAL_ALIGNMENT_CENTER; l.clip_text=true; l.text=value; l.position=r.position; l.size=r.size
	l.set_meta("normal_color",color)
	if parent is Button and parent.get_meta("gold_surface",false): color=DARK
	l.add_theme_font_size_override("font_size",font_size); l.add_theme_color_override("font_color",color); l.mouse_filter=Control.MOUSE_FILTER_IGNORE; parent.add_child(l); l.size=r.size; return l
func image_at(parent: Control, texture: Texture2D, r: Rect2, crop: bool=false) -> TextureRect:
	var t:=TextureRect.new(); t.expand_mode=TextureRect.EXPAND_IGNORE_SIZE; t.texture=texture; t.position=r.position; t.size=r.size
	t.clip_contents=crop; t.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_COVERED if crop else TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	t.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST; t.mouse_filter=Control.MOUSE_FILTER_IGNORE; parent.add_child(t); return t
func face() -> Texture2D:
	var atlas:=AtlasTexture.new(); atlas.atlas=Art.texture("hero"); atlas.region=Rect2(410,210,390,370); return atlas
func panel(r: Rect2, title: String, prominent: bool=false, ornament_only: bool=false) -> Control:
	return UISkin.panel(self,r,title)
func skin(b: Button, selected: bool=false) -> void:
	UISkin.quiet_button(b,selected)
func button_at(parent: Control, text: String, r: Rect2, callback: Callable, selected: bool=false) -> Button:
	var b:=Button.new(); b.text=text; b.position=r.position; b.size=r.size; skin(b,selected); parent.add_child(b); b.pressed.connect(callback); return b
func paper_at(parent: Control, r: Rect2) -> void:
	InterfaceArt.paper(parent,r)
func build() -> void:
	var header:=panel(Rect2(16,14,1248,64),"",true)
	label_at(header,"ステータス",Rect2(28,10,540,40),27)
	label_at(header,unit.name+" / 能力・装備の確認",Rect2(780,14,250,34),18,MUTED)
	label_at(header,"G  %d"%E.money(game.campaign),Rect2(1080,11,145,40),23,GOLD)
	left_panel=panel(Rect2(16,92,296,510),unit.name,true)
	build_left()
	var middle:=panel(Rect2(324,92,580,510),"",true)
	var index:=0
	for key in TABS:
		var b:=button_at(middle,TABS[key],Rect2(14+index*139,11,134,34),func(): choose_tab(key),key==active_tab)
		b.add_theme_font_size_override("font_size",17); b.set_meta("status_tab",key); tab_buttons[key]=b; index+=1
	central=Control.new(); central.position=Vector2(14,61); central.size=Vector2(552,432); middle.add_child(central)
	var right:=panel(Rect2(916,92,348,510),"詳細")
	detail_scroll=ScrollContainer.new(); detail_scroll.position=Vector2(18,54); detail_scroll.size=Vector2(312,382); detail_scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED; detail_scroll.theme=UISkin.scroll_theme(); right.add_child(detail_scroll)
	details=VBoxContainer.new(); details.size_flags_horizontal=Control.SIZE_EXPAND_FILL; details.add_theme_constant_override("separation",12); detail_scroll.add_child(details)
	label_at(right,"装備変更は準備の「装備」から" if game.campaign.phase=="town" else "装備変更は「所持品・装備」から",Rect2(20,454,310,38),14,MUTED)
	build_party()
	back_button=button_at(self,"戻る",Rect2(1060,616,204,88),request_close)
	var border:=Control.new(); border.set_script(Frame); border.ornament_only=true; back_button.add_child(border); border.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	back_button.add_theme_font_size_override("font_size",24); back_button.tooltip_text="前の画面へ / Esc・右クリック"
	build_content()
	wire_tabs()
func build_left() -> void:
	paper_at(left_panel,Rect2(9,48,278,453))
	image_at(left_panel,face(),Rect2(24,61,105,124))
	label_at(left_panel,"Lv.%d"%unit.level,Rect2(145,73,130,38),27,DARK)
	label_at(left_panel,Model.profile().get("species","未設定"),Rect2(145,119,130,28),17,Color("675135"))
	label_at(left_panel,"冒険準備中" if game.campaign.phase=="town" else "地下 %d F"%game.campaign.floor,Rect2(145,150,130,26),14,Color("675135"))
	UISkin.rule(left_panel,Rect2(24,201,248,1),Color("ad946b"))
	make_gauge("hp","HP",int(unit.hp),int(unit.max_hp),225,Color("a83d32"))
	make_gauge("sp","SP",int(unit.sp),int(unit.max_sp),270,Color("267c9c"))
	var level: Dictionary=E.level_info(game.campaign,game.cfg) if game.selected_actor=="hero" else {"progress":0,"next":0}
	make_gauge("exp","EXP",int(level.progress),int(level.next),315,Color("b78229"))
	if unit.level>=int(game.cfg.growth.level_cap): left_values.exp.text="MAX"; bars.exp.value=bars.exp.max_value
	UISkin.rule(left_panel,Rect2(24,365,248,1),Color("ad946b"))
	label_at(left_panel,"探索記録",Rect2(24,376,248,27),17,Color("675135"))
	var rows: Array=[["到達記録","%d F"%game.campaign.highest_floor],["探索回数","%d 回"%E.normal_trips(game.campaign)],["装備中","%d / 11"%preload("res://core/party_ui.gd").gear(game.campaign,game.selected_actor).values().filter(func(uid):return uid!="").size()]]
	for i in rows.size():
		label_at(left_panel,rows[i][0],Rect2(24,411+i*28,118,25),15,Color("675135"))
		label_at(left_panel,rows[i][1],Rect2(153,411+i*28,119,25),18,DARK)
func make_gauge(key: String, title: String, current: int, maximum: int, y: int, color: Color) -> void:
	label_at(left_panel,title,Rect2(24,y-8,54,25),16,DARK)
	left_values[key]=label_at(left_panel,"%d / %d"%[current,maximum],Rect2(91,y-8,181,25),18,DARK)
	left_values[key].horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT
	var bar:=Control.new(); bar.set_script(preload("res://ui/vital_gauge.gd")); bar.position=Vector2(24,y+20); bar.size=Vector2(248,12); bar.max_value=maxi(1,maximum); bar.value=current; bar.mouse_filter=Control.MOUSE_FILTER_IGNORE
	bar.tint=color; left_panel.add_child(bar); bars[key]=bar
	gauges[key]={"current":current,"maximum":maximum}
func refresh_character() -> void:
	# Called only when the owning screen receives an actual data refresh.
	unit=Model.actor(game.campaign,game.cfg,game.data,game.selected_actor)
	if is_instance_valid(gauge_tween): gauge_tween.kill()
	gauge_tween=create_tween().set_parallel(true)
	for key in ["hp","sp"]:
		var maximum: int=unit["max_"+key]; var current: int=unit[key]
		left_values[key].text="%d / %d"%[current,maximum]; bars[key].max_value=maxi(1,maximum); gauge_tween.tween_property(bars[key],"value",float(current),0.15); gauges[key]={"current":current,"maximum":maximum}
	build_content()
func build_party() -> void:
	preload("res://ui/party_picker.gd").build(self,game,Rect2(16,626,650,60))
	button_at(self,"装備",Rect2(684,626,168,60),func():game.call_deferred("open_equipment_from_status")).set_meta("nav","status-equipment")
	button_at(self,"作戦",Rect2(868,626,168,60),func():game.call_deferred("open_services","tactics")).set_meta("nav","status-tactics")
func clear_children(parent: Node) -> void:
	for child in parent.get_children(): parent.remove_child(child); child.queue_free()
func choose_tab(key: String) -> void:
	if closing or input_locked or not TABS.has(key) or key==active_tab: return
	active_tab=key;game.status_memory.tab=key
	for tab in tab_buttons: skin(tab_buttons[tab],tab==key)
	build_content()
	if is_instance_valid(tab_tween): tab_tween.kill()
	central.modulate.a=0.25; tab_tween=create_tween(); tab_tween.tween_property(central,"modulate:a",1.0,0.10)
func select_item(id: String) -> void:
	if closing or input_locked: return
	selection[active_tab]=id;game.status_memory.selection=selection.duplicate(true)
	for key in item_buttons: skin(item_buttons[key],key==id)
	update_details()
func item_button(id: String, title: String, r: Rect2) -> Button:
	var b:=button_at(central,title,r,func(): select_item(id),selection[active_tab]==id); b.set_meta("status_item",id); item_buttons[id]=b; return b
func build_content() -> void:
	clear_children(central); item_buttons={}
	match active_tab:
		"equipment": build_equipment()
		"abilities": build_abilities()
		"conditions": build_conditions()
		"profile": build_profile()
	update_details()
	var ids:=item_buttons.keys()
	for i in ids.size():
		var b: Button=item_buttons[ids[i]]
		b.focus_next=b.get_path_to(item_buttons[ids[i+1]] if i+1<ids.size() else back_button)
		b.focus_previous=b.get_path_to(item_buttons[ids[i-1]] if i>0 else tab_buttons[active_tab])
	for key in tab_buttons: tab_buttons[key].focus_next=NodePath("")
	if not ids.is_empty(): tab_buttons[active_tab].focus_next=tab_buttons[active_tab].get_path_to(item_buttons[ids[0]])
	back_button.focus_next=back_button.get_path_to(tab_buttons[active_tab])
func build_equipment() -> void:
	var scene:=image_at(central,Art.texture("cavern"),Rect2(94,5,364,411),true); scene.modulate=Color(0.62,0.72,0.72)
	var actor:=image_at(central,Art.actor_texture("hero"),Rect2(100,64,352,324)); actor.name="EquipmentActor"
	for c in 2:
		var slots: Array=[["head","body","right_hand","legs","feet"],["neck","ears","eyes","left_hand","wrist","finger"]][c]
		for i in slots.size():
			var slot: String=slots[i]; var item:=Model.equipment(game.campaign,game.cfg,slot,game.selected_actor)
			var b:=item_button(slot,"",Rect2(472 if c==1 else 12,8+i*68,68,64))
			if not item.empty: image_at(b,EquipmentArt.texture(item.template_id,slot),Rect2(7,5,54,54))
			else:
				var silhouette:=Control.new(); silhouette.set_script(preload("res://ui/slot_silhouette.gd")); silhouette.slot=slot; silhouette.position=Vector2(15,12); silhouette.size=Vector2(38,38); b.add_child(silhouette)
			b.tooltip_text=game.cfg.slots[slot]+" / "+("未装備" if item.empty else item.name)
	var art_note:=label_at(central,"人物の外観は共通イラスト",Rect2(117,393,320,25),13,MUTED); art_note.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
func build_abilities() -> void:
	label_at(central,"基本能力",Rect2(9,6,220,34),25,GOLD)
	var current_header:=label_at(central,"現在値",Rect2(205,10,118,28),15,MUTED); current_header.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT
	var parts_header:=label_at(central,"基礎 ＋ 装備・状態",Rect2(342,10,177,28),15,MUTED); parts_header.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT
	var i:=0
	for key in ["atk","def","spd"]:
		var base:=Model.base_value(game.campaign,game.cfg,key,game.selected_actor); var total: float=E.Combat.effective_def(unit,game.data.rules) if key=="def" else float(unit[key])
		var b:=item_button(key,"",Rect2(8,54+i*58,536,50))
		image_at(b,Symbols.texture({"max_hp":"hp","max_sp":"sp"}.get(key,key)),Rect2(7,9,32,32))
		label_at(b,Model.STAT_NAMES[key],Rect2(48,10,160,30),18)
		var current: String="%d / %d"%[unit["hp" if key=="max_hp" else "sp"],total] if key in ["max_hp","max_sp"] else str(snappedf(total,0.1))
		var value:=label_at(b,current,Rect2(205,10,118,30),18,GOLD); value.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT
		var correction:=label_at(b,"%d ＋ %s"%[base,str(snappedf(total-base,0.1))],Rect2(342,10,177,30),18,MUTED); correction.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT
		i+=1
	label_at(central,"HP・SPは左のゲージに表示
器用さ・魔攻・魔防・運・精神・魅力・信仰：計算未実装",Rect2(12,264,525,84),16,MUTED)
func build_conditions() -> void:
	var effects:=Model.effects(unit,game.data.rules)
	label_at(central,"現在の状態",Rect2(8,2,525,32),24,GOLD)
	var normal:=item_button("current","",Rect2(8,42,536,45))
	image_at(normal,Symbols.texture("normal"),Rect2(9,6,32,32))
	label_at(normal,"状態異常なし / 防御態勢なし" if effects.is_empty() else "%d 件の状態が付与中"%effects.size(),Rect2(49,7,475,31),18)
	var ids: Array=["poison","blind","paralysis","defense"]
	for i in ids.size():
		var id: String=ids[i]; var active: Array=effects.filter(func(e):return e.id==id)
		var b:=item_button(id,"",Rect2(8+(i%2)*270,100+(i/2)*55,266,49))
		var symbol:=image_at(b,Symbols.texture(id),Rect2(7,8,32,32)); symbol.modulate.a=1.0 if not active.is_empty() else 0.55
		label_at(b,Model.EFFECT_NAMES[id],Rect2(46,7,117,32),17)
		var value:=label_at(b,"行動あと%d回分"%active[0].remaining if not active.is_empty() else ("未発動" if id=="defense" else "未付与"),Rect2(138,7,118,32),13,MUTED); value.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT
	label_at(central,"属性耐性",Rect2(9,222,525,34),24,GOLD)
	label_at(central,"属性ごとの耐性は未設定です。",Rect2(12,259,525,26),15,MUTED)
	var names: Array=["火","水","雷","土","風","光","闇","無"]
	for i in names.size():
		var b:=button_at(central,"%s   未設定"%names[i],Rect2(8+(i%2)*270,303+(i/2)*29,266,26),func(): pass)
		b.disabled=true; b.add_theme_font_size_override("font_size",15); b.tooltip_text="8属性は導入予定 / 現在は倍率未設定"
func build_profile() -> void:
	label_at(central,unit.name+"の記録",Rect2(8,3,530,36),25,GOLD)
	var facts:=Model.profile()
	item_button("species","種族    "+facts.get("species","未設定"),Rect2(8,55,292,42))
	item_button("journey","旅の記録    %d F / %d 回の探索"%[game.campaign.highest_floor,E.normal_trips(game.campaign)],Rect2(8,109,292,42))
	for info in [["年齢",facts.get("age","未設定")],["出身",facts.get("birthplace","未設定")],["職業",facts.get("occupation","未設定")]]:
		var index: int=["年齢","出身","職業"].find(info[0])
		label_at(central,info[0],Rect2(18,173+index*35,75,29),17,MUTED)
		label_at(central,str(info[1]),Rect2(104,173+index*35,185,29),17)
	image_at(central,Art.texture("cavern"),Rect2(320,55,224,230),true).modulate=Color(0.62,0.72,0.72)
	image_at(central,Art.actor_texture("hero"),Rect2(326,83,212,202))
	paper_at(central,Rect2(8,314,536,99))
	var note:=label_at(central,str(facts.get("description","人物紹介はまだ設定されていません。")),Rect2(23,329,507,69),18,DARK); note.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
func detail_text(value: String, font_size: int=18, color: Color=INK) -> Label:
	var l:=Label.new(); l.language="ja"; l.text=value; l.autowrap_mode=TextServer.AUTOWRAP_WORD; l.add_theme_font_size_override("font_size",font_size); l.add_theme_color_override("font_color",color); details.add_child(l); return l
func section(title: String, body: String) -> void:
	detail_text(title,16,MUTED); detail_text(body,18); details.add_child(HSeparator.new())
func detail_row(title: String, value: String, color: Color=INK) -> void:
	var row:=HBoxContainer.new(); row.add_theme_constant_override("separation",8); details.add_child(row)
	var name_label:=Label.new(); name_label.text=title; name_label.size_flags_horizontal=Control.SIZE_EXPAND_FILL; name_label.add_theme_font_size_override("font_size",16); name_label.add_theme_color_override("font_color",MUTED); row.add_child(name_label)
	var value_label:=Label.new(); value_label.text=value; value_label.add_theme_font_size_override("font_size",18); value_label.add_theme_color_override("font_color",color); row.add_child(value_label)
func detail_heading(title: String, icon: Texture2D, subtitle: String="") -> void:
	var row:=HBoxContainer.new(); row.add_theme_constant_override("separation",12); details.add_child(row)
	var picture:=TextureRect.new(); picture.expand_mode=TextureRect.EXPAND_IGNORE_SIZE; picture.texture=icon; picture.custom_minimum_size=Vector2(64,68); picture.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED; picture.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST; row.add_child(picture)
	var text:=VBoxContainer.new(); text.size_flags_horizontal=Control.SIZE_EXPAND_FILL; row.add_child(text)
	for value in [[title,23,GOLD],[subtitle,15,MUTED]]:
		if value[0]=="": continue
		var l:=Label.new(); l.language="ja"; l.text=value[0]; l.autowrap_mode=TextServer.AUTOWRAP_WORD; l.add_theme_font_size_override("font_size",value[1]); l.add_theme_color_override("font_color",value[2]); text.add_child(l)
func update_details() -> void:
	clear_children(details)
	var id: String=selection[active_tab]
	if active_tab=="equipment":
		var item:=Model.equipment(game.campaign,game.cfg,id,game.selected_actor)
		if item.empty:
			detail_heading(game.cfg.slots[id],Icons.texture(id),"未装備")
		else:
			detail_heading(item.name,EquipmentArt.texture(item.template_id,id),game.cfg.slots[id])
			detail_row("現在値",game.item_effects(item.item,item.uid),GOLD)
			var base: Dictionary=E.Condition.stats(game.campaign,item.uid,game.cfg,true)
			if base!=E.Condition.stats(game.campaign,item.uid,game.cfg): detail_row("基礎値",preload("res://ui/item_presenter.gd").text(base))
			detail_row("耐久度","%d / %d"%[item.condition.current,item.condition.maximum])
			detail_text(preload("res://ui/item_presenter.gd").profile(game.campaign,game.cfg,item.uid),16)
			for field in [["特殊効果","special_effects"],["刻印","marks"]]:
				if item.item.has(field[1]): detail_row(field[0],str(item.item[field[1]]))
			if item.description!="":
				details.add_child(HSeparator.new()); detail_text(item.description,17)
	elif active_tab=="abilities":
		detail_heading(Model.STAT_NAMES[id],Symbols.texture({"max_hp":"hp","max_sp":"sp"}.get(id,id)))
		var total: float=E.Combat.effective_def(unit,game.data.rules) if id=="def" else float(unit[id]); var base:=Model.base_value(game.campaign,game.cfg,id,game.selected_actor)
		detail_row("現在値",str(total),GOLD)
		detail_text(Model.STAT_TEXT[id],18)
		var impacts: Dictionary={"max_hp":"・受け止められるダメージ量","max_sp":"・自動スキルで使えるSPの上限","atk":"・通常攻撃の威力","def":"・受ける攻撃のダメージ軽減","spd":"・戦闘での行動順"}
		section("主な影響",impacts[id])
		detail_row("基礎値",str(base)); detail_row("装備・状態補正","%+.1f"%(total-base))
	elif active_tab=="conditions":
		var found:=false
		for effect in Model.effects(unit,game.data.rules):
			if effect.id==id:
				detail_heading(effect.name,Symbols.texture(id),"付与中"); detail_text(Model.effect_detail(effect,game.data),18); found=true; break
		if not found:
			if id=="current":
				detail_heading("現在の状態",Symbols.texture("normal"))
				detail_text("状態異常や防御態勢は付与されていません。" if Model.effects(unit,game.data.rules).is_empty() else "各状態を選ぶと、効果と自分の行動の残り回数を確認できます。",18)
			else:
				detail_heading(Model.EFFECT_NAMES[id],Symbols.texture(id),"現在は未発動" if id=="defense" else "現在は未付与")
				var descriptions: Dictionary={"poison":"自身の行動機会の開始時にHPを失う状態。ダメージ量は付与時の攻撃力を基に決まります。","blind":"命中率が低下する状態。低下量は発生元の技によって決まります。","paralysis":"自身の行動機会を失う状態。","defense":"防御力を上げる自動スキル。条件を満たしたときに発動します。"}
				detail_text(descriptions[id],18)
				if id=="defense":
					var rule: Dictionary=game.data.rules.skills.S105
					detail_row("消費SP",str(int(rule.sp_cost))); detail_row("防御力","＋%d%%"%roundi(float(rule.def_bonus)*100))
				detail_text("付与中は、自分の行動の残り回数と発生元をここで確認できます。",16,MUTED)
		section("属性耐性","火・水・雷・土・風・光・闇・無。属性ごとの耐性は未設定です。")
	else:
		if id=="species":
			detail_heading(unit.name,face(),Model.profile().get("species","未設定"))
			detail_text("年齢・出身・職業・人物紹介は未設定です。",18)
		else:
			detail_heading("旅の記録",Symbols.texture("normal"))
			detail_row("到達記録","%d F"%game.campaign.highest_floor); detail_row("通常の探索","%d 回"%E.normal_trips(game.campaign)); detail_row("通常の死亡","%d 回"%E.normal_deaths(game.campaign))
			detail_text("この起動中の冒険の記録です。",17,MUTED)
	detail_scroll.set_deferred("scroll_vertical",0)
	if is_instance_valid(detail_tween): detail_tween.kill()
	details.modulate.a=0.5; detail_tween=create_tween(); detail_tween.tween_property(details,"modulate:a",1.0,0.08)
func wire_tabs() -> void:
	var keys:=TABS.keys()
	for i in keys.size():
		tab_buttons[keys[i]].focus_neighbor_left=tab_buttons[keys[i]].get_path_to(tab_buttons[keys[(i+3)%4]])
		tab_buttons[keys[i]].focus_neighbor_right=tab_buttons[keys[i]].get_path_to(tab_buttons[keys[(i+1)%4]])
func request_close() -> void:
	if closing or input_locked: return
	closing=true; back_button.disabled=true
	var exit:=create_tween(); exit.tween_property(self,"modulate:a",0.0,0.18)
	exit.finished.connect(func(): if is_inside_tree(): game.close_status())
func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and not input_locked and not closing:
		if event.keycode>=KEY_1 and event.keycode<=KEY_4:
			var key: String=TABS.keys()[event.keycode-KEY_1]; choose_tab(key); tab_buttons[key].grab_focus(); get_viewport().set_input_as_handled()
		elif event.keycode==KEY_TAB and event.ctrl_pressed:
			var keys:=TABS.keys(); var index: int=keys.find(active_tab); var key: String=keys[(index+(3 if event.shift_pressed else 1))%4]; choose_tab(key); tab_buttons[key].grab_focus(); get_viewport().set_input_as_handled()
		elif event.keycode==KEY_ESCAPE:
			request_close(); get_viewport().set_input_as_handled()
func visual_audit() -> Dictionary:
	var rects: Dictionary={}
	for slot in item_buttons: rects[slot]=str(item_buttons[slot].get_global_rect())
	return {"kind":"status","tab":active_tab,"selected":selection[active_tab],"hero":unit.name,"equipment_slots":E.SLOTS.size(),"item_rects":rects,"party_active":preload("res://core/party_ui.gd").ids(game.campaign).size(),"selected_actor":game.selected_actor,"gauge_values":gauges,"read_only":true,"detail_scroll_max":detail_scroll.get_v_scroll_bar().max_value}
