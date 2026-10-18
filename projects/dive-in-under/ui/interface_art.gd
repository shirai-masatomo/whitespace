extends RefCounted
## Source sheet kept intact. Native regions/nine-patches preserve working controls.
const SHEET=preload("res://assets/interface/v1/interface-sheet.png")
static var cache: Dictionary={}
static func region(key: String, r: Rect2) -> AtlasTexture:
	if cache.has(key): return cache[key]
	var t:=AtlasTexture.new(); t.atlas=SHEET; t.region=r; t.filter_clip=true; cache[key]=t; return t
static func button_style(mode: String, selected: bool=false) -> StyleBoxTexture:
	var r:=Rect2(726,684,160,78)
	if selected or mode=="hover": r=Rect2(895,684,163,78)
	if mode=="pressed": r=Rect2(1063,684,162,78)
	if mode=="disabled": r=Rect2(1231,684,163,78)
	var st:=StyleBoxTexture.new(); st.texture=region("button-"+str(r.position.x),r)
	for side in [SIDE_LEFT,SIDE_TOP,SIDE_RIGHT,SIDE_BOTTOM]:
		st.set_texture_margin(side,12); st.set_content_margin(side,4)
	return st
static func paper(parent: Control, r: Rect2) -> void:
	var n:=NinePatchRect.new(); n.texture=region("parchment",Rect2(83,108,511,369))
	n.position=r.position; n.size=r.size; n.mouse_filter=Control.MOUSE_FILTER_IGNORE
	n.patch_margin_left=16; n.patch_margin_top=16; n.patch_margin_right=16; n.patch_margin_bottom=16
	n.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST; parent.add_child(n)
static func frame(node: Control, r: Rect2) -> void:
	# Four source corners and narrow stone/brass edges, independently scaled.
	var s:=r.size
	for pair in [[Rect2(32,56,70,70),Rect2(0,0,24,24)],[Rect2(581,55,70,70),Rect2(s.x-24,0,24,24)],[Rect2(32,455,70,70),Rect2(0,s.y-24,24,24)],[Rect2(581,455,70,70),Rect2(s.x-24,s.y-24,24,24)]]:
		node.draw_texture_rect_region(SHEET,pair[1],pair[0])
	for pair in [[Rect2(103,58,475,33),Rect2(24,0,s.x-48,10)],[Rect2(103,492,475,33),Rect2(24,s.y-10,s.x-48,10)],[Rect2(34,127,34,326),Rect2(0,24,10,s.y-48)],[Rect2(615,127,34,326),Rect2(s.x-10,24,10,s.y-48)]]:
		node.draw_texture_rect_region(SHEET,pair[1],pair[0])
