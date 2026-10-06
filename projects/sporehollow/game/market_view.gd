extends RefCounted
## Shop presentation only. World.buy/sell remain the transaction authority.
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
	if p.Category=="animals":return {"shiba":"柴犬","hen":"鶏","cat":"猫"}[row.id]
	return p.Name

static func role(id: String) -> String:
	return {"hen":"朝に卵を産む", "cat":"気ままな仲間", "soil":"土の壁・床に", "wood":"木の壁・床に", "stone":"石の壁・床に", "whistle":"遠くの仲間へ指示", "coffee":"眠気を12軽減", "energy_drink":"眠気を25軽減", "egg":"牧場の生産物", "feather":"鶏の落とし物", "mushroom":"仲間の回復に"}.get(id,"牧場で使う品")

static func description(id: String) -> String:
	return {"hen":"朝に卵を産みます。\n移動の誘導に応じます。攻撃はしません。", "cat":"気ままに牧場を歩きます。\n指示には従いません。", "soil":"土の壁や床を作る資材。", "wood":"木の壁・床・ドアを作る資材。", "stone":"石の壁や床を作る資材。", "whistle":"6マス先まで指示できます。\n対応する仲間を最大8匹、一緒に誘導。\n非消耗。猫は指示に従いません。", "coffee":"眠気を12軽減します。\n飲み物は合計1日2本まで。", "energy_drink":"眠気を25軽減します。\n飲み物は合計1日2本まで。", "egg":"牧場で産まれた卵。", "feather":"鶏が落とした柔らかな羽。", "mushroom":"夜明けに傷ついた仲間を癒します。"}.get(id,"牧場で使う品です。")

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
		if row.get("animal_id",-1)>=0 and world.campaign.animals.size()<=1:return "最後の仲間は売却できません"
	return ""

static func unit(p: Dictionary) -> String:
	return "セット" if p.Category=="materials" else ("匹" if p.Category=="animals" else ("本" if p.ProductID in ["coffee","energy_drink"] else "個"))

static func texture_for(id: String) -> Texture2D:
	if Delivered.RESOURCES.has(id):return Delivered.RESOURCES[id][96]
	if id in ["hen","cat"]:return Art.CLIPS[id+"/idle/right"].frames[0]
	if id=="shiba":return UI.SHIBA[1]
	if id=="whistle":
		# Reuse the existing whistle cursor artwork without its pointer arrow.
		var atlas=AtlasTexture.new();atlas.atlas=UI.cursor("whistle");atlas.region=Rect2(11,11,20,16)
		return atlas
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
		game.add_button(game.palette,"open_market","朝の市",Rect2(377,490,220,46),game.open_market)
		game.buttons.open_market.icon=UI.icon("basket")
		game.add_button(game.palette,"open_book","図鑑を開く",Rect2(725,490,220,46),game.open_book)
		game.buttons.open_book.icon=UI.icon("book")
		button_style(game.buttons.open_market,true);button_style(game.buttons.open_book)
		return
	game.add_button(game.palette,"close_market","メニューへ",MENU,game.close_morning_screen)
	game.buttons.close_market.icon=UI.icon("cross");button_style(game.buttons.close_market)
	game.add_button(game.palette,"shop_back","戻る",BACK,game.market_back)
	button_style(game.buttons.shop_back)
	if game.shop_side=="home":
		for i in range(2):
			var side=["buy","sell"][i]
			game.add_button(game.palette,"shop_"+side,"",Rect2(LEFT+i*384,278,368,300),game.shop_choose.bind(side,"animals"))
			var b=game.buttons["shop_"+side];button_style(b)
			b.draw.connect(draw_choice.bind(game,b,side))
		return
	if game.shop_level=="categories":
		var index=0
		for category in game.MARKET_CATEGORIES:
			game.add_button(game.palette,"category_"+category,"",Rect2(LEFT+(index%2)*384,276+(index/2)*174,368,156),game.choose_category.bind(category))
			var b=game.buttons["category_"+category];button_style(b)
			b.draw.connect(draw_category.bind(game,b,category));index+=1
		return
	if game.shop_level=="detail":
		var row=live_row(game);var p=Shop.table()[row.id]
		game.add_button(game.palette,"confirm_trade",("迎える" if p.Category=="animals" else "買う") if game.shop_side=="buy" else "売る",ACTION,game.trade.bind(row.id,row.animal_id))
		var b=game.buttons.confirm_trade;b.icon=UI.icon("coin");button_style(b,true)
		b.tooltip_text=reason(game.world,game.shop_side,row);b.disabled=b.tooltip_text!=""
		return
	var rows=game.shop_rows()
	for index in range(game.shop_page*4,mini(rows.size(),game.shop_page*4+4)):
		var row=rows[index];var id="trade_"+row.id+"_"+str(row.animal_id)
		game.add_button(game.palette,id,"",Rect2(LEFT+(index%4)*(CARD_WIDTH+CARD_GAP),278,CARD_WIDTH,336),game.inspect_product.bind(row))
		var b=game.buttons[id];button_style(b)
		b.tooltip_text=description(row.id)+"\n"+reason(game.world,game.shop_side,row)
		b.draw.connect(draw_product.bind(game,b,row))
	if rows.size()>4:
		game.add_button(game.palette,"shop_page","次の品へ →",Rect2(938,641,190,40),game.next_shop_page.bind(ceili(rows.size()/4.0)))
		button_style(game.buttons.shop_page)

static func draw_choice(game,b,side: String):
	art(b,"basket" if side=="buy" else "gold",Rect2(138,32,92,92),game)
	text(game,b,Rect2(24,150,320,42),"買う" if side=="buy" else "売る",30,UI.MOSS)
	text(game,b,Rect2(24,201,320,54),"動物・資材・道具を揃える" if side=="buy" else "持ち物を商人に渡す",18,MUTED)
	b.draw_style_box(panel(Color("dce5ca"),Color("b5c19e")),Rect2(24,242,320,36))
	text(game,b,Rect2(38,247,270,28),"品を見る" if side=="buy" else "持ち物を見る",18,UI.MOSS)
	b.draw_texture_rect(UI.icon("next"),Rect2(312,250,18,18),false)

static func draw_category(game,b,category: String):
	var data=game.MARKET_CATEGORIES[category]
	art(b,data[1],Rect2(22,34,72,72),game)
	text(game,b,Rect2(116,24,228,36),data[0],24)
	text(game,b,Rect2(116,65,228,28),data[2],16,MUTED)
	text(game,b,Rect2(116,103,228,28),category_status(game,category),17,MUTED)

static func draw_product(game,b,row: Dictionary):
	art(b,row.id,Rect2(22,22,CARD_WIDTH-44,126),game)
	var title=product_name(row)
	if row.animal_id>=0:title=game.product_title(row).split(" Lv")[0]
	text(game,b,Rect2(18,166,CARD_WIDTH-36,55),title,20)
	var subtitle="Lv%d · "%row.get("lv",1) if Shop.table()[row.id].Category=="animals" else ""
	text(game,b,Rect2(18,224,CARD_WIDTH-36,38),subtitle+role(row.id),15,MUTED)
	var p=Shop.table()[row.id]
	price(game,b,Vector2(18,267),p.BuyPrice if game.shop_side=="buy" else p.SellPrice,24)
	var why=reason(game.world,game.shop_side,row)
	var status=why if why!="" else ("在庫 %d%s"%[row.count,unit(p)] if game.shop_side=="buy" else "売却可能 %d%s"%[row.count,unit(p)])
	if game.shop_side=="sell" and p.Category=="materials" and row.count==0 and owned(game.world,row)>0:
		status="あと%s%d"%[product_name(row).split(" ×")[0],p.Amount-owned(game.world,row)]
	text(game,b,Rect2(18,300,CARD_WIDTH-36,34),status,14,UI.DANGER if why!="" else MUTED)

static func draw(game):
	var c=game.hud
	if game.morning_screen=="morning":
		c.draw_style_box(panel(PAPER,UI.WOOD,3),Rect2(330,112,656,444))
		text(game,c,Rect2(368,138,400,44),"%d日目の朝"%game.world.campaign.day,26)
		price(game,c,Vector2(818,141),game.world.campaign.gold,24)
		c.draw_line(Vector2(368,189),Vector2(948,189),Color("c5b590"),1)
		text(game,c,Rect2(377,206,240,38),"朝の市",23)
		text(game,c,Rect2(725,206,240,38),"牧場の仲間",23)
		Art.fit(c,Art.CART,Rect2(346,245,310,222))
		Art.fit(c,Art.CLOSED,Rect2(748,235,176,220))
		return
	c.draw_rect(Rect2(0,0,1280,800),Color(0.13,0.18,0.17,0.65))
	c.draw_style_box(panel(Color("7c6349"),Color("564736"),3),Rect2(100,98,1080,610))
	c.draw_style_box(panel(PAPER,Color("cfbd98"),1),Rect2(112,110,1056,582))
	for i in range(17):c.draw_rect(Rect2(114+i*62,110,62,10),Color("cdb584") if i%2==0 else Color("809880"))
	text(game,c,Rect2(140,135,370,46),"朝の市",34)
	price(game,c,Vector2(728,143),game.world.campaign.gold,26)
	c.draw_line(Vector2(140,195),Vector2(1140,195),Color("c5b590"),1)
	Art.fit(c,Art.CART,Rect2(128,313,220,192))
	text(game,c,Rect2(148,535,196,42),game.world.Story.merchant(game.world) if game.world.story.hidden.recognition>0 else ("いらっしゃい" if game.shop_side!="sell" else "持ち物を見せてね"),16,MUTED)
	var crumb="商人との取引" if game.shop_side=="home" else ("買う" if game.shop_side=="buy" else "売る")+"  /  "+(("今日の品" if game.shop_side=="buy" else "持ち物") if game.shop_level=="categories" else game.MARKET_CATEGORIES[game.shop_category][0])
	text(game,c,Rect2(LEFT,222,750,38),crumb,21)
	if game.shop_level=="list" and game.shop_side!="home" and game.shop_rows().is_empty():
		art(c,game.MARKET_CATEGORIES[game.shop_category][1],Rect2(LEFT+32,318,88,88),game)
		text(game,c,Rect2(LEFT+148,328,550,72),empty_message(game,game.shop_category),23)
		text(game,c,Rect2(LEFT+148,417,550,56),"ほかのカテゴリは「戻る」から確認できます。",17,MUTED)
	if game.shop_side!="home" and game.shop_level=="detail":draw_detail(game)

static func draw_detail(game):
	var c=game.hud;var row=live_row(game);var p=Shop.table()[row.id]
	var buying=game.shop_side=="buy"
	var cost=p.BuyPrice if buying else p.SellPrice
	var title=product_name(row) if row.animal_id<0 else game.product_title(row)
	text(game,c,Rect2(LEFT,268,752,44),title,28)
	c.draw_style_box(panel(Color("e3e6cd"),Color("d1d6bb")),Rect2(LEFT,320,212,204))
	art(c,row.id,Rect2(LEFT+36,350,140,142),game)
	text(game,c,Rect2(616,322,510,80),description(row.id),18)
	var quantity="店の在庫：%d%s"%[row.count,unit(p)] if buying else "売却可能：%d%s"%[row.count,unit(p)]
	var own="所持：%s %d%s"%[product_name({"id":row.id}).split(" ×")[0],owned(game.world,row),"匹" if p.Category=="animals" else ""]
	var one="1回の%s：%s"%["購入" if buying else "売却",product_name(row)+(" ×1" if p.Amount==1 else "")]
	text(game,c,Rect2(616,422,512,24),one,17)
	text(game,c,Rect2(616,452,512,24),quantity+"　／　"+own,17,MUTED)
	price(game,c,Vector2(616,496),cost,28)
	var why=reason(game.world,game.shop_side,row)
	var after=game.world.campaign.gold+(-cost if buying else cost)
	text(game,c,Rect2(LEFT,561,486,28),"所持金 %dG → %s %dG"%[game.world.campaign.gold,"購入後" if buying else "売却後",after] if why=="" else "所持金 %dG"%game.world.campaign.gold,20)
	text(game,c,Rect2(LEFT,596,486,36),why,17,UI.DANGER)
	if game.shop_notice!="":
		c.draw_style_box(panel(Color("dce5ca"),Color("9dac88")),Rect2(LEFT,642,752,38))
		text(game,c,Rect2(LEFT+14,650,724,28),game.shop_notice,17,UI.INK)
