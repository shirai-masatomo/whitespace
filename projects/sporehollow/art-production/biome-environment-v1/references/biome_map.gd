extends RefCounted
## Versioned scenery and placement only. Never used by movement or building rules.
const VERSION=1
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
	return smoothstep(0.72,1.5,d.length()+0.16*(noise(seed_number,p*0.18,17)-0.5))

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
	for blob in blobs:
		var d=(p-blob.center)/blob.radius
		fields[blob.kind]+=exp(-d.length_squared()*1.5)*blob.strength
	var broad=noise(seed_number,p*0.10,29)
	var fine=noise(seed_number,p*0.29,53)
	var margin=clearing(p,seed_number)
	var rock=clampf(fields[1]*(0.65+0.55*fine),0,1)*margin
	var dry=clampf(fields[2]*0.8+rock*0.6,0,1)*margin
	var wood=clampf(fields[0]*(0.7+0.45*broad),0,1)*margin*(1.0-rock*0.85)
	var lush=clampf(0.15+0.7*broad+wood*0.24-dry*0.65-rock*0.55,0,1)
	lush=lerpf(0.22,lush,0.3+0.7*margin)
	return [lush,wood,rock,dry,fine]

static func color_for(f: Array) -> Color:
	var color=Color("839955").lerp(Color("69874b"),f[0]*0.7)
	color=color.lerp(Color("617d48"),f[1]*0.65)
	color=color.lerp(Color("a99a68"),f[3]*0.78)
	color=color.lerp(Color("96917a"),f[2]*0.73)
	return color.lightened((f[4]-0.5)*0.045)

static func generate(seed_number: int,width: int,height: int) -> Dictionary:
	var blobs=lobes(seed_number);var fields=[];var vertices=[]
	for y in range(height):
		for x in range(width):fields.append(sample(seed_number,Vector2(x+0.5,y+0.5),blobs))
	for y in range(height+1):
		for x in range(width+1):
			var color=color_for(sample(seed_number,Vector2(x,y),blobs))
			vertices.append([color.r,color.g,color.b])
	return {"version":VERSION,"seed":seed_number,"width":width,"height":height,"fields":fields,"vertices":vertices}

static func prepare(w):
	# Missing terrain in a legacy save changes scenery only, never its objects.
	w.terrain=w.campaign.get("biome_map",{})
	if w.terrain.is_empty():w.terrain=generate(w.seed_value,w.W,w.H)
	w.campaign.biome_map=w.terrain.duplicate(true)
	if w.campaign.has("biome_natural"):
		w.natural.clear()
		for row in w.campaign.biome_natural:w.natural[Vector2i(row.pos[0],row.pos[1])]=row.kind

static func field(w,p: Vector2i) -> Array:
	return w.terrain.fields[p.y*w.W+p.x]

static func kind(w,p: Vector2i) -> String:
	var f=field(w,p)
	if f[2]>0.43:return "rocky"
	if f[1]>0.40:return "woodland"
	if f[3]>0.42:return "dry"
	if f[0]>0.48:return "lush"
	return "open"

static func resource_weight(w,p: Vector2i,resource: String) -> float:
	var f=field(w,p)
	match resource:
		"stump":return 0.005+pow(f[1],3)*4.0
		"mushroom":return 0.005+pow(f[0],3)*(0.25+f[1])*2.0
		_:return 0.01+pow(f[0],3)*3.0

static func available(w,p: Vector2i) -> bool:
	return w.walkable(p) and not w.occupied(p) and not w.live_structure(p) and not w.floors.has(p) and not w.natural.has(p) and not w.rocks.has(p) and w.items_at(p).is_empty() and not w.jobs.any(func(j):return j.pos==p) and p not in w.storage_cells and p not in w.entries and w.distance(p,w.logistics_entry)>3 and p not in w.Story.idol_cells(w)

static func populate(w):
	if not w.campaign.get("biome_new_map",false):return
	# Trees retain the existing physical blocker and existing wood work target.
	# One free cell between canopies in all directions prevents natural tree walls.
	var records=[]
	for y in range(1,w.H-1):
		for x in range(1,w.W-1):
			var p=Vector2i(x,y);var f=field(w,p)
			if f[1]<0.40 or unit(w.seed_value,x,y,71)>f[1]*0.38 or clearing(Vector2(p),w.seed_value)<0.8 or FOREST.merchant_clearing(p) or not available(w,p):continue
			if w.trees.keys().any(func(q):return maxi(absi(q.x-p.x),absi(q.y-p.y))<=1):continue
			var id="biome-tree-%d-%d"%[x,y]
			w.trees[p]=id;records.append({"id":id,"position":[x,y]})
	w.story.trees=records
	for y in range(w.H):
		for x in range(w.W):
			var p=Vector2i(x,y);var f=field(w,p)
			if f[2]>0.43 and unit(w.seed_value,x,y,97)<f[2]*0.16 and clearing(Vector2(p),w.seed_value)>0.8 and available(w,p):w.rocks[p]={"amount":w.Tasks.STONE_PER_ROCK,"forbidden":false}
	# Initial harvestables use existing kinds and caps, with weighted sampling.
	var r=RandomNumberGenerator.new();r.seed=w.seed_value*2371+419
	for resource in ["weed","mushroom","stump"]:
		for i in range(int(w.nature_config.caps.get(resource,0))):
			if w.natural.size()>=w.nature_config.limit:break
			var sites=[];var total=0.0
			for y in range(w.H):
				for x in range(w.W):
					var p=Vector2i(x,y)
					if not available(w,p) or clearing(Vector2(p),w.seed_value)<0.3:continue
					var weight=resource_weight(w,p,resource);total+=weight;sites.append([p,total])
			if sites.is_empty():break
			var roll=r.randf()*total
			for row in sites:
				if roll<=row[1]:w.natural[row[0]]=resource;w.metrics[resource+"_spawned"]+=1;break
	w.campaign.erase("biome_new_map")
	w.Tasks.save(w);w.Story.persist(w);persist(w)

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
