extends RefCounted
## Full development-world snapshots for manual save and normal close/startup; separate from the original game saves.
const VERSION=1

static func pack(value):
	if value is RandomNumberGenerator:return {"_research_rng":true,"seed":value.seed,"state":value.state}
	if value is Dictionary:
		var result={}
		for key in value:result[key]=pack(value[key])
		return result
	if value is Array:return value.map(func(v):return pack(v))
	return value

static func unpack(value):
	if value is Dictionary:
		if value.get("_research_rng",false):
			var rng=RandomNumberGenerator.new();rng.seed=value.seed;rng.state=value.state;return rng
		var result={}
		for key in value:result[key]=unpack(value[key])
		return result
	if value is Array:return value.map(func(v):return unpack(v))
	return value

static func save(w,path: String) -> bool:
	var state={}
	for property in w.get_property_list():
		if property.name=="script" or not(property.usage&PROPERTY_USAGE_SCRIPT_VARIABLE):continue
		state[property.name]=pack(w.get(property.name))
	var file=FileAccess.open(path,FileAccess.WRITE)
	if file==null:return false
	file.store_var({"version":VERSION,"state":state},false);file.close();return true

static func restore(path: String):
	var file=FileAccess.open(path,FileAccess.READ)
	if file==null:return null
	var payload=file.get_var(false);file.close()
	if not payload is Dictionary or payload.get("version",-1)!=VERSION:return null
	var state=unpack(payload.state)
	var w=load("res://game/world.gd").new(state.campaign,int(state.seed_value))
	for key in state:w.set(key,state[key])
	# The worker registry must reference the actual keeper object after deserialization.
	w.workers.keeper=w.keeper
	# Market panels are scene state, not a world pause that may survive without its UI.
	w.market_open=false;w.cancel_merchant()
	for actor in w.workers.values():w.Work.migrate_priorities(actor)
	if not state.has("colony_version"):w.Cycle.migrate_snapshot(w)
	if not state.has("zones"):
		w.campaign.storage_cells=w.storage_cells.map(func(p):return [p.x,p.y]);w.campaign.erase("zones");w.Zones.init(w)
	w.Zones.sync_storage(w)
	w.Stock.migrate_storage(w);w.Stock.sync(w)
	if not state.has("rocks"):w.Tasks.init(w)
	if not state.has("tree_work"):w.Harvest.init(w)
	w.boundary_version=int(state.get("boundary_version",0))
	w.Land.migrate(w)
	w.Stock.reconcile_forbidden(w)
	return w
