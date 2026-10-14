extends SceneTree
const View=preload("res://game/rock_view.gd")
const Ground=preload("res://game/retained_ground.gd")
class Harvest extends RefCounted:
	static func progress(_w,_kind,_p):return 0.0
class Model extends RefCounted:
	const Biome=preload("res://game/biome_map.gd")
	var Harvest
	var seed_value=31
	var rocks={}
	var floors={}
	var structures={}
	var mined_rock_cells=[]
	var terrain={"seed":31}
	func live_structure(p):return structures.has(p)
class Recorder extends RefCounted:
	var world
	var textures=[]
	var shadows=[]
	var lines=0
	func center(p):return (Vector2(p)+Vector2(0.5,0.5))*Vector2(48,42)
	func draw_texture(texture,p,color=Color.WHITE):textures.append([texture,p,color])
	func draw_rect(rect,color):shadows.append([rect,color])
	func draw_set_transform(_p):pass
	func draw_multiline(_points,_color,_width):lines+=1
var checks=[]
func check(ok,note):
	checks.append({"passed":bool(ok),"check":note})
	if not ok:push_error(note)
func _initialize():call_deferred("run")
func run():
	var out=OS.get_environment("FARM_REVIEW_OUTPUT")
	if DisplayServer.get_name()!="headless" or out=="" or "--isolated-review" not in OS.get_cmdline_user_args():quit(2);return
	var w=Model.new();w.Harvest=Harvest;var p=Vector2i(8,8)
	for mask in range(16):
		w.rocks={p:{"amount":8,"forbidden":false}}
		for i in range(4):
			if mask&(1<<i):w.rocks[p+View.DIRS[i]]={"amount":8,"forbidden":false}
		var before=w.rocks.duplicate(true);var r=Recorder.new();r.world=w
		View.rock(r,p)
		check(View.mask(w,p)==mask and w.rocks==before,"Renderer preserves all four-direction connections and resource records: %d"%mask)
		check(r.textures.any(func(row):return row[0]==View.Art.texture(View.normal_key(w,p))),"Uses adopted normal/single rock texture: %d"%mask)
		if mask!=0:check(r.shadows.size()==(0 if mask&4 else 1),"Only exposed south edge has contact shadow: %d"%mask)
		if mask==15:check(r.lines==0 and r.shadows.is_empty(),"Interior has no repeated per-cell crack or isolated shadow")
	var left=View.contact_shadow(Vector2(24,21),2)
	var right=View.contact_shadow(Vector2(72,21),8)
	check(left.end.x==right.position.x and left.position.y==right.position.y,"Adjacent exposed south shadows touch without overlap or gap")
	w.rocks={p:{"amount":8},p+Vector2i.RIGHT:{"amount":8}}
	var q=p+Vector2i.DOWN;var original=w.rocks.duplicate(true)
	var layers=View.apron(w,q)
	check(layers.size()==2 and layers.all(func(row):return row.alpha>0 and row.alpha<0.7 and View.Art.ASSETS.has(row.key)),"Perimeter layers use existing transparent soil and gravel art")
	check(layers==View.apron(w,q),"Perimeter positions are deterministic")
	check(View.apron(w,p).is_empty() and View.apron(w,p+Vector2i(0,3)).is_empty(),"No apron on rock interior or distant soil")
	w.floors[q]={"status":"ready"};check(View.apron(w,q).is_empty(),"Floor covers apron");w.floors.clear()
	w.structures[q]={};check(View.apron(w,q).is_empty(),"Building covers apron");w.structures.clear()
	check(w.rocks==original and w.mined_rock_cells.is_empty(),"Decorating does not modify resources or mining scars")
	w.rocks.erase(p+Vector2i.RIGHT)
	check(View.apron(w,q).is_empty(),"Removing a neighbour updates apron; isolated rock does not claim connected terrain")
	var covered=true;var bounded=true
	for y in range(24):
		for x in range(24):
			var changed=Vector2i(x,y);var chunks=Ground.rock_dependency_chunks(changed)
			bounded=bounded and chunks.size()<=4
			for dy in range(-2,3):
				for dx in range(-2,3):
					if absi(dx)+absi(dy)>2:continue
					var cell=changed+Vector2i(dx,dy)
					var key=Vector2i(floori(cell.x/8.0),floori(cell.y/8.0))
					covered=covered and key in chunks
	check(covered,"Mining/building rock across chunk edges/corners invalidates every dependent apron cell")
	check(bounded,"Each rock contributes to at most four dirty chunk signatures, not a whole-map redraw")
	var failed=checks.filter(func(c):return not c.passed).size()
	FileAccess.open(out+"/minimal-visual-logic.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failed,"method":"Headless CPU recording canvas and pure layout/cache dependency logic; no game scene or GPU"},"\t"))
	print("Minimal visual logic: ",checks.size()," checks, ",failed," failures")
	quit(1 if failed else 0)
