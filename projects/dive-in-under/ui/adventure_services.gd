extends Control
const E=preload("res://core/expedition.gd")
const UISkin=preload("res://ui/ui_skin.gd")
const Money=preload("res://core/currency.gd")
const Info=preload("res://ui/item_presenter.gd")
var game: Control
var mode: String="prepare"
var source: String="inventory"
var uid: String=""
var amount: SpinBox
var destination: OptionButton
var gear: OptionButton
func txt(parent: Control, text: String, rect: Rect2, px: int=18) -> Label:
	return UISkin.label(parent,text,rect,px,UISkin.DARK,true)
func action(parent: Control, text: String, rect: Rect2, name: String, args: Dictionary={}) -> Button:
	var epoch: int=game.ui_epoch; var revision: int=game.campaign.revision
	var button: Button=UISkin.button(parent,text,rect,func():game.ui_action(func():game.perform(name,args,revision),epoch))
	button.add_theme_font_size_override("font_size",16); button.set_meta("service_action",name);button.set_meta("service_args",args); return button
func _ready() -> void:
	size=Vector2(1280,720); z_index=1400;game.modal_owner=self;game.primary_button=null;game.secondary_button=null
	var shade:=ColorRect.new();shade.color=Color(0,0,0,.73);shade.size=size;add_child(shade)
	var panel: Control=UISkin.panel(self,Rect2(150,58,980,604),"デバッグ専用操作" if mode=="debug" else ("コインの収納・分割・結合" if mode=="coin" else "支給所・個体・印・自動対策"),true)
	txt(panel,game.notice,Rect2(26,53,928,45),16)
	if mode=="debug": debug_controls(panel)
	elif mode=="coin": coin_controls(panel)
	else: prepare_controls(panel)
	var b: Button=UISkin.button(panel,"閉じる［Esc／X／右クリック］",Rect2(300,545,380,44),func():call_deferred("cancel_modal"));b.add_theme_font_size_override("font_size",16);b.grab_focus()
func payment(parent: Control, point: Vector2) -> void:
	txt(parent,"支払元を明示（他収納から自動補填しません）",Rect2(point,Vector2(670,25)),16)
	var select:=OptionButton.new();select.position=point+Vector2(0,30);select.size=Vector2(600,36);parent.add_child(select)
	var sources: Array=["inventory","cloth","warehouse"] if game.campaign.phase=="town" else ["inventory","cloth"]
	for i in sources.size():
		var key: String=sources[i];select.add_item({"inventory":"バッグ","cloth":"風呂敷","warehouse":"地上倉庫"}[key]+" %dG"%Money.amount(game.campaign,key));select.set_item_metadata(i,key)
		if game.campaign.payment_source==key:select.select(i)
	select.item_selected.connect(func(index):game.call_deferred("perform","payment_source",{"source":select.get_item_metadata(index)},int(game.campaign.revision)))
func prepare_controls(panel: Control) -> void:
	var s: Dictionary=game.campaign;var town: bool=s.phase=="town";var shop: bool=town or (s.floor==5 and s.phase in ["portal","portal_done"])
	payment(panel,Vector2(26,95))
	var supply: Button=action(panel,"不足部位の最低装備を再支給",Rect2(655,121,299,40),"supply");supply.disabled=not town
	txt(panel,"バッグ内の予防薬のみ自動使用 / 印が先、薬は付与1回に1個消費",Rect2(26,177,920,28),18)
	for i in 3:
		var status: String=["blind","poison","paralysis"][i];var id: String=["RB","RP","RM"][i];var name: String=game.cfg.items[id].name
		var x: int=26+i*310
		var toggle: Button=action(panel,name+"："+("自動ON" if s.auto_remedy[status] else "自動OFF"),Rect2(x,215,297,38),"auto_remedy",{"status":status})
		toggle.disabled=s.phase=="battle"
		var owned: int=s.inventory.filter(func(k):return s.items[k]==id).size()
		var buy: Button=action(panel,"購入 2G / バッグに%d個"%owned,Rect2(x,262,297,36),"buy_remedy",{"id":id,"source":s.payment_source});buy.disabled=not shop
	txt(panel,"薬の販売：町と5Fポータル。状態のある敵より先に確実に購入できます。",Rect2(26,303,928,30),15)
	gear=OptionButton.new();gear.position=Vector2(26,342);gear.size=Vector2(928,36);panel.add_child(gear);gear.set_meta("service_gear",true)
	var owned_gear: Array=s.inventory+s.equipment.values()
	gear.add_item("個体と印を確認する装備を選択");gear.set_item_metadata(0,"")
	for key in owned_gear:
		if key=="" or not s.items.has(key) or game.cfg.items[s.items[key]].slot=="":continue
		gear.add_item(E.Adventure.label(s,key));gear.set_item_metadata(gear.item_count-1,key)
		if key==game.service_uid:gear.select(gear.item_count-1)
	gear.item_selected.connect(func(index):game.service_uid=gear.get_item_metadata(index);game.call_deferred("show_campaign"))
	var selected: String=game.service_uid
	if not s.items.has(selected):selected=""
	if selected!="":txt(panel,Info.profile(s,game.cfg,selected),Rect2(26,386,928,66),16)
	for i in 3:
		var status: String=["blind","poison","paralysis"][i]
		var b: Button=action(panel,game.cfg.progression.seals[status].name+"（石1＋2G）",Rect2(26+i*310,463,297,38),"seal",{"uid":selected,"status":status,"source":s.payment_source});b.disabled=not town or selected=="" or s.item_details.get(selected,{}).get("seal_slots",0)==0
	txt(panel,"印は1枠1種・確定加工。破損中は印停止。支給品をイベントの対価にはできません。",Rect2(26,504,928,27),14)
func coin_controls(panel: Control) -> void:
	var s: Dictionary=game.campaign
	if not s.items.has(uid) or s.items[uid]!="C01":txt(panel,"コインを選んでください。",Rect2(26,130,928,60));return
	txt(panel,"選択：%s / %d枚（1枚1G）\n全量も分割も同じ収納処理。装備は個体別でスタックしません。"%[{"inventory":"バッグ","cloth":"風呂敷","warehouse":"地上倉庫"}[source],s.quantities[uid]],Rect2(26,100,928,80),21)
	amount=SpinBox.new();amount.min_value=1;amount.max_value=int(s.quantities[uid]);amount.value=int(s.quantities[uid]);amount.position=Vector2(30,210);amount.size=Vector2(250,42);amount.set_meta("coin_quantity",true);panel.add_child(amount)
	destination=OptionButton.new();destination.position=Vector2(330,210);destination.size=Vector2(580,42);panel.add_child(destination)
	for key in ["inventory","cloth","warehouse"]:
		if key==source:continue
		destination.add_item({"inventory":"バッグ","cloth":"風呂敷","warehouse":"地上倉庫"}[key]);destination.set_item_metadata(destination.item_count-1,key)
	var epoch: int=game.ui_epoch
	var move: Button=UISkin.button(panel,"指定枚数を移す（全量も可）",Rect2(30,278,880,45),func():game.ui_action(func():game.perform("coin_move",{"uid":uid,"source":source,"destination":destination.get_item_metadata(destination.selected),"quantity":int(amount.value)},int(s.revision)),epoch));move.set_meta("nav","coin-move")
	var split: Button=UISkin.button(panel,"同じ収納内で指定枚数を分割",Rect2(30,344,880,45),func():game.ui_action(func():game.perform("coin_split",{"uid":uid,"source":source,"quantity":int(amount.value)},int(s.revision)),epoch));split.set_meta("nav","coin-split")
	action(panel,"同じ収納のコインを結合",Rect2(30,410,880,45),"coin_combine",{"source":source})
	txt(panel,"入りきらない移動は全体を取消し、元の枚数を保持します。支払いは別の支払元選択から。",Rect2(30,475,880,45),17)
func debug_controls(panel: Control) -> void:
	txt(panel,"デバッグ中。通常セッション・突破記録と別の起動です。\n次の1階だけ置換し、以後は通常表へ戻します。10F置換でボス扱いにしません。",Rect2(30,110,920,100),22)
	for i in 3:
		var kind: String=["event","treasure","enemy"][i]
		action(panel,"次の階："+{"event":"イベント","treasure":"宝箱","enemy":"戦闘"}[kind],Rect2(30+i*310,255,295,60),"debug_next",{"kind":kind})
	txt(panel,"現在の指定："+(game.campaign.debug_next if game.campaign.debug_next!="" else "なし（通常表）"),Rect2(30,342,920,50),21)
	action(panel,"デバッグ専用：いつでも地上へ帰還",Rect2(30,420,920,58),"debug_return")
func cancel_modal() -> void:
	game.service_mode="";game.modal_owner=null;game.ui_block_until=Time.get_ticks_msec()+360;game.call_deferred("show_campaign")
func modal_key(code: int, backwards: bool=false) -> void:
	if code in [KEY_ESCAPE,KEY_X]:call_deferred("cancel_modal")
	elif code==KEY_TAB:
		var nodes: Array=[];collect(self,nodes)
		if nodes.is_empty():return
		var at: int=nodes.find(get_viewport().gui_get_focus_owner());nodes[posmod(at+(-1 if backwards else 1),nodes.size())].grab_focus()
	elif code in [KEY_ENTER,KEY_KP_ENTER]:
		var focused: Control=get_viewport().gui_get_focus_owner()
		if focused is Button and is_ancestor_of(focused) and not focused.disabled:focused.emit_signal("pressed")
func collect(node: Node, nodes: Array) -> void:
	for child in node.get_children():
		if child is Button and not child.disabled:nodes.append(child)
		elif child is SpinBox:nodes.append(child.get_line_edit())
		collect(child,nodes)

func allows_native_key(code: int) -> bool:
	var focused: Control=get_viewport().gui_get_focus_owner()
	if focused is OptionButton: return code in [KEY_UP,KEY_DOWN,KEY_LEFT,KEY_RIGHT,KEY_ENTER,KEY_KP_ENTER,KEY_SPACE]
	if is_instance_valid(amount) and focused==amount.get_line_edit(): return (code>=KEY_0 and code<=KEY_9) or (code>=KEY_KP_0 and code<=KEY_KP_9) or code in [KEY_BACKSPACE,KEY_DELETE,KEY_LEFT,KEY_RIGHT,KEY_HOME,KEY_END,KEY_ENTER,KEY_KP_ENTER]
	return false
