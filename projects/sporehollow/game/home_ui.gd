extends RefCounted
const Panels=preload("res://game/colony_panels.gd")
class Hours:
	extends Control
	var game
	var actor
	var painting=false
	var last=-1
	var status_tick=-1
	const COLORS={"sleep":Color("7d96b7"),"work":Color("91a28a"),"free":Color("b6aa82")}
	func _ready():mouse_filter=Control.MOUSE_FILTER_STOP;set_process(true)
	func _process(_dt):
		if painting and not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):painting=false
		if status_tick!=game.world.tick:
			status_tick=game.world.tick
			var status=get_parent().get_node_or_null("SleepStatus")
			var wake_button=get_parent().get_node_or_null("Wake")
			if wake_button!=null:wake_button.disabled=not actor.get("resting",false)
			if status!=null:status.text="眠気 %d · %s"%[actor.sleepiness,actor.get("work_status",actor.get("state","待機")).left(24)]
		queue_redraw()
	func _gui_input(event):
		if event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT:
			painting=event.pressed;last=-1
			if painting:paint(event.position.x)
			accept_event()
		elif event is InputEventMouseMotion and painting:paint(event.position.x);accept_event()
	func paint(x):
		var h=clampi(int(x/24),0,23)
		if last<0:last=h
		for i in range(mini(last,h),maxi(last,h)+1):game.world.Sleep.edit(game.world,actor,i,game.schedule_brush)
		last=h;queue_redraw()
	func _draw():
		var table=actor.get("pending_timetable",actor.timetable)
		for h in range(24):
			draw_rect(Rect2(h*24,0,23,28),COLORS[table[h]])
			draw_string(game.FONT,Vector2(h*24+4,18),str(h),HORIZONTAL_ALIGNMENT_LEFT,-1,11,Color("162c25"))
			if h==game.world.Sleep.hour(game.world):draw_rect(Rect2(h*24,0,23,28),Color("fff6cb"),false,2)
static func open_schedule(g):
	g.neutral();g.colony_page="schedule";g.refresh()
static func brush(g,kind:String):g.schedule_brush=kind;g.refresh()
static func schedule(g):
	var height=mini(310,108+g.world.Sleep.people(g.world).size()*62)
	var p=Panels.panel(g,Rect2(16,742-height,796,height));p.name="Timetable"
	Panels.label(p,"時間割　"+g.world.Cycle.label(g.world),Vector2(12,8),18)
	for i in range(3):
		var kind=["sleep","work","free"][i]
		g.add_button(p,"schedule_"+kind,g.world.Sleep.LABELS[kind],Rect2(394+i*92,8,86,28),brush.bind(g,kind));g.UI.selected(g.buttons["schedule_"+kind],g.schedule_brush==kind)
	Panels.label(p,"0〜23時をドラッグで指定。変更は次の時間帯から適用。枠は現在時刻。",Vector2(12,43),13)
	var scroll=ScrollContainer.new();scroll.position=Vector2(10,70);scroll.size=Vector2(776,height-80);scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;scroll.vertical_scroll_mode=ScrollContainer.SCROLL_MODE_SHOW_ALWAYS;p.add_child(scroll);Panels.readable_scroll(scroll)
	var body=VBoxContainer.new();body.custom_minimum_size.x=750;scroll.add_child(body)
	for key in g.world.Sleep.people(g.world):
		var a=g.world.Sleep.people(g.world)[key];g.world.Sleep.initialize(a)
		var row=Control.new();row.custom_minimum_size=Vector2(750,58);body.add_child(row)
		Panels.label(row,a.get("name","牧場主")+" · "+{"early":"朝型","normal":"通常型","late":"夜型"}.get(a.life_type,"通常型"),Vector2(0,0),13)
		Panels.label(row,{"short":"ショートスリーパー","normal":"通常","long":"ロングスリーパー"}.get(a.sleep_trait,"通常"),Vector2(0,25),11)
		Panels.label(row,"眠気 %d · %s"%[a.sleepiness,a.get("work_status","待機").left(24)],Vector2(168,31),12)
		row.get_child(row.get_child_count()-1).name="SleepStatus"
		var wake_button=Button.new();wake_button.name="Wake";wake_button.text="起こす";wake_button.position=Vector2(664,30);wake_button.size=Vector2(80,26);wake_button.disabled=not a.get("resting",false);Panels.compact_button(g,wake_button);wake_button.pressed.connect(wake.bind(g,key));row.add_child(wake_button)
		var hours=Hours.new();hours.game=g;hours.actor=a;hours.position=Vector2(168,0);hours.size=Vector2(576,28);row.add_child(hours)
static func assign(g,id:int,key:String):
	g.world.Homes.assign(g.world,id,key);g.refresh()
static func unassign(g,key:String):
	var a=g.world.Sleep.people(g.world)[key];a.erase("home_id");a.erase("bed_id");a.home_manual_optout=true;g.refresh()
static func close(g):g.neutral();g.refresh()
static func wake(g,key:String):
	var a=g.world.Sleep.people(g.world).get(key,{})
	if a.get("resting",false):g.world.Sleep.wake(g.world,a,true);g.refresh()
static func house(g):
	var h=g.world.homes.get(g.selected.get("id",-1),{})
	if h.is_empty():
		var missing=Panels.panel(g,Rect2(16,622,396,120))
		Panels.label(missing,"家屋が成立していません",Vector2(12,12),18)
		Panels.label(missing,"壁・ドア・床の完成状態を確認してください",Vector2(12,43),13)
		g.add_button(missing,"house_close","閉じる",Rect2(276,78,108,28),close.bind(g));return
	var residents=g.world.Homes.residents(g.world,h.id)
	var p=Panels.panel(g,Rect2(16,422,396,320));p.name="HouseStatus"
	Panels.label(p,g.world.Homes.title(g.world,h),Vector2(12,10),20)
	Panels.label(p,"%dマス · ベッド%d / 空き%d · %s"%[h.cells.size(),h.beds.size(),maxi(0,h.beds.size()-residents.size()),"損傷あり" if g.world.Homes.damaged(g.world,h) else "正常"],Vector2(12,42),14)
	Panels.label(p,"居住者："+("なし" if residents.is_empty() else "・".join(residents.map(func(a):return a.get("name","牧場主")))) ,Vector2(12,68),14)
	Panels.label(p,"設備："+("なし" if h.fixtures.is_empty() else "・".join(h.fixtures).left(30)),Vector2(12,94),13)
	Panels.label(p,"ダブルクリックで内部を個別選択 / Escで終了",Vector2(12,120),12)
	var scroll=ScrollContainer.new();scroll.position=Vector2(12,150);scroll.size=Vector2(372,120);scroll.vertical_scroll_mode=ScrollContainer.SCROLL_MODE_SHOW_ALWAYS;p.add_child(scroll);Panels.readable_scroll(scroll)
	var list=VBoxContainer.new();scroll.add_child(list)
	for key in g.world.Sleep.people(g.world):
		var a=g.world.Sleep.people(g.world)[key];var b=Button.new();b.custom_minimum_size=Vector2(344,30);b.text=a.get("name","牧場主")+("の割当を解除" if a.get("home_id",-1)==h.id else "を割当")
		b.disabled=a.get("home_id",-1)!=h.id and residents.size()>=h.beds.size();Panels.compact_button(g,b);b.pressed.connect(unassign.bind(g,key) if a.get("home_id",-1)==h.id else assign.bind(g,h.id,key));list.add_child(b)
	g.add_button(p,"house_close","閉じる",Rect2(276,280,108,28),close.bind(g))
static func build(g):
	if g.field_book or g.field_shop or not g.world.working():return
	if g.colony_page=="schedule":schedule(g);return
	if g.selected.get("kind")=="house":house(g);return
	if g.colony_page=="roles":g.add_button(g.colony_panel,"time_tab","時間割",Rect2(510,8,116,26),open_schedule.bind(g))
	elif g.selected.get("kind") in ["keeper","worker"]:
		g.add_button(g.palette,"time_tab","時間割",Rect2(386,698,108,36),open_schedule.bind(g))
		var key=g.selected.get("key","keeper")
		if key!="keeper" and g.world.workers.get(key,{}).get("resting",false):g.add_button(g.palette,"wake_worker","起こす",Rect2(502,698,108,36),wake.bind(g,key))
