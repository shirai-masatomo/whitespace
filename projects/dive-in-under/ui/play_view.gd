extends Control
## Production session UI built from native controls and independent user backgrounds.
const UISkin=preload("res://ui/ui_skin.gd")
const Art=preload("res://ui/visual_assets.gd")
const Items=preload("res://ui/equipment_art.gd")
const Symbols=preload("res://ui/status_symbols.gd")
const Routes=preload("res://ui/route_map.gd")
const E=preload("res://core/expedition.gd")
const TITLE_LOGO=preload("res://assets/title/v1/dive-in-under-logo-gold-deep-shadow.png")
const TITLE_DIM_ALPHA: float=0.12
var game: Control
var mode: String
var stage: Control
var route: Control
var routes_overlay: Control
func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	if mode in ["title","hub","equipment","result"]:
		# These are empty town backgrounds, separately supplied without any UI.
		var bg: Texture2D=preload("res://assets/interface/v2/surface-title.png") if mode=="title" else preload("res://assets/interface/v2/surface-preparation.png")
		var backdrop:=UISkin.picture(self,bg,Rect2(0,0,1280,720),true)
		backdrop.name="TownBackdrop"
		if mode=="title":
			var dimmer:=ColorRect.new(); dimmer.name="TitleBackgroundDimmer"
			dimmer.color=Color(0,0,0,TITLE_DIM_ALPHA); dimmer.size=Vector2(1280,720)
			dimmer.mouse_filter=Control.MOUSE_FILTER_IGNORE; add_child(dimmer)
	match mode:
		"title": build_title()
		"hub": build_hub()
		"equipment": build_equipment()
		"result": build_result()
		_: build_exploration()
func header(title: String) -> void:
	var p:=UISkin.panel(self,Rect2(16,14,1248,60),"",true)
	UISkin.logo(p,Rect2(18,1,162,54))
	UISkin.label(p,title,Rect2(211,12,760,34),25,UISkin.DARK)
	if not game.campaign.is_empty(): UISkin.label(p,"G  %d"%game.campaign.gold,Rect2(1080,13,140,32),21,UISkin.DARK)
func nav(parent: Node, text: String, r: Rect2, call: Callable, key: String="", primary: bool=false) -> Button:
	var b:=UISkin.button(parent,text,r,call,primary)
	if key!="": b.set_meta("nav",key)
	return b
func command(parent: Node, text: String, r: Rect2, action: String, args: Dictionary={}, primary: bool=false) -> Button:
	var revision: int=game.campaign.revision
	var b:=nav(parent,text,r,func(): game.perform(action,args,revision),"",primary)
	b.set_meta("campaign_action",action); b.set_meta("campaign_args",args); game.play_buttons[action]=b
	return b
func hero_card(r: Rect2) -> Control:
	var s: Dictionary=game.campaign
	var h: Dictionary=E.battle_state(s,game.data).hero if s.phase=="battle" else E.hero(s,game.cfg)
	var p:=UISkin.panel(self,r,"主人公  /  Lv.%d"%h.level,true)
	var face:=AtlasTexture.new(); face.atlas=Art.texture("hero"); face.region=Rect2(410,210,390,370)
	UISkin.picture(p,face,Rect2(20,57,72,88))
	var pixels:=17 if r.size.x>300 else 15
	UISkin.label(p,"HP  %d / %d"%[h.hp,h.max_hp],Rect2(108,59,r.size.x-126,27),pixels,UISkin.DARK)
	UISkin.gauge(p,h.hp,h.max_hp,Rect2(108,91,r.size.x-128,11),Color("b83e32"))
	UISkin.label(p,"SP  %d / %d"%[h.sp,h.max_sp],Rect2(108,111,r.size.x-126,27),pixels,UISkin.DARK)
	UISkin.gauge(p,h.sp,h.max_sp,Rect2(108,143,r.size.x-128,11),Color("267fae"))
	var lv:=E.level_info(s,game.cfg)
	UISkin.label(p,"EXP   %d / %d"%[lv.progress,lv.next],Rect2(20,177,r.size.x-40,27),16,UISkin.DARK)
	UISkin.gauge(p,lv.progress,lv.next,Rect2(20,211,r.size.x-40,11),Color("b8862b"))
	UISkin.rule(p,Rect2(20,241,r.size.x-40,1),Color("ac9162"))
	UISkin.label(p,"攻撃 %d   防御 %d   素早さ %d"%[h.atk,h.def,h.spd],Rect2(20,251,r.size.x-40,30),15,UISkin.DARK)
	var state_text: String=game.StatusOverlay.status_text(h)
	UISkin.label(p,state_text if state_text!="" else "状態異常なし",Rect2(20,290,r.size.x-40,36),15,UISkin.DARK,true)
	return p
func build_title() -> void:
	var p:=Control.new(); p.name="TitleMenu"; p.position=Vector2(96,128); p.size=Vector2(620,440); add_child(p)
	var plate:=UISkin.panel(p,Rect2(0,0,620,440)); plate.name="TitleOuterPanel"
	var logo:=UISkin.picture(p,TITLE_LOGO,Rect2(40,8,540,180)); logo.name="TitleLogo"; logo.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR
	preload("res://ui/interface_art.gd").paper(p,Rect2(66,203,488,56))
	var caption:=UISkin.label(p,"支度を整え、まだ見ぬ深みへ。",Rect2(78,215,464,32),22,UISkin.DARK); caption.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	game.new_button=nav(p,"はじめる",Rect2(66,275,488,64),game.request_new,"start",true)
	nav(p,"終了",Rect2(66,355,488,64),func():game.get_tree().quit(),"quit")
	UISkin.label(self,"0.6.4",Rect2(1170,675,85,25),15)
	game.new_button.add_theme_font_size_override("font_size",30); game.new_button.grab_focus()
func build_hub() -> void:
	header("冒険の準備")
	var menu:=UISkin.panel(self,Rect2(72,131,466,548),"次の旅の支度"); menu.self_modulate.a=0.28
	var entries: Array=[["ステータス","status"],["倉庫・所持品","warehouse"],["装備","equipment"]]
	for i in entries.size():
		var page: String=entries[i][1]
		var b:=nav(menu,entries[i][0],Rect2(27,75+i*83,412,66),func():game.open_status() if page=="status" else game.open_town_page(page),page)
		UISkin.quiet_button(b); b.add_theme_font_size_override("font_size",25)
		var icon: Texture2D=Symbols.texture("exp") if page=="status" else (preload("res://ui/interface_symbols.gd").texture("warehouse") if page=="warehouse" else Items.texture("A01"))
		UISkin.picture(b,icon,Rect2(16,12,42,42))
	command(menu,"探索に出発",Rect2(27,331,412,76),"depart",{},true).add_theme_font_size_override("font_size",27)
	nav(menu,"タイトルへ",Rect2(27,435,193,58),game.show_title,"title")
	nav(menu,"終了",Rect2(231,435,208,58),func():game.get_tree().quit(),"quit")
	var card:=hero_card(Rect2(820,131,372,430))
	UISkin.label(card,"装備中のアイテム",Rect2(20,332,332,28),17,UISkin.DARK)
	var index:=0
	for slot in E.SLOTS:
		var uid: String=game.campaign.equipment[slot]
		if uid=="": continue
		UISkin.picture(card,Items.texture(game.campaign.items[uid],slot),Rect2(20+index*58,364,50,50)); index+=1
		if index==5: break
	var note:=UISkin.panel(self,Rect2(570,588,224,91))
	UISkin.label(note,"持ち帰った品を預け、装備を整えよう。",Rect2(17,15,190,65),17,UISkin.INK,true)
func add_stage(r: Rect2, enemy: String="") -> void:
	stage=Control.new(); stage.set_script(game.BattleStage); stage.wide_layout=true; stage.integrated_layout=true
	stage.floor_number=game.campaign.floor; stage.enemy_id=enemy; stage.position=r.position; stage.size=r.size; add_child(stage)
func build_exploration() -> void:
	var s: Dictionary=game.campaign; var battling: bool=s.phase=="battle"
	header("地下 %d F  /  %s"%[s.floor,"自動戦闘" if battling else "探索"])
	var left:=UISkin.panel(self,Rect2(16,86,220,424),"探索")
	var down:=command(left,"さらに潜る",Rect2(14,65,192,62),"descend",{},true); down.disabled=s.phase!="explore"
	var back:=command(left,"帰還する",Rect2(14,140,192,58),"return"); back.disabled=s.phase!="explore"
	nav(left,"地図を開く",Rect2(14,214,192,53),open_routes,"map")
	if battling:
		var speed:=nav(left,"進行  %d倍速"%game.play_speed,Rect2(14,279,192,44),func():game.play_speed=2 if game.play_speed==1 else 1; game.show_campaign(),"speed")
		speed.tooltip_text="戦闘は自動で進みます。"
		var pause:=nav(left,"自動戦闘を停止" if game.auto_play else "戦闘を再開",Rect2(14,334,192,44),func():
			if game.auto_play: game.auto_play=false; game.play_timer.stop(); game.show_campaign()
			else: game.resume_auto_battle(),"pause")
		UISkin.quiet_button(pause,not game.auto_play)
		UISkin.label(left,"動作中" if game.auto_play else "停止中",Rect2(18,381,185,22),16,UISkin.GOLD)
		UISkin.label(left,"Space：自動戦闘停止／再開",Rect2(18,404,190,18),12,UISkin.MUTED)
	elif s.phase=="event":
		command(left,game.cfg.events[s.event].choice,Rect2(14,287,192,53),"event",{"choice":"accept"})
		command(left,"見送る",Rect2(14,349,192,53),"event",{"choice":"skip"})
	else: UISkin.label(left,"灯りの先へ進むか、\n準備へ戻るか。",Rect2(18,298,185,80),18,UISkin.INK,true)
	add_stage(Rect2(248,86,748,421),s.battle.get("enemy_id",""))
	var border:=UISkin.panel(self,Rect2(248,86,748,421)); border.mouse_filter=Control.MOUSE_FILTER_IGNORE; border.ornament_only=true
	if s.phase=="event":
		var event_panel:=UISkin.panel(self,Rect2(276,111,692,91),"",true)
		UISkin.label(event_panel,game.cfg.events[s.event].name,Rect2(24,20,644,45),25,UISkin.DARK)
	if battling:
		var b: Dictionary=E.battle_state(s,game.data)
		var foe:=UISkin.panel(self,Rect2(264,101,287,92))
		UISkin.label(foe,"%s  Lv.%d"%[b.enemy.name,b.enemy.level],Rect2(16,10,255,28),18,UISkin.GOLD)
		UISkin.gauge(foe,b.enemy.hp,b.enemy.max_hp,Rect2(16,45,255,12),Color("b64735"))
		UISkin.label(foe,"HP %d / %d  ・  ROUND %d"%[b.enemy.hp,b.enemy.max_hp,b.round],Rect2(16,61,255,23),14)
		var overlay:=Control.new(); overlay.set_script(game.StatusOverlay); overlay.battle=b
		overlay.effects=b.log.filter(func(x):return x.round==b.round and x.type in ["status_applied","status_damage","action_skipped"])
		stage.add_child(overlay)
	hero_card(Rect2(1008,276,256,428))
	var map_panel:=UISkin.panel(self,Rect2(1008,86,256,178),"階層のつながり")
	route=Control.new(); route.set_script(Routes); route.floor_number=s.floor; route.highest_floor=s.highest_floor; route.position=Vector2(10,52); route.size=Vector2(236,103); map_panel.add_child(route)
	var map_hit:=Button.new(); map_hit.flat=true; map_hit.position=Vector2(8,48); map_hit.size=Vector2(240,112); map_hit.tooltip_text="クリックで全景"; map_hit.pressed.connect(open_routes); map_hit.set_meta("nav","minimap"); map_panel.add_child(map_hit)
	var bag:=UISkin.panel(self,Rect2(16,522,220,182),"持ち物")
	UISkin.label(bag,"%d / 15"%s.inventory.size(),Rect2(20,56,95,25),18)
	UISkin.picture(bag,Symbols.texture("bag"),Rect2(134,52,48,48))
	for i in mini(4,s.inventory.size()):
		var uid: String=s.inventory[i]
		UISkin.picture(bag,Items.texture(s.items[uid],game.cfg.items[s.items[uid]].slot),Rect2(20+i*44,94,40,40))
	UISkin.label(bag,"風呂敷  %d / 3"%s.cloth.size(),Rect2(20,144,180,24),15,UISkin.MUTED)
	var journal:=UISkin.panel(self,Rect2(248,522,748,182),"旅の記録")
	var log:=RichTextLabel.new(); log.position=Vector2(17,51); log.size=Vector2(714,116); log.text="\n".join(s.journal.slice(-8)); log.scroll_following=true; log.add_theme_font_size_override("normal_font_size",17); log.theme=UISkin.scroll_theme(); journal.add_child(log)
	if game.route_map_open: open_routes()
func open_routes() -> void:
	if is_instance_valid(routes_overlay): return
	game.route_map_open=true
	routes_overlay=Control.new(); routes_overlay.z_index=1000; routes_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); add_child(routes_overlay)
	var shade:=ColorRect.new(); shade.color=Color(0,0,0,0.76); shade.size=Vector2(1280,720); routes_overlay.add_child(shade)
	var panel:=UISkin.panel(routes_overlay,Rect2(210,96,860,528),"階層の全景")
	var map:=Control.new(); map.set_script(Routes); map.expanded=true; map.floor_number=game.campaign.floor; map.highest_floor=game.campaign.highest_floor; map.position=Vector2(20,55); map.size=Vector2(820,325); panel.add_child(map)
	UISkin.label(panel,"現在地と、通ってきた道。先の出来事は、まだ分からない。",Rect2(30,385,800,42),18,UISkin.INK,true)
	nav(panel,"閉じる",Rect2(586,445,245,58),close_routes,"close-map")
func close_routes() -> void:
	game.route_map_open=false
	if is_instance_valid(routes_overlay): routes_overlay.queue_free(); routes_overlay=null
func build_result() -> void:
	var s: Dictionary=game.campaign
	var text: String={"return":"帰還","death":"探索を終えた","clear":"10 F 突破","draw":"探索を中断"}.get(s.result.kind,"探索の記録")
	header(text)
	var paper:=UISkin.panel(self,Rect2(90,128,630,516),text,true)
	UISkin.label(paper,s.result.reason,Rect2(30,77,570,96),24,UISkin.DARK,true)
	UISkin.label(paper,"到達  %d F\n主人公  Lv.%d\n所持金  %d G"%[s.result.floor,E.hero(s,game.cfg).level,s.gold],Rect2(30,200,570,132),24,UISkin.DARK,true)
	var loss: Dictionary=s.result.loss
	UISkin.label(paper,"今回の損失   Gold %d / EXP %d / 携行品 %d"%[loss.gold,loss.exp,loss.items],Rect2(30,359,570,48),17,UISkin.DARK,true)
	command(paper,"冒険準備へ戻る",Rect2(31,432,566,58),"town",{},true)
	var journal:=UISkin.panel(self,Rect2(752,128,438,516),"最後の記録")
	UISkin.label(journal,"\n".join(s.journal.slice(-8)),Rect2(25,67,390,410),19,UISkin.INK,true)
func build_equipment() -> void:
	header("装備")
	var bag:=UISkin.panel(self,Rect2(16,92,300,532),"バックパック")
	var sc:=ScrollContainer.new(); sc.position=Vector2(14,55); sc.size=Vector2(272,460); sc.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED; sc.theme=UISkin.scroll_theme(); bag.add_child(sc)
	var list:=VBoxContainer.new(); list.size_flags_horizontal=Control.SIZE_EXPAND_FILL; sc.add_child(list)
	for uid in game.campaign.inventory:
		var item: Dictionary=game.cfg.items[game.campaign.items[uid]]
		var row:=Control.new(); row.custom_minimum_size=Vector2(255,96); list.add_child(row)
		UISkin.picture(row,Items.texture(game.campaign.items[uid],item.slot),Rect2(4,4,44,44))
		UISkin.label(row,item.name,Rect2(54,6,196,33),16)
		var equip:=command(row,"装備する",Rect2(52,47,192,40),"equip",{"uid":uid}); equip.disabled=item.slot==""
	if game.campaign.inventory.is_empty(): UISkin.label(bag,"所持品はありません。",Rect2(22,85,256,50),17,UISkin.MUTED)
	var center:=UISkin.panel(self,Rect2(328,92,554,532),"装備部位")
	for i in E.SLOTS.size():
		var slot: String=E.SLOTS[i]; var uid: String=game.campaign.equipment[slot]
		var x:=17+(i%2)*265; var y:=61+(i/2)*72
		var name: String="装備なし" if uid=="" else game.cfg.items[game.campaign.items[uid]].name
		var b:=nav(center,"",Rect2(x,y,254,64),func():game.equipment_focus=slot;game.show_campaign(),"slot-"+slot,game.equipment_focus==slot)
		UISkin.quiet_button(b,game.equipment_focus==slot)
		var ink: Color=UISkin.DARK if game.equipment_focus==slot else UISkin.INK
		UISkin.label(b,game.cfg.slots[slot],Rect2(54,10,185,20),13,ink); UISkin.label(b,name,Rect2(54,30,185,24),16,ink)
		if uid!="": UISkin.picture(b,Items.texture(game.campaign.items[uid],slot),Rect2(8,12,40,40))
	var details:=UISkin.panel(self,Rect2(894,92,370,532),"装備の詳細",true)
	var selected: String=game.campaign.equipment[game.equipment_focus]
	if selected!="":
		var item: Dictionary=game.cfg.items[game.campaign.items[selected]]
		UISkin.picture(details,Items.texture(game.campaign.items[selected],item.slot),Rect2(26,64,85,85))
		UISkin.label(details,item.name,Rect2(125,73,217,74),22,UISkin.DARK,true)
		UISkin.label(details,game.item_effects(item,selected)+"\n"+game.condition_text(selected),Rect2(26,180,320,88),21,UISkin.DARK,true)
		UISkin.label(details,item.get("description",preload("res://ui/warehouse_catalog.gd").DESCRIPTIONS.get(game.campaign.items[selected],"")),Rect2(26,280,320,105),18,UISkin.DARK,true)
		var remove:=command(details,"装備を外す",Rect2(22,398,326,50),"unequip",{"slot":game.equipment_focus})
		remove.disabled=game.campaign.inventory.size()>=15
		if remove.disabled:
			remove.tooltip_text="バックパックに空きがありません"
			UISkin.label(details,"バックパックに空きがありません",Rect2(22,363,326,28),15,UISkin.DARK)
		var cost:=E.Condition.cost(game.campaign,selected,game.cfg)
		var repair:=command(details,"修理  %d G"%maxi(0,cost),Rect2(22,461,326,50),"repair",{"uid":selected}); repair.disabled=cost<=0 or game.campaign.gold<cost
	else: UISkin.label(details,"この部位には何も装備していません。",Rect2(28,184,314,100),23,UISkin.DARK,true)
	nav(self,"冒険準備へ戻る",Rect2(16,643,300,60),func():game.open_town_page("hub"),"back")
	UISkin.label(self,"所持品から装備し、部位を選んで詳細を確認。",Rect2(349,654,700,37),19)
func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if game.route_map_open: close_routes()
		elif mode=="equipment": game.open_town_page("hub")
		elif mode=="hub": game.show_title()
		get_viewport().set_input_as_handled()
func visual_audit() -> Dictionary:
	return {"kind":"session-ui","screen":mode,"session_only":not game.legacy_persistence_mode,"stage_rect":str(stage.get_global_rect()) if is_instance_valid(stage) else "","route":route.nodes() if is_instance_valid(route) else []}

