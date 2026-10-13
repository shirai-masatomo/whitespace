extends SceneTree
const Farm=preload("res://game/world.gd")
const Market=preload("res://game/market_view.gd")
var checks=[]
func _initialize():call_deferred("run")
func check(ok,note):
	checks.append({"passed":ok,"check":note})
	if not ok:push_error(note)
func run():
	var output=OS.get_environment("FARM_REVIEW_OUTPUT")
	if output=="" or "--isolated-review" not in OS.get_cmdline_user_args():quit(2);return
	var w=Farm.new({},31).begin_day();w.field_items.clear();w.zones=[];w.storage_cells=[];w.keeper.pos=Vector2i(10,10);w.trees.clear();w.rocks.clear();w.Mountains.reindex(w)
	w.Zones.create(w,"stockpile",Vector2i(9,10),Vector2i(9,10))
	var row=w.Stock.add(w,"wood",40,Vector2i(9,10));var q=w.Stock.summary(w,"wood")
	check(q.owned==40 and q.stored==40 and q.available==40,"40 stored: total/stored/available agree")
	w.Stock.reserve(w,"wood",8,"review:first",w.keeper);q=w.Stock.summary(w,"wood")
	check(q.owned==40 and q.stored==40 and q.available==32 and q.reserved==8,"Eight claimed is a subset, not extra ownership")
	var helper=w.keeper.duplicate(true);helper.work_key="helper"
	w.Stock.reserve(w,"wood",40,"review:second",helper);q=w.Stock.summary(w,"wood")
	check(q.reserved==40 and q.available==0,"Two workers cannot reserve more than actual stack")
	w.Stock.release_token(w,"review:second")
	var carried=w.Stock.pickup(w,row,"review:first",w.keeper,99);q=w.Stock.summary(w,"wood")
	check(q.owned==40 and q.stored==32 and q.carried==8 and q.available==32 and q.reserved==0,"Pickup moves eight into carry, total unchanged")
	carried.location="site";carried.owner="";w.Stock.sync(w);q=w.Stock.summary(w,"wood")
	check(q.owned==40 and q.site==8 and q.carried==0,"Delivered material is counted on site once")
	w.Stock.finish_build(w,{"id":99},true);q=w.Stock.summary(w,"wood")
	check(q.owned==32 and q.site==0 and w.stock_used.wood==8,"Construction consumes delivered eight once")
	var before=w.Stock.summary(w,"soil").owned;w.campaign.gold=1000;w.phase="shop"
	check(w.buy("soil"),"Production shop purchase succeeds")
	q=w.Stock.summary(w,"soil");check(q.owned==before+50 and q.outside>=50 and Market.owned(w,{"id":"soil"})==q.owned,"Bought materials appear immediately in total ownership and remain outside storage")
	var soil=w.field_items.filter(func(a):return a.kind=="soil")[0]
	w.Zones.create(w,"stockpile",soil.pos,soil.pos);soil.stocked=true;w.Stock.sync(w)
	check(w.sell("soil") and w.Stock.summary(w,"soil").owned==before,"Sell consumes exactly the existing set")
	for enabled in [false,true]:
		w=Farm.new({},31).begin_day();w.trees.clear();w.rocks.clear();w.nature_config.spawn_chance_per_second=0
		w.keeper.pos=Vector2i(15,15);w.animals[0].pos=Vector2i(16,15);w.animals[0].mode="stay";w.animals[0].home=w.animals[0].pos;w.animals[0].order_until=99999
		for category in w.Work.Policy.ORDER:w.keeper.work_priorities[category]=0
		w.keeper.work_priorities.animal=1 if enabled else 0;w.keeper.work_priorities.other=0 if enabled else 1
		var loyalty=w.animals[0].loyalty;w.Tasks.designate(w,"train",Vector2i.ZERO,1)
		for i in range(140):w.step()
		check((w.animals[0].loyalty>loyalty)==enabled,"Animal priority controls actual completed training, enabled="+str(enabled))
	w=Farm.new({},31).begin_day();w.trees.clear();w.rocks.clear();w.natural.clear();w.structures.clear();w.field_items.clear();w.zones.clear();w.Zones.sync_storage(w);w.nature_config.spawn_chance_per_second=0
	w.keeper.pos=Vector2i(4,5);w.animals[0].pos=Vector2i(20,20);w.animals[0].mode="stay";w.animals[0].home=w.animals[0].pos
	for x in range(1,13):
		for y in [4,6]:w.structures[Vector2i(x,y)]={"id":x+y*100,"kind":"wall","status":"ready","hp":8,"max_hp":8,"open":false}
	for x in [1,12]:w.structures[Vector2i(x,5)]={"id":x+500,"kind":"wall","status":"ready","hp":8,"max_hp":8,"open":false}
	helper=w.keeper.duplicate(true);helper.pos=Vector2i(7,7);helper.drafted=true;w.Work.register(w,"helper",helper);helper.drafted=true
	w.Zones.create(w,"stockpile",Vector2i(10,5),Vector2i(10,5));w.Stock.add(w,"wood",8,Vector2i(3,5));w.Stock.designate(w,"haul",Vector2i(3,5),Vector2i(3,5))
	for i in range(20):
		w.step()
		if not w.Stock.cargo(w,"keeper").is_empty():break
	check(w.Stock.summary(w,"wood").carried==8,"Transport had physically picked up eight before the other worker blocked its route")
	helper.pos=Vector2i(7,5)
	var positions=[]
	for i in range(48):
		w.step()
		if i>=32:positions.append(w.keeper.pos)
	check(w.Stock.summary(w,"wood").owned==8 and not w.jobs.is_empty(),"Blocked transport retains the exact eight goods and job")
	check(positions.all(func(p):return p==positions[0]) and not w.jobs.is_empty() and w.jobs[0].get("block_reason","")!="","Worker blocking a one-cell passage causes stable waiting with a reason, not oscillation")
	helper.pos=Vector2i(7,7)
	for i in range(120):
		w.step()
		if w.jobs.is_empty():break
	check(w.jobs.is_empty() and w.Stock.summary(w,"wood").stored==8,"Clearing the actor obstruction resumes and delivers without manual reset")
	var passed=checks.all(func(c):return c.passed)
	FileAccess.open(output+"/quality-ledger.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"passed":passed},"  "))
	quit(0 if passed else 1)

