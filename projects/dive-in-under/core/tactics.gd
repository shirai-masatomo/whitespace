extends RefCounted
## Session-only named squad assets. No adventure-save I/O.
const MAX_RULES=8
const MAX_CONDITIONS=2
const MAX_SETS=8
const CONDITIONS=["always","hp_below","sp_above","poisoned","enemy_telegraph"]
const TARGETS=["enemy_front","enemy_back","enemy_any","self"]
static func default_set(id: String="attack", defensive: bool=false) -> Dictionary:
	var rows: Array=[]
	if defensive: rows.append({"skill":"S105","conditions":[{"kind":"enemy_telegraph"}],"target":"self"})
	rows.append({"skill":"S101","conditions":[{"kind":"always"}],"target":"enemy_front"})
	rows.append({"skill":"attack","conditions":[{"kind":"always"}],"target":"enemy_front"})
	return {"id":id,"name":"予告に備える" if defensive else "攻撃を優先","favorite":true,"order":["hero"],"characters":{"hero":{"rank":"front","rows":rows}}}
static func initial() -> Dictionary:
	return {"active":"defense","sets":[default_set(),default_set("defense",true)]}
static func validate(value: Dictionary) -> String:
	if str(value.get("id","")).is_empty() or str(value.get("name","")).strip_edges().is_empty() or str(value.get("name","")).length()>32: return "作戦名は1〜32文字で指定してください。"
	if not value.get("characters") is Dictionary or value.characters.is_empty(): return "キャラの行動設定が必要です。"
	if not value.get("order") is Array or value.order.size()!=value.characters.size(): return "行動順には各キャラを1回ずつ指定してください。"
	var seen: Array=[]
	for id in value.order:
		if id in seen or not value.characters.has(id): return "行動順が重複または不正です。"
		seen.append(id)
	for id in value.characters:
		var entry: Dictionary=value.characters[id]
		if entry.get("rank","") not in ["front","back"] or not entry.get("rows") is Array or entry.rows.size()>MAX_RULES: return "隊列または行数が不正です（8行まで）。"
		for row in entry.rows:
			if not row is Dictionary or row.get("target","") not in TARGETS or row.get("skill","") not in ["attack","S101","S102","S103","S104","S105"]: return "技能・対象を選んでください。"
			if (row.skill=="S105") != (row.target=="self"): return "防御は自分、攻撃技能は敵を対象にしてください。"
			if not row.get("conditions") is Array or row.conditions.size()>MAX_CONDITIONS: return "条件はANDで2つまでです。"
			for condition in row.conditions:
				if not condition is Dictionary or condition.get("kind","") not in CONDITIONS: return "条件が不正です。"
				if condition.kind in ["hp_below","sp_above"] and (float(condition.get("value",-1))<0 or float(condition.get("value",101))>100): return "割合条件は0〜100%です。"
	return ""
static func active(book: Dictionary) -> Dictionary:
	for value in book.sets:
		if value.id==book.active: return value.duplicate(true)
	return {}
static func save(book: Dictionary, value: Dictionary) -> String:
	var reason: String=validate(value)
	if reason!="": return reason
	var index: int=-1
	for i in book.sets.size():
		if book.sets[i].id==value.id: index=i
	if index<0 and book.sets.size()>=MAX_SETS: return "作戦は8個まで保存できます。"
	if index<0: book.sets.append(value.duplicate(true))
	else: book.sets[index]=value.duplicate(true)
	return ""
static func select(book: Dictionary, id: String) -> bool:
	for value in book.sets:
		if value.id==id: book.active=id; return true
	return false
static func reasons_text(unit: Dictionary) -> String:
	var d: Dictionary=unit.get("last_decision",{})
	if d.is_empty(): return "まだ行動していません。"
	return "選択："+str(d.get("label","待機"))+" / 対象："+str(d.get("target_name","なし"))+"\n"+" / ".join(d.get("skipped",[]))
