extends RefCounted
# Exact candidate function from 8e3a1e8 for headless A/B only.
static func candidates(g) -> Array:
	var result = []
	for a in g.world.animals:
		if a.placed: result.append({"class": "animal", "id": a.id, "point": g.actor_pixel("a%d" % a.id, a.pos)})
	var cells = g.world.natural.keys()
	for item in g.world.field_items:
		if item.get("location","ground")!="ground":continue
		if item.pos not in cells: cells.append(item.pos)
	for cell in cells: result.append({"class": "resource", "id": cell, "point": g.center(cell)})
	for cell in g.world.trees: result.append({"class":"tree","id":cell,"point":g.center(cell)})
	for cell in g.world.structures:
		if g.world.live_structure(cell) and g.selection_layer!="floor": result.append({"class":"structure","id":cell,"point":g.center(cell)})
	for cell in g.world.floors:
		if g.world.floors[cell].status=="ready" and (g.selection_layer=="floor" or not g.world.live_structure(cell)): result.append({"class":"floor","id":cell,"point":g.center(cell)})
	result = result.filter(func(c): return g.group<0 or (g.group==0 and c["class"] in ["structure","floor"]) or (g.group==1 and c["class"]=="animal") or (g.group==2 and c["class"]=="resource"))
	result.sort_custom(func(a,b):
		var da = g.drag_start.distance_squared_to(a.point)
		var db = g.drag_start.distance_squared_to(b.point)
		return da < db if da != db else str(a["class"]) + str(a.id) < str(b["class"]) + str(b.id))
	return result
