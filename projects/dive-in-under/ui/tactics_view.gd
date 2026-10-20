extends Control
const UISkin=preload("res://ui/ui_skin.gd")
const T=preload("res://core/tactics.gd")
const E=preload("res://core/expedition.gd")
var game: Control
var mode: String="tactics"
var uid: String=""
var source: String="inventory"
var draft: Dictionary={}
var actor: String="hero"
var contents: Control
var message: String=""
const SKILLS=["attack","S101","S102","S103","S104","S105"]
const C_LABELS=["いつでも","HP以下%","SP以上%","自分が毒","敵が強打予告"]
const TARGET_LABELS=["敵前衛","敵後衛","敵全体から1体","自分"]
func text(parent: Control, value: String, rect: Rect2, px: int=16) -> Label:
	return UISkin.label(parent,value,rect,px,UISkin.DARK,true)
func button(parent: Control, value: String, rect: Rect2, callback: Callable, key: String="") -> Button:
	var epoch: int=game.ui_epoch
	var b: Button=UISkin.button(parent,value,rect,func():game.ui_action(callback,epoch)); b.add_theme_font_size_override("font_size",15)
	if key!="": b.set_meta("nav",key)
	return b
func option(parent: Control, names: Array, chosen: int, rect: Rect2, callback: Callable) -> OptionButton:
	var b:=OptionButton.new(); b.position=rect.position; b.size=rect.size; b.add_theme_font_size_override("font_size",14); b.fit_to_longest_item=false; b.clip_text=true; compact(b); parent.add_child(b)
	for name in names: b.add_item(str(name))
	b.select(maxi(0,chosen)); b.get_popup().add_theme_font_size_override("font_size",14); b.item_selected.connect(func(index):callback.call_deferred(index)); return b
func _ready() -> void:
	size=Vector2(1280,720); z_index=1400; game.modal_owner=self; game.primary_button=null; game.secondary_button=null
	draft=T.active(game.campaign.tactics);actor=str(draft.order[0]); rebuild()
func compact(control: Control) -> void:
	for state in ["normal","hover","pressed","focus","disabled"]:
		var box:=StyleBoxFlat.new();box.bg_color=Color("d2bc8b");box.border_color=Color("88714b");box.set_border_width_all(1);box.set_content_margin_all(4)
		control.add_theme_stylebox_override(state,box)
	for color_name in ["font_color","font_hover_color","font_pressed_color","font_focus_color","font_selected_color"]: control.add_theme_color_override(color_name,UISkin.DARK)
func rebuild() -> void:
	if not draft.characters.has(actor): actor=str(draft.order[0])
	if is_instance_valid(contents): remove_child(contents); contents.queue_free()
	contents=Control.new(); contents.size=size; add_child(contents)
	var shade:=ColorRect.new(); shade.color=Color(0,0,0,.78); shade.size=size; contents.add_child(shade)
	var panel: Control=UISkin.panel(contents,Rect2(24,24,1232,672),"部隊の作戦",true)
	var book: Dictionary=game.campaign.tactics; var active: Dictionary=T.active(book)
	text(panel,"適用中："+active.name+" / 切替：次の未実行行動から・消費なし",Rect2(24,48,1184,27),19)
	text(panel,"8作戦・1人8行・AND条件2つ / 起動中だけ保存。終了するとリセット。",Rect2(24,79,1184,26),15)
	for i in book.sets.size():
		var value: Dictionary=book.sets[i]
		button(panel,("★ " if value.favorite else "☆ ")+value.name,Rect2(22,120+i*46,217,39),func():draft=value.duplicate(true);actor=str(draft.order[0]);message="編集中。保存して適用するまで現在の作戦を維持。";call_deferred("rebuild"),"tactics-edit-"+value.id)
	button(panel,"複製して新規",Rect2(22,499,217,36),func():
		if book.sets.size()>=8: message="8個まで保存できます。";call_deferred("rebuild");return
		draft=draft.duplicate(true);draft.id="session-"+str(game.campaign.revision);draft.name+="の写し";message="未保存の新しい作戦";call_deferred("rebuild"),"tactics-new")
	var name_edit:=LineEdit.new();name_edit.text=draft.name;name_edit.max_length=32;name_edit.position=Vector2(260,117);name_edit.size=Vector2(560,36);name_edit.add_theme_font_size_override("font_size",16);compact(name_edit);panel.add_child(name_edit);name_edit.text_changed.connect(func(v):draft.name=v)
	var favorite:=CheckButton.new();favorite.text="お気に入り";favorite.button_pressed=draft.favorite;favorite.position=Vector2(844,118);panel.add_child(favorite);favorite.toggled.connect(func(v):draft.favorite=v)
	var roster: Array=draft.order; var names: Array=[]
	for id in roster: names.append("主人公" if id=="hero" else id)
	option(panel,names,roster.find(actor),Rect2(260,164,230,34),func(i):actor=roster[i];call_deferred("rebuild"))
	button(panel,"順序 ↑",Rect2(505,164,110,34),func():move_actor(-1))
	button(panel,"順序 ↓",Rect2(625,164,110,34),func():move_actor(1))
	option(panel,["前衛","後衛"],0 if draft.characters[actor].rank=="front" else 1,Rect2(750,164,150,34),func(i):draft.characters[actor].rank="front" if i==0 else "back")
	text(panel,"行動順："+" → ".join(names),Rect2(260,203,920,25),15)
	for heading in [["技能",260],["条件1・割合",420],["条件2・割合",630],["対象",842],["優先順",1005]]: text(panel,heading[0],Rect2(heading[1],235,180,25),15)
	var rows: Array=draft.characters[actor].rows
	var unit: Dictionary=game.campaign.battle.get("current",{}).get("units",{}).get(actor,E.hero(game.campaign,game.cfg))
	for i in rows.size():
		var row: Dictionary=rows[i]; var y: int=267+i*36
		var labels: Array=[]
		for id in SKILLS: labels.append(("通常攻撃" if id=="attack" else game.data.rules.skills[id].name)+("・未習得" if id!="attack" and id not in unit.skills else ""))
		option(panel,labels,SKILLS.find(row.skill),Rect2(260,y,150,31),func(n):row.skill=SKILLS[n];row.target="self" if row.skill=="S105" else "enemy_front";call_deferred("rebuild"))
		while row.conditions.size()<2: row.conditions.append({"kind":"always","value":50})
		for j in 2:
			var c: Dictionary=row.conditions[j];var x: int=420+j*210
			option(panel,C_LABELS,T.CONDITIONS.find(c.kind),Rect2(x,y,140,31),func(n):c.kind=T.CONDITIONS[n];call_deferred("rebuild"))
			var number:=SpinBox.new();number.min_value=0;number.max_value=100;number.value=c.get("value",50);number.position=Vector2(x+144,y);number.size=Vector2(60,31);number.add_theme_font_size_override("font_size",13);number.get_line_edit().add_theme_font_size_override("font_size",13);compact(number.get_line_edit());panel.add_child(number);number.value_changed.connect(func(v):c.value=int(v));number.visible=c.kind in ["hp_below","sp_above"]
		option(panel,TARGET_LABELS,T.TARGETS.find(row.target),Rect2(842,y,155,31),func(n):row.target=T.TARGETS[n])
		button(panel,"↑",Rect2(1005,y,50,31),func():move_row(i,-1))
		button(panel,"↓",Rect2(1060,y,50,31),func():move_row(i,1))
		button(panel,"×",Rect2(1115,y,50,31),func():rows.remove_at(i);call_deferred("rebuild"))
	var add: Button=button(panel,"行を追加",Rect2(260,563,160,34),func():rows.append({"skill":"attack","conditions":[{"kind":"always","value":50}],"target":"enemy_front"});call_deferred("rebuild"));add.disabled=rows.size()>=8
	button(panel,"保存",Rect2(430,563,160,34),func():commit(false),"tactics-save")
	button(panel,"保存して適用",Rect2(600,563,210,34),func():commit(true),"tactics-apply")
	button(panel,"閉じる［Esc］",Rect2(900,563,267,34),cancel_modal,"tactics-close")
	text(panel,message if message!="" else ("設定順に実行可能な行を判定。全行不成立なら通常攻撃、対象不在なら待機。"),Rect2(22,606,1188,25),14)
	var decision: String=T.reasons_text(unit)
	text(panel,decision,Rect2(22,638,1188,29),12)
func commit(apply: bool) -> void:
	var reason: String=T.validate(draft)
	if reason!="":message=reason;call_deferred("rebuild");return
	game.call_deferred("perform","tactic_save",{"value":draft.duplicate(true),"apply":apply},int(game.campaign.revision))
func move_row(index: int, delta: int) -> void:
	var rows: Array=draft.characters[actor].rows;var to: int=clampi(index+delta,0,rows.size()-1)
	var row: Dictionary=rows[index];rows.remove_at(index);rows.insert(to,row);call_deferred("rebuild")
func move_actor(delta: int) -> void:
	var order: Array=draft.order;var at: int=order.find(actor);var to: int=clampi(at+delta,0,order.size()-1)
	order.remove_at(at);order.insert(to,actor);call_deferred("rebuild")
func cancel_modal() -> void:
	game.service_mode="";game.modal_owner=null;game.ui_block_until=Time.get_ticks_msec()+360;game.call_deferred("show_campaign")
func modal_key(code: int, _backwards: bool=false) -> void:
	if code in [KEY_ESCAPE,KEY_X]:call_deferred("cancel_modal")
func allows_native_key(code: int) -> bool:
	if code in [KEY_ESCAPE,KEY_X]: return false
	return code not in [KEY_C,KEY_I,KEY_E] or get_viewport().gui_get_focus_owner() is LineEdit
