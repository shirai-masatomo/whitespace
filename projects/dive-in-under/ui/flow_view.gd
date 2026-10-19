extends Control
## One stable dungeon shell; only the central situation and detail body change.
const E=preload("res://core/expedition.gd")
const UISkin=preload("res://ui/ui_skin.gd")
const Art=preload("res://ui/visual_assets.gd")
const Items=preload("res://ui/equipment_art.gd")
const Grid=preload("res://ui/item_grid.gd")
const Gear=preload("res://ui/gear_actions.gd")
const Routes=preload("res://ui/route_map.gd")
const Model=preload("res://ui/status_model.gd")
var game: Control
var stage: Control
var route: Control
var center: Control
var detail: Control
var routes_overlay: Control
var map_primary: Button
var battle: Dictionary={}
var actor_huds: Dictionary={}
var hero_hp: Label
var hero_bar: Control
var hero_sp: Label
var detail_body: Control
var choice_buttons: Dictionary={}
var choice_confirm: Button
var drag_hint: Label
func nav(parent: Control, text: String, rect: Rect2, callback: Callable, key: String="", primary: bool=false) -> Button:
	var epoch: int=game.ui_epoch
	var b:=UISkin.button(parent,text,rect,func():game.ui_action(callback,epoch),primary)
	if key!="": b.set_meta("nav",key)
	if primary: game.set_primary(b)
	return b
func action(parent: Control, text: String, rect: Rect2, name: String, args: Dictionary={}, primary: bool=false) -> Button:
	var revision: int=game.campaign.revision
	var b:=nav(parent,text,rect,func():game.perform(name,args,revision),"",primary)
	b.set_meta("campaign_action",name); b.set_meta("campaign_args",args); game.play_buttons[name]=b
	return b
func label_at(parent: Control, text: String, r: Rect2, px: int=18, paper: bool=false) -> Label:
	return UISkin.label(parent,text,r,px,UISkin.DARK if paper else UISkin.INK,true)
func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var s: Dictionary=game.campaign
	var node: Dictionary=E.Journey.node(game.cfg,int(s.floor))
	battle=game.display_battle() if s.phase=="battle" or game.presenting else {}
	UISkin.picture(self,Art.background_texture(node.get("background","cavern")),Rect2(0,0,1280,720),true).modulate=Color(.46,.55,.58)
	var head:=UISkin.panel(self,Rect2(16,14,1248,60),"",true)
	var phase: String="battle" if not battle.is_empty() else s.phase
	label_at(head,"地下 %d F  /  %s  /  %s"%[s.floor,Art.depth_name(s.floor),{"battle":"自動戦闘","explore":"探索","treasure":"宝箱を発見","reward":"獲得品","event":"道中の出来事","event_result":"選択の結果"}.get(phase,"探索")],Rect2(26,10,1010,38),24,true)
	label_at(head,"G  %d"%s.gold,Rect2(1080,13,140,30),20,true)
	build_left(); build_map()
	detail=UISkin.panel(self,Rect2(982,358,282,346),"詳細",true)
	if not battle.is_empty() or phase=="explore": build_field()
	else:
		center=UISkin.panel(self,Rect2(252,86,718,618),{"treasure":"古い宝箱","reward":s.reward_origin,"event":game.cfg.events.get(s.event,{}).get("name","出来事"),"event_result":s.event_result.get("title","選択の結果")}.get(phase,""),true)
		if phase=="treasure": build_chest()
		elif phase=="reward": build_rewards()
		else: build_event()
	refresh_details()
	if game.route_map_open: open_routes()
	if game.reward_confirmation!="" and phase=="reward": confirmation()
func build_left() -> void:
	var s: Dictionary=game.campaign
	var p:=UISkin.panel(self,Rect2(16,86,224,266),"探索操作")
	var descend:=action(p,"さらに潜る［E］",Rect2(14,54,196,49),"advance_ready",{},s.phase=="explore" and not game.presenting)
	descend.disabled=s.phase!="explore" or game.presenting
	descend.tooltip_text="この出来事を確認してから進めます。" if s.phase!="battle" else "戦闘中は進めません。"
	var gear:=nav(p,"所持品・装備［I］",Rect2(14,112,196,42),game.open_field_equipment,"field-equipment"); gear.disabled=not battle.is_empty(); gear.tooltip_text="戦闘中は装備を変更できません。" if gear.disabled else "比較・ダブルクリック・ドラッグで装備交換"
	nav(p,"ステータス［C］",Rect2(14,164,196,42),game.open_status,"field-status")
	var back:=action(p,"町へ帰還",Rect2(14,216,196,42),"return"); back.disabled=s.phase!="explore" or game.presenting; back.tooltip_text="未受領品や出来事を確認してから帰還できます。"
	var hero: Dictionary=battle.hero if not battle.is_empty() else E.hero(s,game.cfg)
	var card:=UISkin.panel(self,Rect2(16,364,224,84),"")
	var pick:=Button.new(); pick.flat=true; pick.size=Vector2(224,84); pick.mouse_default_cursor_shape=CURSOR_POINTING_HAND; card.add_child(pick); pick.pressed.connect(func():select_actor("hero")); pick.set_meta("actor_select","hero")
	label_at(card,"主人公  Lv.%d"%hero.level,Rect2(16,8,192,24),17)
	hero_hp=label_at(card,"HP %d / %d"%[hero.hp,hero.max_hp],Rect2(16,28,192,22),17)
	hero_bar=UISkin.gauge(card,hero.hp,hero.max_hp,Rect2(16,52,192,8),Color("b83e32"))
	hero_sp=label_at(card,"SP %d / %d"%[hero.sp,hero.max_sp],Rect2(16,62,192,20),14)
	var bag:=UISkin.panel(self,Rect2(16,460,224,244),"所持品  %d / 15"%s.inventory.size())
	Grid.bag(bag,game,self,Vector2(18,50),4,44)
	drag_hint=label_at(self,game.notice,Rect2(260,74,702,18),12); drag_hint.z_index=1000
func build_map() -> void:
	var p:=UISkin.panel(self,Rect2(982,86,282,260),"地図  /  クリックで拡大")
	var sc:=ScrollContainer.new(); sc.position=Vector2(14,52); sc.size=Vector2(254,193); sc.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED; sc.theme=UISkin.scroll_theme(); p.add_child(sc)
	route=Control.new(); route.set_script(Routes); route.floor_number=int(game.campaign.floor); route.highest_floor=int(game.campaign.highest_floor); route.max_floor=int(game.cfg.journey.public_max_floor); sc.add_child(route)
	route.opened.connect(func():call_deferred("open_routes")); route.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	sc.set_deferred("scroll_vertical",maxi(0,(int(game.campaign.floor)-1)*44-78))
func build_field() -> void:
	stage=Control.new(); stage.set_script(preload("res://ui/battle_stage.gd")); stage.position=Vector2(252,86); stage.size=Vector2(718,400); stage.integrated_layout=true; stage.wide_layout=true; stage.floor_number=int(game.campaign.floor); stage.enemy_id=battle.enemy.id if not battle.is_empty() else ""; add_child(stage)
	if battle.is_empty(): stage.enemy_art.visible=false
	else:
		var overlay:=Control.new(); overlay.set_script(preload("res://ui/status_overlay.gd")); overlay.battle=battle; stage.add_child(overlay)
		for side in ["hero","enemy"]:
			var hud:=Control.new(); hud.set_script(preload("res://ui/actor_hud.gd")); hud.host=self; hud.stage=stage; hud.side=side; stage.add_child(hud); actor_huds[side]=hud
		if game.intro_active:
			var intro:=UISkin.panel(stage,Rect2(145,12,428,70),"",true); intro.z_index=980
			label_at(intro,("10Fの門番  /  " if game.campaign.floor==10 else "遭遇  /  ")+battle.enemy.name,Rect2(18,10,392,45),23,true)
	center=UISkin.panel(self,Rect2(252,498,718,206),"探索の記録" if battle.is_empty() else "戦闘の記録")
	var y:=53
	if not battle.is_empty():
		nav(center,"停止中 / 再開" if not game.auto_play else "動作中 / 停止",Rect2(20,51,190,34),func():game.auto_play=not game.auto_play; game.cancel_presentation(); game.show_campaign(),"pause-battle")
		label_at(center,"Space：停止 / 再開   ・   ROUND %d"%battle.round,Rect2(224,54,470,29),16); y=94
	var journal: Array=game.presentation_journal if game.presenting else game.campaign.journal
	label_at(center,"\n".join(journal.slice(maxi(0,journal.size()-(4 if not battle.is_empty() else 6)))),Rect2(22,y,675,190-y),16)
func chest_texture(opened: bool=false) -> Texture2D:
	var atlas:=AtlasTexture.new(); atlas.atlas=preload("res://assets/journey/v1/treasure-chest-states.png"); atlas.region=Rect2(887 if opened else 0,0,887,887); atlas.filter_clip=true; return atlas
func build_chest() -> void:
	UISkin.picture(center,chest_texture(),Rect2(224,73,270,270))
	label_at(center,"誰かが残した品が入っている。\n中身を確かめて、次の旅の力にしよう。",Rect2(70,350,578,86),23,true)
	action(center,"開ける［E］",Rect2(103,510,512,62),"open_chest",{},true)
func build_event() -> void:
	var s: Dictionary=game.campaign
	if s.phase=="event":
		if game.event_choice_key!=str(s.trips)+"/"+str(s.floor)+"/"+s.event: game.event_choice=""; game.event_choice_key=str(s.trips)+"/"+str(s.floor)+"/"+s.event
		var event: Dictionary=game.cfg.journey.events[s.event]
		UISkin.picture(center,preload("res://ui/status_symbols.gd").texture(event.get("icon","exp")),Rect2(292,65,134,134))
		label_at(center,event.description,Rect2(58,216,602,128),23,true)
		for i in event.choices.size():
			var choice: Dictionary=event.choices[i]
			var b:=UISkin.button(center,choice.label,Rect2(46+i*322,374,304,62),func():choose_event(choice.id)); UISkin.quiet_button(b,game.event_choice==choice.id); b.set_meta("event_choice",choice.id); choice_buttons[choice.id]=b
		choice_confirm=nav(center,"選んだ行動を決定［E］",Rect2(103,510,512,62),func():game.perform("journey_event",{"choice":game.event_choice},int(s.revision)),"event-confirm",true)
		choice_confirm.disabled=game.event_choice==""
	else:
		label_at(center,s.event_result.text,Rect2(58,122,602,166),26,true)
		var changes: Array[String]=[]
		if s.event_result.hp_delta!=0: changes.append("HP %+d"%s.event_result.hp_delta)
		if s.event_result.exp!=0: changes.append("EXP +%d"%s.event_result.exp)
		label_at(center," / ".join(changes),Rect2(58,316,602,42),23,true)
		if s.pending_rewards.is_empty(): action(center,"さらに潜る［E］",Rect2(103,510,512,62),"advance_ready",{},true)
		else:
			var go:=action(center,"すべて受け取って進む［E］",Rect2(103,510,512,62),"claim_all_advance",{},true)
			go.disabled=s.inventory.size()+s.pending_rewards.size()>15
			action(center,"獲得品を比較・整理",Rect2(180,444,358,46),"continue_event")
func choose_event(id: String) -> void:
	game.event_choice=id
	for key in choice_buttons: UISkin.quiet_button(choice_buttons[key],key==id)
	choice_confirm.disabled=false
func build_rewards() -> void:
	var s: Dictionary=game.campaign
	var earned: Dictionary=s.get("last_reward",{}); var gains: Array[String]=[]
	if earned.get("exp",0)!=0: gains.append("EXP +%d"%earned.exp)
	if earned.get("gold",0)!=0: gains.append("Gold +%d"%earned.gold)
	label_at(center," / ".join(gains),Rect2(30,57,600,32),19,true)
	label_at(center,"未受領 %d 点  /  クリックで比較・詳細"%s.pending_rewards.size(),Rect2(30,100,654,30),18,true)
	if s.pending_rewards.is_empty(): label_at(center,"すべて受け取りました。",Rect2(50,170,618,72),25,true)
	else:
		if E.Journey.reward_index(s,game.reward_selected)<0: game.reward_selected=s.pending_rewards[0].token
		if game.flow_selection.get("kind")=="actor": game.flow_selection={"kind":"pending","uid":game.reward_selected}
		for i in s.pending_rewards.size():
			var reward: Dictionary=s.pending_rewards[i]; var item: Dictionary=game.cfg.items[reward.id]
			var x: int=30+(i%4)*168; var y: int=148+int(i/4)*100
			Grid.cell(center,game,self,Rect2(x,y,64,64),"pending",reward.token,"",game.flow_selection.get("uid")==reward.token)
			label_at(center,item.name,Rect2(x,y+66,160,28),15,true)
	label_at(center,"装備中  /  獲得品をダブルクリック、または部位へドラッグ",Rect2(30,313,658,40),16,true)
	for i in E.SLOTS.size():
		var slot: String=E.SLOTS[i]
		Grid.cell(center,game,self,Rect2(30+i*60,364,56,56),"equipment",s.equipment[slot],slot,game.flow_selection.get("slot")==slot)
	label_at(center,"所持品：ダブルクリックで交換 / 無効なドロップでは移動しません",Rect2(30,431,658,42),15,true)
	var fits: bool=s.inventory.size()+s.pending_rewards.size()<=15
	var text: String=("10F突破の記録へ［E］" if s.reward_return=="clear" else "さらに潜る［E］") if s.pending_rewards.is_empty() else "すべて受け取って進む［E］"
	var go:=action(center,text,Rect2(30,508,658,55),"advance_ready" if s.pending_rewards.is_empty() else "claim_all_advance",{},true); go.disabled=not fits
	if not fits: label_at(center,"容量不足：装備して空きを作るか、所持品と明示的に入れ替えてください。",Rect2(30,472,658,32),15,true)
	if not s.pending_rewards.is_empty(): nav(center,"未受領品を諦める…",Rect2(430,573,258,31),func():game.reward_confirmation="abandon"; confirmation(),"confirm-abandon")
func select_actor(side: String) -> void:
	if side=="enemy" and (battle.is_empty() or battle.enemy.hp<=0): return
	game.flow_selection={"kind":"actor","side":side}; refresh_details()
func select_item(source: String, uid: String, slot: String="") -> void:
	if uid=="" and slot=="": return
	game.flow_selection={"kind":source,"uid":uid,"slot":slot}
	if source=="pending": game.reward_selected=uid
	if source=="inventory": game.replace_selected=uid
	refresh_cell_selection(self); refresh_details()
func refresh_cell_selection(node: Node) -> void:
	if node is Button and node.has_meta("item_source"):
		UISkin.quiet_button(node,node.get_meta("item_source")==game.flow_selection.get("kind") and node.get_meta("item_uid")==game.flow_selection.get("uid") and node.get_meta("equip_slot")==game.flow_selection.get("slot",""))
	for child in node.get_children(): refresh_cell_selection(child)
func activate_item(source: String, uid: String, slot: String="") -> void:
	if uid=="" or source=="equipment": return
	var payload: Dictionary=Gear.payload(game,source,uid,slot)
	Gear.apply(game,payload,"equipment")
func accepts_gear(value: Variant, destination: String, slot: String="") -> bool:
	return Gear.reason(game,value,destination,slot)==""
func show_drag_reason(text: String) -> void:
	if is_instance_valid(drag_hint): drag_hint.text=text
func drop_gear(value: Dictionary, destination: String, slot: String="") -> void:
	Gear.apply(game,value,destination,slot)
func refresh_details() -> void:
	if is_instance_valid(detail_body): detail.remove_child(detail_body); detail_body.queue_free()
	detail_body=Control.new(); detail_body.position=Vector2(16,52); detail_body.size=Vector2(250,278); detail.add_child(detail_body)
	var selection: Dictionary=game.flow_selection
	if selection.get("kind")=="actor":
		var side: String=selection.get("side","hero")
		if side=="enemy" and (battle.is_empty() or battle.enemy.hp<=0): game.flow_selection={"kind":"actor","side":"hero"}; side="hero"
		var h: Dictionary=battle[side] if not battle.is_empty() else E.hero(game.campaign,game.cfg)
		label_at(detail_body,h.name+"  Lv.%d"%h.level,Rect2(0,0,250,44),22,true)
		label_at(detail_body,"HP %d / %d\nSP %d / %d\n攻撃 %d   防御 %d\n素早さ %d"%[h.hp,h.max_hp,h.sp,h.max_sp,h.atk,h.def,h.spd],Rect2(0,53,250,113),18,true)
		var effects: Array=Model.effects(h,game.data.rules); var text: Array[String]=[]
		for effect in effects: text.append(effect.name+" / 残り%d機会"%effect.remaining+"\n"+effect.text)
		label_at(detail_body,"\n".join(text) if not text.is_empty() else "状態異常なし",Rect2(0,177,250,97),15,true)
		return
	var uid: String=selection.get("uid",""); var template: String=""; var slot: String=selection.get("slot","")
	if selection.kind=="pending":
		var i: int=E.Journey.reward_index(game.campaign,uid)
		if i>=0: template=game.campaign.pending_rewards[i].id
	else: template=game.campaign.items.get(uid,"")
	if template=="": label_at(detail_body,game.cfg.slots.get(slot,"アイテム")+" / 未装備",Rect2(0,10,250,65),22,true); return
	var item: Dictionary=game.cfg.items[template]
	UISkin.picture(detail_body,Items.texture(template,item.slot),Rect2(0,0,56,56))
	label_at(detail_body,item.name,Rect2(67,0,183,61),20,true)
	label_at(detail_body,game.cfg.slots.get(item.slot,"素材")+" / ×1"+(" / 未受領" if selection.kind=="pending" else ""),Rect2(0,66,250,26),15,true)
	var lines: Array[String]=[]
	for key in item.stats: lines.append({"atk":"攻撃","def":"防御","spd":"素早さ","max_hp":"最大HP","max_sp":"最大SP"}[key]+" %+d"%int(item.stats[key]))
	if uid in game.campaign.items: lines.append(game.condition_text(uid))
	if item.slot!="" and selection.kind in ["inventory","pending"]:
		var candidate: Dictionary=E.act(game.campaign,"equip_reward" if selection.kind=="pending" else "equip",int(game.campaign.revision),{"token":uid} if selection.kind=="pending" else {"uid":uid},game.data,game.cfg)
		var before: Dictionary=E.hero(game.campaign,game.cfg); var after: Dictionary=E.hero(candidate,game.cfg)
		var compare: Array[String]=[]
		for key in [["atk","攻撃"],["def","防御"],["spd","速"],["max_hp","HP"],["max_sp","SP"]]: compare.append("%s %+d"%[key[1],int(after[key[0]])-int(before[key[0]])])
		lines.append("交換差："+" / ".join(compare))
	label_at(detail_body,"\n".join(lines),Rect2(0,96,250,93),15,true)
	if selection.kind=="pending" and game.campaign.phase=="reward":
		var claim:=action(detail_body,"この品を受け取る",Rect2(0,194,250,34),"claim_reward",{"token":uid}); claim.disabled=game.campaign.inventory.size()>=15
		if item.slot!="":
			var equip:=action(detail_body,"受け取って装備",Rect2(0,237,250,34),"equip_reward",{"token":uid}); equip.disabled=Gear.reason(game,Gear.payload(game,"pending",uid),"equipment")!=""; equip.tooltip_text=Gear.reason(game,Gear.payload(game,"pending",uid),"equipment")
		if game.campaign.inventory.size()>=15 and game.replace_selected in game.campaign.inventory:
			claim.text="選択所持品と入替…"; claim.disabled=false
			for callback in claim.pressed.get_connections(): claim.pressed.disconnect(callback.callable)
			claim.pressed.connect(func():game.reward_confirmation="exchange"; call_deferred("confirmation"))
	elif selection.kind=="inventory" and item.slot!="":
		var equip:=nav(detail_body,"この装備へ交換",Rect2(0,237,250,34),func():activate_item("inventory",uid),"equip-selected"); equip.disabled=not battle.is_empty()
	else:
		label_at(detail_body,item.get("description",preload("res://ui/warehouse_catalog.gd").DESCRIPTIONS.get(template,"")),Rect2(0,194,250,82),16,true)
func refresh_live() -> void:
	battle=game.display_battle()
	if battle.is_empty(): return
	hero_hp.text="HP %d / %d"%[battle.hero.hp,battle.hero.max_hp]; hero_bar.value=battle.hero.hp; hero_sp.text="SP %d / %d"%[battle.hero.sp,battle.hero.max_sp]
	for hud in actor_huds.values(): hud.refresh()
	for child in stage.get_children():
		if child.get_script()==preload("res://ui/status_overlay.gd"): child.battle=battle; child.queue_redraw()
	refresh_details()
func open_routes() -> void:
	if is_instance_valid(routes_overlay): return
	game.route_map_open=true; map_primary=game.primary_button; game.primary_button=null
	routes_overlay=Control.new(); routes_overlay.size=Vector2(1280,720); routes_overlay.z_index=1100; add_child(routes_overlay)
	var shade:=ColorRect.new(); shade.color=Color(0,0,0,.65); shade.size=Vector2(1280,720); routes_overlay.add_child(shade)
	var panel:=UISkin.panel(routes_overlay,Rect2(380,82,520,556),"詳細地図 / 浅い階層から下へ",true)
	var sc:=ScrollContainer.new(); sc.position=Vector2(75,60); sc.size=Vector2(370,410); sc.theme=UISkin.scroll_theme(); sc.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED; panel.add_child(sc)
	var map:=Control.new(); map.set_script(Routes); map.expanded=true; map.floor_number=int(game.campaign.floor); map.highest_floor=int(game.campaign.highest_floor); map.max_floor=int(game.cfg.journey.public_max_floor); sc.add_child(map); sc.set_deferred("scroll_vertical",maxi(0,(int(game.campaign.floor)-1)*44-176))
	nav(panel,"閉じる［Esc］",Rect2(78,485,364,48),close_routes,"close-map")
func close_routes() -> void:
	game.route_map_open=false
	if is_instance_valid(routes_overlay): remove_child(routes_overlay); routes_overlay.queue_free()
	routes_overlay=null; game.primary_button=map_primary
func confirmation() -> void:
	game.primary_button=null
	var modal:=Control.new(); modal.z_index=1200; modal.size=Vector2(1280,720); add_child(modal)
	var shade:=ColorRect.new(); shade.color=Color(0,0,0,.7); shade.size=Vector2(1280,720); modal.add_child(shade)
	var exchange: bool=game.reward_confirmation=="exchange"
	var panel:=UISkin.panel(modal,Rect2(290,190,700,330),"手放す品の確認",true)
	var names: Array[String]=[]
	for reward in game.campaign.pending_rewards: names.append(game.cfg.items[reward.id].name+" ×1")
	var prompt: String="以下の未受領品を失います。\n"+" / ".join(names)
	if exchange: prompt="手放す："+game.cfg.items[game.campaign.items[game.replace_selected]].name+"\n選択した獲得品を受け取ります。元に戻せません。"
	label_at(panel,prompt,Rect2(28,65,644,150),21,true)
	action(panel,"手放して受け取る" if exchange else "未受領品を諦める",Rect2(28,242,308,55),"exchange_reward" if exchange else "abandon_rewards",{"confirmed":true,"replace_uid":game.replace_selected,"token":game.reward_selected})
	nav(panel,"やめる",Rect2(364,242,308,55),func():game.reward_confirmation=""; game.show_campaign(),"cancel-reward")
func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and not event.is_echo():
		get_viewport().set_input_as_handled()
		if game.route_map_open: call_deferred("close_routes")
func visual_audit() -> Dictionary:
	return {"kind":"stable-exploration-shell","phase":game.campaign.phase,"left_rect":[16,86,224,266],"map_rect":[982,86,282,260],"detail_rect":[982,358,282,346],"selected":game.flow_selection.duplicate(true),"map_vertical":true,"map_open":game.route_map_open,"pending":game.campaign.pending_rewards.size(),"primary":game.primary_button.text if is_instance_valid(game.primary_button) else "","actor_huds":actor_huds.keys(),"logo":false}
