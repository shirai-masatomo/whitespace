extends Control
## Town-only, read-only character view. Tabs never rebuild the outer screen.
const Symbols=preload("res://ui/status_symbols.gd")
const Model=preload("res://ui/status_model.gd")
const E=preload("res://core/expedition.gd")
const Art=preload("res://ui/visual_assets.gd")
const Icons=preload("res://ui/item_icons.gd")
const Frame=preload("res://ui/warehouse_frame.gd")
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
	unit=Model.actor(game.campaign,game.cfg,game.data)
	build()
	modulate.a=0.0
	var entry:=create_tween(); entry.tween_property(self,"modulate:a",1.0,0.20)
	entry.finished.connect(func(): input_locked=false; tab_buttons.equipment.grab_focus())
func label_at(parent: Control, value: String, r: Rect2, font_size: int=18, color: Color=INK) -> Label:
	var l:=Label.new(); l.clip_text=true; l.text=value; l.position=r.position; l.size=r.size
	l.add_theme_font_size_override("font_size",font_size); l.add_theme_color_override("font_color",color); l.mouse_filter=Control.MOUSE_FILTER_IGNORE; parent.add_child(l); return l
func image_at(parent: Control, texture: Texture2D, r: Rect2, crop: bool=false) -> TextureRect:
	var t:=TextureRect.new(); t.expand_mode=TextureRect.EXPAND_IGNORE_SIZE; t.texture=texture; t.position=r.position; t.size=r.size
	t.clip_contents=crop; t.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_COVERED if crop else TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	t.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST; t.mouse_filter=Control.MOUSE_FILTER_IGNORE; parent.add_child(t); return t
func face() -> Texture2D:
	var atlas:=AtlasTexture.new(); atlas.atlas=Art.texture("hero"); atlas.region=Rect2(410,210,390,370); return atlas
func panel(r: Rect2, title: String, prominent: bool=false, ornament_only: bool=false) -> Control:
	var p:=Control.new(); p.set_script(Frame); p.prominent=prominent; p.ornament_only=ornament_only; p.position=r.position; p.size=r.size; add_child(p)
	if title!="": label_at(p,title,Rect2(20,8,r.size.x-40,32),22,GOLD)
	return p
func skin(b: Button, selected: bool=false) -> void:
	for mode in ["normal","hover","pressed","disabled","focus"]:
		var st:=StyleBoxFlat.new(); st.set_content_margin_all(4); st.set_border_width_all(1); st.bg_color=Color("0b1b21"); st.border_color=Color("6a5b41")
		if selected: st.bg_color=Color("393329"); st.border_color=GOLD; st.set_border_width_all(2)
		if mode=="hover": st.border_color=Color("ffe3a1"); st.bg_color=Color("2b352f")
		if mode=="pressed": st.bg_color=Color("4b3925"); st.border_color=Color("85653a"); st.border_width_top=3; st.border_width_left=3
		if mode=="disabled": st.bg_color=Color("101c20"); st.border_color=Color("364443")
		if mode=="focus": st.bg_color=Color.TRANSPARENT; st.border_color=Color("71bec6"); st.set_border_width_all(2)
		b.add_theme_stylebox_override(mode,st)
	b.add_theme_color_override("font_color",INK); b.add_theme_color_override("font_hover_color",Color("fff2d5")); b.add_theme_color_override("font_pressed_color",GOLD); b.add_theme_color_override("font_focus_color",INK); b.add_theme_color_override("font_disabled_color",Color("71807d"))
	b.add_theme_font_size_override("font_size",18)
func button_at(parent: Control, text: String, r: Rect2, callback: Callable, selected: bool=false) -> Button:
	var b:=Button.new(); b.text=text; b.position=r.position; b.size=r.size; skin(b,selected); parent.add_child(b); b.pressed.connect(callback); return b
func paper_at(parent: Control, r: Rect2) -> void:
	var c:=ColorRect.new(); c.color=Color("d1bc8e"); c.position=r.position; c.size=r.size; c.mouse_filter=Control.MOUSE_FILTER_IGNORE; parent.add_child(c)
	var fibers:=Control.new(); fibers.set_script(Paper); fibers.parchment=true; fibers.position=r.position+Vector2(8,8); fibers.size=r.size-Vector2(16,16); parent.add_child(fibers)
func build() -> void:
	var header:=panel(Rect2(16,14,1248,64),"",true)
	image_at(header,Icons.texture("lantern"),Rect2(12,8,40,40))
	var brand:=label_at(header,"Dive In Under",Rect2(54,9,280,44),31,GOLD); var serif:=SystemFont.new(); serif.font_names=PackedStringArray(["Georgia"]); brand.add_theme_font_override("font",serif)
	label_at(header,"ステータス",Rect2(350,10,280,40),27)
	label_at(header,"町  /  主人公",Rect2(780,14,250,34),18,MUTED)
	label_at(header,"G  %d"%game.campaign.gold,Rect2(1080,11,145,40),23,GOLD)
	left_panel=panel(Rect2(16,92,296,510),unit.name,true)
	build_left()
	var middle:=panel(Rect2(324,92,580,510),"",true)
	var index:=0
	for key in TABS:
		var b:=button_at(middle,TABS[key],Rect2(14+index*139,11,134,34),func(): choose_tab(key),key==active_tab)
		b.add_theme_font_size_override("font_size",17); b.set_meta("status_tab",key); tab_buttons[key]=b; index+=1
	central=Control.new(); central.position=Vector2(14,61); central.size=Vector2(552,432); middle.add_child(central)
	var right:=panel(Rect2(916,92,348,510),"詳細")
	detail_scroll=ScrollContainer.new(); detail_scroll.position=Vector2(18,54); detail_scroll.size=Vector2(312,436); detail_scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED; right.add_child(detail_scroll)
	details=VBoxContainer.new(); details.size_flags_horizontal=Control.SIZE_EXPAND_FILL; details.add_theme_constant_override("separation",12); detail_scroll.add_child(details)
	build_party()
	back_button=button_at(self,"戻る",Rect2(1060,616,204,88),request_close)
	var border:=Control.new(); border.set_script(Frame); border.ornament_only=true; back_button.add_child(border); border.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	back_button.add_theme_font_size_override("font_size",24); back_button.tooltip_text="町へ戻る / Esc"
	build_content()
	wire_tabs()
func build_left() -> void:
	paper_at(left_panel,Rect2(9,48,278,453))
	image_at(left_panel,face(),Rect2(20,64,106,140))
	label_at(left_panel,"Lv.%d"%unit.level,Rect2(141,62,137,35),25,DARK)
	make_gauge("hp","HP",int(unit.hp),int(unit.max_hp),105,Color("a83d32"))
	make_gauge("sp","SP",int(unit.sp),int(unit.max_sp),147,Color("267c9c"))
	var level: Dictionary=E.level_info(game.campaign,game.cfg)
	make_gauge("exp","EXP",int(level.progress),int(level.next),189,Color("b78229"))
	if unit.level>=int(game.cfg.growth.level_cap): left_values.exp.text="MAX"; bars.exp.value=bars.exp.max_value
	var rows: Array=[["種族",Model.profile().get("species","未設定")],["現在地","町"],["到達記録","%d F"%game.campaign.highest_floor],["探索回数","%d 回"%E.normal_trips(game.campaign)],["装備中","%d / 11"%game.campaign.equipment.values().filter(func(uid):return uid!="").size()]]
	for i in rows.size():
		var y:=244+i*35
		var line:=ColorRect.new(); line.position=Vector2(22,y-2); line.size=Vector2(250,1); line.color=Color("ae9465"); line.mouse_filter=Control.MOUSE_FILTER_IGNORE; left_panel.add_child(line)
		label_at(left_panel,rows[i][0],Rect2(24,y+2,90,28),17,Color("675135"))
		label_at(left_panel,rows[i][1],Rect2(122,y+2,153,28),18,DARK)
	var note:=label_at(left_panel,"ひとり、地下を歩む。",Rect2(24,446,247,38),18,DARK); note.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
func make_gauge(key: String, title: String, current: int, maximum: int, y: int, color: Color) -> void:
	label_at(left_panel,title,Rect2(141,y-6,47,23),14,DARK)
	left_values[key]=label_at(left_panel,"%d / %d"%[current,maximum],Rect2(184,y-6,88,23),14,DARK)
	left_values[key].horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT
	var bar:=ProgressBar.new(); bar.position=Vector2(141,y+19); bar.size=Vector2(132,13); bar.max_value=maxi(1,maximum); bar.value=current; bar.show_percentage=false; bar.mouse_filter=Control.MOUSE_FILTER_IGNORE
	var bg:=StyleBoxFlat.new(); bg.bg_color=Color("352f28"); bg.border_color=Color("685237"); bg.set_border_width_all(1); bar.add_theme_stylebox_override("background",bg)
	var fill:=StyleBoxFlat.new(); fill.bg_color=color; fill.border_color=color.lightened(0.3); fill.set_border_width_all(1); bar.add_theme_stylebox_override("fill",fill); left_panel.add_child(bar); bar.size=Vector2(132,13); bars[key]=bar
	gauges[key]={"current":current,"maximum":maximum}
func refresh_character() -> void:
	# Called only when the owning screen receives an actual data refresh.
	unit=Model.actor(game.campaign,game.cfg,game.data)
	if is_instance_valid(gauge_tween): gauge_tween.kill()
	gauge_tween=create_tween().set_parallel(true)
	for key in ["hp","sp"]:
		var maximum: int=unit["max_"+key]; var current: int=unit[key]
		left_values[key].text="%d / %d"%[current,maximum]; bars[key].max_value=maxi(1,maximum); gauge_tween.tween_property(bars[key],"value",float(current),0.15); gauges[key]={"current":current,"maximum":maximum}
	build_content()
func build_party() -> void:
	var p:=panel(Rect2(16,616,756,88),"",false,true)
	label_at(p,"パーティ",Rect2(15,1,150,23),15,GOLD)
	for pair in 3:
		for member in 2:
			var actual: bool=pair==0 and member==0
			var x:=12+pair*244+member*116
			var text: String="主人公  Lv.%d"%unit.level if actual else ("人間 / 未加入" if member==0 else "配下 / 未解放")
			var b:=button_at(p,text,Rect2(x,28,112,47),func(): if not closing: refresh_character(),actual); b.add_theme_font_size_override("font_size",12); b.disabled=not actual
			b.tooltip_text="主人公を確認" if actual else ("人間1名につき配下1体 / 工程5以降"); party_buttons.append(b)
			if actual:
				image_at(b,face(),Rect2(4,4,31,36)); b.text=""; label_at(b,"主人公",Rect2(39,4,70,22),13); label_at(b,"Lv.%d"%unit.level,Rect2(39,24,70,19),12,MUTED)
	for info in [["inventory","所持品","bag",15,784],["cloth","父親の風呂敷","cloth",3,922]]:
		var card:=panel(Rect2(info[4],616,126,88),"")
		label_at(card,info[1],Rect2(10,9,108,28),15,GOLD)
		image_at(card,Symbols.texture("bag") if info[0]=="inventory" else Icons.texture("cloth"),Rect2(8,47,36,33))
		container_counts[info[0]]=label_at(card,"%d / %d"%[game.campaign[info[0]].size(),info[3]],Rect2(47,46,72,34),18)
		card.tooltip_text="内容の移動は町の倉庫で行います。"
func clear_children(parent: Node) -> void:
	for child in parent.get_children(): parent.remove_child(child); child.queue_free()
func choose_tab(key: String) -> void:
	if closing or input_locked or not TABS.has(key) or key==active_tab: return
	active_tab=key
	for tab in tab_buttons: skin(tab_buttons[tab],tab==key)
	build_content()
	if is_instance_valid(tab_tween): tab_tween.kill()
	central.modulate.a=0.25; tab_tween=create_tween(); tab_tween.tween_property(central,"modulate:a",1.0,0.10)
func select_item(id: String) -> void:
	if closing or input_locked: return
	selection[active_tab]=id
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
	var scene:=image_at(central,Art.texture("cavern"),Rect2(160,20,232,358),true); scene.modulate=Color(0.62,0.72,0.72)
	image_at(central,Art.actor_texture("hero"),Rect2(152,89,248,270))
	for c in 2:
		var column: Array=[["head","body","right_hand","legs","feet"],["neck","ears","eyes","left_hand","wrist","finger"]][c]
		var right: bool=c==1; var x:=402 if right else 0
		for i in column.size():
			var slot: String=column[i]; var item:=Model.equipment(game.campaign,game.cfg,slot)
			var b:=item_button(slot,"",Rect2(x,16+i*(64 if right else 72),150,58))
			label_at(b,game.cfg.slots[slot],Rect2(44,3,101,22),14,MUTED)
			var name_label:=label_at(b,item.name,Rect2(44,25,101,28),14)
			name_label.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
			if not item.empty: image_at(b,Icons.texture(slot),Rect2(3,11,39,39))
			else: label_at(b,"—",Rect2(10,14,30,28),23,Color("667b7c"))
			b.tooltip_text=game.cfg.slots[slot]+" / "+item.name+" / Enterで詳細"
	label_at(central,"装備枠を選ぶと詳細を表示",Rect2(164,365,226,26),15,GOLD)
	var art_note:=label_at(central,"装備の見た目は共通イラスト",Rect2(163,392,233,23),13,MUTED); art_note.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
func build_abilities() -> void:
	label_at(central,"基本能力",Rect2(9,6,220,34),25,GOLD)
	label_at(central,"現在値       基礎 ＋ 装備",Rect2(217,10,320,28),16,MUTED)
	var i:=0
	for key in Model.STAT_NAMES:
		var base:=Model.base_value(game.campaign,game.cfg,key); var total: int=unit[key]
		var b:=item_button(key,"",Rect2(8,54+i*59,536,49))
		image_at(b,Symbols.texture({"max_hp":"hp","max_sp":"sp"}.get(key,key)),Rect2(7,8,32,32))
		label_at(b,Model.STAT_NAMES[key],Rect2(48,8,160,32),19)
		var current: String="%d / %d"%[unit["hp" if key=="max_hp" else "sp"],total] if key in ["max_hp","max_sp"] else str(total)
		var value:=label_at(b,current,Rect2(205,8,118,32),20,GOLD); value.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT
		var correction:=label_at(b,"%d ＋ %d"%[base,total-base],Rect2(342,8,177,32),17,MUTED); correction.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT
		i+=1
	label_at(central,"装備と耐久を反映した、現在の能力です。",Rect2(12,365,525,31),16,MUTED)
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
		var value:=label_at(b,"残り%d"%active[0].remaining if not active.is_empty() else ("未発動" if id=="defense" else "未付与"),Rect2(166,7,90,32),15,MUTED); value.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT
	label_at(central,"属性耐性",Rect2(9,222,525,34),24,GOLD)
	label_at(central,"属性ごとの耐性は未設定です。",Rect2(12,259,525,26),15,MUTED)
	var names: Array=["火","水","雷","土","風","光","闇","無"]
	for i in names.size():
		var b:=button_at(central,"%s   未設定"%names[i],Rect2(8+(i%2)*270,303+(i/2)*29,266,26),func(): pass)
		b.disabled=true; b.add_theme_font_size_override("font_size",15); b.tooltip_text="8属性は導入予定 / 現在は倍率未設定"
func build_profile() -> void:
	label_at(central,"主人公の記録",Rect2(8,3,530,36),25,GOLD)
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
	var l:=Label.new(); l.text=value; l.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART; l.add_theme_font_size_override("font_size",font_size); l.add_theme_color_override("font_color",color); details.add_child(l); return l
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
		var l:=Label.new(); l.text=value[0]; l.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART; l.add_theme_font_size_override("font_size",value[1]); l.add_theme_color_override("font_color",value[2]); text.add_child(l)
func update_details() -> void:
	clear_children(details)
	var id: String=selection[active_tab]
	if active_tab=="equipment":
		var item:=Model.equipment(game.campaign,game.cfg,id)
		detail_heading(item.name,Icons.texture(id) if not item.empty else Symbols.texture("def"),"装備・"+game.cfg.slots[id])
		if item.empty:
			detail_text("この部位には何も装備していません。",18)
		else:
			detail_text(item.description,17)
			details.add_child(HSeparator.new())
			detail_row("現在の補正",game.item_effects(item.item,item.uid),GOLD)
			detail_row("耐久度","%d / %d"%[item.condition.current,item.condition.maximum])
			detail_row("特殊効果","—")
			detail_row("追加能力","未導入")
			detail_row("刻印","未導入")
		section("装備の変更","装備枠の選択では外れません。変更・修理は、町に戻って「装備・修理」から行えます。")
		detail_text("大切な装備は、町の倉庫や父親の風呂敷へ保管できます。",16,MUTED)
		if id=="head": detail_text("マントも、この頭枠に装備します。",15,MUTED)
	elif active_tab=="abilities":
		detail_heading(Model.STAT_NAMES[id],Symbols.texture({"max_hp":"hp","max_sp":"sp"}.get(id,id)))
		var total: int=unit[id]; var base:=Model.base_value(game.campaign,game.cfg,id)
		detail_row("現在値",str(total),GOLD)
		detail_text(Model.STAT_TEXT[id],18)
		var impacts: Dictionary={"max_hp":"・受け止められるダメージ量","max_sp":"・自動スキルで使えるSPの上限","atk":"・通常攻撃の威力","def":"・受ける攻撃のダメージ軽減","spd":"・戦闘での行動順"}
		section("主な影響",impacts[id])
		detail_row("基礎値",str(base)); detail_row("装備補正","%+d"%(total-base))
	elif active_tab=="conditions":
		var found:=false
		for effect in Model.effects(unit,game.data.rules):
			if effect.id==id:
				detail_heading(effect.name,Symbols.texture(id),"付与中"); detail_text(Model.effect_detail(effect,game.data),18); found=true; break
		if not found:
			if id=="current":
				detail_heading("現在の状態",Symbols.texture("normal"))
				detail_text("状態異常や防御態勢は付与されていません。" if Model.effects(unit,game.data.rules).is_empty() else "各状態を選ぶと、効果と残りの自身行動機会を確認できます。",18)
			else:
				detail_heading(Model.EFFECT_NAMES[id],Symbols.texture(id),"現在は未発動" if id=="defense" else "現在は未付与")
				var descriptions: Dictionary={"poison":"自身の行動機会の開始時にHPを失う状態。ダメージ量は付与時の攻撃力を基に決まります。","blind":"命中率が低下する状態。低下量は発生元の技によって決まります。","paralysis":"自身の行動機会を失う状態。","defense":"防御力を上げる自動スキル。条件を満たしたときに発動します。"}
				detail_text(descriptions[id],18)
				if id=="defense":
					var rule: Dictionary=game.data.rules.skills.S105
					detail_row("消費SP",str(int(rule.sp_cost))); detail_row("防御力","＋%d%%"%roundi(float(rule.def_bonus)*100))
				detail_text("付与中は、残りの自身行動機会と発生元をここで確認できます。",16,MUTED)
		section("属性耐性","火・水・雷・土・風・光・闇・無。属性ごとの耐性は未設定です。")
	else:
		if id=="species":
			detail_heading("主人公",face(),Model.profile().get("species","未設定"))
			detail_text("年齢・出身・職業・人物紹介は未設定です。",18)
		else:
			detail_heading("旅の記録",Symbols.texture("normal"))
			detail_row("到達記録","%d F"%game.campaign.highest_floor); detail_row("通常の探索","%d 回"%E.normal_trips(game.campaign)); detail_row("通常の死亡","%d 回"%E.normal_deaths(game.campaign))
			detail_text("この記録は現在のセーブから表示しています。",17,MUTED)
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
	exit.finished.connect(func(): if is_inside_tree(): game.open_town_page(return_page))
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
	return {"kind":"status","tab":active_tab,"selected":selection[active_tab],"hero":unit.name,"equipment_slots":E.SLOTS.size(),"item_rects":rects,"party_active":1,"party_reserved":5,"gauge_values":gauges,"read_only":true,"detail_scroll_max":detail_scroll.get_v_scroll_bar().max_value}
