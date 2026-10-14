extends SceneTree
const Farm=preload("res://game/world.gd")
const UI=preload("res://game/ui_style.gd")
const View=preload("res://game/rock_view.gd")
var checks=[]
var samples=[]
func _initialize():call_deferred("run")
func check(ok,note):
	checks.append({"passed":bool(ok),"check":note})
	if not ok:push_error(note)
func components(cells):
	var left=cells.duplicate();var sizes=[]
	while not left.is_empty():
		var queue=[left.keys()[0]];left.erase(queue[0]);var i=0
		while i<queue.size():
			var p=queue[i];i+=1
			for d in View.DIRS:
				if left.has(p+d):left.erase(p+d);queue.append(p+d)
		sizes.append(queue.size())
	sizes.sort();sizes.reverse();return sizes
func run():
	var out=OS.get_environment("FARM_REVIEW_OUTPUT")
	if DisplayServer.get_name()!="headless" or out=="":quit(2);return
	var b=Button.new();UI.architect_selected(b,true)
	var selected=b.get_theme_stylebox("normal").modulate_color
	check(selected==b.get_theme_stylebox("hover").modulate_color,"Selected light green survives hover")
	check(selected.g>selected.r and selected.g>selected.b,"Selection is green")
	check(b.get_theme_stylebox("pressed").modulate_color==b.get_theme_stylebox("hover_pressed").modulate_color,"Pressed and hovered pressed remain consistent")
	UI.architect_selected(b,false)
	check(b.get_theme_stylebox("hover").modulate_color!=selected,"Unselected hover differs from selection")
	b.free()
	for seed in [31,97,2026]:
		var start=Time.get_ticks_msec();var w=Farm.new({},seed).begin_day();var sizes=components(w.rocks)
		var reachable=w.Biome.reachable(w);var free=0
		for y in range(w.H):
			for x in range(w.W):
				if w.walkable(Vector2i(x,y)):free+=1
		check(sizes[0]>=w.rocks.size()*0.8,"At least 80%% of rocks form one orthogonally connected body: %d"%seed)
		check(w.rocks.size()==w.terrain.rock_layout_budget,"Original rock count/resource budget preserved: %d"%seed)
		check(w.rocks.values().all(func(r):return r.amount==8),"Per-cell mining yield remains 8: %d"%seed)
		check(w.rocks.keys().all(func(p):return not w.Biome.protected(w,p) and not w.walkable(p)),"Protected area remains clear and each actual rock blocks movement: %d"%seed)
		check(reachable.size()==free,"All free ground remains reachable: %d"%seed)
		check(w.rocks.keys().filter(func(p):return View.mask(w,p)==15).size()>10,"Dense connected interior exists: %d"%seed)
		samples.append({"seed":seed,"rocks":w.rocks.size(),"components":sizes,"budget":w.terrain.rock_layout_budget,"generation_and_checks_ms":Time.get_ticks_msec()-start})
	var fail=checks.filter(func(c):return not c.passed).size()
	FileAccess.open(out+"/connected-rocks.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"samples":samples,"failures":fail},"\t"))
	print("CONNECTED_ROCKS: ",checks.size()," checks failures=",fail);quit(1 if fail else 0)
