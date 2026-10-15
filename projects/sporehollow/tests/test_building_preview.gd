extends SceneTree
const Farm=preload("res://game/world.gd")
const Stroke=preload("res://game/wall_stroke.gd")
const Ghost=preload("res://game/building_ghost.gd")
const Art=preload("res://game/building_art.gd")
var checks=[]
var pictures=[]
var timings=[]
func _initialize():call_deferred("run")
func check(ok,text):
	checks.append({"passed":bool(ok),"check":text})
	if not ok:push_error(text)
func fixture():
	var w=Farm.new({},731).begin_day()
	w.trees.clear();w.rocks.clear();w.mountains.clear();w.mountain_cells.clear();w.natural.clear();w.field_items.clear();w.structures.clear();w.floors.clear();w.enemies.clear();w.jobs.clear();w.work_claims.clear();w.zones.clear();w.Zones.sync_storage(w)
	w.keeper.pos=Vector2i(30,25);w.keeper.satiety=100;w.keeper.resting=false;w.jobs_held=false;w.job_hold_reason="";w.animals.clear();w.refresh_indoor()
	w.keeper.work_priorities={"build":1,"gather":2,"collect":3,"animal":4,"other":4,"haul":4}
	w.Zones.create(w,"stockpile",Vector2i(25,23),Vector2i(28,24));w.debug_enabled=true
	return w
func tick(w):
	w.tick+=1
	for a in w.workers.values():w.Combat.recover(a,w.DT,false)
	w.Work.step(w)
func total(w,kind):return w.Stock.totals(w).get(kind,0)
func log_contains(w,text):return w.player_events.any(func(r):return text in r.text)
func logic():
	var w=fixture();var p=Vector2i(35,26);var ghost=Ghost.new()
	var before=w.player_events.size()
	for i in range(30):check(ghost.preview(w,"wood_wall",p).accepted==0,"No material preview is invalid %d"%i)
	check(w.player_events.size()==before,"Hover emits no player log")
	check(not w.act("wood_wall",p) and log_contains(w,"木材不足（必要5／利用可能0）"),"Confirm rejects with material name, cost and available amount")
	check(w.jobs.is_empty(),"Failed confirmation adds no designation")
	check(w.debug_action("replenish"),"Debug button accepts one explicit refill")
	check(total(w,"wood")==40 and total(w,"soil")==40 and total(w,"stone")==40,"Refill creates 40 physical units of each existing resource")
	check(w.field_items.all(func(r):return w.Stock.stored(w,r)) and w.storage_cells.all(func(c):return w.Stock.storage_used(w,c)<=40),"Refill remains inside storage and capacity40")
	check(ghost.preview(w,"wood_wall",p).accepted==1,"Refill invalidates cached shortage preview immediately")
	check(w.act("wood_wall",p),"Same wooden wall accepted after refill")
	check(w.Stock.available(w,"wood")==35 and w.Stock.summary(w,"wood").reserved==5,"Reservation claims five physical units without consuming them")
	var initial=total(w,"wood")
	for i in range(150):
		tick(w)
		if w.metrics.built==1:break
	check(w.metrics.built==1 and w.structures[p].status=="ready","Real delivery and assembly finish the designated wall")
	check(total(w,"wood")==initial-5 and w.stock_used.wood==5,"Exactly five units consumed after completion")
	var rest=total(w,"wood")
	for i in range(20):tick(w)
	check(total(w,"wood")==rest,"No automatic refill across simulation ticks")
	check(not w.debug_action("infinite"),"Removed infinite-material action cannot bypass inventory")
	# New reservation, cancellation and existing delivery claims share the same physical budget.
	w=fixture();w.Stock.add(w,"wood",12,Vector2i(25,23))
	var s=Stroke.new();s.begin("wood_wall",p);s.add(p+Vector2i(3,0))
	var plan=s.plan(w);check(plan.accepted==2 and plan.skipped==2,"Drag budget accepts affordable subset, rejects the rest")
	var result=s.commit(w)
	check(result.accepted==2 and w.Stock.available(w,"wood")==2,"Commit has same budget and no double reservation")
	check(w.player_events.size()==2 and log_contains(w,"2件予約／2件未登録"),"One deduplicated reason plus batch counts, not one log per rejected cell")
	check(not w.Stock.consume(w,"wood",3),"Other consumers cannot spend claimed stock")
	var j=w.jobs[0];w.Jobs.cancel(w,j.id)
	check(w.Stock.available(w,"wood")==7 and total(w,"wood")==12,"Cancelling an unstarted plan releases its claim without loss")
	w.Stock.add(w,"wood",5,Vector2i(29,23)).stocked=false
	check(w.Stock.available(w,"wood")==7,"Unstored resources do not fund construction")
	w.field_items[0].forbidden=true
	check(not w.act("wood_wall",p+Vector2i(0,2)),"Forbidden stock cannot fund construction")
	# Existing plans are left intact when stock is forbidden or removed from a zone.
	check(w.jobs.size()==1 and w.jobs[0].required==5,"Existing designation survives later shortage")
	w=fixture();w.Stock.add(w,"wood",40,Vector2i(25,23));w.rocks[p]={"amount":8}
	check("岩" in w.Jobs.build_reason(w,"wood_wall",p),"Actual rock collision reason takes precedence over material reason")
	w.act("wood_wall",p);check(log_contains(w,"岩を採掘"),"Collision rejection reaches player log on confirm")
	w.rocks.clear();w.campaign.unlocked_blueprints=[]
	check(not w.Jobs.build_reason(w,"kennel",p).is_empty(),"Disabled/blueprint building remains unavailable")
	# Furniture uses completed item claims, rather than reserving the same item twice.
	w.Stock.add(w,"wood_crate",1,Vector2i(26,23))
	check(w.act("place_wood_crate",p),"Furniture can reserve a stored completed item")
	check(not w.act("place_wood_crate",p+Vector2i.RIGHT),"Same furniture cannot be reserved twice")
	check(not w.act("wood_wall",p),"Building cannot overlap an already planned furniture item")
	for i in range(150):
		tick(w)
		if w.jobs.is_empty():break
	check(w.field_items.any(func(r):return r.kind=="wood_crate" and r.get("placed",false) and r.pos==p),"Reserved furniture reaches completed placement")
	check(w.Stock.available(w,"wood_crate")==0,"Placed furniture is no longer available")
func interruptions():
	var w=fixture();var p=Vector2i(35,26)
	w.Stock.add(w,"wood",40,Vector2i(25,23));w.act("wood_wall",p)
	var j=w.jobs[0];w.Delivery.start(w,"keeper",{"seed_job":j.id})
	check(w.Stock.available(w,"wood")==35,"Delivery claims replace, rather than add to, plan claims")
	w.Delivery.release(w,"keeper")
	check(w.Stock.available(w,"wood")==35 and w.field_items[0].claims.get("plan:%d"%j.id,0)==5,"Interrupted fetch restores physical plan claim")
	w.Delivery.start(w,"keeper",{"seed_job":j.id})
	for i in range(80):
		w.tick+=1;w.Delivery.step(w,"keeper")
		if not w.Stock.cargo(w,"keeper").is_empty():break
	check(not w.Stock.cargo(w,"keeper").is_empty(),"Cancellation fixture reaches real carried materials")
	w.Jobs.cancel(w,j.id)
	check(total(w,"wood")==40 and w.jobs.is_empty() and w.field_items.all(func(row):return row.claims.is_empty()),"In-transit cancellation preserves physical total and releases all claims")
	w=fixture();w.Stock.add(w,"wood",10,Vector2i(25,23));w.act("wood_wall",p);j=w.jobs[0]
	w.Stock.release_token(w,"plan:%d"%j.id);j.erase("plan_claimed")
	check(w.Jobs.Reservations.available(w,"wood")==5,"Unfunded pre-existing reservation is deducted from new budget")
	check(w.act("wood_wall",p+Vector2i.RIGHT) and not w.act("wood_wall",p+Vector2i(2,0)),"Existing reservations cannot be displaced by newly accepted jobs")
	w=fixture();w.Stock.add(w,"wood",10,Vector2i(25,23));w.act("wood_wall",p);j=w.jobs[0]
	var transfer=w.Stock.add(w,"wood",3,Vector2i(25,23));transfer.construction_transfer=true;transfer.job_id=j.id
	check(w.Jobs.Reservations.usable(w,transfer,{"id":999,"resource":"wood"})==0,"Dropped construction cargo cannot fund another site even inside storage")
	w=fixture();var old=w.Stock.add(w,"wood",5,Vector2i(25,23));w.act("wood_wall",p);j=w.jobs[0]
	var replacement=w.Stock.add(w,"wood",5,Vector2i(26,23))
	w.Jobs.Reservations.transfer(w,replacement,j,"construction:keeper:%d"%j.id,5)
	check(old.claims.is_empty() and w.Stock.summary(w,"wood").reserved==5,"Replacement source releases old physical claim; never reserves twice the requirement")
func refill_cases():
	var w=fixture();w.zones.clear();w.Zones.sync_storage(w)
	var r=w.Stock.debug_replenish(w)
	check(w.field_items.is_empty() and r.wood.missing==40,"No storage: no spawn, full shortfall")
	check(log_contains(w,"備蓄がありません"),"No storage explanation in log")
	var id=w.Zones.create(w,"stockpile",Vector2i(25,23),Vector2i(25,23));w.Stock.add(w,"soil",39,Vector2i(25,23))
	r=w.Stock.debug_replenish(w)
	check(r.soil.added==1 and r.wood.added==0 and r.stone.added==0 and total(w,"soil")==40,"One space: partial refill one, never overflow or fallback")
	r=w.Stock.debug_replenish(w);check(r.soil.added==0 and total(w,"soil")==40,"Repeated refill on full storage adds nothing")
	w=fixture();w.Zones.filter_change(w,w.zones[0].id,"all","",false)
	r=w.Stock.debug_replenish(w);check(w.field_items.is_empty() and r.wood.added==0,"All-deny filter respected")
	w.Zones.filter_change(w,w.zones[0].id,"items","wood",true)
	r=w.Stock.debug_replenish(w);check(r.wood.added==40 and r.soil.added==0 and r.stone.added==0,"Individual item filter respected")
	w=fixture();var high=w.Zones.create(w,"stockpile",Vector2i(20,20),Vector2i(20,20));w.Zones.find(w,high).priority=2
	r=w.Stock.debug_replenish(w,["wood"])
	check(w.Stock.storage_used(w,Vector2i(20,20))==40,"High-priority storage wins before nearer ordinary storage")
	w=fixture();w.zones[0].cells=[Vector2i(25,23)];w.Zones.sync_storage(w)
	w.jobs.append({"id":500,"kind":"haul","pos":Vector2i(22,23),"storage_target":Vector2i(25,23),"storage_amount":20})
	r=w.Stock.debug_replenish(w,["wood"])
	check(r.wood.added==20 and w.Stock.storage_free(w,Vector2i(25,23))==0,"In-flight hauling capacity reservations are respected")
	w.debug_enabled=false;var count=w.field_items.size()
	check(w.Stock.debug_replenish(w).is_empty() and count==w.field_items.size(),"Normal gameplay cannot use debug refill")
func scale_cases():
	for n in [10,50,100]:
		var w=fixture();w.zones[0].cells.clear()
		for i in range(15):
			var p=Vector2i(20+i,20);w.zones[0].cells.append(p)
		w.Zones.sync_storage(w)
		for p in w.storage_cells:w.Stock.add(w,"wood",40,p)
		var s=Stroke.new();s.kind="wood_wall"
		for i in range(n):s.cells.append(Vector2i(10+i%20,10+i/20))
		var start=Time.get_ticks_usec();var preview=s.plan(w);var ms=(Time.get_ticks_usec()-start)/1000.0
		start=Time.get_ticks_usec();var result=s.commit(w);var commit=(Time.get_ticks_usec()-start)/1000.0
		check(preview.accepted==n and result.accepted==n,"Real material budget supports %d designations"%n)
		check(w.Stock.available(w,"wood")==600-5*n,"Physical reservations remain exact for %d jobs"%n)
		timings.append({"jobs":n,"preview_ms":ms,"commit_ms":commit})
		if n==100:check(not w.act("wood_wall",Vector2i(40,15)) and w.jobs.size()==100,"101st job refused despite sufficient material")
class Painter:
	extends RefCounted
	var world
	var TILE=Vector2(48,42)
	var calls=[]
	func center(c):return Vector2(c)*TILE+TILE*0.5
	func wall_links(c):
		var result={}
		for d in [Vector2i.UP,Vector2i.RIGHT,Vector2i.DOWN,Vector2i.LEFT]:result[d]=world.Buildings.enclosure(world.structures.get(c+d,{}))
		return result
	func color(c):return [c.r,c.g,c.b,c.a]
	func box(r):return [r.position.x,r.position.y,r.size.x,r.size.y]
	func draw_mesh(_mesh,texture,transform,tint):calls.append({"type":"mesh","path":texture.resource_path,"rect":[transform.origin.x,transform.origin.y,48,68],"color":color(tint)})
	func draw_texture(texture,pos,tint=Color.WHITE):calls.append({"type":"sprite","path":texture.resource_path,"rect":[pos.x,pos.y,texture.get_width(),texture.get_height()],"color":color(tint)})
	func draw_texture_rect(texture,r,_tile,tint=Color.WHITE):calls.append({"type":"sprite","path":texture.resource_path,"rect":box(r),"color":color(tint)})
	func draw_rect(r,c,_fill=true,_width=1.0):calls.append({"type":"rect","rect":box(r),"color":color(c)})
	func draw_arc(p,r,a,b,n,c,width):calls.append({"type":"arc","at":[p.x,p.y],"radius":r,"color":color(c),"width":width})
	func draw_line(a,b,c,width):calls.append({"type":"line","points":[[a.x,a.y],[b.x,b.y]],"color":color(c),"width":width})
func rendering():
	var w=fixture();var g=Painter.new();g.world=w;var ghost=Ghost.new();var p=Vector2i(1,1)
	for kind in ["wall","wood_wall","stone_wall","door","locked_door","soil_tile","wood_tile","stone_tile","cooking_bench","carpentry_bench","sewing_bench","place_wood_crate","place_wood_shelf","place_kokeshi","place_fossil"]:
		for valid in [true,false]:
			g.calls.clear();ghost.update(w);ghost.draw(g,kind,p,valid)
			var sprites=g.calls.filter(func(c):return c.type in ["sprite","mesh"])
			check(not sprites.is_empty() and sprites.all(func(c):return c.color[3]>=0.4 and c.color[3]<=0.5),"%s %s uses existing translucent art"%[kind,valid])
			check(g.calls.any(func(c):return c.type=="arc")==not valid,"%s %s prohibition mark correct"%[kind,valid])
			pictures.append({"name":kind+(" 可" if valid else " 不可"),"commands":g.calls.duplicate(true)})
	for kind in Art.FURNITURE_WORLD:
		g.calls.clear();Art.bench(g,g.center(p),kind)
		var completed=g.calls[0];g.calls.clear();ghost.update(w)
		ghost.draw(g,"place_"+kind if kind in ["wood_crate","wood_shelf"] else kind,p)
		check(completed.path==g.calls[0].path and completed.rect==g.calls[0].rect,"Official completed and ghost image/anchor identical: "+kind)
		check(completed.rect==[48.0,40.0,48,48],"Official48x48 with anchor(24,44) at center+(0,21): "+kind)
	# Production normal wall and ghost share exact mesh anchor and texture, every mask.
	for mask in range(16):
		w.structures.clear();var rows=[]
		for pair in [[Vector2i.UP,1],[Vector2i.RIGHT,2],[Vector2i.DOWN,4],[Vector2i.LEFT,8]]:
			if mask&pair[1]:w.structures[p+pair[0]]={"kind":"wall","status":"ready"}
		ghost.update(w);check(ghost.mask(w,"wood_wall",p)==mask,"All 16 wall connections including corners/cross %d"%mask)
		g.calls.clear();ghost.draw(g,"wood_wall",p)
		var ghost_call=g.calls[0]
		g.calls.clear();Art.wall(g,g.center(p),{"kind":"wood_wall","hp":16,"max_hp":16},false)
		check(g.calls[0].path==ghost_call.path and g.calls[0].rect==ghost_call.rect,"Completed wall and ghost texture/anchor identical %d"%mask)
	w.structures.clear();w.jobs=[{"id":1,"kind":"wood_wall","pos":p+Vector2i.RIGHT}]
	var rows=[{"pos":p+Vector2i.UP,"valid":true,"reason":""}];ghost.update(w,"wood_wall",rows)
	check(ghost.mask(w,"wood_wall",p)==3,"Planned and dragged neighbors both connect")
	var builds=ghost.rebuilds
	for i in range(120):ghost.update(w,"wood_wall",rows);ghost.mask(w,"wood_wall",p)
	check(ghost.rebuilds==builds,"Unchanged adjacency not rebuilt across 120 frames")
	w.jobs=[];ghost.update(w,"wood_tile",[{"pos":p+Vector2i.RIGHT,"valid":true,"reason":""}])
	check(ghost.mask(w,"wood_tile",p)==13,"Floor preview hides common internal edge")
func ui():
	var boot=load("res://game/loading.tscn").instantiate();boot.review_mode=true;root.add_child(boot)
	var deadline=Time.get_ticks_msec()+25000
	while not boot.finished and boot.failure=="" and Time.get_ticks_msec()<deadline:await process_frame
	check(boot.finished,"Production UI initializes without opening a game window")
	if not boot.finished:return
	var g=boot.game;g.set_process(false);g.world=fixture();g.world.paused=true;g.story_modal="";g.field_shop=false;g.field_book=false;g.neutral();g.group=0;g.architect_category="壁と扉";g.refresh()
	check("予約はできません" in g.buttons.wood_wall.tooltip_text or "新しい予約はできません" in g.buttons.wood_wall.tooltip_text,"Architect tooltip explains shortage rejection")
	g.debug_view=true;g.refresh()
	check(g.buttons.has("debug_replenish") and not g.buttons.has("debug_infinite"),"Debug UI contains refill instead of infinite toggle")
	check(g.buttons.debug_replenish.text=="資材補充（各40）","Debug button has requested label")
	g.buttons.debug_replenish.pressed.emit()
	check(total(g.world,"wood")==40,"Actual UI button creates physical resources")
	g.debug_view=false;g.group=0;g.tool="wood_wall";g.refresh()
	var p=Vector2i(35,26);g.pointer=g.get_canvas_transform()*g.center(p)
	var event=InputEventMouseButton.new();event.position=g.pointer;event.button_index=MOUSE_BUTTON_LEFT;event.pressed=true
	g._unhandled_input(event)
	check(g.wall_stroke.kind=="wood_wall","World mouse press arms construction ghost gesture")
	event.pressed=false;g._route_input(event)
	check(g.world.jobs.size()==1 and g.world.jobs[0].kind=="wood_wall","World release commits through shared budget validation")
	var j=g.world.jobs[0];g.neutral();g.board_click(event)
	check(g.selected.get("kind")=="job" and g.selected.get("id")==j.id,"Confirmed ghost remains selectable as original construction site")
	check(g.selected_construction().required==5 and g.selected_construction().delivered==0,"Existing site panel distinguishes reservation from delivery")
	boot.queue_free();await process_frame
func run():
	var out=OS.get_environment("FARM_REVIEW_OUTPUT")
	if DisplayServer.get_name()!="headless" or out=="":quit(2);return
	logic();interruptions();refill_cases();scale_cases();rendering();await ui()
	var failures=checks.filter(func(c):return not c.passed).size()
	FileAccess.open(out+"/building-preview.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"timings":timings},"\t"))
	FileAccess.open(out+"/ghost-commands.json",FileAccess.WRITE).store_string(JSON.stringify({"pictures":pictures},"\t"))
	print("BuildingPreview: ",checks.size()," checks, ",failures," failures");quit(1 if failures else 0)
