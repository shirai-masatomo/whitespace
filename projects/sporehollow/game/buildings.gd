extends RefCounted
## Shared topology, two construction layers and transactional onsite upgrades.
const Cost=preload("res://game/build_cost.gd")
const NAMES = {"mushroom_bed":"キノコ栽培床","bed":"ベッド","cooking_bench":"調理台","carpentry_bench":"木工作業台","sewing_bench":"裁縫台","wall":"土壁","wood_wall":"木壁","stone_wall":"石壁","soil_tile":"土タイル","wood_tile":"木タイル","stone_tile":"石タイル","door":"ドア","locked_door":"ロック付きドア","kennel":"犬小屋","coop":"鶏小屋"}
const WALLS = ["wall", "wood_wall", "stone_wall"]
const BENCHES = ["cooking_bench","carpentry_bench","sewing_bench"]
static func cells(kind: String,p: Vector2i) -> Array:
	return [p,p+Vector2i.RIGHT,p+Vector2i.DOWN,p+Vector2i.ONE] if kind in BENCHES else [p]
static func anchor(w,p: Vector2i) -> Vector2i:
	for offset in [Vector2i.ZERO,Vector2i.LEFT,Vector2i.UP,-Vector2i.ONE]:
		var q=p+offset;var b=w.structures.get(q,{})
		if b.get("status") in ["ready","building"] and p in cells(b.kind,q):return q
	return p
static func perimeter(kind: String,p: Vector2i) -> Array:
	var occupied=cells(kind,p);var result=[]
	for q in occupied:
		for n in [q+Vector2i.LEFT,q+Vector2i.RIGHT,q+Vector2i.UP,q+Vector2i.DOWN]:
			if n not in occupied and n not in result:result.append(n)
	return result
static func job_goals(w,j) -> Array:
	var kind=j.kind if w.BUILD.has(j.kind) else w.structures.get(j.pos,{}).get("kind","")
	return perimeter(kind,j.pos)

const DOORS = ["door", "locked_door", "gate"]

static func layer(w, kind: String) -> Dictionary:
	return w.floors if w.BUILD[kind].get("layer", "structure") == "floor" else w.structures

static func enclosure(b: Dictionary) -> bool:
	return b.get("status") == "ready" and b.get("kind") in WALLS + DOORS

static func rooms(w, proposed: Dictionary = {}) -> Dictionary:
	preload("res://game/terrain_metrics.gd").count("buildings.rooms")
	var barriers = {}
	for p in w.structures:
		if enclosure(w.structures[p]): barriers[p] = true
	var tiles = {}
	for p in w.floors:
		if w.floors[p].status == "ready": tiles[p] = true
	for p in w.Story.idol_cells(w): tiles[p]=true # installed footprint covers the ground
	if not proposed.is_empty():
		if w.BUILD[proposed.kind].get("layer") == "floor": tiles[proposed.pos] = true
		elif proposed.kind in WALLS + DOORS: barriers[proposed.pos] = true
	var visited = {}
	var indoor = {}
	for y in range(1, w.H - 1):
		for x in range(1, w.W - 1):
			var start = Vector2i(x,y)
			if visited.has(start) or barriers.has(start): continue
			var open = [start]
			var region = []
			var valid = true
			visited[start] = true
			while not open.is_empty():
				preload("res://game/terrain_metrics.gd").count("rooms_cells")
				var cell = open.pop_back()
				region.append(cell)
				if not tiles.has(cell): valid = false
				for n in w.neighbors(cell):
					if not w.inside(n): valid = false; continue
					if barriers.has(n) or visited.has(n): continue
					visited[n] = true
					open.append(n)
			if valid:
				for cell in region: indoor[cell] = true
	return indoor

static func reason(w, kind: String, p: Vector2i, check_cost: bool = true,job_id: int=-1) -> String:
	for cell in cells(kind,p):
		var why=cell_reason(w,kind,cell,check_cost,job_id)
		if why!="":return why
	return ""

static func cell_reason(w, kind: String, p: Vector2i, check_cost: bool = true,job_id: int=-1) -> String:
	preload("res://game/terrain_metrics.gd").count("buildings.reason")
	if kind in ["kennel","coop"]: return "この建物は休止中です"
	if not w.BUILD.has(kind) or not w.inside(p): return "ここには建てられません"
	if w.trees.has(p): return "先に開拓が必要"
	if w.rocks.has(p) or not w.Mountains.at(w,p).is_empty():return "先に岩を採掘してください"
	if p in w.Story.idol_cells(w): return "黄金像の場所です"
	if p==w.logistics_entry: return "受入口と通路を空けてください"
	if w.occupied(p): return "ここに誰かいます"
	if w.natural.has(p) or w.field_items.any(func(i):return i.pos==p and i.get("location","ground")=="ground" and not (job_id>=0 and i.get("construction_transfer",false) and i.get("job_id",-1)==job_id)): return "物があるため建設できません"
	var data = w.BUILD[kind]
	if data.get("blueprint", "") not in [""] + w.campaign.unlocked_blueprints: return "作り方をまだ知りません"
	var old = layer(w,kind).get(anchor(w,p) if w.BUILD[kind].get("layer")!="floor" else p,{})
	if w.BUILD[kind].get("layer")=="floor" and w.structures.get(anchor(w,p),{}).get("kind") in BENCHES:return "設備の場所です"
	if old.get("status") == "ready":
		var compatible = (kind in WALLS and old.kind in WALLS) or data.get("layer") == "floor"
		if not compatible or data.get("tier",-1) <= w.BUILD.get(old.kind,{}).get("tier",0): return "上位の素材を選んでください"
	elif old.get("status") == "building": return "工事中です"
	if check_cost:
		for material in Cost.materials(w,kind):
			if w.resource_amount(material)<Cost.materials(w,kind)[material]:return "素材が足りません"
	if encloses_outdoor_animal(w,kind,p):return "先に犬を外へ誘導"
	return ""

static func encloses_outdoor_animal(w,kind: String,p: Vector2i) -> bool:
	# Only the connected region containing a restricted animal can reject construction.
	# A single uncovered cell proves that region is outdoors: no whole-map flood is needed.
	var added_floor=w.BUILD[kind].get("layer")=="floor"
	var added_barrier=kind in WALLS or kind in DOORS
	var idol=w.Story.idol_cells(w)
	for a in w.animals:
		if not a.placed or w.SPECIES[a.species].can_enter_indoor or not w.inside(a.pos) or enclosure(w.structures.get(a.pos,{})):continue
		var seen={a.pos:true};var pending=[a.pos];var enclosed=true;var has_interior=false
		while not pending.is_empty():
			var cell=pending.pop_back()
			has_interior=has_interior or (cell.x>0 and cell.y>0 and cell.x<w.W-1 and cell.y<w.H-1)
			preload("res://game/terrain_metrics.gd").count("enclosure_cells")
			if not w.inside(cell) or not ((added_floor and cell==p) or cell in idol or w.floors.get(cell,{}).get("status")=="ready"):
				enclosed=false;break
			for n in w.neighbors(cell):
				if seen.has(n) or (added_barrier and n==p) or enclosure(w.structures.get(n,{})):continue
				seen[n]=true;pending.append(n)
		if enclosed and has_interior:return true
	return false

static func begin(w,j):
	var store = layer(w,j.kind)
	var d = w.BUILD[j.kind]
	j.old = store.get(j.pos,{}).duplicate(true)
	j.remaining = ceili(d.seconds / w.DT)
	j.started = true
	j.state = "working"
	if j.old.get("status") != "ready":
		store[j.pos] = {"id":w.next_structure_id,"kind":j.kind,"status":"building","hp":0,"max_hp":d.hp,"cost":d.cost,"materials":Cost.materials(w,j.kind,j),"resource":j.resource,"open":false,"armor":0,"remaining":j.remaining,"total_ticks":j.remaining}
		w.next_structure_id += 1
	j.site_id=store.get(j.pos,{}).get("id",-1)
	w.invalidate_navigation()

static func advance(w,j,work_factor: float=1.0):
	# Own new site is ignored for validation; upgrades retain the old functioning object.
	var store = layer(w,j.kind)
	var site = store.get(j.pos,{})
	if site.get("status") == "building": store.erase(j.pos)
	var why = reason(w,j.kind,j.pos,false)
	if not site.is_empty(): store[j.pos] = site
	if why != "":
		j.state = "blocked"; j.block_reason = why
		return
	var worker=w.workers.get(j.get("assigned_to","keeper"),w.keeper)
	if not preload("res://game/construction_safety.gd").can_finish(w,j,worker):
		w.Work.block(w,j,"退避経路を確保できません");return
	j.state = "working"
	j.remaining -= work_factor
	if site.get("status") == "building": site.remaining = j.remaining
	if j.remaining > 0: return
	var d = w.BUILD[j.kind]
	var ratio = float(site.hp)/site.max_hp if site.get("status") == "ready" else 1.0
	store[j.pos] = {"id":site.get("id",w.next_structure_id),"kind":j.kind,"status":"ready","hp":maxi(1,floori(d.hp*ratio)),"max_hp":d.hp,"cost":d.cost,"materials":Cost.materials(w,j.kind,j),"resource":j.resource,"open":false,"armor":0,"lock_hp":d.get("lock_hp",0),"max_lock_hp":d.get("lock_hp",0)}
	j.reserved = 0
	w.metrics.built += 1
	w.refresh_indoor()
	w.Jobs.complete(w,j,true)

static func cancel(w,j):
	if not j.started: return
	var store = layer(w,j.kind)
	if store.get(j.pos,{}).get("status") == "building": store.erase(j.pos)
	j.reserved = floori(j.reserved * w.Rules.INTERRUPT_REFUND)
	w.refresh_indoor()
