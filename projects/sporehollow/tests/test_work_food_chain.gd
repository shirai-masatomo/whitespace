extends SceneTree
const Farm=preload("res://game/world.gd")
const Snap=preload("res://game/research_snapshot.gd")
var out=""
var failed=0
var report={"method":"Production World.step; controlled starting positions and satiety; separate-process snapshot reload; injected Godot input for UI. No human play.","groups":[]}
var group={}
func _initialize():call_deferred("run")
func begin(name: String):group={"name":name,"checks":[]};report.groups.append(group)
func check(ok: bool,note: String):
	group.checks.append({"passed":ok,"check":note})
	if not ok:failed+=1;push_error(note)
func farm():
	var w=Farm.new({},31).begin_day();w.trees.clear();w.natural.clear();w.field_items.clear();w.day_seconds=9999;w.nature_config.spawn_chance_per_second=0;w.storage_cells=[];w.stock_used={}
	w.keeper.pos=Vector2i(4,6);w.keeper_path=[[4,6]];w.keeper.satiety=31.6;w.story.intro_seen=true
	w.animals[0].pos=Vector2i(20,13);w.animals[0].mode="stay";w.Stock.sync(w)
	return w
func chain():
	var w=farm();w.Stock.add(w,"wood",w.BUILD.wood_wall.cost+8,Vector2i(8,6));w.Stock.add(w,"mushroom",2,Vector2i(6,5));w.act("storage",Vector2i(10,7));w.act("wood_wall",Vector2i(4,8));return w
func result(w):
	return {"built":w.metrics.built,"tick":w.tick,"satiety":w.keeper.satiety,"totals":w.Stock.totals(w),"used":w.stock_used,"pos":w.keeper.pos,"jobs":w.jobs.map(func(j):return [j.id,j.kind,j.get("phase",""),j.get("assigned_to","")]),"claims":w.work_claims}
func finish_chain(w):
	var states=[];var previous=""
	for i in range(350):
		w.step()
		var state=w.Jobs.status(w)
		if state!=previous:states.append({"tick":w.tick,"state":state,"cargo":w.Stock.cargo(w,"keeper").map(func(r):return [r.kind,r.amount]),"satiety":w.keeper.satiety});previous=state
		if w.metrics.built==1 and w.stock_used.get("mushroom",0)==1:break
	return states
func run():
	out=OS.get_environment("FARM_REVIEW_OUTPUT")
	if out=="" or not "--isolated-review" in OS.get_cmdline_user_args():quit(2);return
	if "--resume-snapshot" in OS.get_cmdline_user_args():
		begin("Separate process restoration")
		var w=Snap.restore(out+"/mid-carry.snapshot")
		check(w!=null,"Dedicated snapshot loads in a new engine process")
		if w!=null:
			check(not w.Stock.cargo(w,"keeper").is_empty() and not w.Work.active(w).is_empty(),"Carried goods and the assigned job survive restart")
			group.states=finish_chain(w)
			var expected=FileAccess.open(out+"/expected.bin",FileAccess.READ).get_var(false)
			check(result(w)==expected,"Resumed completion matches uninterrupted tick, goods, satiety, assignment and resource outflow")
			group.result=result(w)
		write_result("restart.json");return
	begin("1 Wall designation through hauling, eating and resuming")
	var w=chain();var initial=w.Stock.totals(w)
	for i in range(80):
		w.step()
		if not w.Stock.cargo(w,"keeper").is_empty():break
	check(not w.Stock.cargo(w,"keeper").is_empty(),"Human physically picked up building materials")
	check(Snap.save(w,out+"/mid-carry.snapshot"),"Mid-carry snapshot saved without touching campaign save")
	group.states=finish_chain(w)
	check(w.metrics.built==1 and w.structures.get(Vector2i(4,8),{}).get("status")=="ready","Wall completes after autonomous materials and meal")
	check(w.stock_used.get("mushroom",0)==1 and w.keeper.satiety>w.Work.Policy.EAT_THRESHOLD,"Exactly one food unit consumed and satiety restored")
	check(w.Stock.totals(w).get("wood",0)+w.stock_used.get("wood",0)==initial.wood,"Ground, carried and site material plus installed consumption conserve wood")
	check(group.states.any(func(s):return "食事中" in s.state) and group.states.any(func(s):return "物資を" in s.state),"Trace shows meal and resumed physical work")
	group.result=result(w);FileAccess.open(out+"/expected.bin",FileAccess.WRITE).store_var(result(w),false)
	begin("2 Two humans, material/food contention and interrupted cargo")
	w=farm();w.keeper.satiety=100;var helper=w.keeper.duplicate(true);helper.pos=Vector2i(8,8);helper.name="検証用の人";w.Work.register(w,"helper",helper)
	var cost=w.BUILD.wood_wall.cost;w.Stock.add(w,"wood",cost*2,Vector2i(8,6));w.Stock.add(w,"mushroom",2,Vector2i(6,5))
	w.act("wood_wall",Vector2i(4,8));w.act("wood_wall",Vector2i(10,8))
	for i in range(250):
		w.step()
		if w.metrics.built==2:break
	check(w.metrics.built==2 and w.Stock.totals(w).get("wood",0)==0 and w.stock_used.get("wood",0)==cost*2,"Two people build with shared physical stock without duplication")
	w.keeper.satiety=20;helper.satiety=20
	for i in range(100):
		w.step()
		if w.stock_used.get("mushroom",0)==2:break
	check(w.stock_used.get("mushroom",0)==2 and w.Stock.totals(w).get("mushroom",0)==0 and w.keeper.satiety>30 and helper.satiety>30,"Food reservations allocate two meals exactly once")
	w=chain();w.keeper.satiety=100
	for i in range(80):
		w.step()
		if not w.Stock.cargo(w,"keeper").is_empty():break
	var before=w.Stock.totals(w);w.Work.set_drafted(w,"keeper",true)
	check(w.Stock.cargo(w,"keeper").is_empty() and w.Stock.totals(w)==before and w.field_items.all(func(r):return r.claims.is_empty()),"Drafting drops carried material and releases claims without losing quantity")
	w.Work.set_drafted(w,"keeper",false)
	for i in range(80):
		w.step()
		if not w.Stock.cargo(w,"keeper").is_empty():break
	before=w.Stock.totals(w);w.keeper.carrier=999;w.step()
	check(w.Stock.cargo(w,"keeper").is_empty() and w.Stock.totals(w)==before and w.work_claims.is_empty(),"Capture releases carried material and job owner without a quantity loss")
	w.keeper.carrier=-1
	for i in range(220):
		w.step()
		if w.metrics.built==1:break
	check(w.metrics.built==1,"Released material is found again and wall finishes")
	w=chain();w.keeper.satiety=20
	for i in range(100):
		w.step()
		if w.keeper.has("meal_remaining"):break
	before=w.Stock.totals(w);w.Life.set_rest(w,true,"manual");w.step()
	check(not w.keeper.has("meal_remaining") and w.Stock.totals(w)==before and w.field_items.all(func(r):return r.claims.is_empty()),"Manual rest interrupts eating, releases food reservation and retains the uneaten portion")
	w=farm();w.keeper.satiety=100;w.Stock.add(w,"wood",10,Vector2i(8,6));w.act("wood_wall",Vector2i(4,8));w.step()
	var vanished=w.field_items.filter(func(r):return r.kind=="wood")[0];w.field_items.erase(vanished);w.step()
	check(w.jobs[0].state=="blocked" and w.work_claims.is_empty(),"Disappearing reserved material releases ownership with a reason")
	w.Stock.add(w,"wood",10,Vector2i(7,6))
	for i in range(180):
		w.step()
		if w.jobs[0].get("started",false):break
	var original=10;w.Jobs.cancel(w,w.jobs[0].id)
	check(w.Stock.totals(w).get("wood",0)+w.stock_used.get("wood",0)==original and w.work_claims.is_empty(),"Cancelling a started physical site preserves refund plus consumed quantity")
	begin("3 Storage capacity, food shortage and existing transactions")
	w=farm();w.keeper.satiety=100;w.Stock.add(w,"wood",12,Vector2i(8,6));w.act("storage",Vector2i(5,8))
	for i in range(12):w.step()
	check(w.jobs.is_empty() and w.Stock.storage_used(w,Vector2i(5,8))==0,"Storage alone does not create an implicit hauling order")
	w.Stock.designate(w,"haul",Vector2i(8,6),Vector2i(8,6))
	for i in range(180):w.step()
	check(w.Stock.storage_used(w,Vector2i(5,8))==12 and w.Stock.totals(w).wood==12,"Explicit hauling places goods inside designated storage")
	w.Stock.add(w,"stone",w.Work.Policy.STORAGE_CAPACITY-12,Vector2i(5,8));w.Stock.add(w,"wood",3,Vector2i(8,6));w.Stock.designate(w,"haul",Vector2i(8,6),Vector2i(8,6))
	for i in range(35):w.step()
	check(w.jobs.any(func(j):return j.state=="blocked") and w.Stock.totals(w).wood==15,"Full storage retains goods with an explicit blocked reason")
	w.keeper.satiety=20;w.natural[Vector2i(6,6)]="mushroom"
	for i in range(100):
		w.step()
		if w.stock_used.get("mushroom",0)>0:break
	check(w.stock_used.get("mushroom",0)==1 and not w.natural.has(Vector2i(6,6)),"Existing natural mushroom can supply a meal when stock runs out")
	w=farm();w.keeper.satiety=100;w.Stock.add(w,"wood",20,Vector2i(8,6))
	var claims=w.Stock.reserve(w,"wood",8,"test",w.keeper)
	check(w.resource_amount("wood")==12 and not w.Stock.consume(w,"wood",13),"Old resource consumers cannot consume reserved stock")
	w.Stock.release_token(w,"test");w.add_resource("wood",-5)
	check(w.Stock.totals(w).wood==15,"Compatibility resource deduction updates the physical ledger once")
	w.Stock.add(w,"collar",1,Vector2i(7,6));w.animals[0].pos=Vector2i(9,6)
	check(w.Progression.equip_job(w,1,"collar"),"Existing equipment order accepts a physical item")
	for i in range(180):
		w.step()
		if not w.animals[0].equipment.is_empty():break
	check(w.animals[0].equipment.get("item_id")=="collar" and w.item_count("collar")==0 and w.Stock.totals(w).get("collar",0)==1,"Equipment is carried to its animal, leaving exactly one equipped object")
	w.phase="shop";w.campaign.gold=1000
	var goods=w.shop_stock.filter(func(row):return w.Shop.table()[row.product].Category=="materials" and row.remaining>0)
	check(not goods.is_empty(),"Controlled shop has a material transaction to exercise")
	if not goods.is_empty():
		var product=goods[0].product;var amount=w.Shop.table()[product].Amount;var before_buy=w.Stock.totals(w).get(product,0)
		check(w.buy(product) and w.Stock.totals(w).get(product,0)==before_buy+amount,"Buying spawns the purchased material quantity on the map once")
		check(w.sell(product) and w.Stock.totals(w).get(product,0)==before_buy,"Selling removes the physical quantity once")
	w=farm();w.keeper.satiety=20;w.Stock.add(w,"mushroom",1,Vector2i(10,6));w.Stock.add(w,"soil",10,Vector2i(5,6));w.act("wall",Vector2i(4,8))
	for cell in w.neighbors(Vector2i(10,6)):w.structures[cell]={"id":700+cell.x+cell.y*25,"kind":"wall","status":"ready","hp":8,"max_hp":8,"open":false}
	for i in range(100):w.step()
	check(w.metrics.built==1 and w.Stock.totals(w).get("mushroom",0)==1 and w.player_events.filter(func(e):return e.key.begins_with("food_shortage")).size()==1,"Unreachable food does not freeze other work or flood the event history")
	w.structures.erase(Vector2i(9,6))
	for i in range(120):
		w.step()
		if w.stock_used.get("mushroom",0)==1:break
	check(w.stock_used.get("mushroom",0)==1,"Opening the food route leads to a meal without manual reset")
	begin("4 Campaign migration and dedicated snapshot authority")
	var live=Farm.new({},31).begin_day()
	var plots=live.neighbors(live.keeper.pos).filter(func(p):return live.Jobs.build_reason(live,"wall",p)=="")
	check(not plots.is_empty() and live.act("wall",plots[0]),"Unmodified starting ranch accepts a nearby wall designation")
	for i in range(300):
		live.step()
		if live.metrics.built>0:break
	check(live.metrics.built==1,"Starting ranch can reach its initial physical supplies and construct without terrain changes")
	var old=Farm.new_campaign();old.resources.wood=30;old.items={"dog_food":2};old.mushrooms=3
	w=Farm.new(old,31);var totals=w.Stock.totals(w);w.persist_farm();var reload=Farm.new(w.campaign,31)
	check(reload.Stock.totals(reload)==totals and totals.wood==30 and totals.mushroom==3,"Scalar legacy campaign migrates once and does not duplicate on reload")
	var paid=Farm.new_campaign();paid.resources.soil=90;paid.work_jobs=[{"id":91,"kind":"wall","pos":[4,8],"animal_id":-1,"state":"pending","resource":"soil","reserved":10,"started":false}]
	var migrated=Farm.new(paid,31).begin_day();migrated.trees.clear();migrated.day_seconds=9999;migrated.keeper.pos=Vector2i(4,7)
	check(migrated.Stock.totals(migrated).soil==100 and migrated.jobs[0].reserved==0 and migrated.Stock.delivered(migrated,migrated.jobs[0])==10,"Legacy paid budget becomes site material once, separate from the remaining ground stock")
	for i in range(30):
		migrated.step()
		if migrated.metrics.built==1:break
	check(migrated.metrics.built==1 and migrated.Stock.totals(migrated).soil==90,"Legacy paid site completes without charging remaining stock")
	check(Snap.save(reload,out+"/ledger.snapshot") and Snap.restore(out+"/ledger.snapshot").Stock.totals(Snap.restore(out+"/ledger.snapshot"))==totals,"Dedicated snapshot preserves ledger independently from ordinary save")
	if DisplayServer.get_name()!="headless":await visual()
	write_result("work-food-chain.json")
func write_result(name: String):
	report.passed=failed==0;report.failures=failed
	FileAccess.open(out+"/"+name,FileAccess.WRITE).store_string(JSON.stringify(report,"\t"))
	print("Work/food chain: ",report.groups.size()," groups, ",failed," failures")
	quit(0 if failed==0 else 1)
func press(button):
	await click_at(button.get_global_rect().get_center())
func click_at(at: Vector2):
	var motion=InputEventMouseMotion.new();motion.position=at;Input.parse_input_event(motion);await process_frame
	for down in [true,false]:
		var event=InputEventMouseButton.new();event.position=at;event.button_index=MOUSE_BUTTON_LEFT;event.pressed=down;Input.parse_input_event(event);await process_frame
func visual():
	begin("5 Representative live UI")
	root.size=Vector2i(1280,800)
	var g=load("res://game/main.tscn").instantiate();g.automated=true;g.world=chain();g.world.day_seconds=90;g.world.paused=true
	root.add_child(g);await process_frame;await process_frame;g.set_process(false);g.audio.set_process(false);g.reset_view();g.neutral()
	g.colony_page="roles";g.group=2;g.refresh()
	check(g.colony_panel.find_child("Priority_keeper_haul",true,false)!=null and not g.buttons.has("storage_zone"),"Roles contains priorities; zones remain in Architect")
	g.select_group(0);g.architect_category="ゾーン";g.refresh()
	await press(g.buttons.zone_stockpile)
	check(g.tool=="zone_stockpile","Injected mouse selects stockpile designation tool")
	await click_at(g.screen_cell(Vector2i(11,6)))
	check(Vector2i(11,6) in g.world.storage_cells,"Injected board click designates a real storage cell")
	g.tool="";g.refresh();g.toggle_menu()
	await press(g.buttons.menu_save)
	var saved_satiety=g.world.keeper.satiety;g.world.keeper.satiety=55
	await press(g.buttons.menu_load)
	check(is_equal_approx(g.world.keeper.satiety,saved_satiety),"Pause menu save/load restores the development world")
	g.toggle_menu()
	g.world.paused=false
	for i in range(100):
		g.world.step()
		if g.world.keeper.has("meal_remaining"):break
	g.world.paused=true;g.refresh();g.refresh_jobs();g.queue_redraw();g.hud.queue_redraw();await process_frame;await process_frame;await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(out+"/meal-and-work.png")
	check(g.world.keeper.has("meal_remaining"),"Representative scene captured during the actual eating phase")
	g.world.paused=false;finish_chain(g.world);g.world.paused=true;g.refresh();g.refresh_jobs();g.queue_redraw();g.hud.queue_redraw()
	await process_frame;await process_frame;await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(out+"/wall-completed.png")
	check(g.world.metrics.built==1,"Same rendered world resumes and completes its wall")
