extends SceneTree
## CPU-only comparison, not a game screenshot. No main scene or GPU renderer.
const Farm=preload("res://game/world.gd")
const View=preload("res://game/rock_view.gd")
const UI=preload("res://game/ui_style.gd")
class Canvas extends RefCounted:
	var world
	var image: Image
	var origin=Vector2.ZERO
	var shift=Vector2.ZERO
	var textures={}
	func center(p):return (Vector2(p)+Vector2(0.5,0.5))*Vector2(48,42)-origin
	func draw_set_transform(p):shift=p
	func draw_texture(texture,p,color=Color.WHITE):
		var key=str(texture.get_instance_id())+str(color)
		if not textures.has(key):
			var source=texture.get_image().duplicate();source.convert(Image.FORMAT_RGBA8)
			if color!=Color.WHITE:
				for y in range(source.get_height()):
					for x in range(source.get_width()):source.set_pixel(x,y,source.get_pixel(x,y)*color)
			textures[key]=source
		var source=textures[key];image.blend_rect(source,Rect2i(Vector2i.ZERO,source.get_size()),Vector2i(p))
	func draw_rect(rect,color):
		var patch=Image.create(int(rect.size.x),int(rect.size.y),false,Image.FORMAT_RGBA8);patch.fill(color)
		image.blend_rect(patch,Rect2i(Vector2i.ZERO,patch.get_size()),Vector2i(rect.position))
	func draw_multiline(points,color,_width):
		for i in range(0,points.size(),2):
			var a=points[i]+shift;var b=points[i+1]+shift;var n=maxi(1,ceili(a.distance_to(b)))
			for t in range(n+1):
				var p=Vector2i(a.lerp(b,float(t)/n))
				if Rect2i(Vector2i.ZERO,image.get_size()).has_point(p):image.set_pixelv(p,color)
func _initialize():call_deferred("run")
func draw_rocks(w,bounds,path):
	var c=Canvas.new();c.world=w;c.origin=Vector2(bounds.position)*Vector2(48,42)
	c.image=Image.create(bounds.size.x*48,bounds.size.y*42,false,Image.FORMAT_RGBA8);c.image.fill(Color("807c63"))
	for y in range(bounds.position.y,bounds.end.y):
		for x in range(bounds.position.x,bounds.end.x):
			var p=Vector2i(x,y)
			for row in View.apron(w,p):View.Art.paint(c,row.key,c.center(p)+row.offset,row.alpha)
	var cells=w.rocks.keys();cells.sort_custom(func(a,b):return a.y<b.y if a.y!=b.y else a.x<b.x)
	for p in cells:View.rock(c,p)
	if c.image.get_width()>1100:c.image.resize(1100,roundi(c.image.get_height()*1100.0/c.image.get_width()),Image.INTERPOLATE_NEAREST)
	c.image.save_png(path)
func style_image(box,path):
	var source=box.texture.get_image();source.convert(Image.FORMAT_RGBA8)
	var dest=Image.create(180,36,false,Image.FORMAT_RGBA8)
	var sx=[0,7,source.get_width()-7,source.get_width()];var sy=[0,7,source.get_height()-7,source.get_height()]
	var dx=[0,7,173,180];var dy=[0,7,29,36]
	for y in range(3):
		for x in range(3):
			var part=source.get_region(Rect2i(sx[x],sy[y],sx[x+1]-sx[x],sy[y+1]-sy[y]));part.resize(dx[x+1]-dx[x],dy[y+1]-dy[y],Image.INTERPOLATE_NEAREST)
			dest.blit_rect(part,Rect2i(Vector2i.ZERO,part.get_size()),Vector2i(dx[x],dy[y]))
	for y in range(36):
		for x in range(180):dest.set_pixel(x,y,dest.get_pixel(x,y)*box.modulate_color)
	dest.save_png(path)
func run():
	var out=OS.get_environment("FARM_REVIEW_OUTPUT")
	if DisplayServer.get_name()!="headless" or out=="":quit(2);return
	var w=Farm.new({},31).begin_day();w.rocks.clear();w.natural.clear()
	var old=GDScript.new();old.source_code=FileAccess.get_file_as_string("res://game/biome_map.gd").replace("\tconsolidate_rocks(w,eligible,cores)","\tpass # old placement");old.reload()
	old.place_rocks(w);var before=w.rocks.duplicate(true)
	w.rocks.clear();w.Biome.place_rocks(w);var after=w.rocks.duplicate(true)
	var bounds=Rect2i(before.keys()[0],Vector2i.ONE)
	for p in before:bounds=bounds.expand(p)
	for p in after:bounds=bounds.expand(p)
	bounds=bounds.grow(2)
	w.rocks=before;draw_rocks(w,bounds,out+"/rocks-before.png")
	w.rocks=after;draw_rocks(w,bounds,out+"/rocks-after.png")
	var b=Button.new();UI.button(b);UI.selected(b,true)
	style_image(b.get_theme_stylebox("normal"),out+"/button-before-normal.png");style_image(b.get_theme_stylebox("hover"),out+"/button-before-hover.png")
	UI.architect_selected(b,true)
	style_image(b.get_theme_stylebox("normal"),out+"/button-after-normal.png");style_image(b.get_theme_stylebox("hover"),out+"/button-after-hover.png")
	UI.architect_selected(b,false);style_image(b.get_theme_stylebox("hover"),out+"/button-unselected-hover.png");b.free()
	FileAccess.open(out+"/cpu-visual.json",FileAccess.WRITE).store_string(JSON.stringify({"method":"CPU Image compositing of production RockView.rock/apron and actual StyleBoxTexture settings; not game screenshots; background soil shader, actors, HUD and GPU untested","seed":31,"before_count":before.size(),"after_count":after.size(),"bounds":str(bounds),"fixture":"same generated terrain and trees; initial harvestables cleared identically; before generator differs only by omitted consolidate call"},"\t"))
	print("CPU_VISUAL_COMPLETE");quit()
