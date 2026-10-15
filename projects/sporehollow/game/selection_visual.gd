extends RefCounted
const COLOR=Color("b8f8ff")
static func outline(g,rect:Rect2):
	var scale=maxf(0.05,g.camera.zoom.x)
	g.draw_rect(rect,Color("243237"),false,4.0/scale)
	g.draw_rect(rect,COLOR,false,2.0/scale)
static func forbidden(g,p:Vector2,partial:bool=false):
	var scale=maxf(0.05,g.camera.zoom.x)
	var q=p+Vector2(12,-12)/scale
	for stroke in [[7.0,Color("242126")],[4.8,Color("fff0dc")],[3.0,Color("ff554d")]]:
		for pair in [[Vector2(-6,-6),Vector2(6,6)],[Vector2(-6,6),Vector2(6,-6)]]:
			g.draw_line(q+pair[0]/scale,q+pair[1]/scale,stroke[1],stroke[0]/scale)
	if partial:
		g.draw_circle(q+Vector2(9,6)/scale,3.5/scale,Color("242126"))
		g.draw_circle(q+Vector2(9,6)/scale,2/scale,Color("ffd27d"))
static func tree_rect(g,p:Vector2i)->Rect2:
	var data=g.Direction.ASSETS["world.tree_"+g.StoryView.tree_variant(g.world,p)+"_canopy"]
	return Rect2(g.StoryView.tree_foot(g,p)-data.anchor*g.StoryView.TREE_SCALE,data.texture.get_size()*g.StoryView.TREE_SCALE)
static func tree_at(g,point:Vector2):
	var result=null;var front=-INF
	for p in g.world.trees:
		var rect=tree_rect(g,p)
		# Rounded crown hit area excludes transparent corners; no image readback per click.
		if not rect.has_point(point):continue
		var local=(point-rect.get_center())/(rect.size*0.5)
		if local.length_squared()>1.05 and not Rect2(g.StoryView.tree_foot(g,p)-Vector2(10,28),Vector2(20,32)).has_point(point):continue
		var depth=g.StoryView.tree_foot(g,p).y
		if depth>=front:front=depth;result=p
	return result
static func building_rect(g,kind:String,p:Vector2i)->Rect2:
	return Rect2(Vector2(p)*g.TILE,Vector2(2,2)*g.TILE if kind in g.world.Buildings.BENCHES else g.TILE)
