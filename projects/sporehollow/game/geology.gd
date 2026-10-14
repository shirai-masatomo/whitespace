extends RefCounted
## New-map geology. Visual material IDs do not define new resources or prices.
const Heap=preload("res://game/path_heap.gd")
const AREA_FRACTION=0.29
const CORE_DEPTH=2
const DIRS=[Vector2i.UP,Vector2i.RIGHT,Vector2i.DOWN,Vector2i.LEFT]
static func route(_seed_number:int,p:Vector2i,width:int,height:int)->bool:
	# A clear perimeter lets routes go around either side of the massif. Do not
	# cut an artificial cross through a naturally continuous rock formation.
	return p.x<3 or p.y<3 or p.x>=width-3 or p.y>=height-3
static func shape(seed_number:int,width:int,height:int,fields:Array,noise:Callable,clearing:Callable,coastline:bool=true)->Dictionary:
	var ranked=[];var selected={};var depth={};var queue=[]
	for y in range(height):
		for x in range(width):
			var p=Vector2i(x,y);var normalized=Vector2(p)*Vector2(50.0/width,34.0/height)
			var left=2;var right=2;var top=2;var bottom=2
			if coastline:
				# Broad 5–9-cell undulations replace the ruler-straight world-edge clip.
				left+=roundi(noise.call(seed_number,Vector2(0,y*0.17),701)*4)
				right+=roundi(noise.call(seed_number,Vector2(0,y*0.17),709)*4)
				top+=roundi(noise.call(seed_number,Vector2(x*0.17,0),719)*4)
				bottom+=roundi(noise.call(seed_number,Vector2(x*0.17,0),727)*4)
			if x<left or y<top or x>=width-right or y>=height-bottom or clearing.call(normalized,seed_number)<0.82:continue
			var score=fields[y*width+x][2]+0.13*noise.call(seed_number,normalized*0.16,613)
			ranked.append({"p":p,"score":score})
	ranked.sort_custom(func(a,b):return a.score>b.score if a.score!=b.score else (a.p.y<b.p.y if a.p.y!=b.p.y else a.p.x<b.p.x))
	# Expand one region through the strongest neighbouring geology instead of
	# selecting detached high-value pixels scattered around the entire map.
	var scores={};var frontier=[];var seen={};var ordinal=0
	for row in ranked:scores[row.p]=row.score
	if not ranked.is_empty():Heap.push(frontier,[ranked[0].p,-ranked[0].score,ordinal]);seen[ranked[0].p]=true
	var target=mini(roundi(width*height*AREA_FRACTION),ranked.size())
	while not frontier.is_empty() and selected.size()<target:
		var p=Heap.pop(frontier)[0];selected[p]=true
		for d in DIRS:
			var q=p+d
			if scores.has(q) and not seen.has(q):
				ordinal+=1;seen[q]=true;Heap.push(frontier,[q,-scores[q],ordinal])
	for p in selected:
		if DIRS.any(func(d):return not selected.has(p+d)):depth[p]=0;queue.append(p)
	var at=0
	while at<queue.size():
		var p=queue[at];at+=1
		for d in DIRS:
			var q=p+d
			if selected.has(q) and not depth.has(q):depth[q]=depth[p]+1;queue.append(q)
	var layers=[];var cores=[];var ore=[]
	for y in range(height):
		for x in range(width):
			var p=Vector2i(x,y);var f=fields[y*width+x];var n=noise.call(seed_number,Vector2(p)*0.12,641)
			var layer="soil";var core=false;var mineral="stone"
			if selected.has(p):
				var deep=depth[p]
				f[2]=0.44+0.53*smoothstep(0.0,9.0,deep);f[1]*=0.2;f[0]*=0.3
				layer="sand" if deep<=1 and n>0.55 else "clay" if deep<=3 and n>0.35 else "gravel" if deep<3 else "bedrock"
				# Branching noise isolines form veins, rather than whole iron-filled cores.
				var vein=absf(noise.call(seed_number,Vector2(p)*Vector2(0.13,0.21),653)-0.5)
				if deep>=4 and vein<0.065:mineral="iron"
				if deep>=4 and absf(n-0.47)<0.035:layer="clay"
				var rim=CORE_DEPTH
				if coastline:rim+=roundi((noise.call(seed_number,Vector2(p)*0.19,733)-0.5)*2.8)
				core=deep>=rim and not route(seed_number,p,width,height)
			else:
				f[2]=minf(f[2],0.42)
				if f[5]>0.2:layer="sand"
				elif f[6]>0.22:layer="clay"
			f[5]=0.75 if layer=="sand" else f[5]*0.3
			f[6]=0.7 if layer=="clay" else f[6]*0.2
			layers.append(layer);cores.append(core);ore.append(mineral)
	if coastline:smooth_rim(cores,selected,seed_number,width,height)
	join_cores(cores,selected,seed_number,width,height,scores if coastline else {})
	if coastline:
		trim_spurs(cores,width,height)
		# Broad connecting necks can extend slightly beyond the old apron.
		# Extend only the local surface transition, not the entire biome.
		for y in range(height):
			for x in range(width):
				if not cores[y*width+x]:continue
				for dy in range(-2,3):
					for dx in range(-2,3):
						var q=Vector2i(x+dx,y+dy)
						if not scores.has(q) or selected.has(q):continue
						var i=q.y*width+q.x;selected[q]=true
						fields[i][2]=0.7 if cores[i] else 0.44
						layers[i]="bedrock" if cores[i] else "clay" if noise.call(seed_number,Vector2(q)*0.12,641)>0.5 else "gravel"
						fields[i][6]=0.65 if layers[i]=="clay" else fields[i][6]

	return {"schema":1,"area_fraction":AREA_FRACTION,"region_cells":selected.size(),"layers":layers,"cores":cores,"ore":ore}
static func core(w,p:Vector2i)->bool:
	return w.inside(p) and w.terrain.has("geology") and w.terrain.geology.cores[p.y*w.W+p.x]
static func mineral(w,p:Vector2i)->String:
	return w.terrain.geology.ore[p.y*w.W+p.x] if w.terrain.has("geology") and w.inside(p) else "stone"
static func populate(w):
	for y in range(w.H):
		for x in range(w.W):
			var p=Vector2i(x,y)
			if core(w,p) and not w.Biome.protected(w,p) and w.Biome.available(w,p):
				w.rocks[p]={"amount":w.Tasks.STONE_PER_ROCK,"forbidden":false,"geology":mineral(w,p)}

static func join_cores(cores:Array,region:Dictionary,seed_number:int,width:int,height:int,allowed:Dictionary={}):
	var left={};var groups=[]
	for p in region:
		if cores[p.y*width+p.x]:left[p]=true
	while not left.is_empty():
		var queue=[left.keys()[0]];left.erase(queue[0]);var i=0
		while i<queue.size():
			var p=queue[i];i+=1
			for d in DIRS:
				if left.has(p+d):left.erase(p+d);queue.append(p+d)
		groups.append(queue)
	groups.sort_custom(func(a,b):return a.size()>b.size())
	if groups.is_empty():return
	var main={}
	for p in groups[0]:main[p]=true
	for group in groups.slice(1):
		if group.size()<(75 if not allowed.is_empty() else 30):continue
		var targets={}
		for p in group:targets[p]=true
		var queue=main.keys();var previous={};var i=0;var found=null
		for p in queue:previous[p]=p
		while i<queue.size() and found==null:
			var p=queue[i];i+=1
			for d in DIRS:
				var q=p+d
				if not region.has(q) or previous.has(q) or route(seed_number,q,width,height):continue
				previous[q]=p
				if targets.has(q):found=q;break
				queue.append(q)
		if found==null:continue
		var p:Vector2i=found
		while not main.has(p):
			# A three-cell bridge joins neighbouring lobes without filling bays.
			for dy in range(-1,2):
				for dx in range(-1,2):
					var q=p+Vector2i(dx,dy)
					if (region.has(q) or allowed.has(q)) and not route(seed_number,q,width,height):cores[q.y*width+q.x]=true
			p=previous[p]
		for q in group:main[q]=true

static func smooth_rim(cores:Array,region:Dictionary,seed_number:int,width:int,height:int):
	# Two local passes; retain broad lobes and close single-cell slots without
	# filling large bays. Only generation runs this, never mining or rendering.
	for iteration in range(2):
		var next=cores.duplicate()
		for p in region:
			if route(seed_number,p,width,height):continue
			var ring=[];var count=0
			for dy in range(-1,2):
				for dx in range(-1,2):
					if dx==0 and dy==0:continue
					var q=p+Vector2i(dx,dy)
					if q.x>=0 and q.y>=0 and q.x<width and q.y<height and cores[q.y*width+q.x]:count+=1
			for d in DIRS:
				var q=p+d;ring.append(q.x>=0 and q.y>=0 and q.x<width and q.y<height and cores[q.y*width+q.x])
			var index=p.y*width+p.x
			if cores[index] and count<=2:next[index]=false
			elif not cores[index] and (count>=5 or (ring[0] and ring[2]) or (ring[1] and ring[3])):next[index]=true
		cores.assign(next)

static func trim_spurs(cores:Array,width:int,height:int):
	# A one-cell string between distant lobes is not a natural coastline.
	# Keep cells supported by a full 2x2 rock patch; small detached lobes may remain.
	var remove=[]
	for y in range(1,height-1):
		for x in range(1,width-1):
			if not cores[y*width+x]:continue
			var supported=false
			for dy in [-1,1]:
				for dx in [-1,1]:
					if cores[y*width+x+dx] and cores[(y+dy)*width+x] and cores[(y+dy)*width+x+dx]:supported=true
			if not supported:remove.append(y*width+x)
	for i in remove:cores[i]=false
