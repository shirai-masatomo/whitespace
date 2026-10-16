extends RefCounted
const Catalog=preload("res://game/item_catalog.gd")
const Policy=preload("res://game/work_policy.gd")
const COMBINATIONS=["cooked:3","cooked:2","cooked:1","cooked:0","raw:3","raw:2","raw:1","raw:0"]
const CELL_ORDER=["cooked:0","cooked:1","cooked:2","cooked:3","raw:0","raw:1","raw:2","raw:3"]
static func initialize(a):
	if a.get("food_priorities",null) is Dictionary and CELL_ORDER.all(func(key):return a.food_priorities.has(key)):return
	# Migrate legacy permutations without changing or discarding the original data.
	var old=a.get("food_order",COMBINATIONS)
	if not old is Array:old=COMBINATIONS
	var values=a.get("food_priorities",{})
	if not values is Dictionary:values={}
	for key in CELL_ORDER:
		if values.has(key):continue
		var index=old.find(key)
		values[key]=index+1 if index>=0 else COMBINATIONS.find(key)+1
	a.food_priorities=values
static func value(a,combination:String)->int:
	initialize(a);return clampi(int(a.food_priorities.get(combination,8)),1,8)
static func change(a,combination:String,rank_value:int):
	initialize(a)
	if combination in CELL_ORDER:a.food_priorities[combination]=clampi(rank_value,1,8)
static func order(a)->Array:
	initialize(a);var rows=Policy.HUMAN_FOOD.filter(func(id):return Catalog.item(id).subcategory in ["raw","cooked"])
	rows.sort_custom(func(x,y):
		var rx=rank(a,x);var ry=rank(a,y)
		if rx!=ry:return rx<ry
		var cx=cell_index(x);var cy=cell_index(y)
		return cx<cy if cx!=cy else Policy.HUMAN_FOOD.find(x)<Policy.HUMAN_FOOD.find(y))
	return rows
static func cell_index(id:String)->int:
	var item=Catalog.item(id);return CELL_ORDER.find(item.subcategory+":"+str(item.tier))
static func rank(a,id:String)->int:
	var item=Catalog.item(id);return value(a,item.subcategory+":"+str(item.tier))
