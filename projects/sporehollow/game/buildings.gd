extends RefCounted
## Shared topology, two construction layers and transactional onsite upgrades.
const NAMES = {"wall":"土壁","wood_wall":"木壁","stone_wall":"石壁","soil_tile":"土タイル","wood_tile":"木タイル","stone_tile":"石タイル","door":"ドア","locked_door":"ロック付きドア","kennel":"犬小屋","coop":"鶏小屋"}
const WALLS = ["wall", "wood_wall", "stone_wall"]
const DOORS = ["door", "locked_door", "gate"]

static func layer(w, kind: String) -> Dictionary:
	return w.floors if w.BUILD[kind].get("layer", "structure") == "floor" else w.structures

static func enclosure(b: Dictionary) -> bool:
	return b.get("status") == "ready" and b.get("kind") in WALLS + DOORS

static func rooms(w, proposed: Dictionary = {}) -> Dictionary:
	var barriers = {}
	for p in w.structures:
		if enclosure(w.structures[p]): barriers[p] = true
	var tiles = {}
	for p in w.floors:
		if w.floors[p].status == "ready": tiles[p] = true
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

static func reason(w, kind: String, p: Vector2i, check_cost: bool = true) -> String:
	if kind in ["kennel","coop"]: return "この建物は休止中です"
	if not w.BUILD.has(kind) or not w.inside(p): return "ここには建てられません"
	if p in w.entries: return "受入口と通路を空けてください"
	if w.occupied(p): return "ここに誰かいます"
	if w.natural.has(p) or not w.items_at(p).is_empty() or w.field_items.any(func(i):return i.pos==p): return "物があるため建設できません"
	var data = w.BUILD[kind]
	if data.get("blueprint", "") not in [""] + w.campaign.unlocked_blueprints: return "作り方をまだ知りません"
	var old = layer(w,kind).get(p,{})
	if old.get("status") == "ready":
		var compatible = (kind in WALLS and old.kind in WALLS) or data.get("layer") == "floor"
		if not compatible or data.get("tier",-1) <= w.BUILD.get(old.kind,{}).get("tier",0): return "上位の素材を選んでください"
	elif old.get("status") == "building": return "工事中です"
	if check_cost and not (w.debug_enabled and w.debug_infinite) and w.resource_amount(data.get("resource","soil")) < data.cost: return "素材が足りません"
	var predicted = rooms(w,{"kind":kind,"pos":p})
	for a in w.animals:
		if a.placed and not w.SPECIES[a.species].can_enter_indoor and predicted.has(a.pos): return "先に犬を外へ誘導"
	return ""

static func begin(w,j):
	var store = layer(w,j.kind)
	var d = w.BUILD[j.kind]
	j.old = store.get(j.pos,{}).duplicate(true)
	j.remaining = ceili(d.seconds / w.DT)
	j.started = true
	j.state = "working"
	if j.old.get("status") != "ready":
		store[j.pos] = {"id":w.next_structure_id,"kind":j.kind,"status":"building","hp":0,"max_hp":d.hp,"cost":j.reserved,"resource":j.resource,"open":false,"armor":0,"remaining":j.remaining,"total_ticks":j.remaining}
		w.next_structure_id += 1

static func advance(w,j):
	# Own new site is ignored for validation; upgrades retain the old functioning object.
	var store = layer(w,j.kind)
	var site = store.get(j.pos,{})
	if site.get("status") == "building": store.erase(j.pos)
	var why = reason(w,j.kind,j.pos,false)
	if not site.is_empty(): store[j.pos] = site
	if why != "":
		j.state = "blocked"; j.block_reason = why
		return
	j.state = "working"
	j.remaining -= w.Life.factor(w)
	if site.get("status") == "building": site.remaining = j.remaining
	if j.remaining > 0: return
	var d = w.BUILD[j.kind]
	var ratio = float(site.hp)/site.max_hp if site.get("status") == "ready" else 1.0
	store[j.pos] = {"id":site.get("id",w.next_structure_id),"kind":j.kind,"status":"ready","hp":maxi(1,floori(d.hp*ratio)),"max_hp":d.hp,"cost":j.reserved,"resource":j.resource,"open":false,"armor":0,"lock_hp":d.get("lock_hp",0),"max_lock_hp":d.get("lock_hp",0)}
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
