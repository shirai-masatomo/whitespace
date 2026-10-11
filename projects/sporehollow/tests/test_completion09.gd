extends SceneTree
const Farm=preload("res://game/world.gd")
var failed=0
var groups=[]
var group={}
func _initialize():call_deferred("run")
func begin(name):group={"name":name,"checks":[]};groups.append(group)
func check(ok,note):
	group.checks.append({"passed":bool(ok),"check":note})
	if not ok:failed+=1;push_error(note)
func farm():
	var w=Farm.new({},31).begin_day();w.trees.clear();w.natural.clear();w.structures.clear();w.floors.clear();w.jobs.clear();w.field_items.clear();w.zones=[];w.storage_cells=[];w.animals[0].pos=Vector2i(42,29);w.animals[0].mode="stay";w.animals[0].order_until=99999;w.rocks={};w.Tasks.save(w);w.nature_config.spawn_chance_per_second=0
	w.keeper.pos=Vector2i(10,10);w.keeper.placed=true;w.keeper.satiety=100;w.keeper.sleepiness=0;w.story.intro_seen=true;return w
func enemy(w,p):
	w.spawn_enemy({"entry":Vector2i(1,5),"role":"kidnapper","archetype":"kidnapper"})
	var e=w.enemies.back();e.pos=p;e.move_stopped_until=99999;e.next_attack=99999;e.hp=100;e.max_hp=100;e.capture_progress=0;e.defense=0;return e
func progress(w,kind):
	for i in range(100):
		w.step()
		if not w.jobs.any(func(j):return j.kind==kind):return
func run():
	var out=OS.get_environment("FARM_REVIEW_OUTPUT")
	if out=="" or "--isolated-review" not in OS.get_cmdline_user_args():quit(2);return
	begin("3 Physical keeper equipment and drafted target combat")
	var w=farm();w.Stock.add(w,"wood_staff",1,Vector2i(13,10))
	check(w.HumanCombat.equip(w,"wood_staff"),"One physical staff can be reserved for keeper equipment")
	for i in range(30):
		w.step()
		if not w.Stock.cargo(w,"keeper").is_empty():break
	check(w.keeper.get("equipment",{}).is_empty() and w.Stock.cargo(w,"keeper").size()==1,"Worker walks to the actual staff before equipping; carried item exists")
	w.Snapshot.save(w,out+"/equipment.snapshot");w=w.Snapshot.restore(out+"/equipment.snapshot");progress(w,"keeper_equipment")
	check(w.keeper.equipment.get("item_id")=="wood_staff" and w.Stock.totals(w).get("wood_staff",0)==1,"Save during pickup resumes to one equipped item without duplication")
	w.persist_farm();var copy=Farm.new(w.campaign,31)
	check(copy.keeper.equipment==w.keeper.equipment and copy.Stock.totals(copy).get("wood_staff",0)==1,"Campaign persistence retains keeper equipment and total quantity")
	w.HumanCombat.equip(w,"unequip");progress(w,"keeper_equipment")
	check(w.keeper.equipment.is_empty() and w.Stock.available(w,"wood_staff")==1,"Unequip returns one physical staff at current position")
	w.HumanCombat.equip(w,"wood_staff");w.step();var j=w.jobs.filter(func(row):return row.kind=="keeper_equipment")[0]
	w.Jobs.cancel(w,j.id)
	check(w.keeper.equipment.is_empty() and w.Stock.totals(w).get("wood_staff",0)==1,"Cancellation releases reserved/carried equipment without consuming it")
	for row in w.field_items:row.forbidden=true
	check(not w.HumanCombat.equip(w,"wood_staff"),"Forbidden staff cannot be designated for equipping")
	w=farm();var near=enemy(w,Vector2i(9,10));var target=enemy(w,Vector2i(12,10));w.keeper.equipment={"item_id":"wood_staff","durability":-1}
	w.Work.set_drafted(w,"keeper",true);check(w.HumanCombat.designate(w,target.id),"Drafted keeper accepts the explicitly selected enemy")
	w.step();check(target.hp==97 and near.hp==100 and w.keeper.pos==Vector2i(10,10),"Staff strikes selected enemy at two cells; closer enemy is not substituted")
	var until=w.keeper.next_attack;w.step();check(target.hp==97 and w.keeper.next_attack==until,"Automatic defense does not add a second attack or reset target timing")
	w.keeper.equipment={};w.keeper.next_attack=0
	var before=target.hp;w.step();check(target.hp==before,"Bare hands cannot strike from staff reach")
	for i in range(10):w.step()
	check(target.hp<before and maxi(absi(target.pos.x-w.keeper.pos.x),absi(target.pos.y-w.keeper.pos.y))<=1,"Bare hands follow a real walk route into adjacent attack range")
	w.Work.set_drafted(w,"keeper",false);check(not w.jobs.any(func(row):return row.get("direct_control",false)),"Undrafting cancels the direct target job")
	w=farm();target=enemy(w,Vector2i(14,10));w.Work.set_drafted(w,"keeper",true);w.HumanCombat.designate(w,target.id);w.keeper.nutrition_down=true;w.keeper.malnutrition=80;var pos=w.keeper.pos;w.step()
	check(target.hp==100 and w.keeper.pos==pos,"Nutrition incapacity blocks drafted pursuit and attacks")
	begin("4 Daily supply event, old enemies, physical haul/food and save guards")
	w=farm();var old=enemy(w,Vector2i(35,20));w.calendar_ticks=359;w.campaign.calendar_ticks=359
	w.step();check(w.Cycle.period(w)=="day" and w.campaign.last_supply_day==1,"Crossing 10:00 creates the day's noncombat arrival")
	check(w.Stock.totals(w).get("wood",0)==8 and w.Stock.totals(w).get("mushroom",0)==3 and not old.done,"Supplies arrive as physical goods even with an unresolved enemy")
	w.Cycle.supplies(w,1);w.Snapshot.save(w,out+"/supplies.snapshot");w=w.Snapshot.restore(out+"/supplies.snapshot");w.Cycle.supplies(w,1)
	check(w.Stock.totals(w).wood==8 and w.Stock.totals(w).mushroom==3,"Repeated boundary and restore do not duplicate daily goods")
	var z=w.Zones.create(w,"stockpile",Vector2i(7,8),Vector2i(7,8));w.Zones.set_allowed(w,z,["wood"])
	w.keeper.pos=Vector2i(2,5);w.keeper.satiety=20
	for i in range(110):w.step()
	check(w.stock_used.get("mushroom",0)==1 and w.keeper.satiety>30,"Arrived mushrooms enter existing physical eating behavior")
	check(w.field_items.any(func(row):return row.kind=="wood" and row.pos==Vector2i(7,8)) and w.Stock.totals(w).wood==8,"Existing hauling moves arriving wood into storage without loss")
	w.Cycle.supplies(w,2);check(w.Stock.totals(w).wood==16 and w.campaign.last_supply_day==2,"A different day's one arrival remains eligible")
	w.Stock.add(w,"wood_staff",1,w.keeper.pos+Vector2i.RIGHT);w.HumanCombat.equip(w,"wood_staff")
	w.rocks={Vector2i(9,9):{"amount":8,"forbidden":false}};w.Tasks.save(w);w.Tasks.designate(w,"mine",Vector2i(9,9))
	w.Snapshot.save(w,out+"/fixture.snapshot")
	FileAccess.open(out+"/completion09.json",FileAccess.WRITE).store_string(JSON.stringify({"method":"Controlled production World.step and snapshot/campaign tests; simulation, not human play","groups":groups,"failures":failed},"	"))
	print("Completion09: 2 groups, ",failed," failures");quit(1 if failed else 0)
