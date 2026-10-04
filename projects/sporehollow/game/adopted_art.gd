extends RefCounted
const CLIPS = {
	"keeper/settle/right": {"frames":[preload("res://art_delivery/characters_motion_v1/keeper/settle_right_00.png"),preload("res://art_delivery/characters_motion_v1/keeper/settle_right_01.png")],"anchor":Vector2(16,44),"duration":0.18,"loop":false},
	"keeper/settle/left": {"frames":[preload("res://art_delivery/characters_motion_v1/keeper/settle_left_00.png"),preload("res://art_delivery/characters_motion_v1/keeper/settle_left_01.png")],"anchor":Vector2(16,44),"duration":0.18,"loop":false},
	"keeper/rest/right": {"frames":[preload("res://art_delivery/characters_motion_v1/keeper/rest_right_00.png"),preload("res://art_delivery/characters_motion_v1/keeper/rest_right_01.png")],"anchor":Vector2(16,44),"duration":0.65,"loop":true},
	"keeper/rest/left": {"frames":[preload("res://art_delivery/characters_motion_v1/keeper/rest_left_00.png"),preload("res://art_delivery/characters_motion_v1/keeper/rest_left_01.png")],"anchor":Vector2(16,44),"duration":0.65,"loop":true},
	"keeper/sleep/right": {"frames":[preload("res://art_delivery/characters_motion_v1/keeper/sleep_right_00.png"),preload("res://art_delivery/characters_motion_v1/keeper/sleep_right_01.png")],"anchor":Vector2(16,44),"duration":0.65,"loop":true},
	"keeper/sleep/left": {"frames":[preload("res://art_delivery/characters_motion_v1/keeper/sleep_left_00.png"),preload("res://art_delivery/characters_motion_v1/keeper/sleep_left_01.png")],"anchor":Vector2(16,44),"duration":0.65,"loop":true},
	"keeper/wake/right": {"frames":[preload("res://art_delivery/characters_motion_v1/keeper/wake_right_00.png"),preload("res://art_delivery/characters_motion_v1/keeper/wake_right_01.png")],"anchor":Vector2(16,44),"duration":0.18,"loop":false},
	"keeper/wake/left": {"frames":[preload("res://art_delivery/characters_motion_v1/keeper/wake_left_00.png"),preload("res://art_delivery/characters_motion_v1/keeper/wake_left_01.png")],"anchor":Vector2(16,44),"duration":0.18,"loop":false},
	"keeper/walk/right": {"frames":[preload("res://art_delivery/characters_motion_v1/keeper/walk_right_00.png"),preload("res://art_delivery/characters_motion_v1/keeper/walk_right_01.png"),preload("res://art_delivery/characters_motion_v1/keeper/walk_right_02.png"),preload("res://art_delivery/characters_motion_v1/keeper/walk_right_03.png")],"anchor":Vector2(16,44),"duration":0.1,"loop":true},
	"keeper/walk/left": {"frames":[preload("res://art_delivery/characters_motion_v1/keeper/walk_left_00.png"),preload("res://art_delivery/characters_motion_v1/keeper/walk_left_01.png"),preload("res://art_delivery/characters_motion_v1/keeper/walk_left_02.png"),preload("res://art_delivery/characters_motion_v1/keeper/walk_left_03.png")],"anchor":Vector2(16,44),"duration":0.1,"loop":true},
	"shiba/settle/right": {"frames":[preload("res://art_delivery/characters_motion_v1/shiba/settle_right_00.png"),preload("res://art_delivery/characters_motion_v1/shiba/settle_right_01.png")],"anchor":Vector2(24,44),"duration":0.18,"loop":false},
	"shiba/settle/left": {"frames":[preload("res://art_delivery/characters_motion_v1/shiba/settle_left_00.png"),preload("res://art_delivery/characters_motion_v1/shiba/settle_left_01.png")],"anchor":Vector2(24,44),"duration":0.18,"loop":false},
	"shiba/rest/right": {"frames":[preload("res://art_delivery/characters_motion_v1/shiba/rest_right_00.png"),preload("res://art_delivery/characters_motion_v1/shiba/rest_right_01.png")],"anchor":Vector2(24,44),"duration":0.65,"loop":true},
	"shiba/rest/left": {"frames":[preload("res://art_delivery/characters_motion_v1/shiba/rest_left_00.png"),preload("res://art_delivery/characters_motion_v1/shiba/rest_left_01.png")],"anchor":Vector2(24,44),"duration":0.65,"loop":true},
	"shiba/wake/right": {"frames":[preload("res://art_delivery/characters_motion_v1/shiba/wake_right_00.png"),preload("res://art_delivery/characters_motion_v1/shiba/wake_right_01.png")],"anchor":Vector2(24,44),"duration":0.18,"loop":false},
	"shiba/wake/left": {"frames":[preload("res://art_delivery/characters_motion_v1/shiba/wake_left_00.png"),preload("res://art_delivery/characters_motion_v1/shiba/wake_left_01.png")],"anchor":Vector2(24,44),"duration":0.18,"loop":false},
	"shiba/walk/right": {"frames":[preload("res://art_delivery/characters_motion_v1/shiba/walk_right_00.png"),preload("res://art_delivery/characters_motion_v1/shiba/walk_right_01.png"),preload("res://art_delivery/characters_motion_v1/shiba/walk_right_02.png"),preload("res://art_delivery/characters_motion_v1/shiba/walk_right_03.png")],"anchor":Vector2(24,44),"duration":0.1,"loop":true},
	"shiba/walk/left": {"frames":[preload("res://art_delivery/characters_motion_v1/shiba/walk_left_00.png"),preload("res://art_delivery/characters_motion_v1/shiba/walk_left_01.png"),preload("res://art_delivery/characters_motion_v1/shiba/walk_left_02.png"),preload("res://art_delivery/characters_motion_v1/shiba/walk_left_03.png")],"anchor":Vector2(24,44),"duration":0.1,"loop":true},
	"keeper/idle/left": {"frames":[preload("res://art_delivery/characters_motion_v1/keeper/idle_left_00.png")],"anchor":Vector2(16,44),"duration":1.0,"loop":false},
	"hen/idle/right": {"frames":[preload("res://art_delivery/ranch_assets_v1/hen/idle_right_00.png")],"anchor":Vector2(16,29),"duration":1.0,"loop":false},
	"hen/walk/right": {"frames":[preload("res://art_delivery/ranch_assets_v1/hen/walk_right_00.png"),preload("res://art_delivery/ranch_assets_v1/hen/walk_right_01.png"),preload("res://art_delivery/ranch_assets_v1/hen/walk_right_02.png"),preload("res://art_delivery/ranch_assets_v1/hen/walk_right_03.png")],"anchor":Vector2(16,29),"duration":0.12,"loop":true},
	"hen/peck/right": {"frames":[preload("res://art_delivery/ranch_assets_v1/hen/peck_right_00.png"),preload("res://art_delivery/ranch_assets_v1/hen/peck_right_01.png")],"anchor":Vector2(16,29),"duration":0.26,"loop":true},
	"hen/idle/left": {"frames":[preload("res://art_delivery/ranch_assets_v1/hen/idle_left_00.png")],"anchor":Vector2(16,29),"duration":1.0,"loop":false},
	"hen/walk/left": {"frames":[preload("res://art_delivery/ranch_assets_v1/hen/walk_left_00.png"),preload("res://art_delivery/ranch_assets_v1/hen/walk_left_01.png"),preload("res://art_delivery/ranch_assets_v1/hen/walk_left_02.png"),preload("res://art_delivery/ranch_assets_v1/hen/walk_left_03.png")],"anchor":Vector2(16,29),"duration":0.12,"loop":true},
	"hen/peck/left": {"frames":[preload("res://art_delivery/ranch_assets_v1/hen/peck_left_00.png"),preload("res://art_delivery/ranch_assets_v1/hen/peck_left_01.png")],"anchor":Vector2(16,29),"duration":0.26,"loop":true},
	"cat/idle/right": {"frames":[preload("res://art_delivery/ranch_assets_v1/cat/idle_right_00.png")],"anchor":Vector2(24,36),"duration":1.0,"loop":false},
	"cat/walk/right": {"frames":[preload("res://art_delivery/ranch_assets_v1/cat/walk_right_00.png"),preload("res://art_delivery/ranch_assets_v1/cat/walk_right_01.png"),preload("res://art_delivery/ranch_assets_v1/cat/walk_right_02.png"),preload("res://art_delivery/ranch_assets_v1/cat/walk_right_03.png")],"anchor":Vector2(24,36),"duration":0.12,"loop":true},
	"cat/stretch/right": {"frames":[preload("res://art_delivery/ranch_assets_v1/cat/stretch_right_00.png"),preload("res://art_delivery/ranch_assets_v1/cat/stretch_right_01.png")],"anchor":Vector2(24,36),"duration":0.26,"loop":false},
	"cat/idle/left": {"frames":[preload("res://art_delivery/ranch_assets_v1/cat/idle_left_00.png")],"anchor":Vector2(24,36),"duration":1.0,"loop":false},
	"cat/walk/left": {"frames":[preload("res://art_delivery/ranch_assets_v1/cat/walk_left_00.png"),preload("res://art_delivery/ranch_assets_v1/cat/walk_left_01.png"),preload("res://art_delivery/ranch_assets_v1/cat/walk_left_02.png"),preload("res://art_delivery/ranch_assets_v1/cat/walk_left_03.png")],"anchor":Vector2(24,36),"duration":0.12,"loop":true},
	"cat/stretch/left": {"frames":[preload("res://art_delivery/ranch_assets_v1/cat/stretch_left_00.png"),preload("res://art_delivery/ranch_assets_v1/cat/stretch_left_01.png")],"anchor":Vector2(24,36),"duration":0.26,"loop":false},
}
const BOARD_CART = preload("res://art_delivery/merchant_board_v1/cart_idle_00.png")
const CART = preload("res://art_delivery/cart_ui_detail_v1/cart.png")
const CLOSED = preload("res://art_delivery/ranch_assets_v1/book/closed_00.png")
const SCROLL = preload("res://art_delivery/ranch_assets_v1/scroll/idle_none_00.png")

static func sprite(canvas: CanvasItem, who: String, action: String, facing: int, foot: Vector2, elapsed: float=0, alpha: float=1):
	var key = who+"/"+action+("/left" if facing<0 else "/right")
	if not CLIPS.has(key):
		if who=="keeper": preload("res://game/ui_style.gd").keeper(canvas,foot,facing)
		elif who=="shiba": preload("res://game/ui_style.gd").shiba(canvas,foot,0 if facing<0 else 2,alpha)
		else: push_error("Missing adopted animation: "+key)
		return
	var clip = CLIPS[key]
	var index = maxi(0,int(elapsed/clip.duration))
	index = index%clip.frames.size() if clip.loop else mini(index,clip.frames.size()-1)
	canvas.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	canvas.draw_texture(clip.frames[index],(foot-clip.anchor).round(),Color(1,1,1,alpha))

static func fit(canvas: CanvasItem, texture: Texture2D, rect: Rect2):
	var scale = minf(rect.size.x/texture.get_width(),rect.size.y/texture.get_height())
	var size = texture.get_size()*scale
	canvas.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	canvas.draw_texture_rect(texture,Rect2((rect.get_center()-size*0.5).round(),size),false)

static var used_bounds: Dictionary = {}
static func bounds(who: String, action: String, facing: int, foot: Vector2, elapsed: float) -> Rect2:
	var key=who+"/"+action+("/left" if facing<0 else "/right")
	if not CLIPS.has(key): return Rect2(foot-Vector2(16,44),Vector2(32,48))
	var clip=CLIPS[key]
	var index=maxi(0,int(elapsed/clip.duration))
	index=index%clip.frames.size() if clip.loop else mini(index,clip.frames.size()-1)
	var texture=clip.frames[index]
	if not used_bounds.has(texture.resource_path): used_bounds[texture.resource_path]=Rect2(texture.get_image().get_used_rect())
	var rect=used_bounds[texture.resource_path]
	return Rect2(foot-clip.anchor+rect.position,rect.size)
