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
			var current=get_parent().get_node_or_null("CurrentState")
			var wake_button=get_parent().get_node_or_null("Wake")
			if wake_button!=null:wake_button.disabled=not actor.get("resting",false)
			if status!=null:status.text="眠気：%d　｜　%s"%[actor.sleepiness,actor.get("work_status",actor.get("state","待機")).left(24)]
			if current!=null:current.text="睡眠中" if actor.get("resting",false) else "活動中"
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
			draw_rect(Rect2(h*24,0,23,38),COLORS[table[h]])
			draw_string(game.FONT,Vector2(h*24+4,24),str(h),HORIZONTAL_ALIGNMENT_LEFT,-1,11,Color("162c25"))
			if h==game.world.Sleep.hour(game.world):draw_rect(Rect2(h*24,0,23,38),Color("fff6cb"),false,2)
static func compact(g,id:String,height:float=34):
	Panels.compact_button(g,g.buttons[id],14,true);g.buttons[id].size.y=height
static func role_person(g,key:String):g.roles_actor=key;g.refresh()
static func summary(g,a)->String:
	g.world.Resident.initialize(a)
	return "生活タイプ：%s　食欲：%s　危険反応：%s\n満足度 %d/100　｜　%s"%[{"early":"朝型","normal":"通常","late":"夜型"}.get(a.life_type,"通常"),g.world.Resident.APPETITE_NAMES[a.appetite],g.world.Resident.REACTIONS[a.danger_state],a.satisfaction,a.get("mood_reasons",["普段の生活"])[0] if not a.get("mood_reasons",[]).is_empty() else "普段の生活"]
static func open_schedule(g,key:String=""):
	if key=="":
		key=g.roles_actor if g.colony_page=="roles" else g.selected.get("key","keeper")
		if g.selected.get("kind")=="animal" and g.world.Orders.animal(g.world,g.selected.get("id",-1)).get("category")=="human":key="a%d"%g.selected.id
	if g.colony_page in ["life","schedule"]:return
	g.life_return={"group":g.group,"page":g.colony_page,"selected":g.selected.duplicate(true),"animal_list":g.animal_list_open}
	g.neutral();g.colony_page="life";g.life_actor=key;g.refresh()
static func back(g):
	var old=g.life_return.duplicate(true);g.neutral();g.group=old.get("group",-1);g.colony_page=old.get("page","");g.selected=old.get("selected",{});g.animal_list_open=old.get("animal_list",false);g.refresh()
static func brush(g,kind:String):g.schedule_brush=kind;g.refresh()
static func tab(g,kind:String):g.life_tab=kind;g.refresh()
static func person(g,key:String):g.life_actor=key;g.refresh()
static func priority(g,a,combination:String,index:int):g.world.FoodPrefs.change(a,combination,index+1);g.refresh()
class LifeSummary:
	extends Label
	var game
	var actor
	var last_tick=-1
	func _process(_dt):
		if last_tick==game.world.tick:return
		last_tick=game.world.tick;text=game.HomeUI.summary(game,actor)
static func schedule(g):
	var people=g.world.Sleep.people(g.world)
	if not people.has(g.life_actor):g.life_actor="keeper"
	var a=people[g.life_actor];g.world.Sleep.initialize(a);g.world.FoodPrefs.initialize(a)
	var p=Panels.panel(g,Rect2(16,402,796,340));p.name="Timetable"
	Panels.label(p,"生活",Vector2(12,8),20)
	var picker=OptionButton.new();picker.name="LifeResident";picker.position=Vector2(82,8);picker.size=Vector2(250,30);p.add_child(picker);Panels.compact_button(g,picker)
	for key in people:picker.add_item(g.world.PlayerEvents.name_of(g.world,people[key]))
	picker.select(people.keys().find(g.life_actor));picker.item_selected.connect(func(i):person(g,people.keys()[i]))
	for i in range(2):
		var kind=["schedule","food"][i];g.add_button(p,"life_"+kind,["時間割","食事"][i],Rect2(348+i*110,8,104,30),tab.bind(g,kind));g.UI.architect_selected(g.buttons["life_"+kind],g.life_tab==kind);compact(g,"life_"+kind,30)
	g.add_button(p,"life_back","戻る",Rect2(676,8,108,30),back.bind(g));compact(g,"life_back",30)
	var info=LifeSummary.new();info.name="LifeSummary";info.game=g;info.actor=a;info.text=summary(g,a);info.position=Vector2(12,50);info.size=Vector2(760,44);info.add_theme_font_size_override("font_size",14);info.add_theme_color_override("font_color",g.UI.INK);info.tooltip_text=g.world.Resident.describe(a);p.add_child(info)
	var divider=HSeparator.new();divider.position=Vector2(12,98);divider.size=Vector2(772,2);p.add_child(divider)
	var scroll=ScrollContainer.new();scroll.name="LifeContent";scroll.position=Vector2(12,110);scroll.size=Vector2(772,218);scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;scroll.vertical_scroll_mode=ScrollContainer.SCROLL_MODE_SHOW_ALWAYS;p.add_child(scroll);Panels.readable_scroll(scroll)
	var body=Control.new();body.name="LifeBody";body.custom_minimum_size=Vector2(746,204);scroll.add_child(body)
	if g.life_tab=="schedule":
		Panels.label(body,"0〜23時をドラッグして設定。変更は次の時間帯から適用します。",Vector2(0,4),14)
		for i in range(3):
			var kind=["sleep","work","free"][i];g.add_button(body,"schedule_"+kind,g.world.Sleep.LABELS[kind],Rect2(i*110,44,104,34),brush.bind(g,kind));g.UI.architect_selected(g.buttons["schedule_"+kind],g.schedule_brush==kind);compact(g,"schedule_"+kind)
		var hours=Hours.new();hours.name="ScheduleHours";hours.game=g;hours.actor=a;hours.position=Vector2(0,96);hours.size=Vector2(576,38);body.add_child(hours)
		Panels.label(body,"眠気：%d　｜　%s"%[a.sleepiness,a.get("work_status",a.get("state","待機")).left(24)],Vector2(0,150),14);body.get_child(body.get_child_count()-1).name="SleepStatus"
		var border=VSeparator.new();border.position=Vector2(594,44);border.size=Vector2(2,100);body.add_child(border)
		Panels.label(body,"現在の状態",Vector2(614,44),14)
		Panels.label(body,"睡眠中" if a.get("resting",false) else "活動中",Vector2(614,70),16);body.get_child(body.get_child_count()-1).name="CurrentState"
		g.add_button(body,"life_wake","起こす",Rect2(614,100,118,34),wake.bind(g,g.life_actor));g.buttons.life_wake.name="Wake";g.buttons.life_wake.disabled=not a.get("resting",false)
		compact(g,"life_wake");g.buttons.life_wake.tooltip_text="選択中の住民を起こす"
	else:
		Panels.label(body,"1が最優先、数字が大きいほど優先度が下がります。\n同じ数字は同順位として扱われます。",Vector2(0,0),14)
		for tier in range(4):Panels.label(body,g.world.Zones.Catalog.FOOD_TIERS[tier],Vector2(194+tier*136,50),14)
		for row in range(2):
			var category=["cooked","raw"][row];Panels.label(body,["調理済み食品","生食材"][row],Vector2(0,82+row*46),14)
			for tier in range(4):
				var combination=category+":"+str(tier);var choice=OptionButton.new();choice.name="Food_"+category+str(tier);choice.position=Vector2(166+tier*136,76+row*46);choice.size=Vector2(116,34);body.add_child(choice);Panels.compact_button(g,choice,14)
				for rank_value in range(1,9):choice.add_item(str(rank_value))
				choice.select(g.world.FoodPrefs.value(a,combination)-1);choice.item_selected.connect(func(index):priority(g,a,combination,index))
		Panels.label(body,"利用権限・禁止・予約・通路を確認して選択。飼料は対象外。",Vector2(0,178),13)
static func assign(g,id:int,key:String):
	g.world.Homes.assign(g.world,id,key);g.refresh()
static func unassign(g,key:String):
	var a=g.world.Sleep.people(g.world)[key];a.erase("home_id");a.erase("bed_id");a.home_manual_optout=true;g.world.Access.changed(g.world);g.refresh()
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
	Panels.label(p,"居住者："+("なし" if residents.is_empty() else "・".join(residents.map(func(a):return g.world.PlayerEvents.name_of(g.world,a)))) ,Vector2(12,68),14)
	Panels.label(p,"設備："+("なし" if h.fixtures.is_empty() else "・".join(h.fixtures).left(30)),Vector2(12,94),13)
	Panels.label(p,"ダブルクリックで内部を個別選択 / Escで終了",Vector2(12,120),12)
	var scroll=ScrollContainer.new();scroll.position=Vector2(12,150);scroll.size=Vector2(372,120);scroll.vertical_scroll_mode=ScrollContainer.SCROLL_MODE_SHOW_ALWAYS;p.add_child(scroll);Panels.readable_scroll(scroll)
	var list=VBoxContainer.new();scroll.add_child(list)
	for key in g.world.Sleep.people(g.world):
		var a=g.world.Sleep.people(g.world)[key];var b=Button.new();b.custom_minimum_size=Vector2(344,30);b.text=g.world.PlayerEvents.name_of(g.world,a)+("の割当を解除" if a.get("home_id",-1)==h.id else "を割当")
		b.disabled=a.get("home_id",-1)!=h.id and residents.size()>=h.beds.size();Panels.compact_button(g,b);b.pressed.connect(unassign.bind(g,key) if a.get("home_id",-1)==h.id else assign.bind(g,h.id,key));list.add_child(b)
	g.add_button(p,"house_close","閉じる",Rect2(276,280,108,28),close.bind(g))
static func build(g):
	if g.field_book or g.field_shop or not g.world.working():return
	g.add_button(g.palette,"life_main","生活",Rect2(580,754,116,36),open_schedule.bind(g))
	if g.colony_page in ["schedule","life"]:schedule(g);return
	if g.selected.get("kind")=="house":house(g);return
	if g.colony_page=="roles":
		var people=g.world.Sleep.people(g.world)
		if not people.has(g.roles_actor):g.roles_actor="keeper"
		var picker=OptionButton.new();picker.name="RoleLifeResident";picker.position=Vector2(254,8);picker.size=Vector2(244,26);g.colony_panel.add_child(picker);Panels.compact_button(g,picker)
		for key in people:picker.add_item(g.world.PlayerEvents.name_of(g.world,people[key]))
		picker.select(people.keys().find(g.roles_actor));picker.item_selected.connect(func(i):role_person(g,people.keys()[i]));picker.tooltip_text="生活設定の対象住民"
		g.add_button(g.colony_panel,"time_tab","生活",Rect2(510,8,116,26),open_schedule.bind(g,g.roles_actor));compact(g,"time_tab",26)
	elif g.selected.get("kind") in ["keeper","worker"]:
		g.add_button(g.palette,"time_tab","生活",Rect2(386,698,108,36),open_schedule.bind(g,g.selected.get("key","keeper")))
		var key=g.selected.get("key","keeper")
		if key!="keeper" and g.world.workers.get(key,{}).get("resting",false):g.add_button(g.palette,"wake_worker","起こす",Rect2(502,698,108,36),wake.bind(g,key))

	elif g.selected.get("kind")=="animal":
		var a=g.world.Orders.animal(g.world,g.selected.get("id",-1))
		if a.get("category","")=="human":g.add_button(g.palette,"time_tab","生活",Rect2(386,698,108,36),open_schedule.bind(g,"a%d"%a.id))
