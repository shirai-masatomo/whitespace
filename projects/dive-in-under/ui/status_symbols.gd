extends RefCounted
## Original native-UI pixel symbols; no gameplay values or external image dependency.
static var cache: Dictionary={}
const COLORS={"hp":"ce6550","sp":"58b3c6","atk":"e7d9b4","def":"78a9c3","spd":"c9b58a","poison":"ad83ce","blind":"96a7bc","paralysis":"ebcb58","defense":"89c6d6","normal":"98bd94","bag":"c29a57"}
const GLYPHS={
"hp":["  xx xx  "," xxxxxxx "," xxxxxxx "," xxxxxxx ","  xxxxx  ","   xxx   ","    x    "],
"sp":["    x    ","   xxx   ","   xxx   ","  xxxxx  ","  xxxxx  ","  xxxxx  ","   xxx   "],
"atk":["      xx ","     xxx ","    xxx  ","   xxx   "," x xx    ","  xxx    "," xx x    "],
"def":[" xxxxxxx "," xx   xx "," xx   xx "," xxxxxxx ","  xxxxx  ","   xxx   ","    x    "],
"spd":["   xxxx  ","   x xx  ","   x xx  ","  xxxxx  "," xxxxxx  "," xxxxxx  "," xxxxxxx "],
"poison":[" xx  xx  "," xx  xx  ","         ","   xxx   ","  xxxxx  ","  xxxxx  ","   xxx   "],
"blind":["         ","  xxxxx  "," xx x xx ","xx xxx xx"," xx x xx ","  xxxxx  ","         "],
"paralysis":["     xx  ","    xx   ","   xx    ","  xxxxx  ","    xx   ","   xx    ","  xx     "],
"defense":[" xxxxxxx "," xx x xx "," x xxx x "," xx x xx ","  xxxxx  ","   xxx   ","    x    "],
"normal":["    x    ","   xxx   ","  xxxxx  "," xxxxxxx ","  xxxxx  ","   xxx   ","    x    "],
"bag":["   xxx   ","  xxxxx  "," xxxxxxx "," xx x xx "," xxxxxxx "," xx x xx "," xxxxxxx "]}
static func texture(key: String) -> Texture2D:
	if cache.has(key): return cache[key]
	var rows: Array=GLYPHS.get(key,GLYPHS.normal)
	var ink:=Color(COLORS.get(key,COLORS.normal))
	var im:=Image.create(32,32,false,Image.FORMAT_RGBA8)
	for y in rows.size():
		for x in rows[y].length():
			if rows[y][x]=="x":
				im.fill_rect(Rect2i(3+x*3,4+y*3,3,3),Color("101c23"))
				im.fill_rect(Rect2i(2+x*3,3+y*3,3,3),ink.lightened(0.18) if (x+y)%3==0 else ink)
	cache[key]=ImageTexture.create_from_image(im)
	return cache[key]
