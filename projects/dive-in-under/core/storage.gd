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
	if destination=="warehouse" and cfg.items[s.items[uid]].get("supply",false): return "支給品は倉庫へ預けられません"
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
