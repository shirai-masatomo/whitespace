extends SceneTree
const Log=preload("res://game/event_log_view.gd")
var checks=[]
func _initialize():call_deferred("run")
func check(ok,note):
	checks.append({"check":note,"passed":bool(ok)})
	if not ok:push_error(note)
func mouse(button,position,pressed=true):
	var e=InputEventMouseButton.new();e.button_index=button;e.position=position;e.pressed=pressed;return e
func run():
	var out=OS.get_environment("FARM_REVIEW_OUTPUT")
	if DisplayServer.get_name()!="headless" or out=="":quit(2);return
	var log=Log.new();var rows=[];var box=Rect2(900,450,330,200)
	log.sync(rows);log.layout(box,rows.size());check(log.thumb.size.y==log.track.size.y and log.track.size.x==18,"Empty log has a visible full thumb and 18px track")
	for i in range(3):rows.append({"tick":i,"text":"出来事%d"%i})
	log.sync(rows);log.layout(box,rows.size());check(log.following and log.first==0 and log.thumb.has_area(),"Short history retains visible scrollbar")
	for i in range(3,120):rows.append({"tick":i,"text":"出来事%d"%i})
	log.sync(rows);log.layout(box,rows.size());check(log.first==114 and is_equal_approx(log.thumb.end.y,log.track.end.y),"New arrivals follow the bottom")
	check(log.input(mouse(MOUSE_BUTTON_WHEEL_UP,box.get_center()),rows) and log.first==113 and not log.following,"Wheel moves through history and consumes event")
	var anchor=rows[log.first];rows.append({"tick":120,"text":"新着"});log.sync(rows)
	check(rows[log.first]==anchor,"Append does not change the row being read")
	rows.pop_front();log.sync(rows);check(rows[log.first]==anchor,"Bounded history eviction keeps the same surviving row")
	log.choose(rows,0);rows.pop_front();log.sync(rows);check(log.first==0 and not log.following,"Evicted anchor clamps to oldest retained entry, not bottom")
	log.layout(box,rows.size());log.input(mouse(MOUSE_BUTTON_LEFT,log.thumb.get_center()),rows)
	var e=InputEventMouseMotion.new();e.position=Vector2(log.track.get_center().x,log.track.end.y+60)
	check(log.input(e,rows) and log.following,"Thumb drag to bottom resumes following")
	check(log.input(mouse(MOUSE_BUTTON_LEFT,Vector2.ZERO,false),rows) and not log.dragging,"Release outside panel ends dragging")
	rows.append({"tick":121,"text":"新着2"});log.sync(rows);check(log.first==rows.size()-6,"Follow resumes for subsequent arrivals")
	check(not log.input(mouse(MOUSE_BUTTON_WHEEL_UP,Vector2.ZERO),rows),"Outside wheel is left to the existing map/UI handler")
	check(not log.input(mouse(MOUSE_BUTTON_LEFT,box.get_center(),false),rows),"World drag release over log is not stolen")
	check(log.input(mouse(MOUSE_BUTTON_LEFT,box.get_center()),rows),"Clicks in log do not leak into world selection")
	check(log.input(mouse(MOUSE_BUTTON_LEFT,Vector2.ZERO,false),rows) and not log.captured,"Log-owned click release remains consumed outside panel")
	rows.clear();log.sync(rows);check(log.following and log.first==0,"History clear resets follow state")
	var failures=checks.filter(func(c):return not c.passed).size()
	FileAccess.open(out+"/log-scroll.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures},"\t"))
	print("LOG_SCROLL: ",checks.size()," checks, failures=",failures);quit(1 if failures else 0)
