extends RefCounted
## Rebuilt only at structural topology changes. Assignments are keyed by bed ID.
static func rebuild(w):
	var remaining=w.indoor.duplicate();var groups=[]
	while not remaining.is_empty():
		var stack=[remaining.keys()[0]];var cells={};var doors={}
		while not stack.is_empty():
			var q=stack.pop_back()
			if cells.has(q):continue
			if not remaining.has(q):continue
			remaining.erase(q);cells[q]=true
			for n in w.neighbors(q):
				if remaining.has(n):stack.append(n)
				var b=w.structures.get(n,{})
				if w.Buildings.enclosure(b) and b.kind in w.Buildings.DOORS:
					doors[n]=true
		var entrance=false
		for d in doors:
			for n in w.neighbors(d):
				if not cells.has(n) and w.walkable(n):entrance=true
		if entrance and cells.keys().all(func(q):return w.floors.get(q,{}).get("status")=="ready"):groups.append({"cells":cells,"doors":doors})
	var old=w.homes;var fresh={};var used={};w.home_cells.clear()
	groups.sort_custom(func(a,b):return a.cells.size()>b.cells.size())
	for group in groups:
		var best=-1;var overlap=0
		for id in old:
			if used.has(id):continue
			var count=0
			for q in group.cells:
				if old[id].cells.has(q):count+=1
			if count>overlap:best=id;overlap=count
		if best<0:best=w.next_home_id;w.next_home_id+=1
		used[best]=true;group.id=best;group.beds=[];group.fixtures=[];group.damaged=false
		for q in group.cells:
			w.home_cells[q]=best
			var b=w.structures.get(q,{})
			if b.get("status")=="ready":
				if b.kind=="bed":group.beds.append({"id":b.id,"pos":q})
				else:group.fixtures.append(w.Buildings.NAMES.get(b.kind,b.kind))
			for n in w.neighbors(q):
				var boundary=w.structures.get(n,{})
				if w.Buildings.enclosure(boundary) and boundary.hp<boundary.max_hp:group.damaged=true
		group.beds.sort_custom(func(a,b):return a.id<b.id);fresh[best]=group
	w.homes=fresh;w.housing_dirty=true;w.Access.changed(w)
static func at(w,p:Vector2i)->Dictionary:return w.homes.get(w.home_cells.get(p,-1),{})
static func bed(w,a)->Dictionary:
	var h=w.homes.get(a.get("home_id",-1),{})
	for b in h.get("beds",[]):
		if b.id==a.get("bed_id",-1):return b
	return {}
static func residents(w,id:int)->Array:
	var rows=w.Sleep.people(w).values().filter(func(a):return a.get("home_id",-1)==id)
	rows.sort_custom(func(a,b):return a.get("home_order",0)<b.get("home_order",0));return rows
static func damaged(w,h)->bool:
	for q in h.cells:
		for n in w.neighbors(q):
			var b=w.structures.get(n,{})
			if w.Buildings.enclosure(b) and b.hp<b.max_hp:return true
	return false
static func title(w,h)->String:
	var people=residents(w,h.id)
	return "家屋" if people.is_empty() else w.PlayerEvents.name_of(w,people[0])+("の家" if people.size()==1 else "達の家")
static func usable(w,a,b)->bool:
	return not w.Jobs.path_to(w,a.pos,w.Buildings.perimeter("bed",b.pos).filter(func(q):return w.home_cells.get(q,-1)==w.home_cells.get(b.pos,-2))).is_empty()
static func assign(w,id:int,key:String,manual:bool=true)->bool:
	var h=w.homes.get(id,{});var a=w.Sleep.people(w).get(key,{})
	if h.is_empty() or a.is_empty() or a.get("dead",false) or a.get("lost",false) or not a.get("placed",false):return false
	var occupied={}
	for other in w.Sleep.people(w).values():
		if other!=a:occupied[other.get("bed_id",-1)]=true
	for b in h.beds:
		if not occupied.has(b.id) and usable(w,a,b):
			if a.get("home_id",-1)!=id:
				w.set_meta("home_order",w.get_meta("home_order",0)+1);a.home_order=w.get_meta("home_order")
			w.Access.changed(w)
			a.erase("home_manual_optout");a.home_id=id;a.bed_id=b.id;a.home_manual=manual;a.erase("rest_target");a.erase("rest_reason");return true
	return false
static func assign_pending(w):
	var roster=w.Sleep.people(w).values().map(func(a):return [w.Sleep.actor_key(a),a.get("dead",false),a.get("lost",false),a.get("placed",false)])
	if w.get_meta("housing_roster",[])!=roster:w.housing_dirty=true;w.set_meta("housing_roster",roster)
	if not w.housing_dirty:return
	w.housing_dirty=false;w.Access.changed(w)
	for a in w.Sleep.people(w).values():
		if a.has("bed_id"):
			for id in w.homes:
				if w.homes[id].beds.any(func(b):return b.id==a.bed_id):a.home_id=id;break
		if bed(w,a).is_empty() or a.get("dead",false) or a.get("lost",false):a.erase("home_id");a.erase("bed_id");a.erase("home_manual")
	var ids=w.homes.keys();ids.sort();var keys=w.Sleep.people(w).keys();keys.sort()
	for id in ids:
		var h=w.homes[id]
		if not w.zones.any(func(z):return z.kind=="residential" and z.cells.any(func(q):return h.cells.has(q))):continue
		for key in keys:
			var a=w.Sleep.people(w)[key]
			if not a.has("home_id") and a.get("placed",false) and not a.get("dead",false) and not a.get("lost",false) and not a.get("home_manual_optout",false):assign(w,id,key,false)
