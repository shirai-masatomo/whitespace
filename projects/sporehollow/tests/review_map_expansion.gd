extends "res://tests/review_ui_survey.gd"
var perf=[]
func view(cell: Vector2i,zoom=1.0):
	g.camera.position=g.center(cell);g.camera.zoom=Vector2.ONE*zoom;g.clamp_camera();g.queue_redraw();g.hud.queue_redraw();await process_frame
func mouse(point: Vector2,button=MOUSE_BUTTON_LEFT,ctrl=false):
	var motion=InputEventMouseMotion.new();motion.position=point;root.push_input(motion);await process_frame
	for down in [true,false]:
		var e=InputEventMouseButton.new();e.position=point;e.button_index=button;e.pressed=down;e.ctrl_pressed=ctrl;root.push_input(e);await process_frame
func key(code,down):
	var e=InputEventKey.new();e.keycode=code;e.physical_keycode=code;e.pressed=down;root.push_input(e)
func measure(label_name,keys:Array,zoom=1.0,drag=false):
	g.neutral();await view(Vector2i(45,30),zoom);g.world.paused=false;g.automated=false;g.set_process(true)
	for i in range(12):await process_frame
	var samples=[];var times=[];var processing=[];var positions=[];var t=Time.get_ticks_usec();var initial=g.camera.position
	for code in keys:key(code,true)
	if drag:
		var e=InputEventMouseButton.new();e.position=Vector2(980,450);e.button_index=MOUSE_BUTTON_LEFT;e.pressed=true;root.push_input(e)
	for i in range(90):
		if drag:
			var motion=InputEventMouseMotion.new();motion.position=Vector2(980-i*6,450);motion.relative=Vector2(-6,0);motion.button_mask=MOUSE_BUTTON_MASK_LEFT;root.push_input(motion)
		await process_frame
		samples.append(g.draw_profile.duplicate())
		var now=Time.get_ticks_usec();times.append((now-t)/1000.0);t=now;processing.append(Performance.get_monitor(Performance.TIME_PROCESS)*1000);positions.append([g.camera.position.x,g.camera.position.y])
	for code in keys:key(code,false)
	if drag:
		var e=InputEventMouseButton.new();e.position=Vector2(446,450);e.button_index=MOUSE_BUTTON_LEFT;e.pressed=false;root.push_input(e)
	g.automated=true;g.set_process(false);g.world.paused=true
	var sorted=times.duplicate();sorted.sort();var sum=0.0
	for value in times:sum+=value
	perf.append({"mode":label_name,"zoom":zoom,"frames":times,"positions":positions,"mean_ms":sum/times.size(),"p95_ms":sorted[int(sorted.size()*0.95)],"max_ms":sorted[-1],"draw_profile":samples,"engine_process_ms":processing,"distance":g.camera.position.distance_to(initial),"method":"Unpaused production _process + world ticks; real Godot input events; 30 FPS GPU cap, no OS input. Screenshot writes excluded."})
	check(g.camera.position.distance_to(initial)>20,"Camera actually moved: "+label_name)
func motion_frames():
	g.neutral();await view(Vector2i(45,30));g.set_process(true);g.automated=false;g.world.paused=false;key(KEY_D,true)
	for i in range(12):
		await process_frame;await RenderingServer.frame_post_draw;root.get_texture().get_image().save_png(out+"/motion_%02d.png"%i)
	key(KEY_D,false);g.automated=true;g.set_process(false);g.world.paused=true
func run():
	out=OS.get_environment("FARM_REVIEW_OUTPUT")
	if out=="" or "--isolated-review" not in OS.get_cmdline_user_args():quit(2);return
	root.size=Vector2i(1280,800);root.content_scale_size=Vector2i(1280,800)
	if OS.get_environment("FARM_MAP_PERF_ONLY")=="1":
		var sample=Farm.new({},31).begin_day();sample.story.intro_seen=true;sample.paused=true;await scene(sample)
		await measure("overview pan",[KEY_D],0.224)
		FileAccess.open(out+"/camera-performance.json",FileAccess.WRITE).store_string(JSON.stringify({"series":perf},"  "));quit(0);return
	var campaign={}
	for seed_number in [31,73,109]:
		var w=Farm.new({},seed_number).begin_day();w.story.intro_seen=true;w.paused=true
		await scene(w);await view(Vector2i(50,34),0.224);await shot("seed_%d_overview"%seed_number,"100×68 全景 / seed%d"%seed_number)
		await view(Vector2i(50,34));await shot("seed_%d_center"%seed_number,"拠点と開けた草地 / seed%d"%seed_number)
		for kind in ["woodland","rocky"]:
			var sites=[]
			for y in range(6,w.H-6):
				for x in range(8,w.W-8):
					var p=Vector2i(x,y)
					if w.Biome.kind(w,p)==kind:sites.append(p)
			var index=1 if kind=="woodland" else 2
			sites.sort_custom(func(a,b):return w.Biome.field(w,a)[index]>w.Biome.field(w,b)[index])
			await view(sites[0]);await shot("seed_%d_%s"%[seed_number,kind],"通常倍率 / "+kind+" / seed"+str(seed_number))
		if seed_number==31:w.persist_farm();campaign=w.campaign.duplicate(true)
	campaign.night_ready=false
	var w=Farm.new(campaign.duplicate(true),31).begin_day();w.story.intro_seen=true;w.paused=true;await scene(w)
	var edges=[Vector2i(0,0),Vector2i(99,0),Vector2i(0,67),Vector2i(99,67),Vector2i(50,0),Vector2i(50,67),Vector2i(0,34),Vector2i(99,34)]
	for i in range(edges.size()):
		await view(edges[i]);var point=g.get_canvas_transform()*g.center(edges[i]);check(Rect2(0,49,1280,703).has_point(point),"Boundary cell remains visible: "+str(edges[i]));await shot("edge_%d"%i,"外周・四隅 "+str(edges[i]))
	await measure("WASD horizontal",[KEY_D]);await measure("WASD diagonal",[KEY_D,KEY_S]);await measure("mouse drag",[],1.0,true);await measure("overview pan",[KEY_D],0.224);await motion_frames()
	FileAccess.open(out+"/camera-performance.json",FileAccess.WRITE).store_string(JSON.stringify({"series":perf},"  "))
	g.neutral();await view(Vector2i(50,34));var origin=g.camera.position
	g.keys_down={KEY_D:true};g._process(0.1);var straight=g.camera.position.distance_to(origin);g.camera.position=origin;g.keys_down={KEY_D:true,KEY_S:true};g._process(0.1);check(absf(g.camera.position.distance_to(origin)-straight)<0.01,"Diagonal and straight camera speed are equal");g.keys_down.clear()
	g.select_group(4);var count=w.jobs.size()
	for expected in ["haul","forbid","allow","clear","mine","clear_tree"]:
		await mouse(Vector2(760,470),MOUSE_BUTTON_WHEEL_DOWN);check(g.tool==expected and w.jobs.size()==count,"Wheel selects without jobs: "+expected)
	await mouse(Vector2(760,470),MOUSE_BUTTON_WHEEL_UP);check(g.tool=="mine","Reverse wheel")
	var before=g.camera.zoom.x;await mouse(Vector2(760,470),MOUSE_BUTTON_WHEEL_UP,true);check(g.camera.zoom.x>before and g.tool=="mine","Control wheel zoom only")
	await shot("commands","命令6種類・一行・採掘選択")
	await mouse(g.buttons.command_mine.get_global_rect().get_center(),MOUSE_BUTTON_RIGHT);check(g.group==-1 and w.jobs.size()==count,"Right click over command returns neutral, preserves jobs")
	check(not g.queue_controls.visible,"Job queue hidden")
	var r=w.mountains.values().filter(func(a):return a.kind=="large")[0];await view(r.pos+Vector2i(1,1));await mouse(g.get_canvas_transform()*g.center(r.pos+Vector2i(3,3)));check(g.selected.get("id")==r.id,"Click anywhere in large footprint selects same mountain ID");await shot("mountain_selected","4×4岩山を一体選択")
	w.Tasks.designate(w,"mine",r.pos+Vector2i(3,2));w.Tasks.designate(w,"mine",r.pos);check(w.jobs.filter(func(j):return j.get("mountain_id")==r.id).size()==1,"One designation per mountain ID");g.refresh();await shot("mountain_planned","岩山全体の採掘指定")
	w.keeper.pos=w.Mountains.goals(w,r)[0];w.paused=false
	for i in range(160):
		w.step()
		if r.stage>0:break
	w.paused=true;g.refresh();check(r.stage==1,"Actual mining job shrinks footprint one stage");await shot("mountain_shrunk","採掘後の縮小・現地石材")
	campaign.animals.append({"id":2,"name":"こっこ","species":"hen","category":"bird","lv":1,"xp":0,"loyalty":0,"position":[46,36]});campaign.animals.append({"id":3,"name":"みけ","species":"cat","category":"cat","lv":1,"xp":0,"loyalty":0,"position":[48,36]})
	w=Farm.new(campaign.duplicate(true),31).begin_day();w.story.intro_seen=true;w.paused=true;await scene(w);await view(Vector2i(48,35))
	for id in [1,2,3]:
		g.neutral();var a=w.Orders.animal(w,id);await mouse(g.get_canvas_transform()*g.center(a.pos));check(g.selected.get("id")==id and not g.animal_commands_open and g.colony_panel==null,"Direct animal selection only own status: "+a.species);await shot("animal_"+a.species,"個体情報 / "+a.species)
		await mouse(g.buttons.animal_instructions.get_global_rect().get_center());check(g.animal_commands_open,"Shared instructions open: "+a.species);await shot("instructions_"+a.species,"個体指示 / "+a.species)
	g.select_group(1);await shot("animals_three","小型動物一覧・3匹")
	for id in range(4,10):campaign.animals.append({"id":id,"name":"こっこ%d"%id,"species":"hen","category":"bird","lv":1,"xp":0,"loyalty":0,"position":[43+id%3,38+id/3]})
	w=Farm.new(campaign.duplicate(true),31).begin_day();w.story.intro_seen=true;w.paused=true;await scene(w);g.select_group(1);await shot("animals_nine","小型動物一覧・9匹")
	var scroll=g.colony_panel.find_child("AnimalScroll",true,false)
	for i in range(5):await mouse(scroll.get_global_rect().get_center(),MOUSE_BUTTON_WHEEL_DOWN)
	check(scroll.scroll_vertical>0 and g.group==1,"List consumes scroll without changing commands")
	g.neutral();await view(Vector2i(50,36));w.Zones.create(w,"stockpile",Vector2i(52,34),Vector2i(55,36));w.Zones.create(w,"residential",Vector2i(52,38),Vector2i(55,40));w.Stock.add(w,"wood",8,Vector2i(46,37));w.Stock.add(w,"stone",12,Vector2i(46,37));w.Stock.add(w,"egg",2,Vector2i(46,37));await mouse(g.get_canvas_transform()*g.center(Vector2i(46,37)))
	var stock_lines=g.selected_stock_details();check("卵 ×2" in stock_lines and "木材 ×8" in stock_lines and "石 ×12" in stock_lines,"Selection retains every item kind and count without hover")
	var off=InputEventMouseMotion.new();off.position=Vector2(1050,170);root.push_input(off);await process_frame;await shot("zones_items","連続ゾーンと物資の名称・数量（ホバーなし）")
	g.neutral();w.structures.clear();w.floors.clear();w.natural.clear();w.field_items.clear();w.zones.clear();w.Zones.sync_storage(w);w.animals.clear();w.keeper.pos=Vector2i(40,32);w.story.idol.position=[30,30]
	for mask in range(16):
		var p=Vector2i(43+(mask%4)*4,27+(mask/4)*4);var cells=[p]
		for pair in [[1,Vector2i.UP],[2,Vector2i.RIGHT],[4,Vector2i.DOWN],[8,Vector2i.LEFT]]:
			if mask&pair[0]:cells.append(p+pair[1])
		for c in cells:
			var kind=["wall","wood_wall","stone_wall"][(mask+absi(c.x-p.x)+2*absi(c.y-p.y))%3]
			if c==p+Vector2i.RIGHT and mask%2==1:kind="door"
			var spec=w.BUILD[kind];w.structures[c]={"id":c.x+c.y*100,"kind":kind,"status":"ready","hp":spec.hp,"max_hp":spec.hp,"open":false,"armor":spec.get("armor",0)}
		check(g.BuildingArt.wall_mask(g,p)==mask,"Rendered connection mask "+str(mask))
	await view(Vector2i(49,34),0.86);await shot("walls_closed","土・木・石の16接続と閉ドア","16種類の完成壁を設置した描画fixture")
	for b in w.structures.values():
		if b.kind=="door":b.open=true
	await shot("walls_open","開ドアと接続")
	w.spawn_enemy({"role":"destroyer","entry":w.entries[0],"debug_single":true});var attacker=w.enemies.back();attacker.pos=Vector2i(46,27);attacker.object_attack_power=999
	w.move_enemy(attacker,Vector2i(47,27));check(w.structures[Vector2i(47,27)].status=="destroyed" and g.BuildingArt.wall_mask(g,Vector2i(47,26))==0,"Enemy destroys wall and adjoining rendered connection updates");await shot("walls_removed","1マス破壊後の再接続")
	FileAccess.open(out+"/ui-survey.json",FileAccess.WRITE).store_string(JSON.stringify({"source_commit":OS.get_environment("FARM_REVIEW_COMMIT"),"shots":shots,"checks":checks},"  "))
	var ok=checks.all(func(c):return c.passed);g.queue_free();await process_frame;quit(0 if ok else 1)
