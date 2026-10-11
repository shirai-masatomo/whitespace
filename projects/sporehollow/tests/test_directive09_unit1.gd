extends SceneTree
const Farm=preload("res://game/world.gd")
const Snap=preload("res://game/research_snapshot.gd")
var out=""
var failed=0
var report={"method":"Controlled fixtures through production World.step; Godot mouse events on isolated GPU desktop. Simulation, not human play.","groups":[]}
var group={}
func _initialize():call_deferred("run")
func begin(title):group={"name":title,"checks":[]};report.groups.append(group)
func check(ok: bool,note: String):
	group.checks.append({"passed":ok,"check":note})
	if not ok:failed+=1;push_error(note)
func farm():
	var w=Farm.new({},31).begin_day();w.trees.clear();w.natural.clear();w.field_items.clear();w.day_seconds=9999;w.nature_config.spawn_chance_per_second=0;w.storage_cells=[];w.stock_used={}
	w.keeper.pos=Vector2i(4,6);w.keeper_path=[[4,6]];w.keeper.satiety=100;w.story.intro_seen=true
	w.animals[0].pos=Vector2i(20,13);w.animals[0].mode="stay";w.Stock.sync(w);return w
func run():
	out=OS.get_environment("FARM_REVIEW_OUTPUT")
	if out=="" or not "--isolated-review" in OS.get_cmdline_user_args():quit(2);return
	begin("1 Eggs stay goods; hen laying and food/trade retained")
	var w=farm();var egg=w.Stock.add(w,"egg",2,Vector2i(6,6));egg.born_day=-20;egg.incubating=true
	var chick=w.Stock.add(w,"chick",1,Vector2i(7,6));chick.born_day=-20
	var hens=w.animals.filter(func(a):return a.species=="hen").size();w.process_dawn();w.Stock.normalize(w)
	check(egg.kind=="egg" and chick.kind=="chick" and w.animals.filter(func(a):return a.species=="hen").size()==hens,"Old eggs/chicks never transform at dawn")
	check(w.dawn_summary.eggs==w.animals.filter(func(a):return a.species=="hen" and w.available(a)).size(),"Each available existing hen still lays one egg")
	w.keeper.satiety=20
	for i in range(80):
		w.step()
		if w.stock_used.get("egg",0)==1:break
	check(w.stock_used.get("egg",0)==1,"Egg remains usable human food")
	w.phase="shop";var before=w.Stock.totals(w).get("egg",0);check(w.sell("egg") and w.Stock.totals(w).get("egg",0)==before-1,"Egg remains sellable")
	check(not "孵化" in str(preload("res://game/onsite_clarity.gd").eggs(w,[egg],false)),"Egg UI contains no hatch promise")
	begin("2 Forbid interrupts reserved, carried and delivered building stock without loss")
	for stage in ["reserved","carry","site","started"]:
		w=farm();w.Stock.add(w,"wood",10,Vector2i(8,6));w.act("wood_wall",Vector2i(4,8));var j=w.jobs[0];var target={}
		for i in range(100):
			w.step()
			var rows=w.field_items.filter(func(r):return (not r.claims.is_empty() if stage=="reserved" else r.location==("site" if stage=="started" else stage) and (stage!="started" or j.started)))
			if not rows.is_empty():target=rows[0];break
		check(not target.is_empty(),stage+" fixture reached through production movement")
		if target.is_empty():continue
		var quantity=w.Stock.totals(w).wood;var pos=w.Stock.command_pos(w,target)
		w.Stock.designate(w,"forbid",pos,pos)
		check(target.forbidden and target.location==("site" if stage in ["site","started"] else "ground") and target.pos==pos and target.claims.is_empty() and j.assigned_to=="",stage+" forbid releases ownership at its actual location")
		for i in range(35):w.step()
		check(w.metrics.built==0 and w.Stock.totals(w).wood==quantity and w.stock_used.get("wood",0)==0,stage+" forbidden material cannot finish construction")
		w.Stock.designate(w,"allow",pos,pos)
		for i in range(150):
			w.step()
			if w.metrics.built==1:break
		check(w.metrics.built==1 and w.stock_used.get("wood",0)==10 and w.Stock.totals(w).get("wood",0)==0,stage+" allow resumes the same job and consumes exactly its cost")
	w=farm();w.Stock.add(w,"wood",10,Vector2i(8,6));w.act("wood_wall",Vector2i(4,8))
	for i in range(100):
		w.step()
		if w.Stock.delivered(w,w.jobs[0])>0:break
	w.Stock.designate(w,"forbid",Vector2i(4,8),Vector2i(4,8));w.Stock.add(w,"wood",10,Vector2i(6,7))
	for i in range(150):
		w.step()
		if w.metrics.built==1:break
	check(w.metrics.built==1 and w.stock_used.wood==10 and w.field_items.any(func(r):return r.get("forbidden",false) and r.amount==8 and r.pos==Vector2i(4,8)),"Alternative permitted stock finishes the wall while forbidden site stock remains unused at its location")
	begin("3 Forbid at meal/equip use and rectangle haul; persistence")
	w=farm();w.keeper.satiety=20;w.Stock.add(w,"mushroom",1,Vector2i(6,6))
	for i in range(60):
		w.step()
		if w.keeper.get("meal_remaining",99)==1:break
	check(w.keeper.get("meal_remaining",99)==1,"Meal is one tick from consumption")
	var pos=w.keeper.pos;w.Stock.designate(w,"forbid",pos,pos);w.step()
	check(w.stock_used.get("mushroom",0)==0 and w.Stock.totals(w).mushroom==1 and not w.keeper.has("meal_remaining"),"Last-tick forbidden meal stays intact on the ground")
	w.phase="shop";check(not w.sell("mushroom"),"Forbidden food cannot be sold");w.phase="day"
	w.keeper.satiety=100;var collar=w.Stock.add(w,"collar",1,Vector2i(7,6));w.animals[0].pos=Vector2i(12,6);w.Progression.equip_job(w,1,"collar")
	for i in range(80):
		w.step()
		if not w.Stock.cargo(w,"keeper").is_empty():break
	check(not w.Stock.cargo(w,"keeper").is_empty(),"Equipment reached the carried stage")
	pos=w.keeper.pos;w.Stock.designate(w,"forbid",pos,pos)
	for i in range(25):w.step()
	check(w.animals[0].equipment.is_empty() and w.Stock.totals(w).collar==1,"Forbidden carried equipment is dropped and never equipped")
	w=farm();var one=w.Stock.add(w,"wood",4,Vector2i(6,6));var two=w.Stock.add(w,"stone",3,Vector2i(7,7));var outside=w.Stock.add(w,"egg",1,Vector2i(9,6));two.forbidden=true
	var result=w.Stock.designate(w,"haul",Vector2i(5,5),Vector2i(7,7))
	check(result.accepted==1 and one.pos==Vector2i(6,6) and w.Stock.designate(w,"haul",Vector2i(7,7),Vector2i(5,5)).accepted==0,"Rectangle excludes forbidden/outside stock, deduplicates and never teleports")
	w.storage_cells=[Vector2i(10,8)]
	for i in range(130):w.step()
	check(w.Stock.storage_used(w,Vector2i(10,8))==4 and two.pos==Vector2i(7,7) and two.amount==3,"Physical hauling reaches storage; forbidden stock stays put")
	check(Snap.save(w,out+"/forbid.snapshot"),"Snapshot written")
	var restored=Snap.restore(out+"/forbid.snapshot")
	check(restored.Stock.find(restored,two.stock_id).forbidden and restored.Stock.totals(restored)==w.Stock.totals(w),"Snapshot preserves forbidden flags and all quantities")
	w.persist_farm();restored=Farm.new(w.campaign,31)
	check(restored.Stock.find(restored,two.stock_id).forbidden and restored.Stock.totals(restored)==w.Stock.totals(w),"Campaign serialization also preserves forbid/quantity")
	begin("4 Priorities: left category, then distance; blank off and legacy migration")
	w=farm();w.Stock.add(w,"soil",20,Vector2i(6,6));w.natural[Vector2i(5,6)]="mushroom";w.act("collect",Vector2i(5,6));w.act("wall",Vector2i(12,8));w.act("wall",Vector2i(8,8))
	for kind in w.Work.Policy.ORDER:w.Work.set_priority(w,"keeper",kind,2)
	var selected=w.Work.choose(w,"keeper")
	check(selected.kind=="wall" and selected.pos==Vector2i(8,8),"Same priority selects leftmost build category before closer gathering, then nearer wall")
	w.Work.set_priority(w,"keeper","build",0);selected=w.Work.choose(w,"keeper")
	check(selected.kind=="collect","Blank/off build excludes its jobs while other work remains")
	var legacy={"work_priorities":{"build":0,"gather":1,"collect":2,"other":3,"haul":3}}
	w.Work.migrate_priorities(legacy);var once=legacy.duplicate(true);w.Work.migrate_priorities(legacy)
	check(legacy==once and legacy.work_priorities=={"build":0,"gather":2,"collect":3,"animal":4,"other":4,"haul":4},"Legacy off/high/medium/low maps once to off/2/3/4 without repeated migration")
	w.keeper.work_priorities.build=1;w.persist_farm();restored=Farm.new(w.campaign,31)
	check(restored.keeper.work_priorities.build==1 and restored.keeper.work_priority_version==restored.Work.Policy.PRIORITY_VERSION,"New highest priority survives save/reload unchanged")
	if DisplayServer.get_name()!="headless":await visual()
	report.passed=failed==0;report.failures=failed
	FileAccess.open(out+"/directive09-unit1.json",FileAccess.WRITE).store_string(JSON.stringify(report,"\t"))
	print("Directive09 unit1: ",report.groups.size()," groups, ",failed," failures");quit(0 if failed==0 else 1)
func mouse(point: Vector2,down: bool):
	var e=InputEventMouseButton.new();e.position=point;e.button_index=MOUSE_BUTTON_LEFT;e.pressed=down;Input.parse_input_event(e);await process_frame
func move(point: Vector2):
	var e=InputEventMouseMotion.new();e.position=point;Input.parse_input_event(e);await process_frame
func click(point: Vector2):await move(point);await mouse(point,true);await mouse(point,false)
func visual():
	begin("5 Isolated UI input: drag preview, marks, allow/cancel and role display")
	root.size=Vector2i(1280,800)
	var g=load("res://game/main.tscn").instantiate();g.automated=true;g.world=farm();g.world.paused=true
	var row=g.world.Stock.add(g.world,"wood",8,Vector2i(10,7));g.world.Stock.add(g.world,"egg",2,Vector2i(11,8))
	root.add_child(g);await process_frame;await process_frame;g.set_process(false);g.audio.set_process(false);g.reset_view();g.neutral()
	await click(g.buttons.commands.get_global_rect().get_center());await click(g.buttons.command_forbid.get_global_rect().get_center())
	await move(g.screen_cell(Vector2i(9,6)));await mouse(g.screen_cell(Vector2i(9,6)),true);await move(g.screen_cell(Vector2i(11,8)))
	g.queue_redraw();await process_frame;await RenderingServer.frame_post_draw;root.get_texture().get_image().save_png(out+"/commands-preview.png")
	check(g.item_commands.pressed and not row.get("forbidden",false),"Mouse drag shows preview before applying")
	await mouse(g.screen_cell(Vector2i(11,8)),false)
	check(g.world.field_items.all(func(r):return r.get("forbidden",false)),"Mouse rectangle forbids both goods")
	g.queue_redraw();await process_frame;await RenderingServer.frame_post_draw;root.get_texture().get_image().save_png(out+"/commands-forbidden.png")
	await click(g.buttons.command_allow.get_global_rect().get_center());await click(g.screen_cell(Vector2i(10,7)))
	check(not row.forbidden and g.world.field_items[1].forbidden,"Single click allows only the selected cell")
	await click(g.buttons.command_haul.get_global_rect().get_center());await click(g.screen_cell(Vector2i(10,7)))
	check(g.world.jobs.size()==1 and row.pos==Vector2i(10,7),"UI collect creates one real pending haul")
	var e=InputEventKey.new();e.physical_keycode=KEY_ESCAPE;e.pressed=true;Input.parse_input_event(e);await process_frame
	check(g.tool=="","Escape cancels command mode")
	await click(g.buttons.roles.get_global_rect().get_center());g.queue_redraw();await process_frame;await RenderingServer.frame_post_draw
	var priority=g.colony_panel.find_child("Priority_keeper_build",true,false)
	check(priority!=null and "3" in priority.text,"Roles exposes the new numbered priority")
	root.get_texture().get_image().save_png(out+"/roles-priorities.png")
