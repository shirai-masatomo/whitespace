extends RefCounted
## Adopted continuous_bedrock_v1. All image work is cached outside normal draws.
const ROOT="res://art_delivery/continuous_bedrock_v1/"
const DIRS=[Vector2i.UP,Vector2i.RIGHT,Vector2i.DOWN,Vector2i.LEFT]
const CORNERS={"nw":[0,3],"ne":[0,1],"sw":[2,3],"se":[2,1]}
static var images={}
static var rocks={}
static var ground={}
static var inner_textures={}
static var preparations=0
static func source(file:String)->Image:
	if not images.has(file):
		var texture=load(ROOT+file) as Texture2D
		assert(texture!=null,"Missing formal geology asset: "+file)
		var img=texture.get_image();img.convert(Image.FORMAT_RGBA8);images[file]=img
	return images[file]
static func phase(p:Vector2i,period:int)->Vector2i:return Vector2i(posmod(p.x,period),posmod(p.y,period))
static func clipped(img:Image,alpha:Image)->Image:
	var result=img.duplicate()
	for y in range(result.get_height()):
		for x in range(result.get_width()):
			var color=result.get_pixel(x,y);color.a*=alpha.get_pixel(x,y).a;result.set_pixel(x,y,color)
	return result
static func roof(file:String,p:Vector2i)->Image:
	var patch=Image.create(48,54,false,Image.FORMAT_RGBA8)
	patch.blit_rect(source(file),Rect2i(phase(p,8)*Vector2i(48,42),Vector2i(48,42)),Vector2i(0,12))
	return patch
static func rock(p:Vector2i,mask:int,iron:bool)->Texture2D:
	var key=Vector3i(phase(p,8).x+phase(p,8).y*8,mask,int(iron))
	if not rocks.has(key):
		var base=source("normal/mask_%02d.png"%mask).duplicate();var alpha=source("top/mask_%02d.png"%mask)
		var top=clipped(roof("top/atlas.png",p),alpha)
		base.blend_rect(top,Rect2i(0,0,48,54),Vector2i.ZERO)
		if iron:
			var ore=clipped(roof("iron/atlas.png",p),alpha);base.blend_rect(ore,Rect2i(0,0,48,54),Vector2i.ZERO)
		rocks[key]=ImageTexture.create_from_image(base);preparations+=1
	return rocks[key]
static func inner(corner:String)->Texture2D:
	if not inner_textures.has(corner):inner_textures[corner]=load(ROOT+"inner/concave_"+corner+".png")
	return inner_textures[corner]
static func ground_edge(w,p:Vector2i,kind:String)->String:
	var high=DIRS.map(func(d):return w.inside(p+d) and w.Biome.material(w,p+d)==kind)
	for corner in CORNERS:
		var pair=CORNERS[corner]
		if not high[pair[0]] and not high[pair[1]]:return "outer_"+corner
	for i in range(4):
		if not high[i]:return "edge_"+["s","w","n","e"][i]
	for corner in CORNERS:
		var pair=CORNERS[corner];var q=p+DIRS[pair[0]]+DIRS[pair[1]]
		if not w.inside(q) or w.Biome.material(w,q)!=kind:return "inner_"+corner
	return "full"
static func surface(w,p:Vector2i,kind:String)->Texture2D:
	var edge=ground_edge(w,p,kind);var offset=phase(p,4);var key="%s:%s:%s"%[kind,edge,offset]
	if not ground.has(key):
		var crop=source("ground/"+kind+"/atlas.png").get_region(Rect2i(offset*Vector2i(48,42),Vector2i(48,42)))
		ground[key]=ImageTexture.create_from_image(clipped(crop,source("boundary/"+edge+".png")));preparations+=1
	return ground[key]
static func prepare(w):
	# Only terrain v6 uses the new surface contract. No retrofit to existing maps.
	if not w.terrain.has("geology"):return
	rocks.clear();ground.clear()
	for p in w.rocks:
		var row=w.rock_connections[p]
		rock(p,row.mask,w.rocks[p].get("geology")=="iron")
	for corner in CORNERS:inner(corner)
