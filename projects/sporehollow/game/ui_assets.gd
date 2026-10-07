extends RefCounted
## UI AssetIDs are independent of world animation. Empty portrait = nearest world fallback.
const Art=preload("res://game/adopted_art.gd")
const UI=preload("res://game/ui_style.gd")
const Delivered=preload("res://game/delivered_art.gd")
const PORTRAITS={} # animal/<id>/portrait_ui or enemy/<id>/portrait_ui -> approved resource path.
const STATIC={
	"destroyer":preload("res://assets/adopted_ui/destroyer.png"),
	"martial_artist":preload("res://assets/adopted_ui/martial_artist.png"),
	"salaryman":preload("res://assets/adopted_ui/salaryman.png"),
	"ninja":preload("res://assets/adopted_ui/ninja.png"),
	"animal_tamer":preload("res://assets/adopted_ui/animal_tamer.png"),
	"runner":preload("res://assets/adopted_ui/runner.png"),
	"doberman":preload("res://assets/adopted_ui/doberman.png"),
	"bullfrog":preload("res://assets/adopted_ui/bullfrog.png"),
	"hedgehog":preload("res://assets/adopted_ui/hedgehog.png"),
	"collar":preload("res://assets/adopted_ui/collar.png"),
	"berry":preload("res://assets/adopted_ui/healing_berry.png")}
const CATEGORY={"animals":"hen","materials":"wood","facilities":"hammer","items":"whistle"}
const SKILL_ICONS={"bark":"whistle","rescue":"paw","lay":"basket","feather":"spark","charm":"heart","meow":"whistle","intercept":"paw","tongue":"whistle","croak":"whistle","spines":"hammer","hardy":"heart"}

static func texture(id: String, category: String="animal") -> Texture2D:
	var portrait=PORTRAITS.get(category+"/"+id+"/portrait_ui","")
	if portrait!="": return load(portrait)
	if STATIC.has(id): return STATIC[id]
	if id in ["hen","cat"]: return Art.CLIPS[id+"/idle/right"].frames[0]
	if id=="shiba": return UI.SHIBA[1]
	if id=="kidnapper": return Delivered.CLIPS["enemy/idle_right"].frames[0]
	return null

static func portrait(c: CanvasItem,id: String,area: Rect2,category: String="animal"):
	var t=texture(id,category)
	if not t: return
	c.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	var used=Rect2(t.get_image().get_used_rect())
	var scale_value=minf(area.size.x/used.size.x,area.size.y/used.size.y)
	var size=(used.size*scale_value).round()
	c.draw_texture_rect_region(t,Rect2((area.get_center()-size/2).round(),size),used)

static func badge(g,c,p: Vector2,tier: int,small: bool=false):
	tier=clampi(tier,0,4)
	var colors=[Color("8b8871"),Color("628363"),Color("607d98"),Color("8d7393"),Color("ab843e")]
	var rect=Rect2(p,Vector2(116,23) if not small else Vector2(90,20))
	c.draw_style_box(g.MarketView.panel(Color("f0e4bf"),colors[tier],1),rect)
	for i in range(tier+1): c.draw_line(p+Vector2(5+i*3,5),p+Vector2(5+i*3,15),colors[tier],1)
	g.label_on(c,p+Vector2(24,16),g.Farm.ProgressData.RARITY_NAMES[tier],12 if small else 14,colors[tier])
