extends RefCounted
## Presentation time only. One bounded utterance per visible dialogue change.
const HALF=preload("res://assets/ui/merchant_mouth_v1/half.png")
const OPEN=preload("res://assets/ui/merchant_mouth_v1/open.png")
const SOURCE=Rect2(390,288,730,496)
const TARGET=Rect2(307,182,27,18.35)
const FRAMES=[0,1,2,1,0,1,2,1,0]
const TIMES=[0.16,0.16,0.20,0.16,0.26,0.14,0.18,0.16,0.24]
const DURATION=1.66
var key=""
var elapsed=0.0

static func visible_key(game) -> String:
	if not game.field_shop or game.field_book or game.menu_open or not game.world.merchant_present():return ""
	if game.morning_screen=="morning":return "greeting"
	if game.morning_screen!="market":return ""
	return "greeting" if game.shop_side=="home" else game.shop_side

func stop():
	key="";elapsed=0.0

func update(game,delta: float):
	var next=visible_key(game)
	if next!=key:key=next;elapsed=0.0
	else:elapsed=minf(DURATION,elapsed+maxf(delta,0.0))
	if key=="":elapsed=0.0

func frame(game) -> int:
	if key=="" or visible_key(game)!=key or elapsed>=DURATION:return 0
	var end=0.0
	for i in range(FRAMES.size()):
		end+=TIMES[i]
		if elapsed<end:return FRAMES[i]
	return 0

static func mouth_rect(texture: Texture2D,area: Rect2) -> Rect2:
	var used=Rect2(texture.get_image().get_used_rect())
	var size=(used.size*minf(area.size.x/used.size.x,area.size.y/used.size.y)).round()
	var origin=(area.get_center()-size/2).round()
	var ratio=size/used.size
	return Rect2(origin+(TARGET.position-used.position)*ratio,TARGET.size*ratio)

func draw(game,c: CanvasItem,texture: Texture2D,area: Rect2):
	var state=frame(game)
	if state==0:return
	c.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	c.draw_texture_rect_region(HALF if state==1 else OPEN,mouth_rect(texture,area),SOURCE)
