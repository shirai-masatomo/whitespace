extends RefCounted
## Item-template art, separate from live text, slot symbols and ownership data.
const Fallback=preload("res://ui/item_icons.gd")
const SHEET=preload("res://assets/equipment/v1/equipment-sheet.png")
const BLUE=preload("res://assets/equipment/v1/adventurer-cloak-blue.png")
const REGIONS={"A01":[20,65,275,345],"red_cloak":[297,65,283,345],"A03":[585,76,307,338],"A04":[901,77,244,334],"A05":[1150,129,285,283],"I01":[20,437,278,290],"I02":[299,423,293,308],"I03":[597,417,266,314],"I04":[864,447,284,287],"I05":[1178,470,253,264],"I06":[20,758,276,293],"I07":[306,742,290,306],"I08":[620,749,185,299],"I09":[867,757,287,299],"I11":[1164,747,270,306]}
static var cache: Dictionary={}
static func texture(template_id: String, fallback_kind: String="") -> Texture2D:
	if cache.has(template_id): return cache[template_id]
	if template_id!="A02" and not REGIONS.has(template_id): return Fallback.texture(fallback_kind)
	var sheet: Texture2D=BLUE if template_id=="A02" else SHEET
	var bounds:=Rect2i(Vector2i.ZERO,sheet.get_size())
	if REGIONS.has(template_id):
		var r: Array=REGIONS[template_id]; bounds=Rect2i(r[0],r[1],r[2],r[3])
	# Trim transparent margins by region metadata; preserve source pixels and alpha.
	var used:=sheet.get_image().get_region(bounds).get_used_rect()
	var result:=AtlasTexture.new(); result.atlas=sheet
	result.region=Rect2(used.position+bounds.position,used.size); result.filter_clip=true
	cache[template_id]=result
	return result
