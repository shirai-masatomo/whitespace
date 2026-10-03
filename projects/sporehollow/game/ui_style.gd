extends RefCounted
## Shared ranch UI materials. Presentation only; no game rules.
const INK = Color("384738")
const PAPER = Color("e7d9b5")
const WOOD = Color("795b3e")
const MOSS = Color("536e52")
const GOLD = Color("ddba70")
const DANGER = Color("9c5748")
static var textures: Dictionary = {}

static func surface(color: Color, edge: Color = WOOD) -> StyleBoxFlat:
	var box = StyleBoxFlat.new()
	box.bg_color = color
	box.border_color = edge
	box.set_border_width_all(2)
	box.border_width_bottom = 4
	box.set_corner_radius_all(7)
	box.shadow_color = Color(0.12, 0.16, 0.1, 0.22)
	box.shadow_size = 4
	box.shadow_offset = Vector2(0, 3)
	box.content_margin_left = 10
	box.content_margin_right = 10
	return box

static func button(button: Button, color: Color = PAPER):
	button.add_theme_stylebox_override("normal", surface(color))
	button.add_theme_stylebox_override("hover", surface(color.lightened(0.12), GOLD))
	var pressed = surface(color.darkened(0.12), MOSS)
	pressed.shadow_size = 0
	pressed.border_width_bottom = 2
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
