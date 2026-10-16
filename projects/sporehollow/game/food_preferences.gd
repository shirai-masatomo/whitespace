extends RefCounted
const Catalog=preload("res://game/item_catalog.gd")
const COMBINATIONS=["cooked:3","cooked:2","cooked:1","cooked:0","raw:3","raw:2","raw:1","raw:0"]
static func initialize(a):
	if not a.has("food_order"):a.food_order=COMBINATIONS.duplicate()
static func change(a,combination:String,rank:int):
	initialize(a);var i=a.food_order.find(combination);var other=clampi(rank-1,0,7)
	if i<0:return
	var previous=a.food_order[other];a.food_order[other]=combination;a.food_order[i]=previous
static func order(a)->Array:
	initialize(a);var rows=preload("res://game/work_policy.gd").HUMAN_FOOD.duplicate()
	rows.sort_custom(func(x,y):return rank(a,x)<rank(a,y) if rank(a,x)!=rank(a,y) else preload("res://game/work_policy.gd").HUMAN_FOOD.find(x)<preload("res://game/work_policy.gd").HUMAN_FOOD.find(y))
	return rows.filter(func(id):return Catalog.item(id).subcategory in ["raw","cooked"])
static func rank(a,id:String)->int:
	initialize(a);var item=Catalog.item(id);return a.food_order.find(item.subcategory+":"+str(item.tier))
