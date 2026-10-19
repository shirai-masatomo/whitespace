extends RefCounted
const Art=preload("res://ui/interface_art.gd")
const Frame=preload("res://ui/warehouse_frame.gd")
const Gauges=preload("res://ui/vital_gauge.gd")
const GOLD=Color("e7c47d")
const INK=Color("eee6d2")
const MUTED=Color("a6b7b3")
const DARK=Color("30291e")
static func label(parent: Node, text: String, r: Rect2, pixels: int=18, color: Color=INK, wrap: bool=false) -> Label:
	var l:=Label.new(); l.language="ja"; l.text=text; l.position=r.position; l.size=r.size
	l.add_theme_font_size_override("font_size",pixels); l.add_theme_color_override("font_color",color)
	l.mouse_filter=Control.MOUSE_FILTER_IGNORE
	l.autowrap_mode=TextServer.AUTOWRAP_WORD if wrap else TextServer.AUTOWRAP_OFF
	l.clip_text=true; parent.add_child(l); l.size=r.size; return l
static func picture(parent: Node, texture: Texture2D, r: Rect2, cover: bool=false) -> TextureRect:
	var t:=TextureRect.new(); t.expand_mode=TextureRect.EXPAND_IGNORE_SIZE; t.texture=texture; t.position=r.position; t.size=r.size
	t.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_COVERED if cover else TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	t.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST; t.mouse_filter=Control.MOUSE_FILTER_IGNORE; t.clip_contents=cover; parent.add_child(t); return t
static func panel(parent: Node, r: Rect2, title: String="", paper: bool=false) -> Control:
	var c:=Control.new(); c.set_script(Frame); c.position=r.position; c.size=r.size; c.heading_line=title!=""; parent.add_child(c)
	if paper: Art.paper(c,Rect2(10,10,r.size.x-20,r.size.y-20))
	if title!="":
		if not paper: Art.paper(c,Rect2(12,10,r.size.x-24,34))
		label(c,title,Rect2(23,12,r.size.x-46,30),20,DARK)
	return c
static func button(parent: Node, text: String, r: Rect2, call: Callable, primary: bool=false) -> Button:
	var b:=Button.new(); b.text=text; b.position=r.position; b.size=r.size; b.pressed.connect(call); parent.add_child(b)
	b.add_theme_font_size_override("font_size",19)
	for mode in ["normal","hover","pressed","disabled"]:
		b.add_theme_stylebox_override(mode,Art.button_style(mode,primary))
		b.add_theme_color_override("font_"+("color" if mode=="normal" else mode+"_color"),DARK if primary and mode!="disabled" else (Color("79847e") if mode=="disabled" else INK))
	var focus:=StyleBoxFlat.new(); focus.bg_color=Color.TRANSPARENT; focus.border_color=Color("83d0d5"); focus.set_border_width_all(2)
	b.add_theme_stylebox_override("focus",focus); b.add_theme_color_override("font_focus_color",DARK if primary else INK)
	return b
static func gauge(parent: Node, value: int, maximum: int, r: Rect2, tint: Color) -> Control:
	var c:=Control.new(); c.set_script(Gauges); c.value=value; c.max_value=maximum; c.tint=tint; c.position=r.position; c.size=r.size; parent.add_child(c); return c
static func scroll_theme() -> Theme:
	var t:=Theme.new()
	for mode in ["scroll","grabber","grabber_highlight","grabber_pressed"]:
		var s:=StyleBoxFlat.new(); s.bg_color=Color("15262b") if mode=="scroll" else Color("c2a264"); s.border_color=Color("725832"); s.set_border_width_all(1)
		s.content_margin_left=4; s.content_margin_right=4; t.set_stylebox(mode,"VScrollBar",s)
	return t

static func fit_name(l: Label, full_name: String, width: float) -> void:
	# Show an explicit ellipsis within the measured content area; data stays unchanged.
	var font:=l.get_theme_font("font")
	var pixels:=l.get_theme_font_size("font_size")
	var visible:=full_name
	if font.get_string_size(visible,HORIZONTAL_ALIGNMENT_LEFT,-1,pixels).x>width:
		while not visible.is_empty() and font.get_string_size(visible+"…",HORIZONTAL_ALIGNMENT_LEFT,-1,pixels).x>width:
			visible=visible.left(visible.length()-1)
		visible+="…"
	l.text=visible; l.tooltip_text=full_name; l.set_meta("full_name",full_name)
	l.clip_text=true; l.size.x=width
