extends RefCounted
## Read-only material selection. No collision, drop, generation or work mutation.
const Art=preload("res://game/rock_art.gd")
const TOP=Color("bcb59c") # Shared chip tint for legacy FX.
const WALL="biome_connections_v1/"
const NODE="biome_environment_v2/rock_node/"
const DAMAGE_KEYS=["biome_environment_v1/rock/damage/light.png","biome_environment_v1/rock/damage/heavy.png","biome_environment_v2/rock_node/wall_near_depleted_overlay.png"]
static var clipped={}
static var mineral_seams={}
static var ground_source=null
static var ground_kinds={}
static var ground_offsets={}
static var ground_version=""
const DIRS=[Vector2i.UP,Vector2i.RIGHT,Vector2i.DOWN,Vector2i.LEFT]
const CORNERS={"nw":[0,3],"ne":[0,1],"sw":[2,3],"se":[2,1]}

static func mask(w,p: Vector2i) -> int:
	var value=0
	for i in range(4):
		if w.rocks.has(p+DIRS[i]):value|=1<<i
	return value
static func inner(w,p: Vector2i) -> Array:
	var result=[]
	for name in CORNERS:
		var a=DIRS[CORNERS[name][0]];var b=DIRS[CORNERS[name][1]]
		if w.rocks.has(p+a) and w.rocks.has(p+b) and not w.rocks.has(p+a+b):result.append(name)
	return result
static func wall(w,p: Vector2i) -> bool:
	# Surviving wall pieces keep their wall anchor even after the final neighbour is mined.
	return mask(w,p)!=0 or DIRS.any(func(d):return p+d in w.mined_rock_cells)
static func node_size(w,p: Vector2i) -> String:
	var preferred=w.rocks.get(p,{}).get("visual_size","")
	return preferred if preferred in ["small","medium","large"] else ["small","medium","large"][floori(w.Biome.unit(w.seed_value,p.x,p.y,931)*3)]
static func stage(progress: float) -> int:return 3 if progress>=0.85 else 2 if progress>=0.5 else 1 if progress>=0.25 else 0
static func normal_key(w,p: Vector2i) -> String:
	return WALL+"normal/mask_%02d.png"%mask(w,p) if wall(w,p) else NODE+node_size(w,p)+"/"+["intact","damaged_1","damaged_2","near_depleted"][stage(w.Harvest.progress(w,"mine",p))]+".png"
static func clipped_damage(m: int,level: int) -> Texture2D:
	var key="%d:%d"%[m,level]
	if not clipped.has(key):
		var image=Art.texture(DAMAGE_KEYS[level-1]).get_image().duplicate();image.convert(Image.FORMAT_RGBA8)
		var base=Art.texture(WALL+"normal/mask_%02d.png"%m).get_image()
		for y in range(image.get_height()):
			for x in range(image.get_width()):
				var color=image.get_pixel(x,y);color.a*=base.get_pixel(x,y).a;image.set_pixel(x,y,color)
		clipped[key]=ImageTexture.create_from_image(image)
	return clipped[key]
static func rock(g,p: Vector2i):
	var w=g.world;var c=g.center(p);var key=normal_key(w,p);var level=stage(w.Harvest.progress(w,"mine",p))
	if wall(w,p):
		if not(mask(w,p)&4):Art.paint(g,NODE+"shadow_large.png",c+Vector2(0,14))
		Art.paint(g,key,c)
		static_seams(g,p,c)
		for corner in inner(w,p):Art.paint(g,WALL+"inner/concave_"+corner+".png",c)
		if level>0:g.draw_texture(clipped_damage(mask(w,p),level),(c-Vector2(24,33)).round())
	else:
		Art.paint(g,NODE+"shadow_"+node_size(w,p)+".png",c+Vector2(0,14))
		Art.paint(g,key,c+Vector2(0,14))

static func geology(w,p: Vector2i) -> bool:
	return w.inside(p) and (w.Biome.material(w,p) in ["gravel","bedrock"] if w.terrain.get("version",1)>=2 else w.Biome.field(w,p)[2]>0.43)
static func transition(w,p: Vector2i) -> String:
	var high=DIRS.map(func(d):return geology(w,p+d));var here=geology(w,p)
	if here:
		for corner in CORNERS:
			var pair=CORNERS[corner]
			if not high[pair[0]] and not high[pair[1]]:return "outer_"+corner
		for i in range(4):
			if not high[i]:return "edge_"+["s","w","n","e"][i]
		for corner in CORNERS:
			var pair=CORNERS[corner]
			if not geology(w,p+DIRS[pair[0]]+DIRS[pair[1]]):return "inner_"+corner
		return "full"
	# Each PNG finishes its entire grass-to-rock transition in this inside cell.
	# Repeating it in the outside neighbour restarts rock after grass, creating stripes.
	return ""
static func material_edge(w,p: Vector2i,material: String) -> String:
	# A higher-ranked surface is also inside the lower band's boundary. This keeps
	# soil/gravel/bedrock nested, without restarting grass on every material change.
	var ranks={"grass":0,"soil":1,"gravel":2,"bedrock":3};var rank=ranks[material]
	var high=[]
	for d in DIRS:high.append(w.inside(p+d) and ranks[w.Biome.material(w,p+d)]>=rank)
	for corner in CORNERS:
		var pair=CORNERS[corner]
		if not high[pair[0]] and not high[pair[1]]:return "outer_"+corner
	for i in range(4):
		if not high[i]:return "edge_"+["s","w","n","e"][i]
	for corner in CORNERS:
		var pair=CORNERS[corner];var q=p+DIRS[pair[0]]+DIRS[pair[1]]
		if not w.inside(q) or ranks[w.Biome.material(w,q)]<rank:return "inner_"+corner
	return "full"
static func ground_layers(w,p: Vector2i) -> Array:
	if w.terrain.get("version",1)>=4:
		# Continuous rock skins live in the shared vertex mesh; only sparse transparent debris here.
		var rock=w.Biome.field(w,p)[2];var roll=w.Biome.unit(w.seed_value,p.x,p.y,149)
		if rock>0.3 and roll<0.10:return ["biome_environment_v1/rock/ground/gravel.png"]
		if rock>0.2 and roll<0.16:return ["biome_environment_v2/rock_ground/pebbly_soil.png"]
		return []
	if w.terrain.get("version",1)<2:
		var legacy=transition(w,p)
		return [WALL+"transition/"+legacy+".png"] if legacy!="" else []
	var material=w.Biome.material(w,p);var prefix="biome_environment_v2/"
	if material in ["gravel","bedrock"]:
		var edge=material_edge(w,p,material)
		return [prefix+"rock_ground/"+material+".png"] if edge=="full" else [prefix+"rock_transition/"+material+"/"+edge+".png"]
	if material=="soil":
		# Sparse transparent patches leave the continuous vertex colour visible.
		var roll=w.Biome.unit(w.terrain.seed,p.x,p.y,149)
		return [prefix+"rock_ground/pebbly_soil.png"] if roll<0.15 else []
	return []
static func cache_ground(w):
	var token="%s:%s"%[w.terrain.get("version",0),w.terrain.seed]
	if ground_source==w and ground_version==token:return
	ground_source=w;ground_version=token;ground_kinds={};ground_offsets={};mineral_seams.clear()
static func prepare_ground(w):
	cache_ground(w)
	for y in range(w.H):
		for x in range(w.W):
			var p=Vector2i(x,y)
			ground_kinds[p]=ground_layers(w,p)
			if w.terrain.get("version",1)>=4 or ground_kinds[p]==["biome_environment_v2/rock_ground/pebbly_soil.png"]:
				ground_offsets[p]=Vector2(floori(w.Biome.unit(w.terrain.seed,x,y,181)*17)-8,floori(w.Biome.unit(w.terrain.seed,x,y,191)*13)-6)
static func ground(g,region: Rect2=Rect2()):
	var w=g.world;cache_ground(w)
	var visible=Rect2(Vector2.ZERO,Vector2(w.W,w.H)*g.TILE)
	if region.has_area():visible=region
	elif g.has_method("get_canvas_transform"):visible=g.get_canvas_transform().affine_inverse()*g.get_viewport_rect()
	for y in range(maxi(0,floori(visible.position.y/g.TILE.y)-(0 if region.has_area() else 1)),mini(w.H,ceili(visible.end.y/g.TILE.y)+(0 if region.has_area() else 1))):
		for x in range(maxi(0,floori(visible.position.x/g.TILE.x)-(0 if region.has_area() else 1)),mini(w.W,ceili(visible.end.x/g.TILE.x)+(0 if region.has_area() else 1))):
			var p=Vector2i(x,y)
			if w.floors.has(p) or w.live_structure(p):continue
			if not ground_kinds.has(p):
				ground_kinds[p]=ground_layers(w,p)
				if w.terrain.get("version",1)>=4 or ground_kinds[p]==["biome_environment_v2/rock_ground/pebbly_soil.png"]:
					ground_offsets[p]=Vector2(floori(w.Biome.unit(w.terrain.seed,x,y,181)*17)-8,floori(w.Biome.unit(w.terrain.seed,x,y,191)*13)-6)
			for key in ground_kinds.get(p,[]):Art.paint(g,key,g.center(p)+ground_offsets.get(p,Vector2.ZERO))
	for p in w.mined_rock_cells:
		if w.floors.has(p) or w.live_structure(p) or not visible.grow(0 if region.has_area() else 54).has_point(g.center(p)):continue
		Art.paint(g,"biome_environment_v2/rock_mined/exposed_bedrock.png",g.center(p))
		Art.paint(g,"biome_environment_v2/rock_mined/shallow_scoop.png",g.center(p))
		# Low, non-resource scatter persists after the short collapse animation.
		Art.paint(g,"biome_environment_v1/rock/ground/gravel.png",g.center(p),0.48)
static func rubble(g,p: Vector2i,alpha: float=1.0):
	Art.paint(g,"biome_environment_v1/rock/ground/rubble.png",g.center(p),alpha)
static func chips(g,p: Vector2i,age: float):
	var durations=[0.065,0.075,0.085,0.1]
	for i in range(4):
		if age<durations[i]:Art.paint(g,"biome_environment_v1/rock/fx/chips_%02d.png"%i,g.center(p));return
		age-=durations[i]

static func static_seams(g,p,c):
	var w=g.world;var key=[w.terrain.seed,p]
	if not mineral_seams.has(key):
		var dark=PackedVector2Array();var light=PackedVector2Array()
		for i in range(3):
			var x=floori(w.Biome.unit(w.seed_value,p.x,p.y,610+i)*29)-14
			var y=floori(w.Biome.unit(w.seed_value,p.x,p.y,620+i)*17)-19
			var q=Vector2(x,y)
			# Interior only; never draw outside the delivered silhouette/doorway.
			dark.append_array([q,q+Vector2(5,0),q+Vector2(5,0),q+Vector2(8,3)])
			light.append_array([q+Vector2(0,2),q+Vector2(5,2)])
		mineral_seams[key]=[dark,light]
	var lines=mineral_seams[key]
	g.draw_set_transform(c)
	g.draw_multiline(lines[0],Color("9c9680"),1.0)
	g.draw_multiline(lines[1],Color("c4bea6"),1.0)
	g.draw_set_transform(Vector2.ZERO)
