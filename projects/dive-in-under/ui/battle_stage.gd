extends Control
## Layered, static candidate preview. Legacy dots remain only for missing actors.
const VisualAssets = preload("res://ui/visual_assets.gd")
var floor_number := 1
var scenery: TextureRect
var hero_art: Sprite2D
var enemy_art: Sprite2D
var enemy_id := "E04"
var hero_alive := true
var enemy_alive := true
const PALETTE := {"o":"17242b","h":"324553","b":"766047","g":"b4a17b","s":"dfb282","e":"f6d578",
	"t":"486878","m":"6d917a","l":"9ab494","r":"c27a53","a":"c6d0c5","w":"ece9c8"}
const HERO := [
	"       ooooo      ","     oohhhhhoo    ","    ohhhtthhho   ","   ohhhoosssoho  ",
	"   ohhoossesooho ","    ooossssooho  ","    ohhoooohhho  ","   ohhhggbhhho   ",
	"  ohhtggbgbhhho  "," ohtthbggbhhhho  ","ohtthbbgbbhsso   "," ohtobbgbbbbho   ",
	"  oobbbbgbbbho   ","  oobggggggbho   ","   obbbobbbbho   ","  oabbooobbbho   ",
	" oawobbo obbo    ","oaw obbo obbo    ","ow  obgo obgo    ","    obbo obbo    ",
	"    oggo oggo    ","    obbo obbo    ","   obbbo obbbo   ","   ooooo ooooo   "]
const GOBLIN := [
	"    oo     oo    ","   ommooooommo   ","  ommmmmmmmmmo   "," ommllmmmmllmmo  ",
	"  ommemmmmemmo   ","   ommmommmmo    ","    omwwwwmo     ","   ooboooboo     ",
	"  ommbbbbmmmo    "," ommmbbbbmmmmo   ","ommoobbbboommo   "," oo obbbbo oo    ",
	"    oggggo       ","   obboobbo      ","   ommoommo      ","  ommmoommmo     ","  ooooo ooooo    "]
const SLIME := [
	"       oooo       ","     ootttttoo    ","    ottttttttto   ","   ottttttttttto  ",
	"  ottwtttttwtttto "," ottttottttottttto","otttttttttttttttto","ottttttooottttttto"," oooooooooooooooo "]
const RAT := [
	"  ooo      ooo     "," ommmo    ommmo    "," ommmooooommmmo    ","  ommmmmmmmmmo     ",
	" ommmemmmmmemmo    "," ommmmmmmmmmmmo    ","  ommmrrrmmmmo     ","   ommwwmmmmo      ",
	"  ommmmmmmmmmo     "," ommmmmmmmmmmmo    ","ommmmmmmmmmmmmmo   ","ommmmooooommmmmoooo",
	" ommo     ommo     "," oooo     oooo     "]
const BAT := [
	"o                 o","oo      o o      oo","oto    oomoo    oto","otto  ommmmmo  otto",
	"otttoommeemmoottto","otttttmmmmmmttttto"," ottttommmmotttto ","  oto owwwo oto   ","   o   ooo   o    "]
const BEETLE := [
	"  oo          oo   ","  omoo      oommo  ","   omooooooooomo   ","   oohhgggghhoo    ",
	"  ohhgggggggghho   "," ohhgggggggggghho  ","ohhhgggoggogghhho  ","ohhhgggoggogghhho  ",
	" ohhhggoggoghhho   ","  ohhgggggghho     "," oommoeeeoommoo    ","ommo oooo  ommmo   ","oo          ooo    "]
const STATUE := [
	"     oooooooo     ","    oaggggggao    ","    oggoooggao    ","    oggeogeggo    ",
	"    ogggoogggo    ","     ogwwggo      ","   ooaggggaoo     "," ooaaggggggaaoo   ",
	"oaaggggggggggaao  ","oggaaggggggaaggo  ","oggoaggggggaoggo  ","oggoaggggggaoggo  ",
	"ooooaggggggaoooo  ","   oaggggggao     ","   oaggooaggo     ","   oaggooaggo     ",
	"   ogggoogggo     ","  oagggoogggao    ","  ooooo oooooo    "]

func _ready() -> void:
	mouse_filter = MOUSE_FILTER_IGNORE
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	custom_minimum_size.y = 270
	clip_contents = true
	scenery = TextureRect.new()
	scenery.show_behind_parent = true
	scenery.mouse_filter = MOUSE_FILTER_IGNORE
	scenery.texture = VisualAssets.texture(VisualAssets.background_key(floor_number))
	scenery.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	scenery.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	scenery.modulate = VisualAssets.depth_tint(floor_number)
	scenery.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(scenery)
	hero_art = Sprite2D.new()
	hero_art.texture = VisualAssets.actor_texture("hero")
	add_child(hero_art)
	enemy_art = Sprite2D.new()
	enemy_art.texture = VisualAssets.actor_texture(enemy_id)
	add_child(enemy_art)
	resized.connect(layout_art)
	layout_art()

func set_encounter(value: String, depth: int) -> void:
	enemy_id = value
	floor_number = depth
	if scenery != null:
		scenery.texture = VisualAssets.texture(VisualAssets.background_key(depth))
		scenery.modulate = VisualAssets.depth_tint(depth)
		enemy_art.texture = VisualAssets.actor_texture(value)
		layout_art()

func ground_y() -> float:
	if scenery.texture == null: return size.y-35
	var source := scenery.texture.get_size()
	var factor := maxf(size.x/source.x,size.y/source.y)
	return 705.0*factor-(source.y*factor-size.y)*0.5

func place_actor(actor: Sprite2D, key: String, fraction: float, target_height: float) -> void:
	if actor.texture == null: return
	var dimensions := actor.texture.get_size()
	var factor := minf(target_height / dimensions.y, size.x * 0.34 / dimensions.x)
	actor.scale = Vector2.ONE * factor
	actor.centered = false
	actor.offset = -VisualAssets.actor_foot(key)
	actor.position = Vector2(roundf(size.x * fraction), roundf(ground_y()))

func layout_art() -> void:
	place_actor(hero_art,"hero",0.75,165)
	place_actor(enemy_art,enemy_id,0.24,205 if enemy_id == "B10" else 145)
	queue_redraw()

func visual_audit() -> Dictionary:
	var actors: Array = []
	for pair in [["hero",hero_art],[enemy_id,enemy_art]]:
		var actor: Sprite2D = pair[1]
		var entry := {"id":pair[0],"candidate_loaded":actor.texture != null}
		if actor.texture != null:
			var extent := actor.texture.get_size() * actor.scale
			entry["visible_size"] = [extent.x,extent.y]
			var top_left := actor.position+actor.offset*actor.scale
			entry["top_left"] = [top_left.x,top_left.y]
			entry["foot"] = [actor.position.x,actor.position.y]
			entry["within_stage"] = Rect2(Vector2.ZERO,size).encloses(Rect2(top_left,extent))
		actors.append(entry)
	return {"background":VisualAssets.background_key(floor_number),"background_loaded":scenery.texture != null,
		"depth":floor_number,"stage_size":[size.x,size.y],"filter":"nearest","aspect":"preserved",
		"static_only":true,"adoption":"five-assets-current-baseline","actors":actors}

func sprite(pattern: Array, origin: Vector2, pixel: int, _alive: bool) -> void:
	for y in range(pattern.size()):
		for x in range(pattern[y].length()):
			var key: String = pattern[y][x]
			if PALETTE.has(key):
				var color := Color(PALETTE[key])
				draw_rect(Rect2(origin+Vector2(x,y)*pixel,Vector2.ONE*pixel),color)

func draw_placeholder_background() -> void:
	draw_rect(Rect2(Vector2.ZERO,size),Color("0c222b"))
	for x in range(0,int(size.x),24):
		var height := 20 + (x * 7 % 47)
		draw_rect(Rect2(x,0,24,height),Color("153b45"))
		draw_rect(Rect2(x+6,height,12,12),Color("153b45"))
	for x in range(int(size.x*0.42),int(size.x*0.56),8):
		draw_rect(Rect2(x,0,6,size.y-32),Color("255563"))
		for y in range(15,int(size.y-32),29):
			draw_rect(Rect2(x+2,y+x%17,2,12),Color("4c8890"))
	for x in range(0,int(size.x),32):
		draw_rect(Rect2(x,size.y-35,30,5),Color("687260"))
		draw_rect(Rect2(x+2,size.y-30,28,30),Color("243f44"))
		draw_rect(Rect2(x+5,size.y-25,18,3),Color("34555b"))
	for x in [16.0,size.x-30]:
		draw_rect(Rect2(x+5,42,3,47),Color("80663b"))
		draw_rect(Rect2(x,86,16,25),Color("b67b3d"))
		draw_rect(Rect2(x+4,90,8,17),Color("ffdb7b"))
func _draw() -> void:
	if scenery == null or scenery.texture == null: draw_placeholder_background()
	var patterns := {"E01":RAT,"E02":SLIME,"E03":BAT,"E04":GOBLIN,"E05":BEETLE,"B10":STATUE}
	var pattern: Array = patterns.get(enemy_id,GOBLIN)
	if enemy_id!="" and (enemy_art == null or enemy_art.texture == null): sprite(pattern,Vector2(size.x*0.17,ground_y()-pattern.size()*5),5,enemy_alive)
	if hero_art == null or hero_art.texture == null: sprite(HERO,Vector2(size.x*0.72,ground_y()-HERO.size()*5),5,hero_alive)
