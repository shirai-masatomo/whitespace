extends RefCounted
## Mixed construction ingredients. Old single-material definitions remain valid.
static func materials(w,kind:String,j:Dictionary={}) -> Dictionary:
	var data=w.BUILD.get(kind,{"cost":1,"resource":j.get("resource","soil")})
	return j.get("materials",data.get("materials",{data.get("resource","soil"):int(j.get("required",data.cost))})).duplicate()
static func total(values:Dictionary) -> int:
	var n=0
	for count in values.values():n+=int(count)
	return n
static func onsite(w,j,kind:String,include_forbidden:bool=false) -> int:
	var n=0
	for row in w.field_items:
		if row.get("location")=="site" and row.get("job_id",-1)==j.id and row.kind==kind and (include_forbidden or not row.get("forbidden",false)):n+=row.amount
	return n
static func missing(w,j) -> Dictionary:
	var amounts=materials(w,j.kind,j)
	for kind in amounts:amounts[kind]=maxi(0,amounts[kind]-onsite(w,j,kind))
	return amounts
static func text(values:Dictionary) -> String:
	var parts=[]
	for kind in values:parts.append("%s%d"%[preload("res://game/item_catalog.gd").title(kind),values[kind]])
	return "・".join(parts)
