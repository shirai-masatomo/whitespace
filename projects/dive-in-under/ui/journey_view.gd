extends Control
## The same receipt and event screen is used on every configured floor.
const E=preload("res://core/expedition.gd")
const UISkin=preload("res://ui/ui_skin.gd")
const Art=preload("res://ui/visual_assets.gd")
const Items=preload("res://ui/equipment_art.gd")
const Symbols=preload("res://ui/status_symbols.gd")
var game: Control
var notice_label: Label
func label_at(parent: Node, value: String, r: Rect2, size_px: int=21, paper: bool=false) -> Label:
	return UISkin.label(parent,value,r,size_px,UISkin.DARK if paper else UISkin.INK,true)
func action(parent: Node, value: String, r: Rect2, name: String, args: Dictionary={}, primary: bool=false) -> Button:
	var revision: int=game.campaign.revision
	var b:=UISkin.button(parent,value,r,func():game.perform(name,args,revision),primary)
	b.set_meta("campaign_action",name); b.set_meta("campaign_args",args); game.play_buttons[name]=b
	return b
func nav(parent: Node, value: String, r: Rect2, callback: Callable, key: String) -> Button:
	var b:=UISkin.button(parent,value,r,callback); b.set_meta("nav",key); return b
func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var s: Dictionary=game.campaign
	var node: Dictionary=E.Journey.node(game.cfg,int(s.floor))
	UISkin.picture(self,Art.texture(node.get("background","cavern")),Rect2(0,0,1280,720),true)
	var veil:=ColorRect.new(); veil.color=Color(0.01,0.04,0.06,0.35); veil.size=Vector2(1280,720); veil.mouse_filter=MOUSE_FILTER_IGNORE; add_child(veil)
	var header:=UISkin.panel(self,Rect2(16,14,1248,60),"",true); UISkin.logo(header,Rect2(18,1,162,54))
	label_at(header,"地下 %d F  /  %s"%[s.floor,{"treasure":"宝箱を発見","reward":"獲得品の確認","event":"道中の出来事","event_result":"選択の結果"}[s.phase]],Rect2(212,11,790,37),25,true)
	notice_label=label_at(self,game.notice if game.notice!="" else "ここでは探索・戦闘は進みません。",Rect2(29,674,1200,30),17)
	if s.phase=="treasure": build_chest()
	elif s.phase in ["event","event_result"]: build_event()
	else: build_rewards()
func build_chest() -> void:
	var panel:=UISkin.panel(self,Rect2(302,132,676,482),"道の片隅に、古い宝箱",true)
	var chest:=UISkin.picture(panel,preload("res://ui/item_icons.gd").texture("warehouse"),Rect2(243,66,190,190))
	chest.pivot_offset=Vector2(95,95); chest.scale=Vector2(0.92,0.92)
	chest.create_tween().tween_property(chest,"scale",Vector2.ONE,0.2).set_trans(Tween.TRANS_BACK)
	label_at(panel,"誰かが残した品が入っている。
中身を確かめて、次の旅の力にしよう。",Rect2(66,270,544,81),22,true)
	action(panel,"宝箱を開ける",Rect2(128,382,420,62),"open_chest",{},true)
func build_event() -> void:
	var s: Dictionary=game.campaign
	var panel:=UISkin.panel(self,Rect2(224,127,832,510),game.cfg.events[s.event].name if s.phase=="event" else s.event_result.title,true)
	if s.phase=="event":
		var event: Dictionary=game.cfg.journey.events[s.event]
		UISkin.picture(panel,Symbols.texture(event.get("icon","exp")),Rect2(337,65,158,147))
		label_at(panel,event.description,Rect2(64,234,704,100),23,true)
		for i in event.choices.size():
			var choice: Dictionary=event.choices[i]
			action(panel,choice.label,Rect2(62+i*366,399,342,62),"journey_event",{"choice":choice.id},i==0)
	else:
		label_at(panel,s.event_result.text,Rect2(66,112,700,145),26,true)
		var result: String="HP %+d / EXP +%d"%[s.event_result.hp_delta,s.event_result.exp]
		label_at(panel,result,Rect2(66,278,700,60),24,true)
		action(panel,"獲得品を確認" if not s.pending_rewards.is_empty() else "探索へ戻る",Rect2(196,399,440,62),"continue_event",{},true)
func build_rewards() -> void:
	var s: Dictionary=game.campaign
	var left:=UISkin.panel(self,Rect2(16,92,318,516),"持ち物  %d / 15"%s.inventory.size())
	var sc:=ScrollContainer.new(); sc.position=Vector2(16,59); sc.size=Vector2(285,387); sc.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED; sc.theme=UISkin.scroll_theme(); left.add_child(sc)
	var list:=VBoxContainer.new(); list.size_flags_horizontal=Control.SIZE_EXPAND_FILL; sc.add_child(list)
	for uid in s.inventory:
		var item: Dictionary=game.cfg.items[s.items[uid]]
		var row:=Button.new(); row.text=item.name; row.custom_minimum_size=Vector2(265,40); UISkin.quiet_button(row,uid==game.replace_selected); list.add_child(row)
		row.tooltip_text=item.name+" / "+game.condition_text(uid)
		row.pressed.connect(func():game.replace_selected=uid; game.reward_confirmation=""; game.show_campaign())
	label_at(left,"入替時は選んだ所持品を手放します。",Rect2(18,463,282,35),14)
	var center:=UISkin.panel(self,Rect2(346,92,482,516),s.reward_origin)
	var earned: Dictionary=s.get("last_reward",{})
	label_at(center,"EXP +%d / Gold +%d"%[earned.get("exp",0),earned.get("gold",0)],Rect2(22,59,438,39),20)
	if s.pending_rewards.is_empty(): label_at(center,"すべて確認しました。",Rect2(40,213,402,70),24)
	else:
		if E.Journey.reward_index(s,game.reward_selected)<0: game.reward_selected=s.pending_rewards[0].token
		for i in s.pending_rewards.size():
			var reward: Dictionary=s.pending_rewards[i]; var item: Dictionary=game.cfg.items[reward.id]
			var b:=nav(center,item.name+" ×1",Rect2(26,113+i*89,430,77),func():game.reward_selected=reward.token; game.reward_confirmation=""; game.show_campaign(),"reward-"+reward.token)
			UISkin.quiet_button(b,game.reward_selected==reward.token); UISkin.picture(b,Items.texture(reward.id,item.slot),Rect2(9,10,55,55)); b.add_theme_font_size_override("font_size",18)
	label_at(center,"未受領 %d 点 / 1個体ずつ受け取り"%s.pending_rewards.size(),Rect2(25,460,432,32),17)
	var right:=UISkin.panel(self,Rect2(840,92,424,516),"獲得品の詳細",true)
	var index: int=E.Journey.reward_index(s,game.reward_selected)
	if index>=0:
		var reward: Dictionary=s.pending_rewards[index]; var item: Dictionary=game.cfg.items[reward.id]
		UISkin.picture(right,Items.texture(reward.id,item.slot),Rect2(28,64,94,94))
		label_at(right,item.name,Rect2(134,65,264,89),24,true)
		label_at(right,(game.cfg.slots.get(item.slot,"素材"))+" / 数量 1",Rect2(28,174,364,36),18,true)
		var stats: Array[String]=[]
		for key in item.stats: stats.append("%s %+d"%[{"atk":"攻撃","def":"防御","spd":"素早さ","max_hp":"最大HP","max_sp":"最大SP"}[key],item.stats[key]])
		label_at(right," / ".join(stats),Rect2(28,223,364,72),20,true)
		label_at(right,item.get("description",preload("res://ui/warehouse_catalog.gd").DESCRIPTIONS.get(reward.id,"旅の途中で見つけた品。")),Rect2(28,301,364,92),18,true)
		if s.inventory.size()<15:
			action(right,"この品を受け取る",Rect2(28,428,368,56),"claim_reward",{"token":reward.token},true)
		else:
			label_at(right,"バックパックに空きがありません",Rect2(28,396,368,30),16,true)
			var selected: bool=game.replace_selected in s.inventory
			var swap:=nav(right,"選択した所持品と入替",Rect2(28,436,368,48),func():game.reward_confirmation="exchange"; game.show_campaign(),"confirm-exchange"); swap.disabled=not selected
	var has_pending: bool=not s.pending_rewards.is_empty()
	nav(self,"所持品・装備",Rect2(16,624,280,47),game.open_field_equipment,"field-equipment")
	if has_pending:
		nav(self,"残りを諦める…",Rect2(346,624,236,47),func():game.reward_confirmation="abandon"; game.show_campaign(),"confirm-abandon")
	else: action(self,"帰還の記録へ" if s.reward_return=="clear" else "探索へ戻る",Rect2(840,624,424,47),"continue_rewards",{},true)
	if game.reward_confirmation!="": confirmation()
func confirmation() -> void:
	var blocker:=ColorRect.new(); blocker.size=Vector2(1280,720); blocker.color=Color(0,0,0,0.45); blocker.z_index=999; add_child(blocker)
	var exchange: bool=game.reward_confirmation=="exchange"
	var panel:=UISkin.panel(self,Rect2(270,237,740,255),"確認",true); panel.z_index=1000
	var prompt: String="残り%d点を受け取らずに諦めます。元に戻せません。"%game.campaign.pending_rewards.size()
	if exchange and game.replace_selected in game.campaign.inventory: prompt=game.cfg.items[game.campaign.items[game.replace_selected]].name+"を手放して、選んだ獲得品を受け取ります。"
	label_at(panel,prompt,Rect2(30,60,680,77),21,true)
	action(panel,"手放して受け取る" if exchange else "残りを諦める",Rect2(30,169,328,55),"exchange_reward" if exchange else "abandon_rewards",{"confirmed":true,"replace_uid":game.replace_selected,"token":game.reward_selected},true)
	nav(panel,"やめる",Rect2(382,169,328,55),func():game.reward_confirmation=""; game.show_campaign(),"cancel-reward")
func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		game.notice="未受領品は残っています。受領または明示的に諦めてから進んでください。"
		notice_label.text=game.notice
