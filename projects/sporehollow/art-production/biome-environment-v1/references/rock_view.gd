extends RefCounted
## Adopted concept translated to native pixel drawing; collision/placement never read this renderer.
const TOP=Color("bcb59c")
const RIM=Color("d0c7ab")
const FACE=Color("777461")
const DARK=Color("5c5c50")
const MOSS=Color("89984c")
const HEIGHT=12.0

static func mask(w,p: Vector2i) -> int:
	var value=0
	for i in range(4):
		if w.rocks.has(p+[Vector2i.UP,Vector2i.RIGHT,Vector2i.DOWN,Vector2i.LEFT][i]):value|=1<<i
	return value

static func geometry(tile: Vector2,m: int) -> Dictionary:
	var left=-tile.x/2+(0 if m&8 else 3)
	var right=tile.x/2-(0 if m&2 else 3)
	var top=-tile.y/2+(0 if m&1 else 4)
	var bottom=tile.y/2-(0 if m&4 else HEIGHT+3)
	return {"left":left,"right":right,"top":top,"bottom":bottom,"front":not bool(m&4),"north":not bool(m&1),"east":not bool(m&2),"west":not bool(m&8)}

static func unit(w,p: Vector2i,salt: int) -> float:return w.Biome.unit(w.seed_value,p.x,p.y,salt)

static func ground(g):
	var w=g.world;var cells={}
	for p in w.rocks.keys()+w.mined_rock_cells:
		for dy in range(-1,2):
			for dx in range(-1,2):
				var q=p+Vector2i(dx,dy)
				if w.inside(q):cells[q]=true
	for p in cells:
		if w.floors.has(p) or w.live_structure(p):continue
		var corner=Vector2(p)*g.TILE
		for i in range(12):
			var x=2+floori(unit(w,p,200+i*3)*(g.TILE.x-6)/2)*2
			var y=2+floori(unit(w,p,201+i*3)*(g.TILE.y-6)/2)*2
			var r=Rect2(corner+Vector2(x,y),Vector2(2+2*(i%2),2))
			g.draw_rect(r,Color("ab9d77") if i%3 else Color("8f9275"))
		if not w.rocks.has(p) and unit(w,p,253)>0.55:
			var q=g.center(p)+Vector2(6,-5)
			g.draw_rect(Rect2(q+Vector2(-4,2),Vector2(10,4)),Color(0.22,0.26,0.18,0.22))
			g.draw_rect(Rect2(q-Vector2(3,1),Vector2(8,4)),TOP);g.draw_rect(Rect2(q+Vector2(-3,3),Vector2(8,2)),FACE)
	for p in w.mined_rock_cells:
		if w.floors.has(p) or w.live_structure(p) or w.rocks.has(p):continue
		var q=g.center(p)
		g.draw_colored_polygon(PackedVector2Array([q+Vector2(-16,-8),q+Vector2(-8,-13),q+Vector2(14,-10),q+Vector2(18,7),q+Vector2(6,13),q+Vector2(-17,8)]),Color("90876b"))
		g.draw_line(q+Vector2(-14,-7),q+Vector2(12,-9),DARK,2);g.draw_line(q+Vector2(-14,9),q+Vector2(8,11),RIM,2)

static func rock(g,p: Vector2i):
	var w=g.world;var m=mask(w,p);var shape=geometry(g.TILE,m);var c=g.center(p)
	var x0=shape.left;var x1=shape.right;var y0=shape.top;var y1=shape.bottom
	var tl=4 if shape.north and shape.west else 0;var tr=4 if shape.north and shape.east else 0
	var bl=4 if shape.front and shape.west else 0;var br=4 if shape.front and shape.east else 0
	if shape.front:
		g.draw_colored_polygon(PackedVector2Array([c+Vector2(x0+bl,y1),c+Vector2(x1-br,y1),c+Vector2(x1-br,y1+HEIGHT),c+Vector2(x0+bl,y1+HEIGHT)]),FACE)
		g.draw_rect(Rect2(c+Vector2(x0+4,y1+HEIGHT-1),Vector2(x1-x0-8,3)),Color(0.16,0.21,0.13,0.28))
		for i in range(4):
			var x=x0+6+floori(unit(w,p,300+i)*(x1-x0-14)/2)*2
			g.draw_rect(Rect2(c+Vector2(x,y1+2),Vector2(2,6+2*(i%2))),DARK if i%2 else Color("938d76"))
	var roof=PackedVector2Array([c+Vector2(x0+tl,y0),c+Vector2(x1-tr,y0),c+Vector2(x1,y0+tr),c+Vector2(x1,y1-br),c+Vector2(x1-br,y1),c+Vector2(x0+bl,y1),c+Vector2(x0,y1-bl),c+Vector2(x0,y0+tl)])
	g.draw_colored_polygon(roof,TOP.lightened((unit(w,p,400)-0.5)*0.07))
	if shape.north:g.draw_line(c+Vector2(x0+tl,y0),c+Vector2(x1-tr,y0),RIM,2)
	if shape.west:g.draw_line(c+Vector2(x0,y0+tl),c+Vector2(x0,y1-bl),RIM,2)
	if shape.east:g.draw_line(c+Vector2(x1,y0+tr),c+Vector2(x1,y1-br),DARK,2)
	if shape.front:g.draw_line(c+Vector2(x0+bl,y1),c+Vector2(x1-br,y1),RIM,2)
	for i in range(7):
		var x=x0+6+floori(unit(w,p,500+i*2)*maxf(2,x1-x0-14)/2)*2
		var y=y0+6+floori(unit(w,p,501+i*2)*maxf(2,y1-y0-12)/2)*2
		g.draw_rect(Rect2(c+Vector2(x,y),Vector2(4,2)),RIM if i%2 else Color("aaa48c"))
	# Moss and small cracks stay subordinate to the stone silhouette.
	if shape.front:
		for i in range(3):g.draw_rect(Rect2(c+Vector2(x0+6+i*8,y1-2),Vector2(4,2)),MOSS if unit(w,p,600+i)>0.35 else TOP)
