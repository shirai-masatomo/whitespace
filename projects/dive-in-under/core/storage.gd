extends RefCounted
## Town-only instance transfers; no implicit stacking or destruction of legacy excess.
const BACKPACK_CAPACITY := 15
const CLOTH_CAPACITY := 3
const SOURCES := ["inventory","cloth","warehouse"]
static func category(item: Dictionary) -> String:
	if item.has("category"): return item.category
	var slot: String=item.get("slot","")
	if slot in ["right_hand","left_hand"]: return "weapon"
	return "material" if slot=="" else "armor"
static func reason(s: Dictionary, uid: String, source: String, destination: String, cfg: Dictionary) -> String:
	if s.phase!="town": return "町で整理できます"
	if not source in SOURCES or not destination in SOURCES or source==destination: return "移動先を選んでください"
	if not s.has(source) or not uid in s[source] or not s.items.has(uid): return "アイテムを選んでください"
	if s.has("quantities") and s.items[uid]=="C01":
		return "" if preload("res://core/currency.gd").room(s,destination)>=int(s.quantities[uid]) else "コインが入りきりません。分割して移せます。"
	if destination=="inventory" and s.inventory.size()>=BACKPACK_CAPACITY: return "バックパックに空きがありません"
	if destination=="cloth" and s.cloth.size()>=CLOTH_CAPACITY: return "風呂敷に空きがありません"
	return ""
static func move(s: Dictionary, uid: String, source: String, destination: String, cfg: Dictionary) -> bool:
	if reason(s,uid,source,destination,cfg)!="": return false
	if s.has("quantities") and s.items[uid]=="C01": return preload("res://core/currency.gd").move(s,uid,source,destination)
	s[source].erase(uid); s[destination].append(uid)
	return true
static func sort_key(s: Dictionary, uid: String, cfg: Dictionary, mode: String) -> String:
	var item: Dictionary=cfg.items[s.items[uid]]
	var condition: int=int(s.item_condition[uid].current) if s.get("item_condition",{}).has(uid) else 100
	var prefix: String="%03d"%(100-condition) if mode=="condition" else (item.name if mode=="name" else category(item))
	return "%s/%s/%s/%010d"%[prefix,s.items[uid],item.name,int(uid.trim_prefix("item-"))]
static func organize(s: Dictionary, cfg: Dictionary, mode: String) -> bool:
	if s.phase!="town" or not mode in ["category","name","condition"]: return false
	var changed:=false
	for source in SOURCES:
		var before: Array=s[source].duplicate()
		s[source].sort_custom(func(a,b): return sort_key(s,a,cfg,mode)<sort_key(s,b,cfg,mode))
		changed=changed or before!=s[source]
	return changed

static func ensure_positions(s: Dictionary) -> void:
	if not s.has("warehouse_positions"):s.warehouse_positions={}
	for uid in s.warehouse_positions.keys():
		if uid not in s.warehouse:s.warehouse_positions.erase(uid)
	var used: Array=[]
	for uid in s.warehouse:
		var index: int=int(s.warehouse_positions.get(uid,-1))
		if index>=0 and index not in used:used.append(index)
		else:s.warehouse_positions.erase(uid)
	for uid in s.warehouse:
		if s.warehouse_positions.has(uid):continue
		var index: int=0
		while index in used:index+=1
		s.warehouse_positions[uid]=index;used.append(index)
static func position(s: Dictionary, uid: String) -> int:
	return int(s.get("warehouse_positions",{}).get(uid,s.warehouse.find(uid)))
static func uid_at(s: Dictionary, cell: int) -> String:
	for uid in s.warehouse:
		if position(s,uid)==cell:return uid
	return ""
static func reorder(s: Dictionary, uid: String, cell: int) -> String:
	if s.phase!="town" or uid not in s.warehouse or cell<0:return "倉庫の移動先を選んでください。"
	ensure_positions(s);var old: int=position(s,uid);var other: String=uid_at(s,cell)
	if old==cell:return "同じマスです。"
	s.warehouse_positions[uid]=cell
	if other!="":s.warehouse_positions[other]=old
	return ""
static func classification(item: Dictionary) -> String:
	var slot: String=item.get("slot","")
	if slot=="right_hand":return "weapon"
	if slot in ["head","body","legs","feet","left_hand"]:return "armor"
	if slot in ["neck","ears","eyes","finger","wrist"]:return "accessory"
	return "other"
static func matches(item: Dictionary, category_filter: String="all", slot_filter: String="") -> bool:
	return (category_filter=="all" or classification(item)==category_filter) and (slot_filter=="" or item.slot==slot_filter)

static func transfer(s: Dictionary, args: Dictionary, cfg: Dictionary) -> String:
	var uid: String=args.get("uid","");var source: String=args.get("source","inventory");var destination: String=args.get("destination","warehouse");var cell: int=int(args.get("cell",-1))
	if source==destination:
		return reorder(s,uid,cell) if source=="warehouse" else "別の収納へ移してください。"
	var error: String=reason(s,uid,source,destination,cfg)
	if error!="":return error
	if destination=="warehouse" and cell>=0 and uid_at(s,cell)!="":return "その倉庫マスは使用中です。"
	ensure_positions(s)
	var before: Array=s[destination].duplicate()
	if not move(s,uid,source,destination,cfg):return "移動できません。収納の空きを確認してください。"
	ensure_positions(s)
	if destination=="warehouse" and cell>=0:
		var added: Array=s.warehouse.filter(func(id):return id not in before)
		# A coin may merge into an existing stack; no fake second item is created.
		if added.size()==1:s.warehouse_positions[added[0]]=cell
	return ""
