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
var vitals: Dictionary={}
func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	if mode in ["title","hub","equipment","result"] and (mode!="equipment" or game.campaign.phase=="town"):
		# These are empty town backgrounds, separately supplied without any UI.
		var bg: Texture2D=preload("res://assets/interface/v2/surface-title.png") if mode=="title" else preload("res://assets/interface/v2/surface-preparation.png")
		var backdrop:=UISkin.picture(self,bg,Rect2(0,0,1280,720),true)
		backdrop.name="TownBackdrop"
		if mode=="title":
			var dimmer:=ColorRect.new(); dimmer.name="TitleBackgroundDimmer"
			dimmer.color=Color(0,0,0,TITLE_DIM_ALPHA); dimmer.size=Vector2(1280,720)
			dimmer.mouse_filter=Control.MOUSE_FILTER_IGNORE; add_child(dimmer)
	if mode=="equipment" and game.campaign.phase!="town": UISkin.picture(self,Art.texture("cavern"),Rect2(0,0,1280,720),true)
	match mode:
		"title": build_title()
		"hub": build_hub()
		"equipment": build_equipment()
		"result": build_result()
		"exploration","explore","battle","treasure","reward","event","event_result","portal","portal_done":
			var view:=Control.new(); view.set_script(preload("res://ui/flow_view.gd")); view.game=game; stage=null; add_child(view); stage=view.stage; route=view.route
		_: build_exploration()
func header(title: String) -> void:
	var p:=UISkin.panel(self,Rect2(16,14,1248,60),"",true)
	UISkin.label(p,title,Rect2(28,12,1000,34),25,UISkin.DARK)
	if not game.campaign.is_empty(): UISkin.label(p,"G  %d"%E.money(game.campaign),Rect2(1080,13,140,32),21,UISkin.DARK)
func nav(parent: Node, text: String, r: Rect2, call: Callable, key: String="", primary: bool=false) -> Button:
	var epoch: int=game.ui_epoch
	var b:=UISkin.button(parent,text,r,func():game.ui_action(call,epoch),primary)
	if primary: game.set_primary(b)
	if key!="": b.set_meta("nav",key)
	return b
func command(parent: Node, text: String, r: Rect2, action: String, args: Dictionary={}, primary: bool=false) -> Button:
	var revision: int=game.campaign.revision
	var b:=nav(parent,text,r,func():game.perform(action,args,revision),"",primary)
	b.set_meta("campaign_action",action); b.set_meta("campaign_args",args); game.play_buttons[action]=b
	return b
func hero_card(r: Rect2) -> Control:
	var s: Dictionary=game.campaign
	var h: Dictionary=game.display_battle().hero if s.phase=="battle" or game.presenting else E.hero(s,game.cfg)
	var p:=UISkin.panel(self,r,"主人公  /  Lv.%d"%h.level,true)
	var face:=AtlasTexture.new(); face.atlas=Art.texture("hero"); face.region=Rect2(410,210,390,370)
	UISkin.picture(p,face,Rect2(20,57,72,88))
	var pixels:=17
	vitals.hero_hp=UISkin.label(p,"HP  %d / %d"%[h.hp,h.max_hp],Rect2(108,59,r.size.x-126,27),pixels,UISkin.DARK)
	vitals.hero_bar=UISkin.gauge(p,h.hp,h.max_hp,Rect2(108,91,r.size.x-128,11),Color("b83e32"))
	vitals.hero_sp=UISkin.label(p,"SP  %d / %d"%[h.sp,h.max_sp],Rect2(108,111,r.size.x-126,27),pixels,UISkin.DARK)
	vitals.hero_sp_bar=UISkin.gauge(p,h.sp,h.max_sp,Rect2(108,143,r.size.x-128,11),Color("267fae"))
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
	UISkin.label(self,str(ProjectSettings.get_setting("application/config/version")),Rect2(1170,675,85,25),15)
	session_notice()
	if game.debug_run:UISkin.label(self,"デバッグ中 / 通常セッションと別起動",Rect2(770,632,470,36),18,UISkin.GOLD)
	game.new_button.add_theme_font_size_override("font_size",30); game.new_button.grab_focus()
func session_notice() -> void:
	var backing:=ColorRect.new(); backing.position=Vector2(65,680); backing.size=Vector2(1068,30); backing.color=Color(.015,.04,.055,.91); backing.mouse_filter=Control.MOUSE_FILTER_IGNORE; add_child(backing)
	UISkin.label(self,"終了すると、この起動中の進行はリセットされます。保存は行いません。",Rect2(78,683,1040,25),15)
func build_hub() -> void:
	header("冒険の準備")
	session_notice()
	var menu:=UISkin.panel(self,Rect2(72,131,466,548),"次の旅の支度"); menu.self_modulate.a=0.28
	var entries: Array=[["ステータス","status"],["倉庫・所持品","warehouse"],["装備","equipment"]]
	for i in entries.size():
		var page: String=entries[i][1]
		var b:=nav(menu,entries[i][0],Rect2(27,75+i*83,412,66),func():game.open_status() if page=="status" else game.open_town_page(page),page)
		UISkin.quiet_button(b); b.add_theme_font_size_override("font_size",25)
		var icon: Texture2D=Symbols.texture("exp") if page=="status" else (preload("res://ui/interface_symbols.gd").texture("warehouse") if page=="warehouse" else Items.texture("A01"))
		UISkin.picture(b,icon,Rect2(16,12,42,42))
	command(menu,"探索に出発［E］",Rect2(27,331,412,76),"depart",{},true).add_theme_font_size_override("font_size",27)
	nav(menu,"タイトルへ",Rect2(27,435,193,58),game.show_title,"title")
	nav(menu,"終了",Rect2(231,435,208,58),func():game.get_tree().quit(),"quit")
	nav(self,"支給所・個体・印・自動対策",Rect2(560,585,620,58),func():game.open_services(),"services")
	if game.debug_run:nav(self,"デバッグ操作",Rect2(560,80,620,40),func():game.open_services("debug"),"debug-services")
	var card:=hero_card(Rect2(820,131,372,430))
	UISkin.label(card,"装備中のアイテム",Rect2(20,332,332,28),17,UISkin.DARK)
	var index:=0
	for slot in E.SLOTS:
		var uid: String=game.campaign.equipment[slot]
		if uid=="": continue
		UISkin.picture(card,Items.texture(game.campaign.items[uid],slot),Rect2(20+index*58,364,50,50)); index+=1
		if index==5: break
	var warning:=ColorRect.new(); warning.position=Vector2(560,649); warning.size=Vector2(632,28); warning.color=Color(.015,.04,.055,.94); warning.mouse_filter=Control.MOUSE_FILTER_IGNORE; add_child(warning)
	UISkin.label(self,"5Fごとに帰還 / 死亡：装備・バッグ全損、風呂敷・倉庫・成長は保持",Rect2(570,651,612,25),14,UISkin.INK)
func add_stage(r: Rect2, enemy: String="") -> void:
	stage=Control.new(); stage.set_script(game.BattleStage); stage.wide_layout=true; stage.integrated_layout=true
	stage.floor_number=game.campaign.floor; stage.enemy_id=enemy; stage.background_override=E.Journey.node(game.cfg,int(game.campaign.floor),game.campaign).get("background","") if E.Journey.active(game.campaign) else ""; stage.position=r.position; stage.size=r.size; add_child(stage)
func build_exploration() -> void:
	var s: Dictionary=game.campaign; var battling: bool=s.phase=="battle" or game.presenting
	header("地下 %d F  /  %s"%[s.floor,"自動戦闘" if battling else "探索"])
	var left:=UISkin.panel(self,Rect2(16,86,220,424),"探索")
	var down:=command(left,"さらに潜る",Rect2(14,65,192,62),"descend",{},true); down.disabled=s.phase!="explore"
	var back:=command(left,"帰還する",Rect2(14,140,192,58),"return"); back.disabled=s.phase!="explore"
	nav(left,"地図を開く",Rect2(14,214,192,53),open_routes,"map")
	if battling:
		var speed:=nav(left,"進行  %d倍速"%game.play_speed,Rect2(14,274,192,40),func():game.play_speed=2 if game.play_speed==1 else 1; game.cancel_presentation(); game.show_campaign(),"speed")
		speed.tooltip_text="戦闘は自動で進みます。"
		var pause:=nav(left,"自動戦闘を停止" if game.auto_play else "戦闘を再開",Rect2(14,323,192,42),func():
			if game.auto_play: game.auto_play=false; game.play_timer.stop(); game.cancel_presentation(); game.show_campaign()
			else: game.resume_auto_battle(),"pause")
		UISkin.quiet_button(pause,not game.auto_play)
		UISkin.label(left,"自動戦闘：動作中" if game.auto_play else "自動戦闘：停止中",Rect2(18,369,185,22),16,UISkin.GOLD)
		UISkin.label(left,"Space：停止／再開",Rect2(24,392,178,22),14,UISkin.MUTED)
	elif s.phase=="event":
		command(left,game.cfg.events[s.event].choice,Rect2(14,287,192,53),"event",{"choice":"accept"})
		command(left,"見送る",Rect2(14,349,192,53),"event",{"choice":"skip"})
	else: UISkin.label(left,"拾った品は [E] で比較・交換。",Rect2(18,346,185,74),17,UISkin.INK,true)
	if not battling and s.phase=="explore": nav(left,"所持品・装備 [I]",Rect2(14,279,192,51),game.open_field_equipment,"field-equipment").add_theme_font_size_override("font_size",16)
	add_stage(Rect2(248,86,748,421),game.display_battle().enemy.id if battling else "")
	var border:=UISkin.panel(self,Rect2(248,86,748,421)); border.mouse_filter=Control.MOUSE_FILTER_IGNORE; border.ornament_only=true
	if s.phase=="event":
		var event_panel:=UISkin.panel(self,Rect2(276,111,692,91),"",true)
		UISkin.label(event_panel,game.cfg.events[s.event].name,Rect2(24,20,644,45),25,UISkin.DARK)
	if battling:
		var b: Dictionary=game.display_battle()
		var foe:=UISkin.panel(self,Rect2(264,101,287,92))
		UISkin.label(foe,"%s  Lv.%d"%[b.enemy.name,b.enemy.level],Rect2(16,10,255,28),18,UISkin.GOLD)
		vitals.enemy_bar=UISkin.gauge(foe,b.enemy.hp,b.enemy.max_hp,Rect2(16,45,255,12),Color("b64735"))
		vitals.enemy_hp=UISkin.label(foe,"HP %d / %d  ・  ROUND %d"%[b.enemy.hp,b.enemy.max_hp,b.round],Rect2(16,61,255,23),14)
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
	var log:=RichTextLabel.new(); log.position=Vector2(17,51); log.size=Vector2(714,116); log.text="\n".join((game.presentation_journal if game.presenting else s.journal).slice(-8)); log.scroll_following=true; log.add_theme_font_size_override("normal_font_size",17); log.theme=UISkin.scroll_theme(); journal.add_child(log)
	if game.intro_active and battling:
		var intro:=UISkin.panel(stage,Rect2(310,25,418,75),"",true)
		intro.z_index=980
		var label:=UISkin.label(intro,("10Fの門番\n" if s.floor==10 else "遭遇\n")+game.display_battle().enemy.name,Rect2(12,6,394,63),23,UISkin.DARK,true); label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
		intro.modulate.a=0; intro.create_tween().tween_property(intro,"modulate:a",1.0,0.12)
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
	if E.Adventure.active(game.campaign):build_adventure_result();return
	var s: Dictionary=game.campaign
	var text: String={"return":"帰還","death":"探索を終えた","clear":"10 F 突破","draw":"探索を中断"}.get(s.result.kind,"探索の記録")
	header(text)
	var paper:=UISkin.panel(self,Rect2(90,128,630,516),text,true)
	UISkin.label(paper,s.result.reason,Rect2(30,77,570,96),24,UISkin.DARK,true)
	UISkin.label(paper,"到達  %d F\n主人公  Lv.%d\n所持金  %d G"%[s.result.floor,E.hero(s,game.cfg).level,E.money(s)],Rect2(30,200,570,132),24,UISkin.DARK,true)
	if E.Journey.active(s): UISkin.label(paper,"今回の獲得  EXP +%d / Gold +%d / 品物 %d点"%[s.trip_exp,s.trip_gold,s.trip_items],Rect2(30,327,570,30),17,UISkin.DARK)
	var loss: Dictionary=s.result.loss
	UISkin.label(paper,"今回の損失   Gold %d / EXP %d / 携行品 %d"%[loss.gold,loss.exp,loss.items],Rect2(30,359,570,48),17,UISkin.DARK,true)
	command(paper,"冒険準備へ戻る",Rect2(31,432,566,58),"town",{},true)
	var journal:=UISkin.panel(self,Rect2(752,128,438,516),"最後の記録")
	UISkin.label(journal,"\n".join(s.journal.slice(-8)),Rect2(25,67,390,410),19,UISkin.INK,true)
func build_equipment() -> void:
	header("装備")
	var bag:=UISkin.panel(self,Rect2(16,92,300,532),"所持品  %d / 15"%game.campaign.inventory.size())
	preload("res://ui/item_grid.gd").bag(bag,game,self,Vector2(25,66),3,80)
	var center:=UISkin.panel(self,Rect2(328,92,554,532),"装備 / 11部位")
	UISkin.picture(center,Art.texture("cavern"),Rect2(94,53,366,449),true).modulate=Color(.57,.67,.68)
	UISkin.picture(center,Art.actor_texture("hero"),Rect2(100,142,354,350))
	for c in 2:
		var slots: Array=[["head","body","right_hand","legs","feet"],["neck","ears","eyes","left_hand","wrist","finger"]][c]
		for i in slots.size():
			var slot: String=slots[i]
			preload("res://ui/item_grid.gd").cell(center,game,self,Rect2(472 if c==1 else 14,65+i*68,68,64),"equipment",game.campaign.equipment[slot],slot,game.equipment_focus==slot)
	var instructions:=ColorRect.new(); instructions.position=Vector2(94,56); instructions.size=Vector2(366,76); instructions.color=Color(.015,.04,.055,.94); instructions.mouse_filter=Control.MOUSE_FILTER_IGNORE; center.add_child(instructions)
	UISkin.label(center,"ダブルクリックで交換 / 部位へドラッグ\n装備をバックパックへドラッグで解除",Rect2(107,66,340,56),15,UISkin.INK,true)
	var details:=UISkin.panel(self,Rect2(894,92,370,532),"装備の詳細",true)
	var equipped: String=game.campaign.equipment[game.equipment_focus]
	var selected: String=game.equipment_candidate if game.equipment_candidate in game.campaign.inventory else equipped
	if selected!="":
		var item: Dictionary=game.cfg.items[game.campaign.items[selected]]
		UISkin.picture(details,Items.texture(game.campaign.items[selected],item.slot),Rect2(26,64,85,85))
		UISkin.label(details,item.name,Rect2(125,73,217,74),22,UISkin.DARK,true)
		UISkin.label(details,preload("res://ui/item_presenter.gd").performance(game.campaign,game.cfg,selected)+"\n"+game.condition_text(selected),Rect2(26,180,320,88),18,UISkin.DARK,true)
		if game.equipment_candidate=="":
			UISkin.label(details,item.get("description",preload("res://ui/warehouse_catalog.gd").DESCRIPTIONS.get(game.campaign.items[selected],"")),Rect2(26,280,320,54) if game.equipment_candidate=="" else Rect2(26,360,320,0),18,UISkin.DARK,true)

		var candidate: bool=selected!=equipped and item.slot!=""
		if candidate: UISkin.label(details,"現在："+(game.cfg.items[game.campaign.items[equipped]].name if equipped!="" else "未装備"),Rect2(26,149,320,28),15,UISkin.DARK)
		if candidate:
			var preview: Dictionary=E.act(game.campaign,"equip",int(game.campaign.revision),{"uid":selected},game.data,game.cfg)
			var before: Dictionary=E.hero(game.campaign,game.cfg); var after: Dictionary=E.hero(preview,game.cfg)
			UISkin.label(details,"現在 → 交換後   /   増減",Rect2(24,270,322,24),15,UISkin.DARK)
			var rows: Array=preload("res://ui/item_presenter.gd").comparison(before,after)
			for i in rows.size():
				var row: Dictionary=rows[i]
				UISkin.label(details,"%s   %d → %d   (%+d)"%[row.name,row.before,row.after,row.delta],Rect2(26,296+i*18,320,20),15,UISkin.DARK)

		var remove:=command(details,"この装備へ交換" if candidate else "装備を外す",Rect2(22,398,326,50),"equip" if candidate else "unequip",{"uid":selected} if candidate else {"slot":game.equipment_focus})
		remove.disabled=item.slot=="" or (not candidate and game.campaign.inventory.size()>=15)
		if remove.disabled and item.slot!="":
			remove.tooltip_text="バックパックに空きがありません"
			UISkin.label(details,"バックパックに空きがありません",Rect2(22,363,326,28),15,UISkin.DARK)
		if not candidate and E.Condition.cost(game.campaign,selected,game.cfg)>0:
			UISkin.label(details,preload("res://ui/item_presenter.gd").repair_delta(game.campaign,game.cfg,selected),Rect2(26,338,320,48),14,UISkin.DARK,true)
		var cost:=E.Condition.cost(game.campaign,selected,game.cfg)
		var reason: String=preload("res://ui/item_presenter.gd").repair_reason(game.campaign,game.cfg,selected)
		var repair:=command(details,reason if reason!="" else "修理  %d G"%cost,Rect2(22,461,326,50),"repair",{"uid":selected}); repair.disabled=reason!=""
		repair.tooltip_text=(reason+"\n" if reason!="" else "")+preload("res://ui/item_presenter.gd").repair_delta(game.campaign,game.cfg,selected)
	else: UISkin.label(details,"この部位には何も装備していません。",Rect2(28,184,314,100),23,UISkin.DARK,true)
	nav(self,"冒険準備へ戻る" if game.campaign.phase=="town" else "探索へ戻る",Rect2(16,643,300,60),func():game.open_town_page("hub") if game.campaign.phase=="town" else game.close_equipment(),"back")
	nav(self,"個体・印・自動対策",Rect2(328,590,554,32),func():game.open_services("prepare",selected),"equipment-services").add_theme_font_size_override("font_size",15)
	var backing:=ColorRect.new(); backing.position=Vector2(328,643); backing.size=Vector2(936,60); backing.color=Color(.015,.04,.055,.94); backing.mouse_filter=Control.MOUSE_FILTER_IGNORE; add_child(backing)
	var effective: Dictionary=E.hero(game.campaign,game.cfg)
	UISkin.label(self,"現在の能力  攻撃 %d / 防御 %d / 素早さ %d / HP %d/%d / SP %d/%d"%[effective.atk,effective.def,effective.spd,effective.hp,effective.max_hp,effective.sp,effective.max_sp],Rect2(339,654,920,37),17)
func refresh_vitals() -> void:
	if game.display_battle().is_empty(): return
	for child in get_children():
		if child.has_method("refresh_live"): child.refresh_live()
	var b: Dictionary=game.display_battle()
	if vitals.has("hero_hp"):
		vitals.hero_hp.text="HP  %d / %d"%[b.hero.hp,b.hero.max_hp]; vitals.hero_bar.value=b.hero.hp
		vitals.hero_sp.text="SP  %d / %d"%[b.hero.sp,b.hero.max_sp]; vitals.hero_sp_bar.value=b.hero.sp
	if vitals.has("enemy_hp"):
		vitals.enemy_hp.text="HP %d / %d  ・  ROUND %d"%[b.enemy.hp,b.enemy.max_hp,b.round]; vitals.enemy_bar.value=b.enemy.hp
func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		# Keep the receiving Control alive until the viewport finishes dispatching this key.
		if game.route_map_open: call_deferred("close_routes")
		elif mode=="equipment":
			if game.campaign.phase=="town": game.call_deferred("open_town_page","hub")
			else: game.call_deferred("close_equipment")
		elif mode=="hub": game.call_deferred("show_title")
func visual_audit() -> Dictionary:
	return {"kind":"session-ui","screen":mode,"session_only":not game.legacy_persistence_mode,"stage_rect":str(stage.get_global_rect()) if is_instance_valid(stage) else "","route":route.nodes() if is_instance_valid(route) else []}


func select_item(source: String, uid: String, slot: String="") -> void:
	if uid=="" and slot=="": return
	game.flow_selection={"kind":source,"uid":uid,"slot":slot}
	game.equipment_candidate=uid if source=="inventory" else ""
	if slot!="": game.equipment_focus=slot
	elif uid!="" and game.cfg.items[game.campaign.items[uid]].slot!="": game.equipment_focus=game.cfg.items[game.campaign.items[uid]].slot
	game.call_deferred("show_campaign")
func activate_item(source: String, uid: String, slot: String="") -> void:
	if uid=="" or source!="inventory": return
	preload("res://ui/gear_actions.gd").apply(game,preload("res://ui/gear_actions.gd").payload(game,source,uid,slot),"equipment")
func show_drag_reason(text: String) -> void:
	tooltip_text=text
func accepts_gear(value: Variant, destination: String, slot: String="") -> bool:
	return preload("res://ui/gear_actions.gd").reason(game,value,destination,slot)==""
func drop_gear(value: Dictionary, destination: String, slot: String="") -> void:
	preload("res://ui/gear_actions.gd").apply(game,value,destination,slot)

func build_adventure_result() -> void:
	var s: Dictionary=game.campaign
	header("探索結果 / "+{"return":"帰還","death":"死亡","clear":"10F突破","draw":"探索中断"}.get(s.result.kind,"結果"))
	var p:=UISkin.panel(self,Rect2(36,102,1208,510),s.result.reason,true)
	UISkin.label(p,"到達%dF / Lv.%d / 累積EXP %d / バッグのコイン%dG"%[s.result.floor,E.hero(s,game.cfg).level,s.exp,E.money(s)],Rect2(24,61,1160,48),23,UISkin.DARK)
	for i in 2:
		var title: String="失ったもの" if i==0 else "保持したもの"
		UISkin.label(p,title,Rect2(28+i*584,123,550,38),22,UISkin.DARK)
		var scroll:=ScrollContainer.new();scroll.position=Vector2(28+i*584,171);scroll.size=Vector2(550,285);scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;scroll.theme=UISkin.scroll_theme();p.add_child(scroll)
		var lines: Array=s.result.get("lost" if i==0 else "kept",[])
		var label:=Label.new();label.text="\n".join(lines) if not lines.is_empty() else "なし";label.language="ja";label.autowrap_mode=TextServer.AUTOWRAP_WORD;label.size_flags_horizontal=Control.SIZE_EXPAND_FILL;label.add_theme_font_size_override("font_size",19);label.add_theme_color_override("font_color",UISkin.DARK);scroll.add_child(label)
	command(self,"冒険準備へ戻る［E］",Rect2(36,633,1208,66),"town",{},true)
