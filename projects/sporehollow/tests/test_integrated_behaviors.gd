extends "res://tests/test_integrated_revision.gd"
const Art=preload("res://game/adopted_art.gd")
const Book=preload("res://game/book_view.gd")
var frames=[]
class Paint:
	var commands=[]
	var texture_filter=0
	func draw_set_transform(p,angle=0,scale=Vector2.ONE):commands.append(["transform",p,angle,scale])
	func draw_texture(t,p,c=Color.WHITE):commands.append(["texture",t.resource_path,p,c])
	func draw_polygon(p,c,uv,t):commands.append(["polygon",p,c,uv,t.resource_path])
	func draw_colored_polygon(p,c):commands.append(["color",p,c])
class Page:
	func get_texture():return Book.OPEN
func forbidden(w):
	var p=Vector2i(45,34);w.natural[p]="weed"
	check(w.Jobs.enqueue(w,"collect",p,-1),"Harvest reservation accepted before prohibition")
	var job=w.jobs.back();var result=w.Stock.designate(w,"forbid",p,p)
	check(result.accepted==1 and job.state=="blocked" and w.Work.effort(w,w.keeper,job)==INF,"Forbidding natural harvest blocks existing job and excludes assignment")
	check(not w._execute_local("collect",p) and w.natural.has(p),"Forbidden weed cannot be harvested through direct execution")
	w.Stock.designate(w,"allow",p,p)
	check(w._execute_local("collect",p) and w.Stock.totals(w).get("fiber",0)==2,"Allow resumes one physical fiber yield without duplication")
	w.jobs.clear();w.work_claims.clear();w.keeper.work_job=-1
	w.Zones.create(w,"stockpile",p,p+Vector2i(2,0))
	var item=w.Stock.add(w,"wood_staff",1,p)
	w.Stock.designate(w,"forbid",p,p)
	check(w.Stock.available(w,"wood_staff")==0 and not w.HumanCombat.equip(w,"wood_staff"),"Forbidden physical equipment excluded from stock and equip")
	check(w.Stock.reserve(w,"wood_staff",1,"proof",w.keeper).is_empty(),"Forbidden stock cannot be reserved for materials")
	w.Stock.designate(w,"allow",p,p)
	var worker=w.keeper.duplicate(true);worker.pos=Vector2i(44,34);worker.name="住人";w.Work.register(w,"resident",worker)
	check(w.HumanCombat.equip(w,"wood_staff","resident"),"Resident can request physical equipment")
	job=w.jobs.back();check(w.Work.claim(w,"resident",job),"Equipment job claims the correct resident")
	for i in range(80):
		w.tick+=1;w.HumanCombat.execute(w,job,worker)
		if job not in w.jobs:break
	check(worker.get("equipment",{}).get("item_id")=="wood_staff" and w.Stock.totals(w).get("wood_staff",0)==1,"Resident equips one item with conserved physical total")
	check(w.HumanCombat.equip(w,"unequip","resident"),"Resident can request unequip")
	job=w.jobs.back();w.Work.claim(w,"resident",job);w.HumanCombat.execute(w,job,worker)
	check(worker.equipment.is_empty() and w.Stock.totals(w).get("wood_staff",0)==1 and w.field_items.any(func(r):return r.kind=="wood_staff" and r.pos==worker.pos),"Unequip returns one physical item at resident without loss")
	w.workers.erase("resident");w.jobs.clear();w.work_claims.clear();w.keeper.work_job=-1
	var animal=Farm.new({},71).begin_day().animals[0].duplicate(true);animal.pos=Vector2i(44,35);animal.placed=true;animal.loyalty=50;animal.last_training_day=-1;animal.unavailable_through_day=0
	w.animals=[animal]
	check(w.Tasks.designate(w,"train",animal.pos,animal.id),"Training can be designated")
	job=w.Tasks.job(w,"train",animal.pos,animal.id)
	w.Stock.designate(w,"forbid",animal.pos,animal.pos)
	check(animal.forbidden and job.get("state")=="blocked" and w.Tasks.training_reason(w,animal,job.get("id",-1)).contains("禁止"),"Area forbid blocks animal training immediately")
	w.Stock.designate(w,"allow",animal.pos,animal.pos)
	check(not animal.forbidden and w.Tasks.training_reason(w,animal,job.get("id",-1))=="","Allow preserves existing animal job and permits resume")
func ai(w):
	w.keeper.placed=false
	for y in range(12,54):
		for x in range(25,30):w.rocks[Vector2i(x,y)]={"amount":8,"forbidden":false}
	w.refresh_indoor()
	for kind in ["salaryman","ninja","runner","kidnapper","destroyer","martial_artist"]:
		w.enemies.clear();w.spawn_enemy({"role":kind,"archetype":kind,"entry":Vector2i(1,34),"lv":1,"debug_single":true})
		var e=w.enemies.back();e.pos=Vector2i(20,34);e.arrival_complete=true;e.sight_range=2
		var crossed=false;var legal=true
		for i in range(500):
			w.tick+=1;var before=e.pos;w.enemy_step(e)
			if w.distance(before,e.pos)>1 or w.Story.terrain_block(w,e.pos):legal=false
			if e.pos.x>=30:crossed=true;break
		check(crossed and legal,kind+" actual AI marches around rock barrier without teleport")
	w.enemies.clear();w.rocks.clear();w.refresh_indoor()
	w.spawn_enemy({"role":"salaryman","archetype":"salaryman","entry":Vector2i(1,34),"lv":1,"debug_single":true})
	var e=w.enemies.back();e.pos=Vector2i(10,10);e.arrival_complete=true;e.sight_range=6
	w.Zones.create(w,"residential",Vector2i(12,10),Vector2i(13,10))
	check(w.RaidNavigation.objective(w,e)==Vector2i(12,10) and e.raid_reason=="住居へ侵入","Residential tendency uses visible zone")
	e.pos=Vector2i(12,10);w.tick+=1
	check(w.RaidNavigation.objective(w,e)!=e.pos,"Reached zone goal yields onward march, not short oscillation")
	w.zones.clear();w.Zones.sync_storage(w);e.raid_goal_until=0;e.archetype="thief";e.pos=Vector2i(10,10)
	w.Zones.create(w,"stockpile",Vector2i(12,10),Vector2i(13,10))
	check(w.RaidNavigation.objective(w,e)==Vector2i(12,10) and e.raid_reason=="備蓄を襲う","Looting tendency uses visible storage")
	var worker=w.keeper.duplicate(true);worker.placed=true;worker.pos=Vector2i(11,10);worker.name="住人";w.Work.register(w,"resident",worker)
	e.archetype="salaryman";e.can_see_keeper=false
	check(w.Progression.target_candidates(w,e).any(func(t):return t.kind=="worker" and t.id=="resident"),"Visible non-keeper residents are attack candidates")
	w.rocks[Vector2i(11,10)]={"amount":8};w.refresh_indoor();worker.pos=Vector2i(12,10)
	check(not w.Progression.target_candidates(w,e).any(func(t):return t.kind=="worker"),"Resident behind rock is not revealed")
	w.rocks.clear();worker.placed=false;e.pos=Vector2i(2,2);e.raid_routes={}
	for q in w.neighbors(e.pos):w.rocks[q]={"amount":8}
	w.refresh_indoor();var destination=Vector2i(45,34)
	for i in range(12):w.RaidNavigation.route(w,e,destination,true,false)
	check(e.get("raid_route_queries",0)==1,"Unreachable route has bounded retry, not repeated per evaluation")
	var calls=e.raid_route_queries;w.rocks.erase(Vector2i(3,2));w.refresh_indoor()
	check(not w.RaidNavigation.route(w,e,destination,true,false).is_empty() and e.raid_route_queries==calls+1,"Terrain change invalidates failed-route cache")
func door_routes(w):
	w.keeper.placed=false;w.spawn_enemy({"role":"maid","archetype":"maid","entry":Vector2i(1,34),"lv":1,"debug_single":true})
	var e=w.enemies.back();e.pos=Vector2i(10,10);e.arrival_complete=true
	w.structures[Vector2i(11,10)]={"id":991,"kind":"locked_door","status":"ready","hp":30,"open":false,"lock_hp":10}
	w.refresh_indoor();var route=w.RaidNavigation.route(w,e,Vector2i(12,10),false,false)
	check(not route.is_empty() and Vector2i(11,10) not in route,"Non-breaker detours around locked door instead of stalling")
	var revision=w.navigation_revision;w.open_for_ally(Vector2i(11,10))
	check(w.navigation_revision>revision and w.RaidNavigation.passable(w,Vector2i(11,10),false),"Door state invalidates enemy route cache without room rescan")
func specials(w):
	w.keeper.placed=false
	for kind in ["maid","salaryman","dancer","martial_artist"]:
		w.spawn_enemy({"role":kind,"archetype":kind,"entry":Vector2i(1,34),"lv":1,"debug_single":true})
	var maid=w.enemies[0];var ally=w.enemies[1];var dancer=w.enemies[2];var fighter=w.enemies[3]
	for e in w.enemies:e.arrival_complete=true;e.arrival_cleared=true;e.pos=Vector2i(40+e.id,30)
	maid.pos=Vector2i(39,30);dancer.pos=Vector2i(80,30);fighter.pos=Vector2i(81,30);ally.pos=Vector2i(40,30);ally.stamina=20;var stamina=ally.stamina
	w.Content.enemy_step(w,maid)
	check(ally.stamina>stamina,"Maid still provides coffee to adjacent ally")
	w.keeper.placed=true;w.keeper.pos=maid.pos+Vector2i.UP;var hp=w.keeper.hp;maid.rage_until=0;maid.ultimate_gauge=0
	w.RaiderAI.perceive(maid,w);w.Progression.strike(w,maid,{"kind":"keeper","id":-1,"pos":w.keeper.pos})
	check(w.keeper.hp==hp,"Maid normal attack remains disabled")
	w.keeper.placed=false;dancer.pos=Vector2i(44,30);fighter.pos=Vector2i(45,30)
	w.Progression.enemy_hurt(w,fighter,999);dancer.ultimate_gauge=100;dancer.hp=17
	w.Content.enemy_step(w,dancer)
	check(not fighter.dead and fighter.revived_count==1 and fighter.hp==mini(fighter.max_hp,17),"Dancer resurrection retains corpse, once-only and HP rules")
	w.Progression.enemy_hurt(w,dancer,999)
	check(dancer.dead and dancer.revivable,"Dancer death remains a corpse; other dancers exclude its archetype")
	w.enemies.clear();w.field_items.clear();w.keeper.placed=false
	w.spawn_enemy({"role":"thief","archetype":"thief","entry":Vector2i(1,34),"lv":1,"debug_single":true})
	var thief=w.enemies.back();thief.pos=Vector2i(8,8);thief.arrival_complete=true
	var stolen=w.Stock.add(w,"wood",5,Vector2i(9,8));w.Content.enemy_step(w,thief)
	check(not thief.get("stolen",{}).is_empty() and w.Stock.find(w,stolen.stock_id).is_empty(),"Thief still steals physical goods before retreat")
	var before=thief.pos
	for i in range(12):w.tick+=1;w.Content.enemy_step(w,thief)
	check(thief.pos!=before and not thief.stolen.is_empty(),"Carrying thief retreats instead of joining central rally")
func visuals():
	for who in ["shiba","keeper","cat","hen"]:
		for facing in [-1,1]:
			for action in ["idle","walk","run","rest","attack","hurt","settle","wake"]:
				for i in range(4):
					var row=Art.frame(who,action,facing,Vector2(128,144),i*0.1,2.4)
					check(not row.is_empty() and row.rect.size==row.texture.get_size()*2.4 and row.rect.position==(Vector2(128,144)-row.anchor*2.4).round(),"Shared scale/foot %s %s %d frame%d"%[who,action,facing,i])
					if who=="shiba":frames.append({"action":action,"facing":facing,"index":i,"path":row.texture.resource_path,"rect":[row.rect.position.x,row.rect.position.y,row.rect.size.x,row.rect.size.y]})
	var book=Book.new();book.game={"book_motion":"opening","clock":0.0,"book_started":0.0};book.cover_bounds=Rect2(Art.CLOSED.get_image().get_used_rect());book.pages=[Page.new(),Page.new()]
	var first=Paint.new();book.draw(first);book.game.clock=0.39;var held=Paint.new();book.draw(held)
	check(first.commands==held.commands,"Cover remains completely still for first 0.4 seconds")
	book.game.clock=0.94;var ending=Paint.new();book.draw(ending);book.game.book_motion="";var opened=Paint.new();book.draw(opened)
	check(ending.commands==opened.commands,"Opening final frame equals open book origin, size and page commands")
	book.game.book_motion="closing";book.game.book_started=0.94;var closing=Paint.new();book.draw(closing)
	check(closing.commands==opened.commands,"Closing starts at identical open-book geometry")
	book.free()
func run():
	var out=OS.get_environment("FARM_REVIEW_OUTPUT")
	if DisplayServer.get_name()!="headless" or out=="":quit(2);return
	forbidden(fixture());ai(fixture());door_routes(fixture());specials(fixture());visuals()
	var failures=checks.filter(func(r):return not r.passed).size()
	FileAccess.open(out+"/integrated-behaviors.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"frames":frames,"failures":failures},"  "))
	print("INTEGRATED_BEHAVIORS ",checks.size()," checks / ",failures," failures");quit(1 if failures else 0)
