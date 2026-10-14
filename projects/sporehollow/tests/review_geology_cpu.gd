extends SceneTree
## Production cells and RockView rendering composited on CPU. NOT a GPU screenshot.
const Farm=preload("res://game/world.gd")
const View=preload("res://game/rock_view.gd")
class Canvas extends "res://tests/review_connected_rocks_cpu.gd".Canvas:
	const TILE=Vector2(48,42)
func _initialize():call_deferred("run")
func draw(w,bounds,path):
	var c=Canvas.new();c.world=w;c.origin=Vector2(bounds.position)*c.TILE
	c.image=Image.create(bounds.size.x*48,bounds.size.y*42,false,Image.FORMAT_RGBA8)
	for y in range(bounds.position.y,bounds.end.y):
		for x in range(bounds.position.x,bounds.end.x):
			var p=Vector2i(x,y)
			if w.inside(p):c.image.fill_rect(Rect2i(Vector2i(c.center(p))-Vector2i(24,21),Vector2i(48,42)),w.Biome.color_for(w.Biome.field(w,p)))
	View.ground(c,Rect2(Vector2(bounds.position)*c.TILE,Vector2(bounds.size)*c.TILE))
	var cells=w.rocks.keys();cells.sort_custom(func(a,b):return a.y<b.y if a.y!=b.y else a.x<b.x)
	for p in cells:
		if bounds.grow(1).has_point(p):View.rock(c,p)
	if c.image.get_width()>1400:c.image.resize(1400,roundi(c.image.get_height()*1400.0/c.image.get_width()),Image.INTERPOLATE_NEAREST)
	c.image.save_png(path)
func run():
	var out=OS.get_environment("FARM_REVIEW_OUTPUT")
	if DisplayServer.get_name()!="headless" or out=="":quit(2);return
	for seed in [31,97,2026]:
		var w=Farm.new({},seed).begin_day();View.prepare_ground(w)
		draw(w,Rect2i(0,0,w.W,w.H),out+"/cpu-overview-%d.png"%seed)
		if seed==31:
			var iron=w.rocks.keys().filter(func(p):return w.rocks[p].get("geology")=="iron" and View.mask(w,p)==15)[0]
			var bounds=Rect2i(iron-Vector2i(6,5),Vector2i(13,11))
			draw(w,bounds,out+"/cpu-detail-before.png")
			# Visual fixture only: production World.step mining is separately tested.
			w.rocks.erase(iron);w.mined_rock_cells.append(iron);View.changed(w,iron)
			draw(w,bounds,out+"/cpu-detail-after.png")
	print("GEOLOGY_CPU_VISUAL_COMPLETE");quit()
