extends RefCounted
## Shared presentation only. No inventory, resident traits or work rules are changed.
const Panels=preload("res://game/colony_panels.gd")
const Art=preload("res://game/building_art.gd")
static func text(parent,name,value,rect,font=14):
	var label=Label.new();label.name=name;label.text=value;label.position=rect.position;label.size=rect.size;label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;label.add_theme_font_size_override("font_size",font);label.add_theme_color_override("font_color",Color("354b3d"));parent.add_child(label);return label
static func button(g,parent,id,title,rect,callback):
	g.add_button(parent,id,title,rect,callback);Panels.compact_button(g,g.buttons[id],14);g.buttons[id].size=rect.size
static func icon(kind):
	var id=kind.trim_prefix("place_")
	if id=="mushroom_bed":return preload("res://game/board_art.gd").icon("mushroom")
	if Art.FURNITURE_UI.has(id):return Art.FURNITURE_UI[id]
	if kind.ends_with("_tile"):return Art.TEXTURES.get(Art.floor_path(kind)+("wood_00.png" if kind=="wood_tile" else "base.png"))
	if kind in ["wall","wood_wall","stone_wall"]:return Art.TEXTURES.get(("wall/normal/wood_mask_00.png" if kind=="wood_wall" else Art.material(kind)+"/wall/normal/mask_00.png"))
	if kind in ["door","locked_door"]:return Art.TEXTURES["door/horizontal_leaf_closed_normal.png"]
	return null
static func architect_details(g):
	var p=g.colony_panel
	text(p,"BuildTitle",g.TOOLS.get(g.tool,"建築物を選択").split(" ")[0],Rect2(594,18,282,34),19)
	var d=g.Farm.BUILD.get(g.tool,{})
	var hint="左のカテゴリから建築物を選び、\nマップ上で位置を指定します。"
	if not d.is_empty():
		var resource=d.get("resource","soil");var available=g.world.Jobs.Reservations.available(g.world,resource)
		hint="%s\n\n必要素材：%s ×%d\n利用可能：%d%s\n\n施工時間：%s秒\n\n資材搬入 → 施工"%["壁で囲み、床と扉を整えると家屋になります。" if g.tool in g.world.Buildings.WALLS else "完成予想図を確認して配置します。",{"soil":"土","wood":"木材","stone":"石材"}.get(resource,resource),d.get("cost",0),available,"（資材待ちで予約可能）" if available<d.get("cost",0) else "",str(d.get("seconds",1))]
		if d.has("materials"):
			hint="キノコを育てる1×1の設備\n\n建築：木材8・土4\n利用可能：木材%d・土%d\n\n施工4秒 / 植菌キノコ1\n48時間後にキノコ3個を収穫\n\n建築後に選択 → 栽培"%[g.world.Jobs.Reservations.available(g.world,"wood"),g.world.Jobs.Reservations.available(g.world,"soil")]
	elif g.tool.begins_with("place_"):hint="所持する完成品を設置します。\n\n利用可能：%d\n\n空き場所を指定してください。"%g.world.item_count(g.tool.trim_prefix("place_"))
	text(p,"BuildDescription",hint,Rect2(594,60,282,226),14)
static func resident_tab(g,value):g.resident_tab=value;g.refresh()
static func resident_person(g,key):
	g.neutral();g.selected={"kind":"keeper" if key=="keeper" else "worker","key":key};g.refresh()
static func roles(g,key):g.roles_actor=key;g.select_group(3)
class Status extends Control:
	var game
	var actor
	var last_tick=-1
	var nodes={}
	func _process(_dt):
		if last_tick==game.world.tick:return
		last_tick=game.world.tick
		for id in nodes:
			var row=nodes[id];var value=float(actor.get(id,0));var cap=float(actor.get("max_hp",100)) if id=="hp" else float(actor.get("max_stamina",100)) if id=="stamina" else 100.0
			row[0].max_value=maxf(cap,1);row[0].value=value;row[1].text="%d / %d"%[value,cap]
		var state=actor.get("work_status",actor.get("state","待機"))
		if actor.get("resting",false):state="睡眠・休息中"
		elif actor.has("meal_remaining"):state="食事中"
		get_node("Action").text=state
		get_node("Mood").text=game.world.Resident.REACTIONS.get(actor.get("danger_state","relaxed"),"リラックス")+"\n"+"・".join(actor.get("mood_reasons",["普段の生活"]))
		get_node("Meal").text=game.world.Needs.describe(game.world,actor)
static func resident(g):
	var key=g.selected.get("key","keeper");var a=g.world.workers.get(key,{})
	if a.is_empty():return
	var p=Panels.panel(g,Rect2(16,402,896,340));p.name="ResidentDetails"
	text(p,"Heading","住民詳細",Rect2(14,12,90,30),20)
	var picker=OptionButton.new();picker.name="ResidentPicker";picker.position=Vector2(112,10);picker.size=Vector2(180,32);p.add_child(picker);Panels.compact_button(g,picker)
	var keys=g.world.workers.keys()
	for k in keys:picker.add_item(g.world.PlayerEvents.name_of(g.world,g.world.workers[k]))
	picker.select(keys.find(key));picker.item_selected.connect(func(i):resident_person(g,keys[i]))
	for i in range(4):
		var tab=["ステータス","装備","仕事","履歴"][i];var id="resident_tab_%d"%i
		button(g,p,id,tab,Rect2(306+i*96,10,90,32),resident_tab.bind(g,tab));g.UI.architect_selected(g.buttons[id],g.resident_tab==tab);Panels.compact_button(g,g.buttons[id],14,true)
	# Existing life transition keeps the selected actor and its return location.
	if g.buttons.has("time_tab"):
		var b=g.buttons.time_tab;b.reparent(p);b.position=Vector2(694,10);Panels.compact_button(g,b);b.size=Vector2(84,32)
	button(g,p,"resident_close","閉じる",Rect2(790,10,92,32),g.neutral)
	var portrait=TextureRect.new();portrait.texture=Panels.portrait(g,"keeper");portrait.position=Vector2(20,62);portrait.size=Vector2(72,94);portrait.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;portrait.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;portrait.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST;p.add_child(portrait)
	text(p,"Name",g.world.PlayerEvents.name_of(g.world,a)+"\n"+("牧場主" if key=="keeper" else "住民"),Rect2(104,64,146,76),17)
	text(p,"Traits","特性\n生活：%s\n食欲：%s\n仕事：%s"%[{"early":"朝型","normal":"通常","late":"夜型"}.get(a.get("life_type","normal"),"通常"),g.world.Resident.APPETITE_NAMES.get(a.get("appetite","normal"),"通常"),g.world.Resident.WORK_NAMES.get(a.get("work_trait","normal"),"普通")],Rect2(20,162,230,120),14)
	var status=Status.new();status.name="ResidentStatus";status.game=g;status.actor=a;status.position=Vector2(266,60);status.size=Vector2(610,224);status.mouse_filter=Control.MOUSE_FILTER_IGNORE;p.add_child(status)
	for i in range(5):
		var id=["hp","stamina","satiety","sleepiness","satisfaction"][i]
		text(status,"Name_"+id,["HP","スタミナ","満腹度","眠気","満足度"][i],Rect2(0,i*27,76,25),13)
		var bar=ProgressBar.new();bar.position=Vector2(78,i*27+6);bar.size=Vector2(128,12);bar.show_percentage=false;var background=StyleBoxFlat.new();background.bg_color=Color("c8c1a5");bar.add_theme_stylebox_override("background",background);bar.mouse_filter=Control.MOUSE_FILTER_IGNORE;status.add_child(bar)
		var fill=StyleBoxFlat.new();fill.bg_color=[Color("78a76a"),Color("7298b5"),Color("b5aa64"),Color("b68786"),Color("8ca7a1")][i];bar.add_theme_stylebox_override("fill",fill);bar.size=Vector2(128,12)
		var label=text(status,"Value_"+id,"",Rect2(214,i*27,86,24),13);status.nodes[id]=[bar,label]
	text(status,"Mood","",Rect2(0,146,298,74),14)
	text(status,"ActionHeading","現在の行動",Rect2(320,0,270,25),16)
	text(status,"Action","",Rect2(320,29,270,58),14)
	text(status,"Meal","",Rect2(320,100,270,112),14)
	status.visible=g.resident_tab=="ステータス";status.set_process(status.visible)
	if g.resident_tab=="装備":
		var profile=g.world.HumanCombat.profile(a)
		text(p,"Equipment","武器：%s\n射程 %d / 威力 %d\n\n衣服：%s\n\n装備は備蓄の現物を使用します。"%[profile.name,profile.range,profile.damage,"なし" if a.get("clothing",{}).is_empty() else g.world.Zones.Catalog.title(a.clothing.item_id)],Rect2(282,68,570,160),16)
	elif g.resident_tab=="仕事":
		text(p,"Work","現在の仕事："+a.get("work_status","待機")+"\n\n役割画面で仕事の優先度を変更できます。\n生活画面で時間割と食事優先を設定できます。",Rect2(282,68,570,104),16)
		var auto=CheckBox.new();auto.name="AutoCollect";auto.text="自動収集（指定仕事がないとき）";auto.position=Vector2(282,176);auto.size=Vector2(400,34);auto.button_pressed=a.get("auto_collect",true);auto.toggled.connect(func(value):g.world.Work.Ambient.set_enabled(g.world,a,value));p.add_child(auto);Panels.compact_button(g,auto,14)
		button(g,p,"resident_roles","仕事の優先度",Rect2(282,228,180,34),roles.bind(g,key))
	elif g.resident_tab=="履歴":
		var memories=[]
		for event in a.get("mood_events",{}).values():memories.append("%s（心情 %+d）"%[event.label,event.value])
		text(p,"History","最近の心情\n\n"+("記録はまだありません" if memories.is_empty() else "\n".join(memories)),Rect2(282,68,570,208),15)
	# Reuse existing action callbacks and eligibility, rather than duplicate commands.
	var footer=["keeper_rest","resume_jobs","keeper_book","keeper_draft","wake_worker","coffee","energy_drink"]
	var equipment=["keeper_equip","keeper_unequip","human_clothes"]
	var index=0
	for id in footer+equipment:
		if not g.buttons.has(id):continue
		var b=g.buttons[id];b.visible=(g.resident_tab=="装備") if id in equipment else (g.resident_tab in ["ステータス","仕事"])
		b.reparent(p);Panels.compact_button(g,b,13)
		if b.visible:b.position=Vector2(14+index*124,296);b.size=Vector2(118,32);index+=1
static func tool_art(button,kind):
	var title=button.text;button.text="";button.icon=null
	var image=icon(kind)
	if image!=null:
		# Offline measured alpha bounds: no get_image/readback or runtime crop work.
		var bounds={"cooking_bench":Rect2(2,8,28,15),"carpentry_bench":Rect2(2,8,28,15),"sewing_bench":Rect2(2,7,28,17),"bed":Rect2(16,4,31,56)}
		if bounds.has(kind):
			var atlas=AtlasTexture.new();atlas.atlas=image;atlas.region=bounds[kind];image=atlas
		var art=TextureRect.new();art.name="BuildIcon";art.texture=image;art.position=Vector2(16,9);art.size=Vector2(70,56);art.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;art.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;art.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST;art.mouse_filter=Control.MOUSE_FILTER_IGNORE;button.add_child(art)
	var name_label=Label.new();name_label.name="BuildName";name_label.text=title;name_label.position=Vector2(3,68);name_label.size=Vector2(96,24);name_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;name_label.add_theme_font_size_override("font_size",13);name_label.add_theme_color_override("font_color",Color("354b3d"));name_label.mouse_filter=Control.MOUSE_FILTER_IGNORE;button.add_child(name_label)
