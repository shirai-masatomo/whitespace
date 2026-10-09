extends RefCounted
## Shop presentation only. World.buy/sell remain the transaction authority.
const Assets=preload("res://game/ui_assets.gd")
const UI = preload("res://game/ui_style.gd")
const Art = preload("res://game/adopted_art.gd")
const Delivered = preload("res://game/delivered_art.gd")
const Shop = preload("res://game/shop_table.gd")
const PAPER = Color("f1e7cf")
const MUTED = Color("697563")
const LEFT = 376.0
const CARD_WIDTH = 176.0
const CARD_GAP = 16.0
const BACK = Rect2(876,132,112,44)
const MENU = Rect2(1000,132,152,44)
const ACTION = Rect2(880,566,248,50)
const LIST = Rect2(LEFT,252,752,336)
const FOOTER = Rect2(LEFT,624,752,140)
const SCROLL_STEP = 80.0
const ROW_HEIGHT = 72.0
const ROW_PITCH = 80.0
const SPEECH_A=preload("res://assets/ui/merchant_bubble_a.png")
const TRADE_CANDIDATE=preload("res://assets/ui/trial_buy_sell.png")
static var image_regions: Dictionary = {}
static var missing_reported: Dictionary = {}

static func panel(color: Color=PAPER, edge: Color=Color("b6ac8e"), width: int=1) -> StyleBoxFlat:
	var box=StyleBoxFlat.new()
	box.bg_color=color;box.border_color=edge;box.set_border_width_all(width)
	box.set_corner_radius_all(2)
	box.shadow_color=Color(0.16,0.17,0.10,0.13);box.shadow_size=3;box.shadow_offset=Vector2(0,3)
	box.content_margin_left=18;box.content_margin_right=18
	return box

static func button_style(button: Button, primary: bool=false):
	var base=UI.MOSS if primary else PAPER
	button.add_theme_stylebox_override("normal",panel(base,UI.WOOD if primary else Color("b6ac8e"),2 if primary else 1))
	button.add_theme_stylebox_override("hover",panel(base.lightened(0.09),UI.MOSS,2))
	button.add_theme_stylebox_override("pressed",panel(base.darkened(0.08),UI.WOOD,2))
	button.add_theme_stylebox_override("disabled",panel(Color("dfd9c7")))
	button.add_theme_stylebox_override("focus",panel(Color(0,0,0,0),UI.GOLD,2))
	for state in ["font_color","font_hover_color","font_pressed_color"]:
		button.add_theme_color_override(state,Color("fff5db") if primary else UI.INK)
	button.add_theme_color_override("font_disabled_color",MUTED)
	button.add_theme_font_size_override("font_size",20)

static func product_name(row: Dictionary) -> String:
	var p=Shop.table()[row.id]
	if p.Category=="materials":return {"soil":"土","wood":"木材","stone":"石"}[row.id]+" ×%d"%p.Amount
	if p.Category=="animals":return Shop.Animals.SPECIES[row.id].title
	return p.Name

static func role(id: String) -> String:
	if Shop.Animals.SPECIES.has(id):return Shop.Animals.short_description(id)
	return {"kokeshi":"周囲3マスの敵味方の移動を0.8倍。現地設置・回収。","fossil":"飾って回収できる化石。盗賊に注意。復活機能は未実装。","milk":"現地で搾乳したミルク。1個6Gで売却できます。","doberman":"屋外で強く迎撃","bullfrog":"舌拘束と警報","hedgehog":"被弾と警報で迎撃","collar":"犬の忠誠・防御を補助","berry":"ピンチで一度回復","hen":"朝に卵を産む", "cat":"気ままな仲間", "soil":"土の壁・床に", "wood":"木の壁・床に", "stone":"石の壁・床に", "whistle":"遠くの仲間へ指示", "coffee":"眠気を12軽減", "energy_drink":"眠気を25軽減", "egg":"牧場の生産物", "feather":"鶏の落とし物", "mushroom":"仲間の回復に"}.get(id,"牧場で使う品")

static func description(id: String) -> String:
	if Shop.Animals.SPECIES.has(id):return Shop.Animals.character_text(id)
	return {"kokeshi":"周囲3マスの敵味方の移動を0.8倍。現地設置・回収。","fossil":"飾って回収できる化石。盗賊に注意。復活機能は未実装。","milk":"現地で搾乳したミルク。1個6Gで売却できます。","doberman":"屋外専用の自律迎撃犬。救出本能はありません。", "bullfrog":"舌で敵の移動を止め、被弾すると警報を共有。", "hedgehog":"被弾や共有情報に反応して迎撃。棘で防御します。", "collar":"犬系の忠誠+25、防御+2。非消耗。現地で装備。", "berry":"生存中HP50%以下で消費し、最大HPの1/4回復。", "hen":"朝に卵を産みます。\n移動の誘導に応じます。攻撃はしません。", "cat":"気ままに牧場を歩きます。\n指示には従いません。", "soil":"土の壁や床を作る資材。", "wood":"木の壁・床・ドアを作る資材。", "stone":"石の壁や床を作る資材。", "whistle":"6マス先まで指示できます。\n対応する仲間を最大8匹、一緒に誘導。\n非消耗。猫は指示に従いません。", "coffee":"眠気を12軽減します。\n飲み物は合計1日2本まで。", "energy_drink":"眠気を25軽減します。\n飲み物は合計1日2本まで。", "egg":"牧場で産まれた卵。", "feather":"鶏が落とした柔らかな羽。", "mushroom":"夜明けに傷ついた仲間を癒します。"}.get(id,"牧場で使う品です。")

static func owned(world, row: Dictionary) -> int:
	var p=Shop.table()[row.id]
	if p.Category=="materials":return world.resource_amount(row.id)
	if p.Category=="animals":return world.campaign.animals.filter(func(a):return a.species==row.id).size()
	return world.item_count(row.id)

static func reason(world, side: String, row: Dictionary) -> String:
	var p=Shop.table()[row.id]
	if side=="buy":
		if row.count<=0:return "売り切れ"
		if world.campaign.gold<p.BuyPrice:return "あと%dG"%(p.BuyPrice-world.campaign.gold)
	else:
		if row.count<=0:
			if p.Category=="materials" and owned(world,row)>0:return "売却には%sが必要"%product_name(row)
			return "売却できる分はありません"
		if row.id=="maid":return "仲間は売却できません"
		if row.get("animal_id",-1)>=0 and world.campaign.animals.size()<=1:return "最後の仲間は売却できません"
	return ""

static func unit(p: Dictionary) -> String:
	if p.ProductID=="maid":return "人"
	return "セット" if p.Category=="materials" else ("匹" if p.Category=="animals" else ("本" if p.ProductID in ["coffee","energy_drink"] else "個"))

static func texture_for(id: String) -> Texture2D:
	if id in ["buy","sell"]:
		var atlas=AtlasTexture.new();atlas.atlas=TRADE_CANDIDATE;atlas.region=Rect2(0 if id=="buy" else 1028,0,1028,764)
		return atlas
	if Assets.texture(id):return Assets.texture(id)
	if Delivered.RESOURCES.has(id):return Delivered.RESOURCES[id][96]
	if id in ["hen","cat"]:return Art.CLIPS[id+"/idle/right"].frames[0]
	if id=="shiba":return UI.SHIBA[1]
	if id=="whistle":
		# Reuse the existing whistle cursor artwork without its pointer arrow.
		var atlas=AtlasTexture.new();atlas.atlas=UI.cursor("whistle");atlas.region=Rect2(11,11,20,16)
		return atlas
	if id=="milk":return UI.icon("basket")
	if id in ["hammer","basket","animals","buy","sell"]:
		return UI.icon({"animals":"paw","buy":"basket","sell":"coin"}.get(id,id))
	return null

static func art(c: CanvasItem, id: String, area: Rect2, game):
	c.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	var texture=texture_for(id)
	if texture:
		if not image_regions.has(id):
			var image=texture.get_image()
			image_regions[id]=Rect2(image.get_used_rect()) if image else Rect2()
		var region: Rect2=image_regions[id]
		if region.has_area():
			var ratio=minf(area.size.x/region.size.x,area.size.y/region.size.y)
			var size=region.size*ratio
			c.draw_texture_rect_region(texture,Rect2((area.get_center()-size*0.5).round(),size.round()),region)
			return
	# Existing in-game small-object drawings; no regenerated artwork.
	var bounds={"coffee":Rect2(-29,-12,59,40),"energy_drink":Rect2(-15,-22,30,47),"egg":Rect2(-15,-15,30,30),"feather":Rect2(-17,-25,36,45),"mushroom":Rect2(-24,-24,48,48)}
	if bounds.has(id):
		var b: Rect2=bounds[id]
		var scale_value=minf(area.size.x/b.size.x,area.size.y/b.size.y)
		game.draw_card_icon(c,id,area.get_center()-b.get_center()*scale_value,scale_value)
		return
	if not missing_reported.has(id):
		push_warning("Market artwork unavailable: "+id);missing_reported[id]=true
	c.draw_texture_rect(UI.icon("basket"),Rect2(area.get_center()-Vector2(20,20),Vector2(40,40)),false)
	game.label_on(c,area.position+Vector2(0,area.size.y),"画像準備中",14,UI.DANGER)

static func text(game,c,area: Rect2,value: String,size: int=18,color: Color=UI.INK):
	# CJK-friendly wrapping without shrinking long names.
	var paragraph=TextParagraph.new()
	paragraph.add_string(value,game.FONT,size)
	paragraph.width=area.size.x
	paragraph.break_flags=TextServer.BREAK_MANDATORY|TextServer.BREAK_WORD_BOUND|TextServer.BREAK_ADAPTIVE
	paragraph.draw(c.get_canvas_item(),area.position,color)

static func speech_layout(game,area: Rect2,value: String,font_size: int) -> Dictionary:
	var paragraph=TextParagraph.new()
	paragraph.add_string(value,game.FONT,font_size)
	paragraph.width=maxf(80,area.size.x-40)
	paragraph.break_flags=TextServer.BREAK_MANDATORY|TextServer.BREAK_WORD_BOUND|TextServer.BREAK_ADAPTIVE
	paragraph.alignment=HORIZONTAL_ALIGNMENT_CENTER
	var body=Vector2(minf(area.size.x,maxf(150,paragraph.get_size().x+40)),maxf(60,paragraph.get_size().y+28))
	return {"paragraph":paragraph,"body":Rect2(Vector2(area.get_center().x-body.x/2,area.position.y),body)}

static func speech_bubble(game,c,area: Rect2,value: String,font_size: int,tail_up: bool=false):
	var layout=speech_layout(game,area,value,font_size)
	var body: Rect2=layout.body
	# Original RGBA remains intact. Corners and tail retain a uniform 0.14 scale.
	# Extra fixed column protects the tail from the horizontal nine-slice stretch.
	var scale_value=0.14
	var sx=[37.0,240.0,535.0,665.0,1940.0,2140.0]
	var sy=[96.0,240.0,390.0,632.0]
	var left=(sx[1]-sx[0])*scale_value;var right=(sx[5]-sx[4])*scale_value
	var tail_width=(sx[3]-sx[2])*scale_value
	var tail_x=clampf(body.size.x*0.30,left+4,body.size.x-right-tail_width-4)
	var dx=[0.0,left,tail_x,tail_x+tail_width,body.size.x-right,body.size.x]
	var dy=[0.0,(sy[1]-sy[0])*scale_value,body.size.y-(550.0-sy[2])*scale_value,body.size.y+(sy[3]-550.0)*scale_value]
	var previous=c.texture_filter
	c.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR
	c.draw_set_transform(body.position+Vector2(0,body.size.y) if tail_up else body.position,0,Vector2(1,-1) if tail_up else Vector2.ONE)
	for y in range(3):
		for x in range(5):
			var region=Rect2(sx[x],sy[y],sx[x+1]-sx[x],sy[y+1]-sy[y])
			var dest=Rect2(Vector2(dx[x],dy[y]),Vector2(dx[x+1]-dx[x],dy[y+1]-dy[y]))
			c.draw_texture_rect_region(SPEECH_A,dest,region)
	c.draw_set_transform(Vector2.ZERO)
	c.texture_filter=previous
	var paragraph: TextParagraph=layout.paragraph
	paragraph.draw(c.get_canvas_item(),Vector2(body.get_center().x-paragraph.width/2,body.get_center().y-paragraph.get_size().y/2).round(),UI.INK)

static func merchant(game,c,area: Rect2):
	art_texture(c,Art.CART,area)

static func list_title(game) -> String:
	return "持ち物一覧" if game.shop_side=="sell" else "商品一覧"

static func hover_product(game,row: Dictionary):
	game.set_meta("market_hover",row.duplicate())
	game.set_meta("market_skill",-1)
	game.hud.queue_redraw()

static func hover_skill(game,index: int):
	game.set_meta("market_skill",index)
	game.hud.queue_redraw()

static func focus_product(game,row: Dictionary,index: int):
	hover_product(game,row)
	if not game.palette.has_node("MarketScroll"):return
	var bar=game.palette.get_node("MarketScroll")
	var x=index*ROW_PITCH
	if x<bar.value:bar.value=x
	elif x+ROW_HEIGHT>bar.value+bar.page:bar.value=x+ROW_HEIGHT-bar.page

static func skill_rows(game,row: Dictionary) -> Array:
	if not Shop.Animals.SPECIES.has(row.get("id","")):return []
	var a=individual(game,row).duplicate()
	a.species=row.id;a.lv=a.get("lv",row.get("lv",1))
	return game.Journal.animal_skills(game,a).filter(func(skill):return not skill.locked)

static func hovered_row(game) -> Dictionary:
	var rows=game.shop_rows()
	var hovered=game.get_meta("market_hover",{})
	for row in rows:
		if row.id==hovered.get("id","") and row.animal_id==hovered.get("animal_id",-2):return row
	return rows[0] if not rows.is_empty() else {}

static func move_list(game,content: Control,value: float):
	game.set_meta("market_scroll",value)
	content.position.y=-value
	game.hud.queue_redraw()

static func scroll_ui(game,event: InputEvent) -> bool:
	if not event is InputEventMouseButton or event.button_index not in [MOUSE_BUTTON_WHEEL_UP,MOUSE_BUTTON_WHEEL_DOWN,MOUSE_BUTTON_WHEEL_LEFT,MOUSE_BUTTON_WHEEL_RIGHT]:return false
	if game.world.phase!="shop" or game.morning_screen!="market":return false
	# Consume every market wheel event, including limits/empty lists. Never leak into field modes.
	if game.story_modal!="" or game.menu_open:return true
	if event.pressed and game.shop_level=="list" and game.shop_side!="home" and game.palette.has_node("MarketScroll"):
		var bar=game.palette.get_node("MarketScroll")
		var direction=-1 if event.button_index in [MOUSE_BUTTON_WHEEL_UP,MOUSE_BUTTON_WHEEL_LEFT] else 1
		bar.value+=direction*SCROLL_STEP*maxf(1.0,event.factor)
	return true

static func build_list(game):
	var rows=game.shop_rows();var key=game.shop_side+"/"+game.shop_category
	if game.get_meta("market_list_key","")!=key:
		game.set_meta("market_scroll",0.0);game.set_meta("market_hover",{});game.set_meta("market_skill",-1)
	game.set_meta("market_list_key",key)
	var viewport=Control.new();viewport.name="MarketList";viewport.position=LIST.position;viewport.size=LIST.size
	viewport.clip_contents=true;viewport.mouse_filter=Control.MOUSE_FILTER_PASS;game.palette.add_child(viewport)
	var content=Control.new();content.name="Cards";content.mouse_filter=Control.MOUSE_FILTER_IGNORE;viewport.add_child(content)
	for index in range(rows.size()):
		var row=rows[index];var id="trade_"+row.id+"_"+str(row.animal_id)
		game.add_button(content,id,"",Rect2(0,index*ROW_PITCH,LIST.size.x-24,ROW_HEIGHT),game.inspect_product.bind(row))
		var b=game.buttons[id];button_style(b);b.focus_mode=Control.FOCUS_ALL
		b.draw.connect(draw_product.bind(game,b,row))
		b.mouse_entered.connect(hover_product.bind(game,row));b.focus_entered.connect(focus_product.bind(game,row,index))
	var total=maxf(LIST.size.y,rows.size()*ROW_PITCH-8)
	var bar=VScrollBar.new();bar.name="MarketScroll";bar.position=Vector2(LIST.end.x-18,LIST.position.y);bar.size=Vector2(18,LIST.size.y)
	bar.min_value=0;bar.max_value=total;bar.page=LIST.size.y;bar.step=1;bar.value=clampf(game.get_meta("market_scroll",0.0),0,total-LIST.size.y)
	bar.visible=total>LIST.size.y;bar.mouse_filter=Control.MOUSE_FILTER_STOP
	bar.add_theme_stylebox_override("scroll",panel(Color("d6c6a0"),Color("927e59")))
	for state in ["grabber","grabber_highlight","grabber_pressed"]:bar.add_theme_stylebox_override(state,panel(UI.MOSS,UI.WOOD,1))
	game.palette.add_child(bar)
	bar.value_changed.connect(func(value):move_list(game,content,value))
	move_list(game,content,bar.value)
	for i in range(4):build_skill_hover(game,i)

static func build_skill_hover(game,index: int):
	game.add_button(game.palette,"market_skill_%d"%index,"",Rect2(LEFT+100+index*160,724,156,32),func():pass)
	var b=game.buttons["market_skill_%d"%index]
	for state in ["normal","hover","pressed","focus"]:b.add_theme_stylebox_override(state,StyleBoxEmpty.new())
	b.mouse_entered.connect(hover_skill.bind(game,index));b.mouse_exited.connect(hover_skill.bind(game,-1))
	b.focus_entered.connect(hover_skill.bind(game,index));b.focus_exited.connect(hover_skill.bind(game,-1))

static func price(game,c,p: Vector2,amount: int,size: int=25):
	c.draw_texture_rect(UI.icon("coin"),Rect2(p+Vector2(0,2),Vector2(24,24)),false)
	text(game,c,Rect2(p+Vector2(32,0),Vector2(160,38)),"%d G"%amount,size)

static func live_row(game) -> Dictionary:
	var row=game.product_row.duplicate()
	var matches=game.shop_rows().filter(func(r):return r.id==row.id and r.animal_id==row.animal_id)
	row.count=matches[0].count if not matches.is_empty() else 0
	return row

static func empty_message(game, category: String) -> String:
	if game.shop_side=="buy":return "今日はこの品の入荷がありません。"
	if category=="animals":return "売却できる仲間はいません。"
	return "売れる品を持っていません。"

static func category_status(game, category: String) -> String:
	var rows=game.shop_rows(category)
	if rows.is_empty():return "入荷なし" if game.shop_side=="buy" else "売却対象なし"
	if rows.all(func(row):return row.count<=0):return "売り切れ" if game.shop_side=="buy" else "必要数量が足りません"
	return "%d種類"%rows.size()

static func build(game):
	if game.morning_screen=="morning":
		game.set_meta("market_list_key","")
		game.add_button(game.palette,"open_market","商品一覧",Rect2(377,465,220,40),game.open_market)
		game.buttons.open_market.icon=UI.icon("basket")
		game.add_button(game.palette,"open_book","図鑑を開く",Rect2(725,465,220,40),game.open_book)
		game.buttons.open_book.icon=UI.icon("book")
		button_style(game.buttons.open_market,true);button_style(game.buttons.open_book)
		if game.Farm.Progression.Encounters.reached(game.world.campaign):
			if game.restart_confirm:
				game.add_button(game.palette,"route_restart_yes","新しい牧場を始める",Rect2(376,576,256,36),game.new_campaign)
				game.add_button(game.palette,"route_restart_cancel","今の牧場へ戻る",Rect2(710,576,236,36),game.confirm_new_campaign.bind(false))
			else:game.add_button(game.palette,"route_restart","新しく始める…",Rect2(710,576,236,36),game.confirm_new_campaign.bind(true))
		return
	game.add_button(game.palette,"close_market","メニューへ",MENU,game.close_morning_screen)
	game.buttons.close_market.icon=UI.icon("cross");button_style(game.buttons.close_market)
	game.add_button(game.palette,"shop_back","戻る",BACK,game.market_back)
	button_style(game.buttons.shop_back)
	if game.shop_side=="home":
		game.set_meta("market_list_key","")
		for i in range(2):
			var side=["buy","sell"][i]
			game.add_button(game.palette,"shop_"+side,"",Rect2(724,302+i*151,380,127),game.shop_choose.bind(side,"animals"))
			var b=game.buttons["shop_"+side];button_style(b)
			b.draw.connect(draw_choice.bind(game,b,side))
		return
	if game.shop_level=="categories":
		game.set_meta("market_list_key","")
		var index=0
		for category in game.MARKET_CATEGORIES:
			game.add_button(game.palette,"category_"+category,"",Rect2(LEFT+(index%2)*384,276+(index/2)*174,368,156),game.choose_category.bind(category))
			var b=game.buttons["category_"+category];button_style(b)
			b.draw.connect(draw_category.bind(game,b,category));index+=1
		return
	if game.shop_level=="detail":
		var row=live_row(game);var p=Shop.table()[row.id]
		hover_product(game,row)
		game.add_button(game.palette,"confirm_trade",("迎える" if p.Category=="animals" else "買う") if game.shop_side=="buy" else "売る",ACTION,game.trade.bind(row.id,row.animal_id))
		var b=game.buttons.confirm_trade;b.icon=UI.icon("coin");button_style(b,true)
		b.tooltip_text=reason(game.world,game.shop_side,row);b.disabled=b.tooltip_text!=""
		game.add_button(game.palette,"cancel_trade","やめる",Rect2(616,566,248,50),game.market_back)
		button_style(game.buttons.cancel_trade)
		for i in range(4):build_skill_hover(game,i)
		return
	build_list(game)

static func draw_choice(game,b,side: String):
	art(b,side,Rect2(24,25,72,72),game)
	text(game,b,Rect2(122,26,225,36),"買う" if side=="buy" else "売る",28,UI.MOSS)
	text(game,b,Rect2(122,76,230,28),"牧場の品を探す" if side=="buy" else "持ち物を見せる",17,MUTED)
	b.draw_texture_rect(UI.icon("next"),Rect2(341,42,20,20),false)

static func draw_category(game,b,category: String):
	var data=game.MARKET_CATEGORIES[category]
	art(b,Assets.CATEGORY.get(category,data[1]),Rect2(22,34,72,72),game)
	text(game,b,Rect2(116,24,228,36),data[0],24)
	text(game,b,Rect2(116,65,228,28),data[2],16,MUTED)
	text(game,b,Rect2(116,103,228,28),category_status(game,category),17,MUTED)

static func draw_product(game,b,row: Dictionary):
	art(b,row.id,Rect2(12,7,58,58),game)
	var p=Shop.table()[row.id];var title=product_name(row) if row.animal_id<0 else game.product_title(row).split(" Lv")[0]
	text(game,b,Rect2(86,9,365,30),title,21)
	var why=reason(game.world,game.shop_side,row)
	var status=why if why!="" else ("" if p.Category=="animals" else ("在庫 %d%s" if game.shop_side=="buy" else "売却可能 %d%s")%[row.count,unit(p)])
	text(game,b,Rect2(86,42,430,23),status,15,UI.DANGER if why!="" else MUTED)
	price(game,b,Vector2(536,20),p.BuyPrice if game.shop_side=="buy" else p.SellPrice,24)
	if game.shop_side=="buy" and row.count<=0:
		b.draw_line(Vector2(14,60),Vector2(68,12),Color("987b6b"),4,true)
		b.draw_line(Vector2(14,12),Vector2(68,60),Color("987b6b"),4,true)

static func draw(game):
	var c=game.hud
	if game.morning_screen=="morning":
		c.draw_style_box(panel(PAPER,UI.WOOD,3),game.StoryView.morning_layout(game).paper)
		price(game,c,Vector2(818,141),game.world.campaign.gold,24)
		speech_bubble(game,c,Rect2(348,190,314,62),"いらっしゃい、何か見ていくかい？",16)
		merchant(game,c,Rect2(367,263,257,190))
		Art.fit(c,Art.CLOSED,Rect2(762,250,150,210))
		if game.restart_confirm:text(game,c,Rect2(368,523,580,26),"新しく始めると、この牧場での進行は終了します",17,UI.DANGER)
		return
	c.draw_rect(Rect2(0,0,1280,800),Color(0.13,0.18,0.17,0.65))
	c.draw_style_box(panel(Color("7c6349"),Color("564736"),3),Rect2(100,98,1080,684))
	c.draw_style_box(panel(PAPER,Color("cfbd98"),1),Rect2(112,110,1056,660))
	for i in range(17):c.draw_rect(Rect2(114+i*62,110,62,10),Color("cdb584") if i%2==0 else Color("809880"))
	text(game,c,Rect2(140,135,370,46),list_title(game),34)
	price(game,c,Vector2(728,143),game.world.campaign.gold,26)
	c.draw_line(Vector2(140,195),Vector2(1140,195),Color("c5b590"),1)
	if game.shop_side=="home":
		merchant(game,c,Rect2(160,300,498,300))
		speech_bubble(game,c,Rect2(205,215,388,66),"いらっしゃい、何か見ていくかい？",21)
	else:
		merchant(game,c,Rect2(128,313,220,192))
		speech_bubble(game,c,Rect2(138,523,204,67),"いらっしゃい" if game.shop_side=="buy" else "持ち物を見せてね",18,true)
		var crumb="買う" if game.shop_side=="buy" else "売る"
		if game.shop_level!="categories":crumb+=" / "+game.MARKET_CATEGORIES[game.shop_category][0]
		text(game,c,Rect2(LEFT,211,450,30),crumb,17,MUTED)
	if game.shop_level=="list" and game.shop_side!="home" and game.shop_rows().is_empty():
		art(c,game.MARKET_CATEGORIES[game.shop_category][1],Rect2(LEFT+32,318,88,88),game)
		text(game,c,Rect2(LEFT+148,328,550,72),empty_message(game,game.shop_category),23)
		text(game,c,Rect2(LEFT+148,417,550,56),"ほかのカテゴリは「戻る」から確認できます。",17,MUTED)
	if game.shop_side!="home" and game.shop_level=="detail":draw_detail(game)
	if game.shop_side!="home" and game.shop_level=="list":draw_footer(game)

static func draw_footer(game):
	var c=game.hud;var row=live_row(game) if game.shop_level=="detail" else hovered_row(game)
	if row.is_empty():return
	c.draw_style_box(panel(Color("e9e7cd"),Color("b4aa87"),2),FOOTER)
	var skills=skill_rows(game,row);var index=int(game.get_meta("market_skill",-1))
	var title=product_name(row);var detail=description(row.id)
	if index>=0 and index<skills.size():
		var skill=skills[index];var lines=skill.tooltip.split("\n")
		title=lines[0];detail=" / ".join(lines.slice(2))
		text(game,c,Rect2(LEFT+16,636,720,26),title,21,UI.MOSS)
		text(game,c,Rect2(LEFT+16,670,720,52),detail,16)
	else:
		art(c,row.id,Rect2(LEFT+16,642,54,58),game)
		text(game,c,Rect2(LEFT+84,636,638,26),title,21,UI.MOSS)
		text(game,c,Rect2(LEFT+84,670,638,52),detail,16)
	if not skills.is_empty():text(game,c,Rect2(LEFT+16,730,84,24),"所持スキル",14,MUTED)
	for i in range(mini(skills.size(),4)):
		var x=LEFT+100+i*160
		c.draw_texture_rect(Assets.skill_texture(skills[i].id),Rect2(x,725,30,30),false)
		text(game,c,Rect2(x+37,729,116,27),skills[i].tooltip.split("\n")[0],14,UI.MOSS if i==index else UI.INK)
	var rows=game.shop_rows();var count=rows.size()
	if game.shop_level=="list" and count>4:
		var offset=float(game.get_meta("market_scroll",0.0));var maximum=count*ROW_PITCH-8-LIST.size.y
		var more="↑ 前の商品" if offset>=maximum else "下に続く ↓" if offset<=0 else "↑ 前の商品　下に続く ↓"
		text(game,c,Rect2(814,211,314,28),more,15,UI.MOSS)

static func draw_detail(game):
	var c=game.hud;var row=live_row(game);var p=Shop.table()[row.id]
	var buying=game.shop_side=="buy"
	var cost=p.BuyPrice if buying else p.SellPrice
	var title=product_name(row) if row.animal_id<0 else game.product_title(row)
	text(game,c,Rect2(LEFT,260,752,32),"この仲間を迎えますか？" if buying and p.Category=="animals" else "この商品を買いますか？" if buying else "この持ち物を売りますか？",23,UI.MOSS)
	text(game,c,Rect2(616,314,510,44),title,28)
	c.draw_style_box(panel(Color("e3e6cd"),Color("d1d6bb")),Rect2(LEFT,310,212,188))
	art(c,row.id,Rect2(LEFT+36,332,140,142),game)
	if p.Category=="animals":text(game,c,Rect2(616,360,510,25),rarity_label(game,row)+bonus_label(game,row),15,MUTED)
	var quantity=("店の在庫：%d%s"%[row.count,unit(p)] if buying else "売却可能：%d%s"%[row.count,unit(p)]) if p.Category!="animals" else ""
	var own="所持：%s %d%s"%[product_name({"id":row.id}).split(" ×")[0],owned(game.world,row),"匹" if p.Category=="animals" else ""]
	var one="1回の%s：%s"%["購入" if buying else "売却",product_name(row)+(" ×1" if p.Amount==1 else "")]
	text(game,c,Rect2(616,397,512,24),one,17)
	text(game,c,Rect2(616,427,512,24),(quantity+"　／　" if quantity!="" else "")+own,17,MUTED)
	price(game,c,Vector2(616,465),cost,28)
	var why=reason(game.world,game.shop_side,row)
	var after=game.world.campaign.gold+(-cost if buying else cost)
	c.draw_style_box(panel(Color("dfd4b5"),Color("c4b28b")),Rect2(LEFT,514,752,40))
	text(game,c,Rect2(LEFT+20,520,716,28),"所持金 %dG → %s %dG"%[game.world.campaign.gold,"購入後" if buying else "売却後",after] if why=="" else "所持金 %dG　／　%s"%[game.world.campaign.gold,why],20,UI.INK if why=="" else UI.DANGER)
	draw_footer(game)
	if game.shop_notice!="":
		c.draw_style_box(panel(Color("dce5ca"),Color("9dac88")),Rect2(136,626,208,136))
		text(game,c,Rect2(148,639,184,110),game.shop_notice,16,UI.INK)

static func individual(game,row) -> Dictionary:
	if row.get("animal_id",-1)>=0:
		for a in game.world.campaign.animals:
			if a.id==row.animal_id:return a
	for item in game.world.shop_stock:
		if item.product==row.id:return item.individual
	return {}

static func rarity_label(game,row) -> String:
	return Shop.Data.RARITY_NAMES[Shop.Data.rarity(individual(game,row).get("rarity",0))]

static func bonus_label(game,row) -> String:
	return " / 丈夫：最大HP+4" if "hardy" in individual(game,row).get("bonus_skills",[]) else ""

static func art_texture(c: CanvasItem,t: Texture2D,area: Rect2):
	var rect=Rect2(t.get_image().get_used_rect())
	var size=rect.size*minf(area.size.x/rect.size.x,area.size.y/rect.size.y)
	c.draw_texture_rect_region(t,Rect2((area.get_center()-size/2).round(),size.round()),rect)
