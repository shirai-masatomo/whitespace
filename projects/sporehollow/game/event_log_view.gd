extends RefCounted
const UI=preload("res://game/ui_style.gd")
const Market=preload("res://game/market_view.gd")
## Six visible events; history is anchored to a row, not offset from new arrivals.
const PAGE=6
const BAR_WIDTH=18.0
var first=0
var following=true
var anchor={}
var rect=Rect2()
var track=Rect2()
var thumb=Rect2()
var dragging=false
var captured=false
var grab=0.0
var height=144.0
var owner_id=0
var styles=[]
var paragraph_key=[]
var paragraphs=[]
var paragraph_height=16.0
func sync(rows:Array):
	if rows.is_empty():first=0;following=true;anchor={};height=144.0;return
	if following:first=maxi(0,rows.size()-PAGE)
	elif not anchor.is_empty():
		var index=rows.find(anchor)
		first=maxi(0,index) # The oldest retained row replaces an evicted anchor.
	first=clampi(first,0,maxi(0,rows.size()-PAGE));anchor=rows[first]
func choose(rows:Array,index:int):
	first=clampi(index,0,maxi(0,rows.size()-PAGE))
	following=first==maxi(0,rows.size()-PAGE)
	anchor={} if rows.is_empty() else rows[first]
func layout(box:Rect2,count:int):
	rect=box;track=Rect2(box.end.x-BAR_WIDTH-6,box.position.y+8,BAR_WIDTH,box.size.y-16)
	var extent=maxi(0,count-PAGE)
	var size=track.size.y if extent==0 else maxf(26.0,track.size.y*PAGE/count)
	var y=track.position.y+(track.size.y-size)*first/maxi(1,extent)
	thumb=Rect2(track.position.x+2,y,BAR_WIDTH-4,size)
func input(event,rows:Array)->bool:
	sync(rows)
	if event is InputEventMouseMotion and dragging:
		choose(rows,roundi((event.position.y-track.position.y-grab)/maxf(1.0,track.size.y-thumb.size.y)*maxi(0,rows.size()-PAGE)))
		return true
	if not event is InputEventMouseButton:return false
	if event.button_index==MOUSE_BUTTON_LEFT and not event.pressed:
		var owned=captured;captured=false;dragging=false;return owned
	if not rect.has_point(event.position):return false
	if event.button_index in [MOUSE_BUTTON_WHEEL_UP,MOUSE_BUTTON_WHEEL_DOWN]:
		if event.pressed:choose(rows,first+(-1 if event.button_index==MOUSE_BUTTON_WHEEL_UP else 1))
		return true
	if event.button_index==MOUSE_BUTTON_LEFT:
		captured=true
		if event.pressed and track.has_point(event.position):
			if not thumb.has_point(event.position):choose(rows,first+(-PAGE if event.position.y<thumb.position.y else PAGE));layout(rect,rows.size())
			dragging=true;grab=clampf(event.position.y-thumb.position.y,0,thumb.size.y)
		return true
	return false
func draw(g):
	if owner_id!=g.world.get_instance_id():owner_id=g.world.get_instance_id();following=true;anchor={};first=0;height=144.0;dragging=false;captured=false
	var rows=g.world.player_events;sync(rows)
	var width=268 if g.selected.get("kind","") in ["keeper","rock"] else 332
	var visible_rows=rows.slice(first,mini(rows.size(),first+PAGE))
	var texts=[]
	for row in visible_rows:texts.append(row.text)
	var key=[width,texts]
	if key!=paragraph_key:
		paragraph_key=key;paragraphs.clear();paragraph_height=16.0
		for row in visible_rows:
			var paragraph=TextParagraph.new();paragraph.add_string(row.text,g.FONT,13);paragraph.width=width-48
			paragraph.break_flags=TextServer.BREAK_MANDATORY|TextServer.BREAK_WORD_BOUND|TextServer.BREAK_ADAPTIVE
			paragraphs.append(paragraph);paragraph_height+=paragraph.get_size().y+6
	height=maxf(height,paragraph_height)
	if styles.is_empty():styles=[Market.panel(Color(0.12,0.19,0.15,0.72)),Market.panel(Color("34483a"),Color("8f9b76")),Market.panel(Color("c3cfa1"),Color("e4dfb8"))]
	layout(Rect2(1264-width,723-height,width,height),rows.size())
	g.event_log_rect=rect;g.event_scroll=maxi(0,rows.size()-PAGE-first)
	g.label_on(g.hud,Vector2(rect.position.x+8,rect.position.y-5),"ログ · "+("新着に追従" if following else "過去の履歴"),11,UI.PAPER)
	g.hud.draw_style_box(styles[0],rect)
	g.hud.draw_style_box(styles[1],track)
	g.hud.draw_style_box(styles[2],thumb)
	# Grips remain visible even with fewer than six messages.
	for dy in [-3,0,3]:g.hud.draw_line(thumb.get_center()+Vector2(-4,dy),thumb.get_center()+Vector2(4,dy),Color("526348"),1)
	var y=rect.position.y+8
	if rows.is_empty():g.label_on(g.hud,Vector2(rect.position.x+12,y+18),"まだ出来事はありません",13,UI.PAPER)
	for paragraph in paragraphs:
		paragraph.draw(g.hud.get_canvas_item(),Vector2(rect.position.x+12,y),UI.PAPER);y+=paragraph.get_size().y+6
