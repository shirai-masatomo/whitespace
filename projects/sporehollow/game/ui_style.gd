extends RefCounted
## Shared ranch UI materials. Presentation only; no game rules.
const INK = Color("384738")
const PAPER = Color("e7d9b5")
const WOOD = Color("795b3e")
const MOSS = Color("536e52")
const GOLD = Color("ddba70")
const DANGER = Color("9c5748")
static var textures: Dictionary = {}

const FRAME = preload("res://assets/ui/paper-frame.svg")
const SHIBA = [preload("res://art_delivery/characters_v1/shiba_idle_left_00.png"),preload("res://art_delivery/characters_v1/shiba_idle_front_00.png"),preload("res://art_delivery/characters_v1/shiba_idle_right_00.png")]
const KEEPER = preload("res://art_delivery/characters_v1/keeper_idle_right_00.png")
const STALL = preload("res://assets/ui/market-stall.png")
const BOOK = preload("res://assets/ui/book-open.png")

static func shiba(c: CanvasItem, foot: Vector2, pose: int=2, alpha: float=1.0):
	c.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	c.draw_texture(SHIBA[pose],foot-Vector2(24,44),Color(1,1,1,alpha))

static func keeper(c: CanvasItem, foot: Vector2, facing: int=1):
	c.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	# Left is a provisional mirrored static; preserve the delivered canvas and face.
	c.draw_texture_rect(KEEPER,Rect2(foot-Vector2(16,44),Vector2(-32 if facing<0 else 32,48)),false)

static func surface(color: Color, edge: Color = WOOD) -> StyleBoxTexture:
	var box=StyleBoxTexture.new()
	box.texture=FRAME
	box.modulate_color=color.lightened(0.14)
	for side in [SIDE_LEFT,SIDE_TOP,SIDE_RIGHT,SIDE_BOTTOM]:
		box.set_texture_margin(side,7)
		box.set_content_margin(side,10)
	return box

static func button(button: Button, color: Color = PAPER):
	button.add_theme_stylebox_override("normal", surface(color))
	button.add_theme_stylebox_override("hover", surface(color.lightened(0.12), GOLD))
	var pressed = surface(color.darkened(0.12), MOSS)
	pressed.modulate_color = color.darkened(0.08)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_stylebox_override("disabled", surface(Color("a8a48c"), Color("7d8068")))
	button.add_theme_color_override("font_color", INK)
	button.add_theme_color_override("font_hover_color", INK)
	button.add_theme_color_override("font_pressed_color", INK)
	button.add_theme_color_override("font_disabled_color", Color("646c59"))
	button.add_theme_constant_override("h_separation", 7)

static func selected(button: Button, active: bool):
	button.add_theme_stylebox_override("normal", surface(Color("c5d1a2") if active else PAPER, MOSS if active else WOOD))

static func icon(kind: String) -> Texture2D:
	if textures.has(kind): return textures[kind]
	var patterns = {
		"book_closed": ["0111110", "1100011", "1101011", "1101011", "1100011", "1111111", "0111110"],
		"book": ["1110111", "1011101", "1011101", "1011101", "1011101", "1111111", "0001000"],
		"moon": ["0001110", "0011000", "0110000", "0110000", "0110001", "0011111", "0001110"],
		"cup": ["0101000", "0010000", "1111100", "1000111", "1000101", "0111110", "1111110"],
		"back": ["0001000", "0011000", "0111111", "1111111", "0111111", "0011000", "0001000"],
		"next": ["0001000", "0001100", "1111110", "1111111", "1111110", "0001100", "0001000"],
		"check": ["0000001", "0000011", "1000110", "1101100", "0111000", "0010000", "0000000"],
		"paw": ["0101010", "1101011", "1101011", "0000000", "0011100", "0111110", "0011100"],
		"hammer": ["0111100", "1111110", "0111100", "0010000", "0010000", "0010000", "0010000"],
		"basket": ["0011100", "0100010", "1111111", "1000001", "1010101", "1010101", "0111110"],
		"pause": ["0110110", "0110110", "0110110", "0110110", "0110110", "0110110", "0110110"],
		"heart": ["0110110", "1111111", "1111111", "1111111", "0111110", "0011100", "0001000"],
		"spark": ["0001000", "0001000", "0011100", "1111111", "0011100", "0001000", "0001000"],
		"coin": ["0011100", "0111110", "1101011", "1101011", "1101011", "0111110", "0011100"],
		"cross": ["1100011", "0110110", "0011100", "0001000", "0011100", "0110110", "1100011"]}
	var pixels = patterns.get(kind, patterns.spark)
	var picture = Image.create(14, 14, false, Image.FORMAT_RGBA8)
	picture.fill(Color.TRANSPARENT)
	for y in range(7):
		for x in range(7):
			if pixels[y][x] == "1": picture.fill_rect(Rect2i(x * 2, y * 2, 2, 2), INK)
	textures[kind] = ImageTexture.create_from_image(picture)
	return textures[kind]


static func cursor(kind: String) -> Texture2D:
	var key="cursor_"+kind
	if textures.has(key):return textures[key]
	var picture=Image.create(32,32,false,Image.FORMAT_RGBA8)
	picture.fill(Color.TRANSPARENT)
	# Clear arrow tip is the exact click hotspot; the tool is offset to its right.
	for y in range(14):
		for x in range(y/2+1):picture.set_pixel(2+x,2+y,PAPER if x>0 and y>1 else INK)
	if kind=="hammer":
		picture.fill_rect(Rect2i(19,14,5,16),WOOD)
		picture.fill_rect(Rect2i(12,10,18,9),INK)
		picture.fill_rect(Rect2i(13,11,16,6),GOLD)
	elif kind=="move":
		picture.fill_rect(Rect2i(17,12,3,18),INK)
		picture.fill_rect(Rect2i(20,12,11,7),MOSS)
		picture.fill_rect(Rect2i(20,12,10,2),PAPER)
	else:
		picture.fill_rect(Rect2i(14,14,14,12),INK)
		picture.fill_rect(Rect2i(15,15,12,9),GOLD)
		picture.fill_rect(Rect2i(24,11,7,6),PAPER)
		picture.fill_rect(Rect2i(17,17,4,4),INK)
		picture.fill_rect(Rect2i(11,23,4,4),PAPER)
	textures[key]=ImageTexture.create_from_image(picture)
	return textures[key]
