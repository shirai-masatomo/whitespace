extends RefCounted
const Delivered = preload("res://game/delivered_art.gd")
const Biome=preload("res://game/biome_map.gd")
const Ground=preload("res://game/rock_art.gd")
static var ground_source=null
static var ground_version=""
static var ground_cells=[]
static var region_meshes={}
# Geometry, vertex colours and decorative choices are built once per terrain version.
# Only viewport cells are submitted; changing rocks/trees never rebuilds this base.
static func cache_ground(world,tile: Vector2):
	var token="%s:%s:%s"%[world.terrain.get("version",0),world.terrain.seed,tile]
	if ground_source==world and ground_version==token:return
	ground_source=world;ground_version=token;ground_cells=[];region_meshes.clear()
	for y in range(world.H):
		for x in range(world.W):
			var p=Vector2(x,y)*tile;var cell=Vector2i(x,y)
			var colors=PackedColorArray()
			for q in [cell,cell+Vector2i.RIGHT,cell+Vector2i.ONE,cell+Vector2i.DOWN]:
				var rgb=world.terrain.vertices[q.y*(world.W+1)+q.x];colors.append(Color(rgb[0],rgb[1],rgb[2]))
			ground_cells.append({"points":PackedVector2Array([p,p+Vector2(tile.x,0),p+tile,p+Vector2(0,tile.y)]),"colors":colors,"decor":decor_key(world,cell),"offset":Vector2(floori(Biome.unit(world.terrain.seed,x,y,173)*15)-7,floori(Biome.unit(world.terrain.seed,x,y,179)*11)-5)})
static func decor_key(world,p: Vector2i) -> String:
	var zone=Biome.kind(world,p);var roll=Biome.unit(world.terrain.seed,p.x,p.y,103)
	var which=int(Biome.unit(world.terrain.seed,p.x,p.y,111)*5)
	var prefix="biome_environment_v1/ground/"
	match zone:
		"dry":
			if roll<0.44:return prefix+"dry/"+["short_grass","soil_spot","cracks_00","grass_tuft","cracks_01"][which]+".png"
		"lush":
			if roll<0.52:return prefix+"lush/"+["low_sparse","low_dense","tall_tuft","cover_sparse","flowers"][which]+".png"
		"woodland":
			if roll<0.25:return prefix+"lush/"+["low_sparse","cover_sparse","low_sparse","low_dense","flowers"][which]+".png"
		"open":
			if roll<0.09:return prefix+"lush/low_sparse.png"
	return ""
static func draw_ground(c: CanvasItem, world, tile: Vector2, _time: float = 0):
	cache_ground(world,tile)
	var inv=c.get_canvas_transform().affine_inverse()
	var top=inv*Vector2.ZERO;var bottom=inv*c.get_viewport_rect().size
	c.draw_rect(Rect2(top-Vector2(100,100),bottom-top+Vector2(200,200)),Color("344c3b"))
	for y in range(maxi(0,floori(top.y/tile.y)-1),mini(world.H,ceili(bottom.y/tile.y)+1)):
		for x in range(maxi(0,floori(top.x/tile.x)-1),mini(world.W,ceili(bottom.x/tile.x)+1)):
			var row=ground_cells[y*world.W+x];var cell=Vector2i(x,y)
			c.draw_polygon(row.points,row.colors)
			if row.decor!="" and not world.floors.has(cell) and not world.live_structure(cell) and not world.rocks.has(cell) and not world.natural.has(cell):
				Ground.paint(c,row.decor,(Vector2(cell)+Vector2(0.5,0.5))*tile+row.offset,0.8)
	c.draw_rect(Rect2(Vector2.ZERO,Vector2(world.W,world.H)*tile),Color("d4c89d"),false,3)

static func draw_resource(c: CanvasItem, p: Vector2, kind: String):
	if Delivered.RESOURCES.has(kind):
		Delivered.resource(c,kind,p,24)
		return
	match kind:
		"weed":
			c.draw_circle(p + Vector2(0, 7), 11, Color("516c3e"))
			for side in [-1, 1]:
				c.draw_line(p + Vector2(0, 8), p + Vector2(side * 9, -8), Color("c1d074"), 3)
				c.draw_line(p + Vector2(0, 5), p + Vector2(side * 12, -1), Color("91b55d"), 4)
			c.draw_line(p + Vector2(0, 8), p + Vector2(1, -14), Color("d4da89"), 3)
		"mushroom":
			c.draw_rect(Rect2(p + Vector2(-3, -1), Vector2(6, 13)), Color("efe1b3"))
			c.draw_circle(p + Vector2(0, -5), 10, Color("b66653"))
			c.draw_rect(Rect2(p + Vector2(-10, -4), Vector2(20, 5)), Color("db9170"))
			c.draw_rect(Rect2(p + Vector2(-5, -9), Vector2(4, 3)), Color("fae4b0"))
		"stump":
			c.draw_rect(Rect2(p + Vector2(-10, -3), Vector2(20, 18)), Color("84593d"))
			c.draw_circle(p + Vector2(0, -4), 11, Color("c6a277"))
			c.draw_arc(p + Vector2(0, -4), 6, 0, TAU, 12, Color("927149"), 2)

static func icon(kind: String) -> Texture2D:
	if Delivered.RESOURCES.has(kind):return Delivered.RESOURCES[kind][24]
	var img = Image.create(20, 20, false, Image.FORMAT_RGBA8)
	for y in range(4, 18):
		for x in range(2, 18):
			img.set_pixel(x, y, (Color("98ac6d") if y < 8 else Color("a47b4e")) if kind == "soil" else Color("c6a277"))
	return ImageTexture.create_from_image(img)

# Static eight-cell chunks retain these draw commands until occupancy changes.
static func draw_region(c: CanvasItem,world,tile: Vector2,box: Rect2i):
	cache_ground(world,tile)
	if not region_meshes.has(box):
		var points=PackedVector3Array();var colors=PackedColorArray();var indices=PackedInt32Array()
		for y in range(box.position.y,box.end.y):
			for x in range(box.position.x,box.end.x):
				var row=ground_cells[y*world.W+x];var base=points.size()
				for i in range(4):points.append(Vector3(row.points[i].x,row.points[i].y,0));colors.append(row.colors[i])
				for index in [0,1,2,0,2,3]:indices.append(base+index)
		var arrays=[];arrays.resize(Mesh.ARRAY_MAX);arrays[Mesh.ARRAY_VERTEX]=points;arrays[Mesh.ARRAY_COLOR]=colors;arrays[Mesh.ARRAY_INDEX]=indices
		var mesh=ArrayMesh.new();mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays);region_meshes[box]=mesh
	c.draw_mesh(region_meshes[box],null)
	for y in range(box.position.y,box.end.y):
		for x in range(box.position.x,box.end.x):
			var row=ground_cells[y*world.W+x];var cell=Vector2i(x,y)
			if row.decor!="" and not world.floors.has(cell) and not world.live_structure(cell) and not world.rocks.has(cell) and not world.natural.has(cell):Ground.paint(c,row.decor,(Vector2(cell)+Vector2(0.5,0.5))*tile+row.offset,0.8)
