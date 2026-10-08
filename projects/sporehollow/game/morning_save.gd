extends RefCounted
## Morning-only persistence. Objects are never deserialized. Two generations survive interrupted rotation.
const Farm=preload("res://game/world.gd")
const PATH="user://campaign/morning.sav"
const MAGIC="WRM1"
const VERSION=1
const LIMIT=8*1024*1024

static func capture(w) -> Dictionary:
	if w.phase!="shop" or w.campaign.night_ready:return {}
	w.persist_farm()
	return {"version":VERSION,"game":"whistle-ranch","boundary":"morning","seed":w.seed_value,"campaign":w.campaign.duplicate(true),"stock":w.shop_stock.duplicate(true),"checkpoint":w.morning_checkpoint.duplicate(true)}

static func restore(record: Dictionary):
	if not valid(record):return null
	var w=Farm.new(record.campaign,record.seed)
	w.shop_stock=record.stock.duplicate(true)
	w.morning_checkpoint=record.checkpoint.duplicate(true)
	return w

static func plain(value,depth: int=0) -> bool:
	if depth>48:return false
	if value is Dictionary:
		for key in value:
			if not plain(key,depth+1) or not plain(value[key],depth+1):return false
		return true
	if value is Array:
		for item in value:
			if not plain(item,depth+1):return false
		return true
	return typeof(value) in [TYPE_NIL,TYPE_BOOL,TYPE_INT,TYPE_FLOAT,TYPE_STRING,TYPE_STRING_NAME,TYPE_VECTOR2I,TYPE_VECTOR2]

static func coordinate(value) -> bool:
	return value is Vector2i or (value is Array and value.size()==2 and value[0] is int and value[1] is int)

static func campaign_valid(c) -> bool:
	if not c is Dictionary:return false
	for key in ["stage","day","gold","exp_pool"]:
		if not c.get(key) is int or c[key]<0:return false
	if c.day<1 or c.stage<1 or c.get("night_ready",true)!=false:return false
	for key in ["resources","items"]:
		if not c.get(key) is Dictionary:return false
		for value in c[key].values():
			if not value is int or value<0:return false
	if not c.get("animals") is Array:return false
	var ids=[]
	for a in c.animals:
		if not a is Dictionary or not a.get("id") is int or a.id<1 or a.id in ids or not Farm.SPECIES.has(a.get("species")):return false
		if not a.get("lv") is int or a.lv<1 or a.lv>5 or not a.get("loyalty") is int:return false
		if a.has("position") and not coordinate(a.position):return false
		for key in ["equipment"]:
			if a.has(key) and not a[key] is Dictionary:return false
		ids.append(a.id)
	for key in ["facilities","floors","field_items","work_jobs"]:
		if not c.get(key,[]) is Array:return false
		for row in c.get(key,[]):
			if not row is Dictionary or not coordinate(row.get("pos")):return false
			if key in ["facilities","floors"] and (not row.get("id") is int or not Farm.BUILD.has(row.get("kind")) or row.get("status") not in ["ready","building","destroyed","disabled"]):return false
			if key=="field_items" and not row.get("kind") is String:return false
	for key in ["keeper_position"]:
		if c.has(key) and not coordinate(c[key]):return false
	for key in ["world_story","route_progress","keeper_vitals","enemy_knowledge","encounter_counts"]:
		if c.has(key) and not c[key] is Dictionary:return false
	var story=c.get("world_story",{})
	if not story.is_empty():
		for key in ["prayers","events","news","miracles","cleared","trees"]:
			if not story.get(key,[]) is Array:return false
		if not story.get("hidden") is Dictionary or not story.get("idol") is Dictionary:return false
		if not story.idol.is_empty() and not coordinate(story.idol.get("position")):return false
		for key in ["prayers","events","news","miracles","trees"]:
			for row in story.get(key,[]):
				if not row is Dictionary:return false
	var progress=c.get("route_progress",{})
	if not progress.get("milestones",{}) is Dictionary:return false
	return true

static func valid(record) -> bool:
	if not record is Dictionary or not plain(record):return false
	if record.get("version")!=VERSION or record.get("game")!="whistle-ranch" or record.get("boundary")!="morning" or not record.get("seed") is int:return false
	if not campaign_valid(record.get("campaign")) or not campaign_valid(record.get("checkpoint")):return false
	if record.campaign.day!=record.checkpoint.day or not record.get("stock") is Array:return false
	var products=Farm.Shop.table();var seen=[]
	for row in record.stock:
		if not row is Dictionary or not products.has(row.get("product")) or row.product in seen or not row.get("remaining") is int or row.remaining<0 or not row.get("individual",{}) is Dictionary:return false
		seen.append(row.product)
	return true

static func digest(bytes: PackedByteArray) -> PackedByteArray:
	var context=HashingContext.new();context.start(HashingContext.HASH_SHA256);context.update(bytes)
	return context.finish()

static func read_one(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):return {"status":"missing"}
	var file=FileAccess.open(path,FileAccess.READ)
	if file==null:return {"status":"io_error"}
	var size=file.get_length()
	if size<44 or size>LIMIT:return {"status":"corrupt"}
	if file.get_buffer(4).get_string_from_ascii()!=MAGIC:return {"status":"corrupt"}
	if file.get_32()!=VERSION:return {"status":"unsupported_version"}
	var length=file.get_32();var expected=file.get_buffer(32)
	if length!=size-44:return {"status":"corrupt"}
	var bytes=file.get_buffer(length);file.close()
	if digest(bytes)!=expected:return {"status":"corrupt"}
	var record=bytes_to_var(bytes)
	if not valid(record):return {"status":"corrupt"}
	return {"status":"ok","record":record}

static func read(path: String=PATH) -> Dictionary:
	var main=read_one(path)
	if main.status in ["ok","unsupported_version","io_error"]:return main
	for suffix in [".bak",".tmp"]:
		var backup=read_one(path+suffix)
		if backup.status=="unsupported_version":return backup
		if backup.status=="ok":return {"status":"recovered","from":suffix,"record":backup.record}
		if backup.status!="missing":main={"status":"corrupt"}
	return main

static func write(record: Dictionary,path: String=PATH,interrupt_after: String="") -> Dictionary:
	# interrupt_after is a deterministic crash fixture; normal calls always leave it empty.
	if not valid(record):return {"status":"invalid"}
	for suffix in ["",".bak"]:
		var existing=read_one(path+suffix)
		if existing.status in ["unsupported_version","io_error"]:return {"status":existing.status}
	var absolute=ProjectSettings.globalize_path(path)
	if DirAccess.make_dir_recursive_absolute(absolute.get_base_dir())!=OK:return {"status":"io_error"}
	var bytes=var_to_bytes(record)
	if bytes.size()>LIMIT-44:return {"status":"invalid"}
	var file=FileAccess.open(path+".tmp",FileAccess.WRITE)
	if file==null:return {"status":"io_error"}
	file.store_buffer(MAGIC.to_ascii_buffer());file.store_32(VERSION);file.store_32(bytes.size());file.store_buffer(digest(bytes));file.store_buffer(bytes);file.flush()
	var error=file.get_error();file.close()
	if error!=OK or read_one(path+".tmp").get("record",{})!=record:return {"status":"io_error"}
	if interrupt_after=="temporary":return {"status":"interrupted"}
	if FileAccess.file_exists(path):
		if read_one(path).status=="ok":
			if FileAccess.file_exists(path+".bak") and DirAccess.remove_absolute(absolute+".bak")!=OK:return {"status":"io_error"}
			# Destinations must be absent: on Windows rename can remove an existing destination on failure.
			if DirAccess.dir_exists_absolute(absolute+".bak") or DirAccess.rename_absolute(absolute,absolute+".bak")!=OK:return {"status":"io_error"}
		else:
			var quarantine=absolute+".unreadable-"+str(Time.get_unix_time_from_system())+"-"+str(Time.get_ticks_usec())
			if DirAccess.rename_absolute(absolute,quarantine)!=OK:return {"status":"io_error"}
	if interrupt_after=="rotation":return {"status":"interrupted"}
	if DirAccess.dir_exists_absolute(absolute) or FileAccess.file_exists(path):return {"status":"io_error"}
	if DirAccess.rename_absolute(absolute+".tmp",absolute)!=OK:return {"status":"io_error"}
	return {"status":"ok"}
