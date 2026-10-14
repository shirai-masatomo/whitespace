extends SceneTree
const Farm=preload("res://game/world.gd")
const Catalog=preload("res://game/item_catalog.gd")
var checks=[]
func check(ok,note):
	checks.append({"check":note,"passed":bool(ok)})
	if not ok:push_error(note)
func _initialize():call_deferred("run")
func run():
	var out=OS.get_environment("FARM_REVIEW_OUTPUT")
	if DisplayServer.get_name()!="headless" or out=="":quit(2);return
	var w=Farm.new(Farm.new_campaign(),31).begin_day();w.jobs.clear();w.field_items.clear();w.zones.clear();w.storage_cells.clear()
	var p=w.keeper.pos+Vector2i.RIGHT;w.natural[p]="weed";var gold=w.campaign.gold
	check(w._execute_local("collect",p,-1),"Weed can be harvested")
	check(w.campaign.gold==gold and w.field_items.size()==1 and w.field_items[0].kind=="fiber" and w.field_items[0].amount==2 and w.field_items[0].location=="ground","Weed yields two physical fiber and no gold")
	check(not w._execute_local("collect",p,-1) and w.field_items.size()==1,"Repeated harvest cannot duplicate fiber")
	for id in Catalog.ROWS:
		var data=Catalog.item(id);check(Catalog.CATEGORIES.has(data.category) and Catalog.CATEGORIES[data.category][1].has(data.subcategory),"Valid taxonomy "+id)
	var low=w.keeper.pos+Vector2i(0,2);var high=w.keeper.pos+Vector2i(0,4)
	for cell in [low,high]:w.natural.erase(cell);w.rocks.erase(cell);w.trees.erase(cell);w.structures.erase(cell)
	var z1=w.Zones.create(w,"stockpile",low,low);var z2=w.Zones.create(w,"stockpile",high,high)
	w.Zones.filter_change(w,z1,"all","",true);w.Zones.filter_change(w,z2,"all","",false)
	w.Zones.filter_change(w,z2,"categories","resource",true);w.Zones.set_priority(w,z2,2)
	check(w.Zones.accepts(w,high,"fiber") and not w.Zones.accepts(w,high,"egg"),"Main-category filter")
	w.Zones.filter_change(w,z2,"subs","fiber",false);check(not w.Zones.accepts(w,high,"fiber"),"Subcategory override")
	w.Zones.filter_change(w,z2,"items","fiber",true);check(w.Zones.accepts(w,high,"fiber"),"Individual override")
	var stock=w.Stock.add(w,"fiber",39,high);stock.stocked=true
	var plan=w.Stock.storage_plan(w,w.keeper,20,"fiber")
	check(plan.get("pos")==high and plan.get("amount")==1,"High-priority zone reserves remaining one of forty")
	w.jobs.append({"id":999,"kind":"haul","storage_target":high,"storage_amount":1})
	check(w.Stock.storage_plan(w,w.keeper,20,"fiber").get("pos")==low,"Reserved capacity falls back to another zone")
	w.Zones.filter_change(w,z2,"all","",false)
	check(w.Stock.find(w,stock.stock_id).amount==39 and stock.pos==high,"Changing filters preserves existing goods and location")
	var fail=checks.filter(func(c):return not c.passed).size()
	FileAccess.open(out+"/craft-stock.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":fail},"\t"))
	print("CRAFT_STOCK: ",checks.size()," checks, failures=",fail);quit(1 if fail else 0)
