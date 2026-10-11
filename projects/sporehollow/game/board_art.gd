extends RefCounted
const Delivered = preload("res://game/delivered_art.gd")
const Biome=preload("res://game/biome_map.gd")
# Shared vertex colors make contiguous soil/grass/rock transitions at every zoom.
# Cached map fields and coordinate hashes never consume simulation RNG.
static func draw_ground(c: CanvasItem, world, tile: Vector2, _time: float = 0):
	var inv=c.get_canvas_transform().affine_inverse()
	var top=inv*Vector2.ZERO;var bottom=inv*c.get_viewport_rect().size
	c.draw_rect(Rect2(top-Vector2(100,100),bottom-top+Vector2(200,200)),Color("344c3b"))
	for y in range(maxi(0,floori(top.y/tile.y)-1),mini(world.H,ceili(bottom.y/tile.y)+1)):
		for x in range(maxi(0,floori(top.x/tile.x)-1),mini(world.W,ceili(bottom.x/tile.x)+1)):
			var p=Vector2(x,y)*tile;var f=Biome.field(world,Vector2i(x,y))
			var corners=PackedVector2Array([p,p+Vector2(tile.x,0),p+tile,p+Vector2(0,tile.y)])
			var colors=PackedColorArray()
			for q in [Vector2i(x,y),Vector2i(x+1,y),Vector2i(x+1,y+1),Vector2i(x,y+1)]:
				var rgb=world.terrain.vertices[q.y*(world.W+1)+q.x];colors.append(Color(rgb[0],rgb[1],rgb[2]))
			c.draw_polygon(corners,colors)
			var density=f[0]*(1.0-f[2])*(1.0-f[3]*0.65)
			for i in range(4):
				if Biome.unit(world.terrain.seed,x,y,103+i)>density*0.8:continue
				var at=p+Vector2(3+floorf(Biome.unit(world.terrain.seed,x,y,111+i)*(tile.x-8)),7+floorf(Biome.unit(world.terrain.seed,x,y,127+i)*(tile.y-12)))
				c.draw_rect(Rect2(at,Vector2(2,4)),Color("6b874b"))
				c.draw_rect(Rect2(at+Vector2(3,-2),Vector2(2,5)),Color("9bad67"))
				if f[1]>0.45:c.draw_rect(Rect2(at+Vector2(-3,1),Vector2(3,2)),Color("557747"))
			# Low pebbles continue around deposits; bounded in-tile footprints avoid clipped edge objects.
			for i in range(3):
				if Biome.unit(world.terrain.seed,x,y,149+i)>f[2]*0.65:continue
				var at=p+Vector2(4+floorf(Biome.unit(world.terrain.seed,x,y,157+i)*(tile.x-12)),7+floorf(Biome.unit(world.terrain.seed,x,y,163+i)*(tile.y-16)))
				c.draw_rect(Rect2(at+Vector2(-1,2),Vector2(7,3)),Color("77795e"))
				c.draw_rect(Rect2(at,Vector2(5,3)),Color("b3af8d"))
				c.draw_rect(Rect2(at+Vector2(1,0),Vector2(3,1)),Color("c8c2a1"))
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
