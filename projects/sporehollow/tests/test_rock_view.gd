extends SceneTree
const Farm=preload("res://game/world.gd")
const View=preload("res://game/rock_view.gd")
class Recorder extends RefCounted:
	var world
	const TILE=Vector2(48,42)
	var calls=[]
	func center(p):return (Vector2(p)+Vector2.ONE*0.5)*TILE
	func draw_texture(t,p,c=Color.WHITE):calls.append(["texture",t,p,c])
	func draw_rect(r,c,filled=true,width=-1):calls.append(["rect",r,c])
	func draw_line(a,b,c,width=1):calls.append(["line",a,b,c])
	func draw_colored_polygon(p,c):calls.append(["polygon",p,c])
var failed=0
var checks=[]
func check(ok: bool,note: String):
	checks.append({"passed":ok,"check":note})
	if not ok:failed+=1;push_error(note)
func _initialize():call_deferred("run")
func run():
	var out=OS.get_environment("FARM_REVIEW_OUTPUT")
	if out=="" or "--isolated-review" not in OS.get_cmdline_user_args():quit(2);return
	var w=Farm.new({},31).begin_day();w.trees.clear();w.natural.clear();w.rocks.clear();w.keeper.pos=Vector2i(12,11);w.keeper.satiety=100;w.animals[0].pos=Vector2i(3,3);w.animals[0].mode="stay";w.nature_config.spawn_chance_per_second=0
	var p=Vector2i(12,12);var r=Recorder.new();r.world=w
	for mask in range(16):
		w.rocks={p:{"amount":8,"forbidden":false}}
		for i in range(4):
			if mask&(1<<i):w.rocks[p+[Vector2i.UP,Vector2i.RIGHT,Vector2i.DOWN,Vector2i.LEFT][i]]={"amount":8,"forbidden":false}
		var before=w.rocks.duplicate(true);var walkable=w.walkable(p);r.calls.clear();View.rock(r,p)
		check(View.mask(w,p)==mask and not r.calls.is_empty(),"Actual renderer handles four-direction mask "+str(mask))
		check(w.rocks==before and w.walkable(p)==walkable,"Drawing does not alter rock quantity or collision: "+str(mask))
		var texture=View.Art.texture(View.normal_key(w,p));check(texture.get_width()==48 and texture.get_height()==54,"Delivered 48x54 canvas is used without stretching: "+str(mask))
	w.rocks={p:{"amount":8,"forbidden":false}};w.Tasks.designate(w,"mine",p)
	for i in range(80):
		w.step()
		if not w.rocks.has(p):break
	check(not w.rocks.has(p) and w.mined_rock_cells.has(p) and w.Stock.totals(w).get("stone",0)==8,"Mining uses the existing work and drop quantity and leaves a visual scar")
	r.calls.clear();View.ground(r);check(not r.calls.is_empty() and w.walkable(p),"Mined pit renders while preserving the newly walkable cell")
	w.Snapshot.save(w,out+"/rock.snapshot");var restored=w.Snapshot.restore(out+"/rock.snapshot");check(restored.mined_rock_cells==w.mined_rock_cells and restored.rocks==w.rocks,"Scars and remaining rock coordinates persist without respawn")
	FileAccess.open(out+"/rock-view.json",FileAccess.WRITE).store_string(JSON.stringify({"method":"Actual draw functions through a recording Canvas API plus production mining and snapshot roundtrip; GPU appearance checked separately","checks":checks,"failures":failed},"\t"))
	print("RockView: ",checks.size()," checks, ",failed," failures");quit(1 if failed else 0)
