extends RefCounted
## Withdrawal permission: independent of filters, delivery, ownership and pathfinding.
static func key(a)->String:return a.get("work_key",a.get("sleep_key","a%d"%a.get("id",-1)))
static func cell_key(p)->String:return "%d,%d"%[p.x,p.y]
static func changed(w):
	for z in w.zones:
		var valid={}
		for cell in z.cells:valid[cell_key(cell)]=true
		for cell in z.get("access_cells",{}).keys():
			if not valid.has(cell):z.access_cells.erase(cell)
	w.set_meta("access_revision",w.get_meta("access_revision",0)+1);w.stock_revision+=1
static func index(w)->Dictionary:
	var revision=w.get_meta("access_revision",0);var cache=w.get_meta("access_cache",{})
	if cache.get("revision",-1)==revision:return cache.cells
	var cells={};var people={}
	for a in w.Sleep.people(w).values():
		if a.has("home_id") and not a.get("dead",false):
			if not people.has(a.home_id):people[a.home_id]=[]
			people[a.home_id].append(key(a))
	for z in w.zones:
		if z.kind!="stockpile":continue
		for p in z.cells:cells[p]={"zone":z,"residents":people.get(w.home_cells.get(p,-1),[])}
	w.set_meta("access_cache",{"revision":revision,"cells":cells});return cells
static func allowed_at(w,p,a)->bool:
	var row=index(w).get(p,{})
	if row.is_empty():return true
	var manual=row.zone.get("access_cells",{}).get(cell_key(p),{})
	if manual.has(key(a)):return manual[key(a)]
	return row.residents.is_empty() or key(a) in row.residents
static func can_take(w,row,a)->bool:
	return row.get("location","ground")!="ground" or allowed_at(w,row.pos,a)
static func set_permission(w,z,key_value:String,value:bool):
	if not z.has("access_cells"):z.access_cells={}
	for p in z.cells:
		var k=cell_key(p)
		if not z.access_cells.has(k):z.access_cells[k]={}
		z.access_cells[k][key_value]=value
	changed(w)
static func merge(destination,other):
	if not destination.has("access_cells"):destination.access_cells={}
	for p in other.cells:
		var k=cell_key(p)
		if other.get("access_cells",{}).has(k):destination.access_cells[k]=other.access_cells[k].duplicate()
