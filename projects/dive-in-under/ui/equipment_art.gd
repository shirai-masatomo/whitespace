extends RefCounted
## Item-template art, separate from live text, slot symbols and ownership data.
const Fallback=preload("res://ui/item_icons.gd")
const SHEET=preload("res://assets/equipment/v1/equipment-sheet.png")
const BLUE=preload("res://assets/equipment/v1/adventurer-cloak-navy.png")
const REGIONS={"A01":[20,65,275,345],"red_cloak":[297,65,283,345],"A03":[585,76,307,338],"A04":[901,77,244,334],"A05":[1150,129,285,283],"I01":[20,437,278,290],"I02":[299,423,293,308],"I03":[597,417,266,314],"I04":[864,447,284,287],"I05":[1178,470,253,264],"I06":[20,758,276,293],"I07":[306,742,290,306],"I08":[620,749,185,299],"I09":[867,757,287,299],"I11":[1164,747,270,306]}
static var cache: Dictionary={}
static var source_images: Dictionary={}
static func texture(template_id: String, fallback_kind: String="") -> Texture2D:
	var aliases: Dictionary={"W01":"A01","W02":"A01","W03":"A01","B01":"I02","B02":"A03","F01":"I05","G10":"I11"}
	if aliases.has(template_id): return texture(aliases[template_id],fallback_kind)
	if template_id=="A06": return Fallback.texture("shield")
	if template_id=="C01": return Fallback.texture("coin")
	if template_id in ["RB","RP","RM"]: return preload("res://ui/status_symbols.gd").texture({"C01":"gold","RB":"sp","RP":"hp","RM":"exp"}[template_id])
	if cache.has(template_id): return cache[template_id]
	if template_id!="A02" and not REGIONS.has(template_id): return Fallback.texture(fallback_kind)
	var sheet: Texture2D=BLUE if template_id=="A02" else SHEET
	var bounds:=Rect2i(Vector2i.ZERO,sheet.get_size())
	if REGIONS.has(template_id):
		var r: Array=REGIONS[template_id]; bounds=Rect2i(r[0],r[1],r[2],r[3])
	# Trim transparent margins by region metadata; preserve source pixels and alpha.
	var source_key: String="blue" if template_id=="A02" else "sheet"
	if not source_images.has(source_key): source_images[source_key]=sheet.get_image()
	var used: Rect2i=source_images[source_key].get_region(bounds).get_used_rect()
	var result:=AtlasTexture.new(); result.atlas=sheet
	result.region=Rect2(used.position+bounds.position,used.size); result.filter_clip=true
	cache[template_id]=result
	return result
