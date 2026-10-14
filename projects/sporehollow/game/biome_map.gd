extends RefCounted
## Versioned scenery and placement only. Never used by movement or building rules.
const VERSION=5
# Normalized regional scale, transition width and obstacle density; saved in new terrain.
const SETTINGS={"region_scale":1.0,"region_thresholds":{"rocky":0.43,"woodland":0.40,"dry":0.42,"lush":0.48},"boundary_width":1.0,"tree_density":1.0,"rock_clusters_per_1700":1,"mountain_groups_per_1700":0.5}
static func normalized(w,p: Vector2) -> Vector2:
	return p*Vector2(50.0/w.W,34.0/w.H)
const DIRECTIONS=[Vector2i.UP,Vector2i.RIGHT,Vector2i.DOWN,Vector2i.LEFT]
const FOREST=preload("res://game/forest_pattern.gd")

static func unit(seed_number: int,x: int,y: int,salt: int=0) -> float:
	var n=posmod(seed_number*104729+x*73856093+y*19349663+salt*83492791,2147483647)
	n=posmod((n^(n>>13))*48271,2147483647)
	return float(n)/2147483647.0

static func noise(seed_number: int,p: Vector2,salt: int) -> float:
	var cell=Vector2i(floori(p.x),floori(p.y))
	var f=p-Vector2(cell);f=f*f*(Vector2(3,3)-2.0*f)
	return lerpf(lerpf(unit(seed_number,cell.x,cell.y,salt),unit(seed_number,cell.x+1,cell.y,salt),f.x),lerpf(unit(seed_number,cell.x,cell.y+1,salt),unit(seed_number,cell.x+1,cell.y+1,salt),f.x),f.y)

static func clearing(p: Vector2,seed_number: int) -> float:
	var d=(p-Vector2(25,17))/Vector2(9,7)
	return smoothstep(0.72,0.72+0.78*SETTINGS.boundary_width,d.length()+0.16*(noise(seed_number,p*0.18,17)-0.5))

static func lobes(seed_number: int) -> Array:
	var r=RandomNumberGenerator.new();r.seed=seed_number*1013+733
	var rows=[];var rotation=r.randf_range(-PI,PI)
	for kind in range(3):
		var a=rotation+kind*TAU/3.0
		var center=Vector2(25,17)+Vector2(cos(a)*18,sin(a)*12)
		for i in range(3):
			rows.append({"kind":kind,"center":center+Vector2(r.randf_range(-7,7),r.randf_range(-5,5)),"radius":Vector2(r.randf_range(5,10),r.randf_range(4,8)),"strength":r.randf_range(0.45,0.85)})
	return rows

static func sample(seed_number: int,p: Vector2,blobs: Array) -> Array:
	var fields=[0.0,0.0,0.0]
	var original=p
	p+=Vector2(noise(seed_number,p*0.16,301)-0.5,noise(seed_number,p*0.16,307)-0.5)*7.0
	for blob in blobs:
		var d=(p-blob.center)/blob.radius
		fields[blob.kind]+=exp(-d.length_squared()*1.5)*blob.strength
	var broad=noise(seed_number,p*0.10,29)
	var fine=noise(seed_number,p*0.29,53)
	var margin=clearing(original,seed_number)
	var rock=clampf(fields[1]*(0.65+0.55*fine),0,1)*margin
	var dry=clampf(fields[2]*0.8+rock*0.6,0,1)*margin
	var wood=clampf(fields[0]*(0.7+0.45*broad),0,1)*margin*(1.0-rock*0.85)
	var lush=clampf(0.15+0.7*broad+wood*0.24-dry*0.65-rock*0.55,0,1)
	lush=lerpf(0.22,lush,0.3+0.7*margin)
	# Small satellite patches are scenery; the central protected area stays walkable.
	var patch=noise(seed_number,original*0.38,311)
	wood=maxf(wood,smoothstep(0.68,0.92,patch)*0.5*margin)
	var sand=smoothstep(0.48,0.78,noise(seed_number,p*0.17,317))*smoothstep(0.12,0.55,dry)*(1.0-rock)
	var clay=smoothstep(0.12,0.36,rock)*(1.0-smoothstep(0.48,0.8,rock))*smoothstep(0.25,0.72,noise(seed_number,p*0.31,331))
	var soil=clampf(dry*0.45+smoothstep(0.6,0.88,patch)*0.48,0,0.8)*(1.0-rock)
	return [lush,wood,rock,dry,fine,sand,clay,soil]

static func color_for(f: Array) -> Color:
	var color=Color("867961").lerp(Color("768057"),clampf(f[0]*1.5+f[1]*0.25,0,0.85))
	color=color.lerp(Color("6b7652"),f[1]*0.65)
	color=color.lerp(Color("94836a"),f[3]*0.78)
	color=color.lerp(Color("96917a"),f[2]*0.73)
	if f.size()>5:
		color=color.lerp(Color("987855"),clampf(f[7]*2.2,0,0.88)).lerp(Color("a18b69"),clampf(f[5]*1.5,0,0.92)).lerp(Color("626b70"),f[6]*0.88)
	return color.lightened((f[4]-0.5)*0.045)

static func generate(seed_number: int,width: int,height: int,version: int=VERSION) -> Dictionary:
	var blobs=lobes(seed_number);var fields=[];var vertices=[];var surface_vertices=[];var ground_weights=[]
	var scale=Vector2(50.0/width,34.0/height)/SETTINGS.region_scale
	for y in range(height):
		for x in range(width):fields.append(sample(seed_number,Vector2(x+0.5,y+0.5)*scale,blobs))
	for y in range(height+1):
		for x in range(width+1):
			# Average neighboring samples: shared vertices, no per-cell patch seams.
			var f=[0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0]
			for dy in [-1,0]:
				for dx in [-1,0]:
					var row=fields[clampi(y+dy,0,height-1)*width+clampi(x+dx,0,width-1)]
					for i in range(f.size()):f[i]+=row[i]*0.25
			var color=color_for(f);vertices.append([color.r,color.g,color.b])
			ground_weights.append([clampf((f[0]*1.65+f[1]*0.25)*(1.0-f[2]),0,0.9),f[5],f[6],f[2]])
			surface_vertices.append([smoothstep(0.25,0.58,f[2])*0.92,smoothstep(0.49,0.80,f[2])])
	var result={"version":version,"generation_version":version,"settings":SETTINGS.duplicate(),"seed":seed_number,"width":width,"height":height,"fields":fields,"vertices":vertices,"surface_vertices":surface_vertices,"ground_weights":ground_weights}
	classify(result)
	return result

static func prepare(w):
	# Missing terrain in a legacy save changes scenery only, never its objects.
	w.terrain=w.campaign.get("biome_map",{})
	if w.terrain.is_empty():w.terrain=generate(w.seed_value,w.W,w.H,VERSION if w.campaign.get("biome_new_map",false) else 1)
	# Add only derived scenery metadata to old maps. Keep their fields, vertices and version.
	if not w.terrain.has("regions") or not w.terrain.has("materials"):classify(w.terrain)
	if not w.terrain.has("generation_version"):w.terrain.generation_version=int(w.terrain.get("version",1))
	w.campaign.biome_map=w.terrain.duplicate(true)
	prepare_nature(w)
	if w.campaign.has("biome_natural"):
		w.natural.clear()
		for row in w.campaign.biome_natural:w.natural[Vector2i(row.pos[0],row.pos[1])]=row.kind

static func field(w,p: Vector2i) -> Array:
	return w.terrain.fields[p.y*w.W+p.x]

static func region_for(f: Array) -> String:
	if f[2]>SETTINGS.region_thresholds.rocky:return "rocky"
	if f[1]>SETTINGS.region_thresholds.woodland:return "woodland"
	if f[3]>SETTINGS.region_thresholds.dry:return "dry"
	if f[0]>SETTINGS.region_thresholds.lush:return "lush"
	return "open"

static func classify(data: Dictionary):
	var regions=[];var materials=[]
	for f in data.fields:
		regions.append(region_for(f))
		# Continuous thresholds produce grass/soil/gravel/bedrock bands; obstacles
		# are deliberately absent from this immutable ground-material layer.
		var material_name="grass"
		if f[2]>0.72:material_name="bedrock"
		elif f[2]>0.43:material_name="gravel"
		elif f[2]>0.29 or f[3]>0.42 or (f[1]>0.50 and f[4]<0.43):material_name="soil"
		if data.get("version",1)>=4 and f.size()>5 and material_name not in ["bedrock","gravel"]:
			if f[6]>0.22:material_name="clay"
			elif f[5]>0.20:material_name="sand"
			elif f[7]>0.24:material_name="soil"
		materials.append(material_name)
	data.regions=regions;data.materials=materials;data.surface_schema=1

static func kind(w,p: Vector2i) -> String:
	return w.terrain.regions[p.y*w.W+p.x]

static func material(w,p: Vector2i) -> String:
	return w.terrain.materials[p.y*w.W+p.x]

static func resource_weight(w,p: Vector2i,resource: String) -> float:
	var f=field(w,p)
	match resource:
		"stump":return 0.005+pow(f[1],3)*4.0
		"mushroom":return 0.005+pow(f[0],3)*(0.25+f[1])*2.0
		_:return 0.01+pow(f[0],3)*3.0

static func available(w,p: Vector2i) -> bool:
	return w.walkable(p) and not w.occupied(p) and not w.live_structure(p) and not w.floors.has(p) and not w.natural.has(p) and not w.rocks.has(p) and not w.neighbors(p).any(func(q):return not w.Mountains.at(w,q).is_empty()) and w.items_at(p).is_empty() and not w.jobs.any(func(j):return j.pos==p) and p not in w.storage_cells and p not in w.entries and w.distance(p,w.logistics_entry)>3 and p not in w.Story.idol_cells(w)

static func populate(w):
	if not w.campaign.get("biome_new_map",false):return
	w.Mountains.populate(w)
	# Sparse trees follow a broad woodland patch field, with gaps between trunks.
	for y in range(1,w.H-1):
		for x in range(1,w.W-1):
			var p=Vector2i(x,y);var f=field(w,p)
			var patch=noise(w.seed_value,Vector2(p)*0.21,113)
			if f[1]<0.28 or patch<0.32 or unit(w.seed_value,x,y,71)>f[1]*(0.22+patch*0.48)*SETTINGS.tree_density or protected(w,p) or not available(w,p):continue
			if [-1,0,1].any(func(dy):return [-1,0,1].any(func(dx):return w.trees.has(p+Vector2i(dx,dy)))):continue
			w.trees[p]="biome-tree-%d-%d"%[x,y]
	place_rocks(w)
	var repairs=repair_connections(w)
	w.terrain.placement={"version":VERSION,"repair_removed_cells":repairs,"rock_cells":w.rocks.size(),"tree_cells":w.trees.size(),"rock_layout_version":2}
	w.story.trees=[]
	for p in w.trees:w.story.trees.append({"id":w.trees[p],"position":[p.x,p.y]})
	# Initial harvestables use existing kinds and caps, with weighted sampling.
	var r=RandomNumberGenerator.new();r.seed=w.seed_value*2371+419
	var harvest_sites=[]
	for y in range(w.H):
		for x in range(w.W):
			var p=Vector2i(x,y)
			if available(w,p) and clearing(normalized(w,Vector2(p)),w.seed_value)>=0.3:harvest_sites.append(p)
	for resource in ["weed","mushroom","stump"]:
		for i in range(int(w.nature_config.caps.get(resource,0))):
			if w.natural.size()>=w.nature_config.limit:break
			var sites=[];var total=0.0
			for p in harvest_sites:
				if w.natural.has(p):continue
				var weight=resource_weight(w,p,resource);total+=weight;sites.append([p,total])
			if sites.is_empty():break
			var roll=r.randf()*total
			for row in sites:
				if roll<=row[1]:w.natural[row[0]]=resource;w.metrics[resource+"_spawned"]+=1;break
	w.campaign.erase("biome_new_map")
	w.Tasks.save(w);w.Story.persist(w);persist(w)

static func protected(w,p: Vector2i) -> bool:
	return p.x<=0 or p.y<=0 or p.x>=w.W-1 or p.y>=w.H-1 or clearing(normalized(w,Vector2(p)),w.seed_value)<0.8 or w.distance(p,w.MERCHANT_CELL)<=4 or w.entries.any(func(e):return w.distance(p,e)<=1) or w.distance(p,w.keeper.pos)<=2 or w.animals.any(func(a):return a.get("placed",false) and w.distance(p,a.pos)<=2)

static func rock_site(w,p: Vector2i) -> bool:
	return w.inside(p) and not protected(w,p) and field(w,p)[2]>0.43 and available(w,p)

static func place_rocks(w):
	# Rank broad-field 3x3 cores, then grow a few irregular elliptical shelves.
	# The core is deliberately solid: its center is reached by mining an edge.
	var cores=[];var eligible={}
	for y in range(w.H):
		for x in range(w.W):
			var p=Vector2i(x,y)
			if rock_site(w,p):eligible[p]=true
	for y in range(2,w.H-2):
		for x in range(2,w.W-2):
			var p=Vector2i(x,y);var valid=true
			for dy in range(-1,2):
				for dx in range(-1,2):
					if not eligible.has(p+Vector2i(dx,dy)):valid=false
			if valid:cores.append({"pos":p,"score":field(w,p)[2]+noise(w.seed_value,Vector2(p)*0.17,127)*0.18})
	cores.sort_custom(func(a,b):return a.score>b.score if a.score!=b.score else (a.pos.y<b.pos.y if a.pos.y!=b.pos.y else a.pos.x<b.pos.x))
	var selected=[]
	for row in cores:
		var p=row.pos
		if selected.any(func(q):return Vector2(p-q).length()<7.0):continue
		selected.append(p)
		if selected.size()>=ceili(w.W*w.H/1700.0*SETTINGS.rock_clusters_per_1700):break
	for center in selected:
		var radius=Vector2(2.4+unit(w.seed_value,center.x,center.y,139)*1.2,2.0+unit(w.seed_value,center.x,center.y,149))
		for y in range(maxi(1,center.y-4),mini(w.H-1,center.y+5)):
			for x in range(maxi(1,center.x-5),mini(w.W-1,center.x+6)):
				var p=Vector2i(x,y);var core=absi(x-center.x)<=1 and absi(y-center.y)<=1
				var d=Vector2(p-center)/radius
				if (core or d.length()<0.93+(noise(w.seed_value,Vector2(p)*0.36,157)-0.5)*0.45) and eligible.has(p):w.rocks[p]={"amount":w.Tasks.STONE_PER_ROCK,"forbidden":false}
	# A few isolated outcrops keep the adopted single-rock art useful without
	# substituting independently random cells for connected regional shelves.
	var isolated=0
	for y in range(1,w.H-1):
		for x in range(1,w.W-1):
			var p=Vector2i(x,y)
			if isolated>=12 or not eligible.has(p) or unit(w.seed_value,x,y,97)>0.035:continue
			if w.rocks.keys().any(func(q):return maxi(absi(q.x-p.x),absi(q.y-p.y))<=2):continue
			w.rocks[p]={"amount":w.Tasks.STONE_PER_ROCK,"forbidden":false};isolated+=1

	consolidate_rocks(w,eligible,cores)

static func consolidate_rocks(w,eligible: Dictionary,cores: Array):
	# Keep the previous generator's total resource budget, but place it as a
	# dense connected body rather than four spaced-out miniature shelves.
	var records=w.rocks.values().duplicate(true)
	if records.is_empty():return
	w.terrain.rock_layout_budget=records.size()
	var scattered=[]
	for p in w.rocks:
		if DIRECTIONS.all(func(d):return not w.rocks.has(p+d)):scattered.append(p)
	var islands={}
	for p in scattered:
		if islands.size()>=mini(4,records.size()/12):break
		islands[p]=true
	var candidates=eligible.duplicate()
	for p in islands:
		for dy in range(-2,3):
			for dx in range(-2,3):candidates.erase(p+Vector2i(dx,dy))
	# Prefer room for a solid core, not a high-noise site threaded between trees.
	var centers=[]
	for row in cores:
		var compactness=0.0
		for dy in range(-6,7):
			for dx in range(-6,7):
				var offset=Vector2i(dx,dy);var distance=Vector2(offset).length()
				if distance<=6.0 and candidates.has(row.pos+offset):compactness+=7.0-distance
		centers.append({"pos":row.pos,"score":compactness})
	centers.sort_custom(func(a,b):return a.score>b.score if a.score!=b.score else (a.pos.y<b.pos.y if a.pos.y!=b.pos.y else a.pos.x<b.pos.x))
	var result={};var frontier={};var origin=Vector2i.ZERO
	var remaining=records.size()-islands.size()
	while result.size()<remaining and not candidates.is_empty():
		if frontier.is_empty():
			# Start only when a region is exhausted; prefer the strongest full core.
			var found=false
			for row in centers:
				if candidates.has(row.pos):origin=row.pos;found=true;break
			if not found:origin=candidates.keys()[0]
			frontier[origin]=true
		var chosen=Vector2i.ZERO;var score=INF
		for p in frontier:
			var adjacent=0
			for d in DIRECTIONS:
				if result.has(p+d):adjacent+=1
			var distance=Vector2(p-origin)*Vector2(0.86,1.0)
			if seals_free_ground(w,p,result):continue
			var rank=distance.length()+noise(w.seed_value,Vector2(p)*0.28,619)*3.8-adjacent*0.8
			if rank<score:score=rank;chosen=p
		if score==INF:
			for p in frontier:candidates.erase(p)
			frontier.clear();continue
		frontier.erase(chosen);candidates.erase(chosen)
		result[chosen]=records[result.size()]
		for d in DIRECTIONS:
			var next=chosen+d
			if candidates.has(next):frontier[next]=true
	for p in islands:result[p]=records[result.size()]
	# The reserved islands can reduce the candidate pool in a very small legacy
	# map. Preserve every original unit without changing any mining rule.
	if result.size()<records.size():
		for p in eligible:
			if not result.has(p):result[p]=records[result.size()]
			if result.size()==records.size():break
	w.rocks=result

# A local eight-cell ring is sufficient to reject placements that can seal a
# previously connected passage. Run only during generation, never during draw.
static func seals_free_ground(w,p: Vector2i,placed: Dictionary) -> bool:
	var free={}
	for dy in range(-1,2):
		for dx in range(-1,2):
			var q=p+Vector2i(dx,dy)
			if q!=p and w.inside(q) and not placed.has(q) and (w.rocks.has(q) or w.walkable(q)):free[q]=true
	if free.size()<2:return false
	var queue=[free.keys()[0]];free.erase(queue[0]);var i=0
	while i<queue.size():
		var q=queue[i];i+=1
		for d in DIRECTIONS:
			if free.has(q+d):free.erase(q+d);queue.append(q+d)
	return not free.is_empty()

static func reachable(w) -> Dictionary:
	var seen={};var queue=[];var index=0
	if not w.walkable(w.keeper.pos):return seen
	seen[w.keeper.pos]=true;queue.append(w.keeper.pos)
	while index<queue.size():
		var p=queue[index];index+=1
		for d in DIRECTIONS:
			var q=p+d
			if w.walkable(q) and not seen.has(q):seen[q]=true;queue.append(q)
	return seen

static func repair_connections(w) -> Array:
	# New maps only: connect enclosed free pockets by removing the shortest
	# local barrier. Existing structures/idol are never repair candidates.
	var removed=[];var seen=reachable(w)
	for y in range(w.H):
		for x in range(w.W):
			var start=Vector2i(x,y)
			if not w.walkable(start) or seen.has(start):continue
			var queue=[start];var previous={start:start};var index=0;var exit_cell=start;var found=false
			while index<queue.size() and not found:
				var p=queue[index];index+=1
				for d in DIRECTIONS:
					var q=p+d
					if previous.has(q) or not w.inside(q) or (not w.walkable(q) and not w.rocks.has(q) and not w.trees.has(q)):continue
					previous[q]=p
					if seen.has(q):exit_cell=q;found=true;break
					queue.append(q)
			if not found:continue
			while exit_cell!=start:
				if w.rocks.has(exit_cell) or w.trees.has(exit_cell):
					w.rocks.erase(exit_cell);w.trees.erase(exit_cell);removed.append([exit_cell.x,exit_cell.y])
				exit_cell=previous[exit_cell]
			seen=reachable(w)
	return removed

static func persist(w):
	w.campaign.biome_map=w.terrain.duplicate(true)
	w.campaign.biome_natural=w.natural.keys().map(func(p):return {"pos":[p.x,p.y],"kind":w.natural[p]})

static func choose_site(w,sites: Array,resource: String) -> Vector2i:
	var total=0.0;var weights=[]
	for p in sites:total+=resource_weight(w,p,resource);weights.append(total)
	var roll=w.nature_rng.randf()*total
	for i in range(sites.size()):
		if roll<=weights[i]:return sites[i]
	return sites.back()

# Cached cumulative weights preserve weighted conditional placement. Live occupancy
# is checked only for sampled sites; a bounded exact fallback handles full maps.
static func prepare_nature(w):
	var key=[w.terrain.get("version",1),w.terrain.seed,w.W,w.H]
	if w.nature_site_cache.get("key")==key:return
	var sites=[];var cdf={};var totals={}
	for kind in w.nature_config.weights:cdf[kind]=PackedFloat64Array();totals[kind]=0.0
	for y in range(1,w.H-1):
		for x in range(1,w.W-1):
			var p=Vector2i(x,y);sites.append(p)
			for kind in cdf:
				totals[kind]+=resource_weight(w,p,kind);cdf[kind].append(totals[kind])
	w.nature_site_cache={"key":key,"sites":sites,"cdf":cdf,"totals":totals}

static func nature_site_valid(w,p):
	return w.floors.get(p,{}).get("status") not in ["ready","building"] and not w.natural.has(p) and not w.rocks.has(p) and p not in w.entries and not w.field_items.any(func(item):return item.pos==p) and not w.live_structure(p) and not w.occupied(p) and w.walkable(p)

static func sample_nature(w,kind):
	prepare_nature(w)
	var cached=w.nature_site_cache;var cdf=cached.cdf[kind]
	for attempt in range(32):
		var value=w.nature_rng.randf()*cached.totals[kind];var lo=0;var hi=cdf.size()-1
		while lo<hi:
			var mid=(lo+hi)/2
			if cdf[mid]<value:lo=mid+1
			else:hi=mid
		var p=cached.sites[lo]
		if nature_site_valid(w,p):return p
	# No missed spawn and no forced placement: exact weighted scan on exceptional
	# almost-full maps. It uses the same validity predicate as the fast route.
	var sites=[]
	for p in cached.sites:
		if nature_site_valid(w,p):sites.append(p)
	return null if sites.is_empty() else choose_site(w,sites,kind)
