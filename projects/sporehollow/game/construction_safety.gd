extends RefCounted
# A connected footprint can only disconnect components touching its perimeter.
# Check that neighborhood first; never rebuild two whole-map fields per job.
static var cache={}
static func needed(w,j)->bool:
	if w.BUILD.get(j.kind,{}).get("layer")=="floor" or j.kind in w.Buildings.DOORS:return false
	var touching=0
	for q in w.Buildings.perimeter(j.kind,j.pos):
		if not w.walkable(q):touching+=1
	return touching>=2
static func open(w,p,excluded:Dictionary,passability:Dictionary)->bool:
	if excluded.has(p):return false
	if not passability.has(p):passability[p]=w.walkable(p)
	return passability[p]
static func locally_connected(w,goals:Array,excluded:Dictionary,passability:Dictionary)->bool:
	if goals.size()<2:return true
	var area=Rect2i(goals[0],Vector2i.ONE)
	for p in goals:area=area.expand(p)
	area=area.grow(3)
	var pending=[goals[0]];var seen={goals[0]:true};var i=0;var left={}
	for p in goals:left[p]=true
	left.erase(goals[0])
	while i<pending.size():
		var p=pending[i];i+=1
		for q in w.neighbors(p):
			if seen.has(q) or not area.has_point(q) or not open(w,q,excluded,passability):continue
			seen[q]=true;pending.append(q);left.erase(q)
			if left.is_empty():return true
	return false
static func analyze(w,j)->Dictionary:
	var excluded={};var passability={}
	for p in w.Buildings.cells(j.kind,j.pos):excluded[p]=true
	var goals=w.Buildings.perimeter(j.kind,j.pos).filter(func(p):return open(w,p,excluded,passability))
	var result={"sealed":{},"exterior":false}
	if locally_connected(w,goals,excluded,passability):return result
	var outside={}
	for start in goals:
		if outside.has(start) or result.sealed.has(start):continue
		var pending=[start];var seen={start:true};var i=0;var escaped=false
		while i<pending.size():
			var p=pending[i];i+=1
			if outside.has(p) or p.x==0 or p.y==0 or p.x==w.W-1 or p.y==w.H-1:escaped=true;break
			for q in w.neighbors(p):
				if seen.has(q) or not open(w,q,excluded,passability):continue
				seen[q]=true;pending.append(q)
		if escaped:
			result.exterior=true
			for p in seen:outside[p]=true
		else:
			for p in seen:result.sealed[p]=true
	return result
static func states(w,j)->Dictionary:
	var key=[w.get_instance_id(),w.navigation_revision,j.pos,j.kind]
	if cache.has(key):return cache[key]
	if cache.size()>=16:cache.clear()
	var site=w.structures.get(j.pos,{})
	var own_site=site.get("status")=="building" and site.get("id")==j.get("site_id",-1)
	if not own_site and w.Buildings.cells(j.kind,j.pos).all(func(p):return w.blocks(p)):
		return {"sealed":{},"exterior":false} # Upgrade does not close a new passage.
	if own_site:w.structures.erase(j.pos)
	var result=analyze(w,j)
	if own_site:w.structures[j.pos]=site
	cache[key]=result;return result
static func work_goals(w,j,_a,goals:Array)->Array:
	if not needed(w,j):return goals
	var r=states(w,j)
	return goals.filter(func(p):return not r.sealed.has(p)) if r.exterior else goals
static func can_finish(w,j,a)->bool:
	if w.Merchant.visible(w) and w.MERCHANT_CELL in w.Buildings.cells(j.kind,j.pos):return false
	if not needed(w,j):return true
	var r=states(w,j)
	if not r.exterior:return true # Do not modify pre-existing sealed rooms.
	for worker in w.workers.values():
		if worker.get("placed",false) and worker.hp>0 and r.sealed.has(worker.pos):return false
	if w.Merchant.visible(w) and r.sealed.has(w.MERCHANT_CELL):return false
	return not r.sealed.has(a.pos)
