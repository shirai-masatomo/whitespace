extends RefCounted
const SHEET=preload("res://assets/interface/v2/symbols.png")
const BAGS=preload("res://assets/interface/v2/containers.png")
static var cache: Dictionary={}
const REGIONS={"hp":Rect2(20,221,280,316),"sp":Rect2(308,220,265,315),"exp":Rect2(578,220,281,315),"atk":Rect2(868,220,270,315),"def":Rect2(1171,220,271,315),"spd":Rect2(20,548,285,360),"poison":Rect2(310,546,266,362),"blind":Rect2(579,550,285,360),"paralysis":Rect2(873,550,262,360),"defense":Rect2(1146,550,298,360),"bag":Rect2(30,80,460,445),"cloth":Rect2(510,95,400,430),"warehouse":Rect2(930,70,490,465)}
static func texture(key: String) -> Texture2D:
	if not REGIONS.has(key): return null
	if cache.has(key): return cache[key]
	var t:=AtlasTexture.new(); t.atlas=BAGS if key in ["bag","cloth","warehouse"] else SHEET
	t.region=REGIONS[key]; t.filter_clip=true; cache[key]=t; return t
