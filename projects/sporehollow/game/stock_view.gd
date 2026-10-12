extends RefCounted
## Read-only grouping: physical IDs and coordinates never change for presentation.
static func rows(w,location: String="ground",owner: String="") -> Array:
	var groups={}
	for item in w.field_items:
		if item.get("location","ground")!=location or (owner!="" and item.get("owner","")!=owner):continue
		var key="%d:%d:%s"%[item.pos.x,item.pos.y,item.kind]
		if not groups.has(key):groups[key]={"pos":item.pos,"kind":item.kind,"amount":0,"ids":[],"forbidden":0,"stored":0,"offset":Vector2.ZERO,"compact":false}
		var row=groups[key];var n=item.get("amount",1);row.amount+=n;row.ids.append(item.get("stock_id",-1))
		if item.get("forbidden",false):row.forbidden+=n
		if w.Stock.stored(w,item):row.stored+=n
	var result=groups.values();result.sort_custom(func(a,b):return (a.pos.y*w.W+a.pos.x)<(b.pos.y*w.W+b.pos.x) if a.pos!=b.pos else a.kind<b.kind)
	var by_cell={}
	for row in result:
		if not by_cell.has(row.pos):by_cell[row.pos]=[]
		by_cell[row.pos].append(row)
	for cell in by_cell:
		var group=by_cell[cell]
		if group.size()<2:continue
		for i in range(group.size()):
			group[i].compact=true
			group[i].offset=Vector2(-10 if i%2==0 else 10,-8 if i<2 else 8) if group.size()>2 else Vector2(-10 if i==0 else 10,0)
	return result

static func details(w,cell: Vector2i) -> String:
	var lines=[]
	for row in rows(w):
		if row.pos!=cell:continue
		var name={"soil":"土","wood":"木材","stone":"石","mushroom":"キノコ","egg":"卵","dog_food":"犬の餌","hen_food":"鶏の餌","meat":"肉","milk":"牛乳","whistle":"ホイッスル","coffee":"コーヒー","energy_drink":"活力ドリンク","wood_staff":"木の長柄"}.get(row.kind,w.ProgressData.ITEMS.get(row.kind,{}).get("name","物資"))
		lines.append("%s ×%d · 備蓄%d%s"%[name,row.amount,row.stored," · 禁止%d"%row.forbidden if row.forbidden>0 else ""])
	return "\n".join(lines)
