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
const ItemInfo=preload("res://ui/item_presenter.gd")
const Choices=preload("res://ui/event_choices.gd")
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
var main_button: Button
var detail_heading: Label
var detail_scroll: ScrollContainer
var detail_key: String=""
var detail_values: Dictionary={}
var map_scroll: ScrollContainer
var mini_scroll: ScrollContainer
var view_context: String=""
var modal_root: Control
var modal_buttons: Array[Button]=[]
var secondary_saved: Button
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
	view_context="%d/%d"%[s.trips,s.floor]
	if game.flow_memory.get("context","")!=view_context: game.flow_memory={"context":view_context,"details":{},"map":-1,"mini":-1}
	var node: Dictionary=E.Journey.node(game.cfg,int(s.floor),s)
	battle=game.display_battle() if s.phase=="battle" or game.presenting else {}
	if game.flow_selection.get("kind")=="pending" and E.Journey.reward_index(s,game.flow_selection.get("uid",""))<0: game.flow_selection={"kind":"actor","side":"hero"}
	UISkin.picture(self,Art.background_texture(node.get("background","cavern")),Rect2(0,0,1280,720),true).modulate=Color(.46,.55,.58)
	var head:=UISkin.panel(self,Rect2(16,14,1248,60),"",true)
	var phase: String="battle" if not battle.is_empty() else s.phase
	label_at(head,"地下 %d F  /  %s  /  %s"%[s.floor,Art.depth_name(s.floor),{"battle":"自動戦闘","explore":"探索","treasure":"宝箱を発見","reward":"獲得品","event":"道中の出来事","event_result":"選択の結果","portal":"帰還ポータル","portal_done":"帰還か続行"}.get(phase,"探索")],Rect2(26,10,1010,38),24,true)
	label_at(head,"G  %d"%E.money(s),Rect2(1080,13,140,30),20,true)
	build_left(); build_map()
	if game.debug_run: nav(head,"デバッグ操作",Rect2(880,15,170,30),func():game.open_services("debug"),"debug-services")
	detail=UISkin.panel(self,Rect2(982,358,282,346),"詳細",true)
	detail_heading=detail.get_meta("heading_label")
	if not battle.is_empty() or phase=="explore": build_field()
	else:
		center=UISkin.panel(self,Rect2(252,86,718,618),{"treasure":"古い宝箱","reward":s.reward_origin,"event":game.cfg.events.get(s.event,{}).get("name","出来事"),"event_result":s.event_result.get("title","選択の結果"),"portal":"地上に戻れるポータルを発見","portal_done":"この階の出来事は解決済み"}.get(phase,""),true)
		if phase=="treasure": build_chest()
		elif phase=="reward": build_rewards()
		elif phase in ["portal","portal_done"]: build_portal()
		else: build_event()
	refresh_details()
	if game.route_map_open: open_routes()
	if game.reward_confirmation=="choose_replace" and phase=="reward": begin_replacement(game.reward_selected)
	elif game.reward_confirmation!="" and phase=="reward": confirmation()
func build_left() -> void:
	var s: Dictionary=game.campaign
	var p:=UISkin.panel(self,Rect2(16,86,224,266),"探索操作")
	var rect:=Rect2(14,54,196,49)
	if not battle.is_empty():
		main_button=nav(p,"戦闘を再開［Space］" if not game.auto_play else "戦闘を停止［Space］",rect,game.toggle_auto_battle,"pause-battle")
	elif s.phase=="treasure": main_button=action(p,"宝箱を開ける［E］",rect,"open_chest",{},true)
	elif s.phase=="event":
		var event: Dictionary=game.cfg.journey.events[s.event]
		if Choices.simple(event):
			var benefit: Dictionary=event.choices.filter(func(c):return not c.ops.is_empty() if c.has("ops") else c.effect!="none")[0]
			var short: String=benefit.label
			main_button=action(p,short+"［E］",rect,"journey_event",{"choice":benefit.id},true)
		else:
			main_button=nav(p,"選択を決定［E］",rect,func():choose_event(game.event_choice,true),"event-confirm",true)
			main_button.disabled=game.event_choice==""
	elif s.phase=="portal": main_button=action(p,"居座る［E］",rect,"portal_stay",{},true)
	elif s.phase=="portal_done": main_button=action(p,"突破して帰還［E］" if s.floor==10 and s.node.kind=="boss" else "次の階へ［E］",rect,"portal_continue",{},true)
	elif s.phase in ["reward","event_result"] and not s.pending_rewards.is_empty():
		main_button=action(p,"受け取る［E］" if s.floor%5==0 else "受け取って進む［E］",rect,"claim_all_advance",{},true)
		main_button.disabled=not E.Adventure.fits(s,s.pending_rewards) if E.Adventure.active(s) else s.inventory.size()+s.pending_rewards.size()>15
		main_button.tooltip_text="容量不足：獲得品の「所持品と入れ替える…」から手放す品を選べます。" if main_button.disabled else "すべて受領し、次の探索を1回進めます。"
	else: main_button=action(p,"帰還／続行へ［E］" if s.floor%5==0 and s.floor>0 else "さらに潜る［E］",rect,"advance_ready",{},true)
	main_button.add_theme_font_size_override("font_size",16)
	var gear:=nav(p,"所持品・装備［I］",Rect2(14,112,196,42),game.open_field_equipment,"field-equipment"); gear.disabled=not battle.is_empty(); gear.tooltip_text="戦闘中は装備を変更できません。" if gear.disabled else "比較・ダブルクリック・ドラッグで装備交換"
	nav(p,"ステータス［C］",Rect2(14,164,196,42),game.open_status,"field-status")
	var back:=action(p,"突破して帰還" if s.phase=="reward" and s.reward_return=="clear" else "町へ帰還",Rect2(14,216,196,42),"return_ready"); back.disabled=not E.Adventure.can_return(s) if E.Adventure.active(s) else s.phase not in ["explore","reward","event_result"] or not s.pending_rewards.is_empty() or not battle.is_empty(); back.tooltip_text="帰還は5の倍数階のポータルのみ。戦闘中・未受領品がある間は帰還できません。"
	var hero: Dictionary=battle.hero if not battle.is_empty() else E.hero(s,game.cfg)
	var card:=UISkin.panel(self,Rect2(16,364,224,84),"")
	var pick:=Button.new(); pick.flat=true; pick.size=Vector2(224,84); pick.mouse_default_cursor_shape=CURSOR_POINTING_HAND; card.add_child(pick); pick.pressed.connect(func():select_actor("hero")); pick.set_meta("actor_select","hero")
	label_at(card,"主人公  Lv.%d"%hero.level,Rect2(16,8,192,24),17)
	hero_hp=label_at(card,"HP %d / %d"%[hero.hp,hero.max_hp],Rect2(16,28,192,22),17)
	hero_bar=UISkin.gauge(card,hero.hp,hero.max_hp,Rect2(16,52,192,8),Color("b83e32"))
	hero_sp=label_at(card,"SP %d / %d"%[hero.sp,hero.max_sp],Rect2(16,62,192,16),13)
	var bag:=UISkin.panel(self,Rect2(16,460,224,244),"所持品 %d/15"%s.inventory.size())
	var sort:=action(bag,"整列",Rect2(157,12,53,29),"organize_bag"); sort.add_theme_font_size_override("font_size",14); sort.tooltip_text="種類順に整列 / 空き枠数は変わりません。"; sort.disabled=not battle.is_empty()
	Grid.bag(bag,game,self,Vector2(18,50),4,44)
	drag_hint=label_at(self,game.notice,Rect2(260,74,702,18),12); drag_hint.z_index=1000
func build_map() -> void:
	var p:=UISkin.panel(self,Rect2(982,86,282,260),"地図 / 帰還地点 %dF"%(mini(10,int(ceil(float(game.campaign.floor)/5.0))*5)))
	var sc:=ScrollContainer.new(); sc.position=Vector2(14,52); sc.size=Vector2(254,193); sc.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED; sc.theme=UISkin.scroll_theme(); p.add_child(sc); mini_scroll=sc
	route=Control.new(); route.set_script(Routes); route.floor_number=int(game.campaign.floor); route.highest_floor=int(game.campaign.highest_floor); route.max_floor=int(game.cfg.journey.public_max_floor); sc.add_child(route)
	route.opened.connect(func():call_deferred("open_routes")); route.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	sc.set_deferred("scroll_vertical",int(game.flow_memory.mini) if int(game.flow_memory.mini)>=0 else maxi(0,(int(game.campaign.floor)-1)*44-78))
func build_field() -> void:
	stage=Control.new(); stage.set_script(preload("res://ui/battle_stage.gd")); stage.position=Vector2(252,86); stage.size=Vector2(718,400); stage.integrated_layout=true; stage.wide_layout=true; stage.floor_number=int(game.campaign.floor); stage.background_override=E.Journey.node(game.cfg,int(game.campaign.floor),game.campaign).get("background",""); stage.enemy_id=battle.enemy.id if not battle.is_empty() else ""; add_child(stage)
	if battle.is_empty(): stage.enemy_art.visible=false
	else:
		var overlay:=Control.new(); overlay.set_script(preload("res://ui/status_overlay.gd")); overlay.battle=battle; stage.add_child(overlay)
		for side in ["hero","enemy"]:
			var hud:=Control.new(); hud.set_script(preload("res://ui/actor_hud.gd")); hud.host=self; hud.stage=stage; hud.side=side; stage.add_child(hud); actor_huds[side]=hud
		if not game.intro_active and int(battle.enemy.get("ai_phase",0))==2:
			var warning:=UISkin.panel(stage,Rect2(145,12,428,64),"",true); warning.z_index=970
			label_at(warning,"強打の予告  /  次の行動に備える",Rect2(16,10,396,40),21,true)
		if game.intro_active:
			var intro:=UISkin.panel(stage,Rect2(145,12,428,70),"",true); intro.z_index=980
			label_at(intro,("10Fの門番  /  " if game.campaign.floor==10 else "遭遇  /  ")+battle.enemy.name,Rect2(18,10,392,45),23,true)
	center=UISkin.panel(self,Rect2(252,498,718,206),"探索の記録" if battle.is_empty() else "戦闘の記録")
	var y:=53
	if not battle.is_empty():
		label_at(center,"停止中" if not game.auto_play else "自動戦闘中",Rect2(20,51,190,34),18)
		label_at(center,"Space：停止 / 再開   ・   ROUND %d"%battle.round,Rect2(224,54,470,29),16); y=94
	var journal: Array=game.presentation_journal if game.presenting else game.campaign.journal
	label_at(center,"\n".join(journal.slice(maxi(0,journal.size()-(4 if not battle.is_empty() else 6)))),Rect2(22,y,675,190-y),16)
func chest_texture(opened: bool=false) -> Texture2D:
	var atlas:=AtlasTexture.new(); atlas.atlas=preload("res://assets/journey/v1/treasure-chest-states.png"); atlas.region=Rect2(887 if opened else 0,0,887,887); atlas.filter_clip=true; return atlas
func build_chest() -> void:
	UISkin.picture(center,chest_texture(),Rect2(224,73,270,270))
	label_at(center,"誰かが残した品が入っている。\n左の「宝箱を開ける［E］」で中身を確かめる。",Rect2(70,350,578,86),23,true)
	var skip:=action(center,"見送って進む［X／右クリック］",Rect2(135,492,448,52),"skip_chest")
	game.set_secondary(skip)
	label_at(center,"未開封で見送ります。この階では帰還／続行を選べます。" if int(game.campaign.floor)%5==0 else "未開封のまま見送り、次の探索を1回進めます。",Rect2(80,555,558,36),17,true)
func build_event() -> void:
	var s: Dictionary=game.campaign
	if s.phase=="event":
		var event: Dictionary=game.cfg.journey.events[s.event]
		if E.Adventure.active(s) and not Choices.simple(event): build_modern_event(event); return
		if game.event_choice_key!=view_context+"/"+s.event: game.event_choice=""; game.event_choice_key=view_context+"/"+s.event
		UISkin.picture(center,preload("res://ui/status_symbols.gd").texture(event.get("icon","exp")),Rect2(292,65,134,134))
		label_at(center,event.description,Rect2(58,216,602,116),23,true)
		if Choices.simple(event):
			var benefit: Dictionary=event.choices.filter(func(c):return not c.ops.is_empty() if c.has("ops") else c.effect!="none")[0]
			var skip_choice: Dictionary=event.choices.filter(func(c):return c.ops.is_empty() if c.has("ops") else c.effect=="none")[0]
			label_at(center,benefit.label+"："+Choices.summary(benefit,game.cfg)+"\n左の［E］ですぐに実行できます。",Rect2(58,358,602,80),21,true)
			var skip:=action(center,skip_choice.label+"［X／右クリック］",Rect2(135,492,448,52),"journey_event",{"choice":skip_choice.id}); game.set_secondary(skip)
		else:
			for i in event.choices.size():
				var choice: Dictionary=event.choices[i]
				var b:=nav(center,choice.label,Rect2(46+i*322,374,304,62),func():choose_event(choice.id,true),"choice-"+choice.id); UISkin.quiet_button(b,game.event_choice==choice.id); b.set_meta("event_choice",choice.id); choice_buttons[choice.id]=b
				label_at(center,Choices.summary(choice,game.cfg)+("\n代償："+str(choice.cost_text) if choice.has("cost_text") else ""),Rect2(46+i*322,444,304,80),16,true)
			label_at(center,"クリックで決定 / キーボードは↑↓または数字で選び、左の［E］で決定",Rect2(46,550,626,48),16,true)
			main_button.disabled=game.event_choice==""
	else:
		label_at(center,s.event_result.text,Rect2(58,122,602,166),26,true)
		var changes: Array[String]=[]
		if s.event_result.hp_delta!=0: changes.append("HP %+d"%s.event_result.hp_delta)
		if s.event_result.exp!=0: changes.append("EXP +%d"%s.event_result.exp)
		label_at(center," / ".join(changes),Rect2(58,316,602,42),23,true)
		label_at(center,"左の［E］で帰還／続行の選択へ進みます。" if s.floor%5==0 else "左の［E］で、次の探索へ進めます。",Rect2(58,491,602,54),21,true)
		if not s.pending_rewards.is_empty(): action(center,"獲得品を比較・整理",Rect2(180,420,358,46),"continue_event")
func event_args(id: String) -> Dictionary:
	return {"choice":id,"uid":game.campaign.get("event_target",""),"payment_source":game.campaign.get("payment_source","inventory")}
func choose_event(id: String, decide: bool=false) -> void:
	if id=="": return
	if game.event_choice_key!=view_context+"/"+game.campaign.event: game.event_choice_key=view_context+"/"+game.campaign.event
	game.event_choice=id
	for key in choice_buttons: UISkin.quiet_button(choice_buttons[key],key==id)
	var reason: String=""
	if E.Adventure.active(game.campaign):
		for choice in game.cfg.journey.events[game.campaign.event].choices:
			if choice.id==id: reason=E.Adventure.event_reason(game.campaign,choice,event_args(id),game.cfg)
	main_button.disabled=reason!=""; main_button.tooltip_text=reason
	if decide and reason=="": game.perform("journey_event",event_args(id),int(game.campaign.revision))
func build_portal() -> void:
	var s: Dictionary=game.campaign
	UISkin.picture(center,preload("res://ui/status_symbols.gd").texture("exp"),Rect2(285,78,148,148))
	label_at(center,"地下 %d F  /  帰還地点"%s.floor,Rect2(58,235,602,45),28,true)
	label_at(center,("まだ、この階の出来事は始まっていません。\n「居座る」で先へ。「町へ帰還」で成果を持ち帰れます。" if s.phase=="portal" else "この階の出来事は解決済みです。\n帰還するか、左の［E］で続行するか選んでください。"),Rect2(58,299,602,119),23,true)
	var portal_note: String="次の帰還地点：10F。5Fから再開する機能ではありません。"
	if s.floor==10:
		portal_note="10Fで居座ると石像のボス戦へ。帰還だけでは討伐になりません。" if s.phase=="portal" else ("討伐と受領は完了。［E］で突破帰還します。再戦は地上から新しい遠征で。" if s.node.kind=="boss" else "指定した出来事は解決済みです。ボス討伐にはなりません。")
	label_at(center,portal_note,Rect2(58,430,602,68),18,true)
	nav(center,"支度を確認 / 状態対策の薬",Rect2(140,530,438,48),func():game.open_services("prepare"),"portal-services")
	if game.debug_run: nav(center,"デバッグ専用操作",Rect2(390,65,290,36),func():game.open_services("debug"),"debug-services")
func build_modern_event(event: Dictionary) -> void:
	var s: Dictionary=game.campaign
	if game.event_choice_key!=view_context+"/"+s.event: game.event_choice=""; game.event_choice_key=view_context+"/"+s.event
	label_at(center,event.description,Rect2(30,64,658,90),22,true)
	var payment:=OptionButton.new(); payment.position=Vector2(30,165); payment.size=Vector2(310,36); center.add_child(payment)
	for source in ["inventory","cloth"]:
		payment.add_item(("バッグ" if source=="inventory" else "風呂敷")+"から支払う：%dG"%E.money(s,source)); payment.set_item_metadata(payment.item_count-1,source)
	payment.select(1 if s.payment_source=="cloth" else 0)
	payment.item_selected.connect(func(i):game.call_deferred("perform","payment_source",{"source":payment.get_item_metadata(i)},int(s.revision)))
	if event.choices.any(func(c):return c.get("target","")=="gear"):
		var targets:=OptionButton.new(); targets.position=Vector2(355,165); targets.size=Vector2(333,36); center.add_child(targets); targets.add_item("対象の装備を選ぶ"); targets.set_item_metadata(0,"")
		for uid in s.inventory+s.equipment.values():
			if uid=="" or game.cfg.items[s.items[uid]].slot=="": continue
			targets.add_item(game.cfg.items[s.items[uid]].name+" / 耐久%d"%s.item_condition[uid].current); targets.set_item_metadata(targets.item_count-1,uid)
			if uid==s.event_target: targets.select(targets.item_count-1)
		targets.item_selected.connect(func(i):game.call_deferred("perform","event_target",{"uid":targets.get_item_metadata(i)},int(s.revision)))
	for i in event.choices.size():
		var choice: Dictionary=event.choices[i]; var reason: String=E.Adventure.event_reason(s,choice,event_args(choice.id),game.cfg)
		var b:=nav(center,choice.label,Rect2(30,225+i*99,658,40),func():choose_event(choice.id,true),"choice-"+choice.id)
		UISkin.quiet_button(b,game.event_choice==choice.id); b.set_meta("event_choice",choice.id); choice_buttons[choice.id]=b; b.disabled=reason!=""; b.tooltip_text=reason
		label_at(center,Choices.summary(choice,game.cfg)+( "  /  "+reason if reason!="" else ""),Rect2(30,267+i*99,658,53),15,true)
	label_at(center,"クリックで決定 / ↑↓または数字で選び、左の［E］で決定",Rect2(30,565,658,36),15,true)
	if game.event_choice!="": choose_event(game.event_choice)
func build_rewards() -> void:
	var s: Dictionary=game.campaign
	var earned: Dictionary=s.get("last_reward",{}); var gains: Array[String]=[]
	if earned.get("exp",0)!=0: gains.append("EXP +%d"%earned.exp)
	if earned.get("gold",0)!=0: gains.append("Gold +%d"%earned.gold)
	label_at(center," / ".join(gains),Rect2(30,57,600,32),19,true)
	if s.pending_rewards.is_empty():
		label_at(center,"受け取り完了",Rect2(50,159,618,58),27,true)
		label_at(center,"左の［E］で次へ、または「町へ帰還」を選べます。",Rect2(50,230,618,65),20,true)
	else:
		label_at(center,"未受領 %d 点  /  クリックで比較・詳細"%s.pending_rewards.size(),Rect2(30,100,654,30),18,true)
		if E.Journey.reward_index(s,game.reward_selected)<0: game.reward_selected=s.pending_rewards[0].token
		if game.flow_selection.get("kind")=="actor": game.flow_selection={"kind":"pending","uid":game.reward_selected}
		var sc:=ScrollContainer.new(); sc.position=Vector2(30,139); sc.size=Vector2(658,165); sc.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED; sc.theme=UISkin.scroll_theme(); center.add_child(sc)
		var grid:=GridContainer.new(); grid.columns=3; grid.add_theme_constant_override("h_separation",12); grid.add_theme_constant_override("v_separation",10); sc.add_child(grid)
		for reward in s.pending_rewards:
			var item: Dictionary=game.cfg.items[reward.id]
			var card:=Control.new(); card.custom_minimum_size=Vector2(205,151); grid.add_child(card)
			Grid.cell(card,game,self,Rect2(67,0,72,72),"pending",reward.token,"",game.flow_selection.get("uid")==reward.token)
			var name_label:=label_at(card,item.name+("［保証］" if reward.get("guaranteed",false) else ""),Rect2(0,74,205,40),16,true); name_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
			var swap:=nav(card,"所持品と入れ替える…",Rect2(0,116,205,32),func():begin_replacement(reward.token),"replace-reward-"+reward.token); swap.add_theme_font_size_override("font_size",14); swap.disabled=s.inventory.is_empty()
	label_at(center,"装備 / 所持品をダブルクリック、または部位へドラッグで交換",Rect2(30,318,658,36),16,true)
	for i in E.SLOTS.size():
		var slot: String=E.SLOTS[i]
		Grid.cell(center,game,self,Rect2(30+i*60,364,56,56),"equipment",s.equipment[slot],slot,game.flow_selection.get("slot")==slot)
	var fits: bool=E.Adventure.fits(s,s.pending_rewards) if E.Adventure.active(s) else s.inventory.size()+s.pending_rewards.size()<=15
	if not fits: label_at(center,"バッグが満杯です。\n①獲得品の「所持品と入れ替える…」\n②手放す品を選ぶ → ③失う品と得る品を確認",Rect2(30,454,658,91),18,true)
	elif not s.pending_rewards.is_empty(): label_at(center,("左の［E］で受領後、帰還／続行を選びます。" if s.floor%5==0 else "左の［E］で全品を受け取り、次へ進めます。")+"\n個別受領・直接装備は、選択した品の右下詳細から。",Rect2(30,463,658,76),20,true)
	if not s.pending_rewards.is_empty():
		var abandon:=nav(center,"未受領品を諦める…",Rect2(430,573,258,31),func():open_confirmation("abandon"),"confirm-abandon")
		abandon.disabled=s.pending_rewards.any(func(r):return r.get("guaranteed",false)); abandon.tooltip_text="初突破の保証装備は、整理・装備・入替で受け取ってください。" if abandon.disabled else "失う品を確認してから放棄します。"
func select_actor(side: String) -> void:
	if is_instance_valid(game.modal_owner): return
	save_ui_state()
	if side=="enemy" and (battle.is_empty() or battle.enemy.hp<=0): return
	game.flow_selection={"kind":"actor","side":side}; refresh_details()
func select_item(source: String, uid: String, slot: String="") -> void:
	if is_instance_valid(game.modal_owner):
		if game.reward_confirmation=="choose_replace" and source=="inventory" and uid in game.campaign.inventory:
			var epoch: int=game.ui_epoch
			game.ui_action(func():game.replace_selected=uid; open_confirmation("exchange"),epoch)
		return
	save_ui_state()
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
	if is_instance_valid(game.modal_owner): return
	if uid=="" or source=="equipment": return
	var payload: Dictionary=Gear.payload(game,source,uid,slot)
	Gear.apply(game,payload,"equipment")
func accepts_gear(value: Variant, destination: String, slot: String="") -> bool:
	return Gear.reason(game,value,destination,slot)==""
func show_drag_reason(text: String) -> void:
	if is_instance_valid(drag_hint): drag_hint.text=text
func drop_gear(value: Dictionary, destination: String, slot: String="") -> void:
	Gear.apply(game,value,destination,slot)
func selection_key() -> String:
	var value: Dictionary=game.flow_selection
	return "%s/%s/%s/%s"%[value.get("kind",""),value.get("side",""),value.get("uid",""),value.get("slot","")]
func save_ui_state() -> void:
	if game.flow_memory.get("context","")!=view_context: return
	if is_instance_valid(detail_scroll) and detail_key!="": game.flow_memory.details[detail_key]=detail_scroll.scroll_vertical
	if is_instance_valid(map_scroll): game.flow_memory.map=map_scroll.scroll_vertical
	if is_instance_valid(mini_scroll): game.flow_memory.mini=mini_scroll.scroll_vertical
func update_actor_detail(h: Dictionary) -> void:
	detail_values.name.text=h.name+"  Lv.%d"%h.level
	detail_values.stats.text="HP %d / %d\nSP %d / %d\n攻撃 %d   防御 %d\n素早さ %d"%[h.hp,h.max_hp,h.sp,h.max_sp,h.atk,h.def,h.spd]
	var texts: Array[String]=[]
	for effect in Model.effects(h,game.data.rules): texts.append(effect.name+" / 自分の行動あと%d回分"%effect.remaining+"\n"+effect.text)
	detail_values.effects.text="\n".join(texts) if not texts.is_empty() else "状態異常なし"
func refresh_details() -> void:
	var selection: Dictionary=game.flow_selection
	if selection.get("kind")=="actor" and selection.get("side")=="enemy" and (battle.is_empty() or battle.enemy.hp<=0): game.flow_selection={"kind":"actor","side":"hero"}; selection=game.flow_selection; game.flow_memory.details[selection_key()]=0
	var key: String=selection_key()
	if key==detail_key and selection.get("kind")=="actor" and not detail_values.is_empty():
		update_actor_detail(battle[selection.side] if not battle.is_empty() else E.hero(game.campaign,game.cfg)); return
	save_ui_state(); detail_key=key; detail_values={}
	if is_instance_valid(detail_body): detail.remove_child(detail_body); detail_body.queue_free()
	detail_scroll=null
	detail_body=Control.new(); detail_body.position=Vector2(16,52); detail_body.size=Vector2(250,278); detail.add_child(detail_body)
	for hud in actor_huds.values(): hud.queue_redraw()
	if selection.get("kind")=="actor":
		var side: String=selection.get("side","hero"); var h: Dictionary=battle[side] if not battle.is_empty() else E.hero(game.campaign,game.cfg)
		detail_heading.text="敵の情報" if side=="enemy" else "主人公の状態"
		detail_scroll=ScrollContainer.new(); detail_scroll.size=Vector2(250,278); detail_scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED; detail_scroll.theme=UISkin.scroll_theme(); detail_body.add_child(detail_scroll)
		var body:=VBoxContainer.new(); body.size_flags_horizontal=Control.SIZE_EXPAND_FILL; body.add_theme_constant_override("separation",12); detail_scroll.add_child(body)
		for row in [["name",22],["stats",18],["effects",15]]:
			var l:=Label.new(); l.language="ja"; l.autowrap_mode=TextServer.AUTOWRAP_WORD; l.add_theme_font_size_override("font_size",row[1]); l.add_theme_color_override("font_color",UISkin.DARK); body.add_child(l); detail_values[row[0]]=l
		update_actor_detail(h)
	else:
		var uid: String=selection.get("uid",""); var template: String=""; var slot: String=selection.get("slot","")
		if selection.kind=="pending":
			var index: int=E.Journey.reward_index(game.campaign,uid)
			if index>=0: template=game.campaign.pending_rewards[index].id
		else: template=game.campaign.items.get(uid,"")
		detail_heading.text="装備の詳細" if template=="" or game.cfg.items[template].slot!="" else "アイテムの詳細"
		if template=="": label_at(detail_body,game.cfg.slots.get(slot,"アイテム")+" / 未装備",Rect2(0,10,250,65),22,true); return
		var item: Dictionary=game.cfg.items[template]
		UISkin.picture(detail_body,Items.texture(template,item.slot),Rect2(0,0,56,56)); label_at(detail_body,item.name,Rect2(67,0,183,61),20,true)
		label_at(detail_body,game.cfg.slots.get(item.slot,"素材")+(" / 未受領" if selection.kind=="pending" else ""),Rect2(0,66,250,26),15,true)
		var lines: Array[String]=[]
		if uid in game.campaign.items:
			if not item.stats.is_empty(): lines.append(ItemInfo.performance(game.campaign,game.cfg,uid))
			if item.slot!="": lines.append(game.condition_text(uid)); lines.append(ItemInfo.profile(game.campaign,game.cfg,uid))
			if template=="C01": lines.append("%d枚 / 1枚=1G / 上限99枚"%game.campaign.quantities[uid])
		elif not item.stats.is_empty():
			var current: Dictionary=item.stats
			if E.Adventure.active(game.campaign):
				var r: Dictionary=game.campaign.pending_rewards[E.Journey.reward_index(game.campaign,uid)]
				current=r.profile.base_roll.duplicate(true)
				for stat in r.profile.affix_stats: current[stat]=int(current.get(stat,0))+int(r.profile.affix_stats[stat])
			lines.append("現在値  "+ItemInfo.text(current))
		if item.slot!="" and selection.kind in ["inventory","pending"]:
			var compare: Array[String]=[]
			for row in ItemInfo.comparison(E.hero(game.campaign,game.cfg),Gear.compared_hero(game,selection.kind,uid)):
				if row.delta!=0: compare.append("%s %+d"%[row.name,row.delta])
			lines.append("交換差："+(" / ".join(compare) if not compare.is_empty() else "変化なし"))
		var description: String=item.get("description",preload("res://ui/warehouse_catalog.gd").DESCRIPTIONS.get(template,""))
		detail_scroll=ScrollContainer.new(); detail_scroll.position=Vector2(0,96); detail_scroll.size=Vector2(250,93); detail_scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED; detail_scroll.theme=UISkin.scroll_theme(); detail_body.add_child(detail_scroll)
		var text:=Label.new(); text.language="ja"; text.text="\n".join(lines)+("\n"+description if description!="" else ""); text.autowrap_mode=TextServer.AUTOWRAP_WORD; text.size_flags_horizontal=Control.SIZE_EXPAND_FILL; text.add_theme_font_size_override("font_size",15); text.add_theme_color_override("font_color",UISkin.DARK); detail_scroll.add_child(text)
		if selection.kind=="pending" and game.campaign.phase=="reward":
			var claim:=action(detail_body,"この品を受け取る",Rect2(0,194,250,34),"claim_reward",{"token":uid}); claim.disabled=not E.Adventure.fits(game.campaign,[game.campaign.pending_rewards[E.Journey.reward_index(game.campaign,uid)]]) if E.Adventure.active(game.campaign) else game.campaign.inventory.size()>=15; claim.tooltip_text="満杯です。中央の「所持品と入れ替える…」から手放す品を選べます。" if claim.disabled else "この個体を受領します。"
			if item.slot!="":
				var equip:=action(detail_body,"受け取って装備",Rect2(0,237,250,34),"equip_reward",{"token":uid}); equip.disabled=Gear.reason(game,Gear.payload(game,"pending",uid),"equipment")!=""; equip.tooltip_text=Gear.reason(game,Gear.payload(game,"pending",uid),"equipment")
		elif selection.kind=="inventory" and item.slot!="":
			var equip:=nav(detail_body,"この装備へ交換",Rect2(0,237,250,34),func():activate_item("inventory",uid),"equip-selected"); equip.disabled=not battle.is_empty()
		elif template=="C01" and selection.kind=="inventory" and E.Adventure.active(game.campaign):
			nav(detail_body,"枚数を指定 / 分割・結合",Rect2(0,237,250,34),func():game.open_services("coin",uid,"inventory"),"coin-selected")
		else: detail_scroll.size.y=178
	if is_instance_valid(detail_scroll): detail_scroll.set_deferred("scroll_vertical",int(game.flow_memory.details.get(key,0)))
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
	game.route_map_open=true; map_primary=game.primary_button; secondary_saved=game.secondary_button; game.primary_button=null; game.secondary_button=null
	routes_overlay=Control.new(); routes_overlay.size=Vector2(1280,720); routes_overlay.z_index=1100; add_child(routes_overlay)
	var shade:=ColorRect.new(); shade.color=Color(0,0,0,.65); shade.size=Vector2(1280,720); routes_overlay.add_child(shade)
	var panel:=UISkin.panel(routes_overlay,Rect2(380,82,520,556),"詳細地図 / 過去の到達記録",true)
	var sc:=ScrollContainer.new(); sc.position=Vector2(75,60); sc.size=Vector2(370,410); sc.theme=UISkin.scroll_theme(); sc.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED; panel.add_child(sc); map_scroll=sc
	var map:=Control.new(); map.set_script(Routes); map.expanded=true; map.floor_number=int(game.campaign.floor); map.highest_floor=int(game.campaign.highest_floor); map.max_floor=int(game.cfg.journey.public_max_floor); sc.add_child(map); sc.set_deferred("scroll_vertical",int(game.flow_memory.map) if int(game.flow_memory.map)>=0 else maxi(0,(int(game.campaign.floor)-1)*44-176))
	nav(panel,"閉じる［Esc／右クリック］",Rect2(78,485,364,48),close_routes,"close-map").add_theme_font_size_override("font_size",16)
func close_routes() -> void:
	save_ui_state(); game.ui_block_until=Time.get_ticks_msec()+360
	game.route_map_open=false
	if is_instance_valid(routes_overlay): remove_child(routes_overlay); routes_overlay.queue_free()
	routes_overlay=null; map_scroll=null; game.primary_button=map_primary; game.secondary_button=secondary_saved
func reset_modal() -> void:
	if is_instance_valid(modal_root): remove_child(modal_root); modal_root.queue_free()
	modal_buttons=[]; modal_root=Control.new(); modal_root.size=Vector2(1280,720); modal_root.z_index=1200; add_child(modal_root)
	var shade:=ColorRect.new(); shade.color=Color(0,0,0,.7); shade.size=Vector2(1280,720); modal_root.add_child(shade)
	game.modal_owner=self; game.primary_button=null; game.secondary_button=null
func begin_replacement(token: String) -> void:
	if E.Journey.reward_index(game.campaign,token)<0: return
	game.reward_selected=token; game.replace_selected=""; game.reward_confirmation="choose_replace"; reset_modal()
	var panel:=UISkin.panel(modal_root,Rect2(290,95,700,530),"手放す所持品を1つ選ぶ",true)
	var index: int=E.Journey.reward_index(game.campaign,token)
	label_at(panel,"得る品："+game.cfg.items[game.campaign.pending_rewards[index].id].name+"\n手放す所持品をクリックすると、両方の確認へ進みます。",Rect2(30,58,640,60),19,true)
	Grid.bag(panel,game,self,Vector2(89,140),5,96)
	var cancel:=nav(panel,"取消［Esc／X／右クリック］",Rect2(140,462,420,44),cancel_modal,"cancel-reward"); cancel.add_theme_font_size_override("font_size",16); cancel.grab_focus()
func open_confirmation(kind: String) -> void:
	game.reward_confirmation=kind; confirmation()
func confirmation() -> void:
	var exchange: bool=game.reward_confirmation=="exchange"
	var index: int=E.Journey.reward_index(game.campaign,game.reward_selected)
	if exchange and (game.replace_selected not in game.campaign.inventory or index<0): cancel_modal(); return
	reset_modal()
	var panel:=UISkin.panel(modal_root,Rect2(270,185,740,350),"失う品と得る品の確認",true)
	var names: Array[String]=[]
	for reward in game.campaign.pending_rewards: names.append(game.cfg.items[reward.id].name)
	var prompt: String="失う品："+" / ".join(names)+"\n得る品：なし\n未受領品だけを諦めます。所持品は変更しません。"
	if exchange:
		var uid: String=game.replace_selected
		prompt="失う品："+game.cfg.items[game.campaign.items[uid]].name+("（"+game.condition_text(uid)+"）" if game.cfg.items[game.campaign.items[uid]].slot!="" else "")+"\n得る品："+game.cfg.items[game.campaign.pending_rewards[index].id].name+"\n手放した個体は元に戻せません。"
	label_at(panel,prompt,Rect2(30,63,680,171),20,true)
	action(panel,"手放して受け取る" if exchange else "未受領品を諦める",Rect2(30,264,328,55),"exchange_reward" if exchange else "abandon_rewards",{"confirmed":true,"replace_uid":game.replace_selected,"token":game.reward_selected})
	var cancel:=nav(panel,"取消［Esc／X／右クリック］",Rect2(382,264,328,55),cancel_modal,"cancel-reward"); cancel.add_theme_font_size_override("font_size",16); cancel.grab_focus()
func cancel_modal() -> void:
	game.reward_confirmation=""; game.modal_owner=null; game.ui_block_until=Time.get_ticks_msec()+360
	if is_instance_valid(modal_root): remove_child(modal_root); modal_root.queue_free()
	modal_root=null; game.primary_button=main_button; game.secondary_button=null
func modal_key(code: int, backwards: bool=false) -> void:
	if code in [KEY_ESCAPE,KEY_X]: call_deferred("cancel_modal"); return
	if code not in [KEY_TAB,KEY_ENTER,KEY_KP_ENTER]: return
	modal_buttons=[]; collect_modal_buttons(modal_root)
	var current: Control=get_viewport().gui_get_focus_owner()
	if code==KEY_TAB and not modal_buttons.is_empty():
		var at: int=modal_buttons.find(current); modal_buttons[posmod(at+(-1 if backwards else 1),modal_buttons.size())].grab_focus()
	elif code in [KEY_ENTER,KEY_KP_ENTER] and current is Button and current in modal_buttons: current.emit_signal("pressed")
func collect_modal_buttons(node: Node) -> void:
	for child in node.get_children():
		if child is Button and not child.disabled: modal_buttons.append(child)
		collect_modal_buttons(child)
func handle_choice_key(code: int) -> bool:
	if game.campaign.phase!="event" or Choices.simple(game.cfg.journey.events[game.campaign.event]): return false
	var choices: Array=game.cfg.journey.events[game.campaign.event].choices
	var at: int=-1
	for i in choices.size():
		if choices[i].id==game.event_choice: at=i
	if code in [KEY_UP,KEY_DOWN]: at=posmod(at+(-1 if code==KEY_UP else 1),choices.size())
	elif code>=KEY_1 and code<KEY_1+choices.size(): at=code-KEY_1
	else: return false
	choose_event(choices[at].id); return true
func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and not event.is_echo():
		get_viewport().set_input_as_handled()
		if game.route_map_open: call_deferred("close_routes")
func visual_audit() -> Dictionary:
	return {"kind":"stable-exploration-shell","phase":game.campaign.phase,"left_rect":[16,86,224,266],"map_rect":[982,86,282,260],"detail_rect":[982,358,282,346],"selected":game.flow_selection.duplicate(true),"map_vertical":true,"map_open":game.route_map_open,"pending":game.campaign.pending_rewards.size(),"primary":game.primary_button.text if is_instance_valid(game.primary_button) else "","primary_rect":str(main_button.get_global_rect()),"detail_scroll":detail_scroll.scroll_vertical if is_instance_valid(detail_scroll) else 0,"map_scroll":map_scroll.scroll_vertical if is_instance_valid(map_scroll) else 0,"modal":game.reward_confirmation,"actor_huds":actor_huds.keys(),"logo":false}
