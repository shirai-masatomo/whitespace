extends RefCounted
## Read-only presentation of the same per-instance stats used by Expedition.hero.
const E=preload("res://core/expedition.gd")
const NAMES={"atk":"攻撃","def":"防御","spd":"素早さ","max_hp":"最大HP","max_sp":"最大SP"}
static func text(values: Dictionary) -> String:
	var parts: Array[String]=[]
	for key in NAMES:
		if values.has(key): parts.append("%s %+d"%[NAMES[key],int(values[key])])
	return " / ".join(parts)
static func current(s: Dictionary, cfg: Dictionary, uid: String) -> String:
	return text(E.Condition.stats(s,uid,cfg))
static func performance(s: Dictionary, cfg: Dictionary, uid: String) -> String:
	var values: Dictionary=E.Condition.stats(s,uid,cfg); var base: Dictionary=E.Condition.stats(s,uid,cfg,true)
	var value: String="現在値  "+text(values)
	if values!=base: value+="\n基礎値  "+text(base)
	return value
static func repair_delta(s: Dictionary, cfg: Dictionary, uid: String) -> String:
	var values: Dictionary=E.Condition.stats(s,uid,cfg); var base: Dictionary=E.Condition.stats(s,uid,cfg,true); var changes: Dictionary={}
	for key in base:
		if int(base[key])!=int(values[key]): changes[key]=int(base[key])-int(values[key])
	return "修理後  "+text(base)+(" / 差 "+text(changes) if not changes.is_empty() else " / 性能差なし")
static func repair_reason(s: Dictionary, cfg: Dictionary, uid: String) -> String:
	var cost: int=E.Condition.cost(s,uid,cfg)
	if cost<0: return "修理対象外"
	if cost==0: return "修理不要"
	if s.phase!="town": return "町で修理できます"
	if E.money(s,s.get("payment_source","inventory"))<cost: return "所持金不足"
	return ""
static func comparison(before: Dictionary, after: Dictionary) -> Array:
	var changed: Array=[]; var same: Array=[]
	for key in NAMES:
		var row: Dictionary={"key":key,"name":NAMES[key],"before":int(before[key]),"after":int(after[key]),"delta":int(after[key])-int(before[key])}
		if row.delta!=0: changed.append(row)
		else: same.append(row)
	return changed+same

static func profile(s: Dictionary, cfg: Dictionary, uid: String) -> String:
	if not s.has("item_details") or not s.item_details.has(uid): return ""
	var d: Dictionary=s.item_details[uid]
	var seals: Array[String]=[]
	for status in d.seals:seals.append(cfg.progression.seals[status].name)
	return "個体基礎："+text(d.base_roll)+" / 追加："+(text(d.affix_stats) if not d.affix_stats.is_empty() else "なし")+"\n印 %d枠："%d.seal_slots+("・".join(seals) if not seals.is_empty() else "未加工")+("（破損中は停止）" if s.item_condition[uid].current==0 else "")+" / 入手："+d.origin
